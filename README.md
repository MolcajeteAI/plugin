---
module: molcajete-ai
purpose: Spec-driven development framework for Claude Code — EARS requirements, use cases with explicit side effects, prose plans, and automated build dispatch
last-updated: 2026-09-10
---

# Molcajete.ai

AI coding agents are only as good as what you put in front of them.
Without a structured specification, you're not engineering — you're gambling. The same prompt generates two different architectures on two different days. You end up with code you can't test, can't explain, and don't fully own.
The problem isn't the agent. It's the gap between your intent and the code.
Molcajete.ai closes that gap.

It puts a layer of structured specifications between what you want and what gets built — EARS requirements, use cases with explicit side effects, and architecture documents that agents can actually follow. Not as suggestions. As constraints.

The specs become the source of truth. The code is derived from them — deterministically, traceably, repeatably.
You don't just get working software. You get software you understand, can test, and can hand to anyone on your team.

## What is Molcajete.ai?

Molcajete.ai is a spec-driven development framework built on [Claude Code](https://www.anthropic.com/claude/code). It provides a pipeline that transforms freeform feature descriptions into structured specs, then uses those specs to drive implementation through coordinated agent workflows.

The framework ships two components:

- **`m` plugin** — A Claude Code plugin with slash commands and skills organized into modules: spec, plan, build, review, setup, research, and shared.
- **`@MolcajeteAI/cli`** — A Node.js CLI ([source](https://github.com/MolcajeteAI/molcajete)) that orchestrates spec development in unattended mode, running the full spec-to-build pipeline without manual interaction.

### The Pipeline

```
Feature idea → EARS Requirements → Use Cases → Plan (vertical tasks) → Build
```

1. **Explore** — `/m:explore` sizes a change before anything is written: specs first, then code, then an open interview in prose, closed by an exploration document under `.molcajete/explorations/` that walks the change like a pull request body — the true prerequisites, then every change with its behavior, screen, flow, interfaces, data, and configuration, before and after. `/m:build`, `/m:spec`, `/m:change`, and `/m:fix` read it first.
2. **Spec** — Define features with EARS-syntax requirements, measurable fit criteria, and explicit non-goals. Break them into use cases with flat scenario blocks, side effects, and non-side-effects. `/m:spec` (new features) and `/m:cover` (reverse-extract from existing code) write spec prose and log pending work for a separate planning step.
3. **Plan** — A single prose plan file (`specs/plans/<timestamp>-<slug>.md`) decomposes the change into ordered, vertical, working-software tasks — each a `## [ ] T-NNN` checkbox delivering one behavior across all its layers. `/m:plan` writes it for the spec/cover flows; **`/m:fix` and `/m:change` produce their own plan in the same invocation** (diagnose or edit the spec, then plan) and hand straight to build. Every plan carries a Configuration changes block, so a setting is never added without naming the set it extends.
4. **Build** — `/m:execute` executes each task through a TDD red/green protocol, a mutation check, a coverage gate, and a correctness review that verifies the implementation actually satisfies the spec (not just that its own tests pass). The gate holds a new file to the threshold in full, and an existing file only on the lines the task wrote; a file that was already under the threshold is reported and offered as a GitHub issue, never used to block the task. `/m:build` runs the whole lifecycle end to end from one request: one interview, then an autonomous pass through plan, specs, code, tests, and scoped validation, closed by a before/after change report. Both follow one blocker protocol for an issue outside the plan: a small one is fixed in place and recorded, a significant one stops for one question, and neither ever creates a branch.
5. **Review** — A spec-traceable review surface, scoped to the change and nothing around it. `/m:review` writes a severity-scored review to a file. `/m:preflight` walks your own change set before you open a PR, decides each issue itself, and hands you parallel-ready `/m:build` prompts for what must move. Both offer a GitHub issue for anything they meet outside the change. `/m:walkthrough` gives a guided, hierarchical tour of a change set.
6. **Research** — Deep research with tech stack context, parallel agents, and long-form output.
7. **Query** — Read the spec tree back: `/m:desc` explains an ID, `/m:ids` finds the IDs behind a capability, and `/m:prompt` turns a freeform request into the command that delivers it.

### Why Specs?

- **Deterministic agent behavior** — Agents follow structured requirements, not ambiguous prose. Same spec, same output.
- **Traceable coverage** — Every requirement has a fit criterion, every use case has scenarios with explicit outcomes and side effects, every scenario maps to code via the architecture document.
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

The `m` plugin is organized into modules, each owning a stage of the development lifecycle: **spec**, **plan**, **build**, **review**, **setup**, **research**, and **shared**.

### Spec Module

Create and maintain structured specifications from freeform descriptions or existing code. Spec-phase commands write spec prose and log pending work; `/m:fix` and `/m:change` additionally produce their own plan.

| Command | Description |
|---------|-------------|
| `/m:spec` | Create or update features and use cases (with inline scenarios) from natural language |
| `/m:change` | Intentionally change an existing FEAT/UC — updates the specs, marks them dirty, and produces the change plan |
| `/m:fix` | Record a bug against an existing FEAT/UC and produce the regression plan (specs edited only when the spec was wrong) |
| `/m:cover` | Reverse-extract specs from existing code (tests come later via `/m:plan` + `/m:execute`) |

Three read-only commands query the spec tree instead of writing to it:

| Command | Description |
|---------|-------------|
| `/m:desc` | Print what one or more `FEAT`/`UC`/`SC`/`FR`/`NFR`/`US`/`ADR` IDs mean, with the code and test around each |
| `/m:ids` | Find the IDs that match a capability description, grouped by module, with spec file paths |
| `/m:prompt` | Turn a freeform request into a ready-to-paste `/m:spec`, `/m:change`, `/m:fix`, or `/m:cover` command with the IDs resolved |

### Plan Module

| Command | Description |
|---------|-------------|
| `/m:explore` | Size a change or a fix before it is specified — specs first, then code, then a prose interview; writes an exploration document under `.molcajete/explorations/`, never a spec |
| `/m:plan` | Decompose pending spec work into a single prose plan of vertical, working-software tasks under `specs/plans/` |

### Build Module

| Command | Description |
|---------|-------------|
| `/m:build` | Build a feature, a change, or a fix end to end from one request — one interview, then an autonomous run through plan, specs, code, tests, and scoped validation, closed by a before/after change report. Progress and decisions live in a `.molcajete/change-request/` file the run updates as it goes |
| `/m:execute` | Execute a plan — every unfinished task by default, or a named `T-NNN` subset (TDD red/green → mutation check → coverage gate → correctness review). Add `--commit` to commit each task as it passes |

### Review Module

Spec-traceable code review of a PR, branch, or ref range. Molcajete-only — every finding is anchored to a `FEAT/UC/SC` and its integration test.

| Command | Description |
|---------|-------------|
| `/m:review` | Guided, severity-scored review of what the change did, written to a `reviews/` file. Never edits code and never comments on the PR |
| `/m:preflight` | Hands-off pre-PR pass — walks your change set, decides each issue itself, documents the options and the rationale, and emits parallel-ready `/m:build` prompts. Never edits code |
| `/m:walkthrough` | Interactive, hierarchical tour (feature → UC → scenario) of a change set with clickable `file:line` links |

**The review judges the change, and only the change.** `/m:review` and `/m:preflight` answer four questions: is the change architecturally sound, does it follow the rules, do its added and modified lines meet the 80% coverage floor, and does it introduce a defect. Coverage is measured on what the change wrote, not on the whole file — unless the change created that file.

A finding earns a place in the issue list only when it sits on a line the change wrote, when one sentence names the changed hunk that broke something elsewhere, or when the change added behavior that no spec defines and no test asserts. Nothing else scores, and nothing else moves the verdict.

**Everything else becomes an observation.** Neither command searches for observations — they are what you meet while judging the change. They are listed apart from the issues, they carry no severity, and at the end you get one question: open a GitHub issue for them, so a later pull request fixes them under their own use case. A pre-existing bug in a file you edited is not your pull request's problem, and it no longer blocks it.

**Every issue Molcajete opens is findable and actionable.** It carries `AI-finding`, so you can filter for everything the tool raised, plus exactly one kind label — `bug`, `coverage`, `rule violation`, or `spec` — so you can take them one class at a time. It also carries the Molcajete prompt that fixes it, resolved down to the `UC-XXXX` and the `file:line`, so the issue is work someone can start and not a research task. `/m:execute` and `/m:build` open issues under the same rules for a file below the coverage threshold.

**`/m:preflight` hands you prompts. It never edits your code.** A fix usually moves more than one of the three elements — spec, code, test — and an edit made during a review skips the changelog entry, the status flip, and the test lifecycle that `/m:build` and `/m:execute` own. The spec then goes stale and the test breaks.

Preflight decides each issue itself. It reads the spec line, the code, and the test, explores the options, and picks the best long-term fix — correctness first, architecture second, effort last, with effort reported as a countable fact and never as a reason to rank a cheaper option higher. An issue that is small, low-risk, and unrelated to the PR's purpose is skipped on purpose, with the rationale recorded; the bar is that the PR must not introduce a defect, break a rule, or damage the architecture. Every fix becomes a ready-to-paste `/m:build` prompt — related small fixes batched into one prompt, each prompt kept small-to-medium — or a direct instruction for a small single-element cleanup. The run ends with a file at `.molcajete/prompts/<timestamp>-preflight-<slug>.md` that organizes the prompts into independent lanes, so you can launch one session per lane and run them in parallel.

### Setup, Research & Shared

| Command | Description |
|---------|-------------|
| `/m:setup` | Initialize the project foundation in one shot (PROJECT / MODULES / TECH-STACK / ACTORS / GLOSSARY / DOMAINS / FEATURES and host rules) |
| `/m:research` | Deep research with tech stack context, parallel agents, and long-form output |
| `/m:doc` | Generate or update directory documentation (README.md) |

### Skills

Skills are reusable knowledge documents loaded by commands at runtime. Each encodes conventions, patterns, and standards for a specific domain.

| Module | Skill | What it encodes |
|--------|-------|----------------|
| spec | `feature-authoring` | EARS syntax, fit criteria, non-goals positioning, creation interview |
| spec | `usecase-authoring` | UC file structure, flat inline scenarios, mandatory side effects |
| spec | `architecture` | ARCHITECTURE.md schema, spec-ID → code map, table-filling rules |
| spec | `reverse-engineering` | Code-to-spec extraction patterns and scope discovery |
| spec | `spec-revision` | Machinery shared by `/m:fix` and `/m:change` — module-instance fan-out, spec-edit rules, log/status, plan hand-off |
| spec | `spec-lookup` | Machinery shared by `/m:desc`, `/m:ids`, and `/m:prompt` — ID taxonomy, resolve by ID or keyword, context assembly |
| plan | `plan-authoring` | Prose plan format, vertical task shape, filing under specs/plans, Test File Convention, Producing-a-Plan procedure |
| build | `change-report` | The `/m:build` change report — the change-description walk at full depth plus the report tail: new IDs, interview decisions, Done / Not done / Next step |
| build | `plan-adaptation` | Mid-build plan change — trigger catalog, insert/revise operations, the three-option gate, and the audit trail |
| build | `blocker-protocol` | An issue outside the plan, mid-run — the size test, the fix-in-passing record, the two-option blocker question, never a branch |
| review | `change-review` | Change-set resolution + base detection, diff→FEAT/UC/SC mapping, the four review questions and the admission test, rubric and severity, observations and their GitHub issue offer |
| setup | `setup` | One-shot project initialization, module detection, host-rule generation |
| research | `research-methods` | Parallel research fan-out (web docs, community, libraries, local code) with source evaluation |
| research | `headless-research` | Silent, no-interaction research brief written before spec-writing |
| shared | `asking-questions` | Question presentation — markdown brief first, then a short AskUserQuestion carrying only the decision |
| shared | `change-description` | The universal change template — the walk: reason, spec deltas, UI sketches, surface items, flow pairs, verdict, at three depths (full / orientation / glance) |
| shared | `resolution-gate` | Analyze, then ask, then write — no unresolved item ever reaches a generated spec or plan |
| shared | `specs-first` | The read order every entry point runs — features, use cases, architecture, requirements, then code; the configuration inventory; the exit checklist |
| shared | `principles` | Engineering principles — integration-tests-as-contract, hexagonal, DI, coverage floor, craft |
| shared | `testing` | Test-first loop — Implementer / Validator / Reviewer roles, outer-edge mocking, coverage scoped to a new file in full and to an existing file's changed lines |
| shared | `status-rollup` | Status enum (pending / dirty / implemented), UC-as-leaf, Feature roll-up |
| shared | `uc-log` | Per-UC CHANGELOG.md mechanics — entry format and status transitions |
| shared | `code-documentation` | README structure and documentation conventions |
| shared | `git-committing` | Commit message standards for automated task execution — read by `/m:execute --commit` |
| shared | `git-conflict-resolution` | Merge/rebase conflict anatomy and resolution strategies |
| shared | `github-issues` | Issues Molcajete opens — the `AI-finding` label plus one kind label, label creation, the batched offer, and the fix prompt every issue carries |
| shared | `id-generation` | Base-62 timestamp ID generation (FEAT-, UC-, SC- prefixes) |
| shared | `writing-style` | How a sentence reads — Simplified Technical English, the accuracy rules that outrank length, and naming a concept before its ID |
| shared | `output-economy` | How much gets written — the content test, the four output containers, per-surface budgets |

---

## Spec Structure

Molcajete.ai produces a structured `specs/` directory in your project:

```
specs/
├── PROJECT.md                     # Mission, scope, constraints
├── MODULES.md                     # Module → directory / tests tree / driving-ports map
├── TECH-STACK.md                  # Technology inventory, test runner, coverage
├── ACTORS.md                      # Actor definitions and roles
├── GLOSSARY.md                    # Domain vocabulary
├── DOMAINS.md                     # Domain registry
├── FEATURES.md                    # Feature index with status
├── features/
│   └── {module}/
│       └── FEAT-XXXX-{slug}/
│           ├── REQUIREMENTS.md        # EARS requirements + fit criteria (carries feature status)
│           ├── USE-CASES.md           # Use case index
│           ├── ARCHITECTURE.md        # Spec-ID → code map, diagrams, data model
│           ├── UC-XXXX-{slug}.md      # Use case: inline scenarios + side effects (carries UC status)
│           └── UC-XXXX-{slug}/
│               └── CHANGELOG.md       # Per-UC change log (markers, not the status source)
└── plans/
    └── <YYYYMMDDTHHMMSS>-<slug>.md     # Prose plan (one file): vertical `## [ ] T-NNN` tasks
```

Commands that write outside the spec tree use a `.molcajete/` working directory:

```
.molcajete/
├── research/       # Context briefs written before spec-writing
├── explorations/   # Pre-planning sizing documents from /m:explore
├── prompts/        # Ready-to-paste commands from /m:prompt and /m:preflight
├── change-request/ # Per-run plan + decision log + progress + report from /m:build
└── escalations/    # Unresolved-item reports from headless runs
```

### Key Conventions

- **EARS requirements** — Every functional requirement uses explicit keywords (When, While, If/Then) and includes a measurable fit criterion.
- **Flat scenarios** — No main/alternative flow distinction. Every scenario (success, error, edge case) has the same shape: Given, Steps, Outcomes, Side Effects.
- **Side effects are mandatory** — Every scenario declares what changes (events, DB writes) AND what does not (non-side-effects become `And no ...` assertions).
- **Architecture as bridge** — ARCHITECTURE.md maps spec IDs to source files, giving agents precise context for implementation.
- **Vertical tasks** — Plans decompose work into vertical, working-software increments (one behavior across all its layers), never by layer.
- **First-class status** — FEAT and UC carry a `status` (pending | dirty | implemented); the UC is the leaf, and a feature rolls up from its UCs.
- **Base-62 IDs** — Entity IDs are timestamp-based and permanent (e.g., `FEAT-0S9A`, `UC-0KTg`), generated via the id-generation script — never reused.

---

## Plugin Architecture

```
molcajete/
├── .claude-plugin/
│   └── plugin.json       # Plugin manifest (commands, skills, version)
├── spec/                  # Spec module — spec/change/fix/cover + authoring/architecture/reverse-engineering skills
│   ├── commands/
│   └── skills/
├── plan/                  # Plan module — /m:explore + /m:plan + plan-authoring skill
│   ├── commands/
│   └── skills/
├── build/                 # Build module — /m:build (end-to-end run) + /m:execute (TDD + mutation + coverage + correctness review) + change-report, plan-adaptation, and blocker-protocol skills
│   ├── commands/
│   └── skills/
├── review/                # Review module — /m:review, /m:preflight, /m:walkthrough + change-review skill
│   ├── commands/
│   └── skills/
├── setup/                 # Setup module — /m:setup + setup skill
│   ├── commands/
│   └── skills/
├── research/              # Research module — /m:research + research skills
│   ├── commands/
│   └── skills/
└── shared/                # Shared command (/m:doc) + cross-module skills (asking-questions, specs-first, principles, testing, status-rollup, uc-log, git-*, id-generation, code-documentation, writing-style, output-economy)
    ├── commands/
    └── skills/
```

### Key Concepts

- **Commands** — User-facing slash commands (e.g., `/m:build`). Markdown prompts with YAML frontmatter specifying model, tools, and behavior.
- **Skills** — Structured knowledge documents loaded by commands at runtime. Encode conventions, templates, and rules that commands follow.
- **Modules** — Logical groupings (spec, plan, build, review, setup, research, shared) that own a stage of the lifecycle.

---

## Contributing

1. Fork the repository
2. Create a feature branch
3. Add or edit commands and skills within the appropriate module
4. Submit a pull request

Guidelines:
- Commands are plain Markdown with YAML frontmatter
- Skills use YAML frontmatter with `name` and `description` fields
- Place new commands and skills in the module they belong to (spec, plan, build, review, setup, research, or shared)

---

## Support

- **Issues**: [GitHub Issues](https://github.com/MolcajeteAI/plugin/issues)
- **Discussions**: [GitHub Discussions](https://github.com/MolcajeteAI/plugin/discussions)

---

## About

**Molcajete** (mol-ca-HEH-teh) is a traditional Mexican mortar and pestle made from volcanic rock, used for grinding and transforming raw ingredients into refined creations. Just as a molcajete transforms raw ingredients, Molcajete.ai transforms freeform feature descriptions into structured specifications that drive deterministic agent behavior.

## License

MIT
