---
description: Create a new feature with EARS requirements via creation interview
model: claude-opus-4-6
allowed-tools:
  - Read
  - Write
  - Edit
  - Glob
  - Grep
  - Bash
  - Agent
  - AskUserQuestion
argument-hint: <freeform feature description>
---

# Create Feature

You are creating a new feature. You will extract structured content from the user's freeform input, convert requirements to EARS syntax, present each section for review, and generate all feature documents.

**Feature input:** $ARGUMENTS

**All user interaction MUST use the AskUserQuestion tool.** Never ask questions as plain text in your response.

## Step 1: Load Skill

Read the feature-authoring skill for EARS syntax rules, Fit Criteria format, creation interview pattern, and template references:

```
Read: ${CLAUDE_PLUGIN_ROOT}/plan/skills/feature-authoring/SKILL.md
```

Follow the skill's rules for all subsequent steps.

## Step 2: Verify Prerequisites

Check that `prd/PROJECT.md` and `prd/FEATURES.md` exist. If either is missing, tell the user:

"Run `/msetup` first -- PROJECT.md and FEATURES.md are required before creating features."

Then stop.

## Step 3: Load Project Context

Read these files to understand the project:
- `prd/PROJECT.md` -- what this project is
- `prd/TECH-STACK.md` -- technology context (if exists)
- `prd/ACTORS.md` -- known actors (if exists)
- `prd/SCHEMA.md` -- database schema (if exists)
- `prd/FEATURES.md` -- existing features (to assign next ID and avoid duplicates)

## Step 4: Extract from Input

If `$ARGUMENTS` is provided, analyze the freeform text and extract as much as possible:

- **Feature name** -- a short 3-5 word name
- **Non-goals** -- what this feature does NOT do
- **Actors** -- who uses this feature (cross-reference with prd/ACTORS.md)
- **UI** -- any mockups, layout descriptions, or image file paths
- **Functional requirements** -- convert to EARS syntax (When/While/If-Then patterns); add a Fit Criterion to each
- **Non-functional requirements** -- performance, security, reliability (also in EARS)
- **Acceptance criteria** -- how we know the feature is done

If `$ARGUMENTS` is empty, use AskUserQuestion to ask: "Describe the feature you want to create. Include what it does, who uses it, and any requirements you already know."

## Step 5: Creation Interview

Present each section for review via AskUserQuestion, following the feature-authoring skill's Creation Interview rules. Process sections in this order:

### 5.1 Feature Name

Use AskUserQuestion:
- Question: "Feature name: **{extracted name}**\n\nDoes this look correct?"
- Header: "Name"
- Options: "Yes, looks good" / "Edit" (user corrects via Other)

### 5.2 Non-Goals

**If extracted from input:**
Use AskUserQuestion:
- Question: "Non-goals for this feature:\n\n{list}\n\nDo these look correct? Add or remove any."
- Header: "Non-Goals"
- Options: "Yes, looks good" / "Edit"

**If NOT found in input:**
Use AskUserQuestion:
- Question: "What should this feature explicitly NOT do? Non-goals help agents avoid building things you don't want."
- Header: "Non-Goals"
- Options: "I'll list some" (user provides via Other) / "No non-goals for now"

### 5.3 Actors

**If extracted from input** (cross-referenced with ACTORS.md):
Use AskUserQuestion to confirm the actor list.

**If NOT found:**
Use AskUserQuestion:
- Question: "Which actors interact with this feature? Here are the known actors from ACTORS.md:\n\n{actor list}\n\nWhich ones are relevant? Are there new ones?"
- Header: "Actors"

### 5.4 UI

**If UI content was extracted from input** (layout descriptions, mockups, image references):
Use AskUserQuestion:
- Question: "UI for this feature:\n\n{extracted content}\n\nDoes this look correct? You can also provide image file paths."
- Header: "UI"
- Options: "Yes, looks good" / "Edit"

**If NOT found in input:**
Use AskUserQuestion:
- Question: "Does this feature have a user interface? You can describe it and I'll generate ASCII art mockups, or provide image file paths."
- Header: "UI"
- Options: "I'll describe the UI" (user provides via Other) / "No UI -- skip"

