---
name: git-committing
description: >-
  Use when creating git commits, amending commits, or reviewing commit messages.
  Triggers on phrases like "commit my changes", "commit this", "commit what I have",
  "commit the staged changes", "make a commit", "save this as a commit",
  "create a commit", or any request to commit staged work.
  Also triggers via /m:commit command.
  Defines commit message standards: imperative verbs, 50-character limit,
  conventional commit prefixes adapted to the project's existing style,
  and absolutely no AI or tool attribution.
---

# Git Committing Standards

Standards for writing clear, concise git commit messages that communicate changes effectively.

## Commit Message Format

### Structure

```
<Verb> <what changed>

- <why detail 1>
- <why detail 2>
- <why detail 3>
```

The first line is the subject. The body (bullet points) is optional but recommended for non-trivial changes. Separate the subject from the body with a blank line.

### First Line Rules

1. **Start with an imperative verb** (capitalize the first letter):
   - **Adds** — New files, features, or functionality
   - **Fixes** — Bug fixes or corrections
   - **Updates** — Changes to existing features
   - **Removes** — Deletion of features, files, or code
   - **Refactors** — Code restructuring without changing behavior
   - **Improves** — Performance or quality enhancements
   - **Moves** — File or code relocation
   - **Renames** — Renaming files, variables, or functions
   - **Replaces** — Swapping one implementation for another
   - **Simplifies** — Reducing complexity

2. **Maximum 50 characters** for the first line. If it exceeds 50 characters, it is too long — move details to the body.

3. **Describe what changed**, not what was wrong:
   - Good: "Fixes login redirect after authentication"
   - Bad: "Fixes bug where users were stuck on login page"

4. **Use simple language** — Avoid jargon when plain words work:
   - Good: "Adds user search feature"
   - Bad: "Implements user discovery mechanism"

5. **Conventional commit prefixes** (`feat:`, `fix:`, `test:`, `chore:`, `docs:`, `refactor:`, `perf:`) — Use the appropriate prefix based on the staged changes. Check `git log --oneline -20` to adapt to the project's style — if the history does not use prefixes, skip them and use the verb-only format instead.
   - Project uses prefixes: `feat: Add user dashboard`
   - Project does not use prefixes: `Adds user dashboard`

### Body (Optional)

Use bullet points (hyphens, not paragraphs) to explain **why** when:
- The change affects multiple files or areas
- The reasoning is not obvious from the diff
- Multiple steps or trade-offs were involved

```
Refactors authentication flow

- Separates login and registration logic
- Makes code easier to test independently
- Removes duplicate token validation
- Prepares for OAuth integration
```

For simple, obvious changes, a single subject line is enough:

```
Fixes typo in README
```

```
Updates dependencies to latest versions
```

### Issue References

Place issue references at the end of the subject line in parentheses:

```
Fixes payment processing error (#123)
```

Do not use issue tracker language as the subject — "Resolves #123" says nothing about what changed.

See [references/message-format.md](./references/message-format.md) for detailed format rules.
See [references/examples.md](./references/examples.md) for good and bad examples.

## No AI Attribution (CRITICAL)

**THIS IS MANDATORY — NO EXCEPTIONS.**

When creating commit messages:
- NEVER add "Generated with Claude Code" or similar
- NEVER add "Co-Authored-By: Claude" or any AI co-author line
- NEVER add "In collaboration with Claude AI" or similar
- NEVER add any AI emoji (no robot emoji, no sparkles, no similar)
- NEVER add "AI-assisted" or similar phrases
- NEVER add "Created using Copilot" or any tool mentions
- NEVER add attribution links to Claude or AI tools

Commits must look like normal human development:
- Bad: "Refactors authentication logic with help from Claude"
- Bad: "AI-assisted refactoring of auth module"
- Good: "Refactors authentication logic"

**Focus on what changed, not how it was produced.** The process of creating code is irrelevant to the commit message. Only describe the change itself.

## Commit Best Practices

### Make Atomic Commits

Each commit represents one logical change:
- One bug fix per commit
- One feature per commit
- One refactoring per commit

Do not mix unrelated changes:
- Bad: Fixing a bug AND adding a feature in one commit
- Bad: Updating dependencies AND refactoring code in one commit

Small, frequent commits are better than large, infrequent ones: easier to review, easier to revert if needed, better git history, clearer project progression.

### Review the Diff Before Committing

Use `git diff --staged` to check:
- No debug code included (`console.log`, print statements)
- No commented-out code
- No temporary changes
- No unintended file changes

### Stage Specific Files

Only stage files related to the change:

```bash
# GOOD: Stage specific files
git add src/auth.js tests/auth.test.js

# AVOID: Staging everything blindly
git add .
```

### Test Changes Before Committing

- Run tests if available
- Test manually if needed
- Fix errors or warnings before committing

