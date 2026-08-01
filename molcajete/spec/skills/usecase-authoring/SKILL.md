---
name: usecase-authoring
description: >-
  Rules and templates for creating and updating use case files. Defines
  UC file structure with flat inline scenario blocks, mandatory Side Effects
  field with non-side-effects, YAML frontmatter schema, UC-XXXX ID
  assignment, USE-CASES.md row management, and the creation interview
  pattern.
---

# Use Case Authoring

Rules for creating and maintaining use case files: each UC is two artifacts at the feature level. The UC spec lives at `specs/features/{module}/FEAT-XXXX-{slug}/UC-XXXX-{slug}.md` (sibling of REQUIREMENTS.md / USE-CASES.md / ARCHITECTURE.md). A support folder `UC-XXXX-{slug}/` (sibling of the spec file) holds `CHANGELOG.md`. The /m:spec command references this skill to run the creation interview and generate the UC file. Scenarios live **inline** in the UC file using a flat `### SC-XXXX:` heading structure separated by `---` rules.


## Module-Scoped Use Cases

When a feature exists in 2+ modules, the same use case can appear in every module the capability touches. **All module-instances of the same use case share one UC-XXXX ID**, generated once and reused. Contents are module-scoped: each module gets its own `UC-XXXX-{slug}.md` whose name, slug, actor, trigger, preconditions, scenarios, and side effects narrate from that module's perspective. This mirrors multi-module features (one `FEAT-XXXX` across module folders, module-scoped `REQUIREMENTS.md` in each).

**Rules:**
- **ID reuse:** Generate the UC-XXXX code once via `node ${CLAUDE_PLUGIN_ROOT}/shared/skills/id-generation/scripts/generate-id.js` and reuse it for every module-instance. Do **not** generate a fresh ID per module.
- **Naming:** Use module-specific verb-noun goals for the frontmatter `name:` and the `# UC-XXXX: {name}` heading. "Submit Registration" (patient) vs. "Review Registration" (console), not "Handle Registration" in both. The slug derives from the module-scoped name, so it differs too.
- **Actor selection:** Use each module's primary actor, not a generic "User". A `patient` module UC uses "Patient"; a `console` module UC uses "Administrator".
- **Trigger and preconditions:** Describe the trigger as each module's actor experiences it. The same business event has different triggers per module (patient submits form vs. administrator reviews submission).
- **Scenarios:** Scope Steps, Outcomes, and Side Effects to the module boundary. A patient module scenario ends when the patient sees confirmation. A console module scenario begins when the admin sees the pending item.
- **Never copy identical content across module-instances.**

**Cross-module interaction pattern:** Steps stay within the originating module's boundary — the actor acts in their module. Cross-module consequences belong in **Side Effects**, where they name the event or artifact delivered to the other module. The consuming module's UC-instance (same UC-XXXX ID) is triggered by that event.

Example — the shared UC-XXXX for a Registration flow, seen from both modules:

**Patient module** — `specs/features/patient/FEAT-0Fy0-user-onboarding/UC-0KTg-submit-registration.md`

| Field | Content |
|-------|---------|
| Name | Submit Registration |
| Actor | Patient |
| Steps | 1. Patient fills in the registration form 2. System validates input |
| Outcomes | Patient sees "Registration submitted for review" confirmation |
| Side Effects | `registration.submitted` event published with payload `patient_id, timestamp` |

**Console module** — `specs/features/console/FEAT-0Fy0-user-onboarding/UC-0KTg-review-registration.md`

| Field | Content |
|-------|---------|
| Name | Review Registration |
| Actor | Administrator |
| Trigger | Administrator opens the pending registrations queue |
| Steps | 1. Administrator selects a pending registration 2. System displays patient details |
| Outcomes | Administrator sees the registration and can approve or reject it |
| Side Effects | `registration.reviewed` event published with payload `patient_id, admin_id, decision, timestamp` |

Same `UC-0KTg`. Two files. Two names. Two slugs. Module-scoped everything else.

**Single-module features are unaffected.** This section applies only when a UC exists in 2+ module-instances. In single-module projects (or a single-module feature within a multi-module project) there is one UC file, no fan-out, and no shared-ID considerations.

