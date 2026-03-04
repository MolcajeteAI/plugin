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

### 6.2: Get Ours and Theirs Versions

For each conflicted file, extract both sides using git and get the conflicted file content. Run all three via Bash:

```bash
git show :2:{file path} > $TMPDIR/ours.txt
git show :3:{file path} > $TMPDIR/theirs.txt
cat {file path}
```

- `:2:` is the ours version (the branch being rebased onto)
- `:3:` is the theirs version (the commit being replayed)
- `cat` shows the file with conflict markers so you can identify individual hunks

Count the total number of conflict hunks (each `<<<<<<<`...`>>>>>>>` block is one hunk).

Rules for structured content (changelogs, configs, package lists, imports):
- NEVER duplicate section headers, date headers, or group keys — merge entries under shared headers
- Sort entries according to the file's existing convention

### 6.3: Present Hunks One at a Time Using Diff

Process hunks **sequentially, one at a time**. For each hunk, generate a real diff — do NOT manually format diffs as text output.

**For each hunk, do these steps in order:**

**Step A — Write the "before" content.** Use the Write tool to save the ours side of this hunk (content between `<<<<<<<` and `=======`) to a temp file:

Write to `$TMPDIR/hunk_before.txt` — exact ours content, every line, no truncation.

**Step B — Write the resolved content.** Determine the correct merge (preserve intent of BOTH sides when possible). Use the Write tool to save the resolved content to a temp file:

Write to `$TMPDIR/hunk_after.txt` — exact resolved content, every line, no truncation.

**Do NOT use heredocs (`cat << EOF`).** Always use the Write tool for temp files.

**Step C — Generate the diff.** Run the diff command via Bash:

```bash
diff -u $TMPDIR/hunk_before.txt $TMPDIR/hunk_after.txt | tail -n +3
```

The `tail -n +3` strips the file headers, keeping only the `@@` hunks and `+`/`-` lines.

**Step D — Show the diff in your text response.** Do NOT rely on the Bash tool output being visible — it gets collapsed. Instead, copy the exact output from the diff command and paste it into your text response wrapped in a `` ```diff `` code fence:

````
Conflict in `{file path}` — hunk {n} of {total}: {1 sentence — what ours changed, what theirs changed, how the resolution combines them}

```diff
{paste the exact diff output here — verbatim from the diff command, do not modify it}
```
````

This is the only content the user sees. It must be in your text response, not inside a Bash tool result.

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
- Always generate diffs using the temp file + `diff -u` approach in Step 6.3. Never manually format diff output as text.
