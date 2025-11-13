---
name: testing-patterns
description: Test design patterns, best practices, and examples for comprehensive Solidity testing. Use when writing tests for smart contracts or improving test coverage.
---

# Testing Patterns Skill

This skill provides patterns, best practices, and examples for testing Solidity smart contracts using Foundry and Hardhat.

**Testing Language:**
- **Foundry projects:** Tests written in Solidity
- **Hardhat projects:** Tests written in TypeScript with strict mode enabled

## When to Use

Use this skill when:
- Writing tests for new contracts
- Improving test coverage
- Designing test suites
- Implementing fuzz testing
- Creating invariant tests
- Testing security scenarios
- Organizing test files

## Testing Language by Framework

**Foundry projects:** Write tests in **Solidity**
- Type-safe at compile time
- Uses Foundry's Test contract
- Direct access to contract internals
- Built-in fuzz and invariant testing

**Hardhat projects:** Write tests in **TypeScript** (strict mode)
- Strongly typed with TypeScript
- Better IDE support and autocomplete
- Catch type errors before runtime
- Modern async/await patterns

## Testing Frameworks

### Foundry (Solidity Tests)

**Advantages:**
- Fast execution (written in Rust)
- Built-in fuzz testing
- Built-in invariant testing
- Gas reporting
- Cheatcodes for powerful testing
- Native Solidity tests

**Basic Test:**
```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {Test} from "forge-std/Test.sol";
import {MyContract} from "../src/MyContract.sol";

contract MyContractTest is Test {
    MyContract public myContract;
    address public owner = address(1);

    function setUp() public {
        vm.prank(owner);
        myContract = new MyContract();
    }

    function test_BasicFunctionality() public {
        // Arrange
        uint256 expected = 42;

        // Act
        myContract.setValue(expected);

        // Assert
        assertEq(myContract.value(), expected);
    }
}
```

### Hardhat (TypeScript Tests)

**Advantages:**
- TypeScript with strict typing
- Rich ecosystem
- Easy mocking
- Time manipulation
- Network forking

**TypeScript Configuration (tsconfig.json):**
```json
{
  "compilerOptions": {
    "target": "ES2020",
    "module": "commonjs",
    "strict": true,
    "esModuleInterop": true,
    "skipLibCheck": true,
    "forceConsistentCasingInFileNames": true,
    "resolveJsonModule": true,
    "noImplicitAny": true,
    "strictNullChecks": true,
    "strictFunctionTypes": true
  },
  "include": ["./test", "./scripts", "./typechain-types"],
  "files": ["./hardhat.config.ts"]
}
```

**Basic Test (TypeScript):**
```typescript
import { expect } from "chai";
import { ethers } from "hardhat";
import { MyContract } from "../typechain-types";
import { SignerWithAddress } from "@nomicfoundation/hardhat-ethers/signers";

describe("MyContract", function () {
  let myContract: MyContract;
  let owner: SignerWithAddress;

  beforeEach(async function () {
    [owner] = await ethers.getSigners();
    const MyContractFactory = await ethers.getContractFactory("MyContract");
    myContract = await MyContractFactory.deploy();
  });

  it("should set value correctly", async function () {
    const expected: number = 42;
    await myContract.setValue(expected);
    expect(await myContract.value()).to.equal(expected);
  });
});
```

## Test Organization

### File Structure

**Foundry:**
```
test/
├── unit/
│   ├── MyContract.t.sol
│   └── Token.t.sol
├── integration/
│   ├── Integration.t.sol
│   └── Workflow.t.sol
├── fuzz/
│   └── Fuzz.t.sol
└── invariant/
    └── Invariant.t.sol
```

**Hardhat (TypeScript):**
```
test/
├── unit/
│   ├── MyContract.test.ts
│   └── Token.test.ts
├── integration/
│   ├── Integration.test.ts
│   └── Workflow.test.ts
└── fixtures/
    └── deploy.ts
```

### Naming Conventions