## UC File Structure

Every UC file follows this exact structure. All sections are mandatory unless noted.

### 1. Title

```
# UC-XXXX: {Use Case Name}
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

Bullet list of conditions that must be true before any scenario can begin. These are shared across all scenarios.

### 4. Trigger

```
## Trigger

{One sentence: what the actor does or what event occurs.}
```

One sentence only. Either an actor action ("User clicks Submit") or a system event ("Cron job fires at midnight").

### 5. Scenarios

Scenarios are the core of the UC file. Every scenario -- success, error, edge case -- has the same shape and the same level of detail. There is no distinction between "main" and "alternative" flows.

Each scenario is a `### SC-XXXX:` heading followed by four bold-label fields. Scenarios are separated by `---` horizontal rules to give agents an unambiguous boundary signal. Each scenario gets a unique `SC-XXXX` ID. Generate codes by running `node ${CLAUDE_PLUGIN_ROOT}/shared/skills/id-generation/scripts/generate-id.js [count]` (use the count arg for multiple scenarios) and prepend `SC-` to each output line.

```
---

### SC-XXXX: {Scenario Name}

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

### SC-XXXX: {Scenario Name}

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
| **Given** | Bullet list | State specific to THIS scenario only. UC-level Preconditions are not repeated here. |
| **Steps** | Numbered list | Actor/system interaction. Each step is one action. |
| **UI** (optional) | Fenced code block (ASCII art) or Markdown image reference | Inline within Steps. Shows screen state after a step that produces a visual change. Omit for non-visual scenarios. |
| **Outcomes** | Bullet list | What is true after this scenario completes — what the actor observes. |
| **Side Effects** | Bullet list | Events, DB writes, outgoing calls, and explicit non-side-effects. These are the test's assertion targets when the build loop writes tests for this scenario. |

#### Scenario Naming

- Scenario names should be descriptive and unique within the UC (e.g., "Valid credentials", "Expired token", "Missing required field").
- Names should describe the actor's situation or outcome, not internal system behavior. Use "Valid credentials" or "Expired link shown", not "JWT validated" or "Session row created".

#### Scenario Separators

Every scenario block is preceded and followed by a `---` horizontal rule. This includes before the first scenario (after the Trigger section) and after the last scenario.

#### Step Verb Conventions

- **Actor verbs:** provides, selects, confirms, submits, clicks, enters, uploads
- **System verbs:** validates, processes, stores, returns, displays, creates, publishes, sends

Each step is one action. Do not combine multiple actions in one step.

#### Inline UI

Scenarios that involve screens or visual interactions can include optional `**UI:**` blocks within the Steps section. A UI block shows the screen state the actor sees after a particular step.

**Position:** Indented under the step number that produces the visual change, before the next step. The `**UI:**` label is followed by a fenced code block (ASCII art) or an image reference.

```
**Steps:**
1. Actor submits the form
2. System displays the confirmation screen

   **UI:**
   ```
   +----------------------------------+
   | Confirmation                     |
   |----------------------------------|
   | Your changes have been saved.    |
   |                                  |
   | [ Back to Dashboard ]            |
   +----------------------------------+
   ```

