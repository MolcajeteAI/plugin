---
description: Produce a guided, spec-traceable code review of what a PR, branch, or ref range changed, and write it to a reviews/ file. Never edits source and never comments on the PR; opens a GitHub issue only for an out-of-scope observation you approve.
model: claude-opus-5
argument-hint: "[PR # | branch | ref-A ref-B — omit for current branch vs base]"
allowed-tools:
  - Read
  - Glob
  - Grep
  - Bash
  - Agent
  - Write
  - AskUserQuestion
---

# Review Command

`/m:review` produces a review document that **walks the reviewer by the hand** — first orient them (the problem, the 10,000-ft solution, where to look), then list every issue in one place, each traced back to what the spec says (`FEAT/UC/SC`) and what the integration test asserts. It writes the result to a file under `reviews/`. It never edits source, and it never comments on the pull request.

**The review judges the change, and only the change.** It answers four questions: is the change architecturally sound, does it follow the rules, do its added and modified lines meet the 80% coverage floor, and does it introduce a defect. A problem the change did not cause is not part of this review. It goes to the observations, where you decide whether to open a GitHub issue for it and fix it under its own pull request. The `change-review` skill's **Scope of the Review** owns that boundary, and Step 5 enforces it.

The whole point is traceability: **every issue cites the spec and the integration test.** A missing spec or a missing test on behavior the change wrote is not an omission in the review — it is one of the most important issues to report.

**Target argument:** $ARGUMENTS

**Questions:** every substantive question is two moves — write the brief, then ask. Read `${CLAUDE_PLUGIN_ROOT}/shared/skills/asking-questions/SKILL.md` before the first question.

**Writing style:** every document you write and every message you print uses Simplified Technical English. Every one carries only what its reader needs. Read `${CLAUDE_PLUGIN_ROOT}/shared/skills/writing-style/SKILL.md` and `${CLAUDE_PLUGIN_ROOT}/shared/skills/output-economy/SKILL.md` before writing.

## Step 1: Load Skills and Rubric

1. `${CLAUDE_PLUGIN_ROOT}/review/skills/change-review/SKILL.md` — the prerequisite gate, change-set resolution, diff→spec mapping, the scope of the review with its admission test, the rubric + severity, and the observation bucket with its GitHub issue offer.
2. **Engineering principles** — the operative rubric. Load them per that skill's **Review Rubric & Severity** (host file first, plugin fallback with its warning).

Apply the `change-review` skill's **Prerequisites** gate now. If it is not a Molcajete project, refuse per that skill and stop.

## Step 2: Resolve the Target and Gather the Diff

Follow the `change-review` skill's **Resolving the Change Set** for `$ARGUMENTS`. Read the PR body / commit subjects — they are the author's own claim of what the change does and which spec it serves. Note whether they reference any `FEAT/UC`.

## Step 3: Map Changed Files to Modules and Specs

Follow the `change-review` skill's **Mapping the Diff to Specs**, and load the host rules that apply to the touched paths (`.claude/rules/*.md`) plus the root `CLAUDE.md`.

## Step 4: Review Lenses (one output stream)

Run these lenses over **what the diff added and modified**. Each one answers part of one of the four questions in the `change-review` skill's **Scope of the Review**. They only exist to get broad coverage — there are no per-lens sections; everything merges in Step 7. **If the change set is large, dispatch them as parallel Agent sub-agents**, giving each the diff, the touched-file list, the loaded specs/tests, the applicable rules, and the admission test; otherwise run them inline.

- **Architecture** — is the change sound? Boundary violations, god files, duplication the change should have reused, hexagonal drift, business logic the change put in the wrong layer.
- **Rules / principles** — does the change follow `.claude/rules/*`, `CLAUDE.md`, and principles 1–5?
- **Shortcut** — does the change kick a can? TODOs that hide scope, legacy paths it left behind, silent truncation or caps it added, tests it disabled or renamed.
- **Bug** — does the change introduce a defect? Correctness, edge cases, concurrency, nil, overflow, unit mismatches, and callers the change broke.
- **Spec / test / coverage** — resolve `FEAT/UC/SC` for each behavior the change added or modified, confirm a spec defines it and an integration test asserts it, and reason statically about the 80% floor **on the added and modified lines**. Judge a whole file only when the change created it.

