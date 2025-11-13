# Common Vulnerabilities Checklist

Comprehensive checklist based on OWASP Top 10 for smart contracts and common vulnerability patterns.

## 1. Reentrancy Attacks

### Classic Reentrancy
- [ ] All external calls follow Checks-Effects-Interactions pattern
- [ ] State updated before external calls
- [ ] ReentrancyGuard applied to functions with external calls
- [ ] No external calls in view/pure functions that affect state reads

### Cross-Function Reentrancy
- [ ] Multiple functions protected by same reentrancy lock
- [ ] Shared state properly protected
- [ ] No state inconsistencies between related functions

### Read-Only Reentrancy
- [ ] View functions don't rely on stale state during external calls
- [ ] Oracle reads cached before external interactions
- [ ] Balance queries safe from manipulation

**Vulnerable Pattern:**
```solidity
function withdraw(uint amount) public {
    require(balances[msg.sender] >= amount);
    msg.sender.call{value: amount}("");  // ❌ External call first
    balances[msg.sender] -= amount;      // ❌ State update after
}
```

**Secure Pattern:**
```solidity
function withdraw(uint amount) public nonReentrant {
    require(balances[msg.sender] >= amount);
    balances[msg.sender] -= amount;      // ✅ State update first
    (bool success, ) = msg.sender.call{value: amount}("");
    require(success);
}
```

## 2. Access Control Issues

### Missing Access Modifiers
- [ ] All sensitive functions have appropriate modifiers (onlyOwner, onlyRole, etc.)
- [ ] Public functions intentionally public
- [ ] Internal functions not accidentally public
- [ ] Private data truly private (not just visibility)

### Incorrect Authorization
- [ ] Owner/admin checks use correct addresses
- [ ] Role-based access correctly implemented
- [ ] No hard-coded addresses
- [ ] Multi-sig requirements enforced
- [ ] Timelock delays implemented for critical operations

### Centralization Risks
- [ ] Admin powers documented and justified
- [ ] Single points of failure identified
- [ ] Governance mechanisms in place
- [ ] Admin key security considered

**Vulnerable Pattern:**
```solidity
function mint(address to, uint amount) public {  // ❌ No access control
    _mint(to, amount);
}
```

**Secure Pattern:**
```solidity
function mint(address to, uint amount) public onlyOwner {  // ✅ Protected
    _mint(to, amount);
}
```

## 3. Integer Overflow/Underflow

### Arithmetic Operations
- [ ] Using Solidity 0.8+ with automatic checks
- [ ] OR using SafeMath for older versions
- [ ] Unchecked blocks only where overflow is impossible
- [ ] Division by zero checked
- [ ] Modulo by zero checked

### Precision Loss
- [ ] Order of operations prevents precision loss
- [ ] Multiplication before division
- [ ] Appropriate decimal handling
- [ ] Rounding behavior documented

**Vulnerable Pattern (pre-0.8):**
```solidity
uint256 balance = 100;
balance = balance - 200;  // ❌ Underflows to max uint256
```

**Secure Pattern:**
```solidity
// Solidity 0.8+ (automatic)
uint256 balance = 100;
balance = balance - 200;  // ✅ Reverts

// OR explicit check
require(balance >= 200);
balance = balance - 200;
```

## 4. Unchecked Call Return Values

### Low-Level Calls
- [ ] call() return value checked
- [ ] delegatecall() return value checked
- [ ] staticcall() return value checked
- [ ] send() return value checked (or use call())
- [ ] transfer() gas limits considered

### External Calls
- [ ] ERC20 transfer() return value checked
- [ ] External contract call results validated
- [ ] Failed calls handled appropriately

**Vulnerable Pattern:**
```solidity
token.transfer(recipient, amount);  // ❌ Return value ignored
```

**Secure Pattern:**
```solidity
require(token.transfer(recipient, amount), "Transfer failed");  // ✅ Checked

// OR
(bool success, ) = address(token).call(
    abi.encodeWithSignature("transfer(address,uint256)", recipient, amount)
);
require(success, "Transfer failed");
```

