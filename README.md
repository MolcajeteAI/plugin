---
module: molcajete-ai
purpose: Spec-authoring plugin for the Molcajete lifecycle — humans review contracts as change requests, the molcajete CLI applies and executes them
last-updated: 2026-08-23
---

# Molcajete.ai

AI coding agents are only as good as what you put in front of them.
Without a structured specification, you're not engineering — you're gambling. The same prompt generates two different architectures on two different days. You end up with code you can't test, can't explain, and don't fully own.
The problem isn't the agent. It's the gap between your intent and the code.
Molcajete.ai closes that gap.

It puts a layer of structured contracts between what you want and what gets built — EARS requirements, use cases with explicit side effects, module charters, interface maps, and data files that agents actually follow. Not as suggestions. As constraints.

The contracts become the source of truth. The code is derived from them — deterministically, traceably, repeatably.
You don't just get working software. You get software you understand, can test, and can hand to anyone on your team.

## What is Molcajete.ai?

Molcajete.ai is a spec-driven development framework built on [Claude Code](https://www.anthropic.com/claude/code). An architect needs five things to control a system: the features, the modules, the use cases and requirements under each feature, the public interface of every module, and the data layer. Everything else is implementation, and implementation is the machine's job.

The framework ships two components:

- **`m` plugin** — A Claude Code plugin that authors specs. Its commands compose **change requests** — the one artifact a human reviews — and never plan, build, or review code.
- **`molcajete` CLI** — A Node.js CLI ([source](https://github.com/MolcajeteAI/molcajete)) that is the only executor: it applies the change request on a run branch, plans its own work as machine-facing JSON, builds task by task with a verify hook and a mutation check, and closes each cycle with a read-only final verification.

### The Lifecycle

```
Change idea → request.md (human reviews this) → molcajete build → one merge delivers specs, tests, and code together
```

1. **Author** — `/m:spec` (new behavior), `/m:change` (different behavior for shipped code), and `/m:fix` (code disagrees with a correct spec) compose `request.md` under `specs/changes/{change-id}/`: spec diffs, interface diffs, data diagrams, flows, and module relationships. The base branch's specs stay untouched. `/m:cover` extracts specs from existing code — the one command that writes the spec tree directly.
2. **Review** — The human reads the request. Every change entry closes with **Additional Notes** (clarifications that flow into task rationale) and **Examples** (`E-NNN` exact values that become test fixtures and assertions). This is the whole review.
3. **Execute** — `molcajete build {change-id}` creates the run branch, applies the request, writes `plan.json`, and runs the main loop: task sessions fork one base session, a host-generated verify hook validates every step, a mutation check proves the assertions bite, and a read-only reviewer closes each cycle. Decisions the run makes alone land in `decisions.md`; the run ends with `report.md`.
4. **Merge** — One merge delivers specs, tests, and code together. Abandoning a change is deleting a branch.

### Why Contracts?

- **The contract is the review surface.** Every change to a feature, scenario, requirement, interface, or table is shown as a diff before the work starts, or recorded as a decision when discovered mid-run.
- **The machine plans its own work.** The plan is JSON, written and mutated by the CLI, never reviewed by a human.
- **Validation is mechanical first, judgmental second.** A hook runs the impacted tests and the metrics. A read-only reviewer checks the module rules. The human checks neither.
- **Deep modules.** A module owns one responsibility end to end; no module touches another module's tables; the closed `Depends on` set makes every undeclared relationship a finding.

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

You should see `molcajete` in the list with the `m` plugin enabled.

---

## The `m` Plugin

Twelve commands. Five author, one migrates, six are read-only helpers.

### Lifecycle Commands

| Command | Intent | Output |
|---------|--------|--------|
| `/m:setup` | Bootstrap a project | The foundation files, the module charters, and empty `specs/modules/{m}/INTERFACE.md` and `DATA.md` scaffolds |
| `/m:spec` | New behavior | `request.md` |
| `/m:change` | Different behavior for shipped code | `request.md`, with retired scenarios marked |
| `/m:fix` | Code disagrees with a correct spec | `request.md` |
| `/m:cover` | Extract specs from existing code | Writes the spec tree directly; its `request.md` lists the files to spec and test |
| `/m:migrate` | Move a v3 spec tree to v4 | Anchors, INTERFACE.md, DATA.md, and the charters — one invocation, existing IDs untouched |

No command emits a plan. Authoring thinks in contracts; only the executor thinks in tasks.

### Read-Only Helpers

| Command | Description |
|---------|-------------|
| `/m:walkthrough` | Interactive, hierarchical tour (feature → UC → scenario) of a change set with clickable `file:line` links |
| `/m:research` | Deep research with tech stack context, parallel agents, and long-form output |
| `/m:desc` | Print what one or more `FEAT`/`UC`/`SC`/`FR`/`NFR`/`US`/`ADR` IDs mean — including the public interface elements mapped to each |
| `/m:ids` | Find the IDs that match a capability description, grouped by module |
| `/m:prompt` | Turn a freeform request into the ready-to-paste command that delivers it |
| `/m:doc` | Generate or update directory documentation (README.md) |

### Skills

Skills are reusable knowledge documents loaded by commands — and by the CLI's sessions — at runtime.

| Module | Skill | What it encodes |
|--------|-------|----------------|
| spec | `feature-authoring` | EARS syntax, fit criteria, non-goals positioning, explicit anchors |
| spec | `usecase-authoring` | UC file structure, flat inline scenarios, mandatory side effects, anchors |
| spec | `architecture` | ARCHITECTURE.md schema, spec-ID → code map, table-filling rules |
| spec | `module-authoring` | The module charter, INTERFACE.md, DATA.md, per-property responsibilities, the two authoring questions |
| spec | `change-request` | The request.md format, notes and examples, and the apply rules |
| spec | `reverse-engineering` | Code-to-spec extraction patterns and scope discovery |
| spec | `spec-revision` | Machinery shared by `/m:fix` and `/m:change` — diagnosis, diff drafting, request composition |
| spec | `spec-lookup` | ID taxonomy, resolve by ID or keyword, context assembly with the INTERFACE.md map |
| plan | `plan-json` | The plan.json schema, decomposition rules, and the four plan operations — loaded only by the CLI |
| review | `change-review` | Change-set resolution + base detection, diff→FEAT/UC/SC mapping for the walkthrough |
| setup | `setup` | One-shot project initialization, module detection, host-rule generation, the drift catalog |
| research | `research-methods` | Parallel research fan-out with source evaluation |
| research | `headless-research` | Silent, no-interaction research brief written before spec-writing |
| shared | `asking-questions` | Question presentation — markdown brief first, then a short AskUserQuestion |
| shared | `resolution-gate` | Analyze, then ask, then write — no unresolved item reaches a generated document |
| shared | `principles` | Engineering principles — integration-tests-as-contract, hexagonal, DI, coverage floor, craft |
| shared | `testing` | One-actor loop, entry-point-only tests, the verify-hook contract, the mutation check, the Test File Convention |
| shared | `status-rollup` | Status enum (pending / implemented), UC-as-leaf, Feature roll-up |
| shared | `uc-log` | Per-UC CHANGELOG.md mechanics — entry format and status transitions |
| shared | `code-documentation` | README structure and documentation conventions |
| shared | `git-committing` | Commit message standards for automated task execution |
| shared | `git-conflict-resolution` | Merge/rebase conflict anatomy and resolution strategies |
| shared | `id-generation` | Timestamp ID generation, digits and uppercase letters only, permanent immutability |
| shared | `writing-style` | Simplified Technical English, the accuracy rules, and name-before-identifier with the identifier as a link |
| shared | `output-economy` | How much gets written — the content test, the four output containers, per-surface budgets |

---

## Spec Structure

Molcajete.ai produces a structured `specs/` directory in your project:

```
specs/
├── PROJECT.md                     # Mission, scope, constraints
├── MODULES.md                     # Module registry + charters (Depends on is a closed set)
├── TECH-STACK.md                  # Technology inventory, test runner, coverage
├── ACTORS.md                      # Actor definitions and roles
├── GLOSSARY.md                    # Domain vocabulary
├── DOMAINS.md                     # Domain registry
├── FEATURES.md                    # Feature index with status
├── modules/
│   └── {module}/
│       ├── INTERFACE.md           # The public surface, mapped to spec IDs
│       └── DATA.md                # The tables the module owns
├── features/
│   └── {module}/
│       └── FEAT-XXXX-{slug}/
│           ├── REQUIREMENTS.md        # EARS requirements + fit criteria (carries feature status)
│           ├── USE-CASES.md           # Use case index
│           ├── ARCHITECTURE.md        # Spec-ID → code map, diagrams, data model
│           ├── UC-XXXX-{slug}.md      # Use case: inline scenarios + side effects (carries UC status)
│           └── UC-XXXX-{slug}/
│               └── CHANGELOG.md       # Per-UC change log (markers, not the status source)
└── changes/
    └── {YYYYMMDDTHHMMSS}-{slug}/       # One directory per change
        ├── request.md                  # Written at authoring — what the human reviews
        ├── plan.json                   # Written by the CLI at execution start
        ├── decisions.md                # What the run decided alone
        ├── validation/                 # Reviewer findings, one file per cycle
        └── report.md                   # Written when the run ends
```

Commands that write outside the spec tree use a `.molcajete/` working directory:

```
.molcajete/
├── research/       # Context briefs written before spec-writing
├── prompts/        # Ready-to-paste commands from /m:prompt
└── escalations/    # Unresolved-item reports from headless runs
```

### Key Conventions

- **EARS requirements** — Every functional requirement uses explicit keywords (When, While, If/Then) and includes a measurable fit criterion.
- **Flat scenarios** — No main/alternative flow distinction. Every scenario (success, error, edge case) has the same shape: Given, Steps, Outcomes, Side Effects.
- **Side effects are mandatory** — Every scenario declares what changes (events, DB writes) AND what does not.
- **Every identifier is a link** — Generated documents write the name first, then the identifier as a Markdown link to its explicit `<a id>` anchor. A bare ID in a generated document is a defect.
- **Deep modules** — Business logic of one module never appears in another; no module touches another module's tables; a relationship not in `Depends on` is forbidden.
- **First-class status** — FEAT and UC carry a `status` (pending | implemented); the UC is the leaf, and a feature rolls up from its UCs.
- **Immutable IDs** — Entity IDs are timestamp-based and permanent, drawn from digits and uppercase letters (e.g., `FEAT-3FA1`, `UC-9KC2`), generated via the id-generation script — never reused, never renumbered.

---

## Plugin Architecture

```
molcajete/
├── .claude-plugin/
│   └── plugin.json       # Plugin manifest (commands, skills, version)
├── spec/                  # spec/change/fix/cover/migrate + the authoring skills
│   ├── commands/
│   └── skills/
├── plan/                  # plan-json skill (loaded only by the CLI)
│   └── skills/
├── review/                # /m:walkthrough + change-review skill
│   ├── commands/
│   └── skills/
├── setup/                 # /m:setup + setup skill
│   ├── commands/
│   └── skills/
├── research/              # /m:research + research skills
│   ├── commands/
│   └── skills/
└── shared/                # /m:doc + cross-module skills
    ├── commands/
    └── skills/
```

### Key Concepts

- **Commands** — User-facing slash commands (e.g., `/m:spec`). Markdown prompts with YAML frontmatter specifying model, tools, and behavior.
- **Skills** — Structured knowledge documents loaded by commands — and by the CLI's sessions via `--plugin-dir` — at runtime. One plugin, one source of truth, no vendored mirror.
- **Templates** — Every file Molcajete generates has its own template file under the owning skill's `templates/` directory. No inline templates, ever.
- **Modules** — Logical groupings (spec, plan, review, setup, research, shared) that own a stage of the lifecycle.

---

## Contributing

1. Fork the repository
2. Create a feature branch
3. Add or edit commands and skills within the appropriate module
4. Submit a pull request

Guidelines:
- Commands are plain Markdown with YAML frontmatter
- Skills use YAML frontmatter with `name` and `description` fields
- Place new commands and skills in the module they belong to (spec, plan, review, setup, research, or shared)

---

## Support

- **Issues**: [GitHub Issues](https://github.com/MolcajeteAI/plugin/issues)
- **Discussions**: [GitHub Discussions](https://github.com/MolcajeteAI/plugin/discussions)

---

## About

**Molcajete** (mol-ca-HEH-teh) is a traditional Mexican mortar and pestle made from volcanic rock, used for grinding and transforming raw ingredients into refined creations. Just as a molcajete transforms raw ingredients, Molcajete.ai transforms freeform feature descriptions into structured contracts that drive deterministic agent behavior.

## License

MIT
