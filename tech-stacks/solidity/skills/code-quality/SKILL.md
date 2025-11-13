---
name: code-quality
description: Code quality standards, linting rules, and best practices for clean Solidity code. Use when reviewing code quality or establishing project standards.
---

# Code Quality Skill

This skill provides code quality standards, linting configurations, and best practices for maintaining high-quality Solidity codebases.

## When to Use

Use this skill when:
- Setting up new projects
- Reviewing code quality
- Establishing coding standards
- Configuring linters and formatters
- Conducting code reviews

## Solidity Style Guide

Follow the [Official Solidity Style Guide](https://docs.soliditylang.org/en/latest/style-guide.html)

### Key Conventions

**Contract Layout:**
```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

// Imports
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

/**
 * @title MyContract
 * @notice Brief description
 */
contract MyContract is ERC20 {
    // Type declarations
    struct User {
        uint256 balance;
        bool active;
    }

    // State variables
    uint256 public constant MAX_SUPPLY = 1_000_000;
    uint256 private _value;
    mapping(address => User) private _users;

    // Events
    event ValueUpdated(uint256 newValue);

    // Errors
    error InvalidValue(uint256 value);

    // Modifiers
    modifier onlyPositive(uint256 value) {
        if (value == 0) revert InvalidValue(value);
        _;
    }

    // Constructor
    constructor() ERC20("MyToken", "MTK") {}

    // External functions
    function setValue(uint256 newValue) external {}

    // Public functions
    function getValue() public view returns (uint256) {}

    // Internal functions
    function _internalFunction() internal {}

    // Private functions
    function _privateFunction() private {}
}
```

### Naming Conventions

```solidity
// Contracts: PascalCase
contract MyContract {}
interface IMyInterface {}
library MyLibrary {}

// Functions: camelCase
function transferTokens() public {}

// Variables: camelCase
uint256 public tokenBalance;
address private ownerAddress;

// Constants: UPPER_CASE
uint256 public constant MAX_SUPPLY = 1000;

// Private/internal: _prefixed
uint256 private _privateVar;
function _internalFunc() internal {}

// Events: PascalCase
event TokensTransferred(address from, address to);

// Errors: PascalCase
error InsufficientBalance();

// Modifiers: camelCase
modifier onlyOwner() {}
```

### Error Naming Philosophy

**Default to simple, idiomatic names** for common validation and state checks. Use descriptive names only when needed for complex business logic.

#### Simple Idiomatic Names (Preferred)

Use terse, community-standard error names that are immediately understood:

```solidity
// ✅ Simple validation errors (preferred)
error ZeroAddress();
error Expired();
error Unauthorized();
error Forbidden();
error NotFound();
error AlreadyExists();

// ✅ Simple state errors
error InvalidState();
error AlreadyInitialized();
error NotInitialized();
error Paused();
error NotPaused();

// ✅ Simple value errors
error OutOfBounds();
error Overflow();
error Underflow();
error InvalidAmount();

// ✅ Simple timing errors
error TooEarly();
error TooLate();
error DeadlineExpired();
```

#### When to Use Descriptive Names

Use longer, descriptive error names when:
1. Complex business logic with multiple conditions
2. Parameters are needed for debugging/events
3. Context isn't clear from contract/function name

```solidity
// ✅ Complex business logic requiring description
error InsufficientCollateral(uint256 required, uint256 provided);
error InvalidVaultState(VaultState current, VaultState expected);
error ExceedsMaxSupply(uint256 requested, uint256 available);
```

#### Context Reduces Verbosity Needs

The contract and function name provide context, so error names can be simple:

```solidity
// ✅ Good: Context makes meaning clear
contract Vault {
    function deposit(address token, uint256 amount) external {
        if (token == address(0)) revert ZeroAddress();  // Vault.deposit: ZeroAddress - clear it's the token
        if (amount == 0) revert InvalidAmount();         // Vault.deposit: InvalidAmount - clear it's deposit amount
        if (block.timestamp > deadline) revert Expired(); // Vault.deposit: Expired - clear the deposit window expired
    }
}

// ❌ Avoid: Overly verbose with redundant context
contract Vault {
    function deposit(address token, uint256 amount) external {
        if (token == address(0)) revert InvalidVaultDepositTokenAddress();  // Redundant: "Vault", "Deposit" in name
        if (amount == 0) revert VaultDepositAmountCannotBeZero();           // Unnecessarily long
        if (block.timestamp > deadline) revert VaultDepositDeadlineHasExpired(); // Too verbose
    }
}
```

#### Error Parameters

**When to include parameters:**
- For debugging: provide values that caused the error
- For event logs: enable off-chain monitoring
- For user feedback: help users understand what went wrong

**When to skip parameters:**
- Simple validation checks (e.g., zero address, zero amount)
- State checks (e.g., already initialized, paused)
- Gas optimization: parameters increase deployment cost

```solidity
// ✅ Parameters for debugging
error InsufficientBalance(uint256 required, uint256 available);
error TransferFailed(address from, address to, uint256 amount);

// ✅ No parameters for simple checks
error ZeroAddress();        // Don't need to know which address
error Paused();            // State is clear from name
error Unauthorized();      // Caller check failed
```

#### Examples from Industry Standards

OpenZeppelin and other leading contracts use simple, idiomatic error names:

```solidity
// OpenZeppelin style
error InvalidSender();
error InvalidReceiver();
error InsufficientAllowance();
error InvalidApprover();

// Uniswap style
error Expired();
error Forbidden();
error InvalidTo();

// AAVE style
error ZeroAddress();
error InvalidAmount();
error Paused();
```

#### Quick Reference

| Situation | Error Name | Parameters |
|-----------|------------|------------|
| Zero address check | `ZeroAddress()` | None |
| Amount is zero | `InvalidAmount()` | None |
| Deadline passed | `Expired()` | None |
| Not authorized | `Unauthorized()` | None |
| Already initialized | `AlreadyInitialized()` | None |
| Complex balance check | `InsufficientBalance(uint256 required, uint256 available)` | Required |
| Complex state change | `InvalidStateTransition(State from, State to)` | Required |
| Business logic violation | `ExceedsMaxSupply(uint256 requested, uint256 max)` | Recommended |

**Guiding principle:** If OpenZeppelin would use a simple name, you should too. Default to simple, only add complexity when necessary.

### Formatting

**Indentation:** 4 spaces (not tabs)

**Line Length:** Max 120 characters

**Spacing:**
```solidity
// ✅ Good spacing
function transfer(address to, uint256 amount) public returns (bool) {
    require(to != address(0), "Invalid address");
    balances[msg.sender] -= amount;
    balances[to] += amount;
    return true;
}

// ❌ Bad spacing
function transfer(address to,uint256 amount)public returns(bool){
    require(to!=address(0),"Invalid address");
    balances[msg.sender]-=amount;
    balances[to]+=amount;
    return true;
}
```

**Braces:**
```solidity
// ✅ Good: Opening brace on same line
if (condition) {
    doSomething();
} else {
    doSomethingElse();
}

// ❌ Bad: Opening brace on new line
if (condition)
{
    doSomething();
}
```

## Linting Configuration

### Solhint (Foundry/Hardhat)

**Install:**
```bash
npm install --save-dev solhint
```

**.solhint.json:**
```json
{
  "extends": "solhint:recommended",
  "rules": {
    "compiler-version": ["error", "^0.8.0"],
    "func-visibility": ["error", {"ignoreConstructors": true}],
    "max-line-length": ["error", 120],
    "not-rely-on-time": "off",
    "no-empty-blocks": "error",
    "no-unused-vars": "error",
    "avoid-low-level-calls": "warn",
    "avoid-call-value": "warn",
    "reason-string": ["warn", {"maxLength": 64}]
  }
}
```

**Run:**
```bash
npx solhint 'contracts/**/*.sol'
```

### Prettier (Formatting)

**Install:**
```bash
npm install --save-dev prettier prettier-plugin-solidity
```

**.prettierrc:**
```json
{
  "plugins": ["prettier-plugin-solidity"],
  "overrides": [
    {
      "files": "*.sol",
      "options": {
        "printWidth": 120,
        "tabWidth": 4,
        "useTabs": false,
        "singleQuote": false,
        "bracketSpacing": false,
        "explicitTypes": "always"
      }
    }
  ]
}
```

**Run:**
```bash
npx prettier --write 'contracts/**/*.sol'
```

### Slither (Static Analysis)

```bash
# Install
pip3 install slither-analyzer

# Run
slither .

# Run specific checks
slither . --detect reentrancy-eth,unchecked-transfer

# Ignore false positives
slither . --exclude naming-convention,solc-version
```

## Code Quality Principles

### 1. KISS (Keep It Simple, Stupid)

```solidity
// ❌ Overly complex
function calculateFee(uint256 amount, bool isVIP, uint256 tier) public pure returns (uint256) {
    return isVIP
        ? (tier == 1 ? amount * 5 / 1000 : tier == 2 ? amount * 3 / 1000 : amount * 1 / 1000)
        : amount * 10 / 1000;
}

// ✅ Simple and clear
function calculateFee(uint256 amount, bool isVIP, uint256 tier) public pure returns (uint256) {
    uint256 feeRate;

    if (isVIP) {
        if (tier == 1) feeRate = 5;
        else if (tier == 2) feeRate = 3;
        else feeRate = 1;
    } else {
        feeRate = 10;
    }

    return (amount * feeRate) / 1000;
}
```

### 2. DRY (Don't Repeat Yourself)

```solidity
// ❌ Repetitive code
function withdrawETH() external {
    require(msg.sender == owner, "Not owner");
    payable(msg.sender).transfer(address(this).balance);
}

function withdrawTokens(address token) external {
    require(msg.sender == owner, "Not owner");
    IERC20(token).transfer(msg.sender, IERC20(token).balanceOf(address(this)));
}

// ✅ DRY with modifier
modifier onlyOwner() {
    require(msg.sender == owner, "Not owner");
    _;
}

function withdrawETH() external onlyOwner {
    payable(msg.sender).transfer(address(this).balance);
}

function withdrawTokens(address token) external onlyOwner {
    IERC20(token).transfer(msg.sender, IERC20(token).balanceOf(address(this)));
}
```

### 3. Single Responsibility

```solidity
// ❌ Function does too much
function processUser(address user, uint256 amount) external {
    require(users[user].active, "User not active");
    require(amount > 0, "Invalid amount");

    uint256 fee = calculateFee(amount);
    uint256 netAmount = amount - fee;

    balances[user] += netAmount;
    feeCollected += fee;
    lastUpdate[user] = block.timestamp;

    emit UserProcessed(user, netAmount);
    emit FeeCollected(fee);
}

// ✅ Split into focused functions
function deposit(address user, uint256 amount) external {
    _validateDeposit(user, amount);

    uint256 netAmount = _processDeposit(amount);
    _updateUserBalance(user, netAmount);

    emit Deposited(user, netAmount);
}

function _validateDeposit(address user, uint256 amount) private view {
    require(users[user].active, "User not active");
    require(amount > 0, "Invalid amount");
}

function _processDeposit(uint256 amount) private returns (uint256) {
    uint256 fee = _calculateFee(amount);
    feeCollected += fee;
    emit FeeCollected(fee);
    return amount - fee;
}
```

### 4. Explicit Over Implicit

```solidity
// ❌ Implicit types and values
function transfer(address to, uint amount) public {
    balances[msg.sender] -= amount;
    balances[to] += amount;
}

// ✅ Explicit types and checks
function transfer(address to, uint256 amount) public returns (bool) {
    require(to != address(0), "Invalid recipient");
    require(balances[msg.sender] >= amount, "Insufficient balance");

    balances[msg.sender] -= amount;
    balances[to] += amount;

    emit Transfer(msg.sender, to, amount);
    return true;
}
```

## Best Practices

### Use Latest Stable Solidity Version

```solidity
// ✅ Latest stable version
pragma solidity ^0.8.30;

// ❌ Old version
pragma solidity ^0.6.0;
```

### Use Named Imports

```solidity
// ✅ Named imports
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

// ❌ Wildcard imports
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
```

### Use Custom Errors

```solidity
// ✅ Custom errors (gas efficient)
error InsufficientBalance(uint256 available, uint256 required);

if (balance < amount) {
    revert InsufficientBalance(balance, amount);
}

// ❌ String errors (expensive)
require(balance >= amount, "Insufficient balance");
```

### Avoid Magic Numbers

```solidity
// ❌ Magic numbers
uint256 fee = amount * 3 / 100;
uint256 cooldown = block.timestamp + 86400;

// ✅ Named constants
uint256 constant FEE_PERCENTAGE = 3;
uint256 constant FEE_DENOMINATOR = 100;
uint256 constant COOLDOWN_PERIOD = 1 days;

uint256 fee = (amount * FEE_PERCENTAGE) / FEE_DENOMINATOR;
uint256 cooldown = block.timestamp + COOLDOWN_PERIOD;
```

### Check Effects Interactions

```solidity
// ✅ CEI pattern
function withdraw(uint256 amount) external {
    // CHECKS
    require(balances[msg.sender] >= amount, "Insufficient balance");

    // EFFECTS
    balances[msg.sender] -= amount;

    // INTERACTIONS
    (bool success, ) = msg.sender.call{value: amount}("");
    require(success, "Transfer failed");
}
```

### Use Natspec Comments

```solidity
/**
 * @notice Transfers tokens to recipient
 * @param to The recipient address
 * @param amount The amount to transfer
 * @return success True if transfer succeeded
 */
function transfer(address to, uint256 amount) external returns (bool success) {
    // Implementation
}
```

## Code Review Checklist

### General
- [ ] Code follows Solidity style guide
- [ ] Functions have clear names
- [ ] Variables have descriptive names
- [ ] No magic numbers
- [ ] Comments explain "why" not "what"
- [ ] No commented-out code
- [ ] No console.log or debug statements

### Security
- [ ] CEI pattern followed
- [ ] Access control present
- [ ] Integer overflow/underflow handled
- [ ] Reentrancy protection where needed
- [ ] Input validation present
- [ ] No unchecked external calls

### Gas Efficiency
- [ ] Storage access minimized
- [ ] Variables packed efficiently
- [ ] Loops bounded
- [ ] Constants used appropriately
- [ ] Unnecessary storage avoided

### Documentation
- [ ] All public functions documented
- [ ] Complex logic explained
- [ ] Security assumptions documented
- [ ] Known issues/limitations noted

## Common Code Smells

### Long Functions

```solidity
// ❌ Function too long (>50 lines)
function process() external {
    // 100+ lines of code
}

// ✅ Split into smaller functions
function process() external {
    _validate();
    _calculate();
    _execute();
}
```

### Deep Nesting

```solidity
// ❌ Too many nested levels
if (condition1) {
    if (condition2) {
        if (condition3) {
            if (condition4) {
                // Do something
            }
        }
    }
}

// ✅ Early returns
if (!condition1) return;
if (!condition2) return;
if (!condition3) return;
if (!condition4) return;
// Do something
```

### God Contracts

```solidity
// ❌ Contract does everything (1000+ lines)
contract Everything {
    // Token functionality
    // Staking functionality
    // Governance functionality
    // ... everything
}

// ✅ Separate concerns
contract Token is ERC20 {}
contract Staking {}
contract Governance {}
```

## Automated Quality Checks

### GitHub Actions

```yaml
name: Code Quality

on: [push, pull_request]

jobs:
  quality:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3

      - name: Install dependencies
        run: npm install

      - name: Run Solhint
        run: npx solhint 'contracts/**/*.sol'

      - name: Check formatting
        run: npx prettier --check 'contracts/**/*.sol'

      - name: Run Slither
        uses: crytic/slither-action@v0.3.0
```

## Quick Reference

| Tool | Purpose | Command |
|------|---------|---------|
| Solhint | Linting | `npx solhint 'contracts/**/*.sol'` |
| Prettier | Formatting | `npx prettier --write 'contracts/**/*.sol'` |
| Slither | Static Analysis | `slither .` |
| Forge fmt | Formatting (Foundry) | `forge fmt` |

---

**Remember:** Code quality is not just about aesthetics—it's about maintainability, security, and preventing bugs. Establish standards early and enforce them consistently.
