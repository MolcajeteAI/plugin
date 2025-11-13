# Upgradeable Contract Security Checklist

Security checklist for upgradeable smart contracts using proxy patterns (UUPS, Transparent, Beacon, Diamond).

## Storage Layout Safety

### Storage Preservation Rules
- [ ] Never delete state variables
- [ ] Never change type of state variables
- [ ] Never change order of state variables
- [ ] Only add new variables at the end
- [ ] Use storage gaps in base contracts

**Vulnerable Upgrade:**
```solidity
// V1
contract MyContractV1 {
    uint256 public value;
    address public owner;
}

// V2 - ❌ DANGEROUS
contract MyContractV2 {
    address public owner;      // ❌ Changed order
    uint256 public newValue;   // ❌ Changed name/position
}
```

**Safe Upgrade:**
```solidity
// V1
contract MyContractV1 {
    uint256 public value;
    address public owner;
}

// V2 - ✅ SAFE
contract MyContractV2 {
    uint256 public value;      // ✅ Same position
    address public owner;      // ✅ Same position
    uint256 public newValue;   // ✅ Added at end
}
```

### Storage Gaps

**Why Storage Gaps:**
- Reserve space for future variables in base contracts
- Prevent storage collisions in inheritance
- Maintain upgrade compatibility

```solidity
contract BaseContract {
    uint256 public value;

    // Reserve 50 slots for future variables
    uint256[49] private __gap;
}

contract DerivedContract is BaseContract {
    uint256 public newValue;  // Uses slot after gap
}
```

**Storage Gap Rules:**
- [ ] Base contracts have storage gaps
- [ ] Gap size appropriate (usually 50 slots)
- [ ] Gap reduced when adding new variables
- [ ] Total slots (variables + gap) constant

### Storage Collision Detection

**Tools to Use:**
- [ ] `@openzeppelin/hardhat-upgrades` validates storage
- [ ] `slither-check-upgradeability` detects issues
- [ ] Manual storage layout documentation

**Check Commands:**
```bash
# Hardhat
npx hardhat verify-upgrade <PROXY> <NEW_IMPL>

# Slither
slither-check-upgradeability . MyContract

# Foundry (manual calculation)
forge inspect MyContract storage-layout
```

## Initializer Safety

### Constructor vs Initializer

**Rules:**
- [ ] No constructor logic in upgradeable contracts
- [ ] Use `initializer` modifier instead
- [ ] `_disableInitializers()` in constructor
- [ ] Initializers protected from multiple calls

**Correct Pattern:**
```solidity
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

contract MyContract is Initializable {
    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();  // ✅ Prevent implementation init
    }

    function initialize(address owner) public initializer {
        __Ownable_init(owner);
        // Initialization logic
    }
}
```

### Reinitializers

**For Upgraded Versions:**
- [ ] Use `reinitializer(version)` for upgrade initialization
- [ ] Version number incremented
- [ ] Previous initialization preserved
- [ ] Only called during upgrade

```solidity
contract MyContractV2 is Initializable {
    uint256 public version;

    function initializeV2(uint256 newValue) public reinitializer(2) {
        version = 2;
        // V2 initialization
    }
}
```

### Initializer Checklist

- [ ] `initializer` modifier on init function
- [ ] `_disableInitializers()` in constructor
- [ ] Parent initializers called (`__Parent_init()`)
- [ ] Initializer can't be frontrun
- [ ] Failed initialization doesn't brick contract

## UUPS Pattern Security

### Authorization

**Critical: _authorizeUpgrade**
- [ ] `_authorizeUpgrade` function present
- [ ] Function has proper access control
- [ ] Can't be removed in upgrades
- [ ] Multi-sig or timelock recommended

```solidity
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";

contract MyContract is UUPSUpgradeable, OwnableUpgradeable {
    function _authorizeUpgrade(address newImplementation)
        internal
        override
        onlyOwner  // ✅ Access control
    {}

    // ❌ NEVER remove this function!
}
```

### Upgrade Safety

- [ ] Test upgrades on testnet first
- [ ] Verify new implementation before upgrading
- [ ] Timelock on upgrades
- [ ] Pause before upgrade (if applicable)
- [ ] Rollback plan documented

### Common UUPS Mistakes

**Missing Implementation:**
```solidity
// ❌ Forget to import UUPSUpgradeable
contract MyContractV2 is OwnableUpgradeable {
    // Missing: function _authorizeUpgrade
    // Result: Contract becomes non-upgradeable!
}
```

