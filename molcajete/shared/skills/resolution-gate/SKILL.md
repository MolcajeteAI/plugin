---
name: resolution-gate
description: >-
  Rule that forbids an unresolved item in any document Molcajete generates —
  analyze first, then ask, then write. Defines the banned-marker vocabulary the
  spec guard hook enforces, the difference between a hole and a decided default,
  the fixed-category analysis sweep, the relevance filter and the question cap,
  the batched ask, and the halt-and-escalate rule for headless runs. Loaded by
  /m:spec, /m:cover, /m:fix, /m:change, and /m:plan.
---

# Resolution Gate

## The Rule

**Analyze first. Then ask. Then write.**

No document Molcajete generates carries an unresolved item. The command puts every open
decision to the user before the file exists. It never puts one inside the file.

The order is fixed:

1. **Analyze** — sweep the categories in **The Analysis Sweep**. Mark each one Clear, Partial,
   or Missing.
2. **Ask** — write one Markdown brief, then make one batched `AskUserQuestion` call.
3. **Write** — put each answer into the section it belongs to, as normal content.

A command that cannot finish step 2 does not run step 3. It writes nothing for that entity.

The rule binds every file a Molcajete command creates or edits under `specs/`. That includes
`REQUIREMENTS.md`, `UC-XXXX-{slug}.md`, `ARCHITECTURE.md`, `USE-CASES.md`, `FEATURES.md`, and
`specs/plans/<plan-id>.md`.

## Why

A Molcajete spec is not a draft. `/m:plan` reads it and `/m:build` executes it, so it is
baselined the moment it is written. A hole in it is a defect, not a work-in-progress state.

The `principles` skill already gives the reason: "Specs, plans, comments, and reports are read
by the next AI agent with no back-channel. It cannot ask what an ambiguous sentence meant, so
it guesses."

The requirements standards agree. IEEE 830-1998 §4.3.3.1 says that any specification which uses
the phrase "to be determined" is not a complete specification. ISO/IEC/IEEE 29148:2018 §5.2.6
bars every TBD, TBS, and TBR clause from a complete set of requirements.

The sweep is not decoration. Models find gaps badly when they free-associate. Published
measurements show the hit rate falls from roughly one gap in three, to almost none, as the
number of gaps in one document grows. A fixed category list finds what free association misses.
That is why step 1 runs before step 2.

## A Hole Versus a Decided Default

These two look alike. They are opposites. Keep them apart.

A **hole** is a decision that nobody made. It is banned in every artifact, with no exception.

A **decided default** is a decision the user made, written with its reasoning. It is normal
content, and it belongs in the document.

| Part | Required | Example |
|------|----------|---------|
| Value | yes | `30 days` |
| Reason | yes | it matches the session lifetime already set in `FEAT-0Fy0` |
| Provenance | yes | the user chose it when this use case was written |

Write all three parts as one sentence, in the section the value belongs to:

> The refresh token expires after **30 days**. This matches the session lifetime already set in
> `FEAT-0Fy0`. The user confirmed the value when this use case was written.

All three parts are mandatory. A value with no reason is a guess. A value with no provenance is
a guess that the reader will trust. Two parts out of three is a hole.

**A decided default never carries a marker word.** `TBR: 30 days` is still banned. Molcajete
records the decision. It never records the fact that a decision was once open.

## Banned Markers

Tier 1 and Tier 2 are the exact vocabulary of the `spec-resolution-guard` hook that ships with
this plugin. The hook greps these and nothing else, so the hook and this skill always agree.
Never add a marker here without adding it to the hook.

### Tier 1 — the hook denies these

| Marker | Match |
|--------|-------|
| `NEEDS CLARIFICATION` | case-insensitive, with an optional `_` or `-` between the words |
| `TBD` | uppercase, word-bounded |
| `TBS` | uppercase, word-bounded |
| `TBR` | uppercase, word-bounded |
| `FIXME` | uppercase, word-bounded |

### Tier 2 — the hook asks the user

These strings are sometimes real spec prose and sometimes a hole. A person decides.

