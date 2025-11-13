# Git Plugin

Automated git workflow with intelligent commit message generation following best practices.

## Overview

The git plugin provides commands and agents to streamline git operations while maintaining high-quality commit messages. It enforces consistent commit standards across your projects without requiring manual formatting.

## Features

- **Smart Commit Messages** - Analyzes changes and generates clear, concise commit messages
- **Safe Amend** - Amend commits with safety checks to prevent issues
- **Commit Standards** - Enforces best practices for commit message format
- **Context Protection** - Uses subagent to prevent git history from filling main context
- **Error Handling** - Gracefully handles common git errors
- **Style Matching** - Adapts to existing project commit style

## Installation

The git plugin is installed as part of the Claude Code setup:

```bash
# From the claude-code repository
./scripts/install.sh
```

This installs all plugins to `~/.claude/plugins/`.

## Commands

### `/commit`

Analyzes staged changes and creates a well-formatted commit message.

**Usage:**
```
/commit
```

**Workflow:**
1. Checks for staged changes
2. Analyzes what changed
3. Generates appropriate commit message
4. Presents message for approval
5. Commits with approved message

**Example:**
```
$ git add src/auth.js tests/auth.test.js
$ /commit

I'll create this commit:

---
Adds user authentication

- Creates login function
- Adds password validation
- Includes unit tests
---

Does this look good?

> yes

✓ Committed successfully
```

### `/amend`

Amends the last commit with staged changes and an improved message.

**Usage:**
```
/amend
```

**Workflow:**
1. Performs safety checks (commit not pushed, authored by you)
2. Analyzes staged changes
3. Reviews current commit message
4. Generates improved commit message
5. Presents message for approval
6. Amends commit with approved message

**Example:**
```
$ git add src/auth-helper.js
$ /amend

Current commit message:
---
Adds user authentication
---

Will amend to:
---
Adds user authentication

- Creates login function
- Adds password validation
- Includes auth helper utility
---

Please confirm to amend the last commit with this message.

> yes

✓ Commit amended successfully
```

**Safety Features:**
- Checks if commit has been pushed to remote
- Verifies you authored the commit
- Clear error messages if amending is unsafe
- Prevents amending other developers' commits

**When to Use:**
- Adding forgotten files to last commit
- Improving the commit message
- Small fixes to last commit
- Before pushing to remote

**When NOT to Use:**
- Commit already pushed to remote
- Commit authored by someone else
- Commit that others have based work on

## Commit Standards

The plugin follows these standards for all commits:

### Message Format

```
<Verb> <what changed>

- <why detail 1>
- <why detail 2>
```

### Rules

1. **Start with imperative verb**
   - Adds, Fixes, Updates, Removes, Refactors, Improves

2. **Keep first line under 50 characters**
   - Be specific but concise

3. **Use simple language**
   - Avoid fancy words like "comprehensive" or "robust"
   - Focus on clarity

4. **Add bullet points for complex changes**
   - Explain why when not obvious
   - Keep bullets focused

5. **Never mention AI or tools**
   - No "Generated with Claude"
   - No "AI-assisted"
   - Commits should look like normal development

### Good Examples

```
Adds email verification

- Sends verification link on registration
- Blocks login until verified
- Adds resend option
```

```
Fixes payment timeout issue

- Increases timeout from 5s to 30s
- Retries failed requests once
- Shows error to user
```

```
Updates API from v1 to v2

- Migrates to new response format
- Updates error handling
- Maintains backward compatibility
```

### Bad Examples

```
❌ feat: add comprehensive user system
(Uses conventional prefix, too vague, fancy words)

❌ Fixed stuff
(Too vague)

❌ Adds feature (with Claude's help)
(Mentions AI)
```

## Skills

### commit-standards

Defines standards for writing clear commit messages.

**Files:**
- `SKILL.md` - Overview of commit standards
- `message-format.md` - Detailed formatting rules
- `examples.md` - Good and bad examples
- `best-practices.md` - Git workflow best practices

**When to use:**
- Creating commits
- Reviewing commit history
- Teaching others about commits
- Establishing git conventions

## Agents

### code-committer

Workflow agent that handles commit operations.

**Namespace:** `git:`

**Responsibilities:**
- Analyze staged changes
- Generate commit messages
- Execute commits
- Follow commit standards
- Protect main context

