---
description: Produce a guided, spec-traceable code review of a PR, branch, or ref range and write it to a reviews/ file. Read-only; never posts to GitHub.
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

`/m:review` produces a review document that **walks the reviewer by the hand** — first orient them (the problem, the 10,000-ft solution, where to look), then list every issue in one place, each traced back to what the spec says (`FEAT/UC/SC`) and what the integration test asserts. It writes the result to a file under `reviews/`. It never edits source and never posts anything to GitHub.

The whole point is traceability: **every issue cites the spec and the integration test.** A missing spec or a missing test is not an omission in the review — it is one of the most important issues to report.

**Target argument:** $ARGUMENTS

**Questions:** every substantive question is two moves — write the brief, then ask. Read `${CLAUDE_PLUGIN_ROOT}/shared/skills/asking-questions/SKILL.md` before the first question.

**Writing style:** every document you write and every message you print uses Simplified Technical English. Every one carries only what its reader needs. Read `${CLAUDE_PLUGIN_ROOT}/shared/skills/writing-style/SKILL.md` and `${CLAUDE_PLUGIN_ROOT}/shared/skills/output-economy/SKILL.md` before writing.

## Step 1: Load Skills and Rubric

1. `${CLAUDE_PLUGIN_ROOT}/review/skills/change-review/SKILL.md` — the prerequisite gate, change-set resolution, diff→spec mapping, and the review rubric + severity.
2. **Engineering principles** — the operative rubric. Load them per that skill's **Review Rubric & Severity** (host file first, plugin fallback with its warning).

Apply the `change-review` skill's **Prerequisites** gate now. If it is not a Molcajete project, refuse per that skill and stop.

## Step 2: Resolve the Target and Gather the Diff

Follow the `change-review` skill's **Resolving the Change Set** for `$ARGUMENTS`. Read the PR body / commit subjects — they are the author's own claim of what the change does and which spec it serves. Note whether they reference any `FEAT/UC`.

## Step 3: Map Changed Files to Modules and Specs

Follow the `change-review` skill's **Mapping the Diff to Specs**, and load the host rules that apply to the touched paths (`.claude/rules/*.md`) plus the root `CLAUDE.md`.

## Step 4: Review Lenses (one output stream)

Run these lenses over the change set. They only exist to get broad coverage — there are no per-lens sections; everything merges in Step 5. **If the change set is large, dispatch them as parallel Agent sub-agents**, giving each the diff, the touched-file list, the loaded specs/tests, and the applicable rules; otherwise run them inline.

- **Rules / principles** — violations of `.claude/rules/*`, `CLAUDE.md`, and principles 1–5.
- **Architecture** — boundary violations, god files, duplication that should be reuse, hexagonal drift, business logic in the wrong layer.
- **Shortcut** — can-kicking, TODOs that hide scope, legacy paths left behind, silent truncation/caps, disabled or renamed tests.
- **Bug** — correctness, edge cases, concurrency, nil, overflow, unit mismatches.
- **Spec / test** — resolve `FEAT/UC/SC` for each touched behavior, confirm a spec defines it and an integration test asserts it, and reason statically about the 80% coverage floor on touched files.

## Step 5: Synthesize and Write the File

- Merge and dedupe issues across lenses into **one list, sorted `HIGH` → `MEDIUM` → `LOW`** (severity per the rubric).
- Assign the verdict: `BLOCK` (any High) / `CHANGES REQUESTED` (Mediums only) / `APPROVE` (Lows / nits only).
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

## Reviewer checklist

- [ ] Every HIGH issue resolved or explicitly waived
- [ ] Every changed behavior has a spec reference and a passing integration test
- [ ] Touched files meet the 80% coverage floor
`````

### Rules for the template

**Every issue goes in the one list**, sorted `HIGH` → `MEDIUM` → `LOW`. A convention violation, a bug, confusing code, wrong architecture, a missing spec, and a missing integration test are all issues and all rank the same way.

**The index table comes before the issue blocks.** It gives the reviewer the shape of the review before they read a word of it.

**`Spec says` and `Test says` are mandatory rows.** Write `[missing]` when the spec or the test is absent — that absence is the issue, so the row stays and carries it.

**`Type` is a one-word hint, not a grouping:** `bug` · `rule` · `architecture` · `shortcut` · `missing-spec` · `missing-test` · `low-coverage` · `confusing`.

**Four containers, never mixed.** Short facts go in the table. Description and risk are prose under it. Options are a list. The suggested comment is a fenced block, because the reviewer pastes it into the pull request and it must survive verbatim.

## Step 6: Report

Print the verdict as a heading, then the same count table the document carries, then the file path on its own line:

````markdown
## Verdict — BLOCK

| Severity | Count | Issues |
|---|---|---|
| HIGH | 2 | #1, #2 |
| MEDIUM | 3 | #3, #4, #5 |

Written to `reviews/code-review--feat-otp--142--2608201430.md`.
````

Print no issue detail on screen. The file holds it, and repeating it here makes the reader choose between two copies.

End with:

> Next: address the issues, or run `/m:preflight` to decide each one and get the prompt that resolves it before opening the PR.

## Rules for this command

- Cite real `file:line`, real `FEAT/UC/SC`, and real test paths — never guess an ID, and never leave a **Spec says** / **Test says** line blank.