### Never Commit Secrets

Do not commit: API keys, passwords, private keys, access tokens, `.env` files with secrets.

### Never Commit Debug Code

Remove before committing: `console.log()` statements, commented-out code blocks, temporary test data, debug flags.

### Write for Future Readers

Commit messages should help understand the change months from now:
- What changed?
- Why did it change?
- What was the context?

Good commit history makes `git log --oneline` a useful project timeline:

```
a1b2c3d Adds user authentication
b2c3d4e Fixes login redirect
c3d4e5f Updates password validation
d4e5f6g Refactors token handling
```

### Emergency: Committed a Secret

1. Do not just delete the file — the secret is in git history
2. Rotate or invalidate the secret immediately
3. Use tools like `git-filter-repo` to remove from history

### Emergency: Committed to Wrong Branch

```bash
git reset HEAD~1    # Undo commit, keep changes
git stash           # Stash changes
git checkout correct-branch
git stash pop       # Apply changes
git add .
git commit
```

## Amend Safety

### When to Amend

Use `git commit --amend` only for minor corrections to the last commit:
- Typos in the commit message
- Forgotten files
- Small code fixes

### Amend Rules

1. **Only amend unpushed commits** — Never amend commits that have been pushed to a shared remote. Amending rewrites history and causes problems for other contributors.
2. **Check authorship first** — Verify with `git log -1 --format='%an %ae'` that the commit is yours before amending.
3. **Use a new commit for significant changes** — If the fix is more than trivial, create a new commit instead of amending.

---

## Commit Orchestration

This workflow runs when the user asks to commit (natural language or `/m:commit`).

### Mandatory Requirements

**NEVER STAGE FILES.** Do not run `git add`, `git reset`, or `git restore --staged`. Only commit what is already staged. If nothing is staged, stop with an error.

**NEVER ADD AI ATTRIBUTION.** No "Generated with Claude Code", no "Co-Authored-By: Claude", no AI emoji, no tool mentions. Commits must look like normal human development.

**USE AskUserQuestion FOR ALL CONFIRMATIONS.** Never ask questions as plain text. Never end your response with a question. The only way to ask for confirmation is the AskUserQuestion tool.

### Step 1: Verify Staged Changes

Run `git diff --staged --stat` using Bash.

If no staged changes exist, show this error and stop:

```
No staged changes found.

Stage your changes first:
  git add <files>
```

Do not offer to stage files. Do not run `git add`. Stop immediately.

### Step 2: Assess Scope

Run `git diff --staged --stat` and `git diff --staged` to understand the scope of the staged changes.

A commit is **too large** when the staged changes contain **2 or more logically independent concerns**. Examples:
- A new feature AND an unrelated bug fix
- A refactor AND a dependency update
- Changes to module A's API AND an unrelated config change to module B
- A new command AND a skill update AND a version bump (these are related -- one logical change)

**Related changes are NOT too large.** A version bump + changelog + the feature it describes = one logical unit. Multiple files touched by one feature = one logical unit. Judge by intent, not by file count.

If the changes represent a single logical concern, proceed to Step 3 (single commit flow).

If the changes contain multiple independent concerns, proceed to Step 2b (split flow).

### Step 2b: Offer to Split

Use AskUserQuestion:
- **Question:** "These staged changes touch multiple independent concerns:\n\n{list each concern as a bullet with affected files}\n\nWant to split them into separate commits?"
- **Header:** "Split"
- **Options:**
  1. "Split into {N} commits" -- Break into logical commits
  2. "Commit everything together" -- Single commit as-is
- **multiSelect:** false

If the user chooses to commit everything together, proceed to Step 3 (single commit flow).

If the user chooses to split, proceed to Step 2c.

### Step 2c: Plan the Split

Launch a Task with `subagent_type="general-purpose"`:

```
Analyze the staged changes and plan how to split them into logical, atomic commits.

Read the commit standards:
- ${CLAUDE_PLUGIN_ROOT}/skills/git-committing/SKILL.md
- ${CLAUDE_PLUGIN_ROOT}/skills/git-committing/references/message-format.md

Then:
1. Run `git diff --staged --stat` for file summary
2. Run `git diff --staged` for full changes
3. For each changed file, read the full file to understand context
4. Run `git log --oneline -10` to match project commit style

Group the changes into logical, atomic commits. Each commit should represent one concern.

Return a JSON array of commit groups. Each group has:
- "message": the commit message (following the skill's rules)
- "files": array of file paths to include in this commit
- "reason": one sentence explaining why these files belong together

Example:
[
  {"message": "Adds user search endpoint\n\n- Adds GET /users/search with query parameter\n- Includes pagination support", "files": ["src/routes/users.ts", "src/services/search.ts", "tests/routes/users.test.ts"], "reason": "All files implement the search feature"},
  {"message": "Fixes typo in README", "files": ["README.md"], "reason": "Unrelated documentation fix"}
]

Return ONLY the JSON array, nothing else.
```

