# Solidity Development Plugin

Professional Solidity smart contract development with comprehensive support for Foundry and Hardhat frameworks.

## Overview

This plugin provides a complete workflow for Solidity development including:
- Multi-framework support (Foundry, Hardhat, or Hybrid)
- Smart contract development with security-first approach
- Comprehensive testing (unit, integration, fuzz, invariant)
- Gas optimization with benchmarking
- Security auditing with automated tools
- Multi-chain deployment
- Upgradeable contract patterns
- Interactive debugging

## Requirements

**Core:**
- Solidity ^0.8.0
- Node.js >= 18 (for Hardhat)

**Foundry (recommended):**
- [Foundry](https://book.getfoundry.sh/getting-started/installation) (forge, cast, anvil)

**Hardhat:**
- npm or yarn
- TypeScript (for tests)

**Optional Tools:**
- [Slither](https://github.com/crytic/slither) - Static analysis
- [Mythril](https://github.com/ConsenSys/mythril) - Symbolic execution
- [Echidna](https://github.com/crytic/echidna) - Fuzzing

## Installation

The plugin is registered in the local marketplace and will be available after marketplace installation.

## Quick Start

```bash
# Initialize new project
/sol:init

# Compile contracts
/sol:compile

# Run tests
/sol:test

# Generate coverage report
/sol:coverage

# Deploy to testnet
/sol:deploy
```

## Commands

### Project Setup
- `/sol:init` - Initialize new Solidity project with framework selection
- `/sol:install` - Install dependencies
- `/sol:clean` - Clean build artifacts

### Development
- `/sol:compile` - Compile contracts
- `/sol:build` - Full build with artifacts
- `/sol:format` - Format code
- `/sol:lint` - Lint code

### Testing
- `/sol:test` - Run tests (Solidity for Foundry, TypeScript for Hardhat)
- `/sol:coverage` - Generate coverage report
- `/sol:fork` - Run fork tests
- `/sol:snapshot` - Create/compare gas snapshots

### Optimization & Analysis
- `/sol:gas-report` - Generate gas usage report
- `/sol:analyze` - Run static analysis (Slither)
- `/sol:audit` - Comprehensive security audit

### Deployment
- `/sol:deploy` - Deploy contracts with verification
- `/sol:verify` - Verify contract on block explorer
- `/sol:upgrade` - Upgrade proxy contracts

### Debugging
- `/sol:debug` - Debug failed transaction or test
- `/sol:console` - Interactive console

## Agents

Specialized agents handle complex workflows:

### Developer Agent
Smart contract implementation with:
- Security-first development
- NatSpec documentation
- Framework integration
- Code quality standards

### Tester Agent
Comprehensive testing with:
- Unit tests
- Integration tests
- Fuzz testing
- Invariant testing
- Framework-appropriate language (Solidity/TypeScript)

### Gas Optimizer Agent
Gas optimization with:
- Baseline benchmarking
- Optimization implementation
- Before/after comparison
- Regression detection

### Auditor Agent
Security auditing with:
- Slither static analysis
- Mythril symbolic execution
- Echidna fuzzing
- Manual code review
- Comprehensive audit reports

### Deployer Agent
Multi-chain deployment with:
- Testnet/mainnet deployment
- Contract verification
- Deployment validation
- Hardware wallet support

### Debugger Agent
Transaction debugging with:
- Trace analysis
- Test debugging
- Execution flow analysis
- Revert investigation

### Upgrader Agent
Upgradeable contracts with:
- Proxy pattern implementation
- Storage layout validation
- Safe upgrade execution
- Upgrade testing

## Skills

### Framework Support
- **framework-detection** - Auto-detect Foundry/Hardhat/Hybrid
- **setup-foundry** - Foundry project setup
- **setup-hardhat** - Hardhat project setup

### Development Standards
- **code-style** - Solidity style guide
- **code-principles** - Best practices and patterns
- **natspec** - Documentation standards

### Contract Patterns
- **contract-patterns/** - Common patterns library
  - Access control
  - Token standards (ERC20, ERC721, ERC1155)
  - Proxy patterns (UUPS, Transparent, Beacon, Diamond)
  - Reentrancy guards
  - Pull payments
  - State machines

### Testing
- **testing-patterns** - Testing strategies
  - Foundry: Solidity tests
  - Hardhat: TypeScript tests with strict typing
  - Unit, integration, fuzz, invariant tests

### Security
- **security-audit/** - Security audit methodology
  - Audit checklists
  - Vulnerability patterns
  - Tool usage guides
- **upgrade-safety** - Safe upgrade practices

### Optimization
- **gas-optimization** - Gas optimization techniques
  - Storage optimization
  - Loop optimization
  - Function optimization
  - Data structure optimization

### Deployment
- **deployment** - Multi-chain deployment strategies
- **proxy-patterns** - Upgradeable contract patterns

## Framework Support

### Foundry Projects
- Uses `forge`, `cast`, and `anvil`
- Solidity-based tests
- Built-in fuzz and invariant testing
- Fast compilation and testing
- Gas snapshots

### Hardhat Projects
- Uses npm/yarn ecosystem
- TypeScript tests with strict typing
- Rich plugin ecosystem
- OpenZeppelin Upgrades plugin
- TypeChain for type generation

### Hybrid Projects
- Use both frameworks in same project
- Foundry for testing and gas optimization
- Hardhat for deployment and verification
- Best of both worlds

## Supported Networks

- **Ethereum**: Mainnet, Sepolia, Goerli
- **Polygon**: Mainnet, Mumbai
- **Arbitrum**: One, Goerli
- **Optimism**: Mainnet, Goerli
- **Base**: Mainnet, Goerli
- **Avalanche**: C-Chain, Fuji
- **BNB Chain**: Mainnet, Testnet

## Workflow Examples

### Develop New Contract

```bash
# Initialize project
/sol:init

# Develop contract (developer agent)
"Implement ERC20 token with burn capability"

# Write tests (tester agent)
"Write comprehensive tests for the token"

# Check coverage
/sol:coverage

# Optimize gas
/sol:gas-report

# Run security audit
/sol:audit
```

### Deploy to Production

```bash
# Run full test suite
/sol:test

# Generate coverage
/sol:coverage

# Security audit
/sol:audit

# Deploy to testnet
/sol:deploy

# Test on testnet
"Test all functions on Sepolia"

# Deploy to mainnet
/sol:deploy
```

### Implement Upgradeable Contract

```bash
# Initialize with UUPS pattern
"Implement MyContract with UUPS upgradeability"

# Test upgrade scenario
"Write upgrade tests from V1 to V2"

# Deploy proxy
/sol:deploy

# Later: upgrade
/sol:upgrade
```

### Debug Failed Transaction

```bash
# Debug specific test
/sol:debug

# Analyze traces
"What caused the revert in test_transfer?"

# Fix and retest
/sol:test
```

## Security Best Practices

The plugin enforces security-first development:

1. **Access Control**: All admin functions must be protected
2. **Reentrancy**: CEI pattern and ReentrancyGuard usage
3. **Integer Safety**: Solidity 0.8+ with overflow checks
4. **Input Validation**: All external inputs validated
5. **Custom Errors**: Gas-efficient error handling
6. **NatSpec**: Comprehensive documentation
7. **Testing**: >95% coverage with fuzz/invariant tests
8. **Auditing**: Automated tools + manual review before deployment

## Gas Optimization Guidelines

1. **Storage Optimization**: Pack variables, use appropriate types
2. **Caching**: Cache storage reads in memory
3. **Constants**: Use `constant` and `immutable`
4. **Custom Errors**: Replace require strings
5. **Loop Optimization**: Cache length, unchecked increment
6. **Function Visibility**: Use `external` when appropriate
7. **Benchmark**: Always measure before/after

## Testing Standards

### Foundry (Solidity Tests)
```solidity
contract MyContractTest is Test {
    function test_Function() public {
        // Unit test
    }

    function testFuzz_Function(uint256 x) public {
        // Fuzz test
    }

    function invariant_Property() public {
        // Invariant test
    }
}
```

### Hardhat (TypeScript Tests)
```typescript
import { expect } from "chai";
import { ethers } from "hardhat";
import { MyContract } from "../typechain-types";

describe("MyContract", function () {
  let contract: MyContract;

  beforeEach(async function () {
    const Factory = await ethers.getContractFactory("MyContract");
    contract = await Factory.deploy();
  });

  it("should work correctly", async function () {
    // Type-safe test
  });
});
```

## Architecture

The plugin follows the Claude Code plugin architecture:

1. **Commands** → Trigger agents with minimal logic
2. **Agents** → Orchestrate workflows and decision-making
3. **Skills** → Provide detailed rules and standards

This separation ensures:
- Commands are simple entry points
- Agents control the flow
- Skills contain all domain knowledge
- Easy maintenance and updates

## Integration with Product Management

When working with product specifications:
- Agents can read from `.molcajete/prd/specs/` via prd:orchestrator
- Agents can check `.molcajete/prd/specs/{spec}/tasks.md` for implementation tasks
- Automatic context gathering for informed development

## Tips

1. **Start with Foundry**: Faster development and testing
2. **Use Hybrid**: Add Hardhat for deployment and verification
3. **Test First**: Write tests before implementation when possible
4. **Run Audits Early**: Catch security issues during development
5. **Optimize Last**: Correctness before optimization
6. **Use Fork Tests**: Test against real mainnet state
7. **Hardware Wallets**: Always for mainnet deployments
8. **Monitor Gas**: Use snapshots to catch regressions

## Troubleshooting

### Compilation Issues
```bash
# Clean and rebuild
/sol:clean
/sol:compile
```

### Test Failures
```bash
# Run with full traces
/sol:debug
```

### Gas Regressions
```bash
# Check differences
/sol:snapshot
```

### Security Concerns
```bash
# Full audit
/sol:audit
```

## Contributing

When extending this plugin:
1. Follow the architecture (commands → agents → skills)
2. Keep commands minimal
3. Put logic in agents
4. Put rules in skills
5. Test thoroughly

## License

This plugin is part of the Claude Code local marketplace.

---

**Note**: This plugin emphasizes security and best practices. Always audit smart contracts before production deployment.
