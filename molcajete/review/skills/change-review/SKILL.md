---
name: change-review
description: >-
  Shared machinery for the code-review commands (/m:review, /m:preflight,
  /m:walkthrough). Owns the Molcajete prerequisite gate, change-set resolution
  (branch / PR / two refs / working tree) with base-branch detection, the mapping
  from a diff to the spec tree (feature -> UC -> scenario -> integration test), the
  four questions a review answers, the admission test that keeps a finding inside
  the change, the review rubric + severity vocabulary, and the out-of-scope
  observation bucket with its GitHub issue offer. Molcajete-only; every finding is
  spec-anchored.
---

# Change Review

The reviewing family — `/m:review`, `/m:preflight`, `/m:walkthrough` — all start the same way: gate on a Molcajete project, resolve a change set, and map that diff back to the spec tree so every change and every finding is anchored to a `FEAT/UC/SC` and its integration test. This skill owns that machinery, the scope the assessing commands hold to, and the rubric they score against. Output is **emoji-free** — use text severity labels, not colored circles.

A review judges the change. It does not audit the repository around the change. **Scope of the Review** below owns that boundary, and every finding passes its admission test before it earns a severity.

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

The result is a tree: **FEAT → UC → SC → the changed files/functions under it**, each SC carrying its spec quote and its integration-test path (or a `[missing]` marker).

A changed file that carries no `FEAT/UC/SC` comment and matches no spec is recorded as **unmapped**. Unmapped becomes a `missing-spec` issue only when the change added or modified behavior in that file — then the change wrote behavior that no spec describes, and that is this change's debt. When the change only moved, renamed, reformatted, or re-imported the file, the missing spec was already there, so it is an observation. See **Scope of the Review**.

## Scope of the Review

Used by `/m:review` and `/m:preflight` (the walkthrough narrates changes, it does not score them).

**The review answers four questions about the change, and no others:**

1. Are the changes architecturally sound?
2. Do the changes follow every rule that applies to them?
3. Do the changes meet the 80% coverage floor?
4. Do the changes introduce a defect in the application?

Question 3 measures **the lines the change added and modified**, never the whole file. A file the change created is added in full, so the whole file counts. A file that existed before is judged only on what the change wrote into it. Code the change never touched carries its own coverage debt, and that debt is not this change's to pay.

### The admission test

Every candidate finding takes this test before it earns a severity. A finding is an **issue** only when at least one of the three is true.

| # | Test | Example |
|---|------|---------|
| 1 | The defect sits on a line the diff added or modified. | The new `clamp()` call caps a score that `SC-3Z2P` says may exceed the ceiling. |
| 2 | The change caused the defect elsewhere, and one sentence names the changed hunk that caused it. | The new signature at `auth.ts:12` breaks the caller at `session.ts:88`, which the diff never touched. |
| 3 | The change added or modified behavior that no spec defines, or that no integration test asserts. | The diff adds an expiry branch, and no `SC` describes it. |

A finding that passes none of the three is an **observation**. It is not an issue. It carries no severity, it stays out of the issue list, and it never reaches the verdict.

**Write the causal sentence, or take the finding out.** Test 2 is the only test that reaches past the diff, and it is the one that leaks. Before you keep such a finding, write one sentence that names the changed hunk and names what it broke. A sentence that needs "probably", "may also", or a second hop through code the change never touched is not that sentence. A loose relation is not a relation.

These stay observations, whatever they cost the project:

- A defect on an unchanged line, in a file the change edited for another reason.
- A defect you met in surrounding code while you read for context.
- A missing spec or a missing test on behavior the change did not touch.
- An architecture problem the change inherited and did not make worse.
- Coverage already below the floor on code the change did not write.

**Never search for an observation.** You read the code around the change to judge the change, never to audit it. Record an observation only when it crossed your path while you answered the four questions. A run that returns twenty observations and three issues did the wrong job.

## Review Rubric & Severity

Used by `/m:review` and `/m:preflight` (the walkthrough narrates changes, it does not score them). Apply it to the findings that pass the admission test above, and to nothing else.

**The rubric** is the engineering principles plus the host's own rules:

- **Principles** — read `.claude/rules/principles.md` from the host project first (the operative copy). If
  missing, read `${CLAUDE_PLUGIN_ROOT}/shared/skills/principles/SKILL.md` and warn: "No host principles file
  at `.claude/rules/principles.md` — using plugin defaults. Run `/m:setup` to generate the host file." Score
  against principles 1–5, including the 1.1–1.5 test-writing rules and the 5.1–5.5 comment rules.
- **Host rules** — any `.claude/rules/*.md` that applies to the touched paths, plus the root `CLAUDE.md`.

**Severity:**

