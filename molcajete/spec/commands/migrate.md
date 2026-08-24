---
description: One-shot v3-to-v4 spec-tree migration — insert anchors, scaffold and populate INTERFACE.md and DATA.md from code, collect the module charters. Runs once per project; migrates nothing else.
model: claude-opus-5
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

# Migrate Command

`/m:migrate` moves a v3 spec tree to v4. A v3 project is missing four things a v4 run needs: the module charters, INTERFACE.md, DATA.md, and the `<a id>` anchors in its spec files. This command fixes all of them in one invocation, and it exists only for that transition — it migrates nothing else and runs on nothing newer.

**Existing IDs are never touched.** The immutability rule holds through migration: every mixed-case v3 ID stays exactly as it is, and only the anchors, the contract files, and the charters are added.

**Questions:** every substantive question is two moves — write the brief, then ask. Read `${CLAUDE_PLUGIN_ROOT}/shared/skills/asking-questions/SKILL.md` before the first question.

**Writing style:** every document you write and every message you print uses Simplified Technical English. Read `${CLAUDE_PLUGIN_ROOT}/shared/skills/writing-style/SKILL.md` and `${CLAUDE_PLUGIN_ROOT}/shared/skills/output-economy/SKILL.md` before writing.

## Step 1: Load Skills

1. `${CLAUDE_PLUGIN_ROOT}/spec/skills/module-authoring/SKILL.md` — the charter format, the INTERFACE.md and DATA.md templates, and the per-property responsibility rules.
2. `${CLAUDE_PLUGIN_ROOT}/spec/skills/reverse-engineering/SKILL.md` — the extraction rules Step 4 populates the contract files with.
3. `${CLAUDE_PLUGIN_ROOT}/shared/skills/id-generation/SKILL.md` — the immutability rules this command must not break.

## Step 2: Verify Prerequisites

`specs/PROJECT.md` and `specs/MODULES.md` must exist. If missing: "Project foundation not found. Run `/m:setup` first." Stop.

If every module already has `specs/modules/{module}/INTERFACE.md` and `DATA.md`, the MODULES.md table has a `Depends on` column, and a sample of UC files carries anchors, report "Already migrated — nothing to do." and stop.

## Step 3: Insert Anchors

Mechanical, one pass. For every spec file under `specs/features/`:

- Above every ID-bearing heading (`# UC-XXXX:`, `### SC-XXXX:`) and every requirement entry (`**FR-XXXX**`, `**NFR-XXXX**`, `**US-XXXX**`, `**ADR-XXXX:**`, and the feature title heading of each REQUIREMENTS.md), insert the line `<a id="{ID}"></a>` — the exact ID from the heading, character-for-character, mixed case preserved.
- Skip any item that already has an anchor line. The pass is idempotent.
- Change nothing else: no reflow, no renumber, no rewording.

Report the count of anchors inserted per file kind.

## Step 4: Scaffold and Populate the Contract Files

For each module in `specs/MODULES.md`, create `specs/modules/{module}/INTERFACE.md` and `DATA.md` from the module-authoring skill's templates, then populate the rows from code, the way `/m:cover` extracts specs:

- **INTERFACE.md** — scan the module's entry points (routes, resolvers, consumers, exported service APIs, per the module's `Driving Ports`). One element row per public element, with kind, signature, and `Covers` links resolved through the code's traceability comments and the ARCHITECTURE.md Code Map. Every consumed and returned type gets its section with per-property responsibilities. Draw the class diagram.
- **DATA.md** — scan the module's migrations, schema files, and models. One entity per owned table, every field carrying its quoted responsibility. Record cross-module relationships in **both** modules' files, per the module-authoring skill.

On large projects, launch one Explore subagent per module for the scan; the writes stay in this session. Where the code does not state a property's purpose, infer it from usage and mark nothing — an inferred responsibility is still a stated responsibility; the user reviews the files in Step 7.

## Step 5: Collect the Charters

Responsibilities are intent and cannot be extracted from code, so this step is a short interview — the one interactive part of the migration.

1. Add the `Depends on` column to the MODULES.md registry table, populating each module's value from the imports and service calls the Step 4 scan observed.
2. For each module, draft the charter — Responsibilities, Not responsible for, Relationships — from PROJECT.md, the module's description, and the scan.
3. Present each drafted charter for confirmation. The draft is the brief:
   - Question: "Is this charter for `{module}` right?"
   - Header: "Charter"
   - Options: "Yes" / "Edit"

## Step 6: Statuses

Leave every `status:` field as it is, `dirty` included. The status-rollup skill preserves legacy values until a run rebuilds the artifact; migration does not rewrite state.

## Step 7: Report

````markdown
## Migrated to v4

| Step | Result |
|---|---|
| Anchors | 214 inserted across 18 UC files and 6 REQUIREMENTS.md |
| INTERFACE.md | 3 modules, 27 elements mapped |
| DATA.md | 3 modules, 11 tables, 2 cross-module relationships |
| Charters | 3 written, `Depends on` column added |

Review `specs/modules/` — the element and table responsibilities were extracted from code and are worth a read. Existing IDs were not touched.
````

End with the hand-off:

> Next: `/m:spec`, `/m:change`, or `/m:fix` to author your first change request, then `molcajete build {change-id}` to execute it.
