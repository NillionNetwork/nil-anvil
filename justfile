# nil-devnet justfile

# Default recipe - show available commands
default:
    @just --list

# Install dependencies
install:
    forge install

# Build contracts
build:
    forge build

# Run tests
test:
    forge test

# Run tests with verbose output
test-v:
    forge test -vvvv

# Run tests with gas reporting
test-gas:
    forge test --gas-report

# Start local Anvil node
anvil:
    anvil

# Deploy contracts to local Anvil (requires anvil running)
deploy-local:
    forge script script/DeployLocal.s.sol:DeployLocal --rpc-url http://127.0.0.1:8545 --broadcast

# Deploy with verbose output
deploy-local-v:
    forge script script/DeployLocal.s.sol:DeployLocal --rpc-url http://127.0.0.1:8545 --broadcast -vvvv

# Build Docker image
docker-build:
    docker build -t public.ecr.aws/k5d9x2g2/nil-anvil:local .

# Run Docker container
docker-run:
    docker run -p 8545:8545 public.ecr.aws/k5d9x2g2/nil-anvil:local

# Build and run Docker container
docker: docker-build docker-run

# Clean build artifacts
clean:
    forge clean

# Format Solidity code
fmt:
    forge fmt

# Check formatting
fmt-check:
    forge fmt --check

# Deploy NIL token to Sepolia (requires PRIVATE_KEY in .env)
deploy-token-sepolia:
    source .env && forge script script/DeployNilToken.s.sol:DeployNilToken \
        --rpc-url "${SEPOLIA_RPC_URL}" \
        --broadcast \
        -vvv

# Deploy BurnWithDigest to Sepolia (requires PRIVATE_KEY in .env and NIL_TOKEN_SEPOLIA set in Deploy.s.sol)
deploy-sepolia:
    source .env && forge script script/Deploy.s.sol:DeployBurnWithDigest \
        --rpc-url "${SEPOLIA_RPC_URL}" \
        --broadcast \
        -vvv

# Deploy BurnWithDigest to Sepolia with Etherscan verification
deploy-sepolia-verify:
    source .env && forge script script/Deploy.s.sol:DeployBurnWithDigest \
        --rpc-url "${SEPOLIA_RPC_URL}" \
        --broadcast \
        --verify \
        -vvv
