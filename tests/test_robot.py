from moccasin.config import get_config
import boa

ROBOT_ADDRESS = get_config().extra_data["robot_address"]
ALICE_ADDRESS = boa.env.eoa

def test_deployer_params(protocol_contract):
    token_deployer, uniswap_v2_router = protocol_contract
    assert token_deployer.QUICKSWAP_ROUTER() == uniswap_v2_router.address
    assert token_deployer.owner() == ROBOT_ADDRESS

def test_deploy_token(protocol_contract):
    token_deployer, uniswap_v2_router = protocol_contract
    assert token_deployer.user_last_token_index(ALICE_ADDRESS) == 0
    with boa.env.prank(ROBOT_ADDRESS):
        new_token = token_deployer.deploy_token(
            # name: String[25],
            "TestToken",
            # symbol: String[5],
            "TT",
            # decimals: uint8,
            18,
            # name_eip712: String[50],
            "TestToken",
            # version_eip712: String[20],
            "1",
            # total_supply: uint256,
            100000 * 10 ** 18,
            # token_owner: address,
            ALICE_ADDRESS,
            # owner_share: uint256,
            2000
        )

    assert token_deployer.user_last_token_index(ALICE_ADDRESS) == 1
    test_token = token_deployer.user_tokens(ALICE_ADDRESS, 0)
    assert test_token[0] == new_token

    assert token_deployer.token_balance_of(new_token, ALICE_ADDRESS) == 0
    token_deployer.reclaim_token(0, True)
    assert token_deployer.token_balance_of(new_token, ALICE_ADDRESS) == 20000000000000000000000
    print("TOKENO: ", test_token)
    print(boa.env.eoa) # 0xd8dA6BF26964aF9D7eEd9e03E53415D37aA96045  
    # new_token = robot_contract.deploy_token("TestToken", "TT", 18)
    # assert new_token.name() == "TestToken"
    # assert robot_contract.QUICKSWAP_ROUTER() == "0xa5E0829CaCEd8fFDD4De3c43696c57F7D7A678ff"
