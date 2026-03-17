---
name: usecase-authoring
description: >-
  Rules and templates for creating and updating use case files. Defines
  UC file structure with flat scenario blocks, mandatory Side Effects field
  with non-side-effects, YAML frontmatter schema, UC-NNN ID assignment,
  USE-CASES.md row management, and the creation interview pattern. Used by
  /m:usecase and /m:update-usecase.
---

# Use Case Authoring

Rules for creating and maintaining use case files: one file per UC at `prd/features/{slug}/use-cases/UC-NNN-{slug}.md`. The /m:usecase command references this skill to run the creation interview and generate the UC file. The /m:update-usecase command references it for update mode.

## When to Use

- Creating a new use case with /m:usecase
- Updating an existing use case with /m:update-usecase
- Understanding the structure and rules for UC files

## UC File Structure

Every UC file follows this exact structure. All sections are mandatory unless noted.

### 1. Title

```
# UC-NNN: {Use Case Name}
```

The name is a verb-noun goal phrase (e.g., "Create Feature", "Authenticate User").

### 2. Objective

```
> {One sentence: what the actor achieves by completing this use case.}
```

Blockquote format. One sentence only. Describes the actor's goal, not the system's behavior.

### 3. Preconditions

```
## Preconditions

- {Shared state that must exist before ANY scenario can start}
- {Actor state: authenticated, has permission, etc.}
```

Bullet list of conditions that must be true before any scenario can begin. These are shared across all scenarios and map to a Gherkin `Background` block.

### 4. Trigger

```
## Trigger

{One sentence: what the actor does or what event occurs.}
```

One sentence only. Either an actor action ("User clicks Submit") or a system event ("Cron job fires at midnight").

### 5. Gherkin Tags

```
## Gherkin Tags

`@FEAT-NNN @UC-NNN`
```

Both tags on a single line in backticks. Used by /m:stories to tag generated Gherkin scenarios.

### 6. Scenarios

Scenarios are the core of the UC file. Every scenario -- success, error, edge case -- has the same shape and the same level of detail. There is no distinction between "main" and "alternative" flows.

Each scenario is a `### SN:` heading followed by four bold-label fields. Scenarios are separated by `---` horizontal rules to give agents an unambiguous boundary signal.

```
---

### S1: {Scenario Name}

**Given:**
- {State specific to THIS scenario, beyond UC-level Preconditions}

**Steps:**
1. {Actor} {action}
2. System {validates/processes/stores/returns} {what}

**Outcomes:**
- {Entity/state that now exists or has changed}

**Side Effects:**
- `{event.name}` event published with payload `{fields}`
- No {notification/email/webhook} sent

---

### S2: {Scenario Name}

**Given:**
- {Scenario-specific state}

**Steps:**
1. {Actor} {action}
2. System {response}

**Outcomes:**
- {What is true after this scenario}

**Side Effects:**
- {Side effects for this scenario}
- No {thing that does NOT happen}
```

#### Scenario Field Rules

| Field | Format | Rules |
|-------|--------|-------|
| **Given** | Bullet list | State specific to THIS scenario only. UC-level Preconditions are not repeated here. Maps to Gherkin `Given` / `And` after Background. |
| **Steps** | Numbered list | Actor/system interaction. Each step is one action. Maps to Gherkin `When` / `And`. |
| **Outcomes** | Bullet list | What is true after this scenario completes. Maps to Gherkin `Then` clauses. |
| **Side Effects** | Bullet list | Events, DB writes, and explicit non-side-effects. Maps to Gherkin `And` / `And no` clauses. |

#### Scenario Naming

- The first scenario (S1) is typically the success case, but structurally it is identical to every other scenario.
- Scenario names should be descriptive and unique within the UC (e.g., "Valid credentials", "Expired token", "Missing required field").
- Number scenarios sequentially: S1, S2, S3, etc.

#### Scenario Separators

Every scenario block is preceded and followed by a `---` horizontal rule. This includes before S1 (after the Gherkin Tags section) and after the last scenario.

#### Step Verb Conventions

- **Actor verbs:** provides, selects, confirms, submits, clicks, enters, uploads
- **System verbs:** validates, processes, stores, returns, displays, creates, publishes, sends

Each step is one action. Do not combine multiple actions in one step.

## Side Effects Rules

Side Effects is the most critical field for downstream agents. The Tester agent maps side effects to Gherkin `And` clauses and non-side-effects to `And no ...` clauses. Missing or vague side effects produce incomplete test coverage.

### Three Categories

**Events:**
```
- `{domain}.{entity}.{verb}` event published with payload `{field1, field2}`
```

**Database writes:**
```
- `{table}` table: {row created/updated/deleted} with {key fields}
```

**Non-side-effects (explicit):**
```
- No {notification/email/webhook/event} sent
```

### Rules

- Every scenario must have at least one side effect or at least one non-side-effect. A scenario that changes nothing is not a scenario.
- Non-side-effects start with "No" and name the thing that does NOT happen.
- Non-side-effects are just as important as side effects -- they tell the Tester agent what to assert does NOT occur.
- Event names follow `{domain}.{entity}.{verb}` convention (e.g., `auth.session.created`, `billing.invoice.sent`).
- Payload fields are listed in backtick-wrapped comma-separated format.

## Gherkin Mapping

This table defines how UC elements map to Gherkin output for the Tester agent.

| UC Element | Gherkin Output |
|------------|----------------|
| UC `Preconditions` | `Background: Given ...` |
| UC `Gherkin Tags` | `@FEAT-NNN @UC-NNN` on Feature line |
| Scenario `Given` | Additional `Given` / `And` after Background |
| Scenario `Steps` | `When` / `And` clauses |
| Scenario `Outcomes` | `Then` clauses |
| Scenario `Side Effects` (positive) | `And` clauses |
| Scenario `Side Effects` ("No ...") | `And no ...` clauses |

