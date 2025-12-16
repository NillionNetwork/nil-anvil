#!/bin/bash
set -e

echo "Starting Anvil local Ethereum node..."

# Start Anvil in the background, listening on all interfaces
anvil --host 0.0.0.0 --port 8545 &
ANVIL_PID=$!

# Poll until RPC is actually ready (not just process running)
echo "Waiting for Anvil RPC to be ready..."
for i in {1..30}; do
    if cast chain-id --rpc-url http://127.0.0.1:8545 > /dev/null 2>&1; then
        echo "Anvil RPC is ready"
        break
    fi
    if ! kill -0 $ANVIL_PID 2>/dev/null; then
        echo "ERROR: Anvil process died during startup"
        exit 1
    fi
    if [ $i -eq 30 ]; then
        echo "ERROR: Anvil RPC did not become ready in time"
        exit 1
    fi
    sleep 0.5
done

echo "Deploying contracts..."

# Deploy contracts using the local deployment script
cd /app
forge script script/DeployLocal.s.sol:DeployLocal \
    --rpc-url http://127.0.0.1:8545 \
    --broadcast \
    -v

echo ""
echo "=============================================="
echo "  Anvil + Contracts Ready!"
echo "=============================================="
echo ""
echo "  RPC URL:          http://0.0.0.0:8545"
echo "  Chain ID:         31337"
echo ""
echo "  MockERC20:        0x5FbDB2315678afecb367f032d93F642f64180aa3"
echo "  BurnWithDigest:   0xe7f1725E7734CE288F8367e1Bb143E90bb3F0512"
echo ""
echo "  Test Accounts (Anvil defaults):"
echo "  - Deployer:  0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266"
echo "  - Test User: 0x70997970C51812dc3A010C7d01b50e0d17dc79C8 (has ~9,000 mNIL)"
echo ""
echo "=============================================="
echo ""

# Keep the container running by waiting on Anvil
wait $ANVIL_PID
