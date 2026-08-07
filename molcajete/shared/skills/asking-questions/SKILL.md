---
name: asking-questions
description: >-
  Rule governing how every user-facing question is presented — write a Markdown
  brief first, then ask with AskUserQuestion carrying only the decision. Covers
  what may never go inside the question field, field limits, the built-in escape
  hatches, when a brief is not required, and when not to ask at all.
---

# Asking Questions

## The Rule

Every substantive question is **two moves**, in this order:

1. **The brief** — a Markdown message in your own response that explains the decision and every option.
2. **The ask** — an `AskUserQuestion` call carrying only the short question and 2-4 short labels.

**Never put the explanation inside the tool call.** The brief is where the user reads; the tool call is where the user clicks.

## Why

`AskUserQuestion` is a decision widget, not a document viewer. Its fields render as plain terminal text:

| Field | How it renders | Consequence |
|-------|----------------|-------------|
| `question` | A single bold run of plain text | `**Bold**` shows literal asterisks. Tables collapse. `\n\n` only soft-wraps. Code blocks show backticks. |
| option `description` | One dim plain-text line | Same — no Markdown, and long values are truncated or wrap badly. |
| `options` | A selectable list | Hard limit: **2-4** options. |
| `header` | A chip beside the prompt | Hard limit: **12 characters**. |

Your own response message *is* rendered as rich Markdown — headings, tables, fenced code, links. That is the only place an explanation can be read comfortably. Hence the two moves.

## The Brief

Fixed shape, in this order:

1. **What I need to decide** — one sentence naming the decision.
2. **Where we are** — one or two sentences of recap, **when the context has gone stale**. Agent work moves faster than a person tracks it; a user returning after a long tool run has no idea what `{UC-0KTg}` was about. Name the file, the entity, the step. Skip this when the user's last message named the thing being decided.
3. **The options** — one short block per option, headed by the exact option label. Each block states: what it does, its consequence, and what happens next.
4. **Recommendation** — one label plus one clause of why. Always give one.
5. **Escape-hatch line** — when the listed options may not cover what the user wants, remind them that `Other` takes free text and `Chat about this` opens a discussion. Skip it when the options are exhaustive.

### Budget

**Under 250 words. At most 4 options. At most 2 lines of consequence per option.** The user must be able to decide in well under five minutes without re-reading.

If the brief does not fit that budget, the question is too big. Split it into two questions, or narrow the scope before asking.

Write for someone who has not been following along. Prefer a table when options differ along the same axes; prefer short prose blocks when each option needs its own reasoning.

## The Ask

| Field | Rule |
|-------|------|
| `question` | One plain sentence. No Markdown, no `\n`, no interpolated tables, diffs, or lists. |
| `header` | 12 characters maximum. |
| `label` | 1-5 words, and **byte-identical to that option's heading in the brief** so the user can map widget to prose. |
| `description` | One plain-text line, roughly 80 characters. A compressed restatement, never the full explanation. |
| `multiSelect` | `true` when the choices are not mutually exclusive. Omit otherwise. |
| `preview` | Almost never. See below. |

When there are more than 4 real choices, list them all in the brief, then chain `AskUserQuestion` calls of 4 until the user has seen every one.

### `preview` Is Not an Escape Route

`preview` is a **per-option** field. It exists for content that **differs between options** — mockup A beside mockup B, two candidate implementations of the same function. It renders as a truncating monospace pane, not as Markdown.

Moving the payload from `question` into `preview` is the same defect wearing a different hat, and it is worse in one respect: the pane **silently truncates**, so the user is asked to approve something they cannot finish reading.

**Never put the subject of the decision in `preview`.** If the content is the same no matter which option the user picks — a plan being confirmed, a diff being approved, a set of findings being accepted — it is shared context, and shared context goes in the brief.

Use `preview` only when all three hold:

1. Each option has its own distinct preview content.
2. The options are genuinely easier to compare side by side than in prose.
3. Each preview fits in roughly 15 lines.

Otherwise omit it.

## Never Inside the `question` Field

| Payload | Where it belongs |
|---------|------------------|
| Composed foundations, plan summaries, task breakdowns | The brief |
| Diffs, before/after snippets | The brief, in a fenced block |
| ASCII mockups | The brief, in a fenced block |
| Module, domain, feature, or file tables | The brief, as a Markdown table |
| Example lists, `\n\n**Bold:**` blocks | The brief |
| Findings, diagnoses, justifications | The brief |

If you are interpolating a `{placeholder}` that expands to more than a few words, it belongs in the brief.

This applies equally to `preview`. Neither field is a place to put the thing being decided.

## Escape Hatches Are Built In

