---
name: id-generation
description: >-
  Rule enforcing canonical ID generation and permanent immutability for all
  entity identifiers (FEAT, UC, SC, FR, NFR, US, ADR). All IDs must be
  generated via the shared script — never compute an ID tag manually. The
  alphabet is digits and uppercase letters only. Once written, an ID never
  changes: never renumber, never reassign, never regenerate.
---

# ID Generation

All entity IDs in the spec use a 4-character timestamp-derived tag with a type prefix.

## The Alphabet — Digits and Uppercase Letters Only

An ID tag is 4 characters drawn from `0-9` and `A-Z` — `UC-9KC2`, `SC-9KC2-01`, `FEAT-3FA1`. Lowercase letters are forbidden in new tags.

Mixed case causes errors in exactly the readers this system serves. A person cannot see the difference between `0KTg` and `0KTG`. A model miscopies case silently. Every grep and every anchor is case-sensitive, and the identifier-is-a-link rule makes each ID an anchor target where one wrong letter is a dead link. Thirty-six symbols to the fourth power is 1,679,616 tags — capacity was never a reason for a larger alphabet.

Two rules govern the transition from the old mixed-case scheme:

- **New IDs use the new alphabet.** The shared script below already emits it. Nothing else about ID mechanics changes.
- **Existing IDs never change.** The immutability rule outranks the alphabet rule. A project keeps its mixed-case IDs forever — renaming an ID breaks every comment, anchor, and changelog line that carries it. Old and new IDs coexist; only generation is governed.

## Rule

**Always generate IDs by running the shared script. Never invent an ID, never compute a tag inline, and never use sequential numbers** — `FR-0001`, `UC-0002`, `NFR-0003` are wrong; `FR-3FA1`, `UC-9KC2`, `NFR-0L2X` are right.

```
node ${CLAUDE_PLUGIN_ROOT}/shared/skills/id-generation/scripts/generate-id.js [count]
```

- No argument: prints 1 ID code
- Numeric argument: prints N ID codes (one per line), each incrementing the timestamp by 1

The script outputs raw 4-character tags drawn from digits and uppercase letters (e.g., `3FA1`, `9KC2`, `0L2X`). The caller prepends the appropriate prefix.

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

## Immutability — An ID Never Changes

**Once an ID is written to a file, it is permanent.** No command and no skill may ever change it. This holds for every prefix in the table above, and it holds for the whole life of the entity.

An ID is generated from a timestamp. It is already unique, and the collision check above already proves it. **Renumbering can therefore never be necessary** — there is no gap to close, no clash to resolve, and no order to restore. Tidiness is not a reason. An ID that looks inconsistent next to its neighbours is still correct.

### What Breaks When an ID Changes

The ID is the only link between a spec and the code that satisfies it. Change it and every one of these silently points at nothing:

- Traceability comments in production and test files — `// FEAT-XXXX`, `// UC-XXXX`, `// SC-XXXX` (see the `principles` skill, 1.2 and 5.1).
- The `covers` list on every task in `plan.json`, which is the canonical machine-readable spec-to-task mapping.
- The diff-to-spec mapping the `change-review` skill performs for `/m:walkthrough`.
- The element rows in every module's `INTERFACE.md`, which map the public surface to spec IDs.
- The `<a id>` anchors above every spec heading, and every Markdown link that targets them.
- Every `CHANGELOG.md` entry, which the `uc-log` skill forbids rewriting.
- The `FEATURES.md` and `USE-CASES.md` rows, and the `UC-XXXX-{slug}.md` file and folder names.

Nothing raises an error. The traceability just stops being true.

### Forbidden

Never:

- Renumber IDs to make them sequential, contiguous, or ordered.
- Reassign an ID after an entity is deleted or retired. A retired entity's ID is spent forever and is never reused for a different entity.
- Regenerate an ID for an entity that already has one. Run the script only for entities that have no ID yet.
- Renumber the surviving `SC-XXXX` IDs after a scenario is added, retired, or reordered. Scenario order and scenario IDs are independent.
- Rewrite IDs while reordering rows in `FEATURES.md` or `USE-CASES.md`.
- "Correct" an ID because it looks wrong, looks inconsistent, or does not match its neighbours.
- Copy an ID from a peer module-instance into a different entity when propagating an edit across modules.

### Permitted

- The `{slug}` part of `UC-XXXX-{slug}.md` may change when the use case is renamed. The `UC-XXXX` part may not.
- A new entity always gets a newly generated ID, even when it replaces an entity that was just retired.

### Self-Check

After editing any spec file, compare the IDs present before the edit against the IDs present after it. Every ID that existed before must still exist, unchanged and character-for-character identical. New IDs may be added. No existing ID may be missing, altered, or moved to a different entity.

If an ID did change, restore it before you report the edit as done.
