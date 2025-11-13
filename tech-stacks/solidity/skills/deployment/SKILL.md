---
name: deployment
description: Deployment strategies, scripts, and best practices for Solidity smart contracts. Use when deploying contracts to testnets or mainnet.
---

# Deployment Skill

This skill provides deployment strategies, scripts, and best practices for deploying Solidity smart contracts with Foundry and Hardhat.

## When to Use

Use this skill when:
- Deploying contracts to testnets or mainnet
- Writing deployment scripts
- Setting up multi-chain deployments
- Managing contract upgrades
- Verifying deployed contracts

## Deployment Checklist

### Pre-Deployment

- [ ] **Code Complete**
  - All features implemented
  - Tests passing (>95% coverage)
  - Security audit completed (for production)
  - Gas optimization done

- [ ] **Configuration**
  - Network RPC URLs configured
  - Deployment account secured (hardware wallet preferred)
  - Gas price strategy determined
  - Environment variables set

- [ ] **Documentation**
  - Deployment plan documented
  - Constructor parameters documented
  - Initial configuration values defined
  - Verification plan ready

- [ ] **Testing**
  - Deployed and tested on local network
  - Deployed and tested on testnet
  - Integration tests passing
  - Upgrade path tested (if upgradeable)

### During Deployment

- [ ] Deploy to testnet first
- [ ] Verify deployment address
- [ ] Initialize contract (if upgradeable)
- [ ] Configure contract parameters
- [ ] Transfer ownership/roles if needed
- [ ] Verify contract on block explorer

### Post-Deployment

- [ ] Verify all functions work correctly
- [ ] Document deployed addresses
- [ ] Set up monitoring
- [ ] Create emergency procedures
- [ ] Announce deployment

## Foundry Deployment

### Basic Deployment Script

```solidity
// script/Deploy.s.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {Script} from "forge-std/Script.sol";
import {MyContract} from "../src/MyContract.sol";

contract DeployScript is Script {
    function run() external {
        // Load deployer private key
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");

        // Start broadcasting transactions
        vm.startBroadcast(deployerPrivateKey);

        // Deploy contract
        MyContract myContract = new MyContract(
            vm.envAddress("INITIAL_OWNER")
        );

        // Log deployment address
        console.log("MyContract deployed to:", address(myContract));

        // Stop broadcasting
        vm.stopBroadcast();
    }
}
```

### Secure Deployment (Hardware Wallet)

```solidity
contract DeployScript is Script {
    function run() external {
        // Use --ledger flag when running script
        // No private key in environment

        vm.startBroadcast();

        MyContract myContract = new MyContract(msg.sender);

        vm.stopBroadcast();
    }
}
```

**Run with Ledger:**
```bash
forge script script/Deploy.s.sol --rpc-url $SEPOLIA_RPC_URL --ledger --broadcast --verify
```

### Deployment with Constructor Parameters

```solidity
contract DeployScript is Script {
    function run() external returns (MyContract) {
        vm.startBroadcast();

        // Get parameters from environment or hardcode
        address owner = vm.envAddress("OWNER");
        uint256 initialSupply = vm.envUint("INITIAL_SUPPLY");
        string memory name = vm.envString("TOKEN_NAME");

        MyContract myContract = new MyContract(
            owner,
            initialSupply,
            name
        );

        vm.stopBroadcast();

        return myContract;
    }
}
```

### Deploy and Verify

```bash
# Deploy to testnet with verification
forge script script/Deploy.s.sol \
  --rpc-url $SEPOLIA_RPC_URL \
  --broadcast \
  --verify \
  --etherscan-api-key $ETHERSCAN_API_KEY

# Deploy to mainnet
forge script script/Deploy.s.sol \
  --rpc-url $MAINNET_RPC_URL \
  --broadcast \
  --verify \
  --etherscan-api-key $ETHERSCAN_API_KEY \
  --slow  # Use for mainnet to avoid nonce issues
```

### Multi-Contract Deployment

```solidity
contract DeployScript is Script {
    function run() external {
        vm.startBroadcast();

        // Deploy in order
        Token token = new Token();
        console.log("Token:", address(token));

        Oracle oracle = new Oracle();
        console.log("Oracle:", address(oracle));

        Vault vault = new Vault(address(token), address(oracle));
        console.log("Vault:", address(vault));

        // Configure relationships
        token.setVault(address(vault));
        oracle.addAuthorized(address(vault));

        vm.stopBroadcast();
    }
}
```

### Deployment with CREATE2 (Deterministic Address)

```solidity
contract DeployScript is Script {
    function run() external {
        vm.startBroadcast();

        bytes32 salt = bytes32(uint256(1));  // Choose salt for deterministic address

        MyContract myContract = new MyContract{salt: salt}();

        console.log("Deployed to:", address(myContract));

        vm.stopBroadcast();
    }
}
```

## Hardhat Deployment

### Basic Deployment Script (TypeScript)

