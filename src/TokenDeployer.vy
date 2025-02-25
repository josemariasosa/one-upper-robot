# pragma version 0.4.0
# SPDX-License-Identifier: MIT

"""
@title Token Deployer and Liquidity Seeder
@license MIT
@notice Robot deploys, and subsidize, ERC20 tokens.
        Then, token owner must provides initial liquidity on QuickSwap.
"""

from interfaces import IERC20Extended
from interfaces import IOwnable

from pcaversaccio.snekmate.src.snekmate.auth import ownable

initializes: ownable
exports: (
    ownable.owner,
    ownable.renounce_ownership,
    ownable.transfer_ownership,
)

ERC20_IMPL: public(immutable(address))
QUICKSWAP_ROUTER: public(immutable(address))
MAX_OWNER_SHARE: constant(uint256) = 9_000


event TokenDeployed:
    token: indexed(address)
    total_supply: uint256


struct UserToken:
    token: address
    owner_amount: uint256
    liquidity_amount: uint256
    reclaimed: bool


user_tokens: public(HashMap[address, UserToken[100]])
user_last_token_index: public(HashMap[address, uint256])


interface IUniswapV2Router02:
    def addLiquidityETH(
        token: address,
        amount_token_desired: uint256,
        amount_token_min: uint256,
        amount_eth_min: uint256,
        to: address,
        deadline: uint256,
    ) -> (uint256, uint256, uint256): payable


@deploy
def __init__(erc20_impl: address, owner: address, quickswap_router: address):
    ownable.__init__()
    ERC20_IMPL = erc20_impl
    QUICKSWAP_ROUTER = quickswap_router
    ownable._transfer_ownership(owner)


@internal
def _create_token(
    name: String[25],
    symbol: String[5],
    decimals: uint8,
    name_eip712: String[50],
    version_eip712: String[20],
) -> address:
    return create_from_blueprint(
        ERC20_IMPL, name, symbol, decimals, name_eip712, version_eip712
    )


@internal
def _add_liquidity(
    token: address, token_amount: uint256, eth_amount: uint256
) -> uint256:
    # Approve router to spend tokens
    extcall IERC20Extended(token).approve(QUICKSWAP_ROUTER, token_amount)

    liquidity: uint256 = (
        extcall IUniswapV2Router02(QUICKSWAP_ROUTER).addLiquidityETH(
            token,
            token_amount,
            0,  # Disregard min amounts / slippage issues
            0,  # Ibid
            msg.sender,  # LP tokens go back to the caller
            block.timestamp + 1,  # Deadline
            value=eth_amount,
        )
    )[2]
    return liquidity


@external
def deploy_token(
    name: String[25],
    symbol: String[5],
    decimals: uint8,
    name_eip712: String[50],
    version_eip712: String[20],
    total_supply: uint256,
    token_owner: address,
    owner_share: uint256,
) -> address:
    """
    @notice Deploys a new token and adds initial liquidity
    @param name Token name
    @param symbol Token symbol
    @param decimals Token decimals
    @param name_eip712 The signing domain's name
    @param version_eip712 Version of the signing domain
    @param total_supply Initial total supply
    @param owner_share Percentage of tokens for owner (in bps)
    @return Address of new token and amount of LP tokens
    """

    ownable._check_owner()

    assert owner_share < MAX_OWNER_SHARE, "Owner share must be lower than 90%"
    assert total_supply > 0, "Total supply must be greater than 0"

    # deploy the token with the metadata given
    new_token: address = self._create_token(
        name, symbol, decimals, name_eip712, version_eip712
    )

    # Calculate owner's share
    owner_amount: uint256 = total_supply * owner_share // 10_000
    # Calculate liquidity amount (remaining tokens)
    liquidity_amount: uint256 = total_supply - owner_amount

    self.user_tokens[token_owner][self.user_last_token_index[token_owner]] = UserToken(
        token=new_token,
        owner_amount=owner_amount,
        liquidity_amount=liquidity_amount,
        reclaimed=False,
    )
    self.user_last_token_index[token_owner] += 1

    log TokenDeployed(new_token, total_supply)

    return new_token

@external
@payable
def reclaim_token(token_index: uint256, burn_owner: bool) -> uint256:
    token: UserToken = self.user_tokens[msg.sender][token_index]
    assert not token.reclaimed, "Token already reclaimed"
    assert token.owner_amount > 0, "No owner amount to reclaim"
    self.user_tokens[msg.sender][token_index].reclaimed = True

    # Mint tokens
    extcall IERC20Extended(token.token).mint(
        msg.sender, token.owner_amount
    )  # Mint owner's share
    extcall IERC20Extended(token.token).mint(
        self, token.liquidity_amount
    )  # Mint liquidity tokens to contract

    # Renounce token contract ownership if burn_owner or transfer it to the sender
    if burn_owner:
        extcall IOwnable(token.token).renounce_ownership()
    else:
        extcall IOwnable(token.token).transfer_ownership(msg.sender)

    return self._add_liquidity(token.token, token.liquidity_amount, msg.value)

@view
@external
def token_balance_of(token: address, owner: address) -> uint256:
    return staticcall IERC20Extended(token).balanceOf(owner)
    
