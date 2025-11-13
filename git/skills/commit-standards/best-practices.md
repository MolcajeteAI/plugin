# Git Workflow Best Practices

## Commit Timing

### Make Atomic Commits
Each commit should represent one logical change:
- ✅ One bug fix per commit
- ✅ One feature per commit
- ✅ One refactoring per commit

Don't mix unrelated changes:
- ❌ Fixing a bug AND adding a feature
- ❌ Updating dependencies AND refactoring code

### Commit Often
Small, frequent commits are better than large, infrequent ones:
- Easier to review
- Easier to revert if needed
- Better git history
- Clearer project progression

## Before Committing

### Test Your Changes
Make sure your code works before committing:
- Run tests if available
- Test manually if needed
- Fix any errors or warnings
- Check for unintended changes

### Review Your Diff
Use `git diff --staged` to review what you're committing:
- Ensure no debug code is included
- Check for commented-out code
- Remove temporary changes
- Verify file permissions

### Stage Carefully
Only stage files related to your change:
```bash
# Good - stage specific files
git add src/auth.js tests/auth.test.js

# Avoid - staging everything blindly
git add .
```

## Commit Messages

### Write for Your Future Self
Your commit message should help you understand the change months from now:
- What changed?
- Why did it change?
- What was the context?

### Write for Your Team
Others will read your commits:
- Be clear and specific
- Use consistent style
- Explain non-obvious decisions

### Keep History Clean
Good commit messages make git history useful:
```bash
# Useful history
git log --oneline

a1b2c3d Adds user authentication
b2c3d4e Fixes login redirect
c3d4e5f Updates password validation
```

## When to Amend

### Amend for Small Fixes
Use `git commit --amend` for minor corrections to your last commit:
- Typos in commit message
- Forgotten files
- Small code fixes

### Don't Amend Pushed Commits
Only amend commits that haven't been pushed:
- Amending changes commit history
- Can cause problems for others
- Use a new commit instead

### Check Authorship Before Amending
```bash
# Check who authored the commit
git log -1 --format='%an %ae'

# Only amend if it's your commit
```

## What NOT to Commit

### Never Commit Secrets
Don't commit sensitive information:
- API keys
- Passwords
- Private keys
- Access tokens
- `.env` files with secrets

### Avoid Committing Generated Files
Don't commit files that are built:
- `node_modules/`
- `dist/` or `build/`
- Compiled binaries
- IDE settings (unless intentional)

Add these to `.gitignore` instead.

### Don't Commit Debug Code
Remove before committing:
- `console.log()` statements
- Commented-out code blocks
- Temporary test data
- Debug flags

## Commit Message Rules

### ABSOLUTELY CRITICAL: NEVER MENTION AI OR TOOLS

THIS IS MANDATORY - NO EXCEPTIONS:
- ❌ NEVER add "Generated with Claude Code"
- ❌ NEVER add "Co-Authored-By: Claude"
- ❌ NEVER add "In collaboration with Claude AI"
- ❌ NEVER add any 🤖 emoji or similar
- ❌ NEVER add "AI-assisted" or similar phrases
- ❌ NEVER add "Created using Copilot" or tool mentions
- ❌ NEVER add attribution links to Claude or AI tools
- ✅ ONLY write commit messages that look like normal human development

Your commits should look like normal development:
- ❌ "Generated with Claude"
- ❌ "AI-assisted refactoring"
- ❌ "Created using Copilot"
- ✅ "Refactors authentication logic"

### Focus on What, Not How
Describe the change, not the process:
- ❌ "Used AI to help fix the bug in login"
- ✅ "Fixes login redirect issue"

## Working with Branches

### Use Descriptive Branch Names
```bash
# Good
feature/user-authentication
fix/payment-processing
refactor/database-queries

# Avoid
temp
fix
my-branch
```

### Keep Branches Focused
One branch per feature or fix:
- Makes reviews easier
- Clearer purpose
- Easier to merge or revert

### Clean Up After Merging
Delete branches after merging:
```bash
git branch -d feature/user-authentication
```

## Review Before Pushing

### Check Your Commits
```bash
# Review last 3 commits
git log -3

# Review changes in last commit
git show
```

### Verify Tests Pass
If your project has tests:
- Run full test suite
- Fix any failures
- Ensure CI will pass

### Consider Your Team
Before pushing:
- Are commit messages clear?
- Is the code ready for review?
- Did you follow team conventions?

## Emergency Situations

### If You Committed a Secret
1. Don't just delete the file
2. The secret is in git history
3. Rotate/invalidate the secret immediately
4. Use tools like `git-filter-repo` to remove from history

### If You Committed to Wrong Branch
```bash
# Move last commit to another branch
git reset HEAD~1
git stash
git checkout correct-branch
git stash pop
git add .
git commit
```

### If You Need to Undo Last Commit
```bash
# Keep changes, undo commit
git reset --soft HEAD~1

# Discard changes and commit
git reset --hard HEAD~1
```