| Marker | Match |
|--------|-------|
| `TODO` | word-bounded. Exempt in any `CHANGELOG.md`, and exempt on a line that is exactly `TODO:` |
| `to be determined` / `decided` / `defined` / `specified` / `resolved` | case-insensitive |
| `???` | three or more question marks in a row |

The `TODO` exemption is mandatory. The `uc-log` skill makes `TODO:` the literal section header
of every use case changelog, and every lifecycle command writes those files.

### Tier 3 — you check these yourself

The hook ignores Tier 3. These words carry real meaning in normal English, so a regex on them
produces more noise than signal. Read each one in place during `G5`.

`unclear`, `unknown`, `undecided`, `ambiguous`, `maybe`, `probably`, `possibly`, `if needed`,
`as appropriate`, `for now`, `later`, `open question`, `we should decide`, `not sure`.

If the word hides a decision, it is a hole, and you resolve it. If it states a fact — "the API
returns 404 for an unknown user" — you keep it.

Two structural shapes carry no marker word and are still holes:

- **An empty required section** — a heading with no content before the next heading.
- **An empty required table** — a header row and a separator row with no data rows.

Record a section that does not apply. Never leave it blank:

> **Not applicable:** this feature emits no events, so it has no event topology.

Two tables are exempt, because a command fills them later: `## Testing Decisions` in
`ARCHITECTURE.md`, and any `ARCHITECTURE.md` table the architecture skill's **Table Filling**
section allows to stay empty.

### Strings that look banned and are not

`XXX` is **not** a marker. `FEAT-XXXX`, `UC-XXXX`, `SC-XXXX`, and `FR-XXXX` are the plugin's own
ID placeholders, and a rule against `XXX` would block every template.

`not available` in `specs/TECH-STACK.md` is a detected fact about the host project, and the
setup skill requires that exact word. `—` in a table cell is a value when the owning skill
defines it as the empty value.

## The Analysis Sweep

Read the input, the loaded specs, and the code in scope. Mark every category Clear, Partial, or
Missing.

| # | Category | The gap it finds | Where the answer lands |
|---|----------|------------------|------------------------|
| C1 | Functional scope | which behaviors are in, and which are named out | UC scenarios, `## Non-Goals` |
| C2 | Actor and permission | who does it, and who may not | UC `actor`, `specs/ACTORS.md` |
| C3 | Trigger and precondition | what starts the flow, and what must hold first | UC `Trigger`, UC `Preconditions` |
| C4 | Domain and data | entities, fields, constraints, retention, identity | `## Data Model` |
| C5 | Interaction and UI | what the actor does, and what the actor sees | UC `Steps`, UC `Outcomes`, `## UI` |
| C6 | Side effects and events | what changes, and what explicitly does not | UC `Side Effects`, `## Event Topology` |
| C7 | Failure and edge handling | what happens when the flow goes wrong | error scenarios, `## API Surface` |
| C8 | Non-functional quality | limits, latency, security, idempotency | `REQUIREMENTS.md` NFRs |
| C9 | Integration and external dependency | which outside system is called, on which contract | `## Integration Points` |
| C10 | Test feasibility | whether a scenario can be driven end to end | `## Testing Decisions` |
| C11 | Terminology | every domain noun defined once, and used one way | `specs/GLOSSARY.md` |
| C12 | Acceptance signal | how the team knows the work is done | Fit Criteria, `## Acceptance Criteria` |

The three marks:

- **Clear** — the answer is in the input, in a loaded spec, or in the code you read. Cite where.
- **Partial** — an answer exists, and it leaves a real choice open.
- **Missing** — no answer exists anywhere you looked.

Only Partial and Missing can become questions. Clear never does.

**An inferable answer is Clear, not Missing.** If only one module exists, use it. If
`specs/ACTORS.md` lists one actor for this domain, use it. Record the inference and its source
in the document, which makes it a decided default. This is the main volume control, and it is
the same rule the `asking-questions` skill states in "When Not to Ask at All".

Each command sweeps the categories it owns:

| Command | Categories |
|---------|-----------|
| `/m:spec` | C1 to C12 |
| `/m:cover` | C1 to C12, collected across the whole scan |
| `/m:fix` | C1, C3, C6, C7, C10, C12 |
| `/m:change` | C1 to C9, and C12 |
| `/m:plan` | C4, C6, C7, C9, C10 — the spec settled the rest |

