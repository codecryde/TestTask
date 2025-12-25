// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Script} from "forge-std/Script.sol";
import {PropertyOwnershipToken} from "../src/PropertyOwnershipToken.sol";
import {UUPSUpgradeable} from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import {console} from "forge-std/console.sol";

/**
 * @title UpgradePropertyOwnershipTokenScript
 * @notice Script to upgrade an existing PropertyOwnershipToken proxy to a new implementation
 * @dev Run with: forge script script/UpgradePropertyOwnershipToken.s.sol:UpgradePropertyOwnershipTokenScript --rpc-url <RPC_URL> --broadcast
 * 
 * USAGE:
 * 1. Set PROXY_ADDRESS environment variable to your deployed proxy address
 * 2. Deploy new implementation version (if needed, update PropertyOwnershipToken.sol)
 * 3. Run this script to upgrade the proxy to point to new implementation
 * 4. Verify the upgrade was successful
 */
contract UpgradePropertyOwnershipTokenScript is Script {
    
    function run() public {
        // Get proxy address from environment variable
        address proxyAddress = vm.envAddress("PROXY_ADDRESS");
        require(proxyAddress != address(0), "PROXY_ADDRESS not set");
        
        console.log("=== Upgrading PropertyOwnershipToken ===");
        console.log("Proxy Address:", proxyAddress);
        
        // Get existing proxy contract
        PropertyOwnershipToken proxy = PropertyOwnershipToken(proxyAddress);
        
        // Log current state before upgrade
        console.log("\n--- Current State ---");
        console.log("Current Owner:", proxy.owner());
        console.log("Current Version:", proxy.version());
        console.log("Property ID:", proxy.propertyId());
        console.log("Total Supply:", proxy.totalSupply());
        console.log("Max Supply:", proxy.maxSupply());
        
        vm.startBroadcast();
        
        // Deploy new implementation
        console.log("\nDeploying new implementation...");
        PropertyOwnershipToken newImplementation = new PropertyOwnershipToken();
        console.log("New Implementation Address:", address(newImplementation));
        
        // Upgrade proxy to new implementation
        console.log("\nUpgrading proxy to new implementation...");
        proxy.upgradeToAndCall(address(newImplementation), "");
        
        vm.stopBroadcast();
        
        // Verify upgrade
        console.log("\n--- Post-Upgrade State ---");
        console.log("Owner (should be same):", proxy.owner());
        console.log("Version (check if updated):", proxy.version());
        console.log("Property ID (should be same):", proxy.propertyId());
        console.log("Total Supply (should be same):", proxy.totalSupply());
        console.log("Max Supply (should be same):", proxy.maxSupply());
        
        console.log("\n=== Upgrade Complete ===");
        console.log("Proxy:", proxyAddress);
        console.log("New Implementation:", address(newImplementation));
        console.log("\nIMPORTANT: Verify contract on block explorer");
        console.log("IMPORTANT: Test all functions to ensure upgrade was successful");
    }
    
    /**
     * @notice Upgrade with additional initialization data (if new version needs it)
     * @dev Use this if the new implementation has a reinitialize function
     */
    function upgradeWithData() public {
        address proxyAddress = vm.envAddress("PROXY_ADDRESS");
        require(proxyAddress != address(0), "PROXY_ADDRESS not set");
        
        PropertyOwnershipToken proxy = PropertyOwnershipToken(proxyAddress);
        
        vm.startBroadcast();
        
        // Deploy new implementation
        PropertyOwnershipToken newImplementation = new PropertyOwnershipToken();
        
        // Prepare any initialization data for the new version
        // bytes memory initData = abi.encodeWithSelector(
        //     PropertyOwnershipToken.reinitialize.selector,
        //     // ... new parameters if needed
        // );
        
        // For this example, we're not calling any reinitialize function
        bytes memory initData = "";
        
        // Upgrade with initialization data
        proxy.upgradeToAndCall(address(newImplementation), initData);
        
        vm.stopBroadcast();
        
        console.log("Upgraded with data to:", address(newImplementation));
    }
}
