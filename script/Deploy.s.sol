// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import "forge-std/Script.sol";
import "../src/BurnWithDigest.sol";

/**
 * @title DeployBurnWithDigest
 * @notice Deployment script for the BurnWithDigest contract
 * @dev Usage:
 *   Sepolia: forge script script/Deploy.s.sol:DeployBurnWithDigest --rpc-url sepolia --broadcast --verify
 *   Mainnet: forge script script/Deploy.s.sol:DeployBurnWithDigest --rpc-url mainnet --broadcast --verify
 */
contract DeployBurnWithDigest is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address nilTokenAddress = vm.envAddress("NIL_TOKEN_ADDRESS");

        require(nilTokenAddress != address(0), "NIL_TOKEN_ADDRESS env var not set");

        uint256 chainId = block.chainid;
        console.log("Deploying to chain:", chainId);
        console.log("NIL Token address:", nilTokenAddress);

        // Start broadcasting transactions
        vm.startBroadcast(deployerPrivateKey);

        // Deploy the BurnWithDigest contract
        BurnWithDigest burnContract = new BurnWithDigest(nilTokenAddress);

        vm.stopBroadcast();

        // Log deployment information
        console.log("BurnWithDigest deployed at:", address(burnContract));
        console.log("Owner:", burnContract.owner());
        console.log("NIL Token:", address(burnContract.nilToken()));
    }
}
