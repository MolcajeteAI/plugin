---
module: molcajete-ai
purpose: Claude Code plugin marketplace providing opinionated development workflow commands and reusable skills
last-updated: 2026-02-17
---

# Molcajete.ai

**Consistent, opinionated workflows for Claude Code. No AI multiple-personality disorder.**

You know when you start using AI for your daily workflows, one day you get the right personality out of AI, other days you feel like it's the dumbest model in the world. What Molcajete.ai brings is the right setup for Claude Code — well-curated flows and consistent output. A curated marketplace of plugins that grind through complexity and blend workflows into smooth, production-ready solutions. Just opinionated commands and skills that get the job done, the way I like things done.

## What is Molcajete.ai?

Molcajete.ai is a [Claude Code](https://www.anthropic.com/claude/code) plugin marketplace. It ships two plugins:

- **`m`** — The core plugin. Generic, stack-aware commands covering the full development lifecycle, backed by a library of 21 reusable skills.
- **`legacy`** — A migration helper for moving files from the old v1 `.molcajete/` format into the current `m` plugin format.

## Installation

### Prerequisites

- [Claude Code](https://docs.claude.com/claude-code) installed

### Quick Install

```bash
/plugin marketplace add MolcajeteAI/plugin
```

### Alternative: settings.json

For persistent configuration across sessions, add to `.claude/settings.json`:

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

You should see `molcajete` in the list. Both plugins are enabled by default:

```json
{
  "enabledPlugins": {
    "m@molcajete": true
  }
}
```

---

## The `m` Plugin

The `m` plugin is the core of Molcajete.ai. Every command is a structured prompt that reads relevant skills, follows established conventions, and delegates complex sub-tasks to specialized agents.

### Commands

| Command | Description |
|---------|-------------|
| `/m:init` | Initialize a new project with mission, tech stack, roadmap, and changelog |
| `/m:feature` | Scope a new feature into structured requirements |
| `/m:refactor` | Research a refactoring/replacement, produce impact analysis and requirements |
| `/m:spec` | Create a technical specification for a feature or refactor |
| `/m:tasks` | Break a specification into sequenced implementation tasks |
| `/m:stories` | Generate BDD scenarios and step definitions for a feature |
| `/m:dev` | Implement a task from the task plan |
| `/m:run` | Run a spec end-to-end: plan, build, test, validate (headless dispatch) |
| `/m:fix` | Diagnose and fix a bug or failed implementation |
| `/m:test` | Write, run, or analyze tests for code |
| `/m:review` | Code review on staged or recent changes |
| `/m:doc` | Generate or update documentation for a file or directory |
| `/m:explain` | Explain a topic in a clear, friendly 3-5 minute read |
| `/m:research` | Deep research with tech stack context, parallel agents, and long-form output |
| `/m:copy` | Rewrite text or file content with clear structure and good copy |
| `/m:prompt` | Write a well-structured LLM prompt from a rough description |
| `/m:debug` | Guided debugging workflow with hypothesis testing |
| `/m:commit` | Create a well-formatted commit from staged changes |
| `/m:amend` | Amend the last commit with staged changes |
| `/m:rebase` | Interactive rebase helper |

### Natural Language Triggers

Some skills activate automatically based on what you say — no slash command needed. The `research-methods` skill is the first to support this:

| What you say | What runs | Output |
|---|---|---|
| "What is a CLOB?" | Quick answer | Inline response, no agents |
| "Explain how OAuth works" | Explain flow (2 agents) | 3-5 minute Introduction, save prompt |
| "Research sharding for our Postgres" | Deep research (4 agents) | Full Learning Guide, save prompt |

The `/m:explain` and `/m:research` commands are shortcuts that skip classification and go straight to their respective depth.

### Skills

Skills are reusable knowledge documents loaded by commands at runtime. Each skill encodes conventions, patterns, and standards for a specific domain.

| Skill | What it encodes |
|-------|----------------|
| `software-principles` | SOLID, clean code, and architectural principles |
| `dev-workflow` | Development process and task execution conventions |
| `project-management` | Requirements, spec, and roadmap formats and templates |
| `code-documentation` | README structure, inline doc conventions, and templates |
| `git-committing` | Conventional commit format and git workflow standards |
| `typescript-writing-code` | Idiomatic TypeScript patterns and strict type safety |
| `go-writing-code` | Idiomatic Go patterns, project layout, and godoc conventions |
| `node-writing-code` | Node.js backend patterns with Fastify and ESM |
| `react-writing-code` | React component patterns, hooks, and state management |
| `copywriting` | Text transformation for restructuring and improving clarity of written content |
| `prompting` | Writing clear, effective LLM prompts with structure and specificity |
| `research-methods` | Research skill with 3 depth tiers (quick, explain, deep), beginner-friendly templates, and source evaluation. Triggers on natural language ("research X", "explain X", "help me understand X") or via `/m:explain` and `/m:research` commands |
| `react-components` | Component composition, Radix UI, and Tailwind conventions |
| `tailwind-css` | Tailwind utility class patterns and design system usage |
| `typescript-testing` | Vitest and testing conventions for TypeScript projects |
| `go-testing` | Go testing patterns, table-driven tests, and coverage |
| `react-testing` | React Testing Library and component testing patterns |
| `node-testing` | Integration and API testing patterns for Node.js |
| `gherkin` | BDD scenario generation, Gherkin conventions, and step definition patterns |
| `clipboard` | Copy-to-clipboard integration for commands |
| `agent-coordination` | Three-agent dispatch chain (Tester -> Developer -> Validator) for `/m:run` |

### Coordinated Builds

The `/m:run` command orchestrates headless builds using a three-agent model. The prerequisite chain is:

```
/m:spec -> /m:tasks -> /m:stories -> /m:run
```

Per UC, `dispatch.sh` creates a git worktree and runs:

1. **Tester** — writes BDD step definition assertions (red phase)
2. **Developer** (per subtask) — implements production code + unit tests, with LLM review after each commit
3. **Validator** — runs BDD tests; merges worktree to base branch only on green

All agents share one session per UC for full context continuity. The base branch never receives untested code.

---

## The `legacy` Plugin

For users migrating from the old v1 marketplace. If you have existing `.molcajete/prd/` or `.molcajete/research/` directories from the previous format, these commands migrate those files into the current `m` plugin conventions.

| Command | Description |
|---------|-------------|
| `/legacy:migrate-prd` | Convert `.molcajete/prd/` files to the current spec and task format |
| `/legacy:migrate-research` | Convert `.molcajete/research/` files to the current research format |

---

## Plugin Architecture

Each plugin follows this structure:

```
plugin-name/
├── .claude-plugin/
│   └── plugin.json       # Plugin manifest (name, version, commands, skills)
├── commands/             # Slash command prompts
│   └── *.md
└── skills/               # Reusable knowledge loaded by commands
    └── <skill-name>/
        ├── SKILL.md
        └── references/   # Templates and examples referenced by skills
```

### Key Concepts

- **Commands** — User-facing slash commands (e.g., `/m:commit`). Markdown prompts that Claude Code loads as system context.
- **Skills** — Structured knowledge documents with YAML frontmatter. Loaded by commands via `${CLAUDE_PLUGIN_ROOT}/skills/`. Can also be installed standalone via `npx skills`.
- **Namespace** — Plugin identifier prefix (e.g., `m:`, `legacy:`).

## Repository Layout

```
molcajete.ai/
├── .claude-plugin/
│   └── marketplace.json  # Declares the two plugins in this repo
├── molcajete/            # Source for the m plugin
├── legacy/               # Source for the legacy migration plugin
├── deprecated/           # Archived v1 plugins (reference only, not installed)
├── .hooks/               # Git hooks used in this repo (pre-commit)
├── scripts/              # Utility scripts (init.sh)
└── LICENSE               # MIT
```

---

## Contributing

1. Fork the repository
2. Create a feature branch
3. Add or edit commands in `molcajete/commands/` or skills in `molcajete/skills/`
4. Submit a pull request

Guidelines:
- Commands are plain markdown — write them as structured prompts for Claude
- Skills use YAML frontmatter with `name` and `description` fields
- Don't add a new top-level plugin — add commands or skills to `m` instead

---

## Support

- **Issues**: [GitHub Issues](https://github.com/MolcajeteAI/plugin/issues)
- **Discussions**: [GitHub Discussions](https://github.com/MolcajeteAI/plugin/discussions)

---

## About

**Molcajete** (mol-ca-HEH-teh) is a traditional Mexican mortar and pestle made from volcanic rock, used for grinding and transforming raw ingredients into refined creations. Just as a molcajete transforms raw ingredients, Molcajete.ai transforms raw development tasks through coordinated agent workflows.

## License

MIT