### Step 2d: Execute Split Commits

**Before starting the loop:**

1. **Capture the originally staged files:** Run `git diff --staged --name-only` and store the list as `ORIGINALLY_STAGED`.
2. **Unstage everything:** Run `git reset HEAD -- .` to clear the staging area. This does not touch the working tree -- all changes remain as unstaged modifications.

**For each commit group, in order:**

1. **Stage only this group's files:** `git add {files}`
2. **Show the commit to the user** using AskUserQuestion:
   - **Question:** "Commit {N} of {total}:\n\n```\n{message}\n```\n\nFiles: {file list}"
   - **Header:** "Commit {N}/{total}"
   - **Options:**
     1. "Yes, commit" -- Commit this group
     2. "Skip this one" -- Move to next group without committing
   - **multiSelect:** false
3. If confirmed, write message to `/tmp/claude/commit-msg.txt` and run `git commit -F /tmp/claude/commit-msg.txt && rm /tmp/claude/commit-msg.txt && git log --oneline -1`
4. If skipped, run `git reset HEAD -- {files}` to unstage this group's files back to the working tree, then continue to next group.

**After all groups are processed:**

- Collect the files from any skipped groups. Re-stage them so the user's staging area reflects what they had minus what was committed: `git add {skipped files}`.
- Files that were NOT in `ORIGINALLY_STAGED` are never touched -- they remain as unstaged working tree changes throughout.

Report all commits created (hash + message for each).

### Step 3: Draft Commit Message (Sub-Agent)

Launch a Task with `subagent_type="general-purpose"`:

```
Analyze the staged changes and draft a commit message. Do NOT execute any commit.

Read the commit standards skill first:
- ${CLAUDE_PLUGIN_ROOT}/skills/git-committing/SKILL.md
- ${CLAUDE_PLUGIN_ROOT}/skills/git-committing/references/message-format.md
- ${CLAUDE_PLUGIN_ROOT}/skills/git-committing/references/examples.md

Then:
1. Run `git diff --staged` to see full changes
2. Run `git diff --staged --stat` for file summary
3. For each changed file, read the full file to understand the context of the changes (not just the diff hunks)
4. Run `git log --oneline -10` to match project commit style (conventional prefixes or not)
5. Draft a commit message following the skill's rules:
   - Imperative verb (Adds, Fixes, Updates, Removes, Refactors, Improves, etc.)
   - First line under 50 characters
   - Body bullet points only when the change is non-trivial
   - Match project convention for prefixes
   - NEVER mention AI, Claude, or tools

Return ONLY the commit message text, nothing else. No explanation, no preamble. Just the message.
```

### Step 4: Get Confirmation

Take the message returned by the sub-agent and use AskUserQuestion:
- **Question:** "Commit with this message?\n\n```\n{message from sub-agent}\n```"
- **Header:** "Commit"
- **Options:**
  1. "Yes, commit" -- Commit with this message
  2. "Edit message" -- Modify the commit message
- **multiSelect:** false

If the user types in Other or selects "Edit message":
- Treat their input as instructions to modify the message
- Update the message accordingly
- Invoke AskUserQuestion again with the updated message
- Repeat until the user selects "Yes, commit"

### Step 5: Execute Commit

After confirmation, write the commit message file using the **Write tool**, then commit using Bash. Do NOT use heredocs -- zsh's internal heredoc temp file creation is blocked by the sandbox.

1. Use the **Write tool** to create `/tmp/claude/commit-msg.txt` with the confirmed message
2. Then run in a **single Bash call**:

```bash
git commit -F /tmp/claude/commit-msg.txt && rm /tmp/claude/commit-msg.txt && git log --oneline -1
```

Report the result: show the commit hash and message.

### Orchestration Rules

- Use AskUserQuestion for ALL user interaction. Never ask questions as plain text.
- In the single-commit flow (Steps 3-5): never stage or unstage files. The user manages staging.
- In the split flow (Step 2d): staging is managed by the orchestration. Only stage files from `ORIGINALLY_STAGED`. Never touch files that were not originally staged.
- Never add AI or tool attribution to commit messages.
- Show the complete message in the confirmation prompt, never a summary.
- The sub-agent drafts messages. You handle confirmation and execution.
- During split flow, if any commit fails, re-stage all remaining uncommitted files from `ORIGINALLY_STAGED` so the user's staging area is restored, then stop and report the error.

---

## Reference Files

| File | Description |
|---|---|
| [references/message-format.md](./references/message-format.md) | Detailed commit message format rules, verb list, body guidelines |
| [references/examples.md](./references/examples.md) | Good and bad commit message examples for common scenarios |
