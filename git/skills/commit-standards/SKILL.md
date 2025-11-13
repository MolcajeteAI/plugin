---
name: commit-standards
description: Standards for writing clear, concise git commit messages. Use when creating commits, reviewing commit history, or establishing git workflow conventions.
---

# Commit Standards

Standards for writing clear, concise git commit messages that communicate changes effectively.

## Key Principles
1. **Start with an imperative verb** - adds, fixes, updates, removes, refactors
2. **Keep it short** - First line under 50 characters
3. **Be specific** - Describe what changed, not what was wrong
4. **Use simple language** - Avoid fancy or technical jargon when plain words work
5. **Add context when needed** - Use bullet points in the body to explain why

## Instructions

When creating a commit message:

1. Analyze the staged changes with `git diff --staged`
2. Review recent commits with `git log -5 --oneline` to match project style
3. Choose the appropriate verb based on change type:
   - **Adds** - New files, features, or functionality
   - **Fixes** - Bug fixes or corrections
   - **Updates** - Changes to existing features
   - **Refactors** - Code cleanup without changing behavior
   - **Removes** - Deleting files or features
   - **Improves** - Performance or quality enhancements
4. Keep the first line under 50 characters
5. Add bullet points in the body for complex changes
6. **ABSOLUTELY CRITICAL**: Never mention AI, Claude, or other tools in commit messages - NO attribution text, NO co-author lines, NO emoji, NO exceptions

## Examples

### Good Commit Messages
```
Adds user authentication

- Creates login and registration pages
- Adds JWT token handling
- Stores user session in localStorage
```

```
Fixes payment processing error

- Validates amount before charging
- Handles network timeouts
- Shows error message to user
```

```
Updates installation instructions
```

### Bad Commit Messages
❌ `update stuff`
❌ `fix bug`
❌ `WIP`
❌ `Refactors authentication logic with help from Claude`

## Related Files
- `message-format.md` - Detailed commit message format rules
- `examples.md` - Good and bad commit message examples
- `best-practices.md` - Git workflow best practices
