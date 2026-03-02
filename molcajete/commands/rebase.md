---
description: Interactive rebase helper
model: claude-opus-4-6
allowed-tools: Read, Edit, Write, Bash(*), Task, AskUserQuestion
argument-hint: <base branch, e.g. "main" or "master">
---

# Rebase

You help the user rebase their current branch onto a target base branch. You perform safety checks, show what will happen, get confirmation, execute the rebase, and intelligently resolve conflicts by understanding the intent of both branches.

**Base branch:** $ARGUMENTS

## Mandatory Requirements

**NEVER STAGE FILES UNLESS RESOLVING CONFLICTS.** During normal operation, do not run `git add`. The only exception is during conflict resolution (Step 6), where staging resolved files is part of the rebase workflow.

**USE AskUserQuestion FOR ALL CONFIRMATIONS.** Never ask questions as plain text. Never end your response with a question.

**NEVER FORCE PUSH WITHOUT EXPLICIT CONFIRMATION.** After rebase, if the branch was previously pushed, warn the user that force push is required and get explicit confirmation.

## Step 0: Detect Entry Scenario

**Run this FIRST, before anything else.** Determine whether a rebase is already in progress:

```bash
git rev-parse REBASE_HEAD 2>/dev/null
```

- **If REBASE_HEAD exists** → **Scenario B: In-progress rebase with conflicts.** Skip Steps 1–4 entirely. The rebase is paused mid-way — there are conflicted files waiting to be resolved.
- **If REBASE_HEAD does not exist** → **Scenario A: Fresh rebase.** Continue from Step 1.

For Scenario B, detect the target branch from the rebase state:
```bash
onto=$(cat .git/rebase-merge/onto 2>/dev/null || cat .git/rebase-apply/onto 2>/dev/null)
git branch --contains "$onto" --format='%(refname:short)' 2>/dev/null | head -5
```

Also recover the original branch name:
```bash
cat .git/rebase-merge/head-name 2>/dev/null | sed 's|refs/heads/||'
```

Use AskUserQuestion to confirm:
- **Question:** "A rebase is already in progress. Continue resolving conflicts?"
- **Header:** "In-progress rebase"
- **Options:**
  - "Yes, continue" — Resume conflict resolution
  - "Abort rebase" — Run `git rebase --abort` and restore the branch
- **multiSelect:** false

If the user aborts, run `git rebase --abort`, confirm the branch is restored, and stop.

If continuing, proceed to Step 5 (Understand Both Branches) to build context, then Step 6 (Resolve Conflicts).

## Step 1: Validate Input (Scenario A only)

If `$ARGUMENTS` is empty or does not look like a branch name, use AskUserQuestion to ask:
- **Question:** "Which branch should I rebase onto?"
- **Header:** "Base branch"
- **Options:** ["master", "main"]
- **multiSelect:** false

## Step 2: Safety Checks (Scenario A only)

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

## Step 3: Show Rebase Preview (Scenario A only)

Use a Task with `subagent_type="Bash"` to gather the preview data:

```
Run these commands and return their output:
1. git log --oneline {base branch}..HEAD
2. git log --oneline HEAD..{base branch} | wc -l
3. git diff --stat {base branch}...HEAD
```

Present a summary:

```
Rebase Preview

Branch: {current branch}
Onto:   {base branch}

Commits to rebase ({count}):
  {commit list}

Files changed on this branch: {count}
Commits behind {base branch}: {count}
```

If the branch has been pushed, add:

```
Warning: This branch has been pushed to the remote.
After rebasing, you will need to force push: git push --force-with-lease
```

## Step 4: Get Confirmation (Scenario A only)

Use AskUserQuestion with:
- **Question:** "{the preview summary from Step 3}\n\nProceed with rebase?"
- **Header:** "Rebase"
- **Options:** ["Yes, rebase" — Rebase {count} commits onto {base branch}]
- **multiSelect:** false

If the user declines, stop.

## Step 5: Understand Both Branches

**This step runs for both Scenario A and Scenario B.** Before resolving any conflicts, build a mental model of what each branch was trying to accomplish. This understanding drives every conflict resolution decision.

### 5.1: Find the Merge Base

