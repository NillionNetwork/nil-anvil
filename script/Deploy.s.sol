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
    // NIL Token addresses (update these with actual addresses)
    address constant NIL_TOKEN_SEPOLIA = address(0); // TODO: Replace with actual Sepolia NIL token address
    address constant NIL_TOKEN_MAINNET = address(0); // TODO: Replace with actual Mainnet NIL token address

    function run() external {
        // Get the deployer's private key from environment
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");

        // Determine which network we're on
        uint256 chainId = block.chainid;
        address nilTokenAddress;

        if (chainId == 11155111) {
            // Sepolia
            nilTokenAddress = NIL_TOKEN_SEPOLIA;
            require(nilTokenAddress != address(0), "Sepolia NIL token address not set");
            console.log("Deploying to Sepolia...");
        } else if (chainId == 1) {
            // Mainnet
            nilTokenAddress = NIL_TOKEN_MAINNET;
            require(nilTokenAddress != address(0), "Mainnet NIL token address not set");
            console.log("Deploying to Mainnet...");
        } else {
            revert("Unsupported network");
        }

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

        // Log the deployment info to a file for easy reference
        string memory deploymentInfo = string.concat(
            "Chain ID: ",
            vm.toString(chainId),
            "\n",
            "BurnWithDigest: ",
            vm.toString(address(burnContract)),
            "\n",
            "NIL Token: ",
            vm.toString(nilTokenAddress),
            "\n",
            "Owner: ",
            vm.toString(burnContract.owner()),
            "\n"
        );

        vm.writeFile("./deployments/latest.txt", deploymentInfo);
    }
}
