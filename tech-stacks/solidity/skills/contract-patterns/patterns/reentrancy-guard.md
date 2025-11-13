# Reentrancy Guard Pattern

Protection against reentrancy attacks where external contracts call back into your contract during execution.

## What is Reentrancy?

A reentrancy attack occurs when:
1. Contract A calls Contract B (external call)
2. Contract B calls back into Contract A
3. Contract A's state hasn't been updated yet
4. Contract B exploits the stale state

**Famous example:** The DAO hack (2016) - $60M stolen

## ReentrancyGuard Pattern

**Use case:** Any function that makes external calls or transfers ETH

```solidity
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract MyContract is ReentrancyGuard {
    mapping(address => uint256) public balances;

    function withdraw(uint256 amount) public nonReentrant {
        require(balances[msg.sender] >= amount, "Insufficient balance");

        balances[msg.sender] -= amount;

        (bool success, ) = msg.sender.call{value: amount}("");
        require(success, "Transfer failed");
    }

    function deposit() public payable {
        balances[msg.sender] += msg.value;
    }
}
```

## Checks-Effects-Interactions Pattern

**Best practice:** Follow CEI pattern even with ReentrancyGuard

```solidity
contract SafeContract is ReentrancyGuard {
    mapping(address => uint256) public balances;

    function withdraw(uint256 amount) public nonReentrant {
        // 1. CHECKS - Validate conditions
        require(balances[msg.sender] >= amount, "Insufficient balance");
        require(amount > 0, "Amount must be positive");

        // 2. EFFECTS - Update state
        balances[msg.sender] -= amount;

        // 3. INTERACTIONS - External calls last
        (bool success, ) = msg.sender.call{value: amount}("");
        require(success, "Transfer failed");
    }
}
```

## Common Vulnerable Pattern

**DANGEROUS - Do not use:**

```solidity
// ❌ VULNERABLE TO REENTRANCY
function withdraw(uint256 amount) public {
    require(balances[msg.sender] >= amount);

    // External call BEFORE state update
    (bool success, ) = msg.sender.call{value: amount}("");
    require(success);

    // State update happens after external call
    balances[msg.sender] -= amount;  // TOO LATE!
}
```

**Why it's vulnerable:**
- Attacker's fallback function can call `withdraw()` again
- Balance hasn't been updated yet
- Attacker can drain the contract

## Cross-Function Reentrancy

**Use case:** Protecting multiple related functions

```solidity
contract VaultContract is ReentrancyGuard {
    mapping(address => uint256) public balances;

    // Both functions protected by same lock
    function withdraw(uint256 amount) public nonReentrant {
        require(balances[msg.sender] >= amount);
        balances[msg.sender] -= amount;
        payable(msg.sender).transfer(amount);
    }

    function transfer(address to, uint256 amount) public nonReentrant {
        require(balances[msg.sender] >= amount);
        balances[msg.sender] -= amount;
        balances[to] += amount;
    }
}
```

## Read-Only Reentrancy

**Subtle vulnerability:** View functions called during reentrant context

```solidity
// ❌ VULNERABLE
contract LendingPool {
    function getCollateralValue(address user) public view returns (uint256) {
        return collateralToken.balanceOf(address(this)) * prices[user];
    }

    function borrow() public {
        uint256 collateral = getCollateralValue(msg.sender);
        // If collateralToken does external call, getCollateralValue
        // might return stale data during reentrancy
    }
}

// ✅ SAFE - Cache values before external calls
contract SafeLendingPool is ReentrancyGuard {
    function borrow() public nonReentrant {
        uint256 collateral = getCollateralValue(msg.sender);
        // Protected by nonReentrant
    }
}
```

## Multiple Contracts

**Use case:** Reentrancy across multiple related contracts

```solidity
contract SharedReentrancyGuard {
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;
    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    modifier nonReentrant() {
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");
        _status = _ENTERED;
        _;
        _status = _NOT_ENTERED;
    }
}

contract ContractA is SharedReentrancyGuard {
    function functionA() public nonReentrant {
        // Protected
    }
}

contract ContractB is SharedReentrancyGuard {
    function functionB() public nonReentrant {
        // Protected
    }
}
```

## Best Practices

1. **Always use ReentrancyGuard** - For functions with external calls or ETH transfers
2. **Follow CEI pattern** - Checks, Effects, Interactions in that order
3. **Prefer transfer/send over call** - But call is recommended for gas flexibility
4. **Protect all entry points** - Not just withdraw functions
5. **Use pull over push** - Let users withdraw instead of pushing payments
6. **Test with malicious contracts** - Write tests that attempt reentrancy
7. **Gas cost consideration** - nonReentrant adds ~2.5k gas overhead

## When to Use

**Always use for:**
- Functions that transfer ETH
- Functions that call external contracts
- Functions that call untrusted addresses
- NFT minting with callbacks (ERC721 onERC721Received)
- Token transfers with hooks

**May skip for:**
- Pure view/pure functions
- Internal functions only called by protected functions
- Functions with no external calls

## Testing for Reentrancy

```solidity
// Test contract that attempts reentrancy
contract ReentrancyAttacker {
    VictimContract public victim;
    uint256 public attackCount;

    constructor(VictimContract _victim) {
        victim = _victim;
    }

    function attack() public payable {
        victim.deposit{value: msg.value}();
        victim.withdraw(msg.value);
    }

    receive() external payable {
        if (attackCount < 5 && address(victim).balance > 0) {
            attackCount++;
            victim.withdraw(msg.value);
        }
    }
}
```

## Anti-Patterns to Avoid

1. **External calls before state updates** - Always update state first
2. **Inconsistent protection** - Protect all related functions
3. **Trusting external contracts** - Assume all external calls are malicious
4. **Ignoring cross-function reentrancy** - One function can reenter another
5. **No testing** - Always test with malicious contracts
6. **Over-reliance on guards** - Still follow CEI pattern

## Alternative: Pull Payment Pattern

Instead of pushing payments, let users pull:

```solidity
contract PullPayment is ReentrancyGuard {
    mapping(address => uint256) public payments;

    function _asyncTransfer(address dest, uint256 amount) internal {
        payments[dest] += amount;
    }

    function withdrawPayments() public nonReentrant {
        uint256 payment = payments[msg.sender];
        require(payment > 0, "No payment available");

        payments[msg.sender] = 0;

        (bool success, ) = msg.sender.call{value: payment}("");
        require(success, "Transfer failed");
    }
}
```

---

**Remember:** Reentrancy is one of the most common and dangerous vulnerabilities in Solidity. Always use ReentrancyGuard and follow the Checks-Effects-Interactions pattern.
