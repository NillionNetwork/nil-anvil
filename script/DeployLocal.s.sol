// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import "forge-std/Script.sol";
import "../src/BurnWithDigest.sol";
import "../test/BurnWithDigest.t.sol"; // For NIL token

/**
 * @title DeployLocal
 * @notice Comprehensive local deployment script for testing the entire flow
 * @dev Deploys NIL token, BurnWithDigest contract, and executes a test burn
 *
 * Usage:
 *   Terminal 1: anvil
 *   Terminal 2: forge script script/DeployLocal.s.sol:DeployLocal --rpc-url http://127.0.0.1:8545 --broadcast -vvvv
 */
contract DeployLocal is Script {
    function run() external {
        // Anvil's default accounts (all have 10,000 ETH)
        address deployer = 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266; // Anvil account 0
        address testUser = 0x70997970C51812dc3A010C7d01b50e0d17dc79C8; // Anvil account 1

        console.log("=== Local Deployment Script ===");
        console.log("Deployer:", deployer);
        console.log("Test User:", testUser);
        console.log("");

        // Use Anvil's default private key for account 0
        uint256 deployerPrivateKey = 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80;

        vm.startBroadcast(deployerPrivateKey);

        // 1. Deploy NIL Token
        console.log("Step 1: Deploying NIL Token...");
        NIL nilToken = new NIL();
        console.log("  NIL Token deployed at:", address(nilToken));
        console.log("  Total Supply:", nilToken.totalSupply() / 1e18, "NIL");
        console.log("");

        // 2. Deploy BurnWithDigest Contract
        console.log("Step 2: Deploying BurnWithDigest Contract...");
        BurnWithDigest burnContract = new BurnWithDigest(address(nilToken));
        console.log("  BurnWithDigest deployed at:", address(burnContract));
        console.log("  Owner:", burnContract.owner());
        console.log("  Dead Address:", burnContract.DEAD_ADDRESS());
        console.log("");

        // 3. Mint tokens to test user
        console.log("Step 3: Minting tokens to test user...");
        uint256 mintAmount = 10000 * 1e18; // 10,000 NIL
        nilToken.mint(testUser, mintAmount);
        console.log("  Minted", mintAmount / 1e18, "NIL to", testUser);
        console.log("  Test user balance:", nilToken.balanceOf(testUser) / 1e18, "NIL");
        console.log("");

        vm.stopBroadcast();

        // 4. Test a burn (as the test user)
        console.log("Step 4: Testing burnWithDigest...");
        uint256 testUserKey = 0x59c6995e998f97a5a0044966f0945389dc9e86dae88c7a8412f4603b6b78690d; // Anvil account 1
        vm.startBroadcast(testUserKey);

        // Create a test payment digest
        bytes32 testDigest = keccak256(abi.encodePacked("test_payment", block.timestamp, testUser));

        uint256 burnAmount = 1000 * 1e18; // 1000 NIL

        // Approve burn contract
        console.log("  Approving BurnWithDigest to spend", burnAmount / 1e18, "NIL...");
        nilToken.approve(address(burnContract), burnAmount);

        // Execute burn
        console.log("  Executing burnWithDigest...");
        console.log("    Amount:", burnAmount / 1e18, "NIL");
        console.log("    Digest:", vm.toString(testDigest));

        burnContract.burnWithDigest(burnAmount, testDigest);

        vm.stopBroadcast();

        // 5. Verify results
        console.log("");
        console.log("Step 5: Verifying Results...");
        console.log("  Test user balance after burn:", nilToken.balanceOf(testUser) / 1e18, "NIL");
        console.log("  Dead address balance:", nilToken.balanceOf(burnContract.DEAD_ADDRESS()) / 1e18, "NIL");
        console.log("");

        // 6. Output deployment info for nilauth configuration
        console.log("=== Configuration for nilauth ===");
        console.log("ethereum_rpc_url: http://127.0.0.1:8545");
        console.log("nil_token_address:", vm.toString(address(nilToken)));
        console.log("burn_contract_address:", vm.toString(address(burnContract)));
        console.log("chain_id: 31337");
        console.log("");

        // 7. Output environment variables for nilpay
        console.log("=== Environment Variables for nilpay ===");
        console.log("NEXT_PUBLIC_NIL_TOKEN_ADDRESS=", vm.toString(address(nilToken)));
        console.log("NEXT_PUBLIC_BURN_CONTRACT_ADDRESS=", vm.toString(address(burnContract)));
        console.log("NEXT_PUBLIC_ETHEREUM_RPC_URL=http://127.0.0.1:8545");
        console.log("NEXT_PUBLIC_CHAIN_ID=31337");
        console.log("");

        // Note: File writing removed to avoid "stack too deep" in coverage
        // All deployment info is logged above
        console.log("");
        console.log("=== Deployment Complete! ===");
    }
}