| Level | What earns it |
|-------|---------------|
| `HIGH` | A correctness bug the change introduces, a rule violation with real risk, or a missing spec or test on important behavior the change wrote |
| `MEDIUM` | A rule or architecture violation in the change that should move before merge but is not dangerous |
| `LOW` | Nits, style, optional cleanups, inside the change |

**Verdict:** `BLOCK` if any `HIGH`; otherwise `CHANGES REQUESTED` if any `MEDIUM`; otherwise `APPROVE`. An observation never moves the verdict, so a run with no issue and six observations still returns `APPROVE`.

**Issue types** — a one-word hint, not a grouping: `bug` · `rule` · `architecture` · `shortcut` ·
`missing-spec` · `missing-test` · `low-coverage` · `confusing`.

**Every issue is spec-anchored.** Each one carries a `Spec says` value (a `UC-XXXX` / `SC-YYYY` pair and a quote of the required behavior) and a `Test says` value (the integration-test path and what it asserts). Write `[missing]` when the spec or the test is absent.

**A missing spec, a missing test, and a coverage breach are first-class issues when the change owns them**, and they are judged like any other issue. The change owns them under admission test 3: the behavior it added or modified has no spec, or no integration test asserts it. Assess coverage **statically** on the added and modified lines — reason from the tests tree, and never run CI. A file the change created is judged in full. Pre-existing uncovered code in a file the change edited is an observation, not an issue.

Issues from any parallel review lenses merge into **one severity-sorted list**. There are no per-lens sections. Observations merge into their own list, which carries no severity and no sort.

## Issue Block Format

`/m:review` and `/m:preflight` render an issue the same way. Four containers, never mixed:

| Container | Carries |
|-----------|---------|
| H3 heading | `SEVERITY · #n · title` — the anchor, so one issue never runs into the next |
| Two-column table | `Type`, `Location`, `Spec says`, `Test says` — every short fact, labels aligned in one column |
| Prose | The description, unlabeled under the table, then `**Risk.**` as a sentence opener |
| List | The possible fixes, one per line |

A suggested comment for the pull-request author goes in a **fenced code block**, never in prose. The
reviewer pastes it, so it must survive verbatim and stay one click to copy.

**Never stack a bold label and a long description on consecutive lines.** That shape is what these four
containers exist to replace. A label may share a line only when what follows it is a few words, as in a
table cell or a list entry.

`/m:review` renders the whole document; see its **Document template** for the block filled in.

## Observations and the GitHub Issue Offer

An observation is a real problem that the change did not cause and does not own. Both assessing commands collect observations in their own section, apart from the issues, and both offer to open a GitHub issue for each one so a later pull request can fix it.

**An observation never scores.** It takes no severity, it enters no issue list, and it moves no verdict. It also never enters `/m:preflight`'s decision loop, because the user is not deciding this change's fate when they read it.

Keep an observation to three or four lines. The detail belongs in the GitHub issue, where the person who fixes it will look — not in a review document about a different change.

| Field | Carries |
|-------|---------|
| Title | One clause, written as a work item |
| Location | `file:line` |
| What it is | One or two sentences: what is wrong, and what it risks |
| Why it is out | The one reason it failed the admission test, such as "the line predates this branch" |

### Offering the issues

Run this once per command, after every issue is settled. Never ask once per observation.

1. **Check the remote.** Run `gh repo view --json nameWithOwner`. If `gh` is absent or the command fails, print one line — "No GitHub repository reachable, so the observations stay in this document." — and skip the rest of this section.
2. **Write the brief** per the `asking-questions` skill: the observation table, plus the title each issue would carry. The question itself carries none of it.
3. **Ask once:**
   - Question: "Open GitHub issues for these observations?"
   - Header: "Observations"
   - Options: "Open all" / "Let me pick" / "Open none"
4. **On "Let me pick"**, ask again with one option per observation and `multiSelect: true`. Four options is the hard cap, so ask in batches of four when there are more than four.
5. **Create each approved issue** with `gh issue create --title "<title>" --body "<body>"`. Pass no `--label`: a label the repository does not define makes the command fail and loses the issue.

The body carries what a person needs to pick the work up cold:

````markdown
Found while reviewing `<branch or PR #>`, outside the scope of that change.

**Location** — `src/auth/session.ts:88`

**What it is** — `refreshToken()` returns `null` on every failure, so an expired token and a network failure look identical to every caller.

**Why it is separate** — the line predates that branch, and the change did not touch it.

**Suggested direction** — run `/m:cover "the refresh-token error path"` to spec the behavior, then fix it under its own use case.
````

Print each created issue as `#<n> <url>` on its own line, and record the URL against its observation so the document that follows carries it.
