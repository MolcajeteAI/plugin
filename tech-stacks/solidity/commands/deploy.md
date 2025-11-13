---
description: Deploy contracts to specified network with verification
---

IMPORTANT: Immediately use the Task tool with subagent_type="sol:deployer" to delegate ALL work to the deployer agent. Do NOT do any analysis or work in the main context.

Use this exact prompt for the agent:
"Execute the contract deployment workflow following these steps:

1. **Ask User for Target Network**
   - Use AskUserQuestion to ask:
     - Question: \"Which network should I deploy to?\"
     - Header: \"Network\"
     - Options:
       - \"Sepolia\" - Ethereum testnet
       - \"Mumbai\" - Polygon testnet
       - \"Mainnet\" - Ethereum mainnet (requires audit)
     - multiSelect: false
   - If user selects Other, ask them to specify network name

2. **Verify Pre-Deployment Checklist**
   - Follow **deployment** skill pre-deployment requirements
   - Check:
     - All tests passing (run forge test or npx hardhat test)
     - Test coverage >95% if possible
     - Security audit completed (REQUIRED for mainnet, check for audit report)
     - Constructor parameters prepared and verified
     - Deployment account funded (check balance)
     - RPC URL configured in environment
     - Block explorer API key configured for verification
   - If mainnet deployment and no audit found, STOP and warn user
   - Show checklist status to user before proceeding

3. **Detect Framework and Execute Deployment**
   - Use **framework-detection** skill to identify Foundry/Hardhat/Hybrid
   - **For Foundry:**
     ```bash
     # Deploy to network
     forge script script/Deploy.s.sol \
       --rpc-url $NETWORK_RPC_URL \
       --broadcast \
       --verify \
       --etherscan-api-key $ETHERSCAN_API_KEY
     ```
   - **For Hardhat:**
     ```bash
     # Deploy to network
     npx hardhat run scripts/deploy.ts --network NETWORK_NAME

     # Verify separately
     npx hardhat verify --network NETWORK_NAME DEPLOYED_ADDRESS [constructor args]
     ```
   - Capture deployment transaction hash and deployed address
   - If deployment fails, show error and help user troubleshoot

4. **Verify Contract on Block Explorer**
   - **For Foundry:** Verification happens automatically with --verify flag
   - **For Hardhat:** Run separate verification command
   - Confirm contract is verified by checking block explorer
   - If verification fails, help user debug (check compiler version, optimization settings, constructor args)

5. **Save Deployment Information**
   - Create or update deployments/NETWORK_NAME.json with:
     - Contract address
     - Implementation address (if upgradeable)
     - Deployer address
     - Block number
     - Transaction hash
     - Timestamp
     - Constructor arguments
     - Verification status
   - Use Write tool to save deployment info

6. **Run Post-Deployment Validation**
   - Verify contract code exists:
     ```bash
     cast code DEPLOYED_ADDRESS --rpc-url $RPC_URL
     ```
   - Test view functions:
     ```bash
     cast call DEPLOYED_ADDRESS \"owner()(address)\" --rpc-url $RPC_URL
     cast call DEPLOYED_ADDRESS \"name()(string)\" --rpc-url $RPC_URL
     ```
   - Confirm verification on block explorer (visit URL and check)
   - Run a test transaction if safe to do so

7. **Generate Deployment Report**
   - Display complete deployment summary:
     ```
     Deployment Summary
     ==================
     Network: [network name]
     Contract Address: [address]
     Transaction Hash: [hash]
     Block Number: [number]
     Deployer: [address]
     Verified: [yes/no]

     Validation Results:
     - Contract code exists: ✓
     - Owner function works: ✓
     - Block explorer verification: ✓

     Deployment info saved to: deployments/[network].json

     Next steps:
     - Test critical functions
     - Transfer ownership if needed
     - Update documentation
     ```

Follow your agent instructions in agents/deployer.md and reference the deployment and framework-detection skills."