## YAML Frontmatter Schema

| Field | Type | Rules |
|-------|------|-------|
| `id` | string | `UC-NNN` -- assigned ID within the feature |
| `name` | string | Verb-noun goal phrase (e.g., "Create Feature") |
| `feature` | string | Parent feature ID: `FEAT-NNN-slug` |
| `status` | enum | `backlog` when first created. Lifecycle: backlog, scoped, specified, building, live, dirty, deprecated |
| `version` | integer | Starts at `1`. Incremented by /m:update-usecase on each edit |
| `actor` | string | Primary actor role (must exist in prd/ACTORS.md) |
| `tag` | string | `@UC-NNN` -- used for Gherkin scenario filtering |

## UC-NNN ID Assignment

When creating a new use case, assign the next sequential ID within the feature's USE-CASES.md.

**How to determine the next ID:**
1. Read the feature's `USE-CASES.md`
2. Find the last row in the table
3. Extract the numeric portion of its ID (e.g., `UC-003` -> 3)
4. Increment by 1 and zero-pad to 3 digits (e.g., -> `004`)
5. Result: `UC-004`

**Slug rules:**
- Lowercase, hyphens (not underscores)
- Derived from the use case name (e.g., "Create Feature" -> `create-feature`)
- Max 30 characters
- No special characters except hyphens

**If USE-CASES.md has no rows** (empty table): start at UC-001.

**IDs are permanent.** Once assigned, a UC-NNN ID is never reused, even if the use case is deprecated.

**Filename format:** `UC-NNN-{slug}.md` (e.g., `UC-001-create-feature.md`)

## USE-CASES.md Row Management

When creating a use case, add a new row to the feature's `USE-CASES.md`:

```
| UC-NNN | {Use Case Name} | {One-sentence description} | backlog | [UC-NNN-{slug}.md](use-cases/UC-NNN-{slug}.md) |
```

**Column rules:**
- **ID:** `UC-NNN` -- the assigned ID
- **Name:** Verb-noun goal phrase (matches frontmatter `name`)
- **Description:** One sentence -- enough for an agent to identify this use case
- **Status:** Always `backlog` when first created
- **File:** Relative Markdown link to `use-cases/UC-NNN-{slug}.md`

**When updating a use case,** do NOT change the ID. Update Status only when the use case advances through its lifecycle.

## Creation Interview

**All user interaction MUST use the AskUserQuestion tool.** Never ask questions as plain text. This keeps the agent in control of the flow throughout the interview.

The creation interview extracts structured content from the user's freeform input and presents it section-by-section for review. Files are only written after all sections are confirmed.

### Step 1: Extract from Input

From the user's freeform input, attempt to extract:
- Use case name (verb-noun goal)
- Primary actor
- Preconditions
- Trigger
- Scenarios (each with Given, Steps, Outcomes, Side Effects)

Cross-reference `prd/ACTORS.md` to validate the actor exists.

### Step 2: Review Shared Context

For each shared section, use AskUserQuestion to present what was extracted and ask for confirmation.

Present shared context in this order:
1. Use case name
2. Primary actor
3. Preconditions
4. Trigger

**If the input covered the section:**
"For {section name}, this is what I extracted:\n\n{content}\n\nDoes this look correct?"
- Options: "Yes, looks good" / "Edit" (user provides corrections via Other)

**If the input did NOT cover the section:**
"I didn't find any {section name} in your description. Can you provide them?"
- Options: "Yes, I'll add them" (user provides via Other) / "Skip for now"

### Step 3: Review Scenarios

For each scenario extracted from the input, present the full scenario block (Given, Steps, Outcomes, Side Effects) and ask for confirmation.

"Here is Scenario {N}: {Name}\n\n**Given:**\n{given}\n\n**Steps:**\n{steps}\n\n**Outcomes:**\n{outcomes}\n\n**Side Effects:**\n{side_effects}\n\nDoes this look correct?"
- Options: "Yes, looks good" / "Edit" (user provides corrections via Other)

For the **Side Effects** field specifically, always remind the user:
"Include both side effects (events published, DB writes) AND explicit non-side-effects (things that do NOT happen). Non-side-effects become 'And no ...' assertions in Gherkin tests."

After reviewing all extracted scenarios, ask:
"Would you like to add another scenario?"
- Options: "Yes" (user describes the scenario via Other) / "No, that's all"

Repeat the scenario review loop until the user confirms they have no more scenarios.

### Step 4: Write Files

After all sections are confirmed:
1. Assign UC-NNN ID (next available from the feature's USE-CASES.md)
2. Derive slug from use case name
3. Create `prd/features/{feature-slug}/use-cases/` directory if it does not exist
4. Write `UC-NNN-{slug}.md` using [UC-template.md](./templates/UC-template.md) -- fill all sections with confirmed content, set frontmatter status to `backlog`, version to `1`
5. Add row to the feature's `USE-CASES.md`

## Update Mode

/m:update-usecase uses this skill in update mode:
- Read the current UC file
- Compare with the user's change description
- Propose specific changes via AskUserQuestion ("Here's what I'd change:\n\n{diff}\n\nDoes this look correct?")
- Apply after confirmation
- Increment `version` in frontmatter
- Set `status` to `dirty` in frontmatter
- Update the status column in USE-CASES.md
- Do NOT run the creation interview
- Do NOT change the UC-NNN ID or tag

## Template Reference

| Template | Purpose |
|----------|---------|
| [UC-template.md](./templates/UC-template.md) | UC file for each use case |