**Foundry (Solidity):**
- Files: `ContractName.t.sol`
- Contracts: `ContractNameTest`
- Functions: `test_FunctionName_Condition()`
- Fuzz: `testFuzz_FunctionName()`
- Invariant: `invariant_ConditionName()`

**Hardhat (TypeScript):**
- Files: `ContractName.test.ts`
- Describe blocks: Contract/feature names
- It blocks: Specific behavior descriptions
- Strict typing: All variables explicitly typed

## Test Patterns

### 1. Arrange-Act-Assert (AAA)

```solidity
function test_Transfer() public {
    // ARRANGE: Set up test conditions
    address recipient = address(0xBEEF);
    uint256 amount = 100;
    deal(address(token), user, 1000);

    // ACT: Perform the action
    vm.prank(user);
    token.transfer(recipient, amount);

    // ASSERT: Verify the result
    assertEq(token.balanceOf(recipient), amount);
    assertEq(token.balanceOf(user), 900);
}
```

### 2. Setup and Teardown

**Foundry:**
```solidity
contract MyTest is Test {
    MyContract public myContract;
    address public user1;
    address public user2;

    function setUp() public {
        // Runs before each test
        myContract = new MyContract();
        user1 = makeAddr("user1");
        user2 = makeAddr("user2");

        vm.deal(user1, 100 ether);
        vm.deal(user2, 100 ether);
    }
}
```

**Hardhat (TypeScript):**
```typescript
import { ethers } from "hardhat";
import { MyContract } from "../typechain-types";

describe("MyContract", function () {
  let myContract: MyContract;

  beforeEach(async function () {
    // Runs before each test
    const MyContractFactory = await ethers.getContractFactory("MyContract");
    myContract = await MyContractFactory.deploy();
  });

  afterEach(async function () {
    // Cleanup after each test (if needed)
  });
});
```

### 3. Test Fixtures

**Hardhat (TypeScript):**
```typescript
import { loadFixture } from "@nomicfoundation/hardhat-network-helpers";
import { ethers } from "hardhat";
import { Token } from "../typechain-types";
import { SignerWithAddress } from "@nomicfoundation/hardhat-ethers/signers";

async function deployTokenFixture() {
  const [owner, addr1, addr2]: SignerWithAddress[] = await ethers.getSigners();
  const TokenFactory = await ethers.getContractFactory("Token");
  const token: Token = await TokenFactory.deploy();

  return { token, owner, addr1, addr2 };
}

describe("Token", function () {
  it("should transfer tokens", async function () {
    const { token, addr1 } = await loadFixture(deployTokenFixture);
    await token.transfer(addr1.address, 100);
    expect(await token.balanceOf(addr1.address)).to.equal(100);
  });
});
```

### 4. Testing Reverts

**Foundry:**
```solidity
function test_RevertWhen_InsufficientBalance() public {
    vm.expectRevert("Insufficient balance");
    myContract.withdraw(1000);
}

function test_RevertWhen_Unauthorized() public {
    vm.prank(address(0xBEEF));
    vm.expectRevert("Ownable: caller is not the owner");
    myContract.adminFunction();
}

// Custom error
function test_RevertWhen_CustomError() public {
    vm.expectRevert(MyContract.InsufficientBalance.selector);
    myContract.withdraw(1000);
}
```

**Hardhat (TypeScript):**
```typescript
import { expect } from "chai";

it("should revert when insufficient balance", async function () {
  await expect(myContract.withdraw(1000))
    .to.be.revertedWith("Insufficient balance");
});

it("should revert with custom error", async function () {
  await expect(myContract.withdraw(1000))
    .to.be.revertedWithCustomError(myContract, "InsufficientBalance");
});
```

### 5. Testing Events

**Foundry:**
```solidity
function test_EmitsTransferEvent() public {
    vm.expectEmit(true, true, false, true);
    emit Transfer(user1, user2, 100);

    vm.prank(user1);
    token.transfer(user2, 100);
}
```

