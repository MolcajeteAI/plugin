---
description: Reverse-engineer a single scenario from a code path (inline into parent UC)
model: claude-opus-4-6
argument-hint: "[UC-XXXX] <freeform description of code path>"
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

# Reverse-Engineer Scenario from Code

You are extracting a scenario from existing code and writing it inline into the parent use case. This is the atomic reverse command — it scans a specific code path within a use case's scope, extracts scenario details, and appends them to the UC file using the existing flat-scenario format. The UC file is the only output.

**Input:** $ARGUMENTS

**All user interaction MUST use the AskUserQuestion tool.** Never ask questions as plain text in your response.

## Step 1: Load Skills

Read both skills that govern this command:

1. `${CLAUDE_PLUGIN_ROOT}/spec/skills/reverse-engineering/SKILL.md` — research methodology, extraction patterns, ARCHITECTURE.md enrichment, ID resolution
2. `${CLAUDE_PLUGIN_ROOT}/spec/skills/usecase-authoring/SKILL.md` — flat inline scenario structure, Side Effects conventions

Follow these skills' rules for all subsequent steps.

## Step 2: Verify Prerequisites and Resolve UC

### 2a: UC-XXXX Provided

Parse `$ARGUMENTS` for a `UC-XXXX` token. If found:

1. Glob `prd/modules/*/features/*/use-cases/UC-XXXX-*.md` (substituting the actual ID) to find the UC file. If not found:

   "Use case {UC-XXXX} not found. Check the ID and try again."

   Then stop.

2. Extract the parent `FEAT-XXXX` from the path (the directory name under `features/`) and the module from the path (under `prd/modules/`).

3. Verify `prd/MODULES.md` exists. If missing:

   "Run `/m:setup` first — MODULES.md is required."

   Then stop.

4. Verify FEAT-XXXX exists in `prd/FEATURES.md`. If not found:

   "Feature {FEAT-XXXX} not found in FEATURES.md. Check the ID and try again."

   Then stop.

### 2b: UC-XXXX Not Provided

If no `UC-XXXX` token is found in `$ARGUMENTS`, resolve the use case using the ID resolution rules from the reverse-engineering skill:

1. Glob `prd/modules/*/features/*/use-cases/*.md` to find all UC files
2. Read YAML frontmatter of each to get `id`, `name`, and `feature`
3. Match by keyword similarity to the freeform description in `$ARGUMENTS`
4. If 1 match → confirm via AskUserQuestion: "This appears to belong to **{UC-XXXX}: {name}** (under {FEAT-XXXX}). Is that correct?"
   - Options: "Yes" / "No, it belongs to another use case" (user specifies via Other) / "No matching use case — I need to create one first"
5. If N matches → disambiguate via AskUserQuestion: "Which use case does this code path belong to?\n\n{for each match: **{UC-XXXX}:** {name} (under {FEAT-XXXX})}"
6. If 0 matches → "No matching use case found. Use `/m:reverse-usecase` to create one first." Then stop.

After resolution, extract the parent FEAT-XXXX from the UC file path.

## Step 3: Load Project Context

Read these files to understand the project, feature, and use case:

- `prd/PROJECT.md` — what this project is
- `prd/TECH-STACK.md` — technology context (if exists)
- `prd/ACTORS.md` — known actors (if exists)
- `prd/modules/{module}/features/FEAT-XXXX-{slug}/REQUIREMENTS.md` — feature requirements
- `prd/modules/{module}/features/FEAT-XXXX-{slug}/ARCHITECTURE.md` — architecture context (if exists)
- `prd/modules/{module}/features/FEAT-XXXX-{slug}/use-cases/UC-XXXX-{slug}.md` — the target use case

## Step 4: Collect Description

The remainder of `$ARGUMENTS` after the optional UC-XXXX token is the freeform description.

If the freeform part is non-empty, use it as the description of the code path to extract.

