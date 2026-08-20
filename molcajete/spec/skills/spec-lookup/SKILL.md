---
name: spec-lookup
description: >-
  Shared machinery for the spec-query commands (/m:desc, /m:ids, /m:prompt). Owns
  the read-only prerequisite gate, the ID taxonomy that maps each prefix to its
  definition site, resolve-by-ID with its miss and partial branches, resolve-by-
  keyword with glossary expansion and two-tier ranking, and context assembly at two
  depths. Reads the spec tree; never writes to it.
---

# Spec Lookup

The querying family — `/m:desc`, `/m:ids`, `/m:prompt` — all read the spec tree to answer one of two questions: what does this ID mean, or which IDs cover this capability. This skill owns that machinery. It never edits a spec, a changelog, or a status field.

The calling command supplies what is genuinely its own: its argument parsing, its refusal string, the context depth it needs, its report layout, and its hand-off line.

## Prerequisites

Verify before anything else:

- `specs/PROJECT.md` and `specs/MODULES.md` exist.
- `specs/features/` holds at least one `FEAT-*` folder.

If any is missing, refuse and stop:

> This is not a Molcajete project (no `specs/PROJECT.md` / `specs/MODULES.md`). The query commands read the spec tree — run `/m:setup` to initialize the project foundation first.

## ID Taxonomy

Each prefix has one definition site. Find it with the pattern named here.

| Prefix | Definition site | Find pattern |
|--------|-----------------|--------------|
| `FEAT` | `REQUIREMENTS.md` frontmatter | Glob `specs/features/*/FEAT-XXXX-*/` |
| `UC` | `UC-XXXX-{slug}.md` frontmatter | Glob `specs/features/*/FEAT-*/UC-XXXX-*.md` |
| `SC` | Inline heading in the UC spec file | Grep `^### SC-XXXX:` across `specs/features/*/FEAT-*/UC-*.md` |
| `FR` | `REQUIREMENTS.md` → Functional Requirements | Grep `\*\*FR-XXXX\*\*` across `specs/features/*/FEAT-*/REQUIREMENTS.md` |
| `NFR` | `REQUIREMENTS.md` → Non-Functional Requirements | Grep `\*\*NFR-XXXX\*\*` in the same files |
| `US` | `REQUIREMENTS.md` body | Grep `\*\*US-XXXX\*\*` in the same files |
| `ADR` | `ARCHITECTURE.md` → Architecture Decisions | Grep `\*\*ADR-XXXX:\*\*` across `specs/features/*/FEAT-*/ARCHITECTURE.md` |

**Anchor every pattern.** A bare `grep -r "SC-XXXX"` also hits plan `**Covers:**` lines, `ARCHITECTURE.md` Code Map rows, and `// SC-XXXX` code comments. Those are neighbors of the definition, not the definition. Depth 2 fetches them on purpose; a resolve step must not confuse them for the source.

The `UC` glob is the same one `spec-revision` uses for the write-side module fan-out. The difference is what happens next: there the user narrows the set before an edit, here every instance is reported.

## Resolve by ID

Validate the token against `^(FEAT|UC|SC|FR|NFR|US|ADR)-[0-9A-Za-z]{4}$`, then run that prefix's find pattern.

**Case is significant.** IDs are base-62, so `0KTg` and `0ktg` are different IDs. Match case-sensitively first. Retry case-insensitively only when that returns nothing, and report the corrected ID rather than accepting the typed one.

**When the token carries no prefix** (`/m:desc 3Z2L`), run all seven patterns and report every prefix that matches.

### What to read per prefix

- **FEAT** — `REQUIREMENTS.md` frontmatter, the objective blockquote, Non-Goals, and the `FR`/`NFR` list. Read the whole of `USE-CASES.md`; it is short. The curated description is the row `^| FEAT-XXXX |` in `specs/FEATURES.md`, and the domain is the nearest `^## ` heading above that row.
- **UC** — the UC spec file: frontmatter, the objective blockquote, Preconditions, Trigger, and every `### SC-` heading. The module is the path segment under `specs/features/`, and the parent feature is the enclosing `FEAT-*` directory. The curated description is the row `^| UC-XXXX |` in that feature's `USE-CASES.md`.
- **SC** — take the line number from the grep, then read with an offset. The block ends at the next `^---` or the next `^### SC-`.
- **FR / NFR / US** — the definition is the bold-label line plus the two that follow it: `Fit Criterion:` and `Linked to:`. The `Linked to:` line names the child UCs.
- **ADR** — the bold-label line plus the paragraph under it. An ADR has a parent feature and no children.

### The three failure branches

**Multiple hits.** For `FEAT` and `UC` this is normal — one instance per module, same ID, module-scoped content. Report every instance and say so plainly. For `SC`, `FR`, `NFR`, `US`, and `ADR` it is a duplicated ID. Report it as a spec defect and name both files.

**Partial ID** (`UC-3Z2`). Treat the fragment as a prefix and glob it. One hit resolves, and the report states the interpretation. Two to ten hits print the candidate list and stop — in a read-only command the candidate list is the answer, so do not ask a question. More than ten hits says the fragment is too short.

**Not found.** Three steps, in order:

