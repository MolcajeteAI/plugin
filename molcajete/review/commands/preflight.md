---
description: Interactively review your own change set before opening a PR — get familiar with the solution, surface the problems the change itself introduces, decide each one with you, and emit the prompt that fixes it. Never edits source; offers a GitHub issue for anything found outside the change.
model: claude-opus-5
argument-hint: "[base branch — omit to auto-detect and confirm]"
allowed-tools:
  - Read
  - Write
  - Glob
  - Grep
  - Bash
  - Agent
  - AskUserQuestion
---

# Preflight Command

`/m:preflight` is the pre-PR pass on **your own** work: it first walks you through the solution, then surfaces the design problems and rule violations the same way `/m:review` does — and then **decides every issue with you and emits the prompt that resolves it.**

**It never edits source.** Molcajete is a multi-command system, and a fix usually moves more than one of the three elements — spec, code, test. An edit made here skips the changelog entry, the status flip, and the test lifecycle that `/m:change`, `/m:fix`, `/m:cover`, and `/m:build` own, so the spec goes stale and the test breaks. Preflight therefore hands you a prompt, and the command you paste does the work.

Four rules bind the run:

1. **Only the change is on trial.** Preflight answers four questions: is the change architecturally sound, does it follow the rules, do its added and modified lines meet the 80% coverage floor, and does it introduce a defect. A problem the change did not cause is not an issue here. It becomes an **observation**, it never enters the decision loop, and you decide at the end whether it becomes a GitHub issue for a later pull request. The `change-review` skill's **Scope of the Review** owns that boundary.
2. **Every issue ends in one of three states** — `command`, `direct`, or `waived`. The run never ends with an open question. An observation is not an issue, so it takes none of these states.
3. **The emitted prompt carries no decision.** Preflight decides the route, the diagnosis, and every value the fix needs. The prompt states what to do. It never says that the downstream command will work it out.
4. **Correctness first, architecture second, effort last.** The right fix is the recommended fix, whatever it costs — the cheap fix buys today and bills the project later. Between two correct fixes, take the one the principles and the existing architecture support. Effort separates only what already ties on both, and it never promotes a worse fix above a better one.

**Base argument:** $ARGUMENTS

**Questions:** every substantive question is two moves — write the brief, then ask. Read `${CLAUDE_PLUGIN_ROOT}/shared/skills/asking-questions/SKILL.md` before the first question.

**Writing style:** every document you write and every message you print uses Simplified Technical English. Every one carries only what its reader needs. Read `${CLAUDE_PLUGIN_ROOT}/shared/skills/writing-style/SKILL.md` and `${CLAUDE_PLUGIN_ROOT}/shared/skills/output-economy/SKILL.md` before writing.

## Step 1: Load Skills and Rubric

1. `${CLAUDE_PLUGIN_ROOT}/review/skills/change-review/SKILL.md` — the prerequisite gate, change-set resolution, diff→spec mapping, the scope of the review with its admission test, the rubric + severity, and the observation bucket with its GitHub issue offer.
2. **Engineering principles** — the operative rubric. Load them per that skill's **Review Rubric & Severity** (host file first, plugin fallback with its warning).
3. `${CLAUDE_PLUGIN_ROOT}/shared/skills/testing/SKILL.md` — so a prompt that orders a test names the scenario and the precise values the integration-test rules require.
4. `${CLAUDE_PLUGIN_ROOT}/shared/skills/resolution-gate/SKILL.md` — analyze, then ask, then write. No decision survives into an emitted prompt or into the decision file.

Apply the `change-review` skill's **Prerequisites** gate. If it is not a Molcajete project, refuse and stop.

## Step 2: Resolve the Change Set

Follow the `change-review` skill's **Resolving the Change Set** with the base-branch detection, and confirm the base via AskUserQuestion (detected branch pre-selected; `$ARGUMENTS`, if given, is the base). The preflight change set is **branch-vs-base plus the working tree** — union `git diff <base>...HEAD`, `git diff`, and `git diff --cached` so both committed and in-progress work is reviewed.

## Step 3: Map the Change Set to Specs

Follow the `change-review` skill's **Mapping the Diff to Specs** to build the `FEAT → UC → SC → files` tree, each SC carrying its spec quote and integration-test path (or `[missing]`).

## Step 4: Familiarize — walk the solution

Before judging anything, make yourself familiar with what you are about to submit. Present a short hierarchical summary — feature → UC → scenario → the change under it — in plain language: what the change accomplishes end to end, the shape of the approach, and the 2–4 most important changes to understand. That summary is the brief — this step already follows the two-move rule. Then ask:

- Question: "Where do you want to look closer?"
- Header: "Familiarize"
- Options: one per touched feature ("Deeper on {FEAT}"), plus "Move on to the review"

