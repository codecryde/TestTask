# Property Ownership Token - Smart Contract

> **Blockchain Test Task**: Fractional Real Estate Ownership on Ethereum

This project implements a production-ready, upgradeable smart contract for tokenizing real estate properties using the ERC-20 standard with compliance features.

## 📋 What Was Built

### Core Implementation

**PropertyOwnershipToken.sol** - An upgradeable ERC-20 token representing fractional ownership of a single real estate property.

**Key Features:**

- ✅ **Fractional Ownership**: Issue tokens representing percentage ownership of a property
- ✅ **Property Metadata**: On-chain storage of property ID, name, address, and valuation
- ✅ **Fixed Supply**: Token supply defined at initialization (represents 100% ownership)
- ✅ **KYC Whitelist**: Transfer restrictions ensuring only verified investors can hold tokens
- ✅ **Pausable**: Emergency stop functionality for security incidents
- ✅ **Upgradeable**: UUPS proxy pattern for future improvements
- ✅ **Owner Controls**: Administrative functions for compliance and management

### Architecture

```
┌──────────────────┐
│  ERC1967Proxy    │ ◄─── User Interaction (Storage)
│  (State Storage) │
└────────┬─────────┘
         │ delegatecall
         ▼
┌──────────────────┐
│ Implementation   │ ◄─── Logic (Upgradeable)
│ PropertyToken    │
└──────────────────┘
```

## 🏗️ What Was Changed

### 1. Smart Contract Implementation

Created `src/PropertyOwnershipToken.sol` with:

- OpenZeppelin upgradeable contracts (ERC20Upgradeable, OwnableUpgradeable, PausableUpgradeable)
- UUPS proxy pattern for owner-controlled upgrades
- Whitelist mechanism for KYC compliance
- Property metadata tracking
- Investor counting and tracking
- Storage gaps for future upgrades (50 slots reserved)

### 2. Test Suite

Created `test/PropertyOwnershipToken.t.sol` with **38 comprehensive tests**:

- Deployment and initialization validation
- Whitelist management (add, remove, batch operations)
- Token issuance with supply limits
- Transfer restrictions (whitelisted addresses only)
- Pause/unpause emergency controls
- Access control verification
- Property metadata updates
- View function validations
- Integration flow testing
- Fuzz testing for edge cases

**Test Coverage**: All critical paths tested including reverts, edge cases, and integration flows.

### 3. Deployment & Upgrade Scripts

- **`script/PropertyOwnershipToken.s.sol`**: Deploy implementation + proxy with initialization
- **`script/UpgradePropertyOwnershipToken.s.sol`**: Upgrade existing proxy to new implementation

### 4. Documentation

- **`UPGRADEABLE.md`**: Complete guide on upgradeable pattern, deployment, and upgrade process
- Inline NatSpec comments throughout contract explaining compliance considerations

## 🚀 Quick Start

### Prerequisites

```bash
# Install Foundry
curl -L https://foundry.paradigm.xyz | bash
foundryup

# Install dependencies
forge install
```

### Build

```bash
forge build
```

### Test

```bash
# Run all tests
forge test

# Run with verbosity
forge test -vvv

# Run with gas reporting
forge test --gas-report

# Run specific test
forge test --match-test test_IssueTokens
```

### Deploy

**Deploy to Anvil (Local Network):**

```bash
# Terminal 1: Start Anvil local node
anvil

# Terminal 2: Deploy contract using Anvil's default account
# Anvil provides a default private key for the first account
forge script script/PropertyOwnershipToken.s.sol:PropertyOwnershipTokenScript \
  --rpc-url http://localhost:8545 \
  --private-key 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80 \
  --broadcast
```

**Anvil provides:**

- 10 accounts pre-funded with 10,000 ETH each
- Default private key shown above is for Account #0
- All 10 private keys are displayed when Anvil starts
- Instant block mining (no waiting)
- Perfect for development and testing
- Contract addresses are deterministic on fresh restart

**Optional - Deploy to Sepolia Testnet:**

```bash
# 1. Set up environment variables
echo "PRIVATE_KEY=your_private_key_here" > .env
echo "SEPOLIA_RPC_URL=https://sepolia.infura.io/v3/YOUR_KEY" >> .env

# 2. Deploy and verify
forge script script/PropertyOwnershipToken.s.sol:PropertyOwnershipTokenScript \
  --rpc-url $SEPOLIA_RPC_URL \
  --broadcast \
  --verify
```

