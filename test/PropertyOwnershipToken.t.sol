// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Test} from "forge-std/Test.sol";
import {PropertyOwnershipToken} from "../src/PropertyOwnershipToken.sol";
import {ERC1967Proxy} from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import {console} from "forge-std/console.sol";

contract PropertyOwnershipTokenTest is Test {
    PropertyOwnershipToken public propertyToken;
    PropertyOwnershipToken public implementation;
    ERC1967Proxy public proxy;
    
    // Test actors
    address public owner;
    address public investor1;
    address public investor2;
    address public investor3;
    address public unauthorizedUser;
    
    // Property configuration
    string constant PROPERTY_ID = "PROP-TEST-001";
    string constant PROPERTY_NAME = "Test Property";
    string constant PROPERTY_ADDRESS = "123 Test Street";
    uint256 constant PROPERTY_VALUATION = 1_000_000_00; // $1M in cents
    uint256 constant TOKEN_SUPPLY = 1_000_000 * 10**18; // 1M tokens
    string constant TOKEN_NAME = "Test Property Token";
    string constant TOKEN_SYMBOL = "TPT";
    
    // Events to test
    event TokensIssued(
        address indexed investor,
        uint256 amount,
        uint256 timestamp,
        string propertyId
    );
    event InvestorWhitelisted(address indexed investor, uint256 timestamp);
    event InvestorRemovedFromWhitelist(address indexed investor, uint256 timestamp);
    event PropertyMetadataUpdated(
        string propertyId,
        string propertyName,
        string propertyAddress,
        uint256 valuation
    );

    function setUp() public {
        // Set up test addresses
        owner = address(this);
        investor1 = makeAddr("investor1");
        investor2 = makeAddr("investor2");
        investor3 = makeAddr("investor3");
        unauthorizedUser = makeAddr("unauthorized");
        
        // Deploy implementation
        implementation = new PropertyOwnershipToken();
        
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
        
        // Deploy proxy
        proxy = new ERC1967Proxy(address(implementation), initData);
        propertyToken = PropertyOwnershipToken(address(proxy));
    }
    
    // ============================================
    // DEPLOYMENT & INITIALIZATION TESTS
    // ============================================
    
    function test_DeploymentInitialization() public view {
        assertEq(propertyToken.propertyId(), PROPERTY_ID);
        assertEq(propertyToken.propertyName(), PROPERTY_NAME);
        assertEq(propertyToken.propertyAddress(), PROPERTY_ADDRESS);
        assertEq(propertyToken.propertyValuation(), PROPERTY_VALUATION);
        assertEq(propertyToken.maxSupply(), TOKEN_SUPPLY);
        assertEq(propertyToken.name(), TOKEN_NAME);
        assertEq(propertyToken.symbol(), TOKEN_SYMBOL);
        assertEq(propertyToken.totalSupply(), 0);
        assertEq(propertyToken.owner(), owner);
        assertTrue(propertyToken.whitelist(owner)); // Owner auto-whitelisted
        assertEq(propertyToken.investorCount(), 0);
    }
    
    function test_RevertWhen_InitializationWithZeroSupply() public {
        PropertyOwnershipToken newImpl = new PropertyOwnershipToken();
        bytes memory initData = abi.encodeWithSelector(
            PropertyOwnershipToken.initialize.selector,
            PROPERTY_ID,
            PROPERTY_NAME,
            PROPERTY_ADDRESS,
            0, // Invalid: zero supply
            PROPERTY_VALUATION,
            TOKEN_NAME,
            TOKEN_SYMBOL
        );
        vm.expectRevert("Token supply must be greater than zero");
        new ERC1967Proxy(address(newImpl), initData);
    }
    
    function test_RevertWhen_InitializationWithEmptyPropertyId() public {
        PropertyOwnershipToken newImpl = new PropertyOwnershipToken();
        bytes memory initData = abi.encodeWithSelector(
            PropertyOwnershipToken.initialize.selector,
            "", // Invalid: empty property ID
            PROPERTY_NAME,
            PROPERTY_ADDRESS,
            TOKEN_SUPPLY,
            PROPERTY_VALUATION,
            TOKEN_NAME,
            TOKEN_SYMBOL
        );
        vm.expectRevert("Property ID required");
        new ERC1967Proxy(address(newImpl), initData);
    }
    
    function test_RevertWhen_InitializationWithZeroValuation() public {
        PropertyOwnershipToken newImpl = new PropertyOwnershipToken();
        bytes memory initData = abi.encodeWithSelector(
            PropertyOwnershipToken.initialize.selector,
            PROPERTY_ID,
            PROPERTY_NAME,
            PROPERTY_ADDRESS,
            TOKEN_SUPPLY,
            0, // Invalid: zero valuation
            TOKEN_NAME,
            TOKEN_SYMBOL
        );
        vm.expectRevert("Property valuation required");
        new ERC1967Proxy(address(newImpl), initData);
    }
    
    // ============================================
    // WHITELIST TESTS
    // ============================================
    
    function test_AddToWhitelist() public {
        vm.expectEmit(true, false, false, true);
        emit InvestorWhitelisted(investor1, block.timestamp);
        
        propertyToken.addToWhitelist(investor1);
        
        assertTrue(propertyToken.whitelist(investor1));
        assertTrue(propertyToken.isWhitelisted(investor1));
    }
    
    function test_RemoveFromWhitelist() public {
        propertyToken.addToWhitelist(investor1);
        
        vm.expectEmit(true, false, false, true);
        emit InvestorRemovedFromWhitelist(investor1, block.timestamp);
        
        propertyToken.removeFromWhitelist(investor1);
        
        assertFalse(propertyToken.whitelist(investor1));
        assertFalse(propertyToken.isWhitelisted(investor1));
    }
    
    function test_BatchAddToWhitelist() public {
        address[] memory investors = new address[](3);
        investors[0] = investor1;
        investors[1] = investor2;
        investors[2] = investor3;
        
        propertyToken.batchAddToWhitelist(investors);
        
        assertTrue(propertyToken.isWhitelisted(investor1));
        assertTrue(propertyToken.isWhitelisted(investor2));
        assertTrue(propertyToken.isWhitelisted(investor3));
    }
    
    function test_RevertWhen_AddToWhitelistUnauthorized() public {
        vm.prank(unauthorizedUser);
        vm.expectRevert();
        propertyToken.addToWhitelist(investor1);
    }
    
    function test_RevertWhen_AddToWhitelistZeroAddress() public {
        vm.expectRevert("Invalid address");
        propertyToken.addToWhitelist(address(0));
    }
    
    function test_RevertWhen_AddToWhitelistAlreadyWhitelisted() public {
        propertyToken.addToWhitelist(investor1);
        vm.expectRevert("Already whitelisted");
        propertyToken.addToWhitelist(investor1);
    }
    
    function test_RevertWhen_RemoveFromWhitelistNotWhitelisted() public {
        vm.expectRevert("Not whitelisted");
        propertyToken.removeFromWhitelist(investor1);
    }
    
    // ============================================
    // TOKEN ISSUANCE TESTS
    // ============================================
    
    function test_IssueTokens() public {
        propertyToken.addToWhitelist(investor1);
        uint256 amount = 100_000 * 10**18;
        
        vm.expectEmit(true, false, false, true);
        emit TokensIssued(investor1, amount, block.timestamp, PROPERTY_ID);
        
        propertyToken.issueTokens(investor1, amount);
        
        assertEq(propertyToken.balanceOf(investor1), amount);
        assertEq(propertyToken.totalSupply(), amount);
        assertEq(propertyToken.investorCount(), 1);
    }
    
    function test_IssueTokensMultipleInvestors() public {
        propertyToken.addToWhitelist(investor1);
        propertyToken.addToWhitelist(investor2);
        
        uint256 amount1 = 300_000 * 10**18;
        uint256 amount2 = 200_000 * 10**18;
        
        propertyToken.issueTokens(investor1, amount1);
        propertyToken.issueTokens(investor2, amount2);
        
        assertEq(propertyToken.balanceOf(investor1), amount1);
        assertEq(propertyToken.balanceOf(investor2), amount2);
        assertEq(propertyToken.totalSupply(), amount1 + amount2);
        assertEq(propertyToken.investorCount(), 2);
    }
    
    function test_IssueTokensMultipleTimesToSameInvestor() public {
        propertyToken.addToWhitelist(investor1);
        
        uint256 amount1 = 50_000 * 10**18;
        uint256 amount2 = 30_000 * 10**18;
        
        propertyToken.issueTokens(investor1, amount1);
        propertyToken.issueTokens(investor1, amount2);
        
        assertEq(propertyToken.balanceOf(investor1), amount1 + amount2);
        assertEq(propertyToken.investorCount(), 1); // Same investor
    }
    
    function test_RevertWhen_IssueTokensNotWhitelisted() public {
        vm.expectRevert("Investor must be whitelisted before issuance");
        propertyToken.issueTokens(investor1, 100_000 * 10**18);
    }
    
    function test_RevertWhen_IssueTokensZeroAmount() public {
        propertyToken.addToWhitelist(investor1);
        vm.expectRevert("Amount must be greater than zero");
        propertyToken.issueTokens(investor1, 0);
    }
    
    function test_RevertWhen_IssueTokensExceedsSupply() public {
        propertyToken.addToWhitelist(investor1);
        vm.expectRevert("Exceeds maximum token supply");
        propertyToken.issueTokens(investor1, TOKEN_SUPPLY + 1);
    }
    
    function test_RevertWhen_IssueTokensUnauthorized() public {
        propertyToken.addToWhitelist(investor1);
        vm.prank(unauthorizedUser);
        vm.expectRevert();
        propertyToken.issueTokens(investor1, 100_000 * 10**18);
    }
    
    function test_RevertWhen_IssueTokensToZeroAddress() public {
        vm.expectRevert("Invalid investor address");
        propertyToken.issueTokens(address(0), 100_000 * 10**18);
    }
    
    // ============================================
    // TRANSFER RESTRICTION TESTS
    // ============================================
    
    function test_TransferBetweenWhitelistedInvestors() public {
        propertyToken.addToWhitelist(investor1);
        propertyToken.addToWhitelist(investor2);
        
        uint256 amount = 100_000 * 10**18;
        propertyToken.issueTokens(investor1, amount);
        
        vm.prank(investor1);
        propertyToken.transfer(investor2, 50_000 * 10**18);
        
        assertEq(propertyToken.balanceOf(investor1), 50_000 * 10**18);
        assertEq(propertyToken.balanceOf(investor2), 50_000 * 10**18);
    }
    
    function test_RevertWhen_TransferToNonWhitelistedAddress() public {
        propertyToken.addToWhitelist(investor1);
        propertyToken.issueTokens(investor1, 100_000 * 10**18);
        
        vm.prank(investor1);
        vm.expectRevert("Recipient not whitelisted for token transfer");
        propertyToken.transfer(investor2, 50_000 * 10**18);
    }
    
    function test_RevertWhen_TransferFromNonWhitelistedAddress() public {
        propertyToken.addToWhitelist(investor1);
        propertyToken.addToWhitelist(investor2);
        propertyToken.issueTokens(investor1, 100_000 * 10**18);
        
        propertyToken.removeFromWhitelist(investor1);
        
        vm.prank(investor1);
        vm.expectRevert("Sender not whitelisted for token transfer");
        propertyToken.transfer(investor2, 50_000 * 10**18);
    }
    
    function test_ApproveAndTransferFrom() public {
        propertyToken.addToWhitelist(investor1);
        propertyToken.addToWhitelist(investor2);
        propertyToken.issueTokens(investor1, 100_000 * 10**18);
        
        vm.prank(investor1);
        propertyToken.approve(investor2, 50_000 * 10**18);
        
        vm.prank(investor2);
        propertyToken.transferFrom(investor1, investor2, 50_000 * 10**18);
        
        assertEq(propertyToken.balanceOf(investor2), 50_000 * 10**18);
    }
    
    // ============================================
    // PAUSE/UNPAUSE TESTS
    // ============================================
    
    function test_PauseAndUnpause() public {
        propertyToken.pause();
        assertTrue(propertyToken.paused());
        
        propertyToken.unpause();
        assertFalse(propertyToken.paused());
    }
    
    function test_RevertWhen_IssueTokensWhenPaused() public {
        propertyToken.addToWhitelist(investor1);
        propertyToken.pause();
        vm.expectRevert();
        propertyToken.issueTokens(investor1, 100_000 * 10**18);
    }
    
    function test_RevertWhen_TransferWhenPaused() public {
        propertyToken.addToWhitelist(investor1);
        propertyToken.addToWhitelist(investor2);
        propertyToken.issueTokens(investor1, 100_000 * 10**18);
        
        propertyToken.pause();
        
        vm.prank(investor1);
        vm.expectRevert();
        propertyToken.transfer(investor2, 50_000 * 10**18);
    }
    
    function test_RevertWhen_PauseUnauthorized() public {
        vm.prank(unauthorizedUser);
        vm.expectRevert();
        propertyToken.pause();
    }
    
    // ============================================
    // PROPERTY METADATA TESTS
    // ============================================
    
    function test_UpdatePropertyMetadata() public {
        string memory newName = "Updated Property Name";
        string memory newAddress = "456 New Street";
        uint256 newValuation = 1_500_000_00; // $1.5M
        
        vm.expectEmit(false, false, false, true);
        emit PropertyMetadataUpdated(PROPERTY_ID, newName, newAddress, newValuation);
        
        propertyToken.updatePropertyMetadata(newName, newAddress, newValuation);
        
        assertEq(propertyToken.propertyName(), newName);
        assertEq(propertyToken.propertyAddress(), newAddress);
        assertEq(propertyToken.propertyValuation(), newValuation);
        assertEq(propertyToken.propertyId(), PROPERTY_ID); // ID should not change
    }
    
    function test_RevertWhen_UpdatePropertyMetadataUnauthorized() public {
        vm.prank(unauthorizedUser);
        vm.expectRevert();
        propertyToken.updatePropertyMetadata("New Name", "New Address", 2_000_000_00);
    }
    
    function test_RevertWhen_UpdatePropertyMetadataZeroValuation() public {
        vm.expectRevert("Valuation must be positive");
        propertyToken.updatePropertyMetadata("New Name", "New Address", 0);
    }
    
    // ============================================
    // VIEW FUNCTION TESTS
    // ============================================
    
    function test_GetOwnershipPercentage() public {
        propertyToken.addToWhitelist(investor1);
        propertyToken.addToWhitelist(investor2);
        
        propertyToken.issueTokens(investor1, 300_000 * 10**18); // 30%
        propertyToken.issueTokens(investor2, 700_000 * 10**18); // 70%
        
        uint256 investor1Percentage = propertyToken.getOwnershipPercentage(investor1);
        uint256 investor2Percentage = propertyToken.getOwnershipPercentage(investor2);
        
        // 30% = 0.3 * 10^18
        assertEq(investor1Percentage, 3 * 10**17);
        assertEq(investor2Percentage, 7 * 10**17);
    }
    
    function test_GetInvestorPropertyValue() public {
        propertyToken.addToWhitelist(investor1);
        propertyToken.addToWhitelist(investor2);
        
        // Issue to both investors so investor1 has 30% of total issued
        propertyToken.issueTokens(investor1, 300_000 * 10**18); // 30% 
        propertyToken.issueTokens(investor2, 700_000 * 10**18); // 70%
        
        uint256 propertyValue = propertyToken.getInvestorPropertyValue(investor1);
        
        // 30% of $1M = $300,000 (30000000 cents)
        assertEq(propertyValue, 300_000_00);
    }
    
    function test_RemainingSupply() public {
        propertyToken.addToWhitelist(investor1);
        propertyToken.issueTokens(investor1, 400_000 * 10**18);
        
        uint256 remaining = propertyToken.remainingSupply();
        assertEq(remaining, 600_000 * 10**18);
    }
    
    function test_GetPropertyInfo() public {
        propertyToken.addToWhitelist(investor1);
        propertyToken.issueTokens(investor1, 250_000 * 10**18);
        
        (
            string memory id,
            string memory name,
            string memory addr,
            uint256 valuation,
            uint256 supply,
            uint256 issued,
            uint256 investors
        ) = propertyToken.getPropertyInfo();
        
        assertEq(id, PROPERTY_ID);
        assertEq(name, PROPERTY_NAME);
        assertEq(addr, PROPERTY_ADDRESS);
        assertEq(valuation, PROPERTY_VALUATION);
        assertEq(supply, TOKEN_SUPPLY);
        assertEq(issued, 250_000 * 10**18);
        assertEq(investors, 1);
    }
    
    // ============================================
    // EDGE CASE & INTEGRATION TESTS
    // ============================================
    
    function test_CompleteInvestmentFlow() public {
        // 1. Whitelist investors
        propertyToken.addToWhitelist(investor1);
        propertyToken.addToWhitelist(investor2);
        propertyToken.addToWhitelist(investor3);
        
        // 2. Issue tokens
        propertyToken.issueTokens(investor1, 400_000 * 10**18); // 40%
        propertyToken.issueTokens(investor2, 350_000 * 10**18); // 35%
        propertyToken.issueTokens(investor3, 250_000 * 10**18); // 25%
        
        // 3. Verify state
        assertEq(propertyToken.totalSupply(), TOKEN_SUPPLY);
        assertEq(propertyToken.investorCount(), 3);
        assertEq(propertyToken.remainingSupply(), 0);
        
        // 4. Test transfers
        vm.prank(investor1);
        propertyToken.transfer(investor2, 100_000 * 10**18);
        
        assertEq(propertyToken.balanceOf(investor1), 300_000 * 10**18);
        assertEq(propertyToken.balanceOf(investor2), 450_000 * 10**18);
        
        // 5. Verify ownership percentages
        assertEq(propertyToken.getOwnershipPercentage(investor1), 3 * 10**17); // 30%
        assertEq(propertyToken.getOwnershipPercentage(investor2), 45 * 10**16); // 45%
        assertEq(propertyToken.getOwnershipPercentage(investor3), 25 * 10**16); // 25%
    }
    
    function test_EmergencyPauseScenario() public {
        propertyToken.addToWhitelist(investor1);
        propertyToken.issueTokens(investor1, 500_000 * 10**18);
        
        // Emergency: pause all operations
        propertyToken.pause();
        
        // Try to issue more tokens (should fail)
        vm.expectRevert();
        propertyToken.issueTokens(investor1, 100_000 * 10**18);
        
        // Unpause after resolving issue
        propertyToken.unpause();
        
        // Now can issue again
        propertyToken.issueTokens(investor1, 100_000 * 10**18);
        assertEq(propertyToken.balanceOf(investor1), 600_000 * 10**18);
    }
    
    function testFuzz_IssueTokensWithinLimit(uint256 amount) public {
        vm.assume(amount > 0 && amount <= TOKEN_SUPPLY);
        
        propertyToken.addToWhitelist(investor1);
        propertyToken.issueTokens(investor1, amount);
        
        assertEq(propertyToken.balanceOf(investor1), amount);
        assertEq(propertyToken.totalSupply(), amount);
    }
    
    function testFuzz_OwnershipPercentageCalculation(uint256 investorBalance) public {
        vm.assume(investorBalance > 0 && investorBalance <= TOKEN_SUPPLY);
        
        propertyToken.addToWhitelist(investor1);
        propertyToken.issueTokens(investor1, investorBalance);
        
        uint256 percentage = propertyToken.getOwnershipPercentage(investor1);
        uint256 expectedPercentage = (investorBalance * 1e18) / investorBalance;
        
        assertEq(percentage, expectedPercentage);
    }
}
