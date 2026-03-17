---
name: feature-authoring
description: >-
  Rules and templates for creating and updating feature documents. Defines
  EARS syntax patterns, Fit Criteria, Non-Goals positioning, FEAT-NNN-slug
  ID assignment, FEATURES.md row management, and the creation interview
  pattern. Used by /m:feature and /m:update-feature.
---

# Feature Authoring

Rules for creating and maintaining feature documents: requirements.md, USE-CASES.md, and architecture.md scaffold. The /m:feature command references this skill to run the creation interview and generate all feature artifacts. The /m:update-feature command references it for update mode.

## When to Use

- Creating a new feature with /m:feature
- Updating an existing feature's requirements with /m:update-feature
- Understanding the structure and rules for requirements.md, USE-CASES.md, and architecture.md

## EARS Syntax

All functional requirements MUST be written in EARS (Easy Approach to Requirements Syntax). Each sentence has a mandatory keyword and maps directly to a Gherkin `When/While/If-Then` clause.

| Pattern | Keyword | Template | Use for |
|---------|---------|----------|---------|
| Event-driven | When | `When {trigger}, the system shall {response}.` | User actions, API calls, data events |
| State-driven | While | `While {precondition}, the system shall {response}.` | Conditions that must hold |
| Unwanted behavior | If/Then | `If {trigger}, then the system shall {response}.` | Failure modes, error states |
| Always-on | (none) | `The system shall {response}.` | Invariant behavior |
| Complex | When+While | `While {state}, when {trigger}, the system shall {response}.` | Combined conditions |

**Rules:**
- Never write requirements as prose ("The system should be fast")
- Always use the pattern keyword exactly: "When", "While", "If ... then"
- Each sentence expresses one requirement — no "and" chaining
- Requirements must be falsifiable: a test must be able to pass or fail it

## Fit Criteria

Every functional requirement must include a Fit Criterion immediately after it. The Fit Criterion is the measurable condition that proves the requirement is satisfied.

**Format:**
```
**FR-001** `When {trigger}, the system shall {response}.`
Fit Criterion: Given {precondition}, {measurable outcome that proves this is satisfied}.
Linked to: UC-NNN
```

**Rules:**
- Fit Criteria use "Given ... {measurable outcome}" format
- The outcome must be verifiable (a test can check it)
- "The system should feel fast" is not a Fit Criterion
- "Given 100 concurrent users, response time is < 200ms at p95" is a Fit Criterion
- Every FR requires one Fit Criterion — no exceptions

## Non-Goals Positioning

The Non-Goals section MUST appear second in requirements.md — immediately after the one-sentence objective, before Actors, before Functional Requirements.

**Why:** LLMs process documents top-to-bottom. Scope boundaries read late are scope boundaries partially ignored. An agent that sees Non-Goals at position 2 will respect them throughout. An agent that sees them at position 8 may already have invented out-of-scope implementations.

**Required order:**
1. Feature name + one-sentence objective (blockquote)
2. ## Non-Goals
3. ## Actors
4. ## UI (optional -- omit if no user interface)
5. ## Functional Requirements
6. ## Non-Functional Requirements
7. ## Acceptance

Non-Goals entries are bullet points starting with "Does not":
```
- Does not handle {X}
- Does not replace {Y}
- Does not support {Z} -- see FEAT-NNN-slug for that
```

## UI Section

The UI section is optional. It appears at position 4 in requirements.md (after Actors, before Functional Requirements). It provides visual context that informs the reading of requirements that follow. Omit it entirely for features with no user interface.

### Content Types

UI sections support two content types, which can be mixed:

**ASCII art mockups** (default) -- fenced code blocks showing layout:

```
+-------------------+
| Header            |
+-------------------+
| [Search...      ] |
| +------+ +------+ |
| | Card | | Card | |
| +------+ +------+ |
+-------------------+
```

ASCII art conveys layout and element hierarchy. It is always the default -- generate it from the user's description of the feature.

**Image references** -- standard Markdown images pointing to files in `assets/`:

```
![Dashboard overview](assets/overview-dashboard.png)
```

Images are a post-creation enhancement. The `assets/` directory is created inside the feature directory after the feature directory exists. When the user provides image files (file paths), copy them to `prd/features/{slug}/assets/` with descriptive names and reference them in the `## UI` section.

### Asset Management

- Feature-level images go in `prd/features/{slug}/assets/`
- File naming: `{descriptive-slug}.{ext}` -- lowercase, hyphens, no spaces, max 50 character slug
- Supported formats: PNG, JPG
- When the user provides image file paths during creation or update, copy the files and add references

### When to Include

Include the `## UI` section when:
- The feature has screens, forms, or visual interactions
- The user provides mockups, screenshots, or wireframes
- The user describes UI layout in their feature description

Omit the `## UI` section when:
- The feature is pure backend, API-only, or infrastructure
- The user explicitly says no UI

## FEAT-NNN-slug ID Assignment

When creating a new feature, assign the next sequential ID from FEATURES.md.