## The Relevance Filter and the Cap

The sweep finds more items than a person wants to answer. Three controls stop a command from
becoming an interrogation.

**Filter.** Drop every Partial or Missing item unless the answer changes one of these three:

1. what the implementation does,
2. what a test asserts,
3. which file the work touches.

An item that changes none of the three is a detail, not a gap. The writer decides it.

**Deduplicate.** Read what already exists and drop what it answers: `## Testing Decisions` for
C10, `specs/GLOSSARY.md` for C11, and the sibling specs for the rest. Never ask a question the
project already answered.

**Group.** Items that share one decision are one question. Three files that call the same
unsandboxed payment API are one question about that API. They are never three questions.

**Cap.** One gate run per command invocation. Five questions per round. Two rounds maximum,
because round one often answers what round two would have asked.

If items survive round two, stop. Write only the entities whose items are all resolved. Name
every entity you did not write in the report, with the item that blocked it. Tell the user to
run the command again on a narrower scope. Never write a partial entity, and never drop an item
in silence.

## The Batched Ask

The `asking-questions` skill owns the two-move rule, the brief's shape, the 250-word budget, and
the field limits. Follow it. This section adds only what a gate run needs.

**One brief covers the whole round.** Write it before the tool call. It carries, in this order:

1. one sentence naming what the command is about to write,
2. a table of the open items — category, the item in one line, and the consequence of each
   choice,
3. the recommended answer for each item, with one clause of reasoning,
4. the escape-hatch line.

Name the file and the entity in every row. The user may have watched a long scan and holds no
context.

**One tool call carries the round.** `AskUserQuestion` takes up to four questions. Chain a
second call when the round has five.

**After the answers arrive**, write each answer into the section it belongs to, as normal prose.
Do not add a `## Clarifications` log, and do not annotate the section with the fact that it was
once open. A resolved item reads exactly like an item that was never open.

## Headless and Non-Interactive Runs

No user is present, so step 2 cannot run. Step 3 therefore never runs for the affected entity.

1. Do not guess. Do not write a hole. Do not write the entity.
2. Write one escalation file at
   `.molcajete/escalations/resolution-{command}-{YYYYMMDDTHHMMSS}.md`. Record the sweep result,
   every surviving item with its category and its consequence, the recommended answer for each,
   and the entities you did not write.
3. Write the entities whose items are all resolved, exactly as an interactive run would.
4. Print the escalation path in the report, then halt.

## How This Meets `asking-questions`

That skill lists three reasons not to ask. Two of them change here.

| Reason | How it applies to a gate item |
|--------|-------------------------------|
| Headless and non-interactive sessions | **Overridden.** A silent decision is an unrecorded decision, which is the defect this skill exists to stop. Halt and escalate instead. |
| Prohibitions declared by a skill | **Narrowed.** No skill may forbid a question about an item this skill marked Partial or Missing. A skill may still say *when* to ask. |
| When the answer is inferable | **Unchanged, and load-bearing.** An inferable answer is Clear, so it never reaches the filter. |

## The Procedure

Run this before you write or edit any file.

**G1 — Sweep the fixed categories.** Walk the categories in scope for this command. Mark each
one Clear, Partial, or Missing, and cite the source for every Clear. Never free-associate. The
table is the checklist.

**G2 — Drop what is already decided.** Read `## Testing Decisions`, `specs/GLOSSARY.md`, and the
sibling specs. Any item they answer becomes Clear.

**G3 — Filter, group, and rank.** Apply the three-part relevance test. Merge items that share
one decision. Rank what remains by impact times uncertainty, then keep the top five.

**G4 — Ask the round.** Write one brief, then make one batched `AskUserQuestion` call per four
questions. Run a second round only if items survive. Stop after two rounds.

**G5 — Write, then check.** Write each answer as normal content in its own section. Read the
file back and check it against **Banned Markers** — all three tiers, and both structural shapes.
A hit means `G1` missed something. Resolve it before the file is written, never after.
