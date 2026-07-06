---
description: Read pending log entries on referenced UCs, design architecture (or accept the existing one in cover mode), decompose into slices, and write the plan that /m:build will execute.
model: claude-opus-4-6
argument-hint: <FEAT-XXXX | UC-XXXX> [more IDs ...]
allowed-tools:
  - Read
  - Write
  - Edit
  - Glob
  - Grep
  - Bash
  - Agent
  - AskUserQuestion
---

# Plan Command

`/m:plan` is the architect step. It reads the pending log entries written by `/m:spec`, `/m:fix`, `/m:change`, or `/m:cover`, decides the architecture and decomposition, and writes a reviewable plan that `/m:build` consumes.

`/m:plan` produces:

- Slice files written into the UC's support folder (`UC-XXXX-{slug}/SLICE-NNN-{kebab-name}.md`).
- A plan folder under `.molcajete/plans/<timestamp>-<descriptive-name>/` with `plan.md` inside.
- Updated log entries (status flipped from `pending` to `dirty`, plan-id stamped).

`/m:plan` does **not** write production code or tests. Hand-off to `/m:build` is mandatory.

**Use AskUserQuestion for all user interaction.**

## Step 1: Parse Arguments

`$ARGUMENTS` must be one or more `FEAT-XXXX` or `UC-XXXX` IDs. No trailing description — the plan derives intent from the pending log entries on the referenced UCs.

Expand any FEAT IDs to the full list of UCs under that feature.

If `$ARGUMENTS` is empty, ask via AskUserQuestion: "Which feature(s) or use case(s) do you want to plan? Pass at least one `FEAT-XXXX` or `UC-XXXX` ID."

## Step 2: Load Skills and Principles

Read in one batch:

1. `${CLAUDE_PLUGIN_ROOT}/spec/skills/architecture/SKILL.md`
2. `${CLAUDE_PLUGIN_ROOT}/spec/skills/slicing/SKILL.md`
3. `${CLAUDE_PLUGIN_ROOT}/spec/skills/reverse-engineering/SKILL.md` (only when at least one referenced UC has a `command:cover` pending entry)
4. `${CLAUDE_PLUGIN_ROOT}/shared/skills/id-generation/SKILL.md`
5. `${CLAUDE_PLUGIN_ROOT}/shared/skills/uc-log/SKILL.md` — CHANGELOG mechanics only.
6. `${CLAUDE_PLUGIN_ROOT}/shared/skills/status-rollup/SKILL.md` — status semantics, roll-up rule, and which command writes which level.
7. **Engineering principles.** Read `.claude/rules/principles.md` from the host project — this is the operative version of the principles. If the host file is missing, read `${CLAUDE_PLUGIN_ROOT}/shared/skills/principles/SKILL.md` instead and emit a one-line warning to the user: "No host principles file found at `.claude/rules/principles.md`. Using plugin defaults. Run `/m:setup` to generate the host file." The principles bind every architectural and test-scope decision made by this command.

## Step 3: Verify Prerequisites

`specs/PROJECT.md`, `specs/MODULES.md`, and `specs/TECH-STACK.md` must exist. Each referenced UC must have an existing `UC-XXXX-{slug}.md` spec file and a `CHANGELOG.md` inside its support folder.

## Step 4: Read the Pending Work

For each referenced UC, read:

- `UC-XXXX-{slug}.md` (the UC spec — specs, scenarios)
- The feature's `REQUIREMENTS.md`, `ARCHITECTURE.md`
- The UC's `CHANGELOG.md` (inside its support folder): collect every entry under `TODO:` whose status is `pending`. Skip entries already marked `dirty` (a prior plan owns them) and `implemented` entries (in `DONE:`).

If a referenced UC has **zero `pending` log entries**, ask via AskUserQuestion: "{UC} has no pending changes. Plan anyway? (Re-planning may overwrite slice files that already match the current spec.)"

Options: "Skip this UC" / "Re-plan anyway" / "Cancel".

## Step 5: Pick the Mode

Inspect the originating commands of all pending entries across the referenced UCs.

