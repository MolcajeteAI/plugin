---
description: Extract specs from existing code (scope inferred from freeform input). Tests come later via /m:plan + /m:build.
model: claude-opus-4-6
argument-hint: <freeform description — capability, feature, UC, or single code path>
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

# Cover Command

`/m:cover` extracts product specs from an existing codebase: features, use cases, and inline scenarios. The code already exists; this command captures it so the lifecycle can later cover it with integration tests.

**Spec phase only.** `/m:cover` writes spec prose, populates ARCHITECTURE.md, appends a log entry, and hands off to `/m:plan`. It does **not** produce slices, plans, code, or tests.

Scope is inferred from the freeform argument:

- Broad capability ("authentication system") → may produce multiple features.
- Single feature ("the auth feature") → one FEAT with its UCs.
- Single use case ("the login flow") → one UC under the matching feature.
- Single code path ("the duplicate-email rejection branch") → append a single scenario to its parent UC.

The model decides scope from the description. No separate command per scope.

**Use AskUserQuestion for all user interaction.**

## Step 1: Load Skills

Read in one batch:

1. `${CLAUDE_PLUGIN_ROOT}/spec/skills/reverse-engineering/SKILL.md`
2. `${CLAUDE_PLUGIN_ROOT}/spec/skills/feature-authoring/SKILL.md`
3. `${CLAUDE_PLUGIN_ROOT}/spec/skills/usecase-authoring/SKILL.md`
4. `${CLAUDE_PLUGIN_ROOT}/spec/skills/architecture/SKILL.md`
5. `${CLAUDE_PLUGIN_ROOT}/shared/skills/id-generation/SKILL.md`
6. `${CLAUDE_PLUGIN_ROOT}/shared/skills/uc-log/SKILL.md`

## Step 2: Verify Prerequisites

`specs/PROJECT.md` and `specs/MODULES.md` must exist. If missing: "Project foundation not found. Run `/m:setup` first." Stop.

## Step 3: Load Project Context

Read `specs/PROJECT.md`, `specs/TECH-STACK.md`, `specs/ACTORS.md`, `specs/MODULES.md`, `specs/DOMAINS.md`, `specs/FEATURES.md`. Skip missing optional files.

## Step 4: Collect Description

If `$ARGUMENTS` is empty, ask: "Describe the existing code capability you want extracted. Mention paths, function names, or modules if it helps narrow scope."

## Step 5: Infer Scope

From the description, decide the scope:

- **Broad capability or multiple areas** → discover feature groupings.
- **Single feature** (FEAT-XXXX referenced, or "the X feature") → extract one feature with its UCs.
- **Single UC** (UC-XXXX referenced, or "the X flow") → extract or append to one UC.
- **Single code path** (described as a branch / error case / variant) → resolve the parent UC and append one scenario inline.

If the description names an ID (FEAT-XXXX, UC-XXXX), use it. Otherwise resolve by keyword similarity to the loaded specs; if ambiguous, confirm via AskUserQuestion with the candidates.

## Step 6: Discovery Scan

Use Glob, Grep, and Read to find the implementation files in scope. Group by likely feature/UC boundary when extracting multiple. Present discovered files via AskUserQuestion: "Analyze all of these?" with options "Analyze all" / "Narrow" / "Add more files".

## Step 7: Extract via Subagent

Use the Agent tool (`subagent_type: general-purpose`) with one task: read the confirmed files and produce the spec content for the resolved scope. Pass:

- Skills to load: reverse-engineering, feature-authoring, usecase-authoring, architecture, uc-log.
- Project context paths.
- Confirmed file list.
- Resolved scope (one of: features, single feature, single UC, single code path) and any inferred module + domain.
- Instruction: produce REQUIREMENTS.md, UC spec files (`UC-XXXX-{slug}.md` as siblings of REQUIREMENTS.md / USE-CASES.md / ARCHITECTURE.md), UC support folders (each containing an initialized `CHANGELOG.md`), and appended scenarios as appropriate. Populate ARCHITECTURE.md (Component Inventory, Data Model, API Surface, Integration Points, Code Map, Event Topology) per the architecture skill's **Table Filling** rules — every applicable table must be populated. Generate all IDs in one batch call. Add newly discovered actors to ACTORS.md and newly discovered tech-stack entries to TECH-STACK.md per the reverse-engineering skill's project-level discovery rules.

**Do not emit slice files. Do not emit code files. Do not emit test files.** Slice authorship belongs to `/m:plan` (in `mode: cover`); tests are written by `/m:build`.

While scanning the codebase, also collect any **existing test files** that live outside the canonical Test File Convention paths (e.g., tests co-located with source as `src/foo/bar.test.ts` when the module's `Tests` directory says `tests/` or similar). The subagent must produce a "Non-canonical Test Paths" list capturing every such file path it observed. `/m:cover` must **not** move or rewrite these files — they stay where they are.

For single code path scope, the subagent appends one scenario block to the parent UC spec file `UC-XXXX-{slug}.md` (with `---` separators) and increments the UC's frontmatter version.

## Step 8: Append Log Entry and Set UC Status

For every UC touched in Step 7 (new or modified), use the `uc-log` shared skill to:

1. Append a new entry to the UC's `CHANGELOG.md` (under `TODO:`, prepended) with:
   - timestamp (UTC, `YYYYMMDDTHHMMSS`)
   - status: `pending`
   - command: `cover`
   - plan: `—`
   - reason: one-line description of what was extracted (e.g., "extracted UC from src/auth/register.ts", "appended duplicate-email scenario from validateRegisterInput")
2. Set the UC's frontmatter `status` to `pending` per the `uc-log` skill's roll-up rules.

For brand-new UCs created by this command, also initialize the `CHANGELOG.md` file inside the UC's support folder (`UC-XXXX-{slug}/CHANGELOG.md`) with empty `TODO:` and `DONE:` sections before appending the entry.

## Step 9: Report

Tell the user what was created or updated:

- Features extracted with file paths and inline scenario counts.
- For each extracted or extended UC: the new UC status (`pending`) and the log entry that was appended.
- ARCHITECTURE.md tables populated per feature.
- New actors / tech-stack entries added.
- Testability Notes per UC if any signals were detected (silent — surface here as a brief list, do not interrupt the flow). Advisory output, not a recorded table.
- **Non-canonical Test Paths** — if the discovery scan found existing test files outside the canonical Test File Convention layout, list every such path under a clearly-labeled section. Include a one-line note: "Existing tests at non-canonical paths were not moved. You can migrate them to the canonical layout at your own pace; new integration tests will materialize at the canonical paths regardless." Omit this section if all test files are already canonical.

End the report with the explicit hand-off:

> Next: run `/m:plan <FEAT-XXXX | UC-XXXX> [more IDs ...]` to decompose the extracted UCs into coverage slices and write the plan that `/m:build` will execute (in `mode: cover` — tests only, no production code).
