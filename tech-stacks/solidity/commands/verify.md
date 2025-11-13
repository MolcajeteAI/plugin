---
description: Verify contract source code on block explorer
---

# Verify Contract

Verify contract source code on block explorer.

Use the Task tool to launch the **deployer** agent with the following instructions:

1. Ask user for:
   - Contract address
   - Network
   - Constructor arguments (if any)
2. Detect framework and verify:
   - Foundry: `forge verify-contract --verification-method standard-json-input`
   - Hardhat: `npx hardhat verify`
3. Handle verification process:
   - Submit source code using Standard JSON Input format (Foundry)
   - Wait for verification
   - Handle any errors (wrong compiler version, constructor args, etc.)
4. Verify success on block explorer
5. Report verification status with block explorer link

**Note:** Always use `--verification-method standard-json-input` with Foundry for consistent verification.

Reference the framework-detection and deployment skills.
