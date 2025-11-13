---
description: Run linting checks on Solidity code
---

# Lint Code

Run linting checks on Solidity code.

Use the Task tool to launch the **developer** agent with the following instructions:

1. Detect project framework using framework-detection skill
2. Run linting:
   - Foundry: Check code style with `forge fmt --check`
   - Hardhat: Run solhint if configured
3. Check for common issues:
   - Style violations
   - Unused variables
   - Deprecated syntax
   - Missing documentation
4. Report linting results with file and line references
5. Suggest fixes for violations

Reference the framework-detection and code-style skills.
