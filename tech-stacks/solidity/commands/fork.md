---
description: Run tests against a forked network
---

# Fork Testing

Run tests against a forked network.

Use the Task tool to launch the **tester** agent with the following instructions:

1. Use AskUserQuestion to ask:
   - Question: "Which network should I fork for testing?"
   - Header: "Network"
   - Options:
     - "Ethereum Mainnet" - Fork Ethereum mainnet
     - "Arbitrum One" - Fork Arbitrum mainnet
     - "Polygon" - Fork Polygon mainnet
     - "Optimism" - Fork Optimism mainnet
     - "Base" - Fork Base mainnet
   - multiSelect: false
2. If user needs specific block, use AskUserQuestion to ask:
   - Question: "Fork at specific block number? (Leave blank for latest)"
   - Header: "Block"
   - Options: [User can type block number in Other field, or leave blank for latest]
3. Detect framework and run fork tests:
   - Foundry: `forge test --fork-url $RPC_URL --fork-block-number [block]`
   - Hardhat: Configure hardhat network fork in config, then run tests
3. Run tests against forked state
4. Report test results
5. Show any integration issues with mainnet state
6. Report fork block number and network used

Reference the framework-detection and testing-patterns skills.
