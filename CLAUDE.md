# Project Instructions

## About This Project

Molcajete.ai is a Claude Code plugin that provides opinionated, reusable workflows for agentic software development. Named after the traditional Mexican mortar and pestle, it transforms raw development tasks through coordinated agent workflows into structured, high-quality output.

**Core idea:** Portable development lifecycle commands that work across any project, eliminating inconsistency from ad-hoc CLAUDE.md prompts.

### What It Ships

- **`m` plugin** (v3.21.0) — 15 slash commands and 24 reusable skills

### Key Directories

- `molcajete/` — Plugin root, one directory per module (`build/`, `plan/`, `research/`, `review/`, `setup/`, `shared/`, `spec/`), each holding its own `commands/` (Markdown with YAML frontmatter) and/or `skills/` (SKILL.md files)
- `molcajete/.claude-plugin/plugin.json` — Plugin manifest and canonical version
- `research/` — Lifecycle research documents
- `scripts/bump.sh` — Version bump script

### Tech Stack

Pure Markdown plugin system with zero runtime dependencies. Commands and skills are Markdown files with YAML frontmatter specifying model, allowed tools, and prompts. Models are pinned per command: `claude-fable-5` for `/m:plan`; `claude-opus-5` for `/m:spec`, `/m:change`, `/m:fix`, `/m:cover`, `/m:prompt`, `/m:review`, and `/m:preflight`; `claude-sonnet-5` for `/m:build`, `/m:setup`, `/m:walkthrough`, `/m:research`, `/m:doc`, `/m:desc`, and `/m:ids`.

### Conventions

- ID scheme: Base-62 tags (e.g., `UC-0KTg-001`, `FR-0Fy0-003`)
- Diagrams: Mermaid only (no ASCII art)
- Task estimation: Fibonacci story points (1, 2, 3, 5, 8); split if >8
- No emojis in documents
- Commands use sub-agents for context gathering and parallel research
- **Step numbering in commands and skills**: top-level steps are integers (`## Step 1`, `## Step 2`, …). Sub-steps under a single top-level step use one decimal level (`### 1.1`, `### 1.2`). Triple-decimals (`### 1.1.1`) and inserted-decimal steps (`### Step 4.5`, `### 7.6.5`) are forbidden. When a new step is inserted anywhere, **renumber every following step** instead of appending a decimal — cross-references inside the file are part of the renumber. Decimals are reserved exclusively for genuine hierarchical sub-steps, never as a shortcut to avoid renumbering.

## Choosing Between Solutions

Rank every candidate solution in this order. A lower rank never beats a higher one.

1. **What is right beats what is cheap.** The cheapest option is the least preferred option. It buys today with technical debt, and someone pays for it again later. Favor the correct solution, present it first, and explore it in full. When a cheap option is on the table, say plainly why it loses.
2. **Good principles and good architecture.** Between two correct options, take the one that respects the boundaries, the separation, and the patterns the project already holds. `molcajete/shared/skills/principles/SKILL.md` holds the operative set.
3. **Effort, and only as the last tiebreak.** Effort separates two options that already tie on correctness and on architecture. It never promotes a worse option above a better one.

**Never trust your own effort estimate.** A model estimates in human hours, because human hours are what its training data measured. An agent does the same work in a small fraction of that time, so the estimate runs far too high — and an inflated number argues for the cheap option and against the right one.

Two rules follow:

- **Never quote hours or days.** Count what an agent can count instead: files touched, tests to write, specs to edit, use cases affected. The Fibonacci story points above stay the unit for a plan task.
- **Never let an estimate rank the options.** Report the effort as a fact beside each option. The user weighs it. You do not weigh it for them.

## Clarifying Questions

When the user gives an instruction that is ambiguous, open-ended, or could be interpreted in multiple ways, always use the AskUserQuestion tool to clarify intent before proceeding. Only skip this when the request is straightforward and unambiguous.

**How to ask is governed by `molcajete/shared/skills/asking-questions/SKILL.md`.** Every substantive question is two moves — write a Markdown brief explaining the decision and its options, then call `AskUserQuestion` carrying only the short question and 2-4 short labels. Never put the explanation, or the thing being decided, inside the `question` or `preview` fields.
