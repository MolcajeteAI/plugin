---
description: Read pending log entries on referenced UCs, design architecture (or accept the existing one in cover mode), decompose into vertical tasks, and write the prose plan that /m:build will execute.
model: claude-opus-5
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

`/m:plan` is the architect step. It reads the pending log entries written by `/m:spec` or `/m:cover`, decides the architecture and decomposition, and writes a reviewable prose plan that `/m:build` consumes.

> `/m:fix` and `/m:change` produce their own plan in-invocation and do **not** need `/m:plan` — they run the same "Producing a Plan" procedure directly. `/m:plan` is the planning step for the `/m:spec` and `/m:cover` flows, and for re-planning.

`/m:plan` produces:

- A single prose plan file at `specs/plans/<timestamp>-<slug>.md` — one `## [ ] T-NNN` task per vertical, working-software increment. No slice files.
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
2. `${CLAUDE_PLUGIN_ROOT}/plan/skills/plan-authoring/SKILL.md` — the plan file format, task shape, filing, Test File Convention, and the **Producing a Plan** procedure.
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

## Step 5: Produce the Plan

Run the **Producing a Plan** procedure from the `plan-authoring` skill (loaded in Step 2) over the pending entries collected in Step 4. The procedure: picks the mode (`default` / `cover` / `mixed`) from the entries' originating commands; runs the architecture pass and presents it via AskUserQuestion (the review gate); decomposes the affected UCs into vertical tasks; writes `specs/plans/<plan-id>.md`; and flips each consumed entry `pending → dirty` with the plan-id stamped.

The context the procedure needs is already in memory from Steps 2–4 (loaded skills, the UC specs, `REQUIREMENTS.md`/`ARCHITECTURE.md`, and the pending entries).

## Step 6: Report

Tell the user:

- The plan file path: `specs/plans/<plan-id>.md`.
- The mode (`default`, `cover`, or `mixed`).
- The tasks written — each `T-NNN`, its outcome, and the scenarios it covers. In `mode: mixed`, sub-group into "Coverage tasks (pin existing behavior)" and "Implement tasks (new behavior)" so the split is visible.
- The pending log entries flipped to `dirty`.

End the report with the explicit hand-off:

> Next: review `plan.md`. When ready, run `/m:build <plan-id> T-001 [more task IDs ...]` to execute. Pass a single `T-NNN` or several.
