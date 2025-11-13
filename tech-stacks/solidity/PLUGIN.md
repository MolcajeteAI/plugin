---
id: sol
name: Solidity Development Plugin
version: 1.0.0
description: Smart contract development, testing, auditing, and deployment for Solidity
techStackKeywords:
  - solidity
  - smart contract
  - smart contracts
  - blockchain
  - foundry
  - hardhat
  - ethereum
  - evm
  - web3
---

# Solidity Plugin

Comprehensive toolkit for Solidity smart contract development, from implementation through deployment.

## Agents

### sol:developer
**Description:** Implements Solidity smart contracts following security best practices, gas optimization, and proper NatSpec documentation

**Capabilities:**
- smart-contract-development
- natspec-documentation
- code-quality
- framework-integration

**Use When:**
- Implementing new smart contracts
- Adding features to existing contracts
- Refactoring Solidity code
- Compiling contracts

**Tools:** Read, Write, Edit, Bash, Grep, Glob, AskUserQuestion

---

### sol:tester
**Description:** Writes comprehensive tests (unit, integration, fuzz, invariant) for Solidity contracts

**Capabilities:**
- unit-testing
- integration-testing
- fuzz-testing
- invariant-testing
- coverage-analysis

**Use When:**
- Writing tests for contracts
- Improving test coverage
- Testing security properties
- Running test suites

**Tools:** Read, Write, Edit, Bash, Grep, Glob

---

### sol:auditor
**Description:** Performs security audits using Slither, Mythril, and Echidna

**Capabilities:**
- security-analysis
- vulnerability-detection
- static-analysis
- fuzzing

**Use When:**
- Before deployment to testnet/mainnet
- After significant contract changes
- Security reviews and audits
- Checking for vulnerabilities

**Tools:** Read, Bash, Grep, Glob

**Note:** READ-ONLY access. Cannot modify code. Identifies issues and recommends fixes.

---

### sol:gas-optimizer
**Description:** Analyzes and optimizes gas consumption in Solidity contracts with before/after benchmarks

**Capabilities:**
- gas-analysis
- optimization
- benchmarking

**Use When:**
- Optimizing gas costs for contracts
- Establishing gas baselines
- Comparing gas usage across versions
- Production deployment preparation

**Tools:** Read, Edit, Bash, Grep, Glob

---

### sol:deployer
**Description:** Deploys contracts to multiple chains with verification

**Capabilities:**
- multi-chain-deployment
- contract-verification
- deployment-validation

**Use When:**
- Deploying to testnet or mainnet
- Multi-chain deployments
- Contract verification on block explorers
- Production deployments

**Tools:** Read, Write, Bash, AskUserQuestion, Grep, Glob

---

### sol:upgrader
**Description:** Implements and validates proxy patterns for upgradeable contracts (UUPS, Transparent, Beacon, Diamond)

**Capabilities:**
- upgrade-implementation
- proxy-patterns
- storage-validation
- upgrade-safety

**Use When:**
- Implementing upgradeable contracts
- Planning contract upgrades
- Validating storage layout compatibility
- Executing upgrade deployments

**Tools:** Read, Write, Edit, Bash, Grep, Glob

---

### sol:debugger
**Description:** Debugs failed transactions and tests using trace analysis

**Capabilities:**
- transaction-debugging
- trace-analysis
- error-diagnosis

**Use When:**
- Tests are failing
- Transactions revert unexpectedly
- Investigating contract behavior issues
- Production issue investigation

**Tools:** Read, Bash, Grep, Glob

---

## Skills

### Core Development
- **contract-patterns**: Standard patterns (ERC20, ERC721, ERC1155, access control, pausable, upgradeable)
- **code-quality**: Code quality standards, linting rules, naming conventions, error naming philosophy
- **natspec-standards**: Documentation standards for contracts and functions

### Security & Testing
- **security-audit**: Comprehensive audit methodology, checklists, and tool usage
- **vulnerability-patterns**: Common vulnerabilities (reentrancy, access control, etc.) and prevention
- **testing-patterns**: Test design patterns, coverage analysis, and best practices

### Optimization & Gas
- **gas-optimization**: Gas optimization techniques (storage packing, cached reads, loop optimization)
- **coverage-analysis**: Test coverage reporting and improvement strategies

### Upgrades & Deployment
- **proxy-patterns**: Upgradeable contract patterns (UUPS, Transparent, Beacon, Diamond)
- **upgrade-safety**: Safe upgrade practices, storage layout preservation, initializer protection
- **deployment**: Deployment strategies, multi-chain deployment, verification best practices

### Framework Support
- **framework-detection**: Automatic detection of Foundry, Hardhat, or Hybrid setups
- **foundry-setup**: Foundry project initialization and configuration
- **hardhat-setup**: Hardhat project initialization and configuration

---

## Commands

The plugin provides slash commands for common Solidity development tasks:

- `/sol:init` - Initialize new Solidity project (Foundry/Hardhat)
- `/sol:compile` - Compile contracts
- `/sol:test` - Run test suite
- `/sol:coverage` - Generate coverage report
- `/sol:audit` - Perform security audit
- `/sol:deploy` - Deploy contracts to network
- `/sol:upgrade` - Execute contract upgrade
- `/sol:optimize-gas` - Analyze and optimize gas
- `/sol:debug` - Debug failed transactions/tests
- `/sol:fork` - Run tests against forked network

See individual command files in `commands/` for detailed usage.

---

## Integration Notes

**For Product Orchestrator:**

When `tech-stack.md` mentions Solidity-related keywords, the orchestrator should:
1. Load this plugin metadata
2. Select appropriate agents based on task requirements
3. Delegate to sol:* agents for Solidity-specific work

**Example Task Mapping:**
- "Implement smart contract" → `sol:developer`
- "Write tests for contract" → `sol:tester`
- "Security audit before deployment" → `sol:auditor`
- "Deploy to mainnet" → `sol:deployer`
- "Optimize gas usage" → `sol:gas-optimizer`
- "Debug failing test" → `sol:debugger`
- "Implement upgrade" → `sol:upgrader`

**Agent Chaining:**
Common workflows that chain multiple agents:
1. Development → Testing → Auditing → Deployment
   - `sol:developer` → `sol:tester` → `sol:auditor` → `sol:deployer`

2. Gas Optimization → Testing → Benchmarking
   - `sol:gas-optimizer` → `sol:tester` (verify correctness)

3. Upgrade Implementation → Validation → Testing → Deployment
   - `sol:upgrader` → `sol:tester` → `sol:deployer`

---

## Version History

**1.0.0** (Current)
- Initial plugin metadata
- 7 specialized agents (developer, tester, auditor, gas-optimizer, deployer, upgrader, debugger)
- 14 skills covering all aspects of Solidity development
- Foundry and Hardhat support
- Multi-chain deployment capability
