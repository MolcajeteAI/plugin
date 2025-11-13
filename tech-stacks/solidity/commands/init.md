---
description: Initialize a new Solidity project with Foundry or Hardhat
---

# Initialize Solidity Project

Initialize a new Solidity project with framework auto-detection or user prompt.

Use the Task tool to launch the **developer** agent with the following instructions:

1. Detect if a framework is already present (check for foundry.toml or hardhat.config.js/ts)
2. If no framework detected, use AskUserQuestion to ask:
   - Question: "Which Solidity development framework should I initialize?"
   - Header: "Framework"
   - Options:
     - "Foundry" - Fast Solidity testing framework with native Solidity tests
     - "Hardhat" - Flexible Ethereum development environment with TypeScript tests
     - "Hybrid" - Both Foundry and Hardhat for maximum flexibility
   - multiSelect: false
3. Initialize the selected framework(s) following the setup-foundry and setup-hardhat skills
4. Set up project structure with recommended directories
5. Create initial contract files with templates if requested
6. Install dependencies
7. Report completion with next steps

Reference the framework-detection and relevant setup skills.
