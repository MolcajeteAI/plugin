---
description: Turn a freeform request into a ready-to-paste Molcajete command — researches which existing IDs it touches, picks between /m:spec, /m:change, /m:fix, and /m:cover, and writes the full prompt. Runs nothing.
model: claude-opus-5
argument-hint: <freeform request>
allowed-tools:
  - Read
  - Write
  - Glob
  - Grep
  - Bash
  - AskUserQuestion
---

# Prompt Command

`/m:prompt` is the step before `/m:spec`, `/m:change`, `/m:fix`, and `/m:cover`. Describe what you want in your own words — `/m:prompt remove the ceiling for calibration, it can go above 100` — and it researches which existing IDs the request touches, decides which of the four commands fits, and writes the prompt for you to paste.

**It runs nothing.** It emits the command as text and offers to save it. It never invokes the command it chose, and it never edits a spec.

The value it adds is the research. The emitted prompt names the exact `FR` or `SC` that must move, so the downstream command does not repeat the search.

**Target argument:** $ARGUMENTS

**Questions:** every substantive question is two moves — write the brief, then ask. Read `${CLAUDE_PLUGIN_ROOT}/shared/skills/asking-questions/SKILL.md` before the first question.

**Writing style:** every document you write and every message you print uses Simplified Technical English. Every one carries only what its reader needs. Read `${CLAUDE_PLUGIN_ROOT}/shared/skills/writing-style/SKILL.md` and `${CLAUDE_PLUGIN_ROOT}/shared/skills/output-economy/SKILL.md` before writing.

## Step 1: Parse the Request

Take `$ARGUMENTS` as the request. If it is empty, ask via AskUserQuestion: "What do you want to build, change, or fix?" This question only collects free-form input, so it needs no brief.

## Step 2: Load Skill

Read `${CLAUDE_PLUGIN_ROOT}/spec/skills/spec-lookup/SKILL.md` — resolve-by-keyword and context assembly. Apply its **Prerequisites** gate; if this is not a Molcajete project, refuse and stop.

## Step 3: Resolve the Touched IDs

Run the skill's **Resolve by Keyword**, then **Context Assembly** at depth 1 for every main-tier hit. Record each resolved UC's `status`.

Then run the contradiction test. Read the matching scenarios, functional requirements, and non-functional requirements, and find the line the request contradicts. **Quote it or drop it.** If you cannot point at a scenario, an `FR`, or an `NFR` that states the behavior the request changes, there is no contradiction, and Step 5 routes on that fact.

## Step 4: Probe for Unspecified Code

Settle one question: does code exist that no spec covers? Three probes, cheapest first.

1. Did Step 3 resolve any `FEAT` or `UC`? If yes, the answer is no, and you skip probes 2 and 3.
2. For each `Directory` in `specs/MODULES.md`, grep the expanded query terms. Hits mean code exists.
3. For each hit file, check two things: does it carry a `// FEAT-XXXX` or `// UC-XXXX` head comment, and does any `specs/features/*/FEAT-*/ARCHITECTURE.md` Code Map name it?

A file with term hits, no traceability comment, and no Code Map row is unspecified code.

The test is two-sided on purpose. "No spec" alone does not separate unspecified code from a capability that does not exist yet, and those route to different commands.

## Step 5: Choose the Command

Walk the tree top-down. First match wins.

| # | Condition | Route |
|---|-----------|-------|
| 1 | Step 4 found unspecified code, and Step 3 resolved nothing | `/m:cover` |
| 2 | No ID resolved, and no code exists | `/m:spec` |
| 3 | An ID resolved, and the request reports a defect | `/m:fix` |
| 4 | An ID resolved, and the request contradicts a quoted spec line | `/m:change` |
| 5 | An ID resolved, the request adds new behavior, and the spec is silent | `/m:spec` |
| 6 | An ID resolved, and the request asks to document what is already built | `/m:cover` |

Read intent from the verb: *add, create, support* is new behavior; *change, raise, lower, remove the limit* is a change; *broken, wrong, returns X but should return Y* is a defect; *document, capture, we already built* is extraction.

Two guards decide the hard cases:

- **Rows 4 and 5 are separated by the quote, not by the verb.** Route to `/m:change` only when Step 3 produced the spec line being contradicted. Without that quote you are in row 5. `/m:change` refuses a request that only describes new behavior, so a misroute here emits a command that will not run.
- **Row 3 needs the status.** When every resolved UC is `pending`, nothing was built, so a defect is impossible. Route to `/m:spec` instead and say why in the report.

### The one question

Ask only when the intent is genuinely two-way between `/m:fix` and `/m:change` — the spec states a limit, and it is unclear whether that limit is a defect or a decision the user is revising. The two commands do different things, so the answer changes the output.

- Brief: quote the spec line with its ID and file path. State both consequences in one line each — `/m:fix` writes a regression test that asserts the current spec, `/m:change` rewrites the spec and plans the new behavior. Recommend the reading the request supports.
- Question: "Is the current behavior a bug, or a decision you are changing?"
- Header: "Fix or change"
- Options: "It's a bug" / "Changing it"

**One question is the cap.** Every other ambiguity resolves into the emitted text, where the user can edit it. The save question in Step 7 does not count against this cap.

### A request that spans several commands

Emit one primary command and one named follow-up. Never two co-equal commands, and never a compound. The order is fixed, because each step needs the one before it:

1. `/m:cover` — a spec must exist before anything can change it.
2. `/m:change` or `/m:fix`.
3. `/m:spec` — for the genuinely additive part.

## Step 6: Report

Emit the command in a fenced block, ready to copy:

```
/m:change UC-3Z2L UC-3Z2M "remove the 100-point ceiling on calibration output; calibrated scores may exceed 100. FR-3Z2Z currently caps the value at 100 and SC-3Z2P rejects above-ceiling input — both must allow the higher range."
```

The shape is fixed: resolved IDs first, in the order that command's own `argument-hint` expects, then one quoted description that restates the request **and names the specific `FR` or `SC` that must move**.

Under the block, three lines and no more:

- **IDs touched** — each as an ID Summary Line, with its status.
- **The spec line that moves** — the quote from Step 3, with its file path. Write `[none — the spec is silent]` for row 2 or row 5.
- **Why this command** — the row of the tree that matched, in one sentence.

Add a follow-up as one line, only when Step 5 found one:

> Then: `/m:spec "..."` for the {part} — it is additive, and `/m:change` will not carry it.

## Step 7: Offer to Save

Ask whether to keep the prompt as a file. The block above is the brief, so this needs no fresh one.

- Question: "Save this prompt to a file?"
- Header: "Save"
- Options: "Save it" / "No"

On "Save it": run `date +%Y%m%dT%H%M%S` to read the clock, then write `.molcajete/prompts/<timestamp>-<slug>.md`, where `<slug>` is a short kebab-case phrase from the request. Never compose the timestamp yourself. The file holds the fenced command block and the three report lines under it.

End with the hand-off:

> Next: paste the command above to run it. Run `/m:desc <ID>` first if you want to read any of the IDs it names.
