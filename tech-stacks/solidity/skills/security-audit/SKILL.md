---
name: security-audit
description: Security audit methodology, checklists, and tools for identifying vulnerabilities in Solidity smart contracts. Use when reviewing contracts for security issues or performing comprehensive audits.
---

# Security Audit Skill

This skill provides methodology, checklists, and templates for conducting security audits of Solidity smart contracts.

## When to Use

Use this skill when:
- Reviewing contracts for security vulnerabilities
- Performing comprehensive security audits
- Preparing for external audits
- Implementing security best practices
- Analyzing contract attack surfaces
- Validating security assumptions

## Audit Process

### 1. Preparation Phase

**Understand the System:**
- Review project documentation
- Understand business logic and requirements
- Identify trust boundaries
- Map out contract interactions
- Review previous audits (if any)

**Set Scope:**
- Define which contracts are in scope
- Identify external dependencies
- Note any known issues or concerns
- Establish audit timeline

### 2. Automated Analysis

**Tools to run:**

```bash
# Static analysis with Slither
slither . --detect all

# Mythril symbolic execution
myth analyze contracts/MyContract.sol

# Aderyn static analyzer
aderyn .

# Gas optimization with Foundry
forge test --gas-report

# Code coverage
forge coverage

# Mutation testing
vertigo run
```

**Key tools:**
- **Slither**: Fast static analysis with 70+ detectors
- **Mythril**: Symbolic execution for deep analysis
- **Aderyn**: Modern Rust-based analyzer
- **Echidna**: Fuzzing for property testing
- **Manticore**: Symbolic execution for complex scenarios

### 3. Manual Review

See `./checklists/` for comprehensive review checklists:

- **common-vulnerabilities.md** - OWASP Top 10 for smart contracts
- **access-control-checklist.md** - Authorization and permission checks
- **token-checklist.md** - ERC20/721/1155 specific issues
- **defi-checklist.md** - DeFi-specific vulnerabilities
- **upgrade-checklist.md** - Proxy and upgrade safety
- **gas-optimization-checklist.md** - Gas efficiency review

### 4. Testing Review

**Test Coverage Analysis:**
- Line coverage > 95%
- Branch coverage > 90%
- Function coverage = 100%
- Critical paths fully tested

**Test Quality:**
- Edge cases covered
- Negative test cases present
- Fuzz testing implemented
- Integration tests present
- Reentrancy attack tests
- Access control tests

### 5. Documentation Review

**Code Documentation:**
- NatSpec comments present
- Complex logic explained
- Security assumptions documented
- Known limitations noted

**External Documentation:**
- Architecture diagrams
- Threat model documented
- Deployment procedures
- Upgrade procedures
- Emergency procedures

## Critical Vulnerability Categories

### High Severity

1. **Reentrancy**
   - External calls before state updates
   - Missing ReentrancyGuard
   - Cross-function reentrancy

2. **Access Control**
   - Missing access modifiers
   - Incorrect owner checks
   - Centralization risks
   - Privilege escalation

3. **Integer Issues**
   - Overflow/underflow (pre-0.8)
   - Division by zero
   - Precision loss

4. **Unchecked External Calls**
   - Ignored return values
   - Low-level call failures
   - Delegatecall to untrusted addresses

5. **Logic Errors**
   - Incorrect calculations
   - Wrong operator usage
   - State machine issues

### Medium Severity

1. **Front-Running**
   - Transaction ordering dependence
   - Lack of commit-reveal
   - MEV vulnerabilities

2. **Denial of Service**
   - Unbounded loops
   - Gas limit attacks
   - Block gas limit issues

3. **Oracle Manipulation**
   - Price oracle attacks
   - Flash loan exploits
   - Stale price data

4. **Token Issues**
   - Approval race conditions
   - Transfer return value handling
   - Fee-on-transfer tokens

### Low Severity

1. **Gas Optimization**
   - Inefficient storage usage
   - Redundant operations
   - Suboptimal patterns

2. **Code Quality**
   - Unused variables
   - Dead code
   - Magic numbers
   - Inconsistent naming

## Security Patterns

### 1. Checks-Effects-Interactions (CEI)

```solidity
function withdraw(uint256 amount) public {
    // 1. CHECKS
    require(balances[msg.sender] >= amount, "Insufficient balance");

    // 2. EFFECTS
    balances[msg.sender] -= amount;

    // 3. INTERACTIONS
    (bool success, ) = msg.sender.call{value: amount}("");
    require(success, "Transfer failed");
}
```

### 2. Pull Over Push

```solidity
// ❌ BAD: Push payments
function distributeRewards() public {
    for (uint i = 0; i < users.length; i++) {
        users[i].transfer(rewards[users[i]]);
    }
}

// ✅ GOOD: Pull payments
function claimReward() public {
    uint256 reward = rewards[msg.sender];
    require(reward > 0, "No reward");
    rewards[msg.sender] = 0;
    payable(msg.sender).transfer(reward);
}
```

### 3. Rate Limiting

```solidity
mapping(address => uint256) public lastActionTime;
uint256 public constant COOLDOWN = 1 hours;

function sensitiveAction() public {
    require(
        block.timestamp >= lastActionTime[msg.sender] + COOLDOWN,
        "Cooldown not expired"
    );
    lastActionTime[msg.sender] = block.timestamp;
    // Action logic
}
```

### 4. Emergency Stop

```solidity
import "@openzeppelin/contracts/security/Pausable.sol";

contract MyContract is Pausable {
    function criticalFunction() public whenNotPaused {
        // Protected by pause mechanism
    }

    function pause() public onlyOwner {
        _pause();
    }
}
```

## Automated Tool Commands

### Slither Analysis

