---
name: reverse-engineering
description: >-
  Rules and methodology for extracting specs from existing codebases.
  Defines research patterns, ARCHITECTURE.md population from code analysis,
  scope discovery, extraction patterns mapping code constructs to spec
  elements, and subagent dispatch for spec extraction.
---

# Reverse Engineering

Rules for extracting product specs from existing code. The reverse commands scan a codebase, extract structured specs (features, use cases, inline scenarios), and populate ARCHITECTURE.md from code analysis — the inverse of the Specs First (greenfield) pipeline.


## Research Methodology

When scanning code to extract specs, follow this systematic approach:

### What to Scan For

| Code Construct | What to Extract | Spec Target |
|----------------|-----------------|-------------|
| Route handlers, controllers | Entry points, request shapes, response shapes | UC triggers, scenarios |
| Service/business logic | Core workflows, orchestration | UC steps, outcomes |
| Model/schema definitions | Entities, relationships, constraints | Data Model, preconditions |
| Middleware, guards | Auth checks, rate limits, validation | Preconditions, NFRs |
| Event emissions | Async operations, side effects | Side Effects |
| Error handling (try/catch) | Failure modes, error responses | Error scenarios |
| Conditional branches | Alternative flows, edge cases | Scenario variants |
| External API calls | Integration points, dependencies | Integration Points |
| Database queries | Data access patterns, transactions | Data Model, Code Map |
| Configuration/env vars | Feature flags, tunables | Non-goals, constraints |
| Test files | Existing coverage, expected behavior | Scenario validation |

### Scan Order

1. **Entry points first** — routes, controllers, event handlers, CLI commands
2. **Follow the call chain** — trace from entry point through services to data layer
3. **Identify boundaries** — where does this feature's code end and another's begin?
4. **Catalog side effects** — events emitted, DB writes, external calls
5. **Map error paths** — catch blocks, error responses, validation failures

### Scope Discovery

When breaking code into features vs use cases vs scenarios:

- **Feature boundary** — a cohesive set of capabilities sharing a module (e.g., "authentication" encompasses login, registration, token refresh)
- **Use case boundary** — a single actor goal achieved through one interaction (e.g., "user login" is one UC within auth)
- **Scenario boundary** — one path through a use case (e.g., "valid credentials" vs "invalid password" are separate scenarios within login)

**Signals for feature boundaries:**
- Separate directory/module structure
- Distinct data models
- Different actor sets
- Independent middleware chains
- Separate configuration sections

**Signals for use case boundaries:**
- Distinct entry points (routes, event handlers)
- Different triggers (user action vs system event vs scheduled)
- Separate success/failure outcomes
- Different actor roles

## Extraction Patterns

Map code constructs to spec elements using these patterns:

### Route Handlers to UC Triggers

```
POST /auth/login → Trigger: "User submits login credentials"
GET /users/:id   → Trigger: "User requests profile details"
webhook handler  → Trigger: "External system sends webhook event"
```

### Middleware/Guards to Preconditions

```
authMiddleware()     → Precondition: "User is authenticated"
rateLimit(100/min)   → NFR: rate limiting
validateBody(schema) → Precondition: "Request body is valid"
requireRole('admin') → Precondition: "User has admin role"
```

### Try/Catch Blocks to Error Scenarios

```
catch (NotFoundError)     → Scenario: "Resource not found"
catch (ValidationError)   → Scenario: "Invalid input"
catch (UnauthorizedError) → Scenario: "Insufficient permissions"
catch (ConflictError)     → Scenario: "Duplicate resource"
```

### Event Emissions to Side Effects

```
emit('user.account.created')  → Side Effect: Event "user.account.created"
emit('order.payment.failed')  → Side Effect: Event "order.payment.failed"
sendEmail(user, template)     → Side Effect: "Notification email sent"
```

### Conditional Branches to Scenario Variants

