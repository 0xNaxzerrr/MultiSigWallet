// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "forge-std/Script.sol";
import "../src/MultiSigWallet.sol";

contract DeployMultiSigWallet is Script {
    function run() external {
        // Get the private key from the .env
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        
        // Generate signers addresses
        address signer1 = vm.addr(1);
        address signer2 = vm.addr(2);
        address signer3 = vm.addr(3);
        
        address[] memory initialSigners = new address[](3);
        initialSigners[0] = signer1;
        initialSigners[1] = signer2;
        initialSigners[2] = signer3;

        vm.startBroadcast(deployerPrivateKey);

        // Deploy wallets
        MultiSigWallet wallet = new MultiSigWallet(initialSigners);
        
        vm.stopBroadcast();

        console.log("MultiSigWallet deployed at:", address(wallet));
        console.log("Initial signers:");
        console.log("Signer 1:", signer1);
        console.log("Signer 2:", signer2);
        console.log("Signer 3:", signer3);
    }
}