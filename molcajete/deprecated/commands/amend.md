---
description: Amend the last commit with staged changes
model: claude-sonnet-4-6
allowed-tools: Read, Bash(*), Task, AskUserQuestion
argument-hint: <optional: reason for amend>
---

# Amend

You orchestrate an amend workflow: perform safety checks, use a sub-agent to analyze changes and draft an improved message, then execute the amend after user confirmation.

**Context:** $ARGUMENTS

## Mandatory Requirements

**NEVER STAGE FILES.** Do not run `git add`, `git reset`, or `git restore --staged`. Only amend with what is already staged (if anything). The amend may only change the message if nothing is staged.

**NEVER ADD AI ATTRIBUTION.** No "Generated with Claude Code", no "Co-Authored-By: Claude", no AI emoji, no tool mentions.

**USE AskUserQuestion FOR ALL CONFIRMATIONS.** Never ask questions as plain text. Never end your response with a question.

## Step 1: Safety Checks (ALL MUST PASS)

Run these checks using Bash. If any check fails, show the error and stop immediately.

### Check 1: Commit Exists

Run `git log -1 --oneline`. If no commits exist, stop:

```
Cannot amend — no commits exist yet.

Use /m:commit to create your first commit.
```

### Check 2: Commit Is Not Pushed

Run `git status` and check for "Your branch is ahead of" or no upstream tracking.

If the commit has already been pushed to the remote, stop:

```
Cannot safely amend this commit.

Reason: This commit has already been pushed to the remote.
Amending pushed commits rewrites history and causes problems for collaborators.

Create a new commit instead with /m:commit
```

### Check 3: Commit Authorship

Run `git log -1 --format='%an <%ae>'` to check who authored the last commit.

If the commit was authored by someone else, stop:

```
Cannot safely amend this commit.

Reason: This commit was authored by {author name} <{author email}>.
You should only amend commits you created.

Create a new commit instead with /m:commit
```

## Step 2: Draft Improved Message (Sub-Agent)

Launch a Task with `subagent_type="general-purpose"` and the following prompt:

```
Analyze the current commit and any new staged changes, then draft an improved commit message. Do NOT execute any commit or amend.

Read the commit standards skill first:
- ${CLAUDE_PLUGIN_ROOT}/skills/git-committing/SKILL.md
- ${CLAUDE_PLUGIN_ROOT}/skills/git-committing/references/message-format.md
- ${CLAUDE_PLUGIN_ROOT}/skills/git-committing/references/examples.md

Then:
1. Run `git log -1 --format='%B'` to get the current commit message
2. Run `git diff --staged` to see new changes being added (may be empty)
3. Run `git diff --staged --stat` for file summary of new changes
4. Run `git show --stat HEAD` to see what the current commit contains
5. For each file involved (both current commit and new staged changes), read the full file to understand context
6. Run `git log --oneline -10` to match project commit style
7. Draft an improved commit message:
   - If new staged changes exist, incorporate them into the message
   - If no staged changes, improve the existing message
   - Follow the skill's formatting rules
   - NEVER mention AI, Claude, or tools
   {context_hint}

Return your response in this exact format:

CURRENT_MESSAGE:
{the current commit message}

NEW_MESSAGE:
{the improved commit message}
```

Replace `{context_hint}` with:
- If `$ARGUMENTS` is not empty: `8. Context for the amend: $ARGUMENTS`
- If `$ARGUMENTS` is empty: remove the line

## Step 3: Get Confirmation

Parse the sub-agent's response to extract the current and new messages. Use AskUserQuestion:
- **Question:** "Amend the last commit with this message?\n\nCurrent message:\n```\n{current message}\n```\n\nNew message:\n```\n{new message}\n```"
- **Header:** "Amend"
- **Options:** ["Yes, amend" — Amend with this message]
- **multiSelect:** false

If the user types in "Other":
- Treat their input as instructions to modify the new message
- Update the message and invoke AskUserQuestion again
- Repeat until the user selects "Yes, amend"

## Step 4: Execute Amend

After confirmation, write the commit message file using the **Write tool**, then amend using Bash. Do NOT use heredocs — zsh's internal heredoc temp file creation is blocked by the sandbox.

1. Use the **Write tool** to create `/tmp/claude/commit-msg.txt` with the confirmed message
2. Then run in a **single Bash call**:

```bash
git commit --amend -F /tmp/claude/commit-msg.txt && rm /tmp/claude/commit-msg.txt && git log --oneline -1
```

**Do NOT use heredocs (`<< 'EOF'`) in Bash** — zsh creates an internal temp file for heredoc processing in a location the sandbox blocks, even if the output targets `/tmp/claude/`.

Report the result: show the new commit hash and message.

## Rules

- Use AskUserQuestion for ALL user interaction. Never ask questions as plain text.
- Never stage or unstage files. The user manages staging.
- Never add AI or tool attribution to commit messages.
- Do not use the word "comprehensive" in any output.
- If any safety check fails, stop immediately. Do not proceed or offer workarounds.
- Show the complete before/after messages in the confirmation prompt.
- If `git commit --amend` fails (e.g., pre-commit hook), report the error. Do not retry automatically.
- The sub-agent drafts the message. You handle safety checks, confirmation, and execution.
