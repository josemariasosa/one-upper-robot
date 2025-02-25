import pytest
from script.deploy import deploy, deploy_fixture

@pytest.fixture
def robot_contract():
    return deploy()

@pytest.fixture
def protocol_contract():
    return deploy_fixture()