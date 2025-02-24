# pragma version 0.4.0
# @license MIT

from pcaversaccio.snekmate.src.snekmate.auth import ownable
from pcaversaccio.snekmate.src.snekmate.tokens import erc20

initializes: ownable
initializes: erc20[ownable := ownable]
exports: (
    erc20.owner,
    erc20.IERC20,
    erc20.IERC20Detailed,
    erc20.mint,
    erc20.set_minter,
    ownable.renounce_ownership,
    ownable.transfer_ownership,
)


@deploy
def __init__(
    name: String[25],
    symbol: String[5],
    decimals: uint8,
    name_eip712: String[50],
    version_eip712: String[20],
):
    ownable.__init__()
    erc20.__init__(name, symbol, decimals, name_eip712, version_eip712)