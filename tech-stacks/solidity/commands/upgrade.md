---
description: Execute safe contract upgrade for proxy patterns
---

# Upgrade Contract

Execute safe contract upgrade for proxy patterns.

Use the Task tool to launch the **upgrader** agent with the following instructions:

1. Verify this is an upgradeable contract (detect proxy pattern)
2. Run pre-upgrade checklist:
   - Storage layout compatibility check
   - New implementation tested
   - Authorization function present
   - All tests passing
3. Use AskUserQuestion to ask for proxy address:
   - Question: "What is the proxy contract address to upgrade?"
   - Header: "Proxy Address"
   - Options: [User must type address in Other field]
4. Use AskUserQuestion to ask for target network:
   - Question: "Which network is the proxy deployed on?"
   - Header: "Network"
   - Options:
     - "Sepolia" - Ethereum testnet
     - "Mainnet" - Ethereum mainnet (requires extra caution)
     - "Polygon" - Polygon mainnet
     - "Arbitrum" - Arbitrum One mainnet
   - multiSelect: false
5. Use AskUserQuestion to ask about reinitializer:
   - Question: "Does the new implementation have a reinitializer function to call after upgrade?"
   - Header: "Reinitializer"
   - Options:
     - "Yes" - Call reinitializer function after upgrade
     - "No" - Skip reinitializer (no new state to initialize)
   - multiSelect: false
6. Validate upgrade safety:
   - Foundry: Compare storage layouts with `forge inspect`
   - Hardhat: Use `upgrades.validateUpgrade()`
7. Execute upgrade:
   - Deploy new implementation
   - Upgrade proxy to new implementation
   - Call reinitializer if needed
8. Verify upgrade:
   - Check implementation address updated
   - Test functionality
   - Verify storage preserved
9. Report upgrade results

Reference the framework-detection, proxy-patterns, and upgrade-safety skills.