Every lens judges the change. None of them audits the code around it. A lens that reports a problem on a line the change never touched must carry the sentence that ties it to a changed hunk, and Step 5 removes it when that sentence is absent.

## Step 5: Apply the Scope Filter

Put every candidate finding through the `change-review` skill's **admission test** before it earns a severity, then split the list in two:

- **Issues** — the findings that pass. They carry a severity, and they set the verdict.
- **Observations** — the findings that fail. They carry no severity, and they never touch the verdict.

For any finding that points outside the diff, write the causal sentence first: name the changed hunk, and name what it broke. A finding whose sentence you cannot write is an observation.

**Drop nothing.** A finding that fails the test moves to the observations. It does not disappear, and it does not get argued back into the issue list.

## Step 6: Offer to Open GitHub Issues for the Observations

Skip this step when the run produced no observation.

Follow the `change-review` skill's **Offering the issues** — check the remote, write the brief, ask once, and create only what the user approved. Record each issue URL against its observation, because Step 7 writes it into the document.

This is the only step that writes anything outside this repository, and it writes nothing the user did not approve.

## Step 7: Synthesize and Write the File

- Merge and dedupe the **issues** into **one list, sorted `HIGH` → `MEDIUM` → `LOW`** (severity per the rubric).
- Assign the verdict from the issues alone: `BLOCK` (any High) / `CHANGES REQUESTED` (Mediums only) / `APPROVE` (Lows and nits only, or no issue at all). **Observations never change the verdict.**
- Merge and dedupe the **observations** into their own list, numbered `O1`, `O2`, in the order you met them. They stay unsorted, because they carry no severity.
- Render the template below and `Write` it to `reviews/code-review--{branch}--{PR# or "no-pr"}--{YYMMDDHHmm}.md` (sanitize the branch name: replace `/` with `-`; timestamp is local `YYMMDDHHmm`). Create `reviews/` if needed.
- Output is **emoji-free**: text severity labels and `[missing]` markers.

### Document template

`````markdown
# Code Review — <PR title or branch>

|  |  |
|---|---|
| PR / Branch | #<n> · `<branch>` → `<base>` |
| Author | @<author> · <n> commits |
| Size | <n> files · +<add> / −<del> |
| Modules | `auth`, `console` |
| Generated | <YYYY-MM-DD HH:MM> |

## Verdict — BLOCK

<One or two sentences: why this verdict, and the single most important thing to fix.>

| Severity | Count | Issues |
|---|---|---|
| HIGH | 2 | #1, #2 |
| MEDIUM | 3 | #3, #4, #5 |
| LOW | 1 | #6 |

## What this change does

- <3–5 bullets, one clause each>

---

## Orientation

### The problem

<Plain-language description of the need this change addresses.>

> `UC-3Z2L` says: "<what the spec requires>"

When the change references no spec, say so here in one line. That absence is also an issue below.

### The approach

<Narrative of the solution, then a mermaid flow map of the changed path, so the reviewer holds the shape before reading code.>

### Reading order

Work top-down. Every file is `strongly recommended` or `optional` — never tell the reviewer to skip a file; they decide.

| # | File | Why it matters | What to look for | Read |
|---|------|----------------|------------------|------|
| 1 | `src/auth/otp.ts` | Core logic change | The validation branch | strongly recommended |
| 2 | `src/gen/wiring.ts` | Generated wiring | Only if signatures changed | optional |

### Where a bug would hurt most

- `src/calibration/score.ts:142` — the clamp runs on every request path.
- `src/auth/otp.ts:44` — a failure here locks every user out.

---

## Issues

| # | Severity | Title | Type | Location |
|---|---|---|---|---|
| 1 | HIGH | Calibrated score is capped at 100 | `bug` | `src/calibration/score.ts:142` |
| 2 | HIGH | No integration test on OTP expiry | `missing-test` | `src/auth/otp.ts:44` |

### HIGH · #1 · Calibrated score is capped at 100

|  |  |
|---|---|
| Type | `bug` |
| Location | `src/calibration/score.ts:142` |
| Spec says | `UC-3Z2L` / `SC-3Z2P` — "the calibrated score may exceed 100" |
| Test says | `[missing]` — nothing covers the above-ceiling case |

The clamp in `normalize()` runs after calibration, so any score above 100 silently becomes 100.

**Risk.** Every user in the top decile shows an identical score, and the ranking below them is wrong.

**Possible fixes**

- Remove the clamp and widen the response type.
- Keep the clamp behind a flag, defaulting to off.

**Suggested comment**

```
The clamp on line 142 runs after calibration, so scores above 100 collapse to 100. SC-3Z2P says they may exceed it.
```

---

## Observations — outside this change

These are not part of this review, and they do not affect the verdict. This change did not cause them. Each one is a candidate for its own issue and its own pull request.

| # | Title | Location | Why it is out | GitHub issue |
|---|---|---|---|---|
| O1 | `refreshToken()` swallows every error | `src/auth/session.ts:88` | The line predates this branch | #412 |

### O1 · `refreshToken()` swallows every error

`refreshToken()` returns `null` on every failure, so an expired token and a network failure look identical to every caller.

**Why it is out.** The change did not touch this function, and nothing it changed reaches this path.

**GitHub issue** — #412 · https://github.com/acme/app/issues/412

---

## Reviewer checklist

- [ ] Every HIGH issue resolved or explicitly waived
- [ ] Every behavior the change added or modified has a spec reference and a passing integration test
- [ ] The lines the change added and modified meet the 80% coverage floor
`````

