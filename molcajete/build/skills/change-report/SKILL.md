---
name: change-report
description: >-
  Owns the change report /m:build fills at its report step: the fixed section
  order, the before/after tables for interface, data layer, event, and
  configuration changes, the Before/Now/Why blocks for spec edits, and the
  closing Done / Not done / Next step. The report is printed to the screen and
  appended to the change-request file.
---

# Change Report

`/m:build` reads this skill at its report step and fills the template below. The output lands twice, identically: printed to the screen, and appended to the change-request file as its final `## Report` section. The double write is deliberate — the file is the durable record, the screen is the delivery.

The report answers one question: **what changed, before and after, on every surface that matters** — the process, the interfaces, the data, the events, the configuration, and the specs. The reader judges the change from the report alone, without opening the diff.

## Section rules

- **Keep the order. Omit an empty section entirely.** A run with no data-layer change has no Data layer heading. Never write "none".
- **Name a thing before its ID.** Write "the roster screen (UC-YHJ9)", never a bare `UC-YHJ9`.
- **Before/after cells carry facts, not judgments.** "returned bool" and "returns `Settlement`" — the Why or Objective column holds the reason.
- **A new thing's Before cell is `—`.** A retired thing's After cell is `—`.
- **ASCII UI sketches are screen layouts, not diagrams.** The Mermaid-only convention governs diagrams; a layout sketch is the one carve-out, because Mermaid cannot draw one.
- **The spec-change section is exempt from the output budget.** Every edited spec element appears. Completeness outranks brevity there.

## The template

Fill every `{...}`. Drop every section with nothing to show.

````markdown
I {built | changed | fixed} {what, in product language}. {One to three sentences on what a person now sees.}

## How it works now

### Before

1. {step}
2. {step}

### Now

1. {step}
2. {step}

## Surfaced changes

### Interface changes

#### {service} — {model or object} (`{file}`)

| Method | Before | After | Objective |
| --- | --- | --- | --- |
| `{method}` | {behavior or —} | {behavior or new} | {what the change is for} |

#### {service} — API surface

| Method | Path | Handler | Before | After |
| --- | --- | --- | --- | --- |
| {VERB} | `{path}` | `{handler}` | {— or old} | {new or —} |

### Data layer

| Entity | Element | Before | After | Why |
| --- | --- | --- | --- | --- |
| {entity} | {field, constraint, or invariant} | {old or —} | {new or —} | {reason} |

### Events

| Event | Publisher | Payload | Condition | Consumers | Change |
| --- | --- | --- | --- | --- | --- |
| `{event}` | {publisher} | {payload} | {when} | {who} | new \| changed \| retired |

A changed event gets two rows, marked `(before)` and `(now)` after its name.

### Configuration

| Setting | Location | Before | After | Why |
| --- | --- | --- | --- | --- |
| `{setting}` | {file or env var} | {old or —} | {new} | {reason} |

## Spec changes

### {Feature name} (FEAT-XXXX)

{One-line description of the feature.}

#### {Element name} ({ID}) — {added | changed | retired}

**Before**
> {The old text. Omit this block for added.}

**Now**
> {The new text. Omit this block for retired; say instead what replaced it and where.}

**Why** — {the reason, in one or two sentences}.

For a new use case or a new feature: its name, its one-line description, and the IDs of the scenarios under it — never the whole file.

## UI

```
Before                         After
{ASCII layout}                 {ASCII layout}
```

## New IDs

| ID | Kind | Name |
| --- | --- | --- |
| `{ID}` | {Feature \| Use case \| Scenario \| Requirement \| Decision} | {name} |

## Decisions after the interview

| Fork | Chosen | Rejected, and why |
| --- | --- | --- |
| {the fork} | {option} | {each rejected option and its reason} |

The full decision log is in `{change-request file path}`.

## Done

{Full sentences. What works now, and the test count that proves it.}

## Not done

{Full sentences. What the run left out and why, including any failure proven pre-existing.}

## Next step

{One action, one sentence.}
````

## Example: an addition

A run that added a CSV export button to a roster screen.

````markdown
I built the roster export. A clinic administrator now sees an Export button on the roster screen and downloads the roster as a CSV file.

## How it works now

### Before

1. The administrator copies the roster rows by hand into a spreadsheet.

### Now

1. The administrator opens the roster and selects Export.
2. The system streams a CSV file with one row per doctor.

