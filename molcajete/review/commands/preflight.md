---
description: Interactively review your own change set before opening a PR — get familiar with the solution, surface the known problems and rule violations, and fix them one by one until it's clear to ship.
model: claude-opus-5
argument-hint: "[base branch — omit to auto-detect and confirm]"
allowed-tools:
  - Read
  - Edit
  - Write
  - Glob
  - Grep
  - Bash
  - Agent
  - AskUserQuestion
---

# Preflight Command

`/m:preflight` is the pre-PR pass on **your own** work: it first walks you through the solution, then surfaces the design problems and rule violations the same way `/m:review` does — and then helps you **fix them interactively before you open the pull request.** It edits source (that is the point), but it never commits — you commit.

**Base argument:** $ARGUMENTS

**Questions:** every substantive question is two moves — write the brief, then ask. Read `${CLAUDE_PLUGIN_ROOT}/shared/skills/asking-questions/SKILL.md` before the first question.

**Writing style:** every document you write and every message you print uses Simplified Technical English. Every one carries only what its reader needs. Read `${CLAUDE_PLUGIN_ROOT}/shared/skills/writing-style/SKILL.md` and `${CLAUDE_PLUGIN_ROOT}/shared/skills/output-economy/SKILL.md` before writing.

## Step 1: Load Skills and Rubric

1. `${CLAUDE_PLUGIN_ROOT}/review/skills/change-review/SKILL.md` — the prerequisite gate, change-set resolution, diff→spec mapping, and the review rubric + severity.
2. **Engineering principles** — the operative rubric. Load them per that skill's **Review Rubric & Severity** (host file first, plugin fallback with its warning).
3. `${CLAUDE_PLUGIN_ROOT}/shared/skills/testing/SKILL.md` — so a fix that adds or repairs a test follows the integration-test rules (the Implementer/Reviewer contracts, precise values, current-behavior-only).

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

Run the `change-review` skill's **Review Rubric & Severity** against the change set — the same judgment `/m:review` makes, but in-session. Dispatch parallel **Agent** lenses if the change set is large (rules/principles, architecture, shortcut, bug, spec/test), and merge into **one severity-sorted list**.

Present the verdict as a heading, then the issues as one table. This table is the map for the fix loop in Step 6, so it carries no detail — each issue opens in full when its turn comes.

````markdown
## Verdict — CHANGES REQUESTED

| # | Severity | Title | Type | Location |
|---|---|---|---|---|
| 1 | HIGH | Calibrated score is capped at 100 | `bug` | `src/calibration/score.ts:142` |
| 2 | MEDIUM | No integration test on OTP expiry | `missing-test` | `src/auth/otp.ts:44` |
````

If there are no issues, say so plainly — the work is clean against the rubric — and skip to Step 7.

## Step 6: Interactive Fix Loop

Walk the issues in severity order. For each, the full issue is the brief:

- Brief: print the issue per the `change-review` skill's **Issue Block Format** — heading, citation table, description, risk, and the possible fixes as a list with `file:line` references. Recommend a disposition.
- Question: "Issue #{n} — what do you want to do?"
- Header: the severity (12 characters maximum)
- Options: **"Fix now"** / **"Skip (waive)"**

Do not add a "Discuss" option — the built-in `Chat about this` footer already lets the user talk it through before deciding, and re-offers the question afterwards.

On **Fix now**:

- For a code defect or rule violation → edit the source to satisfy the spec. Apply Principle 5 craft and comment rules; keep the change surgical.
- For a `missing-test` → add or extend the canonical integration test per the `testing` skill (drive the entry point, precise values, current behavior only). **Never weaken or delete a test to make an issue disappear** — the fix must satisfy the spec, not silence the check.
- For a `missing-spec` → do not invent the behavior in code. Flag it and recommend `/m:change` (or `/m:fix`) to give the behavior a spec, then a test. Record it as waived-pending-spec.
- After each fix, re-check that specific issue (re-read the file / reason about the assertion) and mark it resolved.

Track each issue's disposition: fixed / waived / deferred-to-spec.

## Step 7: Readiness Report

One heading for the residual verdict, one table for the dispositions, one list for the files touched:

````markdown
## Residual verdict — APPROVE

Clear to ship. One item needs a spec before it can be built.

| # | Issue | Disposition | Note |
|---|---|---|---|
| 1 | Calibrated score is capped at 100 | fixed | Clamp removed |
| 2 | No integration test on OTP expiry | fixed | Test added |
| 3 | Retry budget is undefined | deferred to spec | Needs `/m:change` on `UC-3Z2L` |
| 4 | Duplicate date helper | waived | You chose to keep it |

**Files edited**

- `src/calibration/score.ts`
- `tests/auth/FEAT-3Z2K-email-otp/UC-3Z2L-send-email-otp.test.ts`
````

The `Note` column holds one clause, never a paragraph. A `deferred to spec` row always names the command that unblocks it.

`/m:preflight` does **not** commit. End with:

> Next: review your edits, run your test suite (or `/m:build` for the touched tasks), commit, and open the PR. Any `missing-spec` items should go through `/m:change` first.
