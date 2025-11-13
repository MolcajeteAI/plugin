# Upgradeable Contract Patterns

Proxy patterns allow smart contract logic to be upgraded while preserving storage and address.

## UUPS (Universal Upgradeable Proxy Standard)

**Recommended for most use cases**

```solidity
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

contract MyContract is UUPSUpgradeable, OwnableUpgradeable {
    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize() public initializer {
        __Ownable_init(msg.sender);
        __UUPSUpgradeable_init();
    }

    function _authorizeUpgrade(address newImplementation)
        internal
        override
        onlyOwner
    {}
}
```

**Pros:**
- Gas efficient (upgrade logic in implementation)
- Smaller proxy contract
- Flexible upgrade authorization

**Cons:**
- Risk of removing upgrade function
- More complex implementation

## Transparent Proxy

**Use when admin/user separation is critical**

```solidity
import "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";

// Implementation contract
contract MyContractV1 is Initializable {
    uint256 public value;

    function initialize(uint256 _value) public initializer {
        value = _value;
    }
}

// Deploy proxy
TransparentUpgradeableProxy proxy = new TransparentUpgradeableProxy(
    address(implementation),
    admin,
    abi.encodeWithSignature("initialize(uint256)", 42)
);
```

**Pros:**
- Clear admin/user separation
- Admin cannot call implementation functions
- Battle-tested pattern

**Cons:**
- Higher gas costs
- Larger proxy contract

## Beacon Proxy

**Use for multiple instances sharing same implementation**

```solidity
import "@openzeppelin/contracts/proxy/beacon/UpgradeableBeacon.sol";
import "@openzeppelin/contracts/proxy/beacon/BeaconProxy.sol";

// Deploy beacon
UpgradeableBeacon beacon = new UpgradeableBeacon(implementationAddress);

// Deploy multiple proxies pointing to beacon
BeaconProxy proxy1 = new BeaconProxy(address(beacon), initData);
BeaconProxy proxy2 = new BeaconProxy(address(beacon), initData);

// Upgrade all at once
beacon.upgradeTo(newImplementationAddress);
```

**Pros:**
- Upgrade multiple contracts simultaneously
- Gas efficient for multiple instances
- Centralized upgrade control

**Cons:**
- All instances must upgrade together
- Additional beacon contract needed

## Best Practices

1. **Use UUPS by default** - Best gas efficiency and flexibility
2. **Never remove upgrade function** - Ensure _authorizeUpgrade is always present
3. **Initialize, don't construct** - Use initializer instead of constructor
4. **Disable initializers in constructor** - Prevent implementation initialization
5. **Test upgrades thoroughly** - Verify storage layout compatibility
6. **Document storage layout** - Comment storage variables clearly
7. **Use upgrade plugins** - @openzeppelin/hardhat-upgrades or foundry-upgrades
