---
name: feature-authoring
description: >-
  Rules and templates for creating and updating feature documents. Defines
  EARS syntax patterns, Fit Criteria, Non-Goals positioning, FEAT-XXXX
  ID assignment, FEATURES.md row management, and the creation interview
  pattern. Used by /m:spec.
---

# Feature Authoring

Rules for creating and maintaining feature documents: REQUIREMENTS.md, USE-CASES.md, and ARCHITECTURE.md scaffold. The /m:spec command references this skill to run the creation interview and generate all feature artifacts.


## Module and Domain Resolution

Before creating or locating a feature, resolve the target module and domain:

1. Read `specs/MODULES.md` for the list of registered modules. Read `specs/DOMAINS.md` for the list of registered domains.
2. If only one module exists, use it automatically (no user prompt needed). If multiple modules exist, ask via AskUserQuestion: "Which modules does this feature apply to?\n\n{module table from MODULES.md}" — multi-select. Keep auto-select when only one module exists.
3. Ask which domain this feature belongs to via AskUserQuestion: "Which domain does this feature belong to?\n\n{domain table from DOMAINS.md}" — **single-select**. Every feature belongs to exactly one domain. If the feature seems to span multiple domains, that is a signal it should be split into multiple features (one per domain), not assigned multiple domains.
4. Use the selected module and domain for all path operations.

All feature paths use the pattern `specs/features/{module}/FEAT-XXXX-{slug}/`.

The domain is a spec-organization concept used to group related features (e.g., `identity`, `billing`, `notifications`) and to filter features in registries. Outcomes that touch other systems (emails, notifications, downstream events) are recorded as **side effects** of the UC under test — they are validations of the same UC, not evidence that another domain is being tested.

### Module-Scoped Content (Multi-Module Features)

When a feature spans 2+ modules, each module's REQUIREMENTS.md must focus on that module's actors, concerns, and interactions. Do not copy identical content across modules.

**Rules:**
- Scope **Actors** to the module's primary users (e.g., `patient` module lists patients; `console` module lists administrators)
- Scope **Functional Requirements** to what happens within the module boundary
- Scope **Non-Goals** to exclude concerns handled by other modules in the same feature
- Scope **Non-Functional Requirements** to the module's performance and security profile
- Scope **Acceptance Criteria** to what can be verified from the module's perspective

**Example — one feature, two modules:**

| Section | patient module | console module |
|---------|----------------|----------------|
| Actors | Patient, Caregiver | Administrator, Support Agent |
| FR example | When a patient completes the registration form, the system shall create their patient profile. | When an administrator searches for a patient, the system shall return matching patient records. |
| Non-Goals | Does not handle admin review of registrations -- see console module. | Does not handle patient-facing registration -- see patient module. |

**Use cases inside a multi-module feature follow the same shared-ID, module-scoped-content pattern.** One `UC-XXXX` ID is reused across every module the use case applies to; each module gets its own module-scoped `UC-XXXX-{slug}.md`. See `spec/skills/usecase-authoring/SKILL.md` → **Module-Scoped Use Cases** for the full rule.

**Single-module features are unaffected.** This rule applies only when a feature is created in 2+ modules.

## Refs Declaration

When creating a feature, after the module and domain are resolved and before the creation interview:

1. Read `specs/FEATURES.md` and check if there are existing features this new feature depends on.
2. If dependency candidates exist, ask via AskUserQuestion:
   "Does this feature depend on any existing features?\n\n{features table}\n\nSelect any that apply, or skip."
   Options: list each candidate feature + "None -- no dependencies"
3. Record selected refs for inclusion in REQUIREMENTS.md frontmatter.

## EARS Syntax

All functional requirements MUST be written in EARS (Easy Approach to Requirements Syntax). Each sentence has a mandatory keyword that frames the trigger and the system response.

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
- Each sentence expresses one requirement -- no "and" chaining
- Requirements must be falsifiable: a test must be able to pass or fail it
- Triggers must describe user-observable actions or events, not internal system mechanics (see User-Perspective First)

## Fit Criteria

Every functional requirement must include a Fit Criterion immediately after it. The Fit Criterion is the measurable condition that proves the requirement is satisfied.

**Format:**
```
**FR-XXXX** `When {trigger}, the system shall {response}.`
Fit Criterion: Given {precondition}, {measurable outcome that proves this is satisfied}.
Linked to: UC-XXXX
```

**Rules:**
- Fit Criteria use "Given ... {measurable outcome}" format
- The outcome must be verifiable (a test can check it)
- "The system should feel fast" is not a Fit Criterion
- "Given 100 concurrent users, response time is < 200ms at p95" is a Fit Criterion
- Every FR requires one Fit Criterion -- no exceptions

## User-Perspective First

EARS triggers must describe user-observable actions, not internal mechanics. Requirements tell the story of what users do and see. Implementation details belong exclusively in Fit Criteria -- the verification layer.

### Perspective Selection

