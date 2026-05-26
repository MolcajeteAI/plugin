---
name: architecture
description: >-
  Schema, section definitions, and population rules for ARCHITECTURE.md — the
  feature-level artifact that maps specs to code. Referenced by feature-authoring
  (scaffold creation) and reverse-engineering (code-driven population).
---

# Architecture

Owns all ARCHITECTURE.md knowledge: frontmatter schema, section definitions, population rules, and the template. Both Specs First (greenfield) and Code First (brownfield) flows reference this skill when creating or populating ARCHITECTURE.md.


## Frontmatter Schema

```yaml
---
id: FEAT-XXXX
name: {Feature Name}
use_cases: []
scenarios: []
last_update: YYYY-MM-DD
---
```

All fields are mandatory:
- `id` — the feature's FEAT-XXXX identifier
- `name` — the feature's display name
- `use_cases` — array of UC-XXXX IDs whose implementation is documented in this file. Populated as UCs are created (Specs First) or extracted (Code First).
- `scenarios` — array of SC-XXXX IDs documented in this file. Populated as scenarios are created or extracted.
- `last_update` — date the sections were last updated (use current date).

## Section Reference

### System Context (C4 L1)

Mermaid C4Context diagram showing who uses this feature and what external systems it touches. Includes actors, the system itself, and external dependencies with labeled relationships.

### Container View (C4 L2)

Mermaid C4Container diagram showing which major components are involved and how they communicate. Includes API layers, databases, queues/event buses, and their interactions.

### Data Model

Mermaid ER diagram with entity schemas, field constraints, and invariants. Includes:
- Entity definitions with field types, primary/foreign keys, and constraints
- Relationships between entities
- **Invariants** — business rules that must always hold (e.g., state transition rules, referential constraints)

### Component Inventory

One row per file that participates in this feature.

| Column | Content |
|--------|---------|
| File | Relative path to the source file |
| Role | Brief category: route handler, business logic, data model, middleware, utility, test |
| Key Exports | Primary functions, classes, routes, or constants exported |

Discover files by tracing call chains from entry points through services to the data layer.

### Event Topology

All events this feature emits or consumes. Agents implementing a publisher use this table to know what to emit and when.

| Column | Content |
|--------|---------|
| Event | Domain event name in `{domain}.{entity}.{verb}` format |
| Publisher | Component that emits the event |
| Payload | Key fields included in the event payload |
| Condition | When the event fires |
| Consumers | Components that subscribe to this event |

Include a **Non-events** list for scenarios where an event is explicitly NOT published.

### API Surface

All routes/endpoints belonging to this feature.

| Column | Content |
|--------|---------|
| Method | HTTP method (GET, POST, PUT, DELETE, etc.) |
| Path | Route path |
| Handler | Handler function or controller |
| Auth | Auth requirements for this route |
| Request Shape | Key fields in the request body/params (abbreviated) |
| Response Shape | Key fields in the response (abbreviated) |
| Error Codes | HTTP status codes or error types returned |

### Integration Points

External services, event streams, and infrastructure dependencies.

| Column | Content |
|--------|---------|
| System | External system name |
| Protocol | Communication protocol (HTTP, gRPC, AMQP, etc.) |
| Direction | inbound, outbound, or bidirectional |
| Purpose | What this integration is used for |

### State Transitions

Mermaid stateDiagram-v2 for features where entities have a lifecycle. Shows states, transitions, triggers, and terminal conditions.

### Code Map

Links spec IDs to implementation files. This table is the primary bridge between specs and code — plan and build use it to locate relevant implementation.

| Column | Content |
|--------|---------|
| Spec ID | UC-XXXX or SC-XXXX identifier |
| Spec Name | Human-readable name of the use case or scenario |
| Implementation Files | Source files using `file:function()` notation for scenario-level specificity |

Every UC and SC gets a Code Map entry.

### Testing Decisions

Records resolved E2E testing decisions for this feature. Reverse commands check this section before flagging testability concerns -- if a decision exists for a service or pattern, the concern is not re-flagged.

| Column | Content |
|--------|---------|
| Service/Pattern | The external service, code pattern, or infrastructure component |
| Decision | `e2e`, `mock`, or `injection` -- how this will be tested |
| Reason | Why this decision was made |

Initially empty when scaffolded. Populated by developers after reviewing testability recommendations.

### Architecture Decisions

Non-obvious choices that future agents should not reverse. Uses the format:

```
**ADR-XXXX:** {Decision title}
In the context of {situation}, facing {concern}, we decided {choice} to achieve {quality}, accepting {tradeoff}.
```

Generate ADR IDs the same way as all other entity IDs:

Run: `node ${CLAUDE_PLUGIN_ROOT}/shared/skills/id-generation/scripts/generate-id.js`
Prepend `ADR-` to the output (e.g., `ADR-0L2x`).

## Research Discovery

When generating or updating an ARCHITECTURE.md, scan for relevant research briefs:

1. List `.molcajete/research/*.md` — filenames sort naturally by timestamp (newest first)
2. Read only the YAML frontmatter of each file (not the body)
3. Compare `description` and `query` against the feature's topic
4. If relevant, read the full document and use it as context
5. Stop after the first relevant match to protect context window
6. Also scan `research/*.md` at project root the same way

The brief's "Current Best Practices" and "Key Libraries/APIs" sections directly inform architecture decisions. Cite relevant findings in the Architecture Decisions section when they influenced a choice.

## Population Rules

- Sections are **additive** — append rows, don't replace existing ones
- When adding new UCs or scenarios, add rows to Component Inventory, API Surface, and Code Map without disturbing existing entries
- Update the `use_cases` and `scenarios` frontmatter arrays when adding new IDs
- Always update `last_update` to the current date when modifying sections

## Table Filling

ARCHITECTURE.md ships with empty tables in the scaffold so the file remains valid before the architecture pass runs. Both forward spec and reverse-spec MUST populate the tables before declaring the architecture pass complete — the harness reads them downstream to scope slices, route mutations, and locate implementation files. An ARCHITECTURE.md with empty Component Inventory, API Surface, or Code Map blocks the spec pass.

For every new use case or scenario added under this feature, populate at minimum:

| Table | Forward spec source | Reverse-spec source |
|-------|---------------------|---------------------|
| Component Inventory | Slice `files.create` + `files.modify` aggregated across the UC's slices | Files traced from entry-point grep through the call chain |
| API Surface | Endpoint references in REQUIREMENTS.md and UC scenario steps | Route registrations and handlers found in the codebase |
| Code Map | `Spec ID → file:function()` derived from each slice's `provides` and target files | `Spec ID → file:function()` derived from the discovery scan |
| Testing Decisions | Testability notes surfaced by the spec command | Same — recorded so subsequent reverse passes do not re-flag |
| Event Topology | Events named in scenarios' Side Effects | Producer/consumer pairs traced through the event-bus call sites |
| Integration Points | External systems named in scenarios | External clients located in the codebase |

The architecture tables are the bridge between the spec layer and the slice layer. A slice's `### Contracts` snippet declares the type surface it locks; a slice's target files must already appear in Component Inventory and Code Map. If a slice references a file or contract that is not in the architecture tables, the architecture pass is incomplete.

Leave a table empty only when the feature genuinely has no rows for it (e.g., Event Topology when the feature emits no events; State Transitions when no entity has a lifecycle). Do not leave a table empty out of laziness — the harness treats an unpopulated mandatory table as a spec defect.

## Template Reference

| Template | Purpose |
|----------|---------|
| [ARCHITECTURE-template.md](./templates/ARCHITECTURE-template.md) | ARCHITECTURE.md scaffold for each feature |
