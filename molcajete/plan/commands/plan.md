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

- No `command:cover` entries (only `command:spec` / `command:fix` / `command:change`) → **mode: default**.
- Only `command:cover` entries → **mode: cover**.
- Both `command:cover` and any of `command:spec` / `command:fix` / `command:change` present → **mode: mixed**.

Plan-level `mode` is a summary label. Slice-level `objective` (`implement` / `coverage`) carries the per-slice truth that `/m:build` dispatches on. In `mode: mixed`, one plan folder contains both objectives; the ordering rule in Step 7 ensures coverage slices execute before implement slices so existing behavior is pinned before it is changed.

## Step 6: Architecture Pass

**Apply the engineering principles loaded in Step 2.** Architecture decisions follow Principle 2 (hexagonal default) and Principle 3 (DI). Test-scope decisions follow Principle 1: **every slice's tests are integration tests**. Molcajete does not scaffold unit tests — that is the host team's concern, outside this lifecycle. Do not emit "unit-test slice" annotations.

**mode: default.** Design or revise the architecture for the affected UCs:

- Identify ports (driving and driven), adapters, domain boundaries, and any cross-cutting work (migrations, shared adapters, configuration). Driver ports come from `specs/MODULES.md`'s `Driving Ports` column.
- Wire dependencies through DI per Principle 3 — no module-level globals or import-time side effects in what you scope.
- Reflect the design back into the feature's `ARCHITECTURE.md` per the architecture skill's Table Filling rules. Add or update Component Inventory, API Surface, Code Map, and Event Topology rows as needed.

**mode: cover.** Skip architectural design — the architecture is already in the code. Use the reverse-engineering skill to reconstruct the implicit structure and ensure each UC's `ARCHITECTURE.md` reflects what's actually shipped (Component Inventory, API Surface, Code Map, Event Topology). Reverse-spec discovery patterns from that skill apply here.

**mode: mixed.** Do both, in order, per UC:

1. Apply the `mode: cover` reverse-engineering pass first for the UC's existing behavior — ensure `ARCHITECTURE.md` reflects the shipped code (Component Inventory, API Surface, Code Map, Event Topology). This pins the current design as the baseline.
2. Apply the `mode: default` design pass on top for the `command:spec` / `command:fix` / `command:change` entries — identify ports, adapters, and DI wiring for the new/modified behavior per Principles 2 and 3. Reflect the deltas into `ARCHITECTURE.md` via the architecture skill's Table Filling rules.

The AskUserQuestion summary in mixed mode lists both the pinned current architecture and the new design deltas so the user can see the full picture before slicing.

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

For **mode: mixed**:

- Each pending entry drives its own slices. `command:cover` entries produce `objective: coverage` slices (apply the mode: cover rules above). `command:spec` / `command:fix` / `command:change` entries produce `objective: implement` slices (apply the mode: default rules above).
- **Coverage-before-implement ordering.** Within each UC, assign sequential NNN so that every coverage slice added by this plan lands before any implement slice added by this plan. When appending to a UC that already has slice files, honor the existing `max(NNN) + 1` convention — the ordering rule applies only to slices this plan writes. The plan's `T-NNN` list in Step 9 follows the same order so `/m:build`'s "process in `T-NNN` ascending" rule pins existing behavior before writing new behavior automatically.

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

### Consult non-canonical existing tests (mode: cover only)

Skip this in `mode: default`. In `mode: cover`, before writing slice files to disk, check whether `/m:cover` recorded any existing scattered tests worth consulting.

For every UC in scope:

1. Read the UC's `CHANGELOG.md`. Find the most recent `command: cover` entry (whether `pending`, `dirty`, or already `implemented`). If none exists, skip this UC.
2. From the report `/m:cover` produced for that entry (or, if the report is not preserved, from a fresh discovery scan constrained to files matching the UC's `files.modify` from the newly-decomposed slices), collect the list of **non-canonical test file paths** — existing test files touching the UC's production code that live outside `{module.Tests}/{feature-dir-name}/{uc-dir-name}/`.
3. If the list is empty, skip.
4. For each non-canonical test file, prompt via AskUserQuestion once per file:

   > "Existing test `{path}` touches code covered by `{UC-XXXX-slug}`. What should `/m:build` do with it when it scaffolds the canonical integration test?"

   Options:

   - **"Reference-only"** (default): `/m:build` reads the file when scaffolding the canonical test, lifts fixtures / setup / assertion patterns into the new integration test, leaves the original file in place. The original is not moved and not deleted.
   - **"Migrate"**: same as reference-only, plus `/m:build` prompts (after 8.9 succeeds) to delete the original file since its content now lives at the canonical path.
   - **"Ignore"**: `/m:build` never opens the file. Nothing is recorded on the slice.

5. For each non-ignored decision, attach the entry to the slice whose `covers` overlaps the production code the test touches. If more than one candidate slice matches, prompt via AskUserQuestion asking which slice the reference should attach to (list the candidate slice IDs and names). Record the entry in the target slice's frontmatter `references:` list:

   ```yaml
   references:
     - path: <relative path to original test file>
       mode: reference   # or migrate
   ```

6. Skip silently for UCs where the last cover entry has no non-canonical paths recorded.

This step never moves or deletes test files. It only decides what `/m:build` will do later.

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
mode: default | cover | mixed

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
- In **mode: mixed**, sub-task shape is per-slice: coverage slices (`objective: coverage`) omit the `implement` sub-task per the mode: cover rule; implement slices (`objective: implement`) keep all four. Under each UC block, list every coverage `T-NNN` before any implement `T-NNN` so the on-disk `T-NNN` sequence matches the execution order the build will follow.
- **Every slice is an integration-test slice** (Principle 1). Never annotate a slice as unit-test or emit "unit-test slice" in the plan — Molcajete generates integration tests only.
- The `## Context` section lists upstream paths for every FEAT and UC touched by this plan. `/m:build` cross-checks this list against derived paths; missing or stale entries surface as warnings. This is a documentation aid for the reader — the build derives the authoritative set from FEAT/UC headings.

## Step 10: Update the UC Changelogs

For every UC whose pending entries were consumed by this plan, use the `uc-log` shared skill to:

1. For each consumed entry in the UC's CHANGELOG.md, flip its status from `pending` to `dirty` and set `plan:<plan-id>`. The entry stays in the `TODO:` section.

`/m:plan` does **not** touch UC or Feature frontmatter `status`. UC status was already set to `dirty` by the spec-phase command that produced the changelog entries (when modifying a previously-`implemented` UC). Slice frontmatter `status` is written in Step 7.

## Step 11: Report

Tell the user:

- The plan folder path: `.molcajete/plans/<plan-id>/`.
- The mode (`default`, `cover`, or `mixed`).
- The slices written (paths and IDs), grouped by FEAT/UC. In `mode: mixed`, sub-group each UC's slices into "Coverage slices (pin existing behavior)" and "Implement slices (new behavior)" so the reader can see the split at a glance.
- The pending log entries flipped to `dirty`.
- The `plan.md` task list at a glance.

End the report with the explicit hand-off:

> Next: review `plan.md`. When ready, run `/m:build <plan-id> T-001 [more task IDs ...]` to execute. Pass a single `T-NNN`, multiple, or a sub-task like `T-001.2`.
