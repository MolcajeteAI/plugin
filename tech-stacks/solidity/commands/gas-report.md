---
description: Generate gas usage report for contract functions
---

# Generate Gas Report

Generate gas usage report for contract functions.

Use the Task tool to launch the **gas-optimizer** agent with the following instructions:

1. Detect project framework using framework-detection skill
2. Generate gas report:
   - Foundry: `forge test --gas-report`
   - Hardhat: `REPORT_GAS=true npx hardhat test`
3. Analyze gas usage by function
4. Identify expensive operations
5. Compare with previous snapshots if available
6. Report gas usage summary with cost estimates at current gas prices
7. Suggest optimization opportunities for high-gas functions

Reference the framework-detection and gas-optimization skills.