| App type | Trigger perspective | Response perspective |
|----------|-------------------|---------------------|
| UI app | User action (clicks, submits, navigates) | What user sees (screen, message, redirect) |
| API | Consumer action (sends request, calls endpoint) | Response payload / status code |
| Backend | System event (cron fires, message arrives) | Observable state change (job completes, record updates) |

### Anti-Patterns

| Bad trigger (implementation-leaked) | Corrected trigger (user-perspective) |
|--------------------------------------|--------------------------------------|
| When the system creates a new `users` row with `privy_id` set to the Privy DID | When a new user completes registration |
| When the JWT is validated and the session table is updated | When the user logs in with valid credentials |
| When the webhook handler parses the Stripe payload | When a payment is received from the payment provider |

### Where Implementation Details Belong

Implementation details surface in Fit Criteria, where they serve as measurable proof that a requirement is satisfied. The requirement stays user-perspective — `When a new user completes registration, the system shall create their account and mark their profile as complete.` — while its Fit Criterion names the database column, the exact field value, and the observable confirmation: `Given a user completes the registration form, a users row exists with profile_complete=true and the user sees the welcome screen.`

## Non-Goals Positioning

The Non-Goals section MUST appear second in REQUIREMENTS.md -- immediately after the one-sentence objective, before Actors, before Functional Requirements.

**Why:** agents read top-to-bottom — scope boundaries read late are scope boundaries partially ignored.

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
- Does not support {Z} -- see FEAT-XXXX for that
```

## UI Section

The UI section is optional. It appears at position 4 in REQUIREMENTS.md (after Actors, before Functional Requirements). It provides visual context that informs the reading of requirements that follow. Omit it entirely for features with no user interface.

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

ASCII art conveys layout and element hierarchy — generate it from the user's description of the feature.

**Image references** -- standard Markdown images pointing to files in `assets/`:

```
![Dashboard overview](assets/overview-dashboard.png)
```

Images are a post-creation enhancement: the `assets/` directory is created inside the feature directory after that directory exists. When the user provides image files (file paths), copy them to `specs/features/{module}/FEAT-XXXX-{slug}/assets/` with descriptive names and reference them in the `## UI` section.

### Asset Management

- Feature-level images go in `specs/features/{module}/FEAT-XXXX-{slug}/assets/`
- File naming: `{descriptive-slug}.{ext}` -- lowercase, hyphens, no spaces, max 50 character slug
- Supported formats: PNG, JPG
- When the user provides image file paths during creation or update, copy the files and add references

### When to Include

Include the `## UI` section when the feature has screens, forms, or visual interactions, or when the user supplies mockups, screenshots, wireframes, or a layout description. Omit it for pure backend, API-only, or infrastructure features, and whenever the user says there is no UI.

### UI Informs Requirements

UI is specification, not decoration. Screen names, button labels, and form fields that appear in mockups are the vocabulary for EARS triggers and responses — "the user submits the form" is stronger when the UI section shows exactly which form, with which fields, and what the confirmation screen looks like.

## Feature Status

Every feature's `REQUIREMENTS.md` carries a frontmatter `status:` field with values `pending | dirty | implemented` (legacy `deprecated` preserved when present). The field is the feature's first-class state: `pending` on creation, recomputed by rolling up over child UC statuses thereafter. It is written directly by spec-phase commands and `/m:build` per the `status-rollup` shared skill, which owns the roll-up rule. Authors do not edit this field manually.

## FEAT-XXXX ID Assignment

When creating a new feature, generate a unique ID using a 4-character timestamp code.

**How to generate the ID:**
Run: `node ${CLAUDE_PLUGIN_ROOT}/shared/skills/id-generation/scripts/generate-id.js`
Prepend `FEAT-` to the output (e.g., `FEAT-0S9A`).

**IDs are permanent.** Once assigned, a FEAT-XXXX ID is never reused or deleted, even if the feature is deprecated.

## FR/NFR/US ID Assignment

When writing functional requirements, non-functional requirements, or user stories, generate a unique ID for each using a 4-character timestamp code.

**How to generate IDs:**
Run: `node ${CLAUDE_PLUGIN_ROOT}/shared/skills/id-generation/scripts/generate-id.js {count}`
Prepend the appropriate prefix to each output line:
- `FR-` for functional requirements (e.g., `FR-0Fy0`)
- `NFR-` for non-functional requirements (e.g., `NFR-0Fy1`)
- `US-` for user stories (e.g., `US-0Fy2`)

**IDs are permanent.** Once assigned, an FR/NFR/US ID is never reused.

## Slug Generation

When creating a feature, generate a kebab-case slug from the confirmed feature name:

1. Lowercase the name
2. Replace spaces and underscores with hyphens
3. Strip all characters except `[a-z0-9-]`
4. Collapse consecutive hyphens
5. Trim leading/trailing hyphens
6. Truncate to max 40 characters at the last full word boundary

