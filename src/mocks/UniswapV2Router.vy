# pragma version 0.4.0
# SPDX-License-Identifier: MIT


@payable
@external
def addLiquidityETH(
    token: address,
    amount_token_desired: uint256,
    amount_token_min: uint256,
    amount_eth_min: uint256,
    to: address,
    deadline: uint256,
) -> (uint256, uint256, uint256):
    return (0, 0, 0)


@external
def ping() -> bool:
    return True