Show clickable `file:line` references for the key changes in the brief so the user can open them.

## Step 5: Surface the Known Issues

Run the `change-review` skill's **Review Rubric & Severity** against **what the change added and modified** — the same judgment `/m:review` makes, but in-session. Dispatch parallel **Agent** lenses if the change set is large (architecture, rules/principles, shortcut, bug, spec/test/coverage), and merge into **one severity-sorted list**.

Then put every candidate finding through that skill's **admission test**, and split the list in two. A finding is an issue only when the change put the defect on a line it wrote, when one sentence names the changed hunk that broke something elsewhere, or when the change added behavior that no spec defines and no test asserts. Everything else is an observation.

**When you cannot write that sentence, the finding is an observation.** Never widen the change set to make a finding fit, and never search the surrounding code for more of them.

Present the verdict as a heading, then the issues as one table. This table is the map for the decision loop in Step 6, so it carries no detail — each issue opens in full when its turn comes.

`Touches` names the elements the issue must move: `spec`, `code`, `test`, or a combination. Write the element names and nothing else, so the table stays a map.

````markdown
## Verdict — CHANGES REQUESTED

| # | Severity | Title | Type | Touches | Location |
|---|---|---|---|---|---|
| 1 | HIGH | Calibrated score is capped at 100 | `bug` | code + test | `src/calibration/score.ts:142` |
| 2 | MEDIUM | No integration test on OTP expiry | `missing-test` | test | `src/auth/otp.ts:44` |
| 3 | LOW | Dead date helper | `shortcut` | code | `src/calibration/report.ts:88` |
| 4 | LOW | Duplicate module constant | `rule` | code | `src/auth/config.ts:12` |
````

Then print the observations as their own table, under its own heading, so the two are never read as one list. Write this table only when the run produced an observation. It carries no severity and no `Touches`, because nothing here is yours to decide in this run.

````markdown
## Observations — outside this change

These did not come from your change, and they do not affect the verdict. Step 7 offers a GitHub issue for each one.

| # | Title | Location | Why it is out |
|---|---|---|---|
| O1 | `refreshToken()` swallows every error | `src/auth/session.ts:88` | The line predates this branch |
````

If there is no issue, say so plainly — the change is clean against the rubric — and skip to Step 7. Observations do not change that statement, because a clean change with an observation beside it is still a clean change.

## Step 6: Decide Every Issue, One at a Time

This loop runs over the issue table only. **An observation never enters it.** The loop exists to settle what this change does before it becomes a pull request, and an observation is not part of this change, so it carries no direction to pick and no prompt to emit. Step 7 handles the observations in one question.

One issue is one conversation, and it runs to the end before the next one opens. Never print two issues in one turn, and never cover two issues in one question.

Each issue passes **two gates**. Gate one settles the direction. Gate two approves the exact change. The user may reject at either gate as many times as it takes, so neither gate carries a cap.

### 6.1 Read the three sources

Read the evidence before you write anything, and keep every citation:

- **the spec** — the scenario, `FR`, or `NFR`, quoted with its ID and its file path,
- **the code** — the function at the `file:line` the issue names,
- **the test** — the assertion that covers the behavior, or the fact that none does.

From those three, name the elements the issue must move: `spec`, `code`, `test`. An element moves only when the issue cannot be resolved without it. A refactor that keeps behavior does not move the test, even though the test runs again. A behavior fix on covered code always moves the test.

### 6.2 Explain the issue and the options in prose

The brief carries everything the user needs. Print the issue per the `change-review` skill's **Issue Block Format** — heading, citation table, description, risk — and add one `Touches` row to the citation table, under `Location`. That row is preflight-only. The shared format stays as it is for `/m:review`.

Then write the **options block**, which the shared format does not carry. Write one short block per candidate direction, headed by the exact label the question will use. Each block answers four things, in two lines at most:

- what it does,
- which command carries it, or `direct change` when no command owns it,
- what it changes — spec, code, test,
- what it costs, and what it leaves unfixed.

**Order the blocks by correctness, then by architecture, and never by cost.** The option that makes the spec, the code, and the test agree goes first, and it gets the most detail — how it works, what it touches, and why it is right. Explore it fully even when it is the largest option on the list. An option that leaves any of the three wrong is a partial fix, so write it as one and name the residue it leaves behind.

Give the effort as a countable fact on its own line — "touches four files and one scenario" — never as an argument for or against an option. **Never write hours or days.** Your sense of how long work takes comes from human timings, so it runs far too high, and an inflated number argues for the cheap option. Count files, tests, specs, and use cases instead. The user weighs the cost. You do not weigh it for them by ranking it.

Recommend the correct option, with one clause of reasoning.

**Never put any of this inside the question.** The widget renders plain text, so an explanation is unreadable there. The `asking-questions` skill owns that rule.

