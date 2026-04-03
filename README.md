---
module: molcajete-ai
purpose: Spec-driven development framework for Claude Code — EARS requirements, BDD scenarios, and automated build dispatch
last-updated: 2026-04-03
---

# Molcajete.ai

AI coding agents are only as good as what you put in front of them.
Without a structured specification, you're not engineering — you're gambling. The same prompt generates two different architectures on two different days. You end up with code you can't test, can't explain, and don't fully own.
The problem isn't the agent. It's the gap between your intent and the code.
Molcajete.ai closes that gap.

It puts a layer of structured specifications between what you want and what gets built — EARS requirements, use cases with explicit side effects, Gherkin scenarios, and architecture documents that agents can actually follow. Not as suggestions. As constraints.

The specs become the source of truth. The code is derived from them — deterministically, traceably, repeatably.
You don't just get working software. You get software you understand, can test, and can hand to anyone on your team.

## What is Molcajete.ai?

Molcajete.ai is a spec-driven development framework built on [Claude Code](https://www.anthropic.com/claude/code). It provides a pipeline that transforms freeform feature descriptions into structured specs, then uses those specs to drive implementation through coordinated agent workflows.

The framework ships two components:

- **`m` plugin** — A Claude Code plugin with 17 slash commands and 12 skills organized into four modules: spec, plan, build, and research.
- **`@MolcajeteAI/cli`** — A Node.js CLI ([source](https://github.com/MolcajeteAI/molcajete)) that orchestrates spec development in unattended mode, running the full spec-to-build pipeline without manual interaction.

### The Pipeline

```
Feature idea → EARS Requirements → Use Cases → Scenarios → Gherkin → Build
```

1. **Spec** — Define features with EARS-syntax requirements, measurable fit criteria, and explicit non-goals. Break them into use cases with flat scenario blocks, side effects, and non-side-effects.
2. **Plan** — Generate implementation plans from specs. Wire BDD scenarios to code via architecture documents that map spec IDs to source files.
3. **Build** — Execute plans task-by-task with agents that read the specs and architecture, write code, and validate against Gherkin scenarios.
4. **Research** — Deep research with tech stack context, parallel agents, and structured output at three depth tiers.

### Why Specs?

- **Deterministic agent behavior** — Agents follow structured requirements, not ambiguous prose. Same spec, same output.
- **Traceable coverage** — Every requirement has a fit criterion, every use case maps to Gherkin scenarios, every scenario maps to code via the architecture document.
- **Reversible** — Extract specs from existing codebases with reverse commands, then use the same pipeline to extend them.
- **Unattended execution** — The `@MolcajeteAI/cli` runs the pipeline end-to-end without human-in-the-loop, using specs as the contract.

## Installation

### Prerequisites

- [Claude Code](https://docs.claude.com/claude-code) installed
- Node.js >= 20 (for the CLI)

### Plugin Install

```bash
/plugin marketplace add MolcajeteAI/plugin
```

### CLI Install

```bash
npx @MolcajeteAI/cli
```

### Alternative: settings.json

For persistent plugin configuration across sessions, add to `.claude/settings.json`:

```json
{
  "extraKnownMarketplaces": {
    "molcajete": {
      "source": {
        "source": "github",
        "repo": "MolcajeteAI/plugin"
      }
    }
  }
}
```

### Verify

```bash
/plugin marketplace list
```

You should see `molcajete` in the list with the `m` plugin enabled:

```json
{
  "enabledPlugins": {
    "m@Molcajete.ai": true
  }
}
```

---

## The `m` Plugin

The `m` plugin is organized into four modules, each owning a stage of the development pipeline.

### Spec Module

Create and maintain structured specifications from freeform descriptions or existing code.

| Command | Description |
|---------|-------------|
| `/m:feature` | Create a new feature with EARS requirements via creation interview |
| `/m:usecase` | Create a new use case with flat scenario structure |
| `/m:scenario` | Generate Gherkin feature files from a use case |
| `/m:spec` | Create or update features, use cases, and scenarios from natural language |
| `/m:update-feature` | Update an existing feature's requirements |
| `/m:update-usecase` | Update a use case and propagate changes to Gherkin |
| `/m:update-scenario` | Update a scenario and propagate changes to Gherkin |
| `/m:reverse-spec` | Reverse-engineer specs from existing code (broadest scope) |
| `/m:reverse-feature` | Reverse-engineer a feature from existing code |
| `/m:reverse-usecase` | Reverse-engineer a use case from existing code |
| `/m:reverse-scenario` | Reverse-engineer a scenario from a code path |

### Plan Module

| Command | Description |
|---------|-------------|
| `/m:plan` | Generate an implementation plan from specs |
| `/m:reverse-plan` | Generate a plan for wiring BDD to existing code |

### Build Module

| Command | Description |
|---------|-------------|
| `/m:build` | Execute a task from an implementation plan |
| `/m:setup` | Initialize project with foundational docs and tooling detection |

### Research and Shared

| Command | Description |
|---------|-------------|
| `/m:research` | Deep research with tech stack context and parallel agents |
| `/m:doc` | Generate or update directory documentation |

### Skills

Skills are reusable knowledge documents loaded by commands at runtime. Each skill encodes conventions, patterns, and standards for a specific domain.

| Module | Skill | What it encodes |
|--------|-------|----------------|
| spec | `feature-authoring` | EARS syntax, fit criteria, non-goals positioning, creation interview |
| spec | `usecase-authoring` | UC file structure, flat scenarios, side effects rules, Gherkin mapping |
| spec | `architecture` | ARCHITECTURE.md schema, C4 diagrams, code map, population rules |
| spec | `reverse-engineering` | Code-to-spec extraction patterns, scope discovery, dispatcher integration |
| plan | `planning` | Implementation plan generation and task sequencing |
| build | `setup` | Project initialization, domain structure, tooling detection |
| research | `research-methods` | 3-tier research routing (quick, explain, deep) with source evaluation |
| research | `headless-research` | Unattended research execution for CLI mode |
| shared | `code-documentation` | README structure and documentation conventions |
| shared | `gherkin` | BDD scenario generation and step definition patterns |
| shared | `git-committing` | Commit message standards and orchestration workflow |
| shared | `id-generation` | Base-62 timestamp ID generation (FEAT-, UC-, SC- prefixes) |

---

## Spec Structure

Molcajete.ai produces a structured `prd/` directory in your project:

```
prd/
├── DOMAINS.md                    # Domain registry
├── FEATURES.md                   # Feature index with status tracking
├── ACTORS.md                     # Actor definitions and roles
├── TECH-STACK.md                 # Technology inventory
└── domains/
    └── {domain}/
        └── features/
            └── FEAT-XXXX-{slug}/
                ├── REQUIREMENTS.md    # EARS requirements + fit criteria
                ├── USE-CASES.md       # Use case index
                ├── ARCHITECTURE.md    # Code map, C4 diagrams, data model
                └── use-cases/
                    └── UC-XXXX-{slug}.md  # Scenarios with side effects
```

### Key Conventions

- **EARS requirements** — Every functional requirement uses explicit keywords (When, While, If/Then) and includes a measurable fit criterion
- **Flat scenarios** — No main/alternative flow distinction. Every scenario (success, error, edge case) has the same shape: Given, Steps, Outcomes, Side Effects
- **Side effects are mandatory** — Every scenario declares what changes (events, DB writes) AND what does not change (non-side-effects become `And no ...` assertions in Gherkin)
- **Architecture as bridge** — ARCHITECTURE.md maps spec IDs to source files, giving agents precise context for implementation
- **Base-62 IDs** — All artifacts use timestamp-based IDs (e.g., `FEAT-0S9A`, `UC-0KTg`, `SC-001`) that are permanent and never reused

---

## Plugin Architecture

```
molcajete/
├── .claude-plugin/
│   └── plugin.json       # Plugin manifest (commands, skills, version)
├── spec/                  # Spec module — feature and UC authoring
│   ├── commands/
│   └── skills/
├── plan/                  # Plan module — implementation planning
│   ├── commands/
│   └── skills/
├── build/                 # Build module — task execution
│   ├── commands/
│   └── skills/
├── research/              # Research module — multi-tier research
│   ├── commands/
│   └── skills/
└── shared/                # Shared skills used across modules
    ├── commands/
    └── skills/
```

### Key Concepts

- **Commands** — User-facing slash commands (e.g., `/m:feature`). Markdown prompts with YAML frontmatter specifying model, tools, and behavior.
- **Skills** — Structured knowledge documents loaded by commands at runtime. Encode conventions, templates, and rules that commands follow.
- **Modules** — Logical groupings (spec, plan, build, research, shared) that own a stage of the pipeline.

---

## Contributing

1. Fork the repository
2. Create a feature branch
3. Add or edit commands and skills within the appropriate module
4. Submit a pull request

Guidelines:
- Commands are plain Markdown with YAML frontmatter
- Skills use YAML frontmatter with `name` and `description` fields
- Place new commands and skills in the module they belong to (spec, plan, build, research, or shared)

---

## Support

- **Issues**: [GitHub Issues](https://github.com/MolcajeteAI/plugin/issues)
- **Discussions**: [GitHub Discussions](https://github.com/MolcajeteAI/plugin/discussions)

---

## About

**Molcajete** (mol-ca-HEH-teh) is a traditional Mexican mortar and pestle made from volcanic rock, used for grinding and transforming raw ingredients into refined creations. Just as a molcajete transforms raw ingredients, Molcajete.ai transforms freeform feature descriptions into structured specifications that drive deterministic agent behavior.

## License

MIT
