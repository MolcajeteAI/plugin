---
description: Interactive git rebase with conflict resolution
model: claude-opus-4-6
allowed-tools: Read, Edit, Bash(*), AskUserQuestion
argument-hint: <base branch, e.g. "main" or "master">
---

# Rebase

You help the user rebase their current branch onto a target base branch. You perform safety checks, show the branch diff, get confirmation, and execute the rebase. Your greatest value is during conflict resolution: you deeply understand the intent behind each branch's changes and help the user arrive at a merge strategy that respects both intents, allowing them to coexist whenever possible.

**Base branch:** $ARGUMENTS

## Mandatory Requirements

**NEVER STAGE FILES UNLESS RESOLVING CONFLICTS.** During normal operation, do not run `git add`. The only exception is during conflict resolution (Step 6), where staging resolved files is part of the rebase workflow.

**USE AskUserQuestion FOR ALL CONFIRMATIONS.** Never ask questions as plain text. Never end your response with a question.

**NEVER FORCE PUSH WITHOUT EXPLICIT CONFIRMATION.** After rebase, if the branch was previously pushed, warn the user that force push is required and get explicit confirmation.

## Step 1: Validate Input

If `$ARGUMENTS` is empty or does not look like a branch name, use AskUserQuestion to ask:
- **Question:** "Which branch should I rebase onto?"
- **Header:** "Base branch"
- **Options:** ["master", "main"]
- **multiSelect:** false

## Step 2: Safety Checks

Run all checks using Bash. If any check fails, show the error and stop immediately.

### Check: Not on a Protected Branch

Run `git branch --show-current` to get the current branch name.

If the current branch is `main` or `master`, stop:

```
Cannot rebase — you are on {branch name}.

Rebasing the main branch rewrites shared history and is almost never correct.
Switch to your feature branch first:
  git checkout <your-branch>
```

### Check: Base Branch Exists

Run `git rev-parse --verify {base branch}` to confirm the target branch exists. Also try `origin/{base branch}` if the local branch doesn't exist.

If neither exists, stop:

```
Branch "{base branch}" not found locally or on the remote.

Check available branches:
  git branch -a
```

### Check: Clean Working Tree

Run `git status --porcelain`. If there are uncommitted changes, stop:

```
Cannot rebase with uncommitted changes.

Either commit or stash your changes first:
  git stash
  # or
  /m:commit
```

### Check: Branch Has Been Pushed

Run `git log origin/{current branch}..HEAD --oneline 2>/dev/null` and `git log HEAD..origin/{current branch} --oneline 2>/dev/null` to check if the branch has been pushed.

If the branch has been pushed, note this as a warning (do not stop — include it in the confirmation step).

## Step 3: Show Rebase Preview

Gather the preview data by running these commands via Bash:

1. `git log --oneline {base branch}..HEAD` — commits on this branch
2. `git log --oneline HEAD..{base branch} | wc -l` — how far behind
3. `git diff --stat {base branch}...HEAD` — file change summary

Present the summary:

```
Rebase Preview

Branch:  {current branch}
Onto:    {base branch}

Commits to rebase ({count}):
  {commit list}

Files changed: {stat summary}
Commits behind {base branch}: {count}
```

Do NOT show the full diff — rebases can involve thousands of lines. The diff will be shown hunk by hunk during conflict resolution (Step 6).

If the branch has been pushed, add:

```
Warning: This branch has been pushed to the remote.
After rebasing, you will need to force push: git push --force-with-lease
```

## Step 4: Get Confirmation

Use AskUserQuestion with:
- **Question:** "Proceed with rebase?"
- **Header:** "Rebase"
- **Options:** ["Yes, rebase" — Rebase {count} commits onto {base branch}]
- **multiSelect:** false

If the user declines, stop.

## Step 5: Execute Rebase

Run via Bash:

```bash
git rebase {base branch}
```

If the rebase completes without conflicts, skip to Step 7 (Post-Rebase).

## Step 6: Resolve Conflicts

