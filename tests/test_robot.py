def test_quickswap_address(robot_contract):
    assert robot_contract.QUICKSWAP_ROUTER() == "0xa5E0829CaCEd8fFDD4De3c43696c57F7D7A678ff"

def test_deploy_token(robot_contract):
    new_token = robot_contract.deploy_token("TestToken", "TT", 18)
    assert new_token.name() == "TestToken"
    assert robot_contract.QUICKSWAP_ROUTER() == "0xa5E0829CaCEd8fFDD4De3c43696c57F7D7A678ff"
