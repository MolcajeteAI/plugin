# Molcajete.ai

**Consistent, opinionated workflows for Claude Code. No AI multiple-personality disorder.**

You know when you start using AI for your daily workflows, one day you get the right personality out of AI, other days you feel like it's the dumbest model in the world. What Molcajete.ai brings is the right setup for Claude Code -- well-curated flows and consistent output. Opinionated commands and skills that get the job done, the way I like things done.

Molcajete.ai is a [Claude Code](https://www.anthropic.com/claude/code) plugin marketplace. It ships two plugins:

- **`m`** (v2.7.0) -- The core plugin. 22 slash commands, 21 reusable skills, and 7 specialized agents covering the full development lifecycle.
- **`legacy`** -- A migration helper for moving files from the old v1 `.molcajete/` format into the current plugin format.

---

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

You should see `molcajete` in the list with the `m` plugin enabled:

```json
{
  "enabledPlugins": {
    "m@molcajete": true
  }
}
```

---

## Getting Started

### 1. Initialize your project

If you're starting fresh or onboarding an existing codebase, run:

```
/m:init
```

This creates your product documentation in a `prd/` directory: mission statement, tech stack analysis, roadmap, and changelog. These files give every subsequent command the context it needs about your project.

### 2. The development lifecycle

Molcajete follows a structured pipeline. Each step produces artifacts that feed into the next:

```
/m:feature  -->  /m:spec  -->  /m:tasks  -->  /m:stories  -->  /m:dev
```

| Step | Command | What it produces |
|------|---------|------------------|
| 1. Requirements | `/m:feature` | `requirements.md` -- use cases, user stories, acceptance criteria |
| 2. Specification | `/m:spec` | `spec.md` -- technical design, API contracts, data models |
| 3. Task breakdown | `/m:tasks` | `tasks.md` -- sequenced implementation tasks with story points |
| 4. BDD scenarios | `/m:stories` | `.feature` files with Gherkin scenarios and step definitions |
| 5. Implementation | `/m:dev` | Working code that passes BDD scenarios and unit tests |

You review and approve at each step before moving to the next. The pipeline is flexible -- you can start at any step if you already have the upstream artifacts.

### 3. Your first feature

```
/m:feature "user authentication with email and password"
```

Review the generated requirements, then:

```
/m:spec prd/specs/20260314-1200-user_authentication/
```

Review the spec, then:

```
/m:tasks prd/specs/20260314-1200-user_authentication/
```

Review the tasks, then start implementing:

```
/m:dev UC-0xxx-001/1.1
```

### 4. BDD-driven development (optional but recommended)

After `/m:tasks`, generate BDD scenarios before writing code:

```
/m:stories prd/specs/20260314-1200-user_authentication/
```

This reads your requirements, spec, and tasks to generate Gherkin `.feature` files with `@task-{ID}` tags. Review the scenarios, verify they all fail (red phase), then run `/m:dev` -- it will automatically load matching BDD scenarios as acceptance criteria.

For multi-task features, the coordinator can run tasks in parallel:

```
/m:run prd/specs/20260314-1200-user_authentication/
```

This generates `tasks.json` from your task plan and launches the Go Task coordinator, which dispatches subtasks to parallel Claude Code sessions in isolated git worktrees.

---

## Commands

### Planning and Design

| Command | Model | What it does |
|---------|-------|--------------|
| `/m:init` | opus | Initialize product docs: mission, tech stack, roadmap, changelog |
| `/m:feature` | opus | Scope a feature into structured requirements with use cases and acceptance criteria |
| `/m:refactor` | opus | Analyze impact of a code change, produce scoped requirements |
| `/m:spec` | opus | Create a technical specification from requirements |
| `/m:tasks` | opus | Break a specification into sequenced implementation tasks with story points |

### Implementation

| Command | Model | What it does |
|---------|-------|--------------|
| `/m:dev` | opus | Implement a task: loads BDD scenarios, writes code, runs tests, self-reviews |
| `/m:fix` | opus | Fix a bug or adjust implementation -- classifies root cause, updates specs if needed |
| `/m:test` | sonnet | Write, run, or analyze tests for code |
| `/m:debug` | opus | Guided debugging with hypothesis testing |

### BDD Workflow

| Command | Model | What it does |
|---------|-------|--------------|
| `/m:bdd-setup` | opus | Detect tech stack and configure BDD environment (framework, language, database) |
| `/m:stories` | opus | Generate Gherkin scenarios and step definitions tagged by task ID |
| `/m:run` | opus | Generate `tasks.json` and launch the parallel coordinator |

### Code Quality

| Command | Model | What it does |
|---------|-------|--------------|
| `/m:review` | opus | Code review on staged or recent changes |
| `/m:doc` | sonnet | Generate or update documentation for a file or directory |

### Git

| Command | Model | What it does |
|---------|-------|--------------|
| `/m:commit` | sonnet | Create a well-formatted commit from staged changes |
| `/m:amend` | sonnet | Amend the last commit with staged changes |
| `/m:rebase` | opus | Interactive rebase with conflict resolution |

### Research and Writing

| Command | Model | What it does |
|---------|-------|--------------|
| `/m:explain` | sonnet | Explain a topic in a clear, friendly 3-5 minute read |
| `/m:research` | sonnet | Deep research with tech stack context, parallel agents, long-form output |
| `/m:copy` | sonnet | Rewrite text or file content with clear structure |
| `/m:prompt` | sonnet | Write a well-structured LLM prompt from a rough description |

### Natural Language Triggers

Some commands activate automatically based on what you say -- no slash command needed:

| What you say | What runs | Output |
|---|---|---|
| "What is a CLOB?" | Quick answer | Inline response, no agents |
| "Explain how OAuth works" | Explain flow (2 agents) | 3-5 minute read, saved to file |
| "Research sharding for our Postgres" | Deep research (4 agents) | Full learning guide, saved to file |

`/m:explain` and `/m:research` are shortcuts that skip classification and go straight to their respective depth.

---

## Skills

Skills are reusable knowledge documents loaded by commands at runtime. Each skill encodes conventions, patterns, and standards for a specific domain. Commands load the skills they need automatically -- you don't invoke skills directly (though some are user-invocable for standalone use).

### Process Skills

| Skill | What it encodes |
|-------|----------------|
| `agent-coordination` | How commands invoke agents, handoff patterns, failure handling |
| `dev-workflow` | Task implementation workflow: single-task and multi-task modes |
| `project-management` | Requirements, spec, and roadmap formats, ID schemes, estimation |
| `gherkin` | BDD scaffold, Gherkin conventions, domain categorization, task tagging |
| `git-committing` | Conventional commit format, imperative verbs, no AI attribution |
| `software-principles` | SOLID, clean code, DRY, KISS, YAGNI, architectural principles |
| `code-documentation` | README structure, inline doc conventions, Mermaid diagrams |
| `research-methods` | 3-tier research (quick, explain, deep), source evaluation |
| `copywriting` | Text transformation, restructuring, clarity |
| `prompting` | LLM prompt structure, specificity, examples, output format |
| `clipboard` | Cross-platform clipboard operations |

### Stack-Specific Skills

These are discovered at runtime by agents based on your project's tech stack. If your project uses Go, the Developer agent automatically loads `go-writing-code`; the Tester loads `go-testing`.

| Skill | Stack |
|-------|-------|
| `typescript-writing-code` | TypeScript patterns, strict types, ESM, Biome |
| `typescript-testing` | Vitest, assertions, mocking, coverage |
| `go-writing-code` | Go idioms, error handling, concurrency, project layout |
| `go-testing` | Table-driven tests, benchmarks, race detection |
| `node-writing-code` | Fastify, Zod, Prisma/Drizzle, JWT/RBAC |
| `node-testing` | Fastify inject, Supertest, Testcontainers |
| `react-writing-code` | React 19, server/client components, Zustand, urql |
| `react-testing` | Testing Library, Playwright E2E, axe-core a11y |
| `react-components` | Atomic Design, shadcn/ui, Radix UI |
| `tailwind-css` | Tailwind v4, utility-first, cn(), dark mode |

---

## Agents

Commands delegate specialized work to agents. Each agent has a defined role, model assignment, primary skills, and output format. Agents are coordinated by the `agent-coordination` skill.

| Agent | Model | Role |
|-------|-------|------|
| Developer | sonnet | Implements code and tests from approved plans |
| Reviewer | opus | Reviews for correctness, security, performance, conventions |
| Spec Writer | opus | Writes requirements, specifications, and task breakdowns |
| BDD Analyst | opus | Translates requirements into Gherkin scenarios with domain categorization |
| Researcher | sonnet | Deep research, topic explanation, refactor impact analysis |
| Committer | sonnet | Stages files and creates commits with proper message format |
| BDD Setup | sonnet | Detects tech stack and configures BDD environment |

### Agent Chains

Commands orchestrate agents in chains where each agent's output feeds the next:

- **`/m:dev`**: Developer -> Reviewer -> Committer (with fix loops if review fails)
- **`/m:stories`**: BDD Analyst (standalone, with gherkin skill)
- **`/m:fix`**: Developer -> Reviewer (with fix loops, updates specs first if needed)
- **`/m:bdd-setup`**: BDD Setup (standalone, interactive tech stack detection)

Agents discover stack-specific skills at runtime. A Developer working on a Go project automatically loads `go-writing-code`; a Reviewer loads it for convention checking. Missing skills are not errors -- agents fall back to their primary skills.

---

## Coordinated Builds

For features with multiple tasks, `/m:run` orchestrates parallel execution:

```
/m:run prd/specs/your-feature/
```

### What happens

1. `/m:run` parses `tasks.md` and generates `tasks.json` (dependency graph)
2. The Go Task coordinator (`Taskfile.yml` + shell scripts) reads `tasks.json`
3. Tasks are grouped by dependency level via topological sort
4. Independent tasks run in parallel, each in its own git worktree
5. Each task is dispatched as a headless `claude -p "/m:dev {task-id}"` session
6. Completed worktrees are merged back; `tasks.json` and `tasks.md` are updated
7. Failed tasks are retried with exponential backoff

### Configuration

| Variable | Default | Purpose |
|----------|---------|---------|
| `MOLCAJETE_MAX_PARALLEL` | 1 | Maximum concurrent task sessions |
| `MOLCAJETE_TASK_TIMEOUT` | 900 | Timeout per task in seconds |

### Prerequisites

- [Go Task](https://taskfile.dev/) (`task` binary) -- `brew install go-task`
- `jq` -- `brew install jq`

### Failure handling

- **Rate limits**: exponential backoff (30s, 60s, 120s)
- **Merge conflicts**: LLM-assisted resolution, human fallback
- **Session timeout**: task killed and retried
- **Spend limits**: pipeline paused with actionable message
- **Crashes**: worktree branches preserved for manual recovery

You can check status anytime:

```bash
task -t molcajete/scripts/Taskfile.yml status
```

---

## Common Workflows

### Fix a bug

```
/m:fix UC-0xxx-001/1.2 "login fails when email has uppercase letters"
```

The fix command classifies the root cause (is it a spec issue or a code issue?), updates spec artifacts if needed, then patches the code and runs tests.

### Review your changes

```
/m:review
```

Reviews staged or recent changes for correctness, security, performance, and convention adherence.

### Quick commit

```
/m:commit
```

Creates a well-formatted commit message from your staged changes following the project's existing commit style.

### Research before building

```
/m:research "WebSocket vs SSE for real-time notifications"
```

Launches parallel research agents that produce a structured learning guide with your tech stack context.

### Set up BDD for a new project

```
/m:bdd-setup
```

Detects your language, BDD framework (behave/godog/cucumber-js), E2E framework, and database driver. Creates the `bdd/` scaffold with the right directory structure and configuration.

### Generate stories for a single use case

```
/m:stories UC-0xxx-001
```

### Generate stories for an entire feature

```
/m:stories prd/specs/your-feature/
```

---

## Plugin Architecture

```
molcajete/
├── .claude-plugin/
│   └── plugin.json        # Plugin manifest (name, version, commands, skills)
├── commands/               # Slash command prompts (Markdown + YAML frontmatter)
│   └── *.md
├── skills/                 # Reusable knowledge loaded by commands
│   └── <skill-name>/
│       ├── SKILL.md
│       ├── references/     # Detail docs referenced by the skill
│       └── templates/      # Templates used during generation
├── agents/                 # Agent role definitions (Markdown + YAML frontmatter)
│   └── *.md
└── scripts/                # Coordinator scripts for parallel execution
    ├── Taskfile.yml         # Go Task orchestration
    ├── dispatch.sh          # Task dispatcher with dependency resolution
    ├── merge.sh             # Worktree merge with LLM conflict resolution
    └── status.sh            # Build status reporter
```

### Key Concepts

- **Commands** -- User-facing slash commands (e.g., `/m:dev`). Markdown prompts with YAML frontmatter specifying model, allowed tools, and the prompt itself.
- **Skills** -- Structured knowledge documents loaded by commands at runtime. Encode conventions, patterns, and standards. Referenced via `${CLAUDE_PLUGIN_ROOT}/skills/`.
- **Agents** -- Specialized roles dispatched by commands via the Task tool. Each has defined responsibilities, boundaries, model assignment, and output format.
- **Coordinator** -- Shell scripts + Go Task that orchestrate parallel multi-task execution using git worktrees and headless Claude Code sessions.

---

## Repository Layout

```
molcajete.ai/
├── .claude-plugin/
│   └── marketplace.json    # Declares the two plugins in this repo
├── molcajete/              # Source for the m plugin
├── legacy/                 # Source for the legacy migration plugin
├── prd/                    # Product documentation (mission, roadmap, specs)
│   └── specs/              # Feature specs with requirements, tasks, and plans
├── deprecated/             # Archived v1 plugins (reference only, not installed)
├── .hooks/                 # Git hooks used in this repo
├── scripts/                # Utility scripts
└── LICENSE                 # MIT
```

---

## The `legacy` Plugin

For users migrating from the old v1 marketplace format:

| Command | Description |
|---------|-------------|
| `/legacy:migrate-prd` | Convert `.molcajete/prd/` files to the current spec and task format |
| `/legacy:migrate-research` | Convert `.molcajete/research/` files to the current research format |

---

## Contributing

1. Fork the repository
2. Create a feature branch
3. Add or edit commands in `molcajete/commands/` or skills in `molcajete/skills/`
4. Submit a pull request

Guidelines:
- Commands are plain Markdown -- write them as structured prompts for Claude
- Skills use YAML frontmatter with `name` and `description` fields
- Agent definitions follow the same structure: frontmatter + Responsibilities, Boundaries, Skills, Output Format
- Don't add a new top-level plugin -- add commands or skills to `m` instead

---

## Support

- **Issues**: [GitHub Issues](https://github.com/MolcajeteAI/plugin/issues)
- **Discussions**: [GitHub Discussions](https://github.com/MolcajeteAI/plugin/discussions)

---

## About

**Molcajete** (mol-ca-HEH-teh) is a traditional Mexican mortar and pestle made from volcanic rock, used for grinding and transforming raw ingredients into refined creations. Just as a molcajete transforms raw ingredients, Molcajete.ai transforms raw development tasks through coordinated agent workflows.

## License

MIT
