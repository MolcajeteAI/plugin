---
description: Hands-off pre-PR pass on your own change set — walk the solution, surface the problems the change introduces, decide every issue autonomously, document the options and the rationale, and emit parallel-ready /m:build prompts for what must move before the PR. Never edits source; offers a GitHub issue for anything found outside the change.
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

`/m:preflight` is the pre-PR pass on **your own** work: it first walks you through the solution, then surfaces the design problems and rule violations the same way `/m:review` does — and then **decides every issue itself, documents the options and the rationale, and hands you a run plan of ready prompts.** The run stops for the user twice at most: the base-branch confirmation, and the GitHub-issue offer for the observations. It never asks about an issue.

**It never edits source.** Molcajete is a multi-command system, and a fix usually moves more than one of the three elements — spec, code, test. An edit made here skips the changelog entry, the status flip, and the test lifecycle that `/m:build` and `/m:execute` own, so the spec goes stale and the test breaks. Preflight therefore hands you prompts, and the sessions you launch do the work.

Five rules bind the run:

1. **Only the change is on trial.** Preflight answers four questions: is the change architecturally sound, does it follow the rules, do its added and modified lines meet the 80% coverage floor, and does it introduce a defect. A problem the change did not cause is not an issue here. It becomes an **observation**, it never enters the decision pass, and the user decides in Step 8 whether it becomes a GitHub issue for a later pull request. The `change-review` skill's **Scope of the Review** owns that boundary.
2. **Every issue ends in one of two states** — `fix` or `skip`. Preflight assigns the state; it never asks. A `fix` carries a ready prompt. A `skip` carries a one-clause rationale. The run never ends with an open question. An observation is not an issue, so it takes neither state.
3. **The importance gate decides what moves before the PR.** Preflight runs at the last stage before a pull request, and the bar is fixed: the PR must not introduce a defect, must not break a rule, and must not damage the architecture. An issue that crosses that bar is a `fix`. An issue that is small, low-risk, and unrelated to the PR's purpose is a `skip`, recorded with its reason. `HIGH` is always a `fix`. `LOW` defaults to `skip`. `MEDIUM` is judged against the bar, and the decision is documented either way.
4. **The emitted prompt carries no decision.** Preflight decides the route, the diagnosis, and every value the fix needs. The prompt states what to do. It never says that the downstream command will work it out.
5. **Correctness first, architecture second, effort last.** The right fix is the recommended fix, whatever it costs — the cheap fix buys today and bills the project later. Between two correct fixes, take the one the principles and the existing architecture support. Effort separates only what already ties on both, and it never promotes a worse fix above a better one. `skip` competes only through the importance gate — it never wins as the cheap way out of a real fix.

**Base argument:** $ARGUMENTS

**Questions:** this command asks at most two questions per run — the base confirmation in Step 2, and the GitHub-issue offer in Step 8. Each is two moves — write the brief, then ask. Read `${CLAUDE_PLUGIN_ROOT}/shared/skills/asking-questions/SKILL.md` before the first one.

**Writing style:** every document you write and every message you print uses Simplified Technical English. Every one carries only what its reader needs. Read `${CLAUDE_PLUGIN_ROOT}/shared/skills/writing-style/SKILL.md` and `${CLAUDE_PLUGIN_ROOT}/shared/skills/output-economy/SKILL.md` before writing.

## Step 1: Load Skills and Rubric

1. `${CLAUDE_PLUGIN_ROOT}/review/skills/change-review/SKILL.md` — the prerequisite gate, change-set resolution, diff→spec mapping, the scope of the review with its admission test, the rubric + severity, the fix-route table, and the observation bucket with its GitHub issue offer.
2. **Engineering principles** — the operative rubric. Load them per that skill's **Review Rubric & Severity** (host file first, plugin fallback with its warning).
3. `${CLAUDE_PLUGIN_ROOT}/shared/skills/testing/SKILL.md` — so a prompt that orders a test names the scenario and the precise values the integration-test rules require.
4. `${CLAUDE_PLUGIN_ROOT}/shared/skills/resolution-gate/SKILL.md` — analyze, then decide, then write. No open decision survives into an emitted prompt or into the decision file.

Apply the `change-review` skill's **Prerequisites** gate. If it is not a Molcajete project, refuse and stop.

## Step 2: Resolve the Change Set

Follow the `change-review` skill's **Resolving the Change Set** with the base-branch detection, and confirm the base via AskUserQuestion (detected branch pre-selected; `$ARGUMENTS`, if given, is the base). The preflight change set is **branch-vs-base plus the working tree** — union `git diff <base>...HEAD`, `git diff`, and `git diff --cached` so both committed and in-progress work is reviewed.

