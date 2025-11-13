---
description: Full build with compilation and artifact generation
---

# Build Project

Full build with compilation and artifact generation.

Use the Task tool to launch the **developer** agent with the following instructions:

1. Detect project framework using framework-detection skill
2. Clean any existing artifacts
3. Compile all contracts
4. Generate type definitions (if Hardhat with TypeChain)
5. Verify build artifacts are created
6. Report build summary with contract count, warnings, and artifact locations

Reference the framework-detection skill.