For Scenario B (in-progress rebase):
```bash
git merge-base REBASE_HEAD {base branch}
```

For Scenario A (before starting the rebase):
```bash
git merge-base HEAD {base branch}
```

### 5.2: Analyze Both Branches' Intent (Parallel Sub-Agents)

Launch **two parallel** Tasks with `subagent_type="general-purpose"`:

**Sub-agent 1 — Current branch intent:**

```
Analyze the intent of the current branch (the one being rebased). This is research only — do not modify any files.

Run these commands:
1. `git log --format='%h %s%n%b' {merge-base}..{REBASE_HEAD or HEAD}` — full commit messages
2. `git diff --stat {merge-base}..{REBASE_HEAD or HEAD}` — which files were touched
3. `git diff {merge-base}..{REBASE_HEAD or HEAD}` — the actual changes
4. For key changed files, read the full file to understand broader context

Return:
CURRENT_BRANCH_INTENT:
- Purpose: {1-2 sentences: what was this branch trying to accomplish?}
- Key changes: {bullet list of the main things it did}
- Files modified: {list of files and what changed in each}
```

**Sub-agent 2 — Target branch intent:**

```
Analyze the intent of the target branch (the one being rebased onto). This is research only — do not modify any files.

Run these commands:
1. `git log --format='%h %s%n%b' {merge-base}..{base branch}` — full commit messages
2. `git diff --stat {merge-base}..{base branch}` — which files were touched
3. `git diff {merge-base}..{base branch}` — the actual changes
4. For key changed files, read the full file to understand broader context

Return:
TARGET_BRANCH_INTENT:
- Purpose: {1-2 sentences: what was this branch trying to accomplish?}
- Key changes: {bullet list of the main things it did}
- Files modified: {list of files and what changed in each}
```

### 5.3: Synthesize and Present

Combine the results into a summary and show it to the user before proceeding:

```
Branch Analysis

Current branch was doing: {purpose}
Target branch was doing: {purpose}

Overlapping files: {files modified by both branches — these are likely conflict sources}
```

### 5.4: Execute Rebase (Scenario A only)

Run via Bash:

```bash
git rebase {base branch}
```

If the rebase completes without conflicts, skip to Step 7 (Post-Rebase).

## Step 6: Resolve Conflicts

This is the core of the rebase command. When conflicts occur, you analyze both branches' intent and propose an intelligent merge for each conflicted file.

### 6.1: Identify Conflicted Files

Run `git status` via Bash. Parse the output to identify:
- **Conflicted files** — listed as "both modified" or "both added"
- **Already resolved files** — cleanly merged by git

### 6.2: Analyze Each Conflicted File (Sub-Agent)

For **each conflicted file**, launch a Task with `subagent_type="general-purpose"` to deeply analyze the conflict:

```
Analyze a git rebase conflict and propose a resolution.

File: {file path}
Current branch: {current branch}
Base branch: {base branch}

Branch context from prior analysis:
- Current branch intent: {summary from Step 5}
- Target branch intent: {summary from Step 5}

Do the following:

1. Read the conflicted file at {file path} to see the conflict markers (<<<<<<< HEAD, =======, >>>>>>> {commit})

2. Understand what EACH SIDE intended:
   - Run `git log --oneline {base branch}..REBASE_HEAD -- {file path}` to see commits from the current branch that touched this file
   - Run `git log --oneline REBASE_HEAD..{base branch} -- {file path}` to see commits from the base branch that touched this file
   - Run `git show REBASE_HEAD:{file path}` to see the current branch's full version (ours during rebase)
   - Run `git show {base branch}:{file path}` to see the base branch's full version (theirs during rebase)

3. Read surrounding files if needed to understand the broader context:
   - Check imports/exports that the conflicted code depends on
   - Check callers of functions involved in the conflict
   - Check type definitions referenced by the conflicted code

4. Determine the intent of each branch:
   - What was the current branch trying to achieve in this file?
   - What was the base branch trying to achieve in this file?
   - Are the changes complementary (both can coexist), contradictory (only one can win), or overlapping (same area, different approaches)?

5. Propose a resolution:
   - **Best option: Combine both changes.** If the changes are complementary or overlapping but compatible, write the merged version that preserves the intent of BOTH branches. This is the ideal outcome.
   - **Second option: Pick one side.** If the changes are truly contradictory and cannot be combined, recommend which side to keep and explain why.

Return your response in this exact format:

ANALYSIS:
- Current branch intent: {what the current branch was trying to do}
- Base branch intent: {what the base branch was trying to do}
- Conflict type: {complementary | contradictory | overlapping}

PROPOSED_RESOLUTION:
{The complete resolved content for the conflicted sections — no conflict markers, ready to use. Show enough surrounding context (5-10 lines before and after) so the user can verify the placement.}

EXPLANATION:
{2-3 sentences explaining why this resolution is correct and how it preserves both branches' intent.}
```