**Hardhat (TypeScript):**
```typescript
import { expect } from "chai";

it("should emit Transfer event", async function () {
  await expect(token.transfer(addr1.address, 100))
    .to.emit(token, "Transfer")
    .withArgs(owner.address, addr1.address, 100);
});
```

## Advanced Testing Techniques

### Fuzz Testing

**Purpose:** Test with random inputs to find edge cases

**Foundry:**
```solidity
function testFuzz_Transfer(address to, uint256 amount) public {
    // Foundry will call this with random values
    vm.assume(to != address(0));
    vm.assume(amount <= type(uint256).max);

    deal(address(token), user, amount);

    vm.prank(user);
    if (amount <= token.balanceOf(user)) {
        token.transfer(to, amount);
        assertEq(token.balanceOf(to), amount);
    }
}

// Configure fuzzing
/// forge-config: default.fuzz.runs = 1000
/// forge-config: default.fuzz.max-test-rejects = 100000
```

**Hardhat (with Echidna):**
```solidity
contract EchidnaTest is MyContract {
    function echidna_balance_never_negative() public view returns (bool) {
        return balances[msg.sender] >= 0;
    }
}
```

### Invariant Testing

**Purpose:** Properties that should always hold true

**Foundry:**
```solidity
contract InvariantTest is Test {
    MyContract public myContract;
    Handler public handler;

    function setUp() public {
        myContract = new MyContract();
        handler = new Handler(myContract);

        targetContract(address(handler));
    }

    function invariant_TotalSupplyEqualsSumOfBalances() public {
        assertEq(
            myContract.totalSupply(),
            handler.sumOfBalances()
        );
    }

    function invariant_BalancesNeverExceedSupply() public {
        assertTrue(handler.maxBalance() <= myContract.totalSupply());
    }
}

// Handler contract for invariant testing
contract Handler {
    MyContract public myContract;
    uint256 public sumOfBalances;

    constructor(MyContract _myContract) {
        myContract = _myContract;
    }

    function transfer(address to, uint256 amount) public {
        // Bounded random actions
        amount = bound(amount, 0, myContract.balanceOf(msg.sender));
        myContract.transfer(to, amount);
    }
}
```

### Property-Based Testing

**Example Properties:**
```solidity
// Sum of parts equals whole
function invariant_SumEqualsTotal() public {
    uint256 sum = 0;
    for (uint i = 0; i < holders.length; i++) {
        sum += balances[holders[i]];
    }
    assertEq(sum, totalSupply);
}

// Operation reversibility
function test_DepositWithdrawIdentity(uint256 amount) public {
    uint256 balanceBefore = user.balance;

    vm.prank(user);
    vault.deposit{value: amount}();

    vm.prank(user);
    vault.withdraw(amount);

    assertEq(user.balance, balanceBefore);
}

// Monotonic properties
function test_BalanceNeverDecreases() public {
    uint256 balanceBefore = token.balanceOf(user);

    // Some operation that should only increase balance
    token.mint(user, 100);

    assertTrue(token.balanceOf(user) >= balanceBefore);
}
```

## Common Test Scenarios

### Testing Access Control

```solidity
function test_OnlyOwnerCanMint() public {
    vm.prank(owner);
    token.mint(user, 100);  // Should succeed
    assertEq(token.balanceOf(user), 100);
}

function test_RevertWhen_NonOwnerMints() public {
    vm.prank(user);
    vm.expectRevert("Ownable: caller is not the owner");
    token.mint(user, 100);
}

function test_OwnershipTransfer() public {
    address newOwner = address(0xBEEF);

    vm.prank(owner);
    token.transferOwnership(newOwner);

    assertEq(token.owner(), newOwner);

    // New owner can now mint
    vm.prank(newOwner);
    token.mint(user, 100);
    assertEq(token.balanceOf(user), 100);
}
```

### Testing Pausable Contracts