This is the core of the rebase command. When conflicts occur, you analyze both branches' intent and propose an intelligent merge — presented to the user **one hunk at a time**.

### 6.1: Identify Conflicted Files

Run `git status` via Bash. Parse the output to identify:
- **Conflicted files** — listed as "both modified" or "both added"
- **Already resolved files** — cleanly merged by git

### 6.2: Read the Conflicted File

Read each conflicted file using the Read tool. The file contains conflict markers (`<<<<<<<`, `=======`, `>>>>>>>`) that delimit each hunk.

Count the total number of conflict hunks in the file (each `<<<<<<<`...`>>>>>>>` block is one hunk).

### 6.3: Resolve and Present Hunks One at a Time

Process hunks **sequentially, one at a time**. For each hunk:

1. Read the ours side (between `<<<<<<<` and `=======`) and the theirs side (between `=======` and `>>>>>>>`).
2. Propose a resolution that preserves the intent of BOTH sides whenever possible. Combine changes when complementary. Pick one side only when truly contradictory.
3. Present ONLY the proposed resolution as a diff block. Do NOT show the raw conflict markers or the git diff output.

Rules for structured content (changelogs, configs, package lists, imports):
- NEVER duplicate section headers, date headers, or group keys — merge entries under shared headers
- Sort entries according to the file's existing convention

**Output format** — show this as text output before the AskUserQuestion. Follow this format EXACTLY:

````
Conflict in `{file path}` — hunk {n} of {total}

{1-2 sentence explanation: what ours changed, what theirs changed, and how the resolution combines them}

```diff
{the ENTIRE resolved hunk — every single line, inside this one diff block}
```
````

**CRITICAL: The entire hunk goes inside a single `` ```diff `` ... `` ``` `` block.** Every line of the resolved content must be inside that block. Nothing outside it. No matter how many lines the hunk has — 5 lines or 500 lines — it all goes inside ONE diff block. Never split the content across multiple blocks. Never let content spill out as plain text.

**Diff formatting rules:**
- Use `diff` as the language tag — always `` ```diff ``, never anything else
- Lines that exist in both sides unchanged: no prefix (context)
- Lines only in ours that are being kept: no prefix (context)
- Lines only in theirs that are being added: prefix with `+`
- Lines from ours that are being replaced: prefix with `-`
- Lines replacing them in the resolution: prefix with `+`
- Every single line must appear — NEVER use `...` or ellipsis to truncate

**Example 1 — large changelog hunk with multi-line entries (both sides added entries under the same date):**

````
Conflict in `CHANGELOG.md` — hunk 1 of 1

Both branches added entries under `## 2026-02-28`. Merging all entries under a single header, sorted by timestamp descending.

```diff
 ## 2026-02-28
+- [18:30] Add rate limiting to API gateway (PROJ-042/2)
+  Configured per-route rate limits with Redis-backed sliding window. Added `X-RateLimit-Remaining` response header.
+  Fallback to in-memory store when Redis is unavailable.
+  - Plan: [task-PROJ-042--2.md](specs/plans/task-PROJ-042--2.md)
+  - Changelog: [changelog-PROJ-042--2.md](specs/plans/changelog-PROJ-042--2.md)
+
 - [16:00] Implement user profile page (PROJ-038/1)
   Added avatar upload with S3 presigned URLs, display name editing with validation,
   timezone selector, and email notification preferences. Includes 12 unit tests.
   - Plan: [task-PROJ-038--1.md](specs/plans/task-PROJ-038--1.md)
   - Changelog: [changelog-PROJ-038--1.md](specs/plans/changelog-PROJ-038--1.md)
+
+- [14:00] Fix session expiry redirect loop (PROJ-038/0.1)
+  Clears stale session cookie before redirecting to login. Adds `max-age` to cookie options.
+  - Plan: [task-PROJ-038--0.1.md](specs/plans/task-PROJ-038--0.1.md)
+  - Changelog: [changelog-PROJ-038--0.1.md](specs/plans/changelog-PROJ-038--0.1.md)

 - [12:00] Add OAuth2 provider configuration (PROJ-042/1)
   Added Google and GitHub OAuth2 flows. Config loaded from environment variables.
   - Plan: [task-PROJ-042--1.md](specs/plans/task-PROJ-042--1.md)
   - Changelog: [changelog-PROJ-042--1.md](specs/plans/changelog-PROJ-042--1.md)
```
````