If the freeform part is empty, use AskUserQuestion:
- Question: "Describe the code path you want to extract as a scenario. Include any relevant function names, endpoints, error conditions, or edge cases.\n\n**Examples:**\n- \"The error handling when payment fails due to insufficient funds\"\n- \"The optimistic locking conflict resolution in the update endpoint\"\n- \"The happy path for file upload with image resizing\""
- Header: "Describe Code Path"

## Step 5: Scan Codebase

Use the UC context (objective, preconditions, trigger, existing scenarios) to narrow the search to the specific code path.

### 5.1 Discovery

Search for files implementing the described code path:
- Grep for specific error codes, exception types, conditional branches related to the description
- Read functions, methods, and handlers that implement the path
- Trace the execution from entry point through to response/outcome

Focus on extracting a single scenario:
- **Given** — specific preconditions for this code path (state setup, feature flags, data conditions)
- **Steps** — actor and system actions through the code path
- **Outcomes** — what the user sees / receives at the end
- **Side Effects** — look for event emissions, DB writes, external API calls, logging. Also note non-side-effects (things deliberately NOT done in this path) for `And no ...` assertions

### 5.2 Present Extracted Scenario

Use AskUserQuestion to present the extracted scenario:

- Question: "Here's the scenario extracted from the codebase:\n\n**Scenario: {name}**\n\n**Given:**\n{given}\n\n**Steps:**\n{steps}\n\n**Outcomes:**\n{outcomes}\n\n**Side Effects:**\n{side_effects}\n\nDoes this look correct?\n\n_Reminder: Side effects should include both things that happen (events, DB writes) AND explicit non-side-effects (things that do NOT happen)._"
- Header: "Extracted Scenario"
- Options: "Looks good" / "Edit" (user corrects via Other)

If the user selects "Edit", collect the correction and re-present via AskUserQuestion.

### 5.3 Scenario Loop

After each scenario is confirmed, ask:

- Question: "Would you like to extract another scenario from this use case's code? (e.g., another error path, edge case, or alternative flow)"
- Header: "Extract Another?"
- Options: "Yes, I'll describe the code path" (user provides via Other) / "No, that's all"

If the user wants another, repeat Steps 5.1–5.3 for the new code path. Continue until the user says no.

## Step 6: Assign IDs

Generate scenario IDs for all confirmed scenarios. If there are N scenarios:

```bash
node ${CLAUDE_PLUGIN_ROOT}/shared/skills/id-generation/scripts/generate-id.js N
```

Prepend `SC-` to each output line (e.g., `SC-1T4B`, `SC-1T4C`).

## Step 7: Append to UC File

Edit the UC file (`prd/modules/{module}/features/FEAT-XXXX-{slug}/use-cases/UC-XXXX-{slug}.md`):

1. Append each confirmed scenario in flat structure — each preceded and followed by a `---` horizontal rule, with SC-XXXX ID, Given/Steps/Outcomes/Side Effects.
2. Increment the `version` number in the YAML frontmatter.

## Step 8: Update ARCHITECTURE.md

If `prd/modules/{module}/features/FEAT-XXXX-{slug}/ARCHITECTURE.md` exists:

1. Add Code Map entries for each new SC-XXXX linking to the implementation files discovered during scanning.
2. Add the new SC-XXXX IDs to the frontmatter `scenarios` array.
3. Update `last_update` date in frontmatter to today.
4. If the ARCHITECTURE.md doesn't have a Code Map section yet, add one using the structure from the reverse-engineering skill.

## Step 9: Report

Tell the user what was created:

- Scenarios appended inline to `prd/modules/{module}/features/FEAT-XXXX-{slug}/use-cases/UC-XXXX-{slug}.md` (list SC-XXXX IDs and names)
- ARCHITECTURE.md Code Map entries added

Suggest next steps:
- "Use `/m:reverse-scenario UC-XXXX <description>` to extract more scenarios into this UC."
- "Use `/m:reverse-plan` to generate a coverage-recovery plan when this UC needs more test coverage."
