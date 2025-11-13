---
description: Compile Solidity contracts using the detected framework
---

# Compile Contracts

Compile Solidity contracts using the detected framework.

Use the Task tool to launch the **developer** agent with the following instructions:

1. Detect the project framework (Foundry, Hardhat, or Hybrid) using framework-detection skill
2. Compile contracts using the appropriate command:
   - Foundry: `forge build`
   - Hardhat: `npx hardhat compile`
   - Hybrid: Compile with both
3. Report any compilation errors with file and line references
4. Show compilation artifacts location
5. Report success with contract count and any warnings

Reference the framework-detection skill.
