---
name: output-economy
description: >-
  How much Molcajete says, on every surface it writes to — spec files, plans,
  review documents, on-screen reports, question briefs, and command output.
  Sets the content test, the three moves for an over-long unit, per-surface
  budgets counted in sentences and sections, and the cases where completeness
  outranks the budget. Pairs with writing-style, which governs how each
  sentence reads. Loaded by every command.
---

# Output Economy

Nobody asked Molcajete for a document. They asked for a result.

## The Rule

**Every artifact carries what its reader needs for their next action, and then stops.**

This binds four surfaces:

| Surface | What it covers |
|---|---|
| Files | spec files, plans, review documents, README files, changelog entries, commit messages, code comments |
| Screen | the report a command prints when it finishes, and every gate it prints on the way |
| Questions | the brief that precedes every `AskUserQuestion` call |
| Runtime | what the `molcajete` CLI prints while it runs |

## Why

Volume and style are separate defects. `writing-style` repairs a sentence that reads badly. It cannot repair a document that states a true thing the reader did not need. Only this skill does that.

The standards separate them too. `ISO/IEC/IEEE 26514:2022` splits Conciseness (clause 7.5) from Minimalism (clause 7.6). `IEC/IEEE 82079-1:2019` clause 5.3 binds both at once, alongside Completeness.

26514 clause 3.1.34 states the target:

> minimalism: principle that information for users includes critical information and the least amount of other information needed to be complete

Completeness is the constraint. Least-amount is the objective under it. Neither one wins outright.

## The Content Test

Do not ask whether a sentence is short. Ask what it is for.

**Keep a unit when its reader needs it to act. Cut it when they do not.**

A unit is a sentence, a bullet, a section, a table row, or a printed line. Run the test on the unit. Brevity is what falls out. Brevity is never the thing you aim at.

Three units almost always fail the test:

- **Preamble.** Text that announces what you are about to do. Do the thing.
- **Recap.** Text that restates what the user just said or what you just did. Say the outcome once.
- **Echo.** An artifact printed to screen and then written to a file. Print the outcome and the path.

## The Four Containers

The content test decides what survives. This decides how it is arranged.

**Sort every surviving unit into one of four containers. Never mix two in one line.**

| Container | Carries | Example |
|---|---|---|
| Table | A short fact with a label. Two columns when the facts are unlike, more when they are alike | status, module, file path, a per-task row |
| Prose | A description that needs room to run several lines | what a scenario does, why an issue matters |
| List | A genuine list of peer items | possible fixes, scenario names, files touched |
| Fenced block | Anything the reader copies | a paste-ready comment, a command, a path set |

**A bold label never shares a line with a long description.** The shape `**Label** — <a sentence or more>`, repeated down a list, is the defect these containers replace. It packs a heading and its content onto one line, so the labels stop being findable and the descriptions run together.

A label may share a line only when what follows is a few words — a table cell, or a list entry such as
`` `SC-3Z2P` — Send OTP to a registered address ``.

**Give the reader the shape, not a description of it.** When a command or a skill specifies a report, write the literal template the model fills in. A report specified as prose bullets gets rendered as prose bullets.

This rule binds the Screen and Files surfaces. Text that only an agent parses — a skill-load list, a lens definition, a rule the model reads once — may stay compact.

## The Three Moves

When a unit runs past its budget, apply these in order. Never skip ahead.

1. **Delete words that carry no information.** Hidden verbs (`make an application for` becomes `apply for`), `there is` and `there are`, wordy phrases (`in order to` becomes `to`), excess modifiers, doublets. **This is the only move that reduces total volume.**
2. **Move the content to where it belongs.** Background belongs in the spec, not in the plan. Detail belongs in the file, not in the report. Rationale belongs in the changelog, not in the code comment.
3. **Split the unit.** Two sections, two requirements, two questions.

**Never delete a fact to meet a budget.** When a shorter unit would drop a condition, a scope qualifier, a number, or an ID, the unit stays long. Move it or split it instead. A budget bounds expression. It never bounds content.

## Budgets

Count sentences, bullets, and sections. **Never count words.** Models track sentence counts far better than word counts, and a word cap produces padding as often as it produces cuts.

| Unit | Ceiling |
|---|---|
| Command report | a heading naming the outcome, one metadata line, then at most 5 sections |
| One section of a report | one table, or one list, or at most 3 sentences |
| One table cell or list entry | one clause |
| Section of a written document | 6 sentences (`writing-style` rule 6.6) |
| Question brief | 250 words, at most 4 options (`asking-questions`) |
| Runtime event | one line |

**Every budget is a ceiling. None is a floor.** A report that needs two bullets prints two. A section that needs one sentence writes one. Never pad a unit to reach its ceiling, and never state a range that implies a minimum.

Make a ceiling conditional on the task when one number does not fit. A single-scenario fix and a twelve-task build do not earn the same report.

## Per-Surface Rules

### Files

- Lead every document with its outcome. The reader who stops after the first section still knows what happened.
- Write a template section when the artifact has content for it. **Omit the section when it does not.** An empty heading is not completeness.
- State a rule once, in the skill that owns it. Reference it elsewhere; do not restate it.

### Screen

- Lead with the outcome, as a heading. The reader knows what happened before they read a sentence.
- Report state that **changed**. Do not enumerate artifacts that stayed the same.
- Name the file path. Do not reprint the file.
- Omit a section that has no content. Never print an empty heading to prove you considered it.

### Questions

- The brief exists to make one decision readable. Cut anything that does not move the reader toward that decision.
- Recap only what the user needs to decide, and only when the context is genuinely stale.

### Runtime

- One line per event the user can act on: a decision, a milestone, an error.
- A step that succeeded as expected is not an event.
- Every other line is behind a verbosity flag.

## Where Completeness Wins

The budget yields in these cases. Each one is a place where a missing item is worse than a long report.

- **Findings.** Review findings, correctness-review results, and completeness sweeps. Generate every one, then filter in a separate pass. A budget applied while generating suppresses true findings.
- **Enumerations the spec owns.** Every scenario, side effect, requirement, and acceptance criterion. Economy governs the prose around them, never the list itself.
- **EARS clauses.** Never reword a requirement to fit a budget. Split the requirement.
- **Load-bearing detail.** Numbers, conditions, scope qualifiers, IDs, and file paths.
- **What the user asked for by name.** A direct request outranks every ceiling here.

## How This Pairs With `writing-style`

| Skill | Governs | Question it answers |
|---|---|---|
| `writing-style` | The shape of a sentence | Does this read one way only? |
| `output-economy` | The amount that gets written | Does the reader need this at all? |

Run `writing-style` on what survives this skill. Splitting a sentence to meet the 20-word rule can add a line; that is correct, and it is not this skill's concern.

## Self-Check

Before you write a document or print a report, answer these:

1. Name the reader and their next action.
2. Confirm every section serves that action.
3. Confirm no list was padded to reach its ceiling.
4. Confirm nothing is stated twice, here and in a file.
5. Confirm no fact was dropped to fit.

If check 5 fails, restore the fact and move or split the unit instead.
