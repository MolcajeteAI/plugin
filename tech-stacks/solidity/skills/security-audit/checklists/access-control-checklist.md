# Access Control Checklist

Comprehensive checklist for reviewing access control and authorization mechanisms in smart contracts.

## Owner/Admin Functions

### Ownership Verification
- [ ] Owner address properly initialized in constructor
- [ ] Owner address cannot be zero address
- [ ] Ownership transfer requires two-step process (Ownable2Step)
- [ ] New owner must accept ownership explicitly
- [ ] Ownership renouncement is intentional or disabled
- [ ] Events emitted for ownership changes

**Good Pattern:**
```solidity
import "@openzeppelin/contracts/access/Ownable2Step.sol";

contract MyContract is Ownable2Step {
    constructor() Ownable(msg.sender) {}

    // Owner initiates transfer
    function transferOwnership(address newOwner) public override onlyOwner {
        require(newOwner != address(0), "Invalid address");
        super.transferOwnership(newOwner);
    }

    // New owner accepts
    function acceptOwnership() public override {
        super.acceptOwnership();
    }
}
```

### Admin Function Protection
- [ ] All admin functions have `onlyOwner` or equivalent modifier
- [ ] Critical functions have additional timelock
- [ ] Administrative changes emit events
- [ ] No hard-coded admin addresses
- [ ] Admin functions clearly documented

**Checklist for each admin function:**
- [ ] `function pause()` - onlyOwner or onlyRole(PAUSER_ROLE)
- [ ] `function unpause()` - onlyOwner or onlyRole(PAUSER_ROLE)
- [ ] `function setFee()` - onlyOwner with reasonable bounds
- [ ] `function withdraw()` - onlyOwner with reentrancy protection
- [ ] `function upgrade()` - onlyOwner or onlyRole(UPGRADER_ROLE)
- [ ] `function setOracle()` - onlyOwner with validation

## Role-Based Access Control (RBAC)

### Role Definition
- [ ] Roles defined as constants using keccak256
- [ ] Role names clear and descriptive
- [ ] Role hierarchy documented
- [ ] DEFAULT_ADMIN_ROLE usage understood

**Good Pattern:**
```solidity
import "@openzeppelin/contracts/access/AccessControl.sol";

contract MyContract is AccessControl {
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant BURNER_ROLE = keccak256("BURNER_ROLE");
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");

    constructor() {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }
}
```

### Role Assignment
- [ ] Initial roles granted in constructor
- [ ] DEFAULT_ADMIN_ROLE carefully managed
- [ ] Role admins properly set
- [ ] Multi-sig for role grants if needed
- [ ] Zero address not granted roles

### Role Checks
- [ ] All protected functions use `onlyRole` modifier
- [ ] Role checks before state changes
- [ ] Correct role checked for each function
- [ ] No missing role checks

**Function-to-Role mapping:**
- [ ] `mint()` - MINTER_ROLE
- [ ] `burn()` - BURNER_ROLE
- [ ] `pause()` - PAUSER_ROLE
- [ ] `grantRole()` - Admin of that role
- [ ] `revokeRole()` - Admin of that role

## Multi-Signature Requirements

### Multi-Sig Implementation
- [ ] Critical operations require multiple signatures
- [ ] Threshold appropriately set (e.g., 3-of-5)
- [ ] Signers are trusted and independent
- [ ] Signature verification correct
- [ ] Replay protection implemented
- [ ] Nonce management correct

**Key functions requiring multi-sig:**
- [ ] Ownership transfer
- [ ] Upgrade authorization
- [ ] Parameter changes (fees, limits)
- [ ] Emergency pause
- [ ] Treasury withdrawals

### Multi-Sig Patterns
```solidity
contract MultiSig {
    mapping(address => bool) public isOwner;
    uint256 public required;

    modifier onlyMultiSig() {
        require(confirmations[txId] >= required, "Not enough confirmations");
        _;
    }

    function executeTransaction(uint256 txId) public onlyMultiSig {
        // Execute
    }
}
```

## Timelock Mechanisms

### Timelock Implementation
- [ ] Critical functions have delay
- [ ] Delay duration appropriate (24-48 hours typical)
- [ ] Pending operations are transparent
- [ ] Operations can be cancelled
- [ ] Events emitted for queued and executed operations

**Functions requiring timelock:**
- [ ] Protocol upgrades
- [ ] Parameter changes (fees, interest rates)
- [ ] Admin role grants
- [ ] Treasury operations

**Good Pattern:**
```solidity
import "@openzeppelin/contracts/governance/TimelockController.sol";

contract MyTimelock is TimelockController {
    constructor(
        uint256 minDelay,
        address[] memory proposers,
        address[] memory executors
    ) TimelockController(minDelay, proposers, executors, msg.sender) {}
}
```

## Modifier Usage

### Modifier Implementation
- [ ] Modifiers clearly named
- [ ] Single responsibility per modifier
- [ ] Reentrancy protection where needed
- [ ] State checks before `_`
- [ ] No complex logic in modifiers

**Common modifiers checklist:**
- [ ] `onlyOwner` - Owner verification
- [ ] `onlyRole` - Role verification
- [ ] `whenNotPaused` - Pause state check
- [ ] `nonReentrant` - Reentrancy protection
- [ ] `validAddress` - Address validation

**Anti-Pattern:**
```solidity
// ❌ Too complex
modifier complexCheck() {
    if (condition1) {
        if (condition2) {
            for (uint i = 0; i < array.length; i++) {
                // Complex logic
            }
        }
    }
    _;
}
```

