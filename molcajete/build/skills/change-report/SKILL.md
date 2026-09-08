---
name: change-report
description: >-
  Owns the change report /m:build fills at its report step. The body is the
  change-description walk at full depth; this skill adds the report-only tail:
  the New IDs table, the interview decisions, and the closing
  Done / Not done / Next step. The report is printed to the screen and appended
  to the change-request file.
---

# Change Report

`/m:build` reads this skill at its report step. **Read `${CLAUDE_PLUGIN_ROOT}/shared/skills/change-description/SKILL.md` first** — it owns the body of the report: the atoms, the layout and diagram rules, and the walk assembly. This skill adds only what a build report carries beyond a change description.

The output lands twice, identically: printed to the screen, and appended to the change-request file as its final `## Report` section. The double write is deliberate — the file is the durable record, the screen is the delivery.

## Assembly

The report is the `change-description` walk at **full depth**, with three adjustments and a tail:

1. **The Lead opens in the first person.** `I {built | changed | fixed} {what, in product language}.` — then the one to three sentences the Lead atom defines.
2. **The spec deltas come from the run's own record.** Fill each `Before` row from the change-request file's `## Replaced spec text` section, verbatim. For a new use case or a new feature: its name, its one-line description, and the IDs of the scenarios under it — never the whole file.
3. **The spec blocks are exempt from the output budget.** Every edited spec element appears. Completeness outranks brevity there, and nowhere else.
4. **The screen the user approved at the interview renders in its owning unit's `**UI**` block** — the walk's UI atom, not a tail section.

Then the tail, in this order, after the walk's `## Architecture` section. Omit an empty section entirely, per the layout rules.

````markdown
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

## Example: the tail

The body — lead, change map, the walk units with their UI sketches, the tail sections of the walk — follows the worked rendering the `change-description` skill points to. The report tail under it reads like this, for a run that added a roster CSV export:

````markdown
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