**How to determine the next ID:**
1. Read `prd/FEATURES.md`
2. Find the last row in the Features table
3. Extract the numeric portion of its ID (e.g., `FEAT-003-...` → 3)
4. Increment by 1 and zero-pad to 3 digits (e.g., → `004`)
5. Append the feature slug: `FEAT-004-{slug}`

**Slug rules:**
- Lowercase, hyphens (not underscores)
- Derived from the feature name (e.g., "User Authentication" → `user-authentication`)
- Max 30 characters
- No special characters except hyphens

**If FEATURES.md is empty** (no rows yet): start at FEAT-001.

**IDs are permanent.** Once assigned, a FEAT-NNN-slug ID is never reused or deleted, even if the feature is deprecated.

## FEATURES.md Row Management

When creating a feature, add a new row to `prd/FEATURES.md`:

```
| FEAT-NNN-slug | {Feature Name} | {One-sentence description} | scoped | @FEAT-NNN | [features/{slug}/](features/{slug}/) |
```

**Column rules:**
- **ID:** `FEAT-NNN-slug` — the assigned ID
- **Feature:** Short name (3-5 words)
- **Description:** One sentence — enough for an agent to decide if this is the right feature
- **Status:** Always `scoped` when first created
- **Tag:** `@FEAT-NNN` (the number from the ID) — used as Gherkin feature tag
- **Directory:** Relative Markdown link to `prd/features/{slug}/`

**When updating a feature,** do NOT change the ID or Tag. Update Status only when the feature advances through its lifecycle.

## Creation Interview

**All user interaction MUST use the AskUserQuestion tool.** Never ask questions as plain text. This keeps the agent in control of the flow throughout the interview.

The creation interview extracts structured content from the user's freeform input and presents it section-by-section for review. Files are only written after all sections are confirmed.

### Step 1: Extract from Input

From the user's freeform input, attempt to extract:
- Feature name
- Non-goals (what this feature does NOT do)
- Actors (who uses this feature)
- UI (any mockups, layout descriptions, or image file paths)
- Functional requirements (what the feature does)
- Non-functional requirements (performance, security, reliability)
- Acceptance criteria (how we know it's done)

Convert all extracted FRs to EARS syntax and add Fit Criteria before presenting.

### Step 2: Review Section by Section

For each section, use AskUserQuestion to present what was extracted and ask for confirmation:

**If the input covered the section:**
"For {section name}, this is what I extracted:\n\n{content}\n\nDoes this look correct?"
- Options: "Yes, looks good" / "Edit" (user provides corrections via Other)

**If the input did NOT cover the section:**
"I didn't find any {section name} in your description. Do you have any?"
- Options: "Yes, I'll add them" (user provides via Other) / "No, skip this section"

Present sections in this order:
1. Feature name
2. Non-goals
3. Actors
4. UI (optional -- see UI Section rules above)
5. Functional requirements (shown in EARS syntax with Fit Criteria)
6. Non-functional requirements
7. Acceptance criteria

For the UI step specifically:

**If UI content was extracted from input** (layout descriptions, mockups, image references):
"UI for this feature:\n\n{extracted content}\n\nDoes this look correct?"
- Options: "Yes, looks good" / "Edit" (user provides corrections via Other)

**If UI content was NOT found in input:**
"Does this feature have a user interface? You can describe it and I'll generate ASCII art mockups, or you can provide image file paths."
- Options: "I'll describe the UI" (user provides via Other) / "No UI -- skip"

If the user says "No UI -- skip", do not include the `## UI` section in requirements.md.

If the user describes the UI, generate ASCII art mockups from their description showing layout, key elements, and hierarchy. Use fenced code blocks.

### Step 3: Write Files

After all sections are confirmed:
1. Assign FEAT-NNN-slug ID (next available from FEATURES.md)
2. Create `prd/features/{slug}/` directory and `prd/features/{slug}/use-cases/`
3. If the user provided image file paths, create `prd/features/{slug}/assets/` and copy image files with descriptive names
4. Write `requirements.md` using [REQUIREMENTS-template.md](./templates/REQUIREMENTS-template.md) -- include `## UI` section with confirmed ASCII art and/or image references if UI content was provided; omit `## UI` section entirely if user said no UI
5. Write `USE-CASES.md` using [USE-CASES-template.md](./templates/USE-CASES-template.md) (empty table)
6. Write `architecture.md` scaffold using [ARCHITECTURE-template.md](./templates/ARCHITECTURE-template.md)
6. Add row to `prd/FEATURES.md` (format from the Row Management section above)

## Update Mode

/m:update-feature uses this skill in update mode:
- Read the current `requirements.md` and `architecture.md`
- Compare with the user's change description
- Propose specific changes via AskUserQuestion ("Here's what I'd change: ... Does this look correct?")
- Apply after confirmation
- Do NOT run the creation interview
- Do NOT change the feature's lifecycle status

## Template Reference

| Template | Purpose |
|----------|---------|
| [REQUIREMENTS-template.md](./templates/REQUIREMENTS-template.md) | requirements.md for each feature |
| [USE-CASES-template.md](./templates/USE-CASES-template.md) | USE-CASES.md index for each feature |
| [ARCHITECTURE-template.md](./templates/ARCHITECTURE-template.md) | architecture.md scaffold for each feature |
