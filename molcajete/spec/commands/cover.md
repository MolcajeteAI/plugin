---
description: Extract specs from existing code (scope inferred from freeform input). Tests come later via /m:plan + /m:build.
model: claude-opus-5
argument-hint: <freeform description — capability, feature, UC, or single code path>
allowed-tools:
  - Read
  - Write
  - Edit
  - Glob
  - Grep
  - Bash
  - AskUserQuestion
---

# Cover Command

`/m:cover` extracts product specs from an existing codebase: features, use cases, and inline scenarios. The code already exists; this command captures it so the lifecycle can later cover it with integration tests.

**Spec phase only.** `/m:cover` writes spec prose, populates ARCHITECTURE.md, appends a log entry, and hands off to `/m:plan`. It does **not** produce plans, code, or tests.

Scope is inferred from the freeform argument:

- Broad capability ("authentication system") → may produce multiple features.
- Single feature ("the auth feature") → one FEAT with its UCs.
- Single use case ("the login flow") → one UC under the matching feature.
- Single code path ("the duplicate-email rejection branch") → append a single scenario to its parent UC.

The model decides scope from the description. No separate command per scope.

**Questions:** every substantive question is two moves — write the brief, then ask. Read `${CLAUDE_PLUGIN_ROOT}/shared/skills/asking-questions/SKILL.md` before the first question.

**Writing style:** every document you write and every message you print is Simplified Technical English. Read `${CLAUDE_PLUGIN_ROOT}/shared/skills/writing-style/SKILL.md` before writing.

## Step 1: Load Skills

1. `${CLAUDE_PLUGIN_ROOT}/spec/skills/reverse-engineering/SKILL.md`
2. `${CLAUDE_PLUGIN_ROOT}/spec/skills/feature-authoring/SKILL.md`
3. `${CLAUDE_PLUGIN_ROOT}/spec/skills/usecase-authoring/SKILL.md`
4. `${CLAUDE_PLUGIN_ROOT}/spec/skills/architecture/SKILL.md`
5. `${CLAUDE_PLUGIN_ROOT}/shared/skills/id-generation/SKILL.md`
6. `${CLAUDE_PLUGIN_ROOT}/shared/skills/uc-log/SKILL.md` — CHANGELOG mechanics only.
7. `${CLAUDE_PLUGIN_ROOT}/shared/skills/status-rollup/SKILL.md` — how to write UC and Feature status directly.

## Step 2: Verify Prerequisites

`specs/PROJECT.md` and `specs/MODULES.md` must exist. If missing: "Project foundation not found. Run `/m:setup` first." Stop.

## Step 3: Load Project Context

Read `specs/PROJECT.md`, `specs/TECH-STACK.md`, `specs/ACTORS.md`, `specs/MODULES.md`, `specs/DOMAINS.md`, `specs/FEATURES.md`. Skip missing optional files.

## Step 4: Collect Description

If `$ARGUMENTS` is empty, ask via AskUserQuestion: "Describe the existing code capability you want extracted." Put the guidance — mention paths, function names, or modules to narrow scope — in the brief, not in the question text.

## Step 5: Infer Scope

Decide the scope from the description, per the ladder above. If the description names an ID (FEAT-XXXX, UC-XXXX), use it. Otherwise resolve by keyword similarity to the loaded specs; if ambiguous, confirm via AskUserQuestion with the candidates.

## Step 6: Discovery Scan

Use Glob, Grep, and Read to find the implementation files in scope. Group by likely feature/UC boundary when extracting multiple. Then confirm the file set — the list is the brief:

- Brief: print the discovered files as a Markdown table, grouped by the feature/UC boundary they
  fall under, with a one-line note on what each contributes. State the total count.
- Question: "Analyze all of these files?"
- Header: "File scope"
- Options: "Analyze all" / "Narrow" / "Add more files"

## Step 7: Extract the Specs