```typescript
// scripts/deploy.ts
import { ethers } from "hardhat";

async function main() {
  // Get signer
  const [deployer] = await ethers.getSigners();
  console.log("Deploying with account:", deployer.address);

  // Check balance
  const balance = await ethers.provider.getBalance(deployer.address);
  console.log("Account balance:", ethers.formatEther(balance), "ETH");

  // Deploy contract
  const MyContract = await ethers.getContractFactory("MyContract");
  const myContract = await MyContract.deploy();

  await myContract.waitForDeployment();

  const address = await myContract.getAddress();
  console.log("MyContract deployed to:", address);

  // Wait for block confirmations before verification
  console.log("Waiting for block confirmations...");
  await myContract.deploymentTransaction()?.wait(5);

  // Verify on Etherscan
  if (process.env.ETHERSCAN_API_KEY) {
    console.log("Verifying contract...");
    await run("verify:verify", {
      address: address,
      constructorArguments: [],
    });
  }
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
```

### Deployment with Constructor Parameters

```typescript
async function main() {
  const [deployer] = await ethers.getSigners();

  // Get parameters
  const initialOwner = process.env.INITIAL_OWNER || deployer.address;
  const initialSupply = ethers.parseEther("1000000");

  // Deploy
  const Token = await ethers.getContractFactory("Token");
  const token = await Token.deploy(initialOwner, initialSupply);

  await token.waitForDeployment();

  const address = await token.getAddress();
  console.log("Token deployed to:", address);

  // Verify with constructor args
  await run("verify:verify", {
    address: address,
    constructorArguments: [initialOwner, initialSupply],
  });
}
```

### Using Hardhat Ignition (Recommended)

```typescript
// ignition/modules/MyContract.ts
import { buildModule } from "@nomicfoundation/hardhat-ignition/modules";

export default buildModule("MyContractModule", (m) => {
  const initialOwner = m.getParameter("initialOwner");
  const initialSupply = m.getParameter("initialSupply", 1000000n);

  const token = m.contract("Token", [initialOwner, initialSupply]);

  return { token };
});
```

**Deploy with Ignition:**
```bash
npx hardhat ignition deploy ignition/modules/MyContract.ts --network sepolia
```

### Multi-Contract Deployment

```typescript
async function main() {
  const [deployer] = await ethers.getSigners();

  // Deploy Token
  const Token = await ethers.getContractFactory("Token");
  const token = await Token.deploy();
  await token.waitForDeployment();
  console.log("Token:", await token.getAddress());

  // Deploy Oracle
  const Oracle = await ethers.getContractFactory("Oracle");
  const oracle = await Oracle.deploy();
  await oracle.waitForDeployment();
  console.log("Oracle:", await oracle.getAddress());

  // Deploy Vault with dependencies
  const Vault = await ethers.getContractFactory("Vault");
  const vault = await Vault.deploy(
    await token.getAddress(),
    await oracle.getAddress()
  );
  await vault.waitForDeployment();
  console.log("Vault:", await vault.getAddress());

  // Configure relationships
  await token.setVault(await vault.getAddress());
  await oracle.addAuthorized(await vault.getAddress());

  // Save deployment addresses
  const fs = require("fs");
  const deployment = {
    token: await token.getAddress(),
    oracle: await oracle.getAddress(),
    vault: await vault.getAddress(),
    deployer: deployer.address,
    network: (await ethers.provider.getNetwork()).name,
    timestamp: new Date().toISOString(),
  };

  fs.writeFileSync(
    "deployment.json",
    JSON.stringify(deployment, null, 2)
  );
}
```

## Upgradeable Contract Deployment

### UUPS Deployment (Foundry)

```solidity
import {ERC1967Proxy} from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";

contract DeployUpgradeable is Script {
    function run() external {
        vm.startBroadcast();

        // Deploy implementation
        MyContract implementation = new MyContract();
        console.log("Implementation:", address(implementation));

        // Encode initialize call
        bytes memory initData = abi.encodeWithSelector(
            MyContract.initialize.selector,
            msg.sender
        );

        // Deploy proxy
        ERC1967Proxy proxy = new ERC1967Proxy(
            address(implementation),
            initData
        );
        console.log("Proxy:", address(proxy));

        vm.stopBroadcast();
    }
}
```

### UUPS Deployment (Hardhat)

```typescript
import { ethers, upgrades } from "hardhat";

async function main() {
  const MyContract = await ethers.getContractFactory("MyContract");

  // Deploy upgradeable contract
  const myContract = await upgrades.deployProxy(
    MyContract,
    [initialOwner],  // initializer args
    { initializer: "initialize", kind: "uups" }
  );

  await myContract.waitForDeployment();

  console.log("Proxy deployed to:", await myContract.getAddress());
  console.log("Implementation:", await upgrades.erc1967.getImplementationAddress(
    await myContract.getAddress()
  ));
}
```

## Multi-Chain Deployment

### Foundry Multi-Chain

```bash
# Deploy to multiple networks
networks=("sepolia" "goerli" "mumbai")

for network in "${networks[@]}"; do
  echo "Deploying to $network..."
  forge script script/Deploy.s.sol \
    --rpc-url $(eval echo \$${network^^}_RPC_URL) \
    --broadcast \
    --verify
done
```

