import csv
import hashlib
import os
import platform
import pytest

component = "kernel"
arch = platform.machine()

with open("tests/hashes.csv", newline="") as f:
    reader = csv.DictReader(f)
    for row in reader:
        if row["component"] == component and row["arch"] == arch:
            filename = row["filename"]
            sha256 = row["sha256"]

@pytest.fixture
def build_filename():
    return filename

@pytest.fixture
def expected_hash():
    return sha256

@pytest.fixture
def current_arch():
    return arch

def test_hash(build_filename, expected_hash, current_arch):
    # Skip the test if we're using a dummy string for the hash
    if expected_hash == "0":
        pytest.skip("Build for " + current_arch + " architecture is not yet reproducible")

    with open(build_filename, 'rb') as f:
        file_hash = hashlib.sha256()
        while chunk := f.read(8192):
            file_hash.update(chunk)

    assert file_hash.hexdigest() == expected_hash
