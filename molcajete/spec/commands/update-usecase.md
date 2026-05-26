---
description: Update an existing use case (spec only)
model: claude-opus-4-6
argument-hint: <UC-XXXX> <change description>
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

# Update Use Case

You are updating an existing use case based on a change description. You will load the current spec, propose specific changes, apply after confirmation, and bump the version.

**Input:** $ARGUMENTS

**All user interaction MUST use the AskUserQuestion tool.** Never ask questions as plain text in your response.

## Step 1: Load Skill

Read the skill that governs this command:

1. Read `${CLAUDE_PLUGIN_ROOT}/spec/skills/usecase-authoring/SKILL.md` -- update mode rules, flat inline scenario structure, Side Effects conventions

Follow the skill's Update Mode rules: propose specific changes, do NOT run the creation interview, do NOT change the UC ID.

## Step 2: Parse Arguments

Parse `$ARGUMENTS` into two parts:

1. **Use case ID** -- the first token, expected format `UC-XXXX`
2. **Change description** -- everything after the use case ID

If `$ARGUMENTS` is empty or does not start with a `UC-` token, tell the user:

"Usage: `/m:update-usecase UC-XXXX <change description>`. Provide a valid use case ID and describe what to change."

Then stop.

If the change description is empty (only a UC ID was provided), use AskUserQuestion:
- Question: "What changes do you want to make to {UC-XXXX}? Describe what should be added, removed, or modified in the use case."
- Header: "Change Description"

## Step 3: Verify Use Case Exists

1. Glob `prd/modules/*/features/*/use-cases/UC-XXXX-*.md` (substituting the actual ID) to find the UC file. If not found, tell the user:

   "Use case {UC-XXXX} not found. Check the ID and try again."

   Then stop.

2. Extract the parent `FEAT-XXXX` from the path (the directory name under `features/`) and the module from the path (the directory name under `prd/modules/`).

3. Verify `prd/FEATURES.md` exists. If missing, tell the user:

   "Run `/m:setup` first -- DOMAINS.md and FEATURES.md are required."

   Then stop.

4. Verify FEAT-XXXX exists in `prd/FEATURES.md`. If not found, tell the user:

   "Feature {FEAT-XXXX} not found in FEATURES.md. Check the ID and try again."

   Then stop.

## Step 4: Load Context

Read these files to understand the current state:

- `prd/PROJECT.md` -- project description
- `prd/TECH-STACK.md` -- technology choices (if exists)
- `prd/ACTORS.md` -- known actors (if exists)
- `prd/modules/{module}/features/FEAT-XXXX-{slug}/REQUIREMENTS.md` -- feature requirements
- `prd/modules/{module}/features/FEAT-XXXX-{slug}/ARCHITECTURE.md` -- architecture context (if exists)
- `prd/modules/{module}/features/FEAT-XXXX-{slug}/use-cases/UC-XXXX-{slug}.md` -- the target use case
- `prd/modules/{module}/features/FEAT-XXXX-{slug}/USE-CASES.md` -- use case index

## Step 5: Analyze and Propose Changes

Compare the change description against the current UC file content.

Determine what sections need to change:
- Objective
- Preconditions
- Trigger
- Existing scenarios (Given, Steps, Outcomes, Side Effects)
- New scenarios to add

Use AskUserQuestion to present the proposed changes:
- Question: "Here's what I'd change in **{UC-XXXX}**:\n\n{describe each change -- what's added, modified, or removed, showing before/after for modifications}\n\nDoes this look correct?"
- Header: "Proposed Changes"
- Options: "Yes, apply these changes" / "Edit" (user corrects via Other)

If the user wants edits, revise the proposal and present again via AskUserQuestion.

## Step 6: Apply Spec Changes

Apply the confirmed changes to the UC file:

1. Edit `prd/modules/{module}/features/FEAT-XXXX-{slug}/use-cases/UC-XXXX-{slug}.md` with the confirmed changes.

2. Increment the `version` field in the YAML frontmatter.

3. Do NOT change the UC-XXXX ID.

4. If new scenarios were added, generate SC IDs for them:

```bash
node ${CLAUDE_PLUGIN_ROOT}/shared/skills/id-generation/scripts/generate-id.js N
```

Prepend `SC-` to each output line.

## Step 7: Testability Notes

After applying changes, scan the updated scenarios for new testability signals per the usecase-authoring skill's E2E Testing Philosophy:

- If new or changed scenarios reference external APIs, time-dependent logic, feature flags, or other E2E concern patterns, include them in the report
- Do NOT create a recommendations file on the Specs First path
- Do NOT use AskUserQuestion for testability concerns

## Step 8: Report

Tell the user what changed:

- List each spec file that was modified and summarize the changes
- Note the version bump (e.g., "version: 1 -> 2")
- If testability signals were detected in Step 7, include a **Testability Notes** block listing each concern with its category. Note: "Record any testing decisions in `ARCHITECTURE.md` under `## Testing Decisions`."