## Step 3: Map the Change Set to Specs

Follow the `change-review` skill's **Mapping the Diff to Specs** to build the `FEAT → UC → SC → files` tree, each SC carrying its spec quote and integration-test path (or `[missing]`).

## Step 4: Familiarize — walk the solution

Before judging anything, make yourself familiar with what you are about to submit. Print a short hierarchical summary — feature → UC → scenario → the change under it — in plain language: what the change accomplishes end to end, the shape of the approach, and the 2–4 most important changes to understand. Show clickable `file:line` references for the key changes so the user can open them.

This step asks nothing. Print the walk and continue.

## Step 5: Surface the Known Issues

Run the `change-review` skill's **Review Rubric & Severity** against **what the change added and modified** — the same judgment `/m:review` makes, but in-session. Dispatch parallel **Agent** lenses if the change set is large (architecture, rules/principles, shortcut, bug, spec/test/coverage), and merge into **one severity-sorted list**.

Then put every candidate finding through that skill's **admission test**, and split the list in two. A finding is an issue only when the change put the defect on a line it wrote, when one sentence names the changed hunk that broke something elsewhere, or when the change added behavior that no spec defines and no test asserts. Everything else is an observation.

**When you cannot write that sentence, the finding is an observation.** Never widen the change set to make a finding fit, and never search the surrounding code for more of them.

Present the verdict as a heading, then the issues as one table. This table is the map for the decision pass in Step 6, so it carries no detail — each issue opens in full when its turn comes.

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

Then print the observations as their own table, under its own heading, so the two are never read as one list. Write this table only when the run produced an observation. It carries no severity and no `Touches`, because nothing here belongs to this change.

````markdown
## Observations — outside this change

These did not come from your change, and they do not affect the verdict. Step 8 offers a GitHub issue for each one.

| # | Title | Location | Why it is out |
|---|---|---|---|
| O1 | `refreshToken()` swallows every error | `src/auth/session.ts:88` | The line predates this branch |
````

If there is no issue, say so plainly — the change is clean against the rubric — and skip to Step 8. Observations do not change that statement, because a clean change with an observation beside it is still a clean change.

## Step 6: Decide Every Issue, One at a Time

This pass runs over the issue table only. **An observation never enters it.** The pass exists to settle what this change does before it becomes a pull request, and an observation is not part of this change, so it carries no state to assign and no prompt to write. Step 8 handles the observations in one question.

Nothing in this step asks the user anything. The importance gate and the ranking rules make every call, and the recorded decision is the deliverable — the fork, the option that won, every option that lost, and the reason each one lost. Decide one issue fully, record it, then open the next.

### 6.1 Read the three sources

Read the evidence before you decide anything, and keep every citation — Step 10 writes it into the decision file:

- **the spec** — the scenario, `FR`, or `NFR`, quoted with its ID and its file path,
- **the code** — the function at the `file:line` the issue names,
- **the test** — the assertion that covers the behavior, or the fact that none does.

From those three, name the elements the issue must move: `spec`, `code`, `test`. An element moves only when the issue cannot be resolved without it. A refactor that keeps behavior does not move the test, even though the test runs again. A behavior fix on covered code always moves the test.

### 6.2 Apply the importance gate

Decide `fix` or `skip` per rule 3, and write the verdict in one clause.

A `skip` is a decision, not a gap. Record the rationale — why the issue clears the pre-PR bar — in one clause. A skipped issue stays in the report and in the decision file; it passed the admission test, so it belongs to this change, and it never becomes an observation or a GitHub issue. A `skip` goes straight to 6.5.

### 6.3 Explore the options and choose

Write one short block per candidate direction. Each block answers four things, in two lines at most:

- what it does,
- what it changes — spec, code, test,
- the route it takes — `/m:build`, or a direct change when the `change-review` skill's **Choosing the Fix Command** allows one,
- what it costs, and what it leaves unfixed.

**Order the blocks by correctness, then by architecture, and never by cost.** The option that makes the spec, the code, and the test agree goes first, and it gets the most detail — how it works, what it touches, and why it is right. Explore it fully even when it is the largest option on the list. An option that leaves any of the three wrong is a partial fix, so write it as one and name the residue it leaves behind.

Give the effort as a countable fact on its own line — "touches four files and one scenario" — never as an argument for or against an option. **Never write hours or days.** Your sense of how long work takes comes from human timings, so it runs far too high, and an inflated number argues for the cheap option. Count files, tests, specs, and use cases instead.