### 6.3: Present Resolution to User

For each conflicted file, present the sub-agent's analysis and proposed resolution, then use AskUserQuestion:

- **Question:** "Conflict in `{file path}`:\n\n**Current branch ({current branch}) intended:** {current branch intent}\n**Base branch ({base branch}) intended:** {base branch intent}\n\n**Proposed resolution:**\n```\n{proposed resolution}\n```\n\n{explanation}"
- **Header:** "Conflict"
- **Options:**
  - "Accept proposal" — Use the proposed merged resolution
  - "Keep {current branch}" — Take only the current branch's changes
  - "Keep {base branch}" — Take only the base branch's changes
- **multiSelect:** false

The tool automatically provides an "Other" option. If the user types in Other:
- Treat their input as instructions (e.g., "keep the function from current branch but use the imports from base branch")
- Apply their instructions to produce a new resolution
- Invoke AskUserQuestion again with the updated proposal
- Repeat until the user selects an option

### 6.4: Apply Resolution

Based on the user's choice:

- **"Accept proposal"** — Write the resolved content to the file using the proposed resolution. Apply the changes by editing the conflicted sections to replace conflict markers with the resolved content.
- **"Keep {current branch}"** — Run `git checkout --ours -- {file path}` via Bash
- **"Keep {base branch}"** — Run `git checkout --theirs -- {file path}` via Bash

After resolving, stage the file:

```bash
git add {file path}
```

### 6.5: Continue Rebase

After ALL conflicted files for the current commit are resolved and staged, run:

```bash
git rebase --continue
```

If new conflicts appear on the next commit being replayed, go back to Step 6.1 and repeat the process.

### 6.6: Abort Option

At any point during conflict resolution, include an "Abort rebase" option in the AskUserQuestion choices. If selected:

```bash
git rebase --abort
```

Report that the rebase was cancelled and the branch is restored to its pre-rebase state.

## Step 7: Post-Rebase

After successful rebase:

1. Show the updated commit log: `git log --oneline -10`

2. Use AskUserQuestion to confirm satisfaction:
   - **Question:** "The rebase is complete. Are you satisfied with the result?"
   - **Header:** "Result"
   - **Options:** ["Yes, looks good" — Keep the rebase result]
   - **multiSelect:** false

   The "Other" option lets the user describe concerns. If unsatisfied, discuss what to adjust.

3. If the branch was previously pushed, use a follow-up AskUserQuestion:
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
- Delegate file reading and git analysis to sub-agents to keep the main context clean.
- The goal of conflict resolution is to preserve the intent of BOTH branches whenever possible. Picking one side is the fallback, not the default.
- Never run `git rebase --continue` or write conflict resolutions without explicit user confirmation.
- Never silently drop code from either branch.
- Always explain the *intent* behind each proposed resolution — not just what changed.
- Read actual commit messages and diffs to understand intent. Do not guess.

## Conflict Resolution Principles

When resolving conflicts, apply these in order:

1. **Preserve functional intent** — If both branches added distinct functionality, include both. Never silently drop features.
2. **Prefer the target branch's structure** — Since we're rebasing onto it, its organization takes precedence for shared scaffolding (imports, file layout, config).
3. **Prefer the current branch's logic** — The current branch's specific changes (the ones being rebased) take precedence for the work being carried forward.
4. **When in doubt, ask** — Never silently discard code. Surface the ambiguity to the user via AskUserQuestion.