Note how the ENTIRE hunk — including multi-line descriptions, links, and blank lines — is inside a single `` ```diff `` block. Nothing leaks out.

**Example 2 — overlapping function changes (both sides modified the same function):**

````
Conflict in `src/utils/auth.ts` — hunk 1 of 2

Ours added a `timeout` parameter; theirs added retry logic. Both changes are compatible — combining them.

```diff
-export async function authenticate(token: string) {
-  const result = await verifyToken(token);
+export async function authenticate(token: string, timeout = 5000) {
+  const result = await retry(() => verifyToken(token), { attempts: 3 });
   return result;
 }
```
````

**Example 3 — contradictory changes (only one side can win):**

````
Conflict in `package.json` — hunk 1 of 1

Ours set version to `2.1.0`, theirs set it to `3.0.0`. Keeping theirs since the base branch has the newer release.

```diff
-  "version": "2.1.0",
+  "version": "3.0.0",
```
````

**Then confirm** using AskUserQuestion:
- **Question:** "Accept this resolution for hunk {n} of {total} in `{file path}`?"
- **Header:** "Hunk {n}/{total}"
- **Options:**
  - "Accept" — Use the proposed resolution for this hunk
  - "Keep ours" — Take only the current branch's version of this hunk
  - "Keep theirs" — Take only the base branch's version of this hunk
  - "Abort rebase" — Cancel the entire rebase
- **multiSelect:** false

The tool automatically provides an "Other" option. If the user types in Other:
- Treat their input as instructions (e.g., "keep the function signature from ours but use the body from theirs")
- Apply their instructions to produce a new resolution
- Show the updated resolution and invoke AskUserQuestion again
- Repeat until the user selects an option

Only after the user confirms a hunk do you move to the next one.

### 6.5: Apply Resolutions

After each hunk is confirmed, edit the file to replace the conflict-marked section (`<<<<<<<` through `>>>>>>>`) with the confirmed resolution.

After ALL hunks in a file are resolved, stage the file:

```bash
git add {file path}
```

Then move to the next conflicted file (back to 6.1) if there are more.

### 6.6: Continue Rebase

After ALL conflicted files for the current commit are resolved and staged, run:

```bash
git rebase --continue
```

If new conflicts appear on the next commit being replayed, go back to Step 6.1 and repeat the process.

### 6.7: Abort Option

If the user selects "Abort rebase" at any point during conflict resolution:

```bash
git rebase --abort
```

Report that the rebase was cancelled and the branch is restored to its pre-rebase state.

## Step 7: Post-Rebase

After successful rebase:

1. Show the updated commit log: `git log --oneline -10`
2. If the branch was previously pushed, use AskUserQuestion:
   - **Question:** "The branch was previously pushed. Force push to update the remote?"
   - **Header:** "Force push"
   - **Options:** ["Yes, force push" — Run git push --force-with-lease, "No, skip" — Leave the remote as-is for now]

If the user confirms force push, run `git push --force-with-lease` (never `--force`).

## Rules

- Use AskUserQuestion for ALL user interaction. Never ask questions as plain text.
- Never force push without explicit user confirmation.
- Always use `--force-with-lease` instead of `--force` to prevent overwriting others' work.
- Never rebase main or master.
- Do not use the word "comprehensive" in any output.
- Do not add AI or tool attribution anywhere.
- If `git rebase` fails for reasons other than conflicts, report the error and suggest `git rebase --abort`.
- The goal of conflict resolution is to preserve the intent of BOTH branches whenever possible. Picking one side is the fallback, not the default.
- Use `git diff -- {file}` to get the real conflict diff. Do not reconstruct diffs manually.
