from src import TokenBlueprint, TokenDeployer
from moccasin.boa_tools import VyperContract
from moccasin.config import get_active_network

def deploy() -> VyperContract:
    token_blueprint = TokenBlueprint.deploy_as_blueprint()
    token_deployer = TokenDeployer.deploy(token_blueprint)
    # result = get_active_network().moccasin_verify(token_deployer)
    # result.wait_for_verification()
    print("TokenDeployer deployed at: ", token_deployer.address)
    print("QuickSwap address: ", token_deployer.QUICKSWAP_ROUTER())
    return token_deployer


def moccasin_main() -> VyperContract:
    return deploy()
