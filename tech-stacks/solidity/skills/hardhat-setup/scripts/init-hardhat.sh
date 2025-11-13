#!/usr/bin/env bash
# Hardhat Project Initialization Script
# Automates the setup of a new Hardhat project with best practices

set -e  # Exit on error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Project configuration
PROJECT_NAME="${1:-.}"
USE_TYPESCRIPT="${2:-}"

echo -e "${GREEN}⚙️  Hardhat Project Initialization${NC}"
echo "=================================="

# Check if Node.js is installed
if ! command -v node &> /dev/null; then
    echo -e "${RED}❌ Node.js is not installed${NC}"
    echo "Install Node.js from: https://nodejs.org/"
    exit 1
fi

echo -e "${GREEN}✓ Node.js detected${NC}"
node --version
npm --version

# Create project directory if needed
if [ "$PROJECT_NAME" != "." ]; then
    mkdir -p "$PROJECT_NAME"
    cd "$PROJECT_NAME"
fi

# Initialize npm project
echo ""
echo "Initializing npm project..."
npm init -y
echo -e "${GREEN}✓ npm project initialized${NC}"

# Install Hardhat and essential plugins
echo ""
echo "Installing Hardhat and plugins..."
npm install --save-dev hardhat @nomicfoundation/hardhat-toolbox

if [ "$USE_TYPESCRIPT" == "--typescript" ]; then
    npm install --save-dev typescript ts-node @types/node
    echo -e "${GREEN}✓ Installed Hardhat with TypeScript support${NC}"
else
    echo -e "${GREEN}✓ Installed Hardhat${NC}"
fi

# Install additional dependencies
echo ""
echo "Installing additional dependencies..."
npm install --save-dev dotenv
npm install @openzeppelin/contracts
echo -e "${GREEN}✓ Installed dependencies${NC}"

# Create hardhat config
echo ""
echo "Creating Hardhat configuration..."
if [ "$USE_TYPESCRIPT" == "--typescript" ]; then
    npx hardhat init --yes --typescript
else
    npx hardhat init --yes
fi
echo -e "${GREEN}✓ Hardhat configuration created${NC}"

# Create .gitignore if it doesn't exist
if [ ! -f ".gitignore" ]; then
    cat > .gitignore << 'EOF'
# Hardhat
artifacts/
cache/
cache_hardhat/
coverage/
coverage.json
typechain-types/

# Dependencies
node_modules/

# Environment
.env
.env.local

# IDE
.idea/
.vscode/
*.swp
*.swo

# OS
.DS_Store
Thumbs.db

# Build artifacts
*.log
dist/
build/
EOF
    echo -e "${GREEN}✓ Created .gitignore${NC}"
fi

# Create .env.example
if [ ! -f ".env.example" ]; then
    cat > .env.example << 'EOF'
# RPC URLs
MAINNET_RPC_URL=
SEPOLIA_RPC_URL=

# Private Keys (NEVER commit!)
PRIVATE_KEY=0x

# Etherscan API Keys
ETHERSCAN_API_KEY=

# Gas Reporting
REPORT_GAS=false
COINMARKETCAP_API_KEY=
EOF
    echo -e "${GREEN}✓ Created .env.example${NC}"
fi

# Create .env from .env.example if it doesn't exist
if [ ! -f ".env" ]; then
    cp .env.example .env
    echo -e "${GREEN}✓ Created .env${NC}"
fi

# Compile to verify setup
echo ""
echo "Compiling contracts..."
npx hardhat compile

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✓ Compilation successful${NC}"
else
    echo -e "${RED}❌ Compilation failed${NC}"
    exit 1
fi

# Run tests to verify setup
echo ""
echo "Running tests..."
npx hardhat test

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✓ Tests passed${NC}"
else
    echo -e "${YELLOW}⚠ Tests failed or no tests found${NC}"
fi

# Summary
echo ""
echo "=================================="
echo -e "${GREEN}✅ Hardhat project setup complete!${NC}"
echo ""
echo "Next steps:"
echo "1. Update .env with your RPC URLs and API keys"
echo "2. Write your contracts in contracts/"
echo "3. Write tests in test/"
echo "4. Run 'npx hardhat test' to test your contracts"
echo "5. Run 'npx hardhat compile' to compile"
echo ""
echo "Useful commands:"
echo "  npx hardhat compile           - Compile contracts"
echo "  npx hardhat test              - Run tests"
echo "  npx hardhat test --grep <pattern> - Run specific tests"
echo "  npx hardhat coverage          - Generate coverage report"
echo "  REPORT_GAS=true npx hardhat test - Run with gas reporting"
echo "  npx hardhat node              - Start local node"
echo "  npx hardhat run scripts/deploy.js --network sepolia - Deploy"
echo ""
echo "Documentation: https://hardhat.org/docs"
