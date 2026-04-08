---
id: FEAT-XXXX
name: {Feature Name}
module: {module}
domain: {domain}
status: pending
version: 1
refs: [] # Optional: feature IDs this feature depends on (e.g., [FEAT-0A1b])
---

# {Feature Name}

> {One sentence: what this feature does and who it serves.}

## Non-Goals

> What this feature explicitly does NOT do.
> This section appears second -- before Actors, before requirements.
> LLMs read top-to-bottom; scope boundaries must come early.

- Does not handle {X}
- Does not replace {Y}
- Does not support {Z} -- see FEAT-XXXX for that

## Actors

| Actor | Role | Notes |
|-------|------|-------|
| {Actor name} | {What they do in this feature} | {Any constraints on this actor} |

## UI

> Optional. Delete this section if the feature has no user interface.
> ASCII art mockups show layout and element hierarchy. Image references point to files in `assets/`.

<!-- ASCII art mockups in fenced code blocks: -->
```
+----------------------------------+
| {Screen/Component Name}         |
|                                  |
| {Layout elements}                |
|                                  |
+----------------------------------+
```

<!-- Image references (after feature directory is created): -->
<!-- ![{Description}](assets/{filename}.png) -->

<!-- Generate FR/NFR/US IDs by running: node ${CLAUDE_PLUGIN_ROOT}/shared/skills/id-generation/scripts/generate-id.js {count} -->

## Functional Requirements

> Written in EARS syntax. Each requirement has a Fit Criterion and links to use cases.

**FR-XXXX** `When {trigger}, the system shall {response}.`
Fit Criterion: Given {precondition}, {measurable outcome that proves this is satisfied}.
Linked to: UC-XXXX

**FR-XXXX** `While {precondition}, the system shall {response}.`
Fit Criterion: {measurable condition}.
Linked to: UC-XXXX

**FR-XXXX** `If {trigger}, then the system shall {response}.`
Fit Criterion: {measurable condition}.
Linked to: UC-XXXX

## Non-Functional Requirements

**NFR-XXXX** Performance: `When {trigger}, the system shall {response} within {threshold} at {percentile}.`
**NFR-XXXX** Security: `The system shall {security behavior}.`
**NFR-XXXX** Reliability: `When {failure condition}, the system shall {recovery behavior}.`

## Acceptance

> The feature is complete when all of the following are true:

- All use cases have Gherkin scenarios passing
- All scenarios include side effect assertions
- Architecture.md diagrams reflect the built system
- FEATURES.md status is `implemented`