## 5. Unprotected Functions

### Missing Function Protection
- [ ] initialize() protected against multiple calls
- [ ] selfdestruct() restricted to owner
- [ ] Critical state changes require authorization
- [ ] Upgrade functions protected

### Function Visibility
- [ ] External vs public usage correct
- [ ] Internal functions not exposed
- [ ] Private functions truly private

**Vulnerable Pattern:**
```solidity
function initialize(address owner) public {  // ❌ Can be called multiple times
    _owner = owner;
}
```

**Secure Pattern:**
```solidity
function initialize(address owner) public initializer {  // ✅ One-time only
    _owner = owner;
}
```

## 6. Denial of Service (DoS)

### Gas Limit DoS
- [ ] No unbounded loops
- [ ] Array operations bounded
- [ ] Pagination for large datasets
- [ ] Gas limits considered

### Unexpected Revert DoS
- [ ] External calls can't DoS critical functions
- [ ] Pull over push pattern used
- [ ] Failures isolated

### Block Gas Limit
- [ ] Batch operations don't exceed block limit
- [ ] Alternative execution paths available

**Vulnerable Pattern:**
```solidity
function distributeRewards() public {
    for (uint i = 0; i < users.length; i++) {  // ❌ Unbounded loop
        users[i].transfer(rewards[i]);
    }
}
```

**Secure Pattern:**
```solidity
mapping(address => uint) public pendingRewards;

function claimReward() public {  // ✅ Pull pattern
    uint reward = pendingRewards[msg.sender];
    pendingRewards[msg.sender] = 0;
    payable(msg.sender).transfer(reward);
}
```

## 7. Front-Running

### Transaction Ordering
- [ ] Commit-reveal for sensitive operations
- [ ] Deadline parameters for time-sensitive operations
- [ ] Slippage protection for trades
- [ ] MEV considerations documented

### Price Manipulation
- [ ] Oracle values not manipulable in same block
- [ ] Flash loan attack protection
- [ ] TWAP or similar mechanisms

**Vulnerable Pattern:**
```solidity
function swap(uint amountIn) public {
    uint amountOut = getPrice(amountIn);  // ❌ Can be front-run
    token.transfer(msg.sender, amountOut);
}
```

**Secure Pattern:**
```solidity
function swap(uint amountIn, uint minAmountOut) public {
    uint amountOut = getPrice(amountIn);
    require(amountOut >= minAmountOut, "Slippage too high");  // ✅ Protected
    token.transfer(msg.sender, amountOut);
}
```

## 8. Logic Errors

### State Machine Issues
- [ ] State transitions validated
- [ ] Invalid states impossible
- [ ] Race conditions considered

### Calculation Errors
- [ ] Formulas independently verified
- [ ] Edge cases tested (0, max values)
- [ ] Rounding handled correctly

### Incorrect Assumptions
- [ ] External contract behavior validated
- [ ] Token decimal assumptions correct
- [ ] Time assumptions valid

## 9. Delegatecall Injection

### Delegatecall Safety
- [ ] delegatecall only to trusted contracts
- [ ] User-controlled addresses not used
- [ ] Storage collision risks assessed
- [ ] Proxy patterns correctly implemented

**Vulnerable Pattern:**
```solidity
function execute(address target, bytes data) public {
    target.delegatecall(data);  // ❌ User-controlled delegatecall
}
```

**Secure Pattern:**
```solidity
address private immutable TRUSTED_IMPLEMENTATION;

function execute(bytes data) public onlyOwner {
    TRUSTED_IMPLEMENTATION.delegatecall(data);  // ✅ Fixed trusted address
}
```

## 10. Randomness Issues

### Weak Randomness
- [ ] No reliance on block.timestamp for randomness
- [ ] No reliance on blockhash for randomness
- [ ] VRF (Chainlink VRF) used for random numbers
- [ ] Commit-reveal for fair selection