**Removed Authorization:**
```solidity
// ❌ Remove authorization function
contract MyContractV2 is UUPSUpgradeable {
    // Removed: function _authorizeUpgrade
    // Result: Contract becomes non-upgradeable!
}
```

## Transparent Proxy Security

### Admin Separation

- [ ] Admin address set correctly
- [ ] Admin can't call implementation functions
- [ ] Users can't call admin functions
- [ ] ProxyAdmin contract used
- [ ] Admin transfer is two-step

**Transparent Proxy Rules:**
- Admin calls go to proxy admin functions
- Non-admin calls go to implementation
- Clear separation prevents collisions

### Upgrade Authorization

- [ ] Only ProxyAdmin can upgrade
- [ ] ProxyAdmin ownership secured (multi-sig)
- [ ] Timelock on upgrades
- [ ] Upgrade events emitted

```solidity
// Upgrade via ProxyAdmin
ProxyAdmin admin = ProxyAdmin(adminAddress);
admin.upgrade(proxy, newImplementation);
```

## Beacon Proxy Security

### Beacon Management

- [ ] Beacon address immutable in proxies
- [ ] Beacon upgrade authorization protected
- [ ] All proxies upgrade simultaneously (by design)
- [ ] Beacon owner secured (multi-sig)

**Beacon Pattern:**
```solidity
UpgradeableBeacon beacon = new UpgradeableBeacon(implementation);

// Deploy multiple proxies
BeaconProxy proxy1 = new BeaconProxy(address(beacon), initData);
BeaconProxy proxy2 = new BeaconProxy(address(beacon), initData);

// Upgrade all at once
beacon.upgradeTo(newImplementation);
```

### Risk Assessment

- [ ] Understand all proxies upgrade together
- [ ] Test upgrade with all proxy instances
- [ ] Some proxies may have unique state
- [ ] Rollback plan for multiple proxies

## Diamond Pattern (EIP-2535) Security

### Facet Management

- [ ] Facet addresses validated
- [ ] No function selector collisions
- [ ] Facet add/replace/remove authorized
- [ ] DiamondCut events emitted

### Diamond Storage

- [ ] Storage isolated per facet
- [ ] No storage collisions between facets
- [ ] Diamond storage pattern used correctly
- [ ] Storage documented clearly

```solidity
// Diamond storage pattern
library LibDiamond {
    bytes32 constant DIAMOND_STORAGE_POSITION = keccak256("diamond.standard.diamond.storage");

    struct DiamondStorage {
        mapping(bytes4 => address) facets;
        // Other diamond-specific state
    }

    function diamondStorage() internal pure returns (DiamondStorage storage ds) {
        bytes32 position = DIAMOND_STORAGE_POSITION;
        assembly {
            ds.slot := position
        }
    }
}
```

### Facet Upgrades

- [ ] Facet upgrade authorization
- [ ] Initialization for new facets
- [ ] No breaking changes in facet updates
- [ ] Facet interaction testing

## Upgrade Process Security

### Pre-Upgrade

**Code Review:**
- [ ] Storage layout compatible
- [ ] Initializers correct
- [ ] Authorization preserved
- [ ] Breaking changes documented
- [ ] Security audit for critical upgrades

**Testing:**
- [ ] Unit tests pass
- [ ] Integration tests pass
- [ ] Upgrade test on fork
- [ ] Storage verification
- [ ] Gas cost analysis

**Deployment:**
- [ ] Deploy new implementation
- [ ] Verify on Etherscan
- [ ] Test new implementation standalone
- [ ] Prepare upgrade transaction

### During Upgrade

**Safety Checks:**
- [ ] Pause protocol if applicable
- [ ] Verify implementation address
- [ ] Check initialization parameters
- [ ] Multi-sig approval obtained
- [ ] Timelock delay observed

**Upgrade Execution:**
```bash
# Verify storage compatibility
npx hardhat verify-upgrade <PROXY> <NEW_IMPL>

# Prepare upgrade
npx hardhat prepareUpgrade <PROXY> <NEW_IMPL>

# Execute upgrade
npx hardhat upgradeProxy <PROXY> <NEW_IMPL>

# Verify upgrade
npx hardhat verify <NEW_IMPL_ADDRESS>
```

### Post-Upgrade

**Verification:**
- [ ] Verify implementation address changed
- [ ] Test critical functions
- [ ] Check storage integrity
- [ ] Monitor for issues
- [ ] Unpause if paused

**Monitoring:**
- [ ] Transaction success
- [ ] Events emitted correctly
- [ ] No unexpected reverts
- [ ] User experience unchanged
- [ ] Gas costs reasonable

