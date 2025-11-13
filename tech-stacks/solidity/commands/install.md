---
description: Install project dependencies based on the framework
---

# Install Dependencies

Install project dependencies based on the framework.

Use the Task tool to launch the **developer** agent with the following instructions:

1. Detect project framework using framework-detection skill
2. Install dependencies:
   - Foundry: Install forge-std and any git dependencies listed in foundry.toml
   - Hardhat: Run `npm install` or `yarn install`
   - Hybrid: Install for both frameworks
3. Install commonly used libraries if requested (OpenZeppelin, Solmate, etc.)
4. Update remappings (Foundry) or imports (Hardhat) as needed
5. Report installed packages and versions

Reference the framework-detection, setup-foundry, and setup-hardhat skills.
