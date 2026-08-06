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

**Writing style:** every document you write and every message you print is Simplified Technical English. Read `${CLAUDE_PLUGIN_ROOT}/shared/skills/writing-style/SKILL.md` before writing.

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

````markdown
# Code Review — <PR title or branch>

| | |
|---|---|
| PR / Branch | #<n> · `<branch>` → `<base>` |
| Author · Commits | @<author> · <n> commits |
| Size | <n> files · +<add> / −<del> |
| Modules touched | <module list> |
| Generated | <YYYY-MM-DD HH:MM> |
| Verdict | BLOCK — <n> High issues (#1, #2) |

## TL;DR
- 3–5 bullets: what the change does, the verdict, and the single most important thing to verify.

---

## Part 1 — Orientation (read this before the diff)

### 1.1 The problem
Plain-language description of the need this change addresses.
**Spec anchor:** FEAT-XXXX / UC-XXXX — "<what the spec says the system should do>". If the change references no spec/UC, say so here — it is also an issue in Part 2.

### 1.2 The solution from 10,000 ft
Narrative of the approach plus a small flow map (mermaid) of the changed path, so the reviewer holds the shape before reading code.

### 1.3 Guided reading order (don't read randomly)
Work top-down. Every file is **strongly recommended** or **optional** — never tell the reviewer to skip; they decide.
| # | File | Why it matters | What to look for | Read |
|---|------|----------------|------------------|------|
| 1 | `…/service.ts` | Core logic change | The validation branch | strongly recommended |
| … | `…/gen.ts` | Generated wiring | Only if signatures changed | optional |

### 1.4 Critical areas to focus on
The 2–4 hotspots where a bug would hurt most — one sentence each, and why.

---

## Part 2 — Issues (one list, sorted by severity)

**Everything is an issue, treated the same** — convention violation, potential or actual bug, confusing code, wrong architecture, missing spec, or missing integration test — all in this single list, `HIGH` → `MEDIUM` → `LOW`. Each issue MUST carry a **Spec says** and a **Test says** line; use `[missing]` when the spec or test is absent (that absence is the issue).

> ### HIGH · #1 · <one-line title> · type: bug
> **Location:** `path/to/file.ts:142`
> **What:** <what is wrong, concretely>.
> **Spec says:** `UC-XXXX` SC-YYYY — "<quote of the required behavior>". *(or: [missing] — no spec defines this behavior.)*
> **Test says:** `…/003-http-….test.ts` asserts <exact value>. *(or: [missing] — no integration test covers this.)*
> **Risk:** <what breaks in production / for the user>.
> **Suggested comment:** "<short, paste-ready comment for the author>."
> **Possible fixes:** (a) <option>; (b) <option>.

`type` is a free one-word hint (not a grouping): `bug` · `rule` · `architecture` · `shortcut` · `missing-spec` · `missing-test` · `low-coverage` · `confusing`.

---

## Reviewer checklist (final pass)
- [ ] Every HIGH issue resolved or explicitly waived
- [ ] Every changed behavior has a spec reference and a passing integration test
- [ ] Touched files meet the 80% coverage floor
````

## Step 6: Report

Tell the user the review file path and the verdict, and the count of issues by severity. End with:

> Next: address the issues, or run `/m:preflight` to fix them interactively before opening the PR.

## Rules for this command

- Cite real `file:line`, real `FEAT/UC/SC`, and real test paths — never guess an ID, and never leave a **Spec says** / **Test says** line blank.