3. Actor clicks "Back to Dashboard"
```

**Content types:**

- **ASCII art mockups** (default) -- fenced code blocks showing layout, key elements, and hierarchy. Generate from the user's description.
- **Image references** -- Markdown images pointing to the UC's own `assets/` folder:
  ```
  ![Confirmation screen](assets/UC-XXXX-confirmation.png)
  ```

**Asset management:**

- UC-level images go in `specs/features/{module}/FEAT-XXXX-{slug}/UC-XXXX-{slug}/assets/` (inside the UC's support folder)
- File naming: `{UC-ID}-{descriptive-slug}.{ext}` (e.g., `UC-A1B2-login-form.png`)
- Lowercase, hyphens, no spaces
- Supported formats: PNG, JPG
- Create the UC's `assets/` directory only when images are needed

Include a UI block when the step produces a visible change the actor responds to, or when the user supplies mockups, screenshots, or screen-state descriptions. Omit it for backend-only or error-only scenarios and whenever the user says there is no UI. A UC file can have UI blocks in some scenarios and none in others. Do not add empty UI placeholders.

## Side Effects Rules

Side Effects is the most critical field for the build loop. The Implementer subagent uses side effects as the assertion targets when writing tests for this scenario — they correspond to the Five Exit Doors in `shared/skills/testing/SKILL.md`. Missing or vague side effects produce incomplete test coverage.

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
- Non-side-effects start with "No" and name the thing that does NOT happen — they tell the Implementer what to assert does NOT occur.
- Event names follow `{domain}.{entity}.{verb}` convention (e.g., `auth.session.created`, `billing.invoice.sent`).
- Payload fields are listed in backtick-wrapped comma-separated format.

## User-Perspective First

Scenarios describe what actors do and observe, not internal system behavior. Internal mechanics belong exclusively in Side Effects: the narrative arc of Given/Steps/Outcomes tells the actor's story, and Side Effects is the technical appendix. Write Steps and Outcomes as if narrating the actor's experience — if a step describes something invisible to the actor (database insert, internal event, cache invalidation), move it to Side Effects. The actor never "stores a row" or "publishes an event"; the actor submits a form, clicks a button, or receives a response.

### Perspective by App Type

| App type | Steps perspective | Outcomes perspective | Side Effects perspective |
|----------|------------------|---------------------|------------------------|
| UI app | User clicks, submits, navigates | What user sees (screen, message, redirect) | DB writes, events published, emails queued |
| API | Consumer sends request | Response payload, status code, headers | DB writes, events published, cache updates |
| Backend | System event triggers processing | Observable state change (job completes, status updates) | Tables modified, events published, logs written |

## E2E Testing Philosophy

All scenarios assume the build loop will exercise the code end-to-end with the project's real internal stack and only the outer edge mocked (see `shared/skills/testing/SKILL.md` for the full rule). Write Given/Steps/Outcomes/Side Effects as if everything is testable through the public entry point of the relevant `Application`, with real infrastructure inside the service boundary; the Implementer chooses what to mock at the outer edge per the project's `specs/TECH-STACK.md`. Never design scenarios around mocking. If a scenario requires a database row, the Given step describes the real state. If a scenario publishes an event, the Side Effect names the event on the real bus.

### Potential Concerns

During authoring, the agent may notice areas that could challenge end-to-end execution (e.g., a third-party API with no sandbox, time-dependent logic requiring clock manipulation). These are flagged silently in the final report -- they do NOT interrupt the workflow and do NOT change the spec.

**Concern categories** (closed set):

| Category | Description |
|----------|-------------|
| `fixture` | Complex data setup that may be difficult to seed/teardown |
| `selector` | Hardcoded selectors or identifiers shared across users/sessions |
| `mock` | External service with no sandbox or test mode available |
| `injection` | Time-dependent logic, randomness, or other values requiring injection |
| `environment` | Feature flags, A/B conditions, or environment-specific behavior |
| `data-seed` | Large or interdependent dataset required for realistic test state |

### Testing Decisions in ARCHITECTURE.md

Resolved testing decisions are recorded in the feature's ARCHITECTURE.md under a `## Testing Decisions` section. Commands check this section before flagging concerns -- if a decision already exists for a service or pattern, the concern is not re-flagged.

## YAML Frontmatter Schema

| Field | Type | Rules |
|-------|------|-------|
| `id` | string | `UC-XXXX` -- 4-character timestamp ID |
| `name` | string | Verb-noun goal phrase (e.g., "Create Feature") |
| `feature` | string | Parent feature ID: `FEAT-XXXX` |
| `status` | string | `pending` \| `dirty` \| `implemented` -- the UC's first-class state. `pending` on creation. Written directly by spec-phase commands (when a previously-`implemented` UC is modified, status flips to `dirty`) and by `/m:build` (written directly from the plan's covering-task checkboxes on successful build). See the `status-rollup` shared skill for semantics. Authors do not edit this field manually. |
| `version` | integer | Starts at `1`. Incremented by /m:change on each edit |
| `actor` | string | Primary actor role (must exist in specs/ACTORS.md) |