The interface adds two automatically. **Never author your own version of either** — it duplicates an existing affordance and wastes one of only four option slots.

| Affordance | What it is |
|------------|------------|
| `Other` | Auto-appended final option that accepts free text. Never add an option named `Other`, `Custom`, `Something else`, or `Let me specify`. |
| `Chat about this` | A footer entry that returns the user to normal conversation to ask follow-up questions before deciding. Never add an option named `Discuss`, `Ask a question`, or `I have questions`. |

Reference them in the brief's escape-hatch line instead. When an option's meaning is "the user supplies a value", write the option as the semantic choice (`Edit`, `Narrow`, `Custom path`) and note in the brief that the value is provided via `Other`.

## When a Brief Is Not Required

Ask directly, with no brief, when:

- The question is a trivial confirmation whose consequence is fully contained in one sentence — `Overwrite {path}?`, `Delete the original file now?`
- You are inside a loop and the brief for that node was already given — a `Next / Deeper / Done` navigation prompt does not need a fresh brief each time.
- The question only collects free-form input with no options to weigh — `Which file should I document?`

When in doubt, write the brief. The cost of an unnecessary brief is a few seconds; the cost of a missing one is a blind decision.

## When Not to Ask at All

- **Headless and non-interactive sessions.** No user is present. Decide autonomously from the payload and project context. One exception: the `resolution-gate` skill forbids a guess on an item it marked Partial or Missing. There the command halts and writes an escalation instead.
- **Prohibitions declared by a skill.** A skill may forbid one specific question — `/m:setup`, for example, infers modules, domains, actors, and test runners rather than asking. A prohibition never covers an item the `resolution-gate` skill marked Partial or Missing. A skill may still say *when* to ask: `reverse-engineering` requires `/m:cover` to collect concerns silently through the scan, then resolve them in one gate at the end.
- **When the answer is inferable.** If only one module exists, use it. Detect rather than ask.

Reports, usage messages, progress summaries, and briefs are **not** questions. Emitting them as plain text is correct and required — the two-move rule governs questions only.

## Authoring Format

Specify every question in a command or skill file in this form:

```
- Brief: <what the prose message must cover>
- Question: "<one plain sentence>"
- Header: "<=12 chars>"
- Options: "A" / "B" / "C"
- multiSelect: true          (omit when false)
```

## Worked Example

A confirmation gate that presents a composed project foundation.

**Wrong** — the entire document is stuffed into `question`, where none of it renders:

```
- Question: "Here's the composed foundation I'll write:\n\n**Project:** {summary}\n**Modules:** {list}\n**Tech stack:** {per module}\n**Actors:** {list}\n\nWrite all 7 spec files now?"
- Header: "Foundation Ready"
- Options: "Write all files" / "Edit one section" / "Cancel"
```

Three defects: the payload cannot render, `Foundation Ready` is 16 characters and will be truncated, and the user has no readable basis for the decision.

**Right** — brief first, then a short ask:

````
- Brief: Print the composed foundation as Markdown — a one-line project summary,
  then a table of modules with their directories, tech stack, test command, and
  coverage command, then lists of services, actors, and domains. Name the 8 files
  that will be written. Recommend "Write all files". Close with the escape-hatch line.
- Question: "Write the foundation files now?"
- Header: "Foundation"
- Options: "Write all files" / "Edit one section" / "Cancel"
````

The user reads a rendered table, then makes one click. `Edit one section` collects the specific edit via the built-in `Other`.

### Second Example: A Review Gate

An architecture and decomposition gate, where the payload is long and the same for every option.

**Wrong** — the payload is pushed into the option `preview`, where it renders as untruncated-monospace-until-it-is-not:

```
- Question: "Architecture + decomposition for {FEAT-XXXX} (mode: {mode}). Proceed to write the plan?"
- Options: "Proceed" / "Edit the plan"
- preview: "{existing-tests grep, architecture decisions, test path, task breakdown}"
```

The pane cut it off at `21 lines hidden`. The user was asked to approve five architecture decisions and a task list they could not finish reading, and the content was identical under both options — so it was never per-option content to begin with.

**Right** — the payload is the brief; the ask is one line:

````
- Brief: Present the architecture and decomposition as Markdown. Cover, as sections:
  existing tests found and their disposition; the numbered architecture decisions with
  one line of rationale each; the canonical test path; and a table of tasks with the
  scenarios and requirements each covers, plus the files it touches. Recommend "Proceed".
  Close with the escape-hatch line.
- Question: "Proceed to write the plan?"
- Header: "Plan gate"
- Options: "Proceed" / "Edit the plan"
````

Everything renders, nothing is hidden, and the decision itself is one sentence.