- All entries are `command:spec`, `command:fix`, or `command:change` → **mode: default**.
- All entries are `command:cover` → **mode: cover**.
- A mix of `cover` and any other command → **refuse**.

Refusal message:

> Mixed-mode plan refused. The referenced UCs have pending entries from both `/m:cover` (existing code) and `/m:spec`/`/m:fix`/`/m:change` (new behavior). Run two separate `/m:plan` invocations — one for the cover entries, one for the rest. The exact split: {list of UCs grouped by mode}.

Stop without writing.

## Step 6: Architecture Pass

**Apply the engineering principles loaded in Step 2.** Architecture decisions follow Principle 2 (hexagonal default) and Principle 3 (DI). Test-scope decisions follow Principle 1 (integration first; unit only when the algorithm IS the contract, justified per slice).

**mode: default.** Design or revise the architecture for the affected UCs:

- Identify ports (driving and driven), adapters, domain boundaries, and any cross-cutting work (migrations, shared adapters, configuration). Driver ports come from `specs/MODULES.md`'s `Driving Ports` column.
- Wire dependencies through DI per Principle 3 — no module-level globals or import-time side effects in what you scope.
- Reflect the design back into the feature's `ARCHITECTURE.md` per the architecture skill's Table Filling rules. Add or update Component Inventory, API Surface, Code Map, and Event Topology rows as needed.

**mode: cover.** Skip architectural design — the architecture is already in the code. Use the reverse-engineering skill to reconstruct the implicit structure and ensure each UC's `ARCHITECTURE.md` reflects what's actually shipped (Component Inventory, API Surface, Code Map, Event Topology). Reverse-spec discovery patterns from that skill apply here.

Present the architecture changes via a single AskUserQuestion before slicing:

> "Here is the architecture plan for {scope}: {bulleted summary of decisions and table changes}. Proceed to slicing?"

Options: "Proceed" / "Edit" (user provides corrections via Other) / "Cancel".

## Step 7: Decompose into Slices

Per the slicing skill's Slicing Rules, decompose each affected UC into the minimal DAG of slices that covers every uncovered scenario.

For **mode: default**:

- Each slice's `objective: implement`.
- `files.create` and `files.modify` reflect the production files the slice writes/edits.
- Reuse existing slice files when the new pending entries don't change the slice's contract. Add new slice files for new scenarios. Append to an existing slice's `covers` / `Tests` when the new scenario rides on the same code path.

For **mode: cover**:

- Each slice's `objective: coverage`.
- `files.create` stays empty. `files.modify` lists the shipped files whose behavior the slice tests.
- `provides` lists the existing exports the slice's tests pin (used by the mutation step).
- If the existing code uses a driving-port kind not yet in the module's `Driving Ports` list in `specs/MODULES.md`, add it and surface the addition in the report.

**Slice status (per the `status-rollup` skill):**