**Important:** Save the **PROXY ADDRESS** (not implementation) from deployment output for backend integration!

## 📊 Contract Interaction

### Using Cast (CLI)

```bash
# Set proxy address
PROXY="0x..."

# Check property info
cast call $PROXY "getPropertyInfo()(string,string,string,uint256,uint256,uint256,uint256)"

# Whitelist an investor (owner only)
cast send $PROXY "addToWhitelist(address)" 0xInvestorAddress --private-key $PRIVATE_KEY

# Issue tokens (owner only)
cast send $PROXY "issueTokens(address,uint256)" 0xInvestor 100000000000000000000000 --private-key $PRIVATE_KEY

# Check balance
cast call $PROXY "balanceOf(address)(uint256)" 0xInvestor

# Get ownership percentage
cast call $PROXY "getOwnershipPercentage(address)(uint256)" 0xInvestor
```

### Using Ethers.js (Backend Integration)

```javascript
const { ethers } = require("ethers");

// Connect to contract (use PROXY address)
const provider = new ethers.JsonRpcProvider(process.env.RPC_URL);
const contract = new ethers.Contract(
  process.env.PROXY_ADDRESS,
  PropertyOwnershipTokenABI,
  provider
);

// Read property info
const info = await contract.getPropertyInfo();
console.log("Property:", info.name, "Valuation:", info.valuation);

// Write operations (needs signer)
const signer = new ethers.Wallet(process.env.PRIVATE_KEY, provider);
const contractWithSigner = contract.connect(signer);

// Whitelist investor
await contractWithSigner.addToWhitelist(investorAddress);

// Issue tokens (18 decimals)
await contractWithSigner.issueTokens(
  investorAddress,
  ethers.parseEther("100000")
);
```

## 🔐 Security Considerations

### Implemented Security Features

1. **Access Control**: Only owner can issue tokens, whitelist investors, and upgrade
2. **Transfer Restrictions**: Both sender and recipient must be whitelisted
3. **Pausable**: Emergency stop for all token operations
4. **Supply Cap**: Cannot mint beyond `maxSupply`
5. **Zero Address Protection**: Validation on critical functions
6. **Event Logging**: Complete audit trail for compliance
7. **Upgradeable Pattern**: UUPS with owner-only authorization
8. **OpenZeppelin Base**: Built on audited contracts

### Known Limitations

⚠️ **Centralization**: Contract owner has significant control. Mitigation:

- Use multi-sig wallet (Gnosis Safe) as owner in production
- Implement timelock for upgrades
- Consider DAO governance for decentralized control

⚠️ **Off-Chain Dependencies**: KYC verification happens off-chain. Mitigation:

- Integrate with KYC providers (Onfido, Jumio)
- Implement oracle for automated verification
- Regular re-verification of investors

⚠️ **Regulatory Compliance**: Token represents security, subject to regulations. Mitigation:

- Legal review for jurisdiction-specific requirements (Reg D, Reg S)
- Implement accredited investor checks
- Add compliance officer role
- Enable regulatory reporting

## 🎯 What Could Be Improved in Production

### Short-Term Improvements (Next Sprint)

1. **Multi-Property Factory**

   ```solidity
   contract PropertyTokenFactory {
       function deployProperty(...) external returns (address proxy) {
           // Deploy new PropertyOwnershipToken with proxy
           // Track in registry mapping
       }
   }
   ```

2. **Dividend Distribution**

   ```solidity
   function distributeDividends(uint256 amount) external onlyOwner {
       // Distribute rental income proportionally
   }

   function claimDividends() external {
       // Investors claim their share
   }
   ```

3. **Governance Module**

   - Token holders vote on property decisions
   - Proposals for maintenance, sale, refinancing
   - Timelock for major decisions

4. **KYC Oracle Integration**
   ```solidity
   interface IKYCProvider {
       function isVerified(address user) external view returns (bool);
   }
   // Automatic whitelist updates
   ```

### Long-Term Enhancements

1. **Cross-Chain Support**

   - Bridge to L2 (Polygon, Arbitrum) for lower gas costs
   - Cross-chain ownership tracking

2. **Fractional NFT Hybrid**

   - ERC-721 for property deed
   - ERC-20 for ownership shares
   - Composite ownership structure

