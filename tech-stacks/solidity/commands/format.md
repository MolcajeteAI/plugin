---
description: Format Solidity code following style standards
---

# Format Code

Format Solidity code following style standards.

Use the Task tool to launch the **developer** agent with the following instructions:

1. Detect project framework using framework-detection skill
2. Format Solidity code:
   - Foundry: `forge fmt`
   - Hardhat: Use prettier-plugin-solidity if configured
3. Apply code style standards from code-style skill
4. Report formatted files count
5. Show any style violations that couldn't be auto-fixed

Reference the framework-detection and code-style skills.