Close the brief with the escape-hatch line: `Other` takes the user's own approach as free text, and `Chat about this` opens a discussion and re-offers the question afterwards.

### 6.3 Ask for the direction

- Question: "Issue #{n} — which direction?"
- Header: the severity (12 characters maximum)
- Options: the candidate directions from 6.2, the recommendation first, plus **"Skip (waive)"**. Four is the hard cap, so merge the weakest candidates when the diagnosis produces more.

Do not add an "Other" option, and do not add a "Discuss" option. Both are built in, and both already do what a hand-written option would do.

The candidates come from the elements that move:

| What must move | Route |
|---|---|
| code only, behavior unchanged — dead code, naming, a comment rule, a duplicate helper | direct change |
| test only — specified behavior that nothing asserts | `/m:cover "<the code path>"`, which writes the pending log entry for `/m:plan` and `/m:build` |
| code + test, and the spec is right | `/m:fix <UC-XXXX>` |
| spec + code (+ test), and the spec states the wrong behavior | `/m:fix <UC-XXXX>`, with the spec correction stated in the prompt |
| spec + code + test, and the user revises the behavior on purpose | `/m:change <UC-XXXX>` |
| unmapped code that no spec covers (`missing-spec`) | `/m:cover "<the code path>"` |
| behavior the spec never described, and it must exist | `/m:spec "..."` |

Separate `/m:fix` from `/m:change` by the quoted spec line, the same guard `/m:prompt` uses: route to `/m:change` only when a spec line states the behavior the user revises on purpose. When the reading is genuinely two-way, that is a question, not a guess.

**Ask a follow-up whenever the answer leaves a real choice open.** Each follow-up is two moves again — brief first, then the ask. Ask the ones that apply:

- which of the candidate fixes the prompt orders,
- whether the spec was wrong or the code was,
- the exact value a limit, a timeout, or a boundary takes,
- which module-instance of a shared UC the issue touches.

There is no cap on follow-ups. A question you do not ask becomes a decision inside the prompt, and Step 9 rejects that prompt.

### 6.4 Show what will change, then get approval

Gate two. A waived issue skips this gate and goes to 6.5. Every other issue gets two blocks under it, in this order.

**What we read** — the three citations from 6.1, as a two-column table. The diagnosis rests on these three rows, so the user can reject the diagnosis and not only the fix.

````markdown
**What we read**

| Source | What it says |
|---|---|
| Spec | `SC-3Z2P` — "a raw score of 140 calibrates to 128" · `specs/features/scoring/FEAT-3Z2J-calibration/UC-3Z2L-calibrate-a-raw-score.md` |
| Code | `clamp(value, 0, 100)` at `src/calibration/score.ts:142` returns 100 |
| Test | `tests/scoring/FEAT-3Z2J-calibration/UC-3Z2L-calibrate-a-raw-score.test.ts:31` asserts 100 |
````

**What the change will be** — the finished prompt, in a fenced block. Nothing inside it is conditional.

A **Molcajete command** uses the same shape as `/m:prompt`: the resolved IDs first, in the order that command's own `argument-hint` expects, then one quoted description that restates the issue and **names the exact `SC`, `FR`, or `NFR` that must move**.

````markdown
```
/m:fix UC-3Z2L "the calibrated score must exceed 100 when the raw score is above the ceiling. SC-3Z2P asserts a value of 128, and `clamp()` at src/calibration/score.ts:142 returns 100. The spec is right, so remove the clamp and keep FR-3Z2Z as written."
```
````

A **direct change** is a self-contained instruction for a fresh session: the `file:line`, the change to make, the reason, and the constraint that behavior stays identical. No Molcajete command owns a behavior-preserving cleanup, so none is named.

````markdown
```
Remove the private helper `formatStamp()` at src/calibration/report.ts:88. Nothing calls it since the date helper moved to src/shared/date.ts. Behavior must stay identical — no spec and no test changes.
```
````

Then ask:

- Question: "Issue #{n} — is this the change you want?"
- Header: "Confirm"
- Options: **"Yes, next issue"** / **"Revise it"**

On "Revise it", on free text from `Other`, or on anything the user raises through `Chat about this`, rewrite the prompt and print both blocks again. Repeat until the user approves. The user closes this loop, never you.

### 6.5 Record the decision, then open the next issue

Record the issue as `command`, `direct`, or `waived`, together with the approved prompt or the waive reason.

**When the user picks a partial fix over the correct one, record the residue.** Add it as its own `waived` entry, name what stays wrong, and cite the option that would have fixed it. A choice the user makes on purpose is a decision. The part it leaves behind is still an issue, and it never disappears in silence.

**A waive is a decision, not a gap.** Record the reason in one clause. **Never order a prompt that weakens or deletes a test to make an issue disappear.** The fix must satisfy the spec. It must not silence the check.