## UC-XXXX ID Assignment

When creating a new use case, generate a unique ID using a 4-character timestamp code.

**How to generate the ID:**
Run: `node ${CLAUDE_PLUGIN_ROOT}/shared/skills/id-generation/scripts/generate-id.js`
Prepend `UC-` to the output (e.g., `UC-0S9A`).

**Multi-module UCs share one ID** — generate the code once and reuse it for every module-instance, per **Module-Scoped Use Cases** above.

**IDs are permanent.** Once assigned, a UC-XXXX ID is never reused for a different use case, even if the original use case is deprecated.

## Slug Generation

Use case slugs follow the same rules as feature slugs (defined in the feature-authoring skill): lowercase, hyphens for spaces, strip non-alphanumeric, collapse hyphens, max 40 chars at word boundary. The slug is derived from the confirmed use case name.

**Examples:**
- "Login Flow" → `login-flow`
- "Create Feature" → `create-feature`

**Layout:** UC spec file is `UC-XXXX-{slug}.md` (sibling of REQUIREMENTS.md / USE-CASES.md / ARCHITECTURE.md). UC support folder is `UC-XXXX-{slug}/` containing `CHANGELOG.md`. Example: `UC-0S9A-login-flow.md` + `UC-0S9A-login-flow/CHANGELOG.md`.

## USE-CASES.md Row Management

When creating a use case, add a new row to the feature's `USE-CASES.md`:

```
| UC-XXXX | {Use Case Name} | pending | {One-sentence description} | [UC-XXXX-{slug}.md](UC-XXXX-{slug}.md) |
```

**Column rules:**
- **ID:** `UC-XXXX` -- the generated ID
- **Name:** Verb-noun goal phrase (matches frontmatter `name`)
- **Status:** `pending` on creation; managed by the `status-rollup` shared skill thereafter (written by spec-phase commands and `/m:build`).
- **Description:** One sentence -- enough for an agent to identify this use case
- **File:** Relative Markdown link to `UC-XXXX-{slug}.md` (the UC spec file, a sibling of USE-CASES.md inside the FEAT folder)

**When updating a use case,** do NOT change the ID.

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

Cross-reference `specs/ACTORS.md` to validate the actor exists.

### Step 2: Multi-Module Interview Extension

When the parent feature exists in 2+ modules, extend the review loop so that for each shared section (Name, Actor, Trigger, Preconditions, Scenarios) the user confirms **per module** or explicitly declares "identical across modules — use one canonical content." Ask via AskUserQuestion:

> "This UC applies to {N} modules. For {section name}, do you want module-scoped content or the same content in every module?"
> Options: "Module-scoped (I'll provide per module)" / "Same content everywhere" / "Skip this UC in {module X}"

Any section the user marks "Skip this UC in {module X}" means the UC is not written to that module — the UC's module set narrows accordingly.

### Step 3: Review Shared Context

Confirm each shared section in order — use case name, primary actor, preconditions, trigger — one AskUserQuestion per section.

- **Section covered by the input:** present what was extracted and ask whether it is correct. Options: "Yes, looks good" / "Edit" (user provides corrections via Other).
- **Section missing from the input:** say you didn't find it and ask the user to provide it. Options: "Yes, I'll add them" (user provides via Other) / "Skip for now".

### Step 4: Review Scenarios

For each scenario extracted from the input, present the full scenario block (Given, Steps, Outcomes, Side Effects) and ask whether it is correct. Options: "Yes, looks good" / "Edit" (user provides corrections via Other).

Once the scenario is confirmed, ask whether it has a user interface, offering to generate an ASCII art mockup from the user's description of the screen state at the key step. Options: "I'll describe the UI" (user provides via Other) / "No UI for this scenario". If the user describes UI, generate the mockup, present it for confirmation via AskUserQuestion, and note which step it belongs to. If the user provides image file paths, note them for the Write Files step.

For the **Side Effects** field specifically, always remind the user:
"Include both side effects (events published, DB writes) AND explicit non-side-effects (things that do NOT happen). Non-side-effects become 'And no ...' assertions in tests."