```bash
# Basic analysis
slither .

# Specific detectors
slither . --detect reentrancy-eth,unchecked-transfer

# Generate report
slither . --json slither-report.json

# Check upgradeability
slither-check-upgradeability . MyContract

# Human-readable summary
slither . --print human-summary
```

### Mythril Analysis

```bash
# Analyze specific contract
myth analyze contracts/MyContract.sol

# With specific modules
myth analyze contracts/MyContract.sol -m IntegerOverflow,Reentrancy

# Generate report
myth analyze contracts/MyContract.sol -o json > mythril-report.json
```

### Aderyn Analysis

```bash
# Basic scan
aderyn .

# Generate markdown report
aderyn . --output report.md

# Specific severity
aderyn . --severity high,medium
```

### Echidna Fuzzing

```bash
# Fuzz test with config
echidna-test contracts/MyContract.sol --config echidna.yaml

# Specific test contract
echidna-test contracts/MyContract.sol --contract TestContract
```

## Audit Report Template

See `./templates/audit-report-template.md` for a comprehensive audit report structure.

**Report sections:**
1. Executive Summary
2. Scope and Methodology
3. Findings Overview
4. Detailed Findings
5. Recommendations
6. Conclusion
7. Appendices

## Common Vulnerability Checklist

### Access Control
- [ ] All functions have appropriate access modifiers
- [ ] Owner/admin addresses are validated
- [ ] Role-based access control is correctly implemented
- [ ] No unauthorized privilege escalation possible
- [ ] Multi-sig or timelock for critical functions

### Reentrancy
- [ ] CEI pattern followed
- [ ] ReentrancyGuard applied to vulnerable functions
- [ ] No external calls before state updates
- [ ] Cross-function reentrancy considered

### Integer Operations
- [ ] Using Solidity 0.8+ for automatic checks
- [ ] Division by zero checks where needed
- [ ] Precision loss in calculations handled

### External Calls
- [ ] Return values checked
- [ ] Gas limits considered
- [ ] Delegatecall to trusted addresses only
- [ ] Call used instead of transfer/send for flexibility

### Token Handling
- [ ] ERC20 approval race condition handled
- [ ] Transfer return values checked
- [ ] Fee-on-transfer tokens considered
- [ ] Decimal handling correct

### Upgrades (if applicable)
- [ ] Storage layout preserved
- [ ] Initializers properly protected
- [ ] _authorizeUpgrade function present
- [ ] Storage gaps used
- [ ] Upgrade tested on testnet

### Gas Optimization
- [ ] No unbounded loops
- [ ] Efficient storage usage
- [ ] Batch operations where possible
- [ ] View/pure functions used correctly

### Oracle Usage
- [ ] Price staleness checks
- [ ] Multiple oracle sources
- [ ] Flash loan attack protection
- [ ] Chainlink recommendations followed

## Security Resources

### Documentation
- [Ethereum Smart Contract Security Best Practices](https://consensys.github.io/smart-contract-best-practices/)
- [SWC Registry](https://swcregistry.io/) - Smart contract weakness classification
- [Solidity Security Considerations](https://docs.soliditylang.org/en/latest/security-considerations.html)
- [OpenZeppelin Security](https://docs.openzeppelin.com/contracts/4.x/security)

### Tools
- [Slither](https://github.com/crytic/slither)
- [Mythril](https://github.com/ConsenSys/mythril)
- [Aderyn](https://github.com/Cyfrin/aderyn)
- [Echidna](https://github.com/crytic/echidna)
- [Manticore](https://github.com/trailofbits/manticore)

### Audit Firms
- Trail of Bits
- OpenZeppelin
- ConsenSys Diligence
- Cyfrin (Code4rena)
- Spearbit

## Finding Severity Classification

### Critical
- Direct loss of funds
- Complete contract takeover
- Unrecoverable state corruption

**Example:** Reentrancy allowing unlimited withdrawals

### High
- Significant loss of funds under specific conditions
- Privilege escalation
- Critical function DoS

**Example:** Missing access control on admin function

### Medium
- Partial loss of funds
- Temporary DoS
- Incorrect state management

**Example:** Front-running opportunity affecting fairness

### Low
- Potential issues under rare conditions
- Gas optimizations
- Code quality improvements

**Example:** Use of magic numbers instead of constants

### Informational
- Best practice recommendations
- Documentation improvements
- Code clarity suggestions

**Example:** Missing NatSpec comments

## Best Practices

1. **Multiple passes** - Review code multiple times with different focuses
2. **Assume malicious actors** - Think like an attacker
3. **Test assumptions** - Verify all security assumptions
4. **Check dependencies** - Review imported contracts and libraries
5. **Consider edge cases** - Zero values, max values, empty arrays
6. **Document findings clearly** - Include reproduction steps and recommendations
7. **Retest after fixes** - Verify fixes don't introduce new issues
8. **Stay updated** - Follow latest vulnerability disclosures

## Integration with Other Skills

This skill works with:
- **vulnerability-patterns**: Detailed vulnerability descriptions
- **testing-patterns**: Test design for security scenarios
- **gas-optimization**: Efficient and secure implementations
- **upgrade-safety**: Safe upgrade practices

## Quick Reference

| Task | Tool | Command |
|------|------|---------|
| Static analysis | Slither | `slither .` |
| Symbolic execution | Mythril | `myth analyze contracts/` |
| Modern analysis | Aderyn | `aderyn .` |
| Fuzzing | Echidna | `echidna-test contracts/` |
| Coverage | Foundry | `forge coverage` |
| Gas report | Foundry | `forge test --gas-report` |

---

**Remember:** Security is not a one-time check. Conduct regular audits, especially after significant changes. Consider external audits for production systems handling significant value.