3. **Secondary Market**

   - DEX integration for liquidity
   - Order book for fractional share trading
   - Automated market maker (AMM) pool

4. **Legal Integration**

   - On-chain representation of legal agreements
   - Digital signatures for property documents
   - Escrow smart contracts for transactions

5. **Advanced Compliance**
   - Jurisdiction-specific transfer rules
   - Holding period restrictions
   - Accredited investor tiers
   - FATF travel rule compliance

### Scaling Considerations

- **Gas Optimization**: Batch operations already implemented, consider EIP-1167 minimal proxies for factory
- **Storage Optimization**: Use packed structs for metadata
- **Off-Chain Indexing**: The Graph protocol for efficient querying
- **IPFS Integration**: Store property documents and metadata off-chain with on-chain hashes

## 📈 Test Results

```bash
Ran 1 test suite: 38 tests passed, 0 failed (38 total tests)

Key Tests:
✅ Deployment & Initialization (4 tests)
✅ Whitelist Management (8 tests)
✅ Token Issuance (9 tests)
✅ Transfer Restrictions (4 tests)
✅ Pause/Unpause (4 tests)
✅ Property Metadata (3 tests)
✅ View Functions (4 tests)
✅ Integration Flows (2 tests)
```

## 📁 Project Structure

```
Blockchain/
├── src/
│   └── PropertyOwnershipToken.sol      # Main contract
├── script/
│   ├── PropertyOwnershipToken.s.sol    # Deployment script
│   └── UpgradePropertyOwnershipToken.s.sol  # Upgrade script
├── test/
│   └── PropertyOwnershipToken.t.sol    # Test suite (38 tests)
├── UPGRADEABLE.md                      # Upgrade pattern documentation
└── README.md                           # This file
```

## 🔄 Upgrade Process

See [`UPGRADEABLE.md`](UPGRADEABLE.md) for complete upgrade guide.

**Quick upgrade on Anvil:**

```bash
# Start Anvil if not running
anvil

# Set your deployed proxy address
export PROXY_ADDRESS="0x..."

# Run upgrade script with Anvil's default private key
forge script script/UpgradePropertyOwnershipToken.s.sol \
  --rpc-url http://localhost:8545 \
  --private-key 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80 \
  --broadcast
```

**Optional - Upgrade on Sepolia:**

```bash
export PROXY_ADDRESS="0x..."
forge script script/UpgradePropertyOwnershipToken.s.sol \
  --rpc-url $SEPOLIA_RPC_URL \
  --broadcast
```

## 📝 Compliance Notes

This contract includes design considerations for regulatory compliance:

- **Securities Law**: Token represents property ownership (likely a security)
- **KYC/AML**: Whitelist mechanism ensures only verified investors
- **Transfer Restrictions**: Prevents unauthorized secondary trading
- **Event Logging**: Complete audit trail for regulators
- **Pausability**: Regulatory action response capability

**⚠️ Legal Disclaimer**: This is a technical implementation. Consult legal counsel before deploying for real estate tokenization.

## 🛠️ Technology Stack

- **Solidity**: ^0.8.20
- **Framework**: Foundry (Forge, Cast, Anvil)
- **Libraries**: OpenZeppelin Contracts Upgradeable
- **Proxy Pattern**: UUPS (EIP-1822)
- **Test Framework**: Forge Std Library

## 📞 Audit Recommendations

Before production deployment:

1. ✅ **Automated Analysis**: Slither, Mythril for vulnerability scanning
2. ⚠️ **External Audit**: Engage auditing firm (OpenZeppelin, Trail of Bits, ConsenSys Diligence)
3. ⚠️ **Formal Verification**: Mathematical proof of critical invariants
4. ⚠️ **Bug Bounty**: Community security review with incentives
5. ⚠️ **Testnet Deployment**: Minimum 1 month on testnet before mainnet

## 📄 License

MIT

## 🎓 Learning Resources

- [Foundry Book](https://book.getfoundry.sh/)
- [OpenZeppelin Upgrades](https://docs.openzeppelin.com/upgrades-plugins/)
- [ERC-20 Standard](https://eips.ethereum.org/EIPS/eip-20)
- [UUPS Proxy Pattern](https://eips.ethereum.org/EIPS/eip-1822)

---

**Time to Complete**: ~2 hours
**LOC**: ~411 (contract) + ~514 (tests) + ~120 (scripts)
**Test Coverage**: 38 tests, 100% critical path coverage
