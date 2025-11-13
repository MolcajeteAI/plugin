---
description: Launch interactive console for contract interaction
---

# Interactive Console

Launch interactive console for contract interaction.

Use the Task tool to launch the **developer** agent with the following instructions:

1. Detect framework:
   - Foundry: Launch `cast` for network interactions or explain interactive chisel usage
   - Hardhat: Launch `npx hardhat console`
2. For Foundry, provide common cast commands:
   - `cast call [contract] "[signature]"` - Call view function
   - `cast send [contract] "[signature]"` - Send transaction
   - `cast storage [contract] [slot]` - Read storage
   - `cast 4byte [selector]` - Decode function selector
3. For Hardhat console, show example usage:
   - Loading contract factory
   - Connecting to deployed contracts
   - Calling functions
   - Checking balances and state
4. Provide relevant examples based on contracts in project

Reference the framework-detection skill.