- For each **new** slice file written, set frontmatter `status: pending`.
- For each **existing** slice file that this plan supersedes (the spec changed and the slice's behavior may need to change), set frontmatter `status: dirty`. A slice is superseded when its `covers` list is touched by a pending changelog entry or when the spec edits invalidate its Tests section.
- Slice files that stay `implemented` and are not touched by this plan keep their existing status.

`/m:plan` does **not** write UC or Feature status — that responsibility belongs to spec-phase commands (which write `dirty` directly when modifying an `implemented` UC) and to `/m:build` (which rolls up after a slice completes).

Slice files live inside the UC's support folder:

```
specs/features/{module}/FEAT-XXXX-{slug}/UC-XXXX-{slug}/SLICE-NNN-{kebab-name}.md
```

Slice ID `NNN` is sequential within the UC. Scan the UC's support folder for existing `SLICE-NNN-*.md` files, take `max(NNN)`, and continue. New UCs start at `001`.

Use the slice template at `${CLAUDE_PLUGIN_ROOT}/spec/skills/slicing/templates/slice-template.md`. Pick the contract language tag from `specs/TECH-STACK.md`. **Do not emit a `test_file` field** — the canonical test path is derived from frontmatter and `specs/MODULES.md` at build time.

Every `SC-` in each UC must be covered by exactly one slice's `covers`.

## Step 8: Generate the Plan Folder

Pick a descriptive name from the pending entries' reasons (kebab-case, max 40 chars, e.g., `add-email-verification`, `fix-409-on-duplicate`, `cover-billing-cron`). Build the plan ID:

```
<YYYYMMDDTHHMMSS>-<descriptive-name>
```

Timestamp is UTC, ISO compact (e.g., `20260616T141530`). Create the folder:

```
.molcajete/plans/<plan-id>/
```

Every `/m:plan` invocation creates a **new** folder. Never amend an existing plan folder.

## Step 9: Write plan.md

Write `.molcajete/plans/<plan-id>/plan.md` as a flat Markdown list, organized by FEAT then UC. One `T-NNN` per slice; sub-tasks indented as `T-NNN.N`.

Shape:

```markdown
# Plan {descriptive-name}
mode: default | cover

## Context
- Project: `specs/PROJECT.md`, `specs/MODULES.md`, `specs/TECH-STACK.md`
- FEAT-XXXX-{slug}: `specs/features/{module}/FEAT-XXXX-{slug}/REQUIREMENTS.md`, `…/ARCHITECTURE.md`, `…/USE-CASES.md`
  - UC-XXXX-{slug}: `…/UC-XXXX-{slug}.md`
  - UC-YYYY-{slug}: `…/UC-YYYY-{slug}.md`
- FEAT-ZZZZ-{slug}: …

## FEAT-XXXX-{slug}
### UC-XXXX-{slug}
- [ ] T-001 — SLICE-001-{slice-name}.md
  - [ ] T-001.1 — scaffold integration test
  - [ ] T-001.2 — implement
  - [ ] T-001.3 — mutation check
  - [ ] T-001.4 — coverage gate
- [ ] T-002 — SLICE-002-{slice-name}.md

### UC-YYYY-{slug}
- [ ] T-003 — SLICE-001-{slice-name}.md
```

Rules:

- `T-NNN` is assigned plan-locally and starts at `001`. Numbering crosses FEAT/UC boundaries within the plan.
- The slice reference after the em dash is the slice filename (`SLICE-NNN-{name}.md`), not the slice ID — the slice file is the source of truth.
- **Sub-task shape is fixed:** scaffold integration test → implement → mutation check → coverage gate. Enumerate sub-tasks only when the slice benefits from explicit decomposition; otherwise omit them and the build loop runs the four steps implicitly.
- In **mode: cover**, omit the `implement` sub-task — the code already exists. The TDD loop becomes: scaffold integration test (must start GREEN) → mutation check → coverage gate.
- **Integration is the default per-slice test type** (Principle 1). If a slice's heart is heavy algorithmic logic (parser, encoder, hash, math), it may be a **unit-test slice** — record the justification in the slice's `## Rationale` so `/m:build` knows to scaffold a unit test rather than an integration test.
- The `## Context` section lists upstream paths for every FEAT and UC touched by this plan. `/m:build` cross-checks this list against derived paths; missing or stale entries surface as warnings. This is a documentation aid for the reader — the build derives the authoritative set from FEAT/UC headings.

## Step 10: Update the UC Changelogs

For every UC whose pending entries were consumed by this plan, use the `uc-log` shared skill to:

1. For each consumed entry in the UC's CHANGELOG.md, flip its status from `pending` to `dirty` and set `plan:<plan-id>`. The entry stays in the `TODO:` section.

`/m:plan` does **not** touch UC or Feature frontmatter `status`. UC status was already set to `dirty` by the spec-phase command that produced the changelog entries (when modifying a previously-`implemented` UC). Slice frontmatter `status` is written in Step 7.

## Step 11: Report

Tell the user:

- The plan folder path: `.molcajete/plans/<plan-id>/`.
- The mode (`default` or `cover`).
- The slices written (paths and IDs), grouped by FEAT/UC.
- The pending log entries flipped to `dirty`.
- The `plan.md` task list at a glance.

End the report with the explicit hand-off:

> Next: review `plan.md`. When ready, run `/m:build <plan-id> T-001 [more task IDs ...]` to execute. Pass a single `T-NNN`, multiple, or a sub-task like `T-001.2`.