```
if (user.isVerified) {        → Scenario: "Verified user flow"
} else {                      → Scenario: "Unverified user flow"
}

switch (paymentMethod) {
  case 'card': ...            → Scenario: "Card payment"
  case 'bank': ...            → Scenario: "Bank transfer payment"
}
```

### Non-Side-Effects

Look for what the code explicitly does NOT do in certain paths:
- Conditional blocks that skip event emission → "No {event} is published"
- Early returns before DB writes → "No database record is created"
- Guards that prevent notifications → "No notification is sent"

## Testability Analysis (Reporting Only)

During reverse engineering, identify areas that might challenge end-to-end testing with real internal stack + outer-edge mocking (see `shared/skills/testing/SKILL.md`). These are surfaced in the command's final report. Do not generate a sidecar file; do not interrupt the workflow.

### What to Look For

| Code Pattern | Concern Category | Example |
|-------------|-----------------|---------|
| HTTP clients to external APIs with no known sandbox | `mock` | Stripe live-only endpoints, third-party webhooks |
| `Date.now()`, `new Date()`, time-based conditions | `injection` | Token expiration checks, scheduled job windows |
| `Math.random()`, UUID generation in assertions | `injection` | Non-deterministic output that tests must match |
| OAuth/SSO redirects to external providers | `mock` | Google OAuth, SAML IdP redirects |
| Hardcoded selectors shared across users | `selector` | CSS selectors or element IDs that collide in parallel runs |
| Feature flags, A/B conditions | `environment` | `if (featureFlag('new-checkout'))` branches |
| Large seed datasets or complex fixture graphs | `data-seed` | Reporting queries needing 1000+ rows for realistic results |
| Complex teardown or shared mutable state | `fixture` | Global counters, singleton caches, file locks |

### Check ARCHITECTURE.md First

Before flagging a concern, read the feature's ARCHITECTURE.md and look for a `## Testing Decisions` section. If a decision already exists for the service or pattern in question, skip it — the developer has already resolved this concern.

### No Interruptions, No Sidecar Files

Do not use AskUserQuestion for testability concerns. Do not write a sidecar file. Surface remaining concerns in the command's final report as a "Testability Notes" block, with the count and category per UC.

## Populating ARCHITECTURE.md

For section definitions and population rules, see the architecture skill (`spec/skills/architecture/SKILL.md`).

During reverse engineering, update `last_update` in the frontmatter to the current date. Discover files by tracing call chains from entry points through services to the data layer.

## Project-Level Discovery

Reverse engineering may uncover actors, tech stack components, or features not yet documented in the project-level files. Subagents must compare what they find against what already exists and update accordingly.

### Actors (prd/ACTORS.md)

When code analysis reveals an actor not listed in ACTORS.md — a new user role, system actor, or external service that triggers or receives actions — add a row:

| Actor | Role | Description | Constraints |
|-------|------|-------------|-------------|
| {discovered name} | {human / system / external} | {What they do, derived from code} | {Permissions or limitations observed in code} |

**Signals for new actors:**
- `requireRole('role')` or auth guards referencing an undocumented role
- External API clients or webhook handlers representing a system not listed
- Scheduled jobs or cron handlers acting as system actors
- Event consumers that act on behalf of an unlisted service