Then open the next issue at 6.1. Print nothing about it until this one is recorded.

## Step 7: Offer to Open GitHub Issues for the Observations

Skip this step when the run produced no observation.

Follow the `change-review` skill's **Offering the issues** — check the remote, write the brief, ask once, and create only what the user approved. One question covers every observation. Never open one conversation per observation, because none of them is this change's work.

Record each issue URL against its observation. Step 8 prints it, and Step 9 writes it to the file.

## Step 8: Decision Report

One heading for the residual verdict, one table for the decisions:

````markdown
## Residual verdict — CHANGES REQUESTED

Four issues, four decisions. Three carry a prompt.

| # | Issue | Decision | Prompt |
|---|---|---|---|
| 1 | Calibrated score is capped at 100 | command | `/m:fix UC-3Z2L` |
| 2 | No integration test on OTP expiry | command | `/m:cover "the OTP expiry branch"` |
| 3 | Dead date helper | direct | Remove `formatStamp()` |
| 4 | Duplicate module constant | waived | You keep it until the merge lands |
````

The `Prompt` column holds one clause, never a paragraph — the full prompt already printed in Step 6. Every row carries `command`, `direct`, or `waived`. A row with any other value means Step 6 left the issue open, so return to it.

When the run produced observations, add one line under the table: how many there were, and which ones became issues — "Two observations sit outside this change. One is now issue #412." Print no observation detail here.

## Step 9: Write the Decision File

Skip this step when the run found no issue and no observation.

Run `date +%Y%m%dT%H%M%S` and copy the output. Never compose the timestamp yourself. Then write `.molcajete/prompts/<timestamp>-preflight-<slug>.md`, where `<slug>` is a short kebab-case phrase from the change set — the branch name, or the primary feature. Write it without asking.

The file holds **every issue**, waived ones included. One section each: the title, the severity, the `file:line`, the decision, and the fenced prompt when the issue carries one. The observations follow at the end, in their own table, and they carry no prompt.

Number the sections in run order, and carry the Step 8 issue number as a field. The reader runs the file from top to bottom, so the numbering follows the run, never the severity sort.

`````markdown
# Preflight — `feat/calibration-ceiling`

Reviewed against `master`. Four issues, four decisions. Run these in order.

## 1. No integration test on OTP expiry

MEDIUM · test · `src/auth/otp.ts:44` · issue #2 · decision: command

```
/m:cover "the OTP expiry branch at src/auth/otp.ts:44 — SC-3Z2R states that an OTP expires after 10 minutes, and no test asserts it"
```

## 2. Calibrated score is capped at 100

HIGH · code + test · `src/calibration/score.ts:142` · issue #1 · decision: command

```
/m:fix UC-3Z2L "the calibrated score must exceed 100 when the raw score is above the ceiling. SC-3Z2P asserts a value of 128, and `clamp()` at src/calibration/score.ts:142 returns 100. The spec is right, so remove the clamp and keep FR-3Z2Z as written."
```

## 3. Dead date helper

LOW · code · `src/calibration/report.ts:88` · issue #3 · decision: direct

```
Remove the private helper `formatStamp()` at src/calibration/report.ts:88. Nothing calls it since the date helper moved to src/shared/date.ts. Behavior must stay identical — no spec and no test changes.
```

## Waived

| Issue | Title | Reason |
|---|---|---|
| #4 | Duplicate module constant | You keep it until the merge lands |

## Observations — outside this change

Not part of this change, and not part of these prompts. Fix each one under its own pull request.

| # | Title | Location | GitHub issue |
|---|---|---|---|
| O1 | `refreshToken()` swallows every error | `src/auth/session.ts:88` | #412 |
| O2 | Stale timezone table | `src/shared/tz.ts:20` | not opened |
`````

**The order is the run order**, because each step needs the one before it: `/m:cover` first, then `/m:fix` and `/m:change`, then `/m:spec`, then the direct changes. Waived issues go next, under their own heading, and the observations go last.

Write the `Observations` section only when the run produced one, and write `not opened` for an observation the user declined. That value is a decision the user made, not a hole in the file.

Before the file is final, run the `resolution-gate` skill's **G5** check over it. A banned marker, a conditional sentence, or a prompt that hands a choice to its reader means Step 6 missed a question. Go back, ask it, and rewrite the prompt. The check runs over the issue sections; the observations carry no prompt, so they carry no decision to resolve.

`/m:preflight` edits no source file and commits nothing. The only thing it writes outside this repository is a GitHub issue the user approved in Step 7. End with:

> Next: run the prompts in the order the file lists them. `/m:fix` and `/m:change` each write a plan, so run `/m:build <plan-id>` after each one. Then commit and open the PR.
