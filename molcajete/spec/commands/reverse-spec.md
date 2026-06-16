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
4. `${CLAUDE_PLUGIN_ROOT}/spec/skills/architecture/SKILL.md`
5. `${CLAUDE_PLUGIN_ROOT}/spec/skills/slicing/SKILL.md`

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

- Skills to load: reverse-engineering, feature-authoring, usecase-authoring, architecture, slicing.
- Project context paths.
- Confirmed file list.
- Resolved scope (one of: features, single feature, single UC, single code path) and any inferred module + domain.
- Instruction: produce REQUIREMENTS.md / UC files / appended scenarios as appropriate, populate ARCHITECTURE.md (Component Inventory, Data Model, API Surface, Integration Points, Code Map, Event Topology) per the architecture skill's **Table Filling** rules — every applicable table must be populated. Generate all IDs in one batch call (include `S-` prefixes for slices). Add newly discovered actors to ACTORS.md and newly discovered tech-stack entries to TECH-STACK.md per the reverse-engineering skill's project-level discovery rules.

For each new or extended UC, also emit slice files per the slicing skill — one Markdown file per slice in `prd/modules/{module}/features/FEAT-XXXX-{slug}/use-cases/UC-XXXX-{slug}.slices/UC-XXXX-NNN-{kebab-name}.md`. **Do not emit any code files.** Reverse-spec emits **coverage** slices: set `objective: coverage` in each slice's frontmatter. Coverage slices target existing files only — `files.create` stays empty, `files.modify` lists the shipped files whose uncovered behavior the slice will test. `provides` lists the exports those files already expose that the slice's tests pin (the harness uses this list as the mutation surface). Every `SC-` in the extracted UC must be covered by exactly one slice. Slice IDs are sequential within the UC: scan the `.slices/` folder for `max(NNN)` and increment; for new UCs start at `001`. **Set the slice's `entry_type`** to the driving-port kind that the shipped code uses to expose the behavior — inspect the implementation files to determine the kind (HTTP route handler, GraphQL resolver, event consumer, cron task, queue worker, public service method), and pick the matching kebab-case value from the module's `Driving Ports` column in `prd/MODULES.md`. If the extracted code uses a driving-port kind not yet in the module's list, add it to `prd/MODULES.md` as part of the reverse-spec emission and surface the addition in the report. **Do not emit a `test_file` field in slice frontmatter** — the canonical test path is derived from frontmatter and `prd/MODULES.md` at build time per the slicing skill's Test File Convention. Reuse the template at `${CLAUDE_PLUGIN_ROOT}/spec/skills/slicing/templates/slice-template.md`. Pick the contract language tag from `prd/TECH-STACK.md`.

While scanning the codebase, also collect any **existing test files** that live outside the canonical Test File Convention paths (e.g., tests co-located with source as `src/foo/bar.test.ts` when the module's `Tests` directory says `tests/` or similar). The subagent must produce a "Non-canonical Test Paths" list capturing every such file path it observed. Reverse-spec must **not** move or rewrite these files — they stay where they are.

For single code path scope, the subagent appends one scenario block to the parent UC file (with `---` separators), updates the UC's frontmatter version, and either extends an existing coverage slice's `covers` array and its Tests section (when the new scenario tests files already targeted by a slice) or emits one new coverage slice file in the UC's `.slices/` folder.

## Step 8: Report

Tell the user what was created or updated:

- Features extracted with file paths and inline scenario counts.
- For each extracted or extended UC: coverage slice IDs (UC-XXXX-NNN) with their `covers` lists and the derived test file paths (computed from frontmatter + `prd/MODULES.md` per the slicing skill's Test File Convention) that the CodeWriter will materialize at build time.
- ARCHITECTURE.md tables populated per feature.
- New actors / tech-stack entries added.
- Testability Notes per UC if any signals were detected (silent — surface here as a brief list, do not interrupt the flow). They are advisory output, not a recorded table.
- **Non-canonical Test Paths** — if the discovery scan found existing test files outside the canonical Test File Convention layout, list every such path under a clearly-labeled section in the report. Include a one-line note: "Existing tests at non-canonical paths were not moved. You can migrate them to the canonical layout at your own pace; new coverage slices will materialize at the canonical paths regardless." Omit this section if all test files are already canonical.

Suggest next step: "Run `molcajete build <UC-XXXX>` to execute the coverage slices — the harness will assert each scaffold starts GREEN, fill it out, then mutate the targeted files to confirm the new tests catch regressions."
