# Molcajete.ai Roadmap

## Roadmap Philosophy

This roadmap is **personal-need-driven**. Features are prioritized based on the creator's immediate workflow requirements, not market demand or community requests. If others benefit, that's excellent—but not the primary driver.

We build what we need, when we need it, to the quality standard we demand.

---

## Now (Current Focus - Next 1-3 Months)

### 1. Expand Core Plugin Collection

**Description:** Add more high-value plugins covering common development workflows and languages.

**Why Now:** The current set (defaults, git, prd, res, go, sol) covers specific use cases but gaps remain in day-to-day development.

**Potential Additions:**
- **Python plugin** - Python development standards, testing, packaging
- **React/Frontend plugin** - Component patterns, state management, build optimization
  - **Atomic Design Pattern** [COMPLETE - 100%] - Default component organization hierarchy (Atoms, Molecules, Organisms, Templates, Pages) with Storybook integration for React and React Native tech-stacks. All 6 features complete: Vite SPA, Next.js, Expo, Component Builders, PRD Override, Documentation. Completed 2025-12-29. See `.molcajete/prd/specs/20251229-atomic_design_pattern/spec.md`
  - **Refactor Atomic Design Command** [COMPLETE - 100%] - Command to refactor existing projects to Atomic Design pattern. Analyzes flat component structures, generates migration plan with user approval, moves files, updates imports, creates barrel exports, and generates Storybook stories. Available as `/react:refactor-atomic-design` and `/react-native:refactor-atomic-design`. All 7 features complete including React Native implementation with mobile-specific classification and on-device Storybook support. Completed 2025-12-29. See `.molcajete/prd/specs/20251229-refactor_atomic_design_command/spec.md`
- **Testing plugin** - Test strategy, test generation, TDD workflows
- **Deployment plugin** - CI/CD patterns, containerization, infrastructure as code

**Success Criteria:** Each new plugin demonstrates the same consistency and quality as existing plugins.

---

### 2. Improve Existing Plugins

**Description:** Refine current plugins (defaults, git, prd, res, go, sol) based on real-world usage and discovered gaps.

**Why Now:** Already using these plugins daily; improvements directly impact personal productivity.

**Focus Areas:**
- **Setup command** - Interactive plugin configuration to streamline onboarding [IN DEVELOPMENT - 88% complete (Phase 4/5 done, documentation pending) - See .molcajete/prd/specs/20251114-molcajete_setup_command/tasks.md]
- **PRD plugin** - Enhance strategic interview process; add competitive analysis templates
- **Research plugin** - Better information synthesis; support for code exploration and analysis
- **Go plugin** - Expand testing patterns; add observability and deployment guidance
- **Solidity plugin** - Improve security analysis; add gas optimization patterns
- **Git plugin** - Smarter commit message generation; support for release workflows
- **Defaults plugin** - Core software principles and patterns all plugins should follow

**Success Criteria:** Existing plugins become more reliable and handle edge cases better.

---

## Next (3-6 Months)

### 1. Advanced Workflow Orchestration

**Description:** Enable plugins to compose and chain together for complex multi-step workflows.

**Why Next:** Once individual plugins are solid, natural next step is connecting them for end-to-end automation.

**Examples:**
- **New project workflow** - Chain prd → tech-stack → scaffolding → git-init
- **Feature development workflow** - Chain research → code generation → testing → git commit
- **Release workflow** - Chain testing → changelog → versioning → deployment

**Success Criteria:** Can execute multi-plugin workflows with single command.

---

### 2. Analytics and Telemetry (Personal)

**Description:** Track plugin usage patterns, identify bottlenecks, measure personal productivity impact.

**Why Next:** After building and using plugins for 3-6 months, need data to understand what's working.

**Focus:**
- **Local-only metrics** - No data leaves the machine; privacy-first
- **Usage patterns** - Which plugins get used most; which workflows are most valuable
- **Quality indicators** - Error rates, retry counts, workflow completion rates
- **Time savings** - Estimate productivity impact compared to manual processes

**Success Criteria:** Clear data on which plugins provide most value; informed decision-making on what to improve.

---

## Later (6+ Months, Aspirational)

### 1. Community Marketplace Launch

**Description:** Enable external developers to publish and discover plugins through a curated marketplace.

**Why Later:** Only pursue if personal use proves valuable and community interest emerges organically.

**Requirements:**
- Plugin quality standards and review process
- Discovery and search functionality
- Versioning and compatibility management
- Documentation standards and templates

**Decision Point:** Only build if there's genuine demand and maintaining quality is feasible.

---

### 2. AI-Assisted Plugin Creation

**Description:** Meta-workflow where AI helps users create custom plugins from natural language descriptions.

**Why Later:** Requires mature plugin ecosystem and deep understanding of what makes plugins effective.

**Vision:**
- Describe workflow in natural language
- AI generates agent definition, skills, and commands
- User tests and refines with AI assistance
- Publish to personal or community marketplace

**Decision Point:** Only build if plugin creation becomes a bottleneck; may never be needed.

---

### 3. Enterprise Features

**Description:** Team collaboration, private plugins, compliance features, audit logs.

**Why Later:** Not relevant for current use case; only pursue if enterprise adoption happens organically.

**Potential Features:**
- Team sharing and private plugin repositories
- Compliance reporting and audit trails
- SSO and access control
- Custom plugin hosting infrastructure

**Decision Point:** Only build if paying enterprise customers emerge; otherwise indefinitely postponed.

---

## Completed

### 1. Core Plugin System ✓

**Completed:** Initial release

**What:** Established plugin architecture with commands, agents, and skills. Created namespace system and `.molcajete/` output directory structure.

---

### 2. Foundational Plugin Set ✓

**Completed:** Initial release

**What:** Built six core plugins:
- **defaults** - Core development principles and patterns
- **git** - Commit message generation and git workflows
- **prd** - Product requirements and strategic planning
- **res** - Research workflows and information synthesis
- **go** - Go development standards and patterns
- **sol** - Solidity smart contract development

---

## Principles for Prioritization

1. **Personal need first** - If it doesn't solve a real problem in the creator's workflow, it doesn't get built
2. **Prove before scale** - Features must be proven in personal use before considering broader adoption
3. **Quality over speed** - No rushing; better to build slowly and well than quickly and poorly
4. **Community as bonus** - Community adoption is welcomed but never drives prioritization
5. **Stay focused** - Resist scope creep; stick to the Claude Code ecosystem
