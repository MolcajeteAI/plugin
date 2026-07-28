---
description: Read pending log entries on referenced UCs, design architecture (or accept the existing one in cover mode), decompose into vertical tasks, and write the prose plan that /m:build will execute.
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

`/m:plan` is the architect step. It reads the pending log entries written by `/m:spec`, `/m:fix`, `/m:change`, or `/m:cover`, decides the architecture and decomposition, and writes a reviewable prose plan that `/m:build` consumes.

`/m:plan` produces:

- A single prose plan file at `specs/plans/<timestamp>-<slug>/plan.md` — one `## [ ] T-NNN` task per vertical, working-software increment. No slice files.
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
2. `${CLAUDE_PLUGIN_ROOT}/plan/skills/plan-authoring/SKILL.md` — the plan file format, task shape, filing, and Test File Convention.
3. `${CLAUDE_PLUGIN_ROOT}/spec/skills/reverse-engineering/SKILL.md` (only when at least one referenced UC has a `command:cover` pending entry)
4. `${CLAUDE_PLUGIN_ROOT}/shared/skills/id-generation/SKILL.md`
5. `${CLAUDE_PLUGIN_ROOT}/shared/skills/uc-log/SKILL.md` — CHANGELOG mechanics only.
6. `${CLAUDE_PLUGIN_ROOT}/shared/skills/status-rollup/SKILL.md` — status semantics, roll-up rule, and which command writes which level.
7. **Engineering principles.** Read `.claude/rules/principles.md` from the host project — this is the operative version of the principles. If the host file is missing, read `${CLAUDE_PLUGIN_ROOT}/shared/skills/principles/SKILL.md` instead and emit a one-line warning to the user: "No host principles file found at `.claude/rules/principles.md`. Using plugin defaults. Run `/m:setup` to generate the host file." The principles bind every architectural and test-scope decision made by this command.

## Step 3: Verify Prerequisites

`specs/PROJECT.md`, `specs/MODULES.md`, and `specs/TECH-STACK.md` must exist. Each referenced `UC-XXXX` must resolve to at least one module-instance (an existing `UC-XXXX-{slug}.md` spec file with a `CHANGELOG.md` inside its support folder). Multi-module UCs must have one such module-instance per module.

## Step 4: Read the Pending Work

Multi-module UCs share one `UC-XXXX` ID across every module the capability appears in (see `spec/skills/usecase-authoring/SKILL.md` → Module-Scoped Use Cases). For each referenced `UC-XXXX`, first **resolve its module-instances**: glob `specs/features/*/FEAT-*/UC-XXXX-*.md`. Every match is one module-instance of that UC. The module is the segment immediately under `specs/features/`.

For each module-instance of each referenced UC, read:

- `UC-XXXX-{slug}.md` (the module-scoped UC spec — specs, scenarios)
- That module's feature `REQUIREMENTS.md`, `ARCHITECTURE.md`
- That module-instance's `CHANGELOG.md` (inside its support folder): collect every entry under `TODO:` whose status is `pending`. Skip entries already marked `dirty` (a prior plan owns them) and `implemented` entries (in `DONE:`). Entries carrying a `modules:` token indicate fan-out from a prior spec-phase command; treat each module-instance's entry as an independent pending item to consume.

If a referenced UC has **zero `pending` log entries across all its module-instances**, ask via AskUserQuestion: "{UC} has no pending changes. Plan anyway? (Re-planning may overwrite a plan that already matches the current spec.)"

If a referenced UC has pending entries in some module-instances but not others, plan only the module-instances with pending entries — untouched instances stay `implemented`.

Options: "Skip this UC" / "Re-plan anyway" / "Cancel".

## Step 5: Pick the Mode

Inspect the originating commands of all pending entries across the referenced UCs.

- No `command:cover` entries (only `command:spec` / `command:fix` / `command:change`) → **mode: default** (all `implement` tasks).
- Only `command:cover` entries → **mode: cover** (all `coverage` tasks).
- Both `command:cover` and any of `command:spec` / `command:fix` / `command:change` present → **mode: mixed**.

Plan-level `mode` is a summary label written on the `**Specs:**` line. Per-task truth is carried by each task's prose (implement vs coverage — see the plan-authoring skill's "Task Objectives"). In `mode: mixed`, coverage tasks are ordered (lower `T-NNN`) before the implement tasks that change the same behavior, so existing behavior is pinned before it is modified.

## Step 6: Architecture Pass

