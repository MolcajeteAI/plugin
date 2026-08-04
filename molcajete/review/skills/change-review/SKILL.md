---
name: change-review
description: >-
  Shared machinery for the code-review commands (/m:review, /m:preflight,
  /m:walkthrough). Owns the Molcajete prerequisite gate, change-set resolution
  (branch / PR / two refs / working tree) with base-branch detection, the mapping
  from a diff to the spec tree (feature -> UC -> scenario -> integration test), and
  the review rubric + severity vocabulary. Molcajete-only; every finding is
  spec-anchored.
---

# Change Review

The reviewing family — `/m:review`, `/m:preflight`, `/m:walkthrough` — all start the same way:
gate on a Molcajete project, resolve a change set, and map that diff back to the spec tree so every
change and every finding is anchored to a `FEAT/UC/SC` and its integration test. This skill owns that
machinery plus the review rubric the assessing commands score against. Output is **emoji-free** — use
text severity labels, not colored circles.

## Prerequisites (Molcajete-only)

These commands only operate inside a Molcajete project. Before anything else, verify:

- `specs/PROJECT.md` and `specs/MODULES.md` exist.
- The spec tree exists (`specs/features/` has at least one `FEAT-*` folder).

If any is missing, refuse and stop:

> This is not a Molcajete project (no `specs/PROJECT.md` / `specs/MODULES.md`). The review commands are
> spec-anchored — run `/m:setup` to initialize the project foundation first.

## Resolving the Change Set

Parse the command's target argument into one of four shapes, then gather the diff.

| Target argument | Meaning | How to gather |
|-----------------|---------|---------------|
| empty | the current branch vs its base | resolve base (below); `git diff <base>...HEAD` |
| a branch name | that branch vs its base | `git diff <base>...<branch>` |
| a PR number (all digits) | a GitHub pull request | `gh pr view <n> --json title,body,files,additions,deletions,baseRefName,headRefName,commits,author` then `gh pr diff <n>` |
| two refs (`A B`, `A..B`, or `A...B`) | changes between two refs | `git diff A...B` (e.g. `master production`) |

**Base-branch detection** (for the empty / branch-name forms). Do not assume `master`:

1. `git symbolic-ref refs/remotes/origin/HEAD 2>/dev/null | sed 's@^refs/remotes/origin/@@'` — the remote's
   default branch, when set.
2. Otherwise the first of `main`, `master`, `develop` that resolves (`git rev-parse --verify <name>`).
3. Confirm the base. This is a short question, so the brief is one line:
   - Brief: name the detected branch and how it was detected, and list the other candidates found.
   - Question: "Review against which base branch?"
   - Header: "Base branch"
   - Options: the detected branch first, then the other candidates

   Do not add an "Other — I'll name it" option; the built-in `Other` already collects a branch name.

For a PR target, the base is `baseRefName` from `gh pr view` — no prompt needed.

**Gather, for every target:**

- `git diff <base>...<head>` (the unified diff) and `git diff <base>...<head> --stat`.
- `git log <base>..<head> --oneline` — the commit subjects are the author's own claim of what changed and why.
- For a PR: also the PR title/body and commit list from `gh pr view`.
- **Working tree (only when the caller asks — `/m:preflight`):** union `git diff` (unstaged) and
  `git diff --cached` (staged) into the change set, so in-progress edits are reviewed too.

If `gh` is not installed and a PR number was given, stop and say so ("`gh` (GitHub CLI) is required to review
a PR by number — pass a branch name or two refs instead, or install `gh`").

## Mapping the Diff to Specs (feature → UC → scenario)

Build a hierarchical map from the changed files up to the spec, so the commands can group changes by feature.
For each changed path:

1. **Module** — resolve from `specs/MODULES.md` (the module whose `Directory` prefixes the path).
2. **FEAT / UC / SC** — read the traceability comments the code carries (principles §5.1): `// FEAT-XXXX`,
   `// UC-XXXX` at the file head, and `// SC-XXXX, SC-YYYY` above the functions the diff touches. The comment
   syntax follows the language (`//`, `#`, `--`, `/* */`).
3. **Cross-reference the spec tree** to confirm and enrich: `specs/features/{module}/FEAT-*/UC-XXXX-*.md`
   (the module is the segment under `specs/features/`); scenarios (`SC-XXXX`) live **inline** in the UC spec
   file. Read the touched UC's scenarios — they are the behavioral source of truth. The owning task's `Covers`
   list in `specs/plans/*.md` is the canonical machine-readable FEAT→UC→SC→file map when the change came
   through a plan.
4. **Integration test** — the canonical path is `{module.Tests}/{feature-dir}/{uc-dir}.{ext}`
   (`module.Tests` from `specs/MODULES.md`). Grep the changed symbols against the module's tests tree to see
   what actually asserts them.

The result is a tree: **FEAT → UC → SC → the changed files/functions under it**, each SC carrying its spec
quote and its integration-test path (or a `[missing]` marker). A changed file that carries no `FEAT/UC/SC`
comment and matches no spec is recorded as **unmapped** — that is a `missing-spec` finding, not a gap to
paper over.

## Review Rubric & Severity

Used by `/m:review` and `/m:preflight` (the walkthrough narrates changes, it does not score them).

**The rubric** is the engineering principles plus the host's own rules:

- **Principles** — read `.claude/rules/principles.md` from the host project first (the operative copy). If
  missing, read `${CLAUDE_PLUGIN_ROOT}/shared/skills/principles/SKILL.md` and warn: "No host principles file
  at `.claude/rules/principles.md` — using plugin defaults. Run `/m:setup` to generate the host file." Score
  against principles 1–5, including the 1.1–1.5 test-writing rules and the 5.1–5.5 comment rules.
- **Host rules** — any `.claude/rules/*.md` that applies to the touched paths, plus the root `CLAUDE.md`.

**Severity** and **verdict**:

- `HIGH` — correctness bug, a rule violation with real risk, a missing spec/test on important behavior.
- `MEDIUM` — a rule/architecture violation or gap that should change before merge but isn't dangerous.
- `LOW` — nits, style, optional cleanups.
- **Verdict:** `BLOCK` if any `HIGH`; else `CHANGES REQUESTED` if any `MEDIUM`; else `APPROVE`.

**Every issue is spec-anchored.** Each finding carries a **Spec says** line (`UC-XXXX` SC-YYYY + a quote of
the required behavior, or `[missing]` when no spec defines the behavior) and a **Test says** line (the
integration-test path + what it asserts, or `[missing]` when nothing covers it). A missing spec, a missing
test, or a touched file below the 80% coverage floor is a **first-class issue**, judged like any other.
Assess coverage **statically** — reason from the tests tree; never run CI.

**Issue types** (a one-word hint, not a grouping): `bug` · `rule` · `architecture` · `shortcut` ·
`missing-spec` · `missing-test` · `low-coverage` · `confusing`.

Findings from any parallel review lenses merge into **one severity-sorted list** — there are no per-lens
sections.
