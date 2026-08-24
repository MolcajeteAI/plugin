---
name: change-request
description: >-
  The request.md format and its apply rules. A change request is the one
  artifact authoring produces and the whole human review surface: every
  proposed spec, interface, and data edit, organized per module, with fixed
  Additional Notes and Examples subsections per change. The base branch's
  specs stay untouched until the CLI applies the request on the run branch.
  Loaded by /m:spec, /m:change, /m:fix, and /m:cover.
---

# The Change Request

`/m:spec`, `/m:change`, and `/m:fix` do not edit the spec tree. They write `request.md` — every proposed edit, organized per module — and the base branch's specs stay untouched. The human approves the request; the execution applies it, on the run branch, before any task runs. Until the run merges, the entire change — specs included — is reversible by deleting a branch.

This replaces editing in place, deliberately. Under the request model the base branch's spec tree always describes shipped code, an abandoned change is a deleted branch, and one merge delivers specs, tests, and code together.

The request is written for a scanner, not a reader. Tables and diagrams first, prose only where a decision needs a why. Every identifier follows the writing-style skill: name first, identifier in parentheses, identifier is a link to its anchor.

## Where It Lives

```
specs/changes/{change-id}/request.md
```

The authoring command creates the change directory and its ID — `{YYYYMMDDTHHMMSS}-{slug}`, timestamp from the clock (`date -u +%Y%m%dT%H%M%S`), never composed — and writes `request.md` into it, plus an `assets/` subdirectory when the change carries user-provided images (see **The UI Is Contract Content**). Everything else in the directory (`plan.json`, `decisions.md`, `validation/`, `report.md`) is the CLI's, written at execution time.

The template is [request-template.md](./templates/request-template.md). Fill it; never compose the shape from prose memory.

## The Sections

The sections are fixed. First:

**1. Features and modules** — a table: each feature the change touches, and the module that owns each touched part.

Then, grouped **per touched module**, four sections in this order:

**2. The specs** — for every use case, scenario, functional requirement, and non-functional requirement: a new item is shown whole and marked new; a changed item is shown as before and after; a removed item is marked removed, with what it used to do stated so the loss is a decision and not an accident. These diffs are authoritative — the apply step executes exactly them. New and changed items carry their `<a id>` anchors in the diff, exactly as they will land in the spec files.

**3. The interface** — the INTERFACE.md diff — new elements, changed signatures, removed elements — plus the Mermaid class diagram of the surface as it will be, including every type an element consumes or returns and each type's properties with their responsibilities.

**4. The data layer** — every table the change touches — and every table the feature merely reads, because understanding a feature means seeing all the data it uses. Expressed as the Mermaid entity-relationship diagram, every field carrying its responsibility, changes marked and unchanged tables kept for context.

**5. The flows** — a Mermaid sequence diagram per changed flow, showing which module calls which, through which interface element.

Closing the request, one cross-module section:

**6. Module relationships** — one diagram of the touched modules and their allowed interactions, rendered as a Mermaid class or graph diagram per the Mermaid-only convention. A charter amendment the change needs (a new responsibility, a new `Depends on` entry) appears here as a diff, with its why.

## Additional Notes and Examples — Per Change

Every change entry in the request — each use case, scenario, requirement, and interface diff — closes with two fixed subsections. They are present even when empty, so there is always an obvious place to write:

```markdown
### Additional Notes

- None

### Examples

- None
```

Both carry the human's own words, and both are inputs to the run, not decoration.

A **note** is a clarification, and it is the one part of the request meant to be edited after the first writing — an afterthought is a normal note. Notes are not applied to the specs. They are instructions to the run: the planning session reads every note, and a note flows into the `rationale` of the tasks that implement its change. Edits count until the run is triggered, because the apply-and-plan phase reads the request as it is at that moment.

An **example** pins exact values and carries a tag — `E-001`, `E-002`, sequential within the request. An example is never wasted: **every example becomes test material**. The planner assigns each example to a task through the task's `examples` field, the builder turns it into a fixture or an assertion using the example's exact values, and the final verification treats an example no test asserts as a finding. The scenario states what happens; the example states the exact values it happens with.

## The UI Is Contract Content

When a change involves a graphical interface, the spec diffs in section 2 carry **ASCII art mockups** — the layout and element hierarchy of every screen the change touches, in fenced blocks, exactly as the feature-authoring skill defines for `## UI` sections and the usecase-authoring skill defines for in-scenario `**UI:**` blocks. The mockup is reviewed like any other diff: the human sees how the screen is going to look and corrects it before the run starts.

The mockups are not decoration, and they are not disposable examples. Three rules bind them, mirroring how notes and examples flow:

- **The apply step lands them verbatim.** A UI block in a spec diff reaches the spec tree character-for-character, like every other diff line.
- **They flow into the build.** Screen names, fields, and labels in a mockup are the vocabulary of the tasks that build the UI — the planning session carries them into the tasks' `contracts` and `rationale`, and the builder implements what the mockup shows.
- **The final verification checks UI conformance.** Every screen the applied specs mock up must exist in the built UI with the elements the mockup names. A mocked-up element no code renders is a finding.

**High-definition images and other assets travel with the request.** The authoring command copies user-provided files into `specs/changes/{change-id}/assets/` — descriptive names per the feature-authoring skill's Asset Management rules — and the request's diffs reference them there. The apply step copies each referenced asset into the owning feature's `specs/features/{module}/FEAT-XXXX-{slug}/assets/` directory and rewrites the landed reference to point there. `/m:cover`, which writes the spec tree directly, keeps copying assets straight to the feature folder.

## Retired Scenarios

When the change retires a scenario (`/m:change` only), the spec diff marks it **retired** — stating what it used to assert — so the planning session can populate the `retires` list of the task that deletes its tests and code. A scenario the request does not mark retired is never deleted.

## The Apply Rules

The CLI's apply step executes the request on the run branch, before any task runs. The rules bind both sides — the author writes a request that can be applied mechanically, and the applier adds nothing:

1. **The diffs are authoritative.** The apply step lands exactly the befores-and-afters the request shows — same wording, same anchors, same IDs. No paraphrase, no improvement.
2. **Apply is complete.** Every diff in sections 2, 3, 4, and 6 lands: the UC files, INTERFACE.md, DATA.md, and the MODULES.md charter. Section 5's flow diagrams are context, not edits.
3. **Notes are never applied.** They flow into task `rationale` at planning, nothing else.
4. **Changelog entries are written at apply time**, per the uc-log skill: one `pending` entry per touched UC module-instance, carrying the originating command's token and the change ID.
5. **Statuses are written at apply time**, per the status-rollup skill: new UCs `pending`, modified previously-`implemented` UCs `pending`, features re-rolled.
6. **Assets land with the diffs.** Every asset the request references under `specs/changes/{change-id}/assets/` is copied into the owning feature's `assets/` directory, and the landed reference points at the feature-relative path. An asset the request references but the change directory does not hold is an apply error.
7. **One commit.** The whole application is the run branch's first commit, so "the request was applied" has exactly one marker a resumed run can check.
8. **Applied means fully specified.** If a diff cannot be applied mechanically — an anchor missing, a before-text that does not match, a referenced asset missing — the apply step stops and reports which entry is ambiguous. It never guesses.

## `/m:cover` — The One Exception

`/m:cover` documents shipped behavior, which changes no contract, so it writes the spec tree directly — features, UCs, INTERFACE.md rows, DATA.md tables extracted from code. Its `request.md` is a list of the files to spec and test, so the run knows its scope. Everything else in this skill — the directory, the ID, the notes and examples subsections — applies to cover requests unchanged.
