# pragma version 0.4.0

"""
@title Token Deployer and Liquidity Seeder
@license MIT
@notice Robot deploys, and subsidize, ERC20 tokens.
        Then, token owner must provides initial liquidity on QuickSwap.
"""

from interfaces import IERC20Extended
from interfaces import IOwnable

ERC20_IMPL: public(immutable(address))

ROBOT_ADDRESS: public(immutable(address))


QUICKSWAP_ROUTER: public(
    constant(address)
) = 0xa5E0829CaCEd8fFDD4De3c43696c57F7D7A678ff
MAX_OWNER_SHARE: constant(uint256) = 9_000


event TokenDeployed:
    token: indexed(address)
    total_supply: uint256


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
def __init__(erc20_impl: address, robot_address: address):
    ERC20_IMPL = erc20_impl
    ROBOT_ADDRESS = robot_address


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
@payable
def deploy_token(
    name: String[25],
    symbol: String[5],
    decimals: uint8,
    name_eip712: String[50],
    version_eip712: String[20],
    total_supply: uint256,
    owner_share: uint256,
    burn_owner: bool,
) -> (address, uint256):
    """
    @notice Deploys a new token and adds initial liquidity
    @param name Token name
    @param symbol Token symbol
    @param decimals Token decimals
    @param name_eip712 The signing domain's name
    @param version_eip712 Version of the signing domain
    @param total_supply Initial total supply
    @param owner_share Percentage of tokens for owner (in bps)
    @param burn_owner Whether to burn owner privileges
    @return Address of new token and amount of LP tokens
    """

    assert msg.sender == ROBOT_ADDRESS, "Only the robot can deploy tokens"

    assert msg.value > 0, "POL amount must be greater than 0"
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

    # Mint tokens
    extcall IERC20Extended(new_token).mint(
        msg.sender, owner_amount
    )  # Mint owner's share
    extcall IERC20Extended(new_token).mint(
        self, liquidity_amount
    )  # Mint liquidity tokens to contract
    log TokenDeployed(new_token, total_supply)

    # Renounce token contract ownership if burn_owner or transfer it to the sender
    if burn_owner:
        extcall IOwnable(new_token).renounce_ownership()
    else:
        extcall IOwnable(new_token).transfer_ownership(msg.sender)

    return new_token, self._add_liquidity(
        new_token, liquidity_amount, msg.value
    )