### Hardhat Multi-Chain

```typescript
// hardhat.config.ts
export default {
  networks: {
    sepolia: {
      url: process.env.SEPOLIA_RPC_URL,
      accounts: [process.env.PRIVATE_KEY!],
    },
    polygon: {
      url: process.env.POLYGON_RPC_URL,
      accounts: [process.env.PRIVATE_KEY!],
    },
    arbitrum: {
      url: process.env.ARBITRUM_RPC_URL,
      accounts: [process.env.PRIVATE_KEY!],
    },
  },
};
```

**Deploy to each:**
```bash
npx hardhat run scripts/deploy.ts --network sepolia
npx hardhat run scripts/deploy.ts --network polygon
npx hardhat run scripts/deploy.ts --network arbitrum
```

## Contract Verification

### Foundry Verification

```bash
# Verify contract
forge verify-contract \
  --chain-id 11155111 \
  --num-of-optimizations 200 \
  --watch \
  --compiler-version v0.8.30 \
  --verification-method standard-json-input \
  --etherscan-api-key $ETHERSCAN_API_KEY \
  0x1234... \
  src/MyContract.sol:MyContract

# Verify with constructor args
forge verify-contract \
  --chain-id 1 \
  --constructor-args $(cast abi-encode "constructor(address,uint256)" 0x... 1000) \
  --verification-method standard-json-input \
  0x1234... \
  src/MyContract.sol:MyContract
```

### Hardhat Verification

```bash
# Verify contract
npx hardhat verify --network sepolia 0x1234...

# Verify with constructor args
npx hardhat verify --network sepolia 0x1234... "arg1" 123

# Verify upgradeable (verify implementation)
npx hardhat verify --network sepolia IMPLEMENTATION_ADDRESS
```

## Gas Price Strategies

### Foundry Gas Options

```bash
# Set gas price
forge script Deploy.s.sol --gas-price 50gwei

# Set priority fee
forge script Deploy.s.sol --priority-gas-price 2gwei

# Legacy gas pricing
forge script Deploy.s.sol --legacy
```

### Hardhat Gas Configuration

```typescript
// hardhat.config.ts
export default {
  networks: {
    mainnet: {
      url: process.env.MAINNET_RPC_URL,
      gasPrice: 50000000000,  // 50 gwei
    },
  },
};

// Or in script
const tx = await myContract.deploy({
  gasPrice: ethers.parseUnits("50", "gwei"),
});
```

## Deployment Best Practices

1. **Test First**
   - Deploy to local network
   - Deploy to testnet
   - Verify all functionality
   - Only then deploy to mainnet

2. **Security**
   - Use hardware wallet for mainnet
   - Never commit private keys
   - Use encrypted keystores or env variables
   - Verify contract addresses

3. **Documentation**
   - Document deployment addresses
   - Document configuration parameters
   - Create deployment guide
   - Maintain changelog

4. **Verification**
   - Always verify contracts on block explorer
   - Verify all related contracts
   - Check source code matches

5. **Gas Management**
   - Monitor gas prices
   - Use appropriate gas limits
   - Consider gas price oracles
   - Budget for deployment costs

6. **Multi-Sig for Critical Functions**
   - Deploy with multi-sig owner
   - Use timelock for upgrades
   - Document key management

## Deployment Tracking

### Save Deployment Info

```typescript
// Save to JSON
const deployment = {
  network: network.name,
  contractAddress: await contract.getAddress(),
  deployer: deployer.address,
  blockNumber: contract.deploymentTransaction()?.blockNumber,
  transactionHash: contract.deploymentTransaction()?.hash,
  timestamp: new Date().toISOString(),
  constructorArgs: [owner, initialSupply],
};

fs.writeFileSync(
  `deployments/${network.name}.json`,
  JSON.stringify(deployment, null, 2)
);
```

### Environment-Specific Deployment

```typescript
const config = {
  development: {
    initialSupply: ethers.parseEther("1000000"),
    fee: 100,  // 1%
  },
  production: {
    initialSupply: ethers.parseEther("100000000"),
    fee: 30,   // 0.3%
  },
};

const env = process.env.NODE_ENV || "development";
const params = config[env];
```

## Quick Reference

### Foundry Commands

```bash
# Deploy
forge script Deploy.s.sol --rpc-url $RPC_URL --broadcast

# Deploy with verification
forge script Deploy.s.sol --rpc-url $RPC_URL --broadcast --verify

# Deploy with hardware wallet
forge script Deploy.s.sol --rpc-url $RPC_URL --ledger --broadcast

# Verify existing contract
forge verify-contract ADDRESS Contract --chain-id 1
```

### Hardhat Commands

```bash
# Deploy
npx hardhat run scripts/deploy.ts --network sepolia

# Verify
npx hardhat verify --network sepolia ADDRESS "arg1" 123

# Deploy upgradeable
npx hardhat run scripts/deployUpgradeable.ts --network sepolia
```

---

**Remember:** Always test deployments on testnets first. Use hardware wallets or secure key management for mainnet deployments. Verify all contracts on block explorers.
