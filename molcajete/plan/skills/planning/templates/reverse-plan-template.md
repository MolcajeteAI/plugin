<!--
Reverse plan.md template — companion to plan.json, produced by /m:reverse-plan.

Only write this file when at least one scoped UC has a materially-blocking
REC entry in its `UC-XXXX-{slug}-TEST-ISSUES.md` sibling. If no such REC
exists (or all have been resolved in the feature's
ARCHITECTURE.md#Testing Decisions), skip MD generation entirely.

This file lists scenarios by ID + short description and details the
prerequisites that `molcajete build` must satisfy before it can run the
Gherkin scenarios. Regenerated from plan.json + TEST-ISSUES source files
on every plan write; never hand-edit.

Do NOT include execution state fields: status, summary, errors,
estimated_context, depends_on.
-->

# {plan.title} — Reverse Plan

## Context

Wiring BDD step definitions to existing code for {N} scenario(s) across
{M} use case(s). This file exists because testability prerequisites must
be resolved before `molcajete build` can run the scenarios.

## Scenarios to wire

<!--
ID + one-line description only, derived from each task's scenario field and
the matching Scenario line in the .feature file. NO full Gherkin body.
-->

- `SC-XXXX` — {one-line scenario summary} · UC: [UC-XXXX](../../../prd/modules/{module}/features/FEAT-XXXX-{slug}/use-cases/UC-XXXX-{slug}.md)
- `SC-YYYY` — {...}

## Global prerequisites

<!--
Only render this section when at least one REC is classified as global
(no Scenario field, or same area appears across ≥2 scoped UCs).
Global RECs are absorbed into T-001 as sub-tasks in plan.json.
-->

### PRE-G-NN: {short title}

- **Source:** [{UC-XXXX-...-TEST-ISSUES.md}](../../../prd/modules/{module}/features/FEAT-XXXX-{slug}/use-cases/UC-XXXX-{slug}-TEST-ISSUES.md) / REC-NNN
- **Category:** {fixture | selector | mock | injection | environment | data-seed}
- **Why it blocks tests:** {1–3 sentences}
- **Required changes for `molcajete build`:**
  - {file/change 1}
  - {file/change 2}
- **Maps to task:** T-001 (infrastructure absorbed, per planning skill)

## Per-scenario prerequisites

<!--
Only render this section when at least one REC is scenario-local.
Group by scenario ID. Each REC links back to its source TEST-ISSUES file.
-->

### SC-XXXX

- **PRE-SC-NN** — {short title} · [REC source](../../../prd/modules/{module}/features/FEAT-XXXX-{slug}/use-cases/UC-XXXX-{slug}-TEST-ISSUES.md) · Category: {…}
  - Why it blocks: {…}
  - Required changes: {…}
  - Maps to task: T-NNN
