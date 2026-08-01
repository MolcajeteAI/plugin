---
name: id-generation
description: >-
  Rule enforcing canonical ID generation for all entity identifiers
  (FEAT, UC, SC, FR, NFR, US, ADR). All IDs must be generated via the shared
  script — never compute base-62 manually.
---

# ID Generation

All entity IDs in the PRD spec use a 4-character timestamp encoded in base-62 with a type prefix.

## Rule

**Always generate IDs by running the shared script. Never invent an ID, never compute base-62 inline, and never use sequential numbers** — `FR-0001`, `UC-0002`, `NFR-0003` are wrong; `FR-0Fy0`, `UC-0KTg`, `NFR-0L2x` are right.

```
node ${CLAUDE_PLUGIN_ROOT}/shared/skills/id-generation/scripts/generate-id.js [count]
```

- No argument: prints 1 ID code
- Numeric argument: prints N ID codes (one per line), each incrementing the timestamp by 1

The script outputs raw 4-character timestamps encoded in base-62 (e.g., `0Fy0`, `0KTg`, `0L2x`). The caller prepends the appropriate prefix.

## Prefixes

| Prefix | Entity |
|--------|--------|
| `FEAT-` | Feature |
| `UC-` | Use Case |
| `SC-` | Scenario |
| `FR-` | Functional Requirement |
| `NFR-` | Non-Functional Requirement |
| `US-` | User Story |
| `ADR-` | Architecture Decision Record |

## Collision Check

Before using a generated ID, check existing IDs in the relevant file for the prefix:

| Prefix | Where to check |
|--------|----------------|
| `FEAT-` | `FEATURES.md` |
| `UC-` | `USE-CASES.md` |
| `SC-` | Scenario headings in the parent UC file |
| `FR-` / `NFR-` / `US-` | The feature's `REQUIREMENTS.md` |
| `ADR-` | The feature's `ARCHITECTURE.md` |

If a collision is detected, re-run the script — the timestamp will have advanced, producing a new code.
