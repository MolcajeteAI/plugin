---
description: Read pending log entries on referenced UCs, design architecture (or accept the existing one for cover work), decompose into vertical tasks each carrying a kind, and write the prose plan that /m:build will execute.
model: claude-fable-5
argument-hint: <FEAT-XXXX | UC-XXXX> [more IDs ...]
allowed-tools:
  - Read
  - Write
  - Edit
  - Glob
  - Grep
  - Bash
  - AskUserQuestion
---

# Plan Command

`/m:plan` is the architect step. It reads the pending log entries written by `/m:spec` or `/m:cover`, decides the architecture and decomposition, and writes a reviewable prose plan that `/m:build` consumes.

`/m:plan` produces:

- A single prose plan file at `specs/plans/<timestamp>-<slug>.md` — one `## [ ] T-NNN` task per vertical, working-software increment.
- Updated log entries (status flipped from `pending` to `dirty`, plan-id stamped).

`/m:plan` does **not** write production code or tests. Hand-off to `/m:build` is mandatory.

**Questions:** every substantive question is two moves — write the brief, then ask. Read `${CLAUDE_PLUGIN_ROOT}/shared/skills/asking-questions/SKILL.md` before the first question.

**Writing style:** every document you write and every message you print uses Simplified Technical English. Every one carries only what its reader needs. Read `${CLAUDE_PLUGIN_ROOT}/shared/skills/writing-style/SKILL.md` and `${CLAUDE_PLUGIN_ROOT}/shared/skills/output-economy/SKILL.md` before writing.

## Step 1: Parse Arguments

`$ARGUMENTS` must be one or more `FEAT-XXXX` or `UC-XXXX` IDs. No trailing description — the plan derives intent from the pending log entries on the referenced UCs.

Expand any FEAT IDs to the full list of UCs under that feature.

If `$ARGUMENTS` is empty, ask via AskUserQuestion: "Which feature(s) or use case(s) do you want to plan? Pass at least one `FEAT-XXXX` or `UC-XXXX` ID."

## Step 2: Load Skills and Principles

Read:

1. `${CLAUDE_PLUGIN_ROOT}/spec/skills/architecture/SKILL.md`
2. `${CLAUDE_PLUGIN_ROOT}/plan/skills/plan-authoring/SKILL.md` — the plan file format, task shape, filing, Test File Convention, and the **Producing a Plan** procedure.
3. `${CLAUDE_PLUGIN_ROOT}/shared/skills/resolution-gate/SKILL.md` — the design-time categories only (C4, C6, C7, C9, C10); the gate runs before the plan file is written.
4. `${CLAUDE_PLUGIN_ROOT}/spec/skills/reverse-engineering/SKILL.md` (only when at least one referenced UC has a `command:cover` pending entry)
5. `${CLAUDE_PLUGIN_ROOT}/shared/skills/id-generation/SKILL.md`
6. `${CLAUDE_PLUGIN_ROOT}/shared/skills/uc-log/SKILL.md` — CHANGELOG mechanics only.
7. `${CLAUDE_PLUGIN_ROOT}/shared/skills/status-rollup/SKILL.md` — status semantics, roll-up rule, and which command writes which level.
8. **Engineering principles.** Read `.claude/rules/principles.md` from the host project (fall back to `${CLAUDE_PLUGIN_ROOT}/shared/skills/principles/SKILL.md` with a one-line warning if missing). They bind every architectural and test-scope decision made by this command.

## Step 3: Verify Prerequisites

`specs/PROJECT.md`, `specs/MODULES.md`, and `specs/TECH-STACK.md` must exist. Each referenced `UC-XXXX` must resolve to at least one module-instance (an existing `UC-XXXX-{slug}.md` spec file with a `CHANGELOG.md` inside its support folder).

## Step 4: Read the Pending Work

For each referenced `UC-XXXX`, first **resolve its module-instances** (see `spec/skills/usecase-authoring/SKILL.md` → Module-Scoped Use Cases): glob `specs/features/*/FEAT-*/UC-XXXX-*.md`. Every match is one module-instance of that UC. The module is the segment immediately under `specs/features/`.

For each module-instance of each referenced UC, read:

- `UC-XXXX-{slug}.md` (the module-scoped UC spec — specs, scenarios)
- That module's feature `REQUIREMENTS.md`, `ARCHITECTURE.md`
- That module-instance's `CHANGELOG.md` (inside its support folder): collect every `TODO:` entry whose status is `pending`. Skip `dirty` entries — a prior plan owns them. Each module-instance's entry is an independent pending item to consume, including entries carrying a `modules:` token.

If a referenced UC has **zero `pending` log entries across all its module-instances**, ask. The consequence goes in the brief:

- Brief: name the UC, its current status, and the plan file that already exists for it. State that re-planning may overwrite a plan matching the current spec. Recommend "Skip this UC".
- Question: "{UC} has no pending changes. Plan it anyway?"
- Header: "No changes"
- Options: "Skip this UC" / "Re-plan anyway" / "Cancel"

If a referenced UC has pending entries in some module-instances but not others, plan only the module-instances with pending entries — untouched instances stay `implemented`.

## Step 5: Produce the Plan

Run the **Producing a Plan** procedure from the `plan-authoring` skill (loaded in Step 2) over the pending entries collected in Step 4.

## Step 6: Report

This is the shape:

````markdown
## Plan written — `20260820T1430-otp-expiry`

`mode: mixed` · 3 tasks · `specs/plans/20260820T1430-otp-expiry.md`

| Task | Kind | Outcome | Covers |
|---|---|---|---|
| T-001 | cover | Pins the current OTP send path | `SC-3Z2P` |
| T-002 | implement | Rejects an unregistered address | `SC-3Z2Q` |
| T-003 | change | Expires the OTP after 10 minutes | `SC-3Z2R`, `SC-3Z2S` |

**Log entries flipped to `dirty`**

- `UC-3Z2L` · module `auth` — stamped with this plan ID.
````

Rows stay in `T-NNN` order — the `Kind` column carries the split, so never regroup the table by kind. When the plan holds more than one kind, add one line under the table giving the count per kind.

End the report with the explicit hand-off:

> Next: review `plan.md`. When ready, run `/m:build <plan-id>` to execute. That runs every unfinished task in the plan. Add task IDs — `/m:build <plan-id> T-001 [more ...]` — to run a subset.
