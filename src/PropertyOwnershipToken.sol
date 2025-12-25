// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";

/**
 * @title PropertyOwnershipToken
 * @dev ERC-20 token representing fractional ownership of a real estate property
 * 
 * COMPLIANCE CONSIDERATIONS:
 * - This contract includes a whitelist mechanism to ensure only KYC-verified investors can hold tokens
 * - In production, integrate with an off-chain KYC provider (e.g., Onfido, Jumio)
 * - Consider jurisdiction-specific requirements (Reg D, Reg S, etc.)
 * - Implement accredited investor verification before adding to whitelist
 * - Token transfers should log events for regulatory reporting
 * 
 * SECURITY NOTES:
 * - Uses OpenZeppelin's audited contracts as foundation
 * - Pausable pattern allows emergency stops
 * - Whitelist prevents unauthorized token holders
 * - Owner controls are centralized; consider multi-sig wallet in production
 * 
 * UPGRADE STRATEGY:
 * - Uses UUPS (Universal Upgradeable Proxy Standard) proxy pattern
 * - Only owner can authorize upgrades via _authorizeUpgrade function
 * - Storage layout must be preserved in upgrades (no reordering/deletion of variables)
 * - Use storage gaps for future variable additions
 * - Audit required before deploying upgrades
 */

contract PropertyOwnershipToken is 
    Initializable,
    ERC20Upgradeable, 
    OwnableUpgradeable, 
    PausableUpgradeable,
    UUPSUpgradeable 
{
    
    // ============================================
    // STATE VARIABLES
    // ============================================
    
    /// @notice Unique identifier for the property (can be linked to off-chain DB)
    string public propertyId;
    
    /// @notice Physical address of the property
    string public propertyAddress;
    
    /// @notice Property name/description
    string public propertyName;
    
    /// @notice Total property valuation in USD (stored in cents to avoid decimals)
    uint256 public propertyValuation;
    
    /// @notice Fixed token supply set at deployment (represents total ownership)
    uint256 public maxSupply;
    
    /// @notice Mapping of addresses allowed to hold tokens (KYC whitelist)
    mapping(address => bool) public whitelist;
    
    /// @notice Timestamp when the contract was deployed
    uint256 public deploymentTimestamp;
    
    /// @notice Total number of investors who have received tokens
    uint256 public investorCount;
    
    /// @notice Mapping to track if an investor has been counted
    mapping(address => bool) private hasInvested;
    
    /// @dev Storage gap for future upgrades (allows adding new state variables)
    uint256[50] private __gap;
    
    // ============================================
    // EVENTS
    // ============================================
    
    /// @notice Emitted when tokens are issued to an investor
    event TokensIssued(
        address indexed investor,
        uint256 amount,
        uint256 timestamp,
        string propertyId
    );
    
    /// @notice Emitted when an investor is added to the whitelist
    event InvestorWhitelisted(
        address indexed investor,
        uint256 timestamp
    );
    
    /// @notice Emitted when an investor is removed from the whitelist
    event InvestorRemovedFromWhitelist(
        address indexed investor,
        uint256 timestamp
    );
    
    /// @notice Emitted when property metadata is updated
    event PropertyMetadataUpdated(
        string propertyId,
        string propertyName,
        string propertyAddress,
        uint256 valuation
    );
    
    // ============================================
    // MODIFIERS
    // ============================================
    
    /// @notice Ensures the recipient is whitelisted before transfer
    modifier onlyWhitelisted(address recipient) {
        require(
            whitelist[recipient],
            "Recipient not whitelisted for token transfer"
        );
        _;
    }
    
    // ============================================
    // CONSTRUCTOR & INITIALIZER
    // ============================================
    
    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }
    
    /**
     * @notice Initialize the property token with metadata and supply
     * @dev Replaces constructor for upgradeable pattern. Can only be called once.
     * @param _propertyId Unique identifier for the property
     * @param _propertyName Human-readable property name
     * @param _propertyAddress Physical address of the property
     * @param _tokenSupply Total token supply (represents 100% ownership)
     * @param _propertyValuation Property value in USD cents
     * @param _tokenName ERC-20 token name (e.g., "Sunset Villa Ownership")
     * @param _tokenSymbol ERC-20 token symbol (e.g., "SVILLA")
     */
    function initialize(
        string memory _propertyId,
        string memory _propertyName,
        string memory _propertyAddress,
        uint256 _tokenSupply,
        uint256 _propertyValuation,
        string memory _tokenName,
        string memory _tokenSymbol
    ) public initializer {
        require(_tokenSupply > 0, "Token supply must be greater than zero");
        require(bytes(_propertyId).length > 0, "Property ID required");
        require(_propertyValuation > 0, "Property valuation required");
        
        // Initialize parent contracts
        __ERC20_init(_tokenName, _tokenSymbol);
        __Ownable_init(msg.sender);
        __Pausable_init();
        
        // Initialize property details
        propertyId = _propertyId;
        propertyName = _propertyName;
        propertyAddress = _propertyAddress;
        propertyValuation = _propertyValuation;
        maxSupply = _tokenSupply;
        deploymentTimestamp = block.timestamp;
        
        // Automatically whitelist the contract owner/deployer
        whitelist[msg.sender] = true;
        emit InvestorWhitelisted(msg.sender, block.timestamp);
    }
    
    // ============================================
    // CORE FUNCTIONS
    // ============================================
    
    /**
     * @notice Issue tokens to a whitelisted investor
     * @dev Only owner can issue tokens. Checks supply limit and whitelist.
     * @param investor Address of the investor receiving tokens
     * @param amount Number of tokens to issue (in wei, 18 decimals)
     */
    function issueTokens(
        address investor,
        uint256 amount
    ) external onlyOwner whenNotPaused {
        require(investor != address(0), "Invalid investor address");
        require(amount > 0, "Amount must be greater than zero");
        require(
            whitelist[investor],
            "Investor must be whitelisted before issuance"
        );
        require(
            totalSupply() + amount <= maxSupply,
            "Exceeds maximum token supply"
        );
        
        // Track unique investors
        if (!hasInvested[investor]) {
            hasInvested[investor] = true;
            investorCount++;
        }
        
        _mint(investor, amount);
        
        emit TokensIssued(
            investor,
            amount,
            block.timestamp,
            propertyId
        );
    }
    
    /**
     * @notice Add an investor to the whitelist after KYC verification
     * @dev In production, this should be called after off-chain KYC process
     * @param investor Address to whitelist
     */
    function addToWhitelist(address investor) external onlyOwner {
        require(investor != address(0), "Invalid address");
        require(!whitelist[investor], "Already whitelisted");
        
        whitelist[investor] = true;
        emit InvestorWhitelisted(investor, block.timestamp);
    }
    
    /**
     * @notice Remove an investor from the whitelist
     * @dev Useful for compliance violations or failed re-verification
     * @param investor Address to remove
     */
    function removeFromWhitelist(address investor) external onlyOwner {
        require(whitelist[investor], "Not whitelisted");
        
        whitelist[investor] = false;
        emit InvestorRemovedFromWhitelist(investor, block.timestamp);
    }
    
    /**
     * @notice Batch whitelist multiple investors (gas efficient)
     * @param investors Array of addresses to whitelist
     */
    function batchAddToWhitelist(address[] calldata investors) external onlyOwner {
        for (uint256 i = 0; i < investors.length; i++) {
            address investor = investors[i];
            if (investor != address(0) && !whitelist[investor]) {
                whitelist[investor] = true;
                emit InvestorWhitelisted(investor, block.timestamp);
            }
        }
    }
    
    /**
     * @notice Update property metadata (for corrections or revaluations)
     * @param _propertyName New property name
     * @param _propertyAddress New property address
     * @param _propertyValuation New valuation in USD cents
     */
    function updatePropertyMetadata(
        string memory _propertyName,
        string memory _propertyAddress,
        uint256 _propertyValuation
    ) external onlyOwner {
        require(_propertyValuation > 0, "Valuation must be positive");
        
        propertyName = _propertyName;
        propertyAddress = _propertyAddress;
        propertyValuation = _propertyValuation;
        
        emit PropertyMetadataUpdated(
            propertyId,
            _propertyName,
            _propertyAddress,
            _propertyValuation
        );
    }
    
    // ============================================
    // EMERGENCY CONTROLS
    // ============================================
    
    /**
     * @notice Pause all token transfers (emergency stop)
     * @dev Use in case of security incident or regulatory action
     */
    function pause() external onlyOwner {
        _pause();
    }
    
    /**
     * @notice Resume token transfers after pause
     */
    function unpause() external onlyOwner {
        _unpause();
    }
    
    // ============================================
    // UPGRADE AUTHORIZATION
    // ============================================
    
    /**
     * @notice Authorize upgrade to new implementation
     * @dev Only owner can upgrade. Called by upgradeToAndCall.
     * @param newImplementation Address of new implementation contract
     */
    function _authorizeUpgrade(address newImplementation) internal override onlyOwner {}
    
    /**
     * @notice Get the current implementation version
     * @return Version string for tracking deployments
     */
    function version() public pure virtual returns (string memory) {
        return "1.0.0";
    }
    
    // ============================================
    // OVERRIDES (Transfer Restrictions)
    // ============================================
    
    /**
     * @notice Override transfer to enforce whitelist and pause
     * @dev Both sender and recipient must be whitelisted
     */
    function _update(
        address from,
        address to,
        uint256 amount
    ) internal override whenNotPaused onlyWhitelisted(to) {
        // Allow minting (from = address(0)) without sender whitelist check
        if (from != address(0)) {
            require(
                whitelist[from],
                "Sender not whitelisted for token transfer"
            );
        }
        
        super._update(from, to, amount);
    }
    
    // ============================================
    // VIEW FUNCTIONS
    // ============================================
    
    /**
     * @notice Calculate percentage ownership for a given address
     * @param investor Address to check
     * @return Ownership percentage (scaled by 1e18 for precision)
     */
    function getOwnershipPercentage(address investor) external view returns (uint256) {
        if (totalSupply() == 0) return 0;
        return (balanceOf(investor) * 1e18) / totalSupply();
    }
    
    /**
     * @notice Get property value owned by an investor in USD cents
     * @param investor Address to check
     * @return Value in USD cents
     */
    function getInvestorPropertyValue(address investor) external view returns (uint256) {
        if (totalSupply() == 0) return 0;
        return (balanceOf(investor) * propertyValuation) / totalSupply();
    }
    
    /**
     * @notice Check if an address is whitelisted
     * @param investor Address to check
     * @return Boolean indicating whitelist status
     */
    function isWhitelisted(address investor) external view returns (bool) {
        return whitelist[investor];
    }
    
    /**
     * @notice Get remaining tokens available for issuance
     * @return Number of tokens not yet minted
     */
    function remainingSupply() external view returns (uint256) {
        return maxSupply - totalSupply();
    }
    
    /**
     * @notice Get comprehensive property information
     * @return id Unique property identifier
     * @return name Property name
     * @return addr Physical property address
     * @return valuation Property valuation in USD cents
     * @return supply Maximum token supply
     * @return issued Total tokens issued
     * @return investors Total number of investors
     */
    function getPropertyInfo() external view returns (
        string memory id,
        string memory name,
        string memory addr,
        uint256 valuation,
        uint256 supply,
        uint256 issued,
        uint256 investors
    ) {
        return (
            propertyId,
            propertyName,
            propertyAddress,
            propertyValuation,
            maxSupply,
            totalSupply(),
            investorCount
        );
    }
}
