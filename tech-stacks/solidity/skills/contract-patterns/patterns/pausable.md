# Pausable Pattern

Emergency stop mechanism to pause contract functionality during security incidents or maintenance.

## Basic Implementation

**Use case:** Contracts that need emergency pause capability

```solidity
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract MyContract is Pausable, Ownable {
    constructor() Ownable(msg.sender) {}

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function normalFunction() public whenNotPaused {
        // Function logic only executes when not paused
    }

    function emergencyWithdraw() public onlyOwner whenPaused {
        // Only callable when paused
    }
}
```

## With Role-Based Access Control

**Use case:** Separate pause authority from ownership

```solidity
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";

contract MyContract is Pausable, AccessControl {
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");

    constructor() {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(PAUSER_ROLE, msg.sender);
    }

    function pause() public onlyRole(PAUSER_ROLE) {
        _pause();
    }

    function unpause() public onlyRole(PAUSER_ROLE) {
        _unpause();
    }

    function criticalFunction() public whenNotPaused {
        // Protected by pause mechanism
    }
}
```

## Pausable Token

**Use case:** ERC20 token with emergency pause

```solidity
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract PausableToken is ERC20, Pausable, Ownable {
    constructor() ERC20("MyToken", "MTK") Ownable(msg.sender) {}

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function _update(address from, address to, uint256 value)
        internal
        override
        whenNotPaused
    {
        super._update(from, to, value);
    }
}
```

## Key Features

- **whenNotPaused modifier** - Restricts function execution when paused
- **whenPaused modifier** - Only executes when paused (for emergency functions)
- **paused() view function** - Check current pause state
- **_pause() internal** - Trigger pause
- **_unpause() internal** - Resume operations

## Best Practices

1. **Use for critical contracts** - Especially those handling user funds
2. **Combine with access control** - Restrict who can pause
3. **Document pause behavior** - Clear comments on what gets paused
4. **Test pause scenarios** - Verify all functions respect pause state
5. **Emergency procedures** - Document when and how to pause
6. **Time-limited pauses** - Consider auto-unpause after timeout
7. **Emit events** - Paused and Unpaused events for transparency

## Common Use Cases

- **Security incident response** - Halt operations during attacks
- **Upgrade preparation** - Pause before upgrading contracts
- **Maintenance windows** - Scheduled maintenance periods
- **Circuit breaker** - Automatic pause on anomalous conditions

## Anti-Patterns to Avoid

1. **Pausing everything** - Some functions (like view functions) don't need pausing
2. **No unpause mechanism** - Always include a way to resume
3. **Unclear pause scope** - Document exactly what gets paused
4. **Centralization risk** - Consider multi-sig for pause authority