Read the confirmed files and write the spec content for the resolved scope: REQUIREMENTS.md, UC spec files (`UC-XXXX-{slug}.md` as siblings of REQUIREMENTS.md / USE-CASES.md / ARCHITECTURE.md), UC support folders (each containing an initialized `CHANGELOG.md` with empty TODO/DONE sections), and appended scenarios as appropriate. Populate ARCHITECTURE.md (Component Inventory, Data Model, API Surface, Integration Points, Code Map, Event Topology) per the architecture skill's **Table Filling** rules — every applicable table must be populated. Generate all IDs in one batch call. Add newly discovered actors to ACTORS.md and newly discovered tech-stack entries to TECH-STACK.md per the reverse-engineering skill's project-level discovery rules.

**Multi-module capability handling.** When the discovered code spans multiple modules for what is logically the same capability (same business event, same domain object, same lifecycle):

- Generate **one shared `UC-XXXX` ID** for that capability and reuse it across every module the capability appears in. Do not mint per-module IDs.
- Emit one `UC-XXXX-{slug}.md` **per module**, each written from that module's perspective — module-specific actor, trigger, scenarios, and side effects (per `spec/skills/usecase-authoring/SKILL.md` → Module-Scoped Use Cases). Names and slugs may differ per module.
- Emit one `UC-XXXX-{slug}/` support folder per module, each with its own `CHANGELOG.md` initialized.
- Add a row to each module's feature `USE-CASES.md`.
- Record the target module set for the shared UC — Step 8 uses it to fan out the log entry with the `modules:` token.

Same-ID / different-content is the correct pattern here.

While scanning the codebase, also collect any **existing test files** that live outside the canonical Test File Convention paths (e.g., tests co-located with source as `src/foo/bar.test.ts` when the module's `Tests` directory says `tests/` or similar). Produce a "Non-canonical Test Paths" list capturing every such file path observed. `/m:cover` must **not** move or rewrite these files — they stay where they are.

For single code path scope, append one scenario block to the parent UC spec file `UC-XXXX-{slug}.md` (with `---` separators) and increment the UC's frontmatter version.

## Step 8: Append Log Entry and Set UC Status

For every UC-XXXX touched in Step 7 (new or modified), iterate over every module-instance emitted: append the changelog entry per the `uc-log` shared skill, then write that instance's and its parent feature's status per the `status-rollup` shared skill. Extracted UC instances are always `pending`.

Per-command entry values:

- command: `cover`
- plan: `—`
- timestamp: the **same** UTC timestamp across every module-instance of the same UC-XXXX in this run
- reason: one-line description of what was extracted from this module (e.g., "extracted UC from `apps/patient/src/register.ts`", "appended duplicate-email scenario from `packages/api/validateRegisterInput`"). Reasons may differ per module-instance since the source files differ.

## Step 9: Report

Tell the user what was created or updated:

- Features extracted with file paths and inline scenario counts.
- For each extracted or extended UC: the new UC status (`pending`) and the log entry that was appended.
- ARCHITECTURE.md tables populated per feature.
- New actors / tech-stack entries added.
- Testability Notes per UC if any signals were detected (silent — surface here as a brief list, do not interrupt the flow). Advisory output, not a recorded table.
- **Non-canonical Test Paths** — if the discovery scan found existing test files outside the canonical Test File Convention layout, list every such path under a clearly-labeled section. Include a one-line note: "`/m:plan` will consult this list when it decomposes these UCs and ask you per file whether to reference (default — read as input for the canonical integration test, leave original in place), migrate (same, plus delete original after 8.9 succeeds), or ignore." Omit this section if all test files are already canonical.

End the report with the explicit hand-off:

> Next: run `/m:plan <FEAT-XXXX | UC-XXXX> [more IDs ...]` to decompose the extracted UCs into coverage tasks and write the plan that `/m:build` will execute (in `mode: cover` — tests only, no production code).
