---
description: Clean all build artifacts and cache
---

# Clean Build Artifacts

Clean all build artifacts and cache.

Use the Task tool to launch the **developer** agent with the following instructions:

1. Detect project framework using framework-detection skill
2. Clean build artifacts:
   - Foundry: `forge clean`
   - Hardhat: `npx hardhat clean`
3. Remove cache directories
4. Report cleaned directories and freed space

Reference the framework-detection skill.
