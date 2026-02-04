#!/bin/bash
# Test script for specific version scenario

set -e

source dev-container-features-test-lib

# Check that bun is installed
check "bun is installed" bash -c "which bun"

# Check bun version matches expected (1.1.0)
check "bun version is 1.1.0" bash -c "bun --version | grep -q '1.1.0'"

reportResults
