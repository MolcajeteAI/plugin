---
description: Produce a guided, spec-traceable code review of a PR, branch, or ref range and write it to a reviews/ file. Read-only; never posts to GitHub.
model: claude-opus-4-6
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

**All user interaction MUST use the AskUserQuestion tool.** Never plain-text questions.

## Step 1: Load Skills and Rubric

Read in one batch:

1. `${CLAUDE_PLUGIN_ROOT}/review/skills/change-review/SKILL.md` — the prerequisite gate, change-set resolution, diff→spec mapping, and the review rubric + severity.
2. **Engineering principles.** Read `.claude/rules/principles.md` from the host project — the operative rubric. If missing, read `${CLAUDE_PLUGIN_ROOT}/shared/skills/principles/SKILL.md` instead and warn: "No host principles file found at `.claude/rules/principles.md`. Using plugin defaults. Run `/m:setup` to generate the host file."

Apply the `change-review` skill's **Prerequisites** gate now. If it is not a Molcajete project, refuse per that skill and stop.

## Step 2: Resolve the Target and Gather the Diff

Follow the `change-review` skill's **Resolving the Change Set**: parse `$ARGUMENTS` (empty → current branch vs detected base; a branch name; a PR number via `gh`; or two refs), detect and confirm the base branch via AskUserQuestion, and gather the diff, `--stat`, and the commit log (plus the PR body/commits for a PR).

Read the PR body / commit subjects — they are the author's own claim of what the change does and which spec it serves. Note whether they reference any `FEAT/UC`.

## Step 3: Map Changed Files to Modules and Specs

Follow the `change-review` skill's **Mapping the Diff to Specs**. For each changed path, resolve its module from `specs/MODULES.md`, read its `// FEAT/UC/SC` traceability comments, cross-reference the UC spec files (scenarios inline) and the owning task's `Covers` in `specs/plans/*.md`, and locate the canonical integration test. Load the host rules that apply to the touched paths (`.claude/rules/*.md`) and the root `CLAUDE.md`. Record any changed file that maps to no spec as **unmapped** — a `missing-spec` candidate.

## Step 4: Fan Out Review Lenses (one output stream)

Dispatch parallel **Agent** sub-agents. The lenses only exist to get broad coverage — **their findings all merge into one severity-sorted list.** There are no per-lens sections. Give each agent the diff, the touched-file list, the loaded specs/tests, and the applicable rules, and require every issue it returns to fill in the **Spec says** and **Test says** lines (with an explicit `[missing]` when absent).

- **Rules / principles** — violations of `.claude/rules/*` and `CLAUDE.md`, and of principles 1–5 (integration-tests-as-contract, the 1.1–1.5 test-writing rules, hexagonal shape, DI, coverage floor, craft/comment rules 5.1–5.5).
- **Architecture** — boundary violations, god files, duplication that should be reuse, hexagonal drift, business logic in the wrong layer.
- **Shortcut** — can-kicking, TODOs that hide scope, legacy paths left behind, silent truncation/caps, disabled or renamed tests, `nil`/error guards masking real gaps.
- **Bug** — correctness, edge cases, concurrency, nil, overflow, unit mismatches.
- **Spec / test** — for each touched behavior resolve `FEAT/UC/SC`; confirm a spec defines it and an integration test asserts it; reason statically about the 80% coverage floor on touched files. Emit `missing-spec`, `missing-test`, and `low-coverage` issues like any other.

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

- Never post to GitHub, never edit source — this command only reads and writes the review file.
- Cite real `file:line`, real `FEAT/UC/SC`, and real test paths. If a spec or test is absent, write `[missing]` explicitly — do not guess an ID and do not leave the line blank.
- Keep suggested comments short and paste-ready.
- Coverage is assessed statically (reason from the tests tree); never run CI.