1. Retry the pattern case-insensitively.
2. Glob the same prefix and compare the four characters. Report any neighbor that differs by one character.
3. Grep `specs/` and `specs/plans/` for the raw string. A plan `**Covers:**` line or a Code Map row that names an ID with no defining heading is itself the answer worth printing: the ID is referenced but nothing defines it.

If all three find nothing, say so and point to `/m:ids <keywords>` for a search by description.

## Resolve by Keyword

Four passes turn freeform text into a ranked ID set.

**Read the index yourself. Do not dispatch a subagent.** The searchable index layer — `specs/FEATURES.md` plus every `USE-CASES.md` — is a few hundred lines on a real project. A subagent costs a full turn and returns a summary, and the summary discards the module instance the query needed. That loss is the exact failure these commands must not commit.

Measure before you skip a pass. If `cat specs/FEATURES.md specs/features/*/FEAT-*/USE-CASES.md | wc -l` exceeds 2000 lines, skip Pass 1 and rely on Pass 2.

### Pass 0 — expand through the glossary

Reduce the query to 2-6 content terms. Expand each through `specs/GLOSSARY.md`, adding the canonical name and any synonym the glossary records.

This one file read is the highest-value defense against a miss. A query for "odds calibration" finds nothing when the specs say "probability normalization", and only the glossary bridges that.

### Pass 1 — sweep the index

Read `specs/FEATURES.md` and every `specs/features/*/FEAT-*/USE-CASES.md`. These hold one human-written sentence per feature and per UC — the highest signal per byte in the tree. Score every row.

### Pass 2 — grep the bodies

Per expanded term, run two case-insensitive greps:

- `specs/features/*/FEAT-*/UC-*.md`
- `specs/features/*/FEAT-*/REQUIREMENTS.md`

Do not grep `ARCHITECTURE.md`, `CHANGELOG.md`, or `specs/plans/` in this pass. They restate spec text, so they inflate the result set without adding a match the first two files missed.

### Pass 3 — score

| Signal | Weight |
|--------|--------|
| Term in a FEAT name or a UC name | strongest |
| Term in a UC objective, or in an index Description cell | strong |
| Term in an `### SC-XXXX:` scenario name | strong |
| Term in `FR` / `NFR` requirement text | medium |
| Term only in scenario Steps, Given, or Side Effects | weak |
| Count of distinct expanded terms hitting the same entity | multiplier |

The multiplier outranks the per-signal weights. An entity hit by both "odds" and "calibration" beats an entity that says "calibration" five times.

### Pass 4 — cut

Two rules. Both are required, and they solve different halves of the problem.

**Module completeness overrides the cutoff.** For every `UC-XXXX` that survives, re-glob `specs/features/*/FEAT-*/UC-XXXX-*.md` and include every instance — including an instance that scored zero. A second module states the same use case in different words, so it never has to rank well; it arrives with its sibling. Grouping the output by module is a consequence of this rule, not a layout choice.

**Two tiers, never suppression.** A hit on a name, an objective, or a scenario name goes in the main output, capped at 10 entries. A hit only on body text collapses to one trailing line:

```
Also mentions "calibration": UC-4A2P, UC-51KX, FR-3Z2Z.
```

No description and no path on that line. A weak match is demoted, never dropped — a dropped match is a miss.

When more than 10 entries qualify for the main output, print the top 10 and the total count. Never truncate the module expansion of an entry that made the cut.

**Zero hits.** Say so, print the three closest entities by name similarity, and note that the capability may exist in code with no spec.

## Context Assembly

Two depths. The calling command names the one it needs.

### Depth 1

- Name, and the one-line description from the index row.
- `status` from frontmatter, and the module.
- The spec file path.
- Scenario names, for a UC.

### Depth 2

Depth 1, plus:

- **Parent chain** — the SC's UC, the UC's feature, the feature's domain.
- **Implementation files** — read the feature's `ARCHITECTURE.md` **Code Map** table first. That table maps each UC and SC to `file:function()`, and the `architecture` skill calls it the primary bridge between specs and code. Grep for `// UC-XXXX` or `// SC-XXXX` traceability comments only when the Code Map has no row for the ID.
- **Integration test** — the canonical path is `{module.Tests}/{feature-dir}/{uc-dir}.{ext}`, where `Tests` comes from the module's row in `specs/MODULES.md`. Report the path and whether the file exists.
- **Latest change** — the newest entry in `specs/features/{module}/FEAT-*/UC-XXXX-*/CHANGELOG.md`. Its `reason` states why the UC last moved.

## Naming an Entity

Two forms. Use the one the surrounding container calls for.

**In a heading**, write the ID and the name separated by a middle dot:

```
## UC-3Z2L · Send Email OTP
```

**In a table cell or a list entry**, write the ID in backticks followed by the name:

```
| `UC-3Z2L` Send Email OTP | Receives a passcode at their registered address | implemented |
```

Every other field — status, module, parent, spec path, test path — is a short fact, so it belongs in a table column rather than strung onto the same line. See the `output-economy` skill's **The Four Containers**.

Each command owns its own layout beyond this. `/m:desc` goes deep on a few IDs, `/m:ids` goes shallow on many grouped by module, and `/m:prompt` reports the set as one table under the command it emits.