Then choose the option that serves the project best over the long run — the same standing rule `/m:build` runs under. Record the fork: the option you chose, every option you rejected, and the one clause that sank each loser.

**When the chosen option is a partial fix, record the residue.** Add it as its own `skip` entry, name what stays wrong, and cite the option that would have fixed it. The part a decision leaves behind is still an issue, and it never disappears in silence.

### 6.4 Write the prompt

A `fix` gets its prompt now, while the three citations are in front of you. Route it per the `change-review` skill's **Choosing the Fix Command**: `/m:build` is the default route, and a direct change is allowed only for a small fix that moves one element — spec, code, or test — or code + test only.

A **`/m:build` prompt** is one quoted freeform request. It restates the issue, names the exact `SC`, `FR`, or `NFR` that must move, states which of spec, code, and test is right, and carries every resolved value — the boundary, the limit, the expected outcome. Nothing inside it is conditional, and nothing inside it hands a choice to the reader.

````markdown
```
/m:build "the calibrated score must exceed 100 when the raw score is above the ceiling. SC-3Z2P asserts a value of 128, and `clamp()` at src/calibration/score.ts:142 returns 100. The spec is right, so remove the clamp and keep FR-3Z2Z as written."
```
````

A **direct change** is a self-contained instruction for a fresh session: the `file:line`, the change to make, the reason, and the constraint that behavior stays identical when it must.

````markdown
```
Remove the private helper `formatStamp()` at src/calibration/report.ts:88. Nothing calls it since the date helper moved to src/shared/date.ts. Behavior must stay identical — no spec and no test changes.
```
````

**Never write a prompt that weakens or deletes a test to make an issue disappear.** The fix must satisfy the spec. It must not silence the check.

### 6.5 Record the decision, then open the next issue

Record the issue as `fix` or `skip`, together with the prompt or the skip rationale, the three citations from 6.1, and the options record from 6.3. Step 7 batches the prompts, Step 9 reports the decisions, and Step 10 writes them to the file.

Then open the next issue at 6.1. Print nothing about it until this one is recorded.

## Step 7: Assemble the Run Plan

The `fix` prompts become a run plan the user executes in parallel sessions. Build it in three moves.

**1. List what each prompt touches.** For every `fix`, name the feature, the use cases, and the files its work will move — specs, code, and tests. A `/m:build` run also writes feature-level artifacts — the feature's `REQUIREMENTS.md`, its `ARCHITECTURE.md` rows, and the status roll-up — so count the whole feature as touched, not only the files the prompt names.

**2. Batch.** Merge fixes that touch the same feature or the same files into one `/m:build` prompt with numbered requests — `/m:build` handles several small requests in one run. Then gauge each batch by countable facts: files, use cases, scenarios, tests. A batch stays small-to-medium — roughly one use case's worth of change. When a batch outgrows that, split it along use-case or file boundaries. Never emit one massive prompt. A direct change joins the `/m:build` batch of its area as one more numbered request when one exists; otherwise it stays its own prompt.

**3. Cut the lanes.** Two prompts conflict when they touch the same file, the same use case, or the same feature. Conflicting prompts go into the same **lane**, ordered so that a prompt runs after every prompt whose output it edits; when no such dependency exists, order by severity. A prompt that conflicts with nothing gets its own lane. Lanes are independent by construction: the user launches one session per lane, and no two sessions edit the same file.

## Step 8: Offer to Open GitHub Issues for the Observations

Skip this step when the run produced no observation.

Read `${CLAUDE_PLUGIN_ROOT}/shared/skills/github-issues/SKILL.md` now — a run with no observation never reaches this step, so it never loads it.

Follow the `change-review` skill's **Offering the issues** — check the remote, write the brief, ask once, and create only what the user approved. One question covers every observation. Never open one conversation per observation, because none of them is this change's work.

Every issue carries `AI-finding` plus one kind label, and every issue carries the Molcajete prompt that fixes it. The prompt rules are the same ones Step 6 applies to an in-change fix: resolve every value, and never hand a choice to the reader.

Record each issue URL against its observation. Step 9 prints it, and Step 10 writes it to the file.

## Step 9: Decision Report

One heading for the residual verdict, one table for the decisions:

````markdown
## Residual verdict — CHANGES REQUESTED

Four issues, four decisions. Three carry a prompt, in two lanes.

| # | Severity | Title | Decision | Lane |
|---|---|---|---|---|
| 1 | HIGH | Calibrated score is capped at 100 | fix | A |
| 2 | MEDIUM | No integration test on OTP expiry | fix | B |
| 3 | LOW | Dead date helper | fix | A |
| 4 | LOW | Duplicate module constant | skip | — |
````

