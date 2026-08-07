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

## Extraction Patterns

The **What to Scan For** table above is the canonical code-construct → spec-element mapping. One pattern needs its own rule:

### Non-Side-Effects

Look for what the code explicitly does NOT do in certain paths:
- Conditional blocks that skip event emission → "No {event} is published"
- Early returns before DB writes → "No database record is created"
- Guards that prevent notifications → "No notification is sent"

## Testability Analysis

During reverse engineering, identify areas that might challenge end-to-end testing with real internal stack + outer-edge mocking (see `shared/skills/testing/SKILL.md`). Each one is an unresolved item. Resolve it with the user before any spec file is written, per the `resolution-gate` shared skill. Do not generate a sidecar file.

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

Before you collect a concern, read the feature's ARCHITECTURE.md and find its `## Testing Decisions` section. The architecture skill defines that section and `ARCHITECTURE-template.md` ships it, so every feature has one. If a row already names the service or pattern in question, drop the concern — the user resolved it in an earlier run. A table with no data rows has resolved nothing, so every concern for that feature survives to the gate.

### Collect, Then Resolve Once

Never stop the scan on a finding. `/m:cover` reads hundreds of files, and one question per file is an interrogation.

1. **During the scan** — append every surviving concern to an in-memory list. Record the UC, the file, the category, and the code pattern that raised it. Print nothing and ask nothing.
2. **When the scan finishes, and before the first spec file is written** — run the `resolution-gate` shared skill over the whole list as one gate run. Its relevance filter, its grouping rule, and its cap of five questions per round apply to the list, never to a single item. Concerns that name the same service or the same pattern are one question.
3. **After the answers arrive** — write one row per resolved concern to the feature's `ARCHITECTURE.md` under `## Testing Decisions`, in the `| Service/Pattern | Decision | Reason |` schema the architecture skill defines. One row per service or pattern, never one row per file.

A concern the filter dropped is dropped. It is not asked, it is not written, and it is not reported. Do not write a sidecar file.

## Populating ARCHITECTURE.md

For section definitions and population rules, see the architecture skill (`spec/skills/architecture/SKILL.md`).

During reverse engineering, update `last_update` in the frontmatter to the current date.

## Project-Level Discovery

Reverse engineering may uncover actors, tech stack components, or features not yet documented in the project-level files. Compare what the scan finds against what already exists and update accordingly.

### Actors (specs/ACTORS.md)

When code analysis reveals an actor not listed in ACTORS.md — a new user role, system actor, or external service that triggers or receives actions — add a row:

| Actor | Role | Description | Constraints |
|-------|------|-------------|-------------|
| {discovered name} | {human / system / external} | {What they do, derived from code} | {Permissions or limitations observed in code} |

**Rules:**
- Only add actors that are genuinely new — check ACTORS.md first. An actor that is just a different permission level of an already-listed actor is not new; update the existing row's Constraints instead.
- Use the naming style already present in ACTORS.md (if it says "End User", don't add "end-user")
- If ACTORS.md doesn't exist, create it using the template at `${CLAUDE_PLUGIN_ROOT}/setup/skills/setup/templates/ACTORS-template.md`

### Tech Stack (specs/TECH-STACK.md)

When code analysis reveals a technology not listed in TECH-STACK.md — a database, framework, queue system, external service SDK, or infrastructure component — add it to the appropriate section.

**Rules:**
- Only add technologies that play a structural role — not every npm package belongs in TECH-STACK.md. Utility libraries (lodash, moment) and dev dependencies (linters, formatters) are implementation details, not stack choices.
- Match the existing format and section headings
- If TECH-STACK.md doesn't exist, create it using the template at `${CLAUDE_PLUGIN_ROOT}/setup/skills/setup/templates/TECH-STACK-template.md`

## Command Integration

`/m:cover` spans multiple scope levels — a broad capability may map to multiple features, while a single code path appends one scenario to one UC. The command scans the confirmed files and writes the specs itself in one pass: ARCHITECTURE.md tables (Component Inventory, Data Model, API Surface, Integration Points, Code Map, Event Topology), REQUIREMENTS.md, UC files with inline scenarios, USE-CASES.md and FEATURES.md rows, every ID assigned via the id-generation skill (`shared/skills/id-generation/SKILL.md`), plus new ACTORS.md / TECH-STACK.md entries per the project-level discovery rules above. **Assign an ID only to an entity that does not already have one.** When the scan lands on a feature, UC, or scenario that is already specced, reuse its existing ID verbatim — appending a scenario to an existing UC keeps that UC's ID and every sibling `SC-XXXX`, and rewriting a `FEATURES.md` or `USE-CASES.md` row never alters the ID in it. See the skill's **Immutability** section. Every spec statement must trace to a file the scan actually read. `/m:cover` produces specs only — no test code; tests come later via `/m:plan` (mode: cover) + `/m:build`.

> **Note:** Reverse commands hand off to `/m:plan`, which decomposes the extracted specs into `coverage` tasks (see the plan-authoring skill). `/m:build` runs each coverage task through the GREEN-first / mutation-RED protocol, adding tests to existing files without writing production code.

## Template Reference

| Template | Source | Purpose |
|----------|--------|---------|
| ARCHITECTURE-template.md | `spec/skills/architecture/templates/ARCHITECTURE-template.md` | ARCHITECTURE.md scaffold |