If the user says "No UI -- skip", omit the `## UI` section entirely from requirements.md.

If the user describes the UI, generate ASCII art mockups from their description showing layout, key elements, and hierarchy. Use fenced code blocks. Present the mockup for confirmation before proceeding.

If the user provides image file paths, note them for Step 7 (file generation).

### 5.5 Functional Requirements

Present the extracted FRs in EARS syntax with Fit Criteria:

Use AskUserQuestion:
- Question: "Functional requirements (EARS syntax):\n\n{FR list with Fit Criteria}\n\nDo these look correct? Add, remove, or modify any."
- Header: "FRs"
- Options: "Yes, looks good" / "Edit"

**If no FRs were extracted:**
Use AskUserQuestion:
- Question: "What should this feature do? I'll convert your description into EARS-syntax requirements."
- Header: "FRs"

### 5.6 Non-Functional Requirements

Use AskUserQuestion:
- Question: "Non-functional requirements:\n\n{NFR list, or 'None extracted'}\n\nAny performance, security, or reliability requirements?"
- Header: "NFRs"
- Options: "Yes, looks good" / "I'll add some" (user provides via Other) / "No NFRs for now"

### 5.7 Acceptance Criteria

Use AskUserQuestion:
- Question: "Acceptance criteria:\n\n{extracted criteria, or default set from skill}\n\nDo these look correct?"
- Header: "Acceptance"
- Options: "Yes, looks good" / "Edit"

## Step 6: Assign Feature ID

Read `prd/FEATURES.md` and determine the next available FEAT-NNN number:
1. Find the last row in the Features table
2. Extract the numeric portion (e.g., FEAT-003 -> 3)
3. Increment by 1 and zero-pad to 3 digits
4. Create the slug from the confirmed feature name (lowercase, hyphens)
5. Full ID: `FEAT-{NNN}-{slug}`

If FEATURES.md has no rows, start at FEAT-001.

## Step 7: Generate Documents

Read templates and generate all files:

1. Create directory `prd/features/{slug}/` and `prd/features/{slug}/use-cases/`
   If UI content includes image file paths, also create `prd/features/{slug}/assets/`
   Copy any user-provided image files to `prd/features/{slug}/assets/` using descriptive names (lowercase, hyphens)

2. Read `${CLAUDE_PLUGIN_ROOT}/plan/skills/feature-authoring/templates/REQUIREMENTS-template.md`
   Write `prd/features/{slug}/requirements.md` with:
   - YAML frontmatter: id, name, status (scoped), version (1)
   - Non-Goals as second section
   - Actors table
   - If UI content was confirmed: `## UI` section with ASCII art mockups and/or image references (`![description](assets/filename.png)`)
   - If no UI content: omit `## UI` section entirely
   - FRs in EARS syntax with Fit Criteria and "Linked to:" placeholders
   - NFRs in EARS syntax
   - Acceptance criteria checkboxes

3. Read `${CLAUDE_PLUGIN_ROOT}/plan/skills/feature-authoring/templates/USE-CASES-template.md`
   Write `prd/features/{slug}/USE-CASES.md` with empty table (rows added by /musecase)

4. Read `${CLAUDE_PLUGIN_ROOT}/plan/skills/feature-authoring/templates/ARCHITECTURE-template.md`
   Write `prd/features/{slug}/architecture.md` as a scaffold with placeholder diagrams

5. Add a new row to `prd/FEATURES.md` (format from the feature-authoring skill's Row Management section):
   ```
   | FEAT-NNN-slug | {Feature Name} | {One-sentence description} | scoped | @FEAT-NNN | [features/{slug}/](features/{slug}/) |
   ```

## Step 8: Report

Tell the user what was created:

- `prd/features/{slug}/requirements.md` -- EARS requirements with Fit Criteria
- `prd/features/{slug}/USE-CASES.md` -- empty use case index
- `prd/features/{slug}/architecture.md` -- architecture scaffold
- `prd/FEATURES.md` -- updated with new row (FEAT-NNN-slug, status: scoped)

Suggest next steps: "Use `/musecase FEAT-NNN {description}` to add use cases to this feature."
