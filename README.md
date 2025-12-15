# nil-devnet

Local Ethereum development network with NIL token contracts for testing.

**This is for development and CI only. Not for testnet or mainnet.**

## What's Included

- **Anvil** - Local Ethereum node (Foundry)
- **NIL Token** - Test NIL token with mint and burn functions (mimics mainnet)
- **BurnWithDigest** - Payment contract for burning NIL with a digest

## Quick Start

### Using Docker

```bash
docker build -t nil-devnet .
docker run -p 8545:8545 nil-devnet
```

### Development

```bash
# Install dependencies
forge install

# Build contracts
forge build

# Run tests
forge test

# Start Anvil and deploy contracts manually
anvil &
forge script script/DeployLocal.s.sol:DeployLocal --rpc-url http://127.0.0.1:8545 --broadcast
```

## Chain Id

Anvil uses the chain_id `31337`

## Contract Addresses (Deterministic)

When deployed to Anvil with the default accounts, contracts are always at these addresses:

| Contract       | Address                                      |
|----------------|----------------------------------------------|
| NIL            | `0x5FbDB2315678afecb367f032d93F642f64180aa3` |
| BurnWithDigest | `0xe7f1725E7734CE288F8367e1Bb143E90bb3F0512` |

## Test Accounts

Anvil provides 10 pre-funded accounts. After deployment:

| Account       | Address                                      | Balance                 |
|---------------|----------------------------------------------|-------------------------|
| Deployer (0)  | `0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266` | 10,000 ETH              |
| Test User (1) | `0x70997970C51812dc3A010C7d01b50e0d17dc79C8` | 10,000 ETH + ~9,000 NIL |

**Test User Private Key:** `0x59c6995e998f97a5a0044966f0945389dc9e86dae88c7a8412f4603b6b78690d`