**Apply the engineering principles loaded in Step 2.** Architecture decisions follow Principle 2 (hexagonal default) and Principle 3 (DI). Test-scope decisions follow Principle 1: **every task's tests are integration tests**. Molcajete does not scaffold unit tests — that is the host team's concern, outside this lifecycle.

**mode: default.** Design or revise the architecture for the affected UCs:

- Identify ports (driving and driven), adapters, domain boundaries, and any cross-cutting work (migrations, shared adapters, configuration). Driver ports come from `specs/MODULES.md`'s `Driving Ports` column.
- Wire dependencies through DI per Principle 3 — no module-level globals or import-time side effects in what you scope.
- Reflect the design back into the feature's `ARCHITECTURE.md` per the architecture skill's Table Filling rules. Add or update Component Inventory, API Surface, Code Map, and Event Topology rows as needed.

**mode: cover.** Skip architectural design — the architecture is already in the code. Use the reverse-engineering skill to reconstruct the implicit structure and ensure each UC's `ARCHITECTURE.md` reflects what's actually shipped (Component Inventory, API Surface, Code Map, Event Topology).

**mode: mixed.** Do both, in order, per UC:

1. Apply the `mode: cover` reverse-engineering pass first for the UC's existing behavior — ensure `ARCHITECTURE.md` reflects the shipped code. This pins the current design as the baseline.
2. Apply the `mode: default` design pass on top for the `command:spec` / `command:fix` / `command:change` entries — identify ports, adapters, and DI wiring for the new/modified behavior. Reflect the deltas into `ARCHITECTURE.md`.

Present the architecture changes via a single AskUserQuestion before decomposing:

> "Here is the architecture plan for {scope}: {bulleted summary of decisions and table changes}. Proceed to task decomposition?"

Options: "Proceed" / "Edit" (user provides corrections via Other) / "Cancel".

## Step 7: Decompose into Tasks

Per the plan-authoring skill's Vertical-Increment Rules, decompose the affected UCs into the minimal ordered list of **vertical, working-software tasks** that closes every uncovered scenario. Each task delivers one behavior across all the layers it needs — never a single layer. Tasks are ordered by dependency; that order becomes the `T-NNN` sequence.

For each task, write the task section per the plan-authoring skill's Task Shape:

- `## [ ] T-NNN — {outcome}` heading (checkbox, plan-local sequential ID).
- `**Covers:**` — the comma-separated `SC-`/`FR-` IDs this task closes.
- `**Depends on:**` — the comma-separated prior `T-NNN`s, or `—`.
- Prose that names the target files, the entry point / driving port, what "green" means, and the decisions/trade-offs — enough detail that `/m:build` can derive the test path, scaffold the test, and implement without guessing. See the plan-authoring skill's "Task Prose".

For **mode: default** — every task is an implement task: the integration test starts RED and build writes production code to GREEN. Reuse the existing production surface where the new scenarios ride the same code path; introduce new files where the behavior is new.

For **mode: cover** — every task is a coverage task: state in the prose that it pins existing behavior with no new production code, name the shipped files whose behavior it tests, and describe the assertions that lock current behavior (the mutation step will prove they have teeth). If the existing code uses a driving-port kind not yet in the module's `Driving Ports` list in `specs/MODULES.md`, add it and surface the addition in the report.

For **mode: mixed** — each pending entry drives its own tasks. `command:cover` entries produce coverage tasks; `command:spec` / `command:fix` / `command:change` entries produce implement tasks. **Order all coverage tasks (lower `T-NNN`) before the implement tasks** that change the same behavior, so `/m:build`'s ascending walk pins existing behavior before writing new behavior.

**Rules:**

- Every `SC-` in every UC in scope must appear in exactly one task's `Covers`. Same for any `FR-` a task claims.
- A production file is created/modified by at most one task in the plan. If two tasks need the same file, merge them or sequence them via `Depends on`.
- Keep each task sized to fit a single ~200k-token build context. Split only at a genuine logical boundary or on a context-size overflow — never to isolate a layer.

### Consult non-canonical existing tests (mode: cover / mixed only)

Skip this in `mode: default`. When a UC has a `command:cover` pending entry, `/m:cover` may have recorded existing scattered tests worth consulting when `/m:build` scaffolds the canonical integration test.