## Surfaced changes

### Interface changes

#### roster service — Roster (`app/models/roster.rb`)

| Method | Before | After | Objective |
| --- | --- | --- | --- |
| `to_csv` | — | new | give the export endpoint one place that owns the column order |

#### roster service — API surface

| Method | Path | Handler | Before | After |
| --- | --- | --- | --- | --- |
| GET | `/roster.csv` | `RostersController#show` | — | new, administrator-only |

## Spec changes

### Roster management (FEAT-0K3d)

Administrators maintain the clinic's doctor roster.

New use case: **Export the roster (UC-0K7a)** — an administrator downloads the roster as a CSV file. Scenarios: SC-0K7b, SC-0K7c.

## UI

```
Before                         After
+---------------------+        +---------------------+
| Roster              |        | Roster    [Export]  |
| Ana  | Dermatology  |        | Ana  | Dermatology  |
+---------------------+        +---------------------+
```

## New IDs

| ID | Kind | Name |
| --- | --- | --- |
| `UC-0K7a` | Use case | Export the roster |
| `SC-0K7b` | Scenario | A roster with doctors downloads as CSV |
| `SC-0K7c` | Scenario | An empty roster downloads headers only |

## Decisions after the interview

| Fork | Chosen | Rejected, and why |
| --- | --- | --- |
| Where the CSV is built | `Roster#to_csv` | A controller helper — the column order belongs to the model, and a second export surface would duplicate it. |

The full decision log is in `.molcajete/change-request/20260908T151200-roster-export.md`.

## Done

The export ships behind the administrator role. Three integration tests cover the two scenarios and the role refusal, and all three pass.

## Not done

Nothing was left out.

## Next step

Run the full test suite before you merge.
````

## Example: a change

A run that made a directory search narrow while the user types.

````markdown
I changed the doctor search. The directory now narrows while the administrator types, once the term reaches three characters, instead of waiting for a button press.

## How it works now

### Before

1. The administrator types a term and presses Search.
2. The system lists the doctors whose name contains the term.

### Now

1. The administrator types a term.
2. At the third character, the system narrows the list on each keystroke, 300 milliseconds after the last one.

## Surfaced changes

### Data layer

| Entity | Element | Before | After | Why |
| --- | --- | --- | --- | --- |
| Doctor | index on `name` | — | trigram index | a contains-search on each keystroke needs it to stay fast |

### Events

| Event | Publisher | Payload | Condition | Consumers | Change |
| --- | --- | --- | --- | --- | --- |
| `search.performed (before)` | directory controller | term | on button press | audit log | changed |
| `search.performed (now)` | directory controller | term, result count | on each narrowed list | audit log | changed |

### Configuration

| Setting | Location | Before | After | Why |
| --- | --- | --- | --- | --- |
| `search.debounce_ms` | `config/settings.yml` | — | `300` | one tunable place for the keystroke delay |

## Spec changes

### Doctor directory (FEAT-0Fy0)

Administrators find doctors by name in the directory.

#### The doctor search (FR-0Fy7) — changed

**Before**
> When a platform administrator submits a search term on the directory, the system shall list only the doctors whose name contains that term.

**Now**
> While a platform administrator types a search term on the directory, the system shall list only the doctors whose name contains that term, once the term reaches three characters.

**Why** — the administrator pressed a button to search, and now the list narrows while they type. The three-character floor keeps a one-letter term from scanning the whole directory.

## New IDs

| ID | Kind | Name |
| --- | --- | --- |
| `SC-0FyB` | Scenario | A two-character term does not narrow the list |

## Decisions after the interview

| Fork | Chosen | Rejected, and why |
| --- | --- | --- |
| Debounce length | 300 ms | 150 ms — fires mid-word for most typists and doubles the query load for no visible gain. |

The full decision log is in `.molcajete/change-request/20260908T163400-live-doctor-search.md`.

## Done

The live search ships with the three-character floor. Four integration tests cover the narrowed list, the floor, the debounce setting, and the audit event, and all four pass.

## Not done

The directory's Spanish locale file already carried the search copy, so no copy changed.

## Next step

Run the full test suite before you merge.
````

The two examples split the optional sections between them on purpose: the addition shows interface, API surface, a new use case, UI art, and section omission; the change shows the Before/Now/Why block, data layer, events, and configuration. Together they exercise every section once.
