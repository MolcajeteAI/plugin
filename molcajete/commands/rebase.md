---
description: Rebase current branch onto a target branch with safety checks, preview, and intelligent conflict resolution that understands both branches' intent
model: claude-opus-4-6
allowed-tools: Read, Edit, Write, Bash(*), Task, AskUserQuestion
argument-hint: <base branch, e.g. "main" or "master">
---

# Rebase

You help the user rebase their current branch onto a target base branch. You perform safety checks, show what will happen, get confirmation, execute the rebase, and intelligently resolve conflicts by understanding the intent of both branches.

**Base branch:** $ARGUMENTS

## Mandatory Requirements

**NEVER STAGE FILES UNLESS RESOLVING CONFLICTS.** During normal operation, do not run `git add`. The only exception is during conflict resolution (Step 7), where staging resolved files is part of the rebase workflow.

**USE AskUserQuestion FOR ALL CONFIRMATIONS.** Never ask questions as plain text. Never end your response with a question.

**NEVER FORCE PUSH WITHOUT EXPLICIT CONFIRMATION.** After rebase, if the branch was previously pushed, warn the user that force push is required and get explicit confirmation.

## Step 1: Detect Entry Scenario

**Run this FIRST, before anything else.** Determine whether a rebase is already in progress:

```bash
git rev-parse REBASE_HEAD 2>/dev/null
```

- **If REBASE_HEAD exists** → **Scenario B: In-progress rebase with conflicts.** Skip to Step 4 (Analyze Branch Intent). The rebase is paused mid-way — there are conflicted files waiting to be resolved.
- **If REBASE_HEAD does not exist** → **Scenario A: Fresh rebase.** Continue from Step 2.

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

If continuing, proceed to Step 4 (Analyze Branch Intent) to build context, then Step 7 (Resolve Conflicts).

## Step 2: Validate Input (Scenario A only)

If `$ARGUMENTS` is empty or does not look like a branch name, use AskUserQuestion to ask:
- **Question:** "Which branch should I rebase onto?"
- **Header:** "Base branch"
- **Options:** ["master", "main"]
- **multiSelect:** false

## Step 3: Safety Checks (Scenario A only)

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

If the branch has been pushed, note this as a warning (do not stop — include it in the preview step).

## Step 4: Analyze Branch Intent (Conditional)

**This step runs for both Scenario A and Scenario B**, but only when the complexity warrants it.

### 4.1: Assess Complexity

Before launching sub-agents, quickly assess whether analysis is needed:

```bash
git merge-base HEAD {base branch}  # (or REBASE_HEAD for Scenario B)
```

Then check:
```bash
# Count files modified by both branches (overlap)
comm -12 \
  <(git diff --name-only {merge-base}..HEAD | sort) \
  <(git diff --name-only {merge-base}..{base branch} | sort)
```

**Skip analysis** (proceed directly to Step 5 for Scenario A, or Step 7 for Scenario B) when ALL of these are true:
- Zero or one overlapping files
- The diff is small (fewer than ~100 lines changed across both branches)
- The rebase intent is obvious from commit messages alone

**Run analysis** when ANY of these are true:
- Multiple overlapping files (files modified by both branches)
- Large or complex diffs
- Non-trivial merge base (branches diverged significantly)
- Scenario B (conflicts already exist — understanding intent is critical for resolution)

### 4.2: Analyze Both Branches' Intent (Parallel Sub-Agents)

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

IMPORTANT: Do NOT fetch the entire target branch history. The target branch may have hundreds of commits. Scope your analysis to commits that touch the overlapping files (files modified by both branches).

Run these commands:
1. For each overlapping file: `git log --format='%h %s%n%b' {merge-base}..{base branch} -- {file path}` — only commits touching that file
2. `git diff {merge-base}..{base branch} -- {overlapping files}` — changes scoped to overlapping files only
3. If you need broader context (e.g., to understand a rename or a moved function), expand to neighboring files but do NOT run an unscoped `git log` or `git diff` on the entire branch

Return:
TARGET_BRANCH_INTENT:
- Purpose: {1-2 sentences: what was this branch trying to accomplish in the overlapping files?}
- Key changes: {bullet list of the main things it did to the overlapping files}
- Files modified: {list of overlapping files and what changed in each}
```

### 4.3: Synthesize

Combine the results into a summary for use in subsequent steps:

```
Branch Analysis

Current branch was doing: {purpose}
Target branch was doing: {purpose}

Overlapping files: {files modified by both branches — these are likely conflict sources}
```

For Scenario A, this analysis feeds into the preview (Step 5). For Scenario B, it feeds into conflict resolution (Step 7).

## Step 5: Show Rebase Preview (Scenario A only)

Run these commands via Bash to gather the preview data:

```bash
git log --oneline {base branch}..HEAD
git log --oneline HEAD..{base branch} | wc -l
git diff --stat {base branch}...HEAD
git diff {base branch}...HEAD
```

Present the summary **and** the full diff to the user:

```
Rebase Preview

Branch: {current branch}
Onto:   {base branch}

Commits to rebase ({count}):
  {commit list}

Files changed on this branch: {count}
Commits behind {base branch}: {count}
```

If Step 4 ran, include the branch analysis summary:

```
Branch Analysis

Current branch was doing: {purpose}
Target branch was doing: {purpose}