**Rules:**
- Only add actors that are genuinely new — check ACTORS.md first
- Use the naming style already present in ACTORS.md (if it says "End User", don't add "end-user")
- If ACTORS.md doesn't exist, create it using the template at `${CLAUDE_PLUGIN_ROOT}/setup/skills/setup/templates/ACTORS-template.md`

### Tech Stack (prd/TECH-STACK.md)

When code analysis reveals a technology not listed in TECH-STACK.md — a database, framework, queue system, external service SDK, or infrastructure component — add it to the appropriate section.

**Signals for new tech stack entries:**
- Import/require of an undocumented framework or library that plays a structural role (ORM, queue, cache, auth provider)
- Database connection strings or drivers for an unlisted database
- Infrastructure config (Docker services, CI steps) referencing unlisted tools
- SDK imports for external services (payment processors, email providers, cloud APIs)

**Rules:**
- Only add technologies that play a structural role — not every npm package belongs in TECH-STACK.md
- Match the existing format and section headings
- If TECH-STACK.md doesn't exist, create it using the template at `${CLAUDE_PLUGIN_ROOT}/setup/skills/setup/templates/TECH-STACK-template.md`

### What NOT to Add

- Utility libraries (lodash, moment) — these are implementation details, not stack choices
- Dev dependencies (linters, formatters) — unless they represent a project convention worth documenting
- Actors that are just different permission levels of an already-listed actor — update the existing row's Constraints instead

## Dispatcher Integration

Reverse commands that span multiple scope levels (reverse-spec, reverse-feature) use a two-step dispatcher pattern to protect the 200K context limit. Both steps produce specs only — no test code is written by reverse commands.

### Codebase Research

Launched as an **Explore subagent** (`subagent_type: "Explore"`). This is read-only — no file writes. Receives:
- Project context (PROJECT.md, TECH-STACK.md, ACTORS.md, FEATURES.md)
- The freeform description of what to extract
- Confirmed file scope from the parent command
- Thoroughness level (typically `"very thorough"` for reverse engineering)

Produces a **structured research report** (returned as text, not written to files):
- Feature boundaries and proposed groupings
- Use case inventory with triggers, steps, and outcomes
- Scenario variants per use case (happy path + error paths)
- Component inventory (files, roles, relationships)
- Data model entities with fields and constraints
- API surface (routes, auth, request/response shapes)
- Integration points and side effects
- Code map entries (`file:function()` notation)
- Any new actors or tech stack entries discovered

### Spec Writing

Launched as a **general-purpose subagent** after research completes. Receives:
- The research report from the prior step
- Project context (PROJECT.md, TECH-STACK.md, ACTORS.md, FEATURES.md)
- Skill files for formatting rules

Produces:
- ARCHITECTURE.md (Component Inventory, Data Model, API Surface, Integration Points, Code Map)
- PRD specs (REQUIREMENTS.md, UC files with inline scenarios, USE-CASES.md rows, FEATURES.md rows)
- All IDs assigned (FEAT-, UC-, SC-, FR-, NFR-, US-, ADR-) using the id-generation skill (`shared/skills/id-generation/SKILL.md`)
- Updates to ACTORS.md and TECH-STACK.md if new entries were discovered

### Subagent Launch Pattern

**Explore subagent** (read-only research):

```
Use the Agent tool with subagent_type: "Explore" and specify:
1. Thoroughness level ("very thorough" for reverse engineering)
2. Which project context files to read for orientation
3. The confirmed file scope to scan
4. What to scan for (features, use cases, scenarios, data model, etc.)
5. The output format: a structured research report (text, not files)
```

The Explore agent cannot write files. It returns its findings as text, which the parent passes to the spec-writing subagent.

**General-purpose subagent** (spec writing):

```
Use the Agent tool (general-purpose, the default) with a detailed prompt
that includes:
1. The research findings from the prior Explore agent
2. Which skill files to load for formatting rules
3. Which project context files to read
4. The specific writing task
5. Where to write output files
```

The parent command does NOT re-read the files the subagent created — it trusts the subagent's report and presents the results to the user.

> **Note:** Reverse commands emit `coverage` slices alongside the extracted specs (see the slicing skill). The harness runs each coverage slice through the GREEN-first / mutation-RED protocol; CodeWriter only adds tests to existing files.

## Template Reference

| Template | Source | Purpose |
|----------|--------|---------|
| ARCHITECTURE-template.md | `spec/skills/architecture/templates/ARCHITECTURE-template.md` | ARCHITECTURE.md scaffold |