**Tool Access:** Bash (for git commands)

## How It Works

### Context Protection

The code-committer agent runs in a subagent to protect your main context from being filled with git history and diffs. This allows:
- Multiple commits without context overflow
- Clean main conversation
- Faster responses

### Smart Analysis

The agent analyzes:
1. **What changed** - Uses `git diff --staged`
2. **Change type** - Determines if it's a feature, fix, etc.
3. **Project style** - Checks `git log` to match existing patterns
4. **Complexity** - Decides if bullet points are needed

### Message Generation

The agent:
1. Chooses the right verb based on change type
2. Keeps first line concise and specific
3. Adds bullet points for complex changes
4. Uses simple, clear language
5. Never mentions AI or tools

## Configuration

### Namespace

Default namespace: `git:`

Commands can be called as:
- `/commit` (without namespace)
- `/git:commit` (with namespace)

### Customization

To customize commit standards:
1. Edit `skills/commit-standards/message-format.md`
2. Add project-specific rules
3. Update examples as needed

## Error Handling

### No Staged Changes

```
No staged changes found.

Please stage your changes first:
  git add <files>
```

**Solution:** Stage files and run command again.

### Not a Git Repository

```
Error: Not a git repository.

Initialize git first:
  git init
```

**Solution:** Initialize git or run from correct directory.

### Git Command Fails

```
Error: Git command failed

<actual error>

Please fix the issue and try again.
```

**Solution:** Read error message and resolve the issue.

## Best Practices

### Before Committing

1. **Review your changes**
   ```bash
   git diff --staged
   ```

2. **Run tests**
   - Ensure code works
   - Fix any failing tests

3. **Stage related files only**
   ```bash
   git add src/feature.js tests/feature.test.js
   ```

### Commit Timing

- **Commit often** - Small, focused commits
- **One change per commit** - Don't mix unrelated changes
- **Test before committing** - Ensure code works

### Message Quality

- **Be specific** - "Fixes login redirect" not "Fixes bug"
- **Be concise** - Keep first line under 50 chars
- **Add context** - Use bullets to explain why

## Examples

### Feature Addition

```bash
$ git add src/search.js src/components/SearchBar.jsx tests/search.test.js
$ /commit

Adds user search feature

- Creates search API endpoint
- Adds search bar component
- Includes fuzzy matching
- Adds pagination for results
```

### Bug Fix

```bash
$ git add src/payment.js
$ /commit

Fixes duplicate charge issue

- Adds transaction locking
- Prevents race conditions
- Logs all payment attempts
```

### Refactoring

```bash
$ git add src/db/*.js
$ /commit

Refactors database connection logic

- Separates connection and query logic
- Adds connection pooling
- Makes testing easier
```

### Simple Change

```bash
$ git add README.md
$ /commit

Updates installation instructions
```

### Amending a Commit

```bash
# Made a commit but forgot to add a file
$ git commit -m "Adds user profile page"
$ git add src/profile-validator.js

# Amend to include the forgotten file
$ /amend

Current commit message:
---
Adds user profile page
---

Will amend to:
---
Adds user profile page

- Creates profile view component
- Adds profile edit form
- Includes input validation
---

Please confirm to amend the last commit with this message.

> yes

✓ Commit amended successfully
```

## Troubleshooting

### Commit message too long

The agent should keep first line under 50 chars automatically. If it doesn't:
- Provide feedback: "Make first line shorter"
- Agent will revise

### Wrong verb chosen

Provide feedback:
- "This is a fix, not an addition"
- Agent will update the verb

### Missing important details

Provide feedback:
- "Add bullet about why we changed the timeout"
- Agent will add missing context

## Future Enhancements

Planned features:
- `/fixup <commit-hash>` - Create fixup commits for later squashing
- `/reword` - Change commit message without adding files
- `/uncommit` - Soft reset last commit
- Branch management commands
- Merge conflict resolution
- Stash operations
- Cherry-pick assistance
- Interactive rebase guidance
- Tag management

## Contributing

To improve the git plugin:

1. Edit skill files for better standards
2. Add examples for common scenarios
3. Update agent behavior in `agents/code-committer.md`
4. Test with real commits
5. Share improvements

## License

Part of the Claude Code plugin system.
