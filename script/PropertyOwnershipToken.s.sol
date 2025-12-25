// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Script} from "forge-std/Script.sol";
import {PropertyOwnershipToken} from "../src/PropertyOwnershipToken.sol";
import {ERC1967Proxy} from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import {console} from "forge-std/console.sol";

/**
 * @title PropertyOwnershipTokenScript
 * @notice Deployment script for PropertyOwnershipToken contract
 * @dev Run with: forge script script/PropertyOwnershipToken.s.sol:PropertyOwnershipTokenScript --rpc-url <RPC_URL> --broadcast
 */
contract PropertyOwnershipTokenScript is Script {
    PropertyOwnershipToken public propertyToken;
    PropertyOwnershipToken public implementation;
    ERC1967Proxy public proxy;

    // ============================================
    // DEPLOYMENT CONFIGURATION
    // ============================================
    
    // Property Details
    string constant PROPERTY_ID = "PROP-001-NYC-MANHATTAN";
    string constant PROPERTY_NAME = "Sunset Villa Manhattan";
    string constant PROPERTY_ADDRESS = "123 Park Avenue, New York, NY 10001";
    uint256 constant PROPERTY_VALUATION = 5_000_000_00; // $5,000,000 in cents
    
    // Token Details
    uint256 constant TOKEN_SUPPLY = 1_000_000 * 10**18; // 1 million tokens (18 decimals)
    string constant TOKEN_NAME = "Sunset Villa Ownership Token";
    string constant TOKEN_SYMBOL = "SVILLA";
    
    // Initial Investors (can be modified per deployment)
    address[] public initialInvestors;

    function setUp() public {
        // Add initial investors to whitelist (optional)
        // These would be KYC-verified addresses in production
        // initialInvestors.push(0x1234567890123456789012345678901234567890);
        // initialInvestors.push(0x2345678901234567890123456789012345678901);
    }

    function run() public {
        // Start broadcasting transactions
        // Uses private key passed via --private-key flag
        vm.startBroadcast();

        // Deploy the PropertyOwnershipToken implementation
        console.log("Deploying PropertyOwnershipToken Implementation...");
        console.log("Property ID:", PROPERTY_ID);
        console.log("Property Valuation: $", PROPERTY_VALUATION / 100);
        console.log("Token Supply:", TOKEN_SUPPLY);
        
        implementation = new PropertyOwnershipToken();
        console.log("Implementation deployed at:", address(implementation));
        
        // Prepare initialization data
        bytes memory initData = abi.encodeWithSelector(
            PropertyOwnershipToken.initialize.selector,
            PROPERTY_ID,
            PROPERTY_NAME,
            PROPERTY_ADDRESS,
            TOKEN_SUPPLY,
            PROPERTY_VALUATION,
            TOKEN_NAME,
            TOKEN_SYMBOL
        );
        
        // Deploy proxy pointing to implementation
        proxy = new ERC1967Proxy(address(implementation), initData);
        propertyToken = PropertyOwnershipToken(address(proxy));

        console.log("Proxy deployed at:", address(proxy));
        console.log("PropertyOwnershipToken (via proxy) at:", address(propertyToken));
        
        // Whitelist initial investors if any
        if (initialInvestors.length > 0) {
            console.log("Whitelisting initial investors...");
            propertyToken.batchAddToWhitelist(initialInvestors);
            console.log("Whitelisted", initialInvestors.length, "investors");
        }
        
        // Log deployment details
        console.log("\n=== Deployment Summary ===");
        console.log("Implementation Address:", address(implementation));
        console.log("Proxy Address:", address(proxy));
        console.log("Contract Address (use this):", address(propertyToken));
        console.log("Property ID:", propertyToken.propertyId());
        console.log("Property Name:", propertyToken.propertyName());
        console.log("Token Symbol:", propertyToken.symbol());
        console.log("Max Supply:", propertyToken.maxSupply());
        console.log("Deployer (Owner):", propertyToken.owner());
        console.log("Deployment Timestamp:", propertyToken.deploymentTimestamp());
        console.log("Version:", propertyToken.version());

        vm.stopBroadcast();
        
        console.log("\n=== Next Steps ===");
        console.log("1. Verify implementation and proxy on block explorer");
        console.log("2. Add investors to whitelist: propertyToken.addToWhitelist(address)");
        console.log("3. Issue tokens: propertyToken.issueTokens(investor, amount)");
        console.log("4. Save PROXY address to backend config (not implementation)");
        console.log("5. To upgrade: deploy new implementation, call upgradeToAndCall on proxy");
    }
    
    /**
     * @notice Alternative deployment function for custom parameters
     * @dev Useful for deploying different properties without modifying script
     */
    function deployCustomProperty(
        string memory _propertyId,
        string memory _propertyName,
        string memory _propertyAddress,
        uint256 _tokenSupply,
        uint256 _propertyValuation,
        string memory _tokenName,
        string memory _tokenSymbol
    ) public {
        vm.startBroadcast();

        // Deploy implementation
        implementation = new PropertyOwnershipToken();
        
        // Prepare initialization data
        bytes memory initData = abi.encodeWithSelector(
            PropertyOwnershipToken.initialize.selector,
            _propertyId,
            _propertyName,
            _propertyAddress,
            _tokenSupply,
            _propertyValuation,
            _tokenName,
            _tokenSymbol
        );
        
        // Deploy proxy
        proxy = new ERC1967Proxy(address(implementation), initData);
        propertyToken = PropertyOwnershipToken(address(proxy));

        console.log("Custom PropertyOwnershipToken deployed at:", address(propertyToken));
        console.log("Implementation:", address(implementation));
        console.log("Proxy:", address(proxy));

        vm.stopBroadcast();
    }
}