Overlapping files: {list — these are likely conflict sources}
```

Then show the full diff output below the summary, inside a fenced code block with the `diff` language tag for syntax highlighting:

````
```diff
{output of git diff {base branch}...HEAD}
```
````

If the branch has been pushed, add:

```
Warning: This branch has been pushed to the remote.
After rebasing, you will need to force push: git push --force-with-lease
```

## Step 6: Confirm and Execute Rebase (Scenario A only)

### 6.1: Get Confirmation

Use AskUserQuestion with:
- **Question:** "{the preview summary from Step 5}\n\nProceed with rebase?"
- **Header:** "Rebase"
- **Options:** ["Yes, rebase" — Rebase {count} commits onto {base branch}]
- **multiSelect:** false

If the user declines, stop.

### 6.2: Execute Rebase

Run via Bash:

```bash
git rebase {base branch}
```

If the rebase completes without conflicts, skip to Step 8 (Post-Rebase).

If conflicts occur, proceed to Step 7. (If Step 4 was skipped earlier because the rebase looked simple, run Step 4 now before entering Step 7 — conflicts mean the analysis is needed after all.)

## Step 7: Resolve Conflicts

This is the core of the rebase command. When conflicts occur, you analyze both branches' intent (from Step 4) and propose an intelligent merge for each conflicted file.

### 7.1: Identify Conflicted Files

Run `git status` via Bash. Parse the output to identify:
- **Conflicted files** — listed as "both modified" or "both added"
- **Already resolved files** — cleanly merged by git

### 7.2: Analyze Each Conflicted File (Sub-Agent)

For **each conflicted file**, launch a Task with `subagent_type="general-purpose"` to analyze the conflict and propose resolutions **per conflict hunk**:

```
Analyze a git rebase conflict and propose a resolution for EACH individual conflict hunk.

File: {file path}
Current branch: {current branch}
Base branch: {base branch}

Branch context from prior analysis:
- Current branch intent: {summary from Step 4}
- Target branch intent: {summary from Step 4}

Do the following:

1. Read the conflicted file at {file path} to see the conflict markers (<<<<<<< HEAD, =======, >>>>>>> {commit})

2. Identify EACH separate conflict hunk in the file. A conflict hunk is one <<<<<<< ... ======= ... >>>>>>> block. Number them sequentially.

3. Understand what EACH SIDE intended:
   - Run `git log --oneline REBASE_HEAD..{base branch} -- {file path}` to see commits from the base branch that touched this file (scope to this file only — do NOT fetch the entire branch history)
   - Run `git log --oneline {merge-base}..REBASE_HEAD -- {file path}` to see commits from the current branch that touched this file
   - Run `git show REBASE_HEAD:{file path}` to see the current branch's full version
   - Run `git show {base branch}:{file path}` to see the base branch's full version

4. Read surrounding files if needed to understand the broader context:
   - Check imports/exports that the conflicted code depends on
   - Check callers of functions involved in the conflict
   - Check type definitions referenced by the conflicted code

5. For EACH conflict hunk, propose a resolution:
   - **Best option: Combine both changes.** If the changes are complementary or overlapping but compatible, write the merged version that preserves the intent of BOTH branches.
   - **Second option: Pick one side.** If the changes are truly contradictory and cannot be combined, recommend which side to keep.

Return your response in this exact format (repeat for each hunk):

HUNK {N} of {total}:
BEFORE (conflict markers as they appear in the file):
{The exact <<<<<<< ... ======= ... >>>>>>> block, including a few lines of surrounding context}

AFTER (proposed resolution):
{The resolved code — no conflict markers, ready to use. Include the same surrounding context lines so placement is clear.}
```

### 7.3: Present Each Conflict Hunk to User

Present conflict hunks **one at a time**. For each hunk, show ONLY the proposed resolved code — no analysis, no explanation, no commentary. The code speaks for itself.

Use AskUserQuestion with:
- **Question:** Show the proposed resolution as a fenced code block with appropriate language tag. Format:

  ````
  `{file path}` — conflict {N}/{total}

  ```{language}
  {the AFTER code from the sub-agent — the proposed resolved version with surrounding context}
  ```
  ````

- **Header:** "Conflict {N}/{total}"
- **Options:**
  - "Accept" — Use this resolution
  - "Keep {current branch}" — Take only the current branch's changes
  - "Keep {base branch}" — Take only the base branch's changes
- **multiSelect:** false

The tool automatically provides an "Other" option. If the user types in Other:
- Treat their input as instructions for how to resolve this specific hunk
- Apply their instructions to produce a new resolution
- Invoke AskUserQuestion again showing ONLY the updated code block
- Repeat until the user selects an option

Process all hunks in a file sequentially before moving to the next file.

### 7.4: Apply Resolutions

After all hunks in a file are decided, apply them:

- **"Accept"** hunks — Edit the file to replace each conflict block (<<<<<<< through >>>>>>>) with the accepted resolution code.
- **"Keep {current branch}"** hunks — Use the code from the <<<<<<< HEAD side.
- **"Keep {base branch}"** hunks — Use the code from the >>>>>>> side.

Apply all hunk resolutions for the file in a single pass (top to bottom), then stage:

After resolving, stage the file:

```bash
git add {file path}
```

### 7.5: Continue Rebase

After ALL conflicted files for the current commit are resolved and staged, run:

```bash
GIT_EDITOR=true git rebase --continue
```

Setting `GIT_EDITOR=true` accepts the original commit message without opening an editor.

If new conflicts appear on the next commit being replayed, go back to Step 7.1 and repeat the process.

### 7.6: Abort Option

At any point during conflict resolution, include an "Abort rebase" option in the AskUserQuestion choices. If selected:

```bash
git rebase --abort
```

Report that the rebase was cancelled and the branch is restored to its pre-rebase state.

## Step 8: Post-Rebase

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