**Good Pattern:**
```solidity
// ✅ Simple and clear
modifier onlyOwner() {
    require(msg.sender == owner, "Not owner");
    _;
}
```

## Function Visibility

### Visibility Review
- [ ] Public functions intentionally public
- [ ] External vs public correctly chosen
- [ ] Internal functions not exposed
- [ ] Private functions truly private
- [ ] No accidental public exposure

**Decision matrix:**
| Function Called From | Visibility |
|---------------------|-----------|
| External only | external |
| External & internal | public |
| Internal only | internal |
| Same contract only | private |

### State Variable Visibility
- [ ] Public state variables intentional
- [ ] Sensitive data not public
- [ ] Private variables understand limitations
- [ ] Getter functions for computed values

## Centralization Risks

### Single Point of Failure
- [ ] Owner can't brick contract
- [ ] Owner powers limited and documented
- [ ] Upgrade path doesn't allow theft
- [ ] Emergency pause doesn't trap funds
- [ ] No unchecked admin minting

**Red flags:**
- [ ] Owner can withdraw all user funds
- [ ] Owner can change user balances directly
- [ ] Owner can front-run users
- [ ] No timelock on critical changes
- [ ] Single key controls everything

### Decentralization Measures
- [ ] Multi-sig for ownership
- [ ] Timelock for changes
- [ ] Governance for decisions
- [ ] Limited admin powers
- [ ] Path to immutability documented

## Function-Level Checks

### Per-Function Verification

For each public/external function:

```
Function: _________________

□ Purpose clearly documented
□ Access control appropriate
□ Caller restrictions enforced
□ Parameter validation present
□ State changes authorized
□ Events emitted
□ Reentrancy protected if needed
□ Return values validated
```

### Critical Functions

**Minting:**
- [ ] Only authorized roles can mint
- [ ] Supply cap enforced
- [ ] Mint amounts reasonable
- [ ] Events emitted
- [ ] No arbitrary minting

**Burning:**
- [ ] Users can burn own tokens OR authorized
- [ ] Burning reduces supply correctly
- [ ] Events emitted

**Transfers:**
- [ ] Authorization checked
- [ ] Balance updates correct
- [ ] Events emitted
- [ ] Reentrancy protected

**Upgrades:**
- [ ] Authorization checked
- [ ] Timelock enforced
- [ ] Storage layout preserved
- [ ] Events emitted

**Parameter Changes:**
- [ ] Authorization checked
- [ ] Reasonable bounds enforced
- [ ] Events emitted
- [ ] Timelock if critical

## Emergency Functions

### Emergency Pause
- [ ] Pause function exists for critical contracts
- [ ] Only authorized can pause
- [ ] Unpause requires authorization
- [ ] Pause doesn't trap user funds
- [ ] Emergency withdrawal possible when paused

### Emergency Recovery
- [ ] Recovery mechanism for edge cases
- [ ] Requires authorization (multi-sig preferred)
- [ ] Cannot steal user funds
- [ ] Limited to genuine emergencies
- [ ] Transparent and documented

## Testing Access Control

### Test Coverage
- [ ] Test all access modifiers
- [ ] Test unauthorized access attempts
- [ ] Test role grant/revoke
- [ ] Test ownership transfer
- [ ] Test edge cases (zero address, self-assignment)

**Example tests:**
```solidity
function testOnlyOwnerCanPause() public {
    vm.prank(user);
    vm.expectRevert("Ownable: caller is not the owner");
    contract.pause();
}

function testOwnerCanPause() public {
    vm.prank(owner);
    contract.pause();
    assertTrue(contract.paused());
}
```

## Documentation Requirements

### Access Control Documentation
- [ ] All roles documented
- [ ] Admin powers clearly listed
- [ ] Privilege escalation paths identified
- [ ] Multi-sig requirements documented
- [ ] Timelock delays specified
- [ ] Emergency procedures defined

**Required documentation:**
```
## Roles

- **DEFAULT_ADMIN_ROLE**: Can grant/revoke all roles
- **MINTER_ROLE**: Can mint new tokens (subject to cap)
- **PAUSER_ROLE**: Can pause/unpause contract

## Admin Powers

1. Pause/unpause (PAUSER_ROLE, no timelock)
2. Update fee (ADMIN_ROLE, 48h timelock)
3. Upgrade contract (ADMIN_ROLE, 48h timelock)

## Multi-Sig Requirements

- Ownership changes: 3-of-5 multi-sig
- Upgrades: 3-of-5 multi-sig + 48h timelock
```

## Red Flags

Watch out for these patterns:

### Critical Issues
- [ ] ❌ No access control on mint function
- [ ] ❌ Owner can drain user funds
- [ ] ❌ Single key controls everything
- [ ] ❌ No multi-sig or timelock on critical functions
- [ ] ❌ Ownership transfer is one-step

### Warning Signs
- [ ] ⚠️ Extensive admin powers
- [ ] ⚠️ No documentation of admin capabilities
- [ ] ⚠️ Missing events for admin actions
- [ ] ⚠️ Hard-coded addresses
- [ ] ⚠️ Unusual access patterns

## Quick Reference

| Function Type | Typical Protection |
|--------------|-------------------|
| Mint | onlyRole(MINTER_ROLE) |
| Burn | Owner or authorized |
| Pause | onlyRole(PAUSER_ROLE) |
| Upgrade | onlyOwner + timelock |
| Fee changes | onlyOwner + timelock |
| Withdraw | onlyOwner + nonReentrant |
| Role grant | onlyRole(getRoleAdmin(role)) |

---

**Remember:** Access control bugs are often the most critical. A missing `onlyOwner` modifier can allow anyone to drain funds or brick the contract.