**Vulnerable Pattern:**
```solidity
uint random = uint(blockhash(block.number - 1));  // ❌ Predictable
```

**Secure Pattern:**
```solidity
// Use Chainlink VRF
import "@chainlink/contracts/src/v0.8/VRFConsumerBase.sol";

contract Random is VRFConsumerBase {
    function getRandomNumber() public returns (bytes32) {
        return requestRandomness(keyHash, fee);  // ✅ Truly random
    }
}
```

## 11. Oracle Manipulation

### Price Oracle Issues
- [ ] Price staleness checks
- [ ] Multiple oracle sources
- [ ] TWAP or similar dampening
- [ ] Flash loan attack protection
- [ ] Chainlink best practices followed

**Vulnerable Pattern:**
```solidity
uint price = oracle.getPrice();  // ❌ No staleness check
uint value = balance * price;
```

**Secure Pattern:**
```solidity
(uint price, uint updatedAt) = oracle.getPrice();
require(block.timestamp - updatedAt < 1 hours, "Stale price");  // ✅ Freshness check
uint value = balance * price;
```

## 12. Token Issues

### ERC20 Issues
- [ ] Approval race condition handled
- [ ] Transfer return value checked
- [ ] Fee-on-transfer tokens considered
- [ ] Decimal handling correct
- [ ] Zero address checks

### ERC721 Issues
- [ ] Safe transfer functions used
- [ ] Token ownership validated
- [ ] Reentrancy in callbacks protected

### ERC1155 Issues
- [ ] Batch operations safe
- [ ] Receiver checks implemented
- [ ] Supply tracking correct

## 13. Signature Verification

### Signature Issues
- [ ] Proper EIP-712 implementation
- [ ] Signature replay protection
- [ ] Nonce management
- [ ] Deadline enforcement
- [ ] Signer validation

**Vulnerable Pattern:**
```solidity
function executeWithSignature(bytes signature) public {
    address signer = recoverSigner(message, signature);
    // ❌ No replay protection
}
```

**Secure Pattern:**
```solidity
mapping(bytes32 => bool) public usedSignatures;

function executeWithSignature(bytes signature) public {
    bytes32 sigHash = keccak256(signature);
    require(!usedSignatures[sigHash], "Signature already used");  // ✅ Replay protection
    usedSignatures[sigHash] = true;

    address signer = recoverSigner(message, signature);
    require(signer == authorized, "Invalid signer");
}
```

## 14. Storage Collisions

### Proxy Storage
- [ ] Storage slots don't collide
- [ ] Storage gaps used
- [ ] Layout preserved in upgrades
- [ ] No storage struct reordering

### Diamond Storage
- [ ] Unique storage positions
- [ ] No overlap between facets
- [ ] Proper storage access patterns

## 15. Timestamp Dependence

### Time-Based Logic
- [ ] Block timestamp manipulation considered
- [ ] ≥15 second tolerance acceptable
- [ ] No reliance on exact timestamp
- [ ] block.number preferred for ordering

**Risky Pattern:**
```solidity
require(block.timestamp == deadline);  // ❌ Exact timestamp
```

**Better Pattern:**
```solidity
require(block.timestamp <= deadline);  // ✅ Range check
```

## Quick Reference

| Vulnerability | Severity | Detection | Prevention |
|--------------|----------|-----------|------------|
| Reentrancy | Critical | Slither, Manual | ReentrancyGuard, CEI |
| Access Control | Critical | Manual | Modifiers, RBAC |
| Integer Issues | High | Slither | Solidity 0.8+ |
| Unchecked Calls | High | Slither | Check returns |
| DoS | Medium | Manual | Bounded loops |
| Front-Running | Medium | Manual | Slippage, commit-reveal |
| Oracle Issues | High | Manual | Staleness checks |
| Weak Randomness | High | Manual | VRF |

---

**Remember:** This checklist is not exhaustive. Always consider contract-specific vulnerabilities and emerging attack patterns.