```solidity
function test_PauseStopsTransfers() public {
    // Setup
    deal(address(token), user, 1000);

    // Pause
    vm.prank(owner);
    token.pause();

    // Try transfer
    vm.prank(user);
    vm.expectRevert("Pausable: paused");
    token.transfer(address(0xBEEF), 100);
}

function test_UnpauseRestoresTransfers() public {
    deal(address(token), user, 1000);

    vm.prank(owner);
    token.pause();

    vm.prank(owner);
    token.unpause();

    // Transfer should work now
    vm.prank(user);
    token.transfer(address(0xBEEF), 100);
    assertEq(token.balanceOf(address(0xBEEF)), 100);
}
```

### Testing Reentrancy Protection

```solidity
contract Attacker {
    MyContract public target;
    uint256 public attackCount;

    constructor(MyContract _target) {
        target = _target;
    }

    function attack() public payable {
        target.deposit{value: msg.value}();
        target.withdraw(msg.value);
    }

    receive() external payable {
        if (attackCount < 3) {
            attackCount++;
            target.withdraw(msg.value);
        }
    }
}

function test_ReentrancyProtection() public {
    Attacker attacker = new Attacker(myContract);

    vm.deal(address(attacker), 1 ether);

    vm.expectRevert("ReentrancyGuard: reentrant call");
    attacker.attack{value: 1 ether}();
}
```

### Testing Upgradeable Contracts

```solidity
function test_UpgradePreservesStorage() public {
    // Deploy V1
    MyContractV1 v1 = new MyContractV1();
    v1.initialize(owner);
    v1.setValue(42);

    // Deploy V2
    MyContractV2 v2 = new MyContractV2();

    // Upgrade
    vm.prank(owner);
    // Simulate upgrade (depends on proxy pattern)

    // Verify storage preserved
    assertEq(v2.value(), 42);
}
```

## Cheatcodes (Foundry)

### Time Manipulation

```solidity
// Set block timestamp
vm.warp(block.timestamp + 1 days);

// Set block number
vm.roll(block.number + 100);

// Skip time
skip(1 days);

// Rewind time
rewind(1 hours);
```

### Account Manipulation

```solidity
// Set msg.sender for next call
vm.prank(user);

// Set msg.sender for all subsequent calls
vm.startPrank(user);
vm.stopPrank();

// Create labeled address
address user = makeAddr("user");

// Give ETH to address
vm.deal(user, 100 ether);

// Set token balance
deal(address(token), user, 1000);
```

### Call Manipulation

```solidity
// Expect revert
vm.expectRevert("Error message");

// Expect emit
vm.expectEmit(true, true, false, true);

// Mock calls
vm.mockCall(
    address(token),
    abi.encodeWithSelector(token.balanceOf.selector, user),
    abi.encode(1000)
);
```

### State Snapshots

```solidity
// Take snapshot
uint256 snapshot = vm.snapshot();

// Revert to snapshot
vm.revertTo(snapshot);
```

## Test Coverage

### Measuring Coverage

**Foundry:**
```bash
# Generate coverage report
forge coverage

# Generate detailed report
forge coverage --report lcov

# Generate HTML report
genhtml lcov.info --output-directory coverage

# View specific file
forge coverage --report debug > coverage.txt
```

**Hardhat:**
```bash
# Generate coverage
npx hardhat coverage

# Coverage stored in coverage/index.html
```

### Coverage Goals

- **Line Coverage:** >95%
- **Branch Coverage:** >90%
- **Function Coverage:** 100%
- **Statement Coverage:** >95%

**Focus on:**
- All public/external functions tested
- All access control paths
- All error conditions
- Edge cases (0, max values)
- Integration scenarios

## Testing Best Practices

### 1. Test Naming

**Good:**
```solidity
function test_RevertWhen_WithdrawWithInsufficientBalance() public {}
function test_TransferUpdatesBalances() public {}
function testFuzz_CannotOverflowTotalSupply(uint256 amount) public {}
```

**Bad:**
```solidity
function test1() public {}
function testTransfer() public {}  // Too generic
function test_withdraw() public {}  // Doesn't describe outcome
```

### 2. One Assert Per Concept