## Common Upgrade Vulnerabilities

### Storage Collisions

**Scenario:** New variable overwrites existing storage slot

```solidity
// V1
contract V1 {
    address public owner;  // slot 0
}

// V2 - ❌ Storage collision
contract V2 {
    uint256 public value;  // slot 0 - overwrites owner!
    address public owner;  // slot 1 - now empty
}
```

### Uninitialized Implementation

**Scenario:** Implementation contract can be initialized by attacker

```solidity
// ❌ No constructor protection
contract MyContract is Initializable {
    function initialize() public initializer {
        // Attacker can initialize the implementation!
    }
}

// ✅ Protected
contract MyContract is Initializable {
    constructor() {
        _disableInitializers();  // Prevents initialization
    }

    function initialize() public initializer {
        // Only proxy can be initialized
    }
}
```

### Selfdestruct in Implementation

**Scenario:** Selfdestruct kills implementation for all proxies

```solidity
// ❌ NEVER use selfdestruct in upgradeable contracts
contract MyContract {
    function destroy() public onlyOwner {
        selfdestruct(payable(owner));  // ❌ Kills implementation!
    }
}
```

### Delegatecall to User-Controlled Address

**Scenario:** Arbitrary delegatecall allows storage manipulation

```solidity
// ❌ User-controlled delegatecall
function execute(address target, bytes calldata data) public {
    target.delegatecall(data);  // ❌ Can manipulate any storage!
}
```

## Testing Upgrades

### Storage Layout Tests

```solidity
function testStorageLayout() public {
    // Deploy V1
    MyContractV1 v1 = new MyContractV1();
    v1.initialize(owner);
    v1.setValue(100);

    // Upgrade to V2
    MyContractV2 v2 = MyContractV2(address(v1));

    // Verify storage preserved
    assertEq(v2.getValue(), 100);
    assertEq(v2.owner(), owner);
}
```

### Upgrade Simulation

```bash
# Fork mainnet
forge test --fork-url $MAINNET_RPC_URL

# In test:
# 1. Deploy new implementation
# 2. Upgrade proxy
# 3. Verify storage and functionality
```

### Invariant Testing

```solidity
// Invariant: Storage values survive upgrades
function invariant_storagePreserved() public {
    uint256 valueBefore = contract.getValue();
    // Simulate upgrade
    uint256 valueAfter = contract.getValue();
    assertEq(valueBefore, valueAfter);
}
```

## Best Practices

1. **Always use OpenZeppelin upgradeable contracts** (`@openzeppelin/contracts-upgradeable`)
2. **Test upgrades on testnet** before mainnet
3. **Use storage gaps** in all base contracts (50 slots)
4. **Document storage layout** in comments
5. **Never remove _authorizeUpgrade** in UUPS
6. **Disable initializers in constructor** (`_disableInitializers()`)
7. **Use multi-sig and timelock** for upgrades
8. **Audit before major upgrades** - security critical
9. **Monitor after upgrade** - watch for issues
10. **Have rollback plan** - can deploy previous implementation

## Upgrade Checklist Template

```markdown
## Upgrade Preparation

- [ ] Storage layout verified compatible
- [ ] New implementation audited
- [ ] Tests pass (unit, integration, upgrade simulation)
- [ ] Storage gaps maintained
- [ ] Initializers protected
- [ ] Authorization functions present
- [ ] Deployment addresses verified
- [ ] Multi-sig signers ready
- [ ] Timelock delay observed
- [ ] Communication plan ready

## Upgrade Execution

- [ ] Pause protocol (if applicable)
- [ ] Deploy new implementation
- [ ] Verify on Etherscan
- [ ] Prepare upgrade transaction
- [ ] Execute upgrade via multi-sig
- [ ] Verify implementation address
- [ ] Test critical functions
- [ ] Unpause protocol

## Post-Upgrade

- [ ] Monitor transactions
- [ ] Check error rates
- [ ] Verify user experience
- [ ] Document changes
- [ ] Announce upgrade
```

## Quick Reference

| Pattern | Pros | Cons | Best For |
|---------|------|------|----------|
| UUPS | Gas efficient, flexible | Can brick if mistake | Most use cases |
| Transparent | Clear separation | Higher gas cost | Admin separation critical |
| Beacon | Upgrade many at once | All upgrade together | Multiple instances |
| Diamond | Unlimited size | Complex | Large contracts |

---

**Remember:** Upgradeability introduces significant complexity. Only use when necessary, and always prioritize security over convenience.