**Examples:**
- "User Authentication" -> `user-authentication`
- "Real-Time Notifications" -> `real-time-notifications`
- "API Rate Limiting & Throttling" -> `api-rate-limiting-throttling`

The slug is appended to the FEAT ID with a hyphen: `FEAT-XXXX-{slug}` (e.g., `FEAT-0S9A-user-authentication`).

## FEATURES.md Row Management

When creating a feature, add a new row to `specs/FEATURES.md` under the `## {domain}` section.

**Format:**
```
| FEAT-XXXX | {Feature Name} | {One-sentence description} | pending |
```

**Column rules:**
- **ID:** `FEAT-XXXX` -- the generated ID
- **Feature:** Short name (3-5 words)
- **Description:** One sentence -- enough for an agent to decide if this is the right feature
- **Status:** Always `pending` when first created

**When updating a feature,** do NOT change the ID. Update Status only when the feature advances through its lifecycle.

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

Confirm each section with one AskUserQuestion:

- **Section covered by the input:** present what was extracted and ask whether it is correct. Options: "Yes, looks good" / "Edit" (user provides corrections via Other).
- **Section missing from the input:** say you didn't find it and ask whether the user has any. Options: "Yes, I'll add them" (user provides via Other) / "No, skip this section".

Present sections in this order:
1. Feature name
2. Non-goals
3. Actors
4. UI (optional -- see UI Section rules above)
5. Functional requirements (shown in EARS syntax with Fit Criteria)
6. Non-functional requirements
7. Acceptance criteria

The UI step differs from the others:

- **UI content extracted from input** (layout descriptions, mockups, image references): present it and ask whether it is correct. Options: "Yes, looks good" / "Edit" (user provides corrections via Other).
- **No UI content in the input:** ask whether the feature has a user interface, offering to generate ASCII art mockups from a description or to take image file paths. Options: "I'll describe the UI" (user provides via Other) / "No UI -- skip".

If the user says "No UI -- skip", do not include the `## UI` section in REQUIREMENTS.md. If the user describes the UI, generate ASCII art mockups in fenced code blocks showing layout, key elements, and hierarchy.

### Step 3: Write Files

After all sections are confirmed:
1. Generate FEAT-XXXX ID (4-character timestamp code)
2. Create `specs/features/{module}/FEAT-XXXX-{slug}/` directory. Use cases are direct children of this folder — there is no `use-cases/` subdirectory.
3. If the user provided image file paths, create `specs/features/{module}/FEAT-XXXX-{slug}/assets/` and copy image files with descriptive names. UC-level assets live inside each UC's own folder (`UC-XXXX-{slug}/assets/`) and are created later by `/m:spec` when the UC is authored.
4. Write `specs/features/{module}/FEAT-XXXX-{slug}/REQUIREMENTS.md` using [REQUIREMENTS-template.md](./templates/REQUIREMENTS-template.md) -- include `## UI` section with confirmed ASCII art and/or image references if UI content was provided; omit `## UI` section entirely if user said no UI. Frontmatter: `module: {module}`, `domain: {domain}` (single value).
5. Write `USE-CASES.md` using [USE-CASES-template.md](./templates/USE-CASES-template.md) (empty table).
6. Write `ARCHITECTURE.md` scaffold using the template at `spec/skills/architecture/templates/ARCHITECTURE-template.md`
7. Add row to `specs/FEATURES.md` under the `## {domain}` section (format from the Row Management section above)

## Update Mode

/m:spec uses this skill in update mode:
- Read the current `REQUIREMENTS.md` and `ARCHITECTURE.md`
- Compare with the user's change description
- Propose specific changes via AskUserQuestion ("Here's what I'd change: ... Does this look correct?")
- Apply after confirmation
- Do NOT run the creation interview
- Do NOT change the feature's lifecycle status

## ARCHITECTURE.md

For ARCHITECTURE.md schema, sections, and population rules, see the architecture skill (`spec/skills/architecture/SKILL.md`).

During feature creation, scaffold ARCHITECTURE.md using the template at `spec/skills/architecture/templates/ARCHITECTURE-template.md`.

ARCHITECTURE.md may include a `## Testing Decisions` section that records resolved E2E testing decisions for the feature. This section is checked by reverse commands before flagging testability concerns -- if a decision already exists for a service or pattern, the concern is not re-flagged.

**Format:** table with columns `| Service/Pattern | Decision | Reason |`

**Examples:**

| Service/Pattern | Decision | Reason |
|-----------------|----------|--------|
| Stripe API | e2e | Use test mode API keys |
| Legacy reporting DB | mock | Read-only replica, cannot seed fixtures |
| Clock-dependent expiration | injection | Use injectable clock for deterministic tests |

## Template Reference

| Template | Purpose |
|----------|---------|
| [REQUIREMENTS-template.md](./templates/REQUIREMENTS-template.md) | REQUIREMENTS.md for each feature |
| [USE-CASES-template.md](./templates/USE-CASES-template.md) | USE-CASES.md index for each feature |