After reviewing all extracted scenarios, ask whether to add another. Options: "Yes" (user describes the scenario via Other) / "No, that's all". Repeat the scenario review loop until the user confirms they have no more scenarios.

### Step 5: Write Files

After all sections are confirmed:

1. Generate UC-XXXX ID (4-character timestamp code) — **exactly once** for this use case, even when it will exist in multiple modules.
2. Determine the set of modules this UC applies to. For single-module features, that is the feature's one module. For multi-module features, the interview (see Step 2 above) collected a per-module name and content for the UC — use every module the user selected.
3. **For each module in the set:**
   a. Compute the module-scoped slug from the module-scoped UC name (see the Slug Generation section).
   b. Create the UC support folder `specs/features/{module}/FEAT-XXXX-{slug-for-module}/UC-XXXX-{slug-for-module}/` (this holds CHANGELOG.md).
   c. If any scenario has image files, create `.../UC-XXXX-{slug-for-module}/assets/` and copy images with `{UC-ID}-{descriptive-slug}.{ext}` naming.
   d. Write the UC spec file `specs/features/{module}/FEAT-XXXX-{slug-for-module}/UC-XXXX-{slug-for-module}.md` using [UC-template.md](./templates/UC-template.md) — fill sections with the **module-scoped** content confirmed for this module, include inline `**UI:**` blocks within Steps for scenarios that have UI, set frontmatter `version: 1` and `status: pending`. Every module-instance carries the **same** UC-XXXX ID but its own module-scoped `name:`, actor, trigger, scenarios, and side effects.
   e. Initialize the change log `.../UC-XXXX-{slug-for-module}/CHANGELOG.md` via the `uc-log` shared skill (empty TODO/DONE sections; the calling command appends the first entry — for multi-module UCs the calling command fans out one entry per module-instance per the `uc-log` skill's Multi-Module UC Logging section).
   f. Add a row to that feature-folder's `USE-CASES.md`.

**Anti-pattern:** Do not generate one UC-XXXX ID per module. Do not copy identical scenarios across modules. Do not skip one module because "it's the same use case" — every module the UC applies to gets its own module-scoped file.

## Update Mode

`/m:change` (and `/m:fix` when it touches the spec) uses this skill in update mode:

- **Resolve every module-instance of the UC.** Glob `specs/features/*/FEAT-*/UC-XXXX-*.md` for the given UC-XXXX ID. The result is a set of one or more files. All of them share the same UC-XXXX ID; each is module-scoped.
- Read every module-instance file (and the parent feature's `REQUIREMENTS.md` / `ARCHITECTURE.md`) so the proposed edit is informed by full cross-module context.
- Compare the user's change description with the current content per module-instance.
- Propose specific changes **per module-instance** via AskUserQuestion. When the edit only makes sense in one module, offer the user the option to narrow the fan-out. When the edit is the same everywhere, offer "apply to all instances." Example:
  > "Here's what I'd change for {UC-XXXX} in {module}: {diff}. Apply here?"
  > Options: "Apply here" / "Apply to all module-instances" / "Edit" / "Skip this module"
- Apply after confirmation. Every touched module-instance file gets its frontmatter `version` incremented independently — versions are per-file, not per-UC-ID.
- Do NOT run the creation interview.
- Do NOT change the UC-XXXX ID.
- Do NOT create new module-instances of the UC in this mode. If the change means the UC should now exist in a module it wasn't in before, that is a new authoring action (use `/m:spec` or `/m:change` with an explicit "add module-instance" affordance in a future revision — out of scope here).

## Test Subject vs. Observation Surface

See `shared/skills/testing/SKILL.md` → **Test Subject vs. Observation Surface** for the canonical rule. Authoring implication: side effects in a UC's scenarios must list every user-observable consequence of the use case, even when produced by code in other features (emails sent, notifications shown, downstream writes). These are observations of the UC under test, not tests of those other features — the build loop will assert on them when generating tests.

## Template Reference

| Template | Purpose |
|----------|---------|
| [UC-template.md](./templates/UC-template.md) | UC file for each use case |
