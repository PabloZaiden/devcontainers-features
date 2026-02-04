#!/bin/bash
# Test script for the Bun devcontainer feature

set -e

# Import the dev container features test library
source dev-container-features-test-lib

# Check that bun is installed and accessible
check "bun is installed" bash -c "which bun"

# Check bun version command works
check "bun version" bash -c "bun --version"

# Check that bun can execute a simple script
check "bun can run script" bash -c "echo 'console.log(\"hello\")' | bun run -"

# Check BUN_INSTALL environment variable
check "BUN_INSTALL is set" bash -c "[ -n \"\${BUN_INSTALL}\" ]"

# Report results
reportResults
