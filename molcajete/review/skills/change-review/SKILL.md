---
name: change-review
description: >-
  Shared machinery for /m:walkthrough. Owns the Molcajete prerequisite gate,
  change-set resolution (branch / PR / two refs) with base-branch detection,
  and the mapping from a diff to the spec tree (feature -> UC -> scenario ->
  integration test). Molcajete-only; every node of the walkthrough is
  spec-anchored. The scoring rubric and severity vocabulary live in the CLI's
  final verification, not here.
---

# Change Review

`/m:walkthrough` starts the same way every reviewing surface used to: gate on a Molcajete project,
resolve a change set, and map that diff back to the spec tree so every change is anchored to a
`FEAT/UC/SC` and its integration test. This skill owns that machinery. Output is **emoji-free**.

The review rubric and severity vocabulary moved to the CLI's final verification — the read-only
reviewer session that closes every main-loop cycle. This skill serves the human's understanding, never
the build loop.

## Prerequisites (Molcajete-only)

The walkthrough only operates inside a Molcajete project. Before anything else, verify:

- `specs/PROJECT.md` and `specs/MODULES.md` exist.
- The spec tree exists (`specs/features/` has at least one `FEAT-*` folder).

If any is missing, refuse and stop:

> This is not a Molcajete project (no `specs/PROJECT.md` / `specs/MODULES.md`). The walkthrough is
> spec-anchored — run `/m:setup` to initialize the project foundation first.

## Resolving the Change Set

Parse the command's target argument into one of four shapes, then gather the diff.

| Target argument | Meaning | How to gather |
|-----------------|---------|---------------|
| empty | the current branch vs its base | resolve base (below); `git diff <base>...HEAD` |
| a branch name | that branch vs its base | `git diff <base>...<branch>` |
| a PR number (all digits) | a GitHub pull request | `gh pr view <n> --json title,body,files,additions,deletions,baseRefName,headRefName,commits,author` then `gh pr diff <n>` |
| two refs (`A B`, `A..B`, or `A...B`) | changes between two refs | `git diff A...B` (e.g. `master production`) |

A run branch (`change/{change-id}`) is a normal branch target — walking one before merging it is the
expected way to inspect a finished run.

**Base-branch detection** (for the empty / branch-name forms). Do not assume `master`:

1. `git symbolic-ref refs/remotes/origin/HEAD 2>/dev/null | sed 's@^refs/remotes/origin/@@'` — the remote's
   default branch, when set.
2. Otherwise the first of `main`, `master`, `develop` that resolves (`git rev-parse --verify <name>`).
3. Confirm the base. This is a short question, so the brief is one line:
   - Brief: name the detected branch and how it was detected, and list the other candidates found.
   - Question: "Walk through against which base branch?"
   - Header: "Base branch"
   - Options: the detected branch first, then the other candidates

   Do not add an "Other — I'll name it" option; the built-in `Other` already collects a branch name.

For a PR target, the base is `baseRefName` from `gh pr view` — no prompt needed.

**Gather, for every target:**

- `git diff <base>...<head>` (the unified diff) and `git diff <base>...<head> --stat`.
- `git log <base>..<head> --oneline` — the commit subjects are the author's own claim of what changed and why.
- For a PR: also the PR title/body and commit list from `gh pr view`.

If `gh` is not installed and a PR number was given, stop and say so ("`gh` (GitHub CLI) is required to walk
a PR by number — pass a branch name or two refs instead, or install `gh`").

## Mapping the Diff to Specs (feature → UC → scenario)

Build a hierarchical map from the changed files up to the spec, so the walkthrough can group changes by
feature. For each changed path:

1. **Module** — resolve from `specs/MODULES.md` (the module whose `Directory` prefixes the path).
2. **FEAT / UC / SC** — read the traceability comments the code carries (principles §5.1): `// FEAT-XXXX`,
   `// UC-XXXX` at the file head, and `// SC-XXXX, SC-YYYY` above the functions the diff touches. The comment
   syntax follows the language (`//`, `#`, `--`, `/* */`).
3. **Cross-reference the spec tree** to confirm and enrich: `specs/features/{module}/FEAT-*/UC-XXXX-*.md`
   (the module is the segment under `specs/features/`); scenarios (`SC-XXXX`) live **inline** in the UC spec
   file. Read the touched UC's scenarios — they are the behavioral source of truth. Two more sources enrich
   the map when they exist: the module's `specs/modules/{module}/INTERFACE.md` element rows tie changed
   public elements to spec IDs, and — when the change came through a run — the `covers` lists in
   `specs/changes/{change-id}/plan.json` are the canonical machine-readable FEAT→UC→SC→file map, and the
   change's `request.md` and `decisions.md` state what the change was meant to do and what the run decided
   alone.
4. **Integration test** — the canonical path is `{module.Tests}/{feature-dir}/{uc-dir}.{ext}`
   (`module.Tests` from `specs/MODULES.md`). Grep the changed symbols against the module's tests tree to see
   what actually asserts them.

The result is a tree: **FEAT → UC → SC → the changed files/functions under it**, each SC carrying its spec
quote and its integration-test path (or a `[missing]` marker). A changed file that carries no `FEAT/UC/SC`
comment and matches no spec is recorded as **unmapped** — name it plainly; it has no spec authority.