```solidity
// ✅ Good: Clear what's being tested
function test_Transfer_UpdatesSenderBalance() public {
    uint256 balanceBefore = token.balanceOf(sender);
    token.transfer(recipient, 100);
    assertEq(token.balanceOf(sender), balanceBefore - 100);
}

function test_Transfer_UpdatesRecipientBalance() public {
    uint256 balanceBefore = token.balanceOf(recipient);
    token.transfer(recipient, 100);
    assertEq(token.balanceOf(recipient), balanceBefore + 100);
}
```

### 3. Test Independence

```solidity
// ✅ Good: Each test is independent
function test_Scenario1() public {
    uint256 snapshot = vm.snapshot();
    // Test logic
    vm.revertTo(snapshot);
}

function test_Scenario2() public {
    // Fresh state from setUp()
}
```

### 4. Meaningful Test Data

```solidity
// ❌ Bad: Magic numbers
function test_Transfer() public {
    token.transfer(address(0x123), 42);
}

// ✅ Good: Named constants
function test_Transfer() public {
    address recipient = makeAddr("recipient");
    uint256 transferAmount = 100 * 10**18;  // 100 tokens
    token.transfer(recipient, transferAmount);
}
```

### 5. Test Edge Cases

```solidity
function test_TransferZeroAmount() public {}
function test_TransferMaxAmount() public {}
function test_TransferToZeroAddress() public {}
function test_TransferToSelf() public {}
function test_TransferWithNoBalance() public {}
```

## Integration Testing

### Cross-Contract Interactions

```solidity
contract IntegrationTest is Test {
    Token public token;
    Vault public vault;
    Oracle public oracle;

    function setUp() public {
        token = new Token();
        oracle = new Oracle();
        vault = new Vault(address(token), address(oracle));
    }

    function test_DepositAndEarn() public {
        // Setup
        deal(address(token), user, 1000);

        vm.startPrank(user);

        // Approve
        token.approve(address(vault), 1000);

        // Deposit
        vault.deposit(1000);

        // Warp time
        vm.warp(block.timestamp + 30 days);

        // Check earnings
        uint256 earned = vault.earned(user);
        assertTrue(earned > 0);

        vm.stopPrank();
    }
}
```

### Forking Mainnet

**Foundry:**
```solidity
contract ForkTest is Test {
    function setUp() public {
        vm.createSelectFork(vm.envString("MAINNET_RPC_URL"));
    }

    function test_InteractWithUniswap() public {
        IUniswapV2Router router = IUniswapV2Router(UNISWAP_ROUTER);
        // Test against real mainnet contracts
    }
}
```

**Hardhat (TypeScript):**
```typescript
import { ethers, network } from "hardhat";
import { IUniswapV2Router } from "../typechain-types";

describe("Fork Test", function () {
  before(async function () {
    await network.provider.request({
      method: "hardhat_reset",
      params: [{
        forking: {
          jsonRpcUrl: process.env.MAINNET_RPC_URL,
          blockNumber: 15000000
        }
      }]
    });
  });

  it("should interact with Uniswap", async function () {
    const ROUTER_ADDRESS: string = "0x...";
    const router: IUniswapV2Router = await ethers.getContractAt(
      "IUniswapV2Router",
      ROUTER_ADDRESS
    );
    // Test
  });
});
```

## Quick Reference

### Foundry Commands (Solidity Tests)

```bash
# Run tests
forge test

# Run specific test
forge test --match-test test_Transfer

# Run with gas report
forge test --gas-report

# Run with coverage
forge coverage

# Run with verbosity
forge test -vvvv

# Fuzz testing
forge test --fuzz-runs 10000
```

### Hardhat Commands (TypeScript Tests)

```bash
# Run tests
npx hardhat test

# Run specific test
npx hardhat test test/MyContract.test.ts

# With gas reporter
REPORT_GAS=true npx hardhat test

# With coverage
npx hardhat coverage
```

---

**Remember:** Good tests are the first line of defense against bugs and vulnerabilities. Aim for comprehensive coverage, but focus on meaningful test scenarios over arbitrary coverage percentages.