### Rules for the template

**Every issue goes in the one list**, sorted `HIGH` → `MEDIUM` → `LOW`. A convention violation, a bug, confusing code, wrong architecture, a missing spec, and a missing integration test are all issues and all rank the same way — when the change owns them.

**An observation never enters that list.** The two sections stay apart, and the count table above the issues counts issues only. Write the Observations section only when the run produced one; a review with no observation carries no empty section, and no "none found" line.

**`Why it is out` names one reason, in one clause.** It states why the finding failed the admission test — the line predates the branch, the change did not reach this path, the coverage gap is on code the change did not write. It never argues the finding's importance, because importance is not what put it here.

**The index table comes before the issue blocks.** It gives the reviewer the shape of the review before they read a word of it.

**`Spec says` and `Test says` are mandatory rows.** Write `[missing]` when the spec or the test is absent — that absence is the issue, so the row stays and carries it.

**`Type` is a one-word hint, not a grouping:** `bug` · `rule` · `architecture` · `shortcut` · `missing-spec` · `missing-test` · `low-coverage` · `confusing`.

**Four containers, never mixed.** Short facts go in the table. Description and risk are prose under it. Options are a list. The suggested comment is a fenced block, because the reviewer pastes it into the pull request and it must survive verbatim.

## Step 8: Report

Print the verdict as a heading, then the same count table the document carries, then one line for the observations, then the file path on its own line:

````markdown
## Verdict — BLOCK

| Severity | Count | Issues |
|---|---|---|
| HIGH | 2 | #1, #2 |
| MEDIUM | 3 | #3, #4, #5 |

Two observations sit outside this change. One is now issue #412.

Written to `reviews/code-review--feat-otp--142--2608201430.md`.
````

Print the observation line only when the run produced an observation. Print no issue detail and no observation detail on screen. The file holds both, and repeating them here makes the reader choose between two copies.

End with:

> Next: address the issues, or run `/m:preflight` to decide each one and get the prompt that resolves it before opening the PR.

## Rules for this command

- Cite real `file:line`, real `FEAT/UC/SC`, and real test paths — never guess an ID, and never leave a **Spec says** / **Test says** line blank.
- Judge the change, never the repository around it. When a finding fails the admission test, move it to the observations. Never widen the change set to make a finding fit.
- Open a GitHub issue only for an observation the user approved in Step 6. Never comment on the pull request, and never edit source.
