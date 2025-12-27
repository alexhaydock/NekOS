import hashlib
import os
import platform
import pytest

@pytest.fixture
def built_file_path():
    return "firmware/build/firmware.fd"

@pytest.fixture
def expected_hash_x86_64():
    return "be3cf92e8ae2fe8d171cef616484c5e26f023dd96c95d933373378bf762cbdee"

@pytest.fixture
def expected_hash_aarch64():
    return "0000000000000000000000000000000000000000000000000000000000000000"

def test_hash(built_file_path, expected_hash_x86_64, expected_hash_aarch64):
    machine_type = platform.machine()
    if machine_type == 'x86_64':
        expected_hash = expected_hash_x86_64
    elif machine_type == 'aarch64':
        expected_hash = expected_hash_aarch64

    # Skip the test if we're using a dummy string for the hash
    if expected_hash == "0000000000000000000000000000000000000000000000000000000000000000":
        pytest.skip("Build for " + machine_type + " architecture is not yet reproducible")

    with open(built_file_path, 'rb') as f:
        file_hash = hashlib.sha256()
        while chunk := f.read(8192):
            file_hash.update(chunk)

    assert file_hash.hexdigest() == expected_hash
