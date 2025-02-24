import pytest
from script.deploy import deploy

@pytest.fixture
def robot_contract():
    return deploy()