For each such UC, read its `CHANGELOG.md`, find the most recent `command: cover` entry, and collect the **non-canonical test file paths** it recorded (existing test files touching the UC's production code that live outside the canonical tests tree). For each such file, prompt via AskUserQuestion once per file:

> "Existing test `{path}` touches code covered by `{UC-XXXX-slug}`. What should `/m:build` do with it when it scaffolds the canonical integration test?"

Options:

- **"Reference-only"** (default): `/m:build` reads the file, lifts fixtures / setup / assertion patterns into the new integration test, leaves the original in place.
- **"Migrate"**: same as reference-only, plus `/m:build` prompts to delete the original after the canonical test verifies.
- **"Ignore"**: `/m:build` never opens the file.

For each non-ignored decision, **name the file in the prose of the task whose behavior overlaps it**, with the mode inline — e.g. "When scaffolding, consult the existing test `src/legacy/foo.test.ts` (reference)" or "(migrate — delete after the canonical test is green)". There is no frontmatter to record this; the task prose carries it. This step never moves or deletes files.

## Step 8: Generate the Plan Folder

Pick a descriptive slug from the pending entries' reasons (kebab-case, max 40 chars, e.g., `add-email-verification`, `fix-409-on-duplicate`, `cover-billing-cron`). Build the plan ID:

```
<YYYYMMDDTHHMMSS>-<slug>
```

Timestamp is UTC, ISO compact to the second (e.g., `20260616T141530`). Create the folder under `specs/`:

```
specs/plans/<plan-id>/
```

Every `/m:plan` invocation creates a **new** folder. Never amend an existing plan folder. Plans live under `specs/` because they are part of the application's recorded change history.

## Step 9: Write plan.md

Write `specs/plans/<plan-id>/plan.md` as a single prose document per the plan-authoring skill's Plan File Structure. Shape:

```markdown
# Plan: {Descriptive Name}

{One or two sentences: the working capability this plan delivers, and why.}

**Specs:** FEAT-XXXX-{slug} · UC-XXXX-{slug} · SC-XXXX, SC-YYYY  ·  **Mode:** default | cover | mixed

{Optional short paragraph of shared context — what we're building and the slice of the
architecture it touches. Reference the spec files once here so no task repeats them.}

## [ ] T-001 — {User-visible behavior}

**Covers:** SC-XXXX
**Depends on:** —

{Prose: what this increment makes real end to end, the files it creates/modifies named
inline, the entry point it rides, what "green" means, and the decisions/trade-offs.}

## [ ] T-002 — {Next behavior}

**Covers:** SC-YYYY, SC-ZZZZ
**Depends on:** T-001

{Prose.}
```

Rules:

- `T-NNN` is assigned plan-locally, starts at `001`, and crosses FEAT/UC/module boundaries — one `T-NNN` sequence per plan.
- The `**Specs:**` line names every FEAT and UC touched by the plan and the scenarios in scope. For a multi-module UC, name each module the tasks touch; the files in each task's prose make the module concrete.
- **Every task is an integration-test task** (Principle 1). Never annotate a task as unit-test — Molcajete generates integration tests only.
- `Covers` and `Depends on` are comma-separated lists and sit directly under the heading, before the prose.

## Step 10: Update the UC Changelogs

For every module-instance of every UC whose pending entries were consumed by this plan, use the `uc-log` shared skill to:

1. For each consumed entry in that module-instance's CHANGELOG.md, flip its status from `pending` to `dirty` and set `plan:<plan-id>` (the `specs/plans` folder name). The entry stays in the `TODO:` section. The `modules:` token, if present, is preserved unchanged.

Multi-module UCs have one CHANGELOG.md per module-instance; each is updated independently. A module-instance whose entries were not consumed stays `pending`.

`/m:plan` does **not** touch UC or Feature frontmatter `status`. UC status was already set to `dirty` by the spec-phase command that produced the changelog entries (when modifying a previously-`implemented` UC).

## Step 11: Report

Tell the user:

- The plan file path: `specs/plans/<plan-id>/plan.md`.
- The mode (`default`, `cover`, or `mixed`).
- The tasks written — each `T-NNN`, its outcome, and the scenarios it covers. In `mode: mixed`, sub-group into "Coverage tasks (pin existing behavior)" and "Implement tasks (new behavior)" so the split is visible.
- The pending log entries flipped to `dirty`.

End the report with the explicit hand-off:

> Next: review `plan.md`. When ready, run `/m:build <plan-id> T-001 [more task IDs ...]` to execute. Pass a single `T-NNN` or several.
