#!/bin/bash
# Test script for the Debian scenario

set -e

source dev-container-features-test-lib

# Check that bun is installed
check "bun is installed" bash -c "which bun"

# Check bun version command works
check "bun version" bash -c "bun --version"

# Check that bun can execute a simple script
check "bun can run script" bash -c "echo 'console.log(\"hello\")' | bun run -"

reportResults
