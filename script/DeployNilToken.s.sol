// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import "forge-std/Script.sol";
import "../test/BurnWithDigest.t.sol";

/**
 * @title DeployNilToken
 * @notice Deploys a mock NIL token for testnet use
 * @dev Usage:
 *   forge script script/DeployNilToken.s.sol:DeployNilToken --rpc-url sepolia --broadcast -vvv
 */
contract DeployNilToken is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address deployer = vm.addr(deployerPrivateKey);

        console.log("Deploying NIL token to chain:", block.chainid);
        console.log("Deployer:", deployer);

        vm.startBroadcast(deployerPrivateKey);

        NIL token = new NIL();

        vm.stopBroadcast();

        console.log("");
        console.log("NIL Token deployed at:", address(token));
        console.log("Total supply:", token.totalSupply() / 1e18, "NIL");
        console.log("Deployer balance:", token.balanceOf(deployer) / 1e18, "NIL");
        console.log("");
        console.log("Next step: Update NIL_TOKEN_SEPOLIA in Deploy.s.sol with this address");
    }
}