Every row carries `fix` or `skip`. A row with any other value means Step 6 left the issue open, so return to it.

Under the table, print one short block per issue: the option preflight chose, each rejected option with the one clause that sank it, and for a `skip` the rationale. Keep a block to four lines — the full record already lives in the decision file.

Close with one line on the run plan — how many lanes, and that each lane is one session. When the run produced observations, add one more line: how many there were, and which ones became issues — "Two observations sit outside this change. One is now issue #412." Print no observation detail here.

## Step 10: Write the Decision File

Skip this step when the run found no issue and no observation.

Run `date +%Y%m%dT%H%M%S` and copy the output. Never compose the timestamp yourself. Then write `.molcajete/prompts/<timestamp>-preflight-<slug>.md`, where `<slug>` is a short kebab-case phrase from the change set — the branch name, or the primary feature. Write it without asking.

The file holds the run plan, **every issue** — skipped ones included — and the observations. Each lane section carries its prompts in run order. Each prompt section carries the issue titles it resolves, the severities, the issue numbers from Step 5, the citation table from 6.1 (one per issue in the batch), the options record from 6.3, and the fenced prompt.

`````markdown
# Preflight — `feat/calibration-ceiling`

Reviewed against `master`. Four issues: three fixed in two lanes, one skipped.

## Run plan

Lanes are independent. Run each lane in its own session, prompts top to bottom.

| Lane | Prompts | Touches |
|---|---|---|
| A | 1 | FEAT-3Z2J (calibration) — 3 files |
| B | 1 | FEAT-2Kp1 (auth) — 2 files |

## Lane A

### A1 — Calibrated score is capped at 100 · Dead date helper

HIGH + LOW · issues #1, #3 · decision: fix

**What we read — issue #1**

| Source | What it says |
|---|---|
| Spec | `SC-3Z2P` — "a raw score of 140 calibrates to 128" · `specs/features/scoring/FEAT-3Z2J-calibration/UC-3Z2L-calibrate-a-raw-score.md` |
| Code | `clamp(value, 0, 100)` at `src/calibration/score.ts:142` returns 100 |
| Test | `tests/scoring/FEAT-3Z2J-calibration/UC-3Z2L-calibrate-a-raw-score.test.ts:31` asserts 100 |

**Options.** Remove the clamp and keep `FR-3Z2Z` as written — chosen; it makes the spec, the code, and the test agree. Raise the clamp ceiling to 128 — rejected; it hard-codes a spec value into the code. Cap the spec at 100 — rejected; `SC-3Z2P` states the intended behavior.

```
/m:build "two requests in the calibration feature. 1) The calibrated score must exceed 100 when the raw score is above the ceiling. SC-3Z2P asserts a value of 128, and `clamp()` at src/calibration/score.ts:142 returns 100. The spec is right, so remove the clamp and keep FR-3Z2Z as written. 2) Remove the private helper `formatStamp()` at src/calibration/report.ts:88 — nothing calls it since the date helper moved to src/shared/date.ts. Behavior stays identical for request 2 — no spec and no test changes."
```

## Lane B

### B1 — No integration test on OTP expiry

MEDIUM · issue #2 · decision: fix

...

## Skipped

| Issue | Title | Why skipped |
|---|---|---|
| #4 | Duplicate module constant | LOW, no rule broken, unrelated to this PR's purpose |

## Observations — outside this change

Not part of this change, and not part of these prompts. Fix each one under its own pull request.

| # | Title | Location | GitHub issue |
|---|---|---|---|
| O1 | `refreshToken()` swallows every error | `src/auth/session.ts:88` | #412 |
| O2 | Stale timezone table | `src/shared/tz.ts:20` | not opened |
`````

Write the `Observations` section only when the run produced one, and write `not opened` for an observation the user declined. That value is a decision the user made, not a hole in the file.

Before the file is final, run the `resolution-gate` skill's **G5** check over it. A banned marker, a conditional sentence, or a prompt that hands a choice to its reader means Step 6 left a value unresolved. Go back, resolve it, and rewrite the prompt. The check runs over the lane sections; the observations carry no prompt, so they carry no decision to resolve.

`/m:preflight` edits no source file and commits nothing. The only thing it writes outside this repository is a GitHub issue the user approved in Step 8. End with:

> Next: launch one session per lane and run its prompts top to bottom. Lanes touch disjoint files, so they run in parallel. `/m:build` runs each prompt end to end — no follow-up command. Then run the full suite, commit, and open the PR.
