from src.mocks import UniswapV2Router
from moccasin.boa_tools import VyperContract
from moccasin.config import get_active_network


def deploy() -> VyperContract:
    uniswap_v2_router: VyperContract = UniswapV2Router.deploy()
    print("UniswapV2Router02 ping 🏓: ", uniswap_v2_router.ping())
    return uniswap_v2_router


def moccasin_main() -> VyperContract:
    return deploy()
