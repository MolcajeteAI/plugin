# Access Control Patterns

Access control patterns manage who can execute specific functions in smart contracts.

## Ownable Pattern

**Use case:** Simple contracts with single administrator

```solidity
import "@openzeppelin/contracts/access/Ownable.sol";

contract MyContract is Ownable {
    constructor() Ownable(msg.sender) {}

    function adminFunction() public onlyOwner {
        // Only owner can call
    }

    function transferOwnership(address newOwner) public override onlyOwner {
        super.transferOwnership(newOwner);
    }
}
```

**Key features:**
- Single owner address
- `onlyOwner` modifier for restricted functions
- Ownership transfer mechanism
- Two-step ownership transfer available (Ownable2Step)

## AccessControl Pattern (RBAC)

**Use case:** Complex permissions with multiple roles

```solidity
import "@openzeppelin/contracts/access/AccessControl.sol";

contract MyContract is AccessControl {
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    constructor() {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(ADMIN_ROLE, msg.sender);
    }

    function mint(address to) public onlyRole(MINTER_ROLE) {
        // Only minters can call
    }

    function adminFunction() public onlyRole(ADMIN_ROLE) {
        // Only admins can call
    }
}
```

**Key features:**
- Multiple independent roles
- Role hierarchy
- `onlyRole` modifier
- Role granting/revoking
- Role admin delegation

## Best Practices

1. **Use Ownable for simple cases** - Single admin, straightforward permissions
2. **Use AccessControl for complex cases** - Multiple roles, delegated permissions
3. **Always initialize properly** - Grant roles in constructor
4. **Use 2-step transfer** - Ownable2Step for safer ownership transfer
5. **Document roles** - Clear comments on what each role can do
6. **Principle of least privilege** - Grant minimum necessary permissions
