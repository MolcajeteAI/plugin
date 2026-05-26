---
description: Reverse-engineer specs from existing code (scope inferred from freeform input)
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

# Reverse-Engineer Spec from Code

Extracts product specs from an existing codebase: features, use cases, and inline scenarios. Scope is inferred from the freeform argument:

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

## Step 2: Verify Prerequisites

`prd/PROJECT.md` and `prd/MODULES.md` must exist.

## Step 3: Load Project Context

Read `prd/PROJECT.md`, `prd/TECH-STACK.md`, `prd/ACTORS.md`, `prd/MODULES.md`, `prd/DOMAINS.md`, `prd/FEATURES.md`. Skip missing optional files.

## Step 4: Collect Description

If `$ARGUMENTS` is empty, ask: "Describe the existing code capability you want extracted. Mention paths, function names, or modules if it helps narrow scope."

## Step 5: Infer Scope

From the description, decide the scope:

- **Broad capability or multiple areas** → discover feature groupings.
- **Single feature** (FEAT-XXXX referenced, or "the X feature") → extract one feature with its UCs.
- **Single UC** (UC-XXXX referenced, or "the X flow") → extract or append to one UC.
- **Single code path** (described as a branch / error case / variant) → resolve the parent UC and append one scenario inline.

If the description names an ID (FEAT-XXXX, UC-XXXX), use it. Otherwise resolve by keyword similarity to the loaded PRD; if ambiguous, confirm via AskUserQuestion with the candidates.

## Step 6: Discovery Scan

Use Glob, Grep, and Read to find the implementation files in scope. Group by likely feature/UC boundary when extracting multiple. Present discovered files via AskUserQuestion: "Analyze all of these?" with options "Analyze all" / "Narrow" / "Add more files".

## Step 7: Extract via Subagent

Use the Agent tool (`subagent_type: general-purpose`) with one task: read the confirmed files and produce the spec content for the resolved scope. Pass:

- Skills to load: reverse-engineering, feature-authoring, usecase-authoring.
- Project context paths.
- Confirmed file list.
- Resolved scope (one of: features, single feature, single UC, single code path) and any inferred module + domain.
- Instruction: produce REQUIREMENTS.md / UC files / appended scenarios as appropriate, populate ARCHITECTURE.md (Component Inventory, Data Model, API Surface, Integration Points, Code Map). Generate all IDs in one batch call. Add newly discovered actors to ACTORS.md and newly discovered tech-stack entries to TECH-STACK.md per the reverse-engineering skill's project-level discovery rules.

For single code path scope, the subagent appends one scenario block to the parent UC file (with `---` separators) and updates the UC's frontmatter version.

## Step 8: Report

Tell the user what was created or updated:

- Features extracted with file paths and inline scenario counts.
- New actors / tech-stack entries added.
- Testability Notes per UC if any signals were detected (silent — surface here, do not interrupt the flow).

Suggest next step: "Run `/m:reverse-plan` to generate a coverage-recovery plan when modules need more test coverage."
