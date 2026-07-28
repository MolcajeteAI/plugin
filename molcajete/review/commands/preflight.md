---
description: Interactively review your own change set before opening a PR — get familiar with the solution, surface the known problems and rule violations, and fix them one by one until it's clear to ship.
model: claude-opus-4-6
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

`/m:preflight` is the pre-PR pass on **your own** work — the checklist you clear before takeoff. When code is written with agents you are often not fully familiar with it, so this command first walks you through the solution, then surfaces the design problems and rule violations the same way `/m:review` does — and then helps you **fix them interactively before you open the pull request.** It edits source (that is the point), but it never commits — you commit.

**Base argument:** $ARGUMENTS

**All user interaction MUST use the AskUserQuestion tool.** Never plain-text questions.

## Step 1: Load Skills and Rubric

Read in one batch:

1. `${CLAUDE_PLUGIN_ROOT}/review/skills/change-review/SKILL.md` — the prerequisite gate, change-set resolution, diff→spec mapping, and the review rubric + severity.
2. **Engineering principles.** Read `.claude/rules/principles.md` from the host project — the operative rubric. If missing, read `${CLAUDE_PLUGIN_ROOT}/shared/skills/principles/SKILL.md` and warn: "No host principles file found at `.claude/rules/principles.md`. Using plugin defaults. Run `/m:setup` to generate the host file."
3. `${CLAUDE_PLUGIN_ROOT}/shared/skills/testing/SKILL.md` — so a fix that adds or repairs a test follows the integration-test rules (the Implementer/Reviewer contracts, precise values, current-behavior-only).

Apply the `change-review` skill's **Prerequisites** gate. If it is not a Molcajete project, refuse and stop.

## Step 2: Resolve the Change Set

Follow the `change-review` skill's **Resolving the Change Set** with the base-branch detection, and confirm the base via AskUserQuestion (detected branch pre-selected; `$ARGUMENTS`, if given, is the base). The preflight change set is **branch-vs-base plus the working tree** — union `git diff <base>...HEAD`, `git diff`, and `git diff --cached` so both committed and in-progress work is reviewed.

## Step 3: Map the Change Set to Specs

Follow the `change-review` skill's **Mapping the Diff to Specs** to build the `FEAT → UC → SC → files` tree, each SC carrying its spec quote and integration-test path (or `[missing]`).

## Step 4: Familiarize — walk the solution

Before judging anything, make yourself familiar with what you are about to submit. Present a short hierarchical summary — feature → UC → scenario → the change under it — in plain language: what the change accomplishes end to end, the shape of the approach, and the 2–4 most important changes to understand. Offer, via AskUserQuestion, to go deeper on any feature/UC or to move on:

> "Here is what your change set does, grouped by feature. Where do you want to look closer — or move on to the review?"

Options include each touched feature ("Deeper on {FEAT}"), and "Move on to the review". Show clickable `file:line` references for the key changes so you can open them.

## Step 5: Surface the Known Issues

Run the `change-review` skill's **Review Rubric & Severity** against the change set — the same judgment `/m:review` makes, but in-session. Dispatch parallel **Agent** lenses if the change set is large (rules/principles, architecture, shortcut, bug, spec/test), and merge into **one severity-sorted list**. Each issue is spec/test-anchored (`Spec says` / `Test says`, `[missing]` when absent); missing-spec, missing-test, and sub-floor coverage on touched files are first-class issues.

Present the list compactly (title, severity, location, one-line what) and the current verdict (`BLOCK` / `CHANGES REQUESTED` / `APPROVE`). If there are no issues, say so plainly — the work is clean against the rubric — and skip to Step 7.

## Step 6: Interactive Fix Loop

Walk the issues in severity order (`HIGH` → `MEDIUM` → `LOW`). For each, present it fully (what, Spec says, Test says, risk, possible fixes) and ask via AskUserQuestion:

> "Issue #{n} ({severity}, {type}): {title}. What do you want to do?"

Options: **"Fix now"** / **"Skip (waive)"** / **"Discuss"** (respond via Other; then re-offer).

On **Fix now**:

- For a code defect or rule violation → edit the source to satisfy the spec. Apply Principle 5 craft and comment rules; keep the change surgical.
- For a `missing-test` → add or extend the canonical integration test per the `testing` skill (drive the entry point, precise values, current behavior only). **Never weaken or delete a test to make an issue disappear** — the fix must satisfy the spec, not silence the check.
- For a `missing-spec` → do not invent the behavior in code. Flag it and recommend `/m:change` (or `/m:fix`) to give the behavior a spec, then a test. Record it as waived-pending-spec.
- After each fix, re-check that specific issue (re-read the file / reason about the assertion) and mark it resolved.

Track each issue's disposition: fixed / waived / deferred-to-spec.

## Step 7: Readiness Report

Tell the user:

- What was fixed (per issue, with the file touched).
- What was waived or deferred, and why (especially any `missing-spec` that needs `/m:change`).
- The residual verdict after fixes (`BLOCK` / `CHANGES REQUESTED` / `APPROVE`) — whether it is clear to ship.
- The files edited this session (so you can review before committing).

`/m:preflight` does **not** commit. End with:

> Next: review your edits, run your test suite (or `/m:build` for the touched tasks), commit, and open the PR. Any `missing-spec` items should go through `/m:change` first.
