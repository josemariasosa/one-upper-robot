from src import TokenBlueprint, TokenDeployer
from moccasin.boa_tools import VyperContract
from moccasin.config import get_config


def deploy() -> VyperContract:
    active_network = get_config().get_active_network()
    uniswap_v2_router: VyperContract = active_network.manifest_named("uniswap_v2_router")

    token_blueprint = TokenBlueprint.deploy_as_blueprint()
    token_deployer = TokenDeployer.deploy(
        token_blueprint,
        get_config().extra_data["robot_address"],
        uniswap_v2_router
    )

    print("UniswapRouter deployed at: ", uniswap_v2_router.address)
    print("TokenDeployer deployed at: ", token_deployer.address)
    print("QuickSwap address: ", token_deployer.QUICKSWAP_ROUTER())

    return token_deployer


def deploy_fixture() -> tuple[VyperContract, VyperContract]:
    active_network = get_config().get_active_network()
    uniswap_v2_router: VyperContract = active_network.manifest_named("uniswap_v2_router")

    token_blueprint = TokenBlueprint.deploy_as_blueprint()
    token_deployer = TokenDeployer.deploy(
        token_blueprint,
        get_config().extra_data["robot_address"],
        uniswap_v2_router
    )

    print("UniswapRouter deployed at: ", uniswap_v2_router.address)
    print("TokenDeployer deployed at: ", token_deployer.address)
    print("QuickSwap address: ", token_deployer.QUICKSWAP_ROUTER())

    return (token_deployer, uniswap_v2_router)


def moccasin_main() -> VyperContract:
    return deploy()
