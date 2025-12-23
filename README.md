# Molcajete.ai

**Consistent, opinionated workflows for Claude Code. No AI multiple-personality disorder.**

You know when you start using AI for your daily workflows, one day you get the right personality out of AI, other days you feel like it's the dumbest model in the world. What Molcajete.ai brings is the right setup for Claude Code—well-curated flows and consistent output. A curated marketplace of specialized plugins that grind through complexity and blend workflows into smooth, production-ready solutions. No multiple-personality disorder AI. Just opinionated commands, agents, and skills that get the job done, the way I like things to get done.

## What is Molcajete.ai?

Molcajete.ai is a plugin marketplace for [Claude Code](https://www.anthropic.com/claude/code) that provides specialized agents, commands, and workflows for modern software development. Each plugin is designed to handle specific aspects of the development lifecycle, from product planning to implementation, testing, and deployment.

## Plugins

### 🎯 Core Plugins

#### **prd** - Product Requirements & Spec Management
Spec-driven product management from vision to implementation.

**Commands:**
- `/prd:plan-product` - Establish strategic foundation (vision, roadmap, tech stack)
- `/prd:scope-feature` - Refine rough ideas into clear requirements
- `/prd:write-spec` - Create formal technical specifications
- `/prd:create-tasks` - Break specs into actionable tasks organized by features
- `/prd:break-task` - Decompose complex tasks into manageable sub-tasks
- `/prd:execute-tasks` - Orchestrate implementation with stack-specific agents

**Output Location:** `.molcajete/prd/`

**Agents:** product-strategist, feature-analyst, spec-writer, task-planner, orchestrator

---

#### **res** - Research & Information Gathering
Intelligent research workflows with automatic source tracking and smart formatting.

**Commands:**
- `/res:search` - Search documentation and web sources
- `/res:document` - Create comprehensive documentation from research

**Output Location:** `.molcajete/research/`

**Agents:** orchestrator, search-agent, fetch-agent, local-agent, synthesis-agent

**Features:**
- Multi-agent parallel research
- Automatic source prioritization (official docs first)
- Session-based coordination
- Simple vs. detailed response types

---

#### **git** - Git Workflow Automation
Standards-based git commit and workflow automation.

**Commands:**
- `/git:commit` - Create well-formatted commits following project standards
- `/git:amend` - Amend the last commit with staged changes

**Skills:** commit-standards

**Features:**
- Follows conventional commits format
- Analyzes git history to match project style
- Interactive commit message refinement
- Safety checks (authorship, push status)

---

#### **defaults** - Core Functionality
Essential hooks and audio feedback system.

**Skills:** play-sound

**Features:**
- Task completion sound notifications
- User prompt audio feedback
- Cross-platform support (macOS, Linux, Windows)
- Zero dependencies
- Silent failure (won't interrupt workflow)

---

### 🔧 Tech Stack Plugins

#### **go** - Go Development
Comprehensive Go development assistance from initialization through deployment.

**Commands:**
- `/go:init` - Initialize new Go project with Makefile
- `/go:build` - Build application
- `/go:test` - Run test suite with coverage
- `/go:bench` - Run benchmarks
- `/go:lint` - Run linters
- `/go:sec-scan` - Run security scanners
- `/go:deploy` - Deploy application
- And more...

**Agents:** developer, tester, debugger, optimizer, security, deployer, documenter

**Skills:** code-quality, testing-patterns, error-handling, concurrency-patterns, performance-profiling, and more

---

#### **sol** - Solidity Development
Smart contract development, testing, auditing, and deployment for Foundry and Hardhat.

**Commands:**
- `/sol:init` - Initialize new Solidity project
- `/sol:compile` - Compile contracts
- `/sol:test` - Execute test suite
- `/sol:test-fuzz` - Run fuzz tests
- `/sol:coverage` - Generate coverage report
- `/sol:audit` - Perform security audit
- `/sol:deploy` - Deploy contracts with verification
- And more...

**Agents:** developer, tester, debugger, auditor, gas-optimizer, deployer, upgrader

**Skills:** Framework detection, testing-patterns, security-audit, gas-optimization, proxy-patterns, and more

---

#### **js** - JavaScript/TypeScript Development
Base JavaScript/TypeScript development with strict TypeScript, Biome/ESLint, Vitest testing, and modern ESM patterns.

**Commands:**
- `/js:init` - Initialize new TypeScript project
- `/js:install` - Install dependencies
- `/js:dev` - Start development server
- `/js:build` - Build for production
- `/js:type-check` - Run TypeScript type checking
- `/js:lint` - Run ESLint/Biome linting
- `/js:format` - Format code with Prettier/Biome
- `/js:test` - Run test suite with Vitest
- `/js:test-coverage` - Generate coverage report
- `/js:audit` - Run security audit
- `/js:validate` - Run all checks (types, lint, tests)
- `/js:pre-commit` - Run pre-commit checks

**Agents:** developer, tester, security, quality-guardian, documenter

**Skills:** typescript-strict-config, esm-module-patterns, type-safety-patterns, vitest-configuration, testing-patterns, and more

---

#### **react** - React Development
React 19 and Next.js 15 development with Vite, TailwindCSS, component testing, and deployment patterns.

**Commands:**
- `/react:spa-init` - Initialize Vite + React SPA project
- `/react:nextjs-init` - Initialize Next.js 15 project
- `/react:preview` - Preview production build
- `/react:analyze` - Analyze bundle size
- `/react:test-component` - Run component tests
- `/react:test-e2e` - Run Playwright E2E tests
- `/react:test-visual` - Run visual regression tests
- `/react:build-spa` - Build Vite SPA
- `/react:build-nextjs` - Build Next.js application
- `/react:deploy-vercel` - Deploy to Vercel
- `/react:deploy-netlify` - Deploy to Netlify
- `/react:deploy-cloudflare` - Deploy to Cloudflare Pages

**Agents:** component-builder, state-architect, ui-designer, performance-optimizer, e2e-tester

**Skills:** react-19-patterns, hooks-best-practices, component-patterns, zustand-patterns, tanstack-query-setup, radix-ui-patterns, shadcn-ui-setup, tailwind-setup, playwright-setup, and more

---

#### **node** - Node.js Backend Development
Node.js backend development with Fastify, Prisma/Drizzle ORM, Docker containerization, and serverless deployment.

**Commands:**
- `/node:api-init` - Initialize Fastify API project
- `/node:db-generate` - Generate database client
- `/node:db-migrate` - Run database migrations
- `/node:db-seed` - Seed database with data
- `/node:api-validate` - Validate API schemas
- `/node:test-integration` - Run integration tests
- `/node:test-e2e` - Run E2E API tests
- `/node:test-containers` - Run tests with Testcontainers
- `/node:docker-build` - Build Docker image
- `/node:docker-run` - Run Docker container
- `/node:deploy` - Deploy to cloud platform

**Agents:** api-builder, database-architect, deployer

**Skills:** fastify-patterns, api-versioning, authentication-strategies, prisma-setup, drizzle-setup, migration-strategies, zod-validation, testcontainers-usage, docker-backend-patterns, serverless-patterns, and more

---

#### **react-native** - React Native Development
React Native with Expo SDK 52+, NativeWind, Gluestack-ui, and EAS Build/Update for mobile development.

**Commands:**
- `/react-native:expo-init` - Initialize Expo project
- `/react-native:preview` - Preview on device/simulator
- `/react-native:test-component` - Run component tests
- `/react-native:test-e2e` - Run Maestro E2E tests
- `/react-native:build-ios` - Build iOS app with EAS
- `/react-native:build-android` - Build Android app with EAS
- `/react-native:build-all` - Build for all platforms
- `/react-native:deploy-eas` - Deploy to EAS
- `/react-native:analyze` - Analyze bundle size
- `/react-native:update-ota` - Push OTA update

**Agents:** component-builder, ui-designer, navigation-architect, performance-optimizer, e2e-tester

**Skills:** nativewind-patterns, gluestack-ui-setup, expo-router-patterns, react-native-performance, flashlist-patterns, reanimated-patterns, maestro-testing, eas-build-setup, eas-update-setup, and more

---

## Installation

### Prerequisites

- [Claude Code CLI](https://docs.claude.com/claude-code) installed

### Quick Install (Recommended)

Add the marketplace directly from GitHub:

```bash
/plugin marketplace add IvanTorresEdge/molcajete.ai
```

That's it! The plugins are now available.

### Alternative: Configuration File Method

For persistent configuration across sessions, add to `.claude/settings.json`:

```json
{
  "extraKnownMarketplaces": {
    "molcajete": {
      "source": {
        "source": "github",
        "repo": "IvanTorresEdge/molcajete.ai"
      }
    }
  }
}
```

### Verify Installation

```bash
/plugin marketplace list
```

You should see `molcajete` in the list. Try any command to get started:
```bash
/prd:plan-product
```

### Enable/Disable Plugins

Edit `.claude-plugin/marketplace.json` in the molcajete directory:

```json
{
  "enabledPlugins": {
    "defaults@molcajete": true,
    "git@molcajete": true,
    "go@molcajete": true,
    "js@molcajete": true,
    "node@molcajete": true,
    "prd@molcajete": true,
    "react@molcajete": true,
    "react-native@molcajete": true,
    "res@molcajete": true,
    "sol@molcajete": true
  }
}
```

Set to `false` to disable any plugin.

---

## Output Directory Structure

All plugin outputs are stored in `.molcajete/` within your project:

```
.molcajete/
├── prd/                    # Product management outputs
│   ├── PRD.md              # Master product index
│   ├── mission.md          # Product vision
│   ├── roadmap.md          # Feature roadmap
│   ├── tech-stack.md       # Technology decisions
│   └── specs/              # Feature specifications
│       └── {timestamp}-{feature-name}/
│           ├── requirements.md
│           ├── spec.md
│           └── tasks.md
│
├── research/               # Research outputs
│   └── *.md                # Saved research documents
│
└── tmp/                    # Temporary files (gitignored)
    └── claude-code-researcher-*/  # Research sessions
```

### Version Control

Add to your project's `.gitignore`:

```gitignore
# Exclude all Molcajete outputs
.molcajete/

# Or selectively keep specs and research
.molcajete/tmp/
```

---

## Quick Start

### 1. Plan Your Product
```bash
# Establish strategic foundation
/prd:plan-product
```

### 2. Create a Feature Spec
```bash
# Write specification for a feature
/prd:write-spec user-authentication
```

### 3. Break Into Tasks
```bash
# Create implementation task list
/prd:create-tasks user-authentication
```

### 4. Research Best Practices
```bash
# Research authentication patterns
/res:search "JWT authentication best practices"
```

### 5. Implement
```bash
# Execute tasks with orchestration
/prd:execute-tasks user-authentication
```

### 6. Commit Your Work
```bash
# Create well-formatted commit
git add .
/git:commit
```

---

## Example Workflows

### Product Development Workflow
```bash
/prd:plan-product              # One-time setup
/prd:scope-feature             # Optional: Complex features
/prd:write-spec feature-name   # Create specification
/prd:create-tasks feature-name # Break into tasks
/prd:execute-tasks feature-name # Implement
```

### Go Application Development
```bash
/go:init my-service            # Initialize project
/go:build                      # Build application
/go:test                       # Run tests
/go:lint                       # Check code quality
/go:sec-scan                   # Security scan
/git:commit                    # Commit changes
```

### Solidity Smart Contract Development
```bash
/sol:init my-contract          # Initialize project
/sol:compile                   # Compile contracts
/sol:test                      # Run tests
/sol:test-fuzz                 # Fuzz testing
/sol:audit                     # Security audit
/sol:coverage                  # Coverage report
/sol:deploy                    # Deploy to network
```

### JavaScript/TypeScript Development
```bash
/js:init my-project            # Initialize TypeScript project
/js:install                    # Install dependencies
/js:dev                        # Start development
/js:test                       # Run tests
/js:lint                       # Check code quality
/js:validate                   # Run all checks
/git:commit                    # Commit changes
```

### React Application Development
```bash
/react:spa-init my-app         # Initialize Vite + React SPA
/js:dev                        # Start development server
/react:test-component          # Run component tests
/react:test-e2e                # Run E2E tests
/react:analyze                 # Analyze bundle
/react:build-spa               # Build for production
/react:deploy-vercel           # Deploy to Vercel
```

### Next.js Application Development
```bash
/react:nextjs-init my-app      # Initialize Next.js project
/js:dev                        # Start development server
/react:test-component          # Run component tests
/react:test-e2e                # Run E2E tests
/react:build-nextjs            # Build for production
/react:deploy-vercel           # Deploy to Vercel
```

### Node.js API Development
```bash
/node:api-init my-api          # Initialize Fastify API
/node:db-generate              # Generate database client
/node:db-migrate               # Run migrations
/js:dev                        # Start development server
/node:test-integration         # Run integration tests
/node:docker-build             # Build Docker image
/node:deploy                   # Deploy to cloud
```

### React Native Mobile Development
```bash
/react-native:expo-init my-app # Initialize Expo project
/react-native:preview          # Preview on device
/react-native:test-component   # Run component tests
/react-native:test-e2e         # Run Maestro E2E tests
/react-native:build-ios        # Build iOS app
/react-native:build-android    # Build Android app
/react-native:deploy-eas       # Deploy to EAS
/react-native:update-ota       # Push OTA update
```

---

## Plugin Architecture

Each plugin follows a consistent structure:

```
plugin-name/
├── .claude-plugin/
│   └── plugin.json           # Plugin manifest
├── commands/                 # Slash commands
│   └── *.md
├── agents/                   # Specialized agents
│   └── *.md
├── skills/                   # Reusable knowledge
│   └── */
│       └── SKILL.md
└── README.md                # Plugin documentation
```

### Key Concepts

- **Commands**: User-facing slash commands (e.g., `/prd:plan-product`)
- **Agents**: Specialized subagents that execute complex workflows
- **Skills**: Reusable knowledge and templates that agents reference
- **Namespace**: Plugin identifier prefix (e.g., `prd:`, `res:`, `go:`)

---

## Contributing

We welcome contributions! To add a new plugin or improve existing ones:

1. Fork the repository
2. Create a feature branch
3. Follow the plugin architecture guidelines
4. Add comprehensive documentation
5. Submit a pull request

### Plugin Development Guidelines

- Use clear, descriptive command names
- Delegate complex work to specialized agents
- Reference skills for standards and templates
- Include comprehensive README documentation
- Test all commands thoroughly

---

## Support

- **Documentation**: README.md (this file)
- **Issues**: [GitHub Issues](https://github.com/IvanTorresEdge/molcajete.ai/issues)
- **Discussions**: [GitHub Discussions](https://github.com/IvanTorresEdge/molcajete.ai/discussions)

---

## About Molcajete.ai

**Molcajete** (mol-ca-HEH-teh) is a traditional Mexican mortar and pestle made from volcanic rock, used for grinding and transforming ingredients. Just as a molcajete transforms raw ingredients into refined creations, Molcajete.ai transforms raw development tasks through coordinated agent processing.

This repository contains the plugin marketplace component - a curated collection of specialized Claude Code plugins for modern software development.

## License

MIT
