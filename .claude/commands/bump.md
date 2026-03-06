---
description: Bump plugin version and update changelog
model: sonnet
allowed-tools:
  - Read
  - Edit
  - Write
  - Bash
  - Glob
  - Grep
---

# /bump

Bump the plugin version and update the changelog.

## Input

The user provides:
- **Bump level**: `patch`, `minor`, or `major` (default: `patch`)
- **Summary**: Optional description of what changed

If the user does not specify a bump level, infer it from the changes:
- New commands or skills = `minor`
- Bug fixes, typo corrections, refinements = `patch`
- Breaking changes = `major`

## Skill

Load and apply: `molcajete/skills/versioning/SKILL.md`

## Workflow

### Step 1: Determine Changes

Read `prd/changelog.md` to understand the current version and recent entries. Then review the git diff against the last version bump commit to understand what changed.

```bash
git log --oneline --all | head -20
git diff $(git log --oneline --all --grep="Bumps version" -1 --format=%H)..HEAD --stat
```

### Step 2: Bump Version

Run the bump script:

```bash
./scripts/bump.sh <level>
```

### Step 3: Update Changelog

Add a new entry at the top of the changelog in `prd/changelog.md` following the format defined in the versioning skill. Use today's date.

Categorize changes into Added, Changed, Fixed, or Removed sections. Only include sections that have entries.

### Step 4: Summary

Output:
- Previous version and new version
- Changelog entry that was added
- Remind the user to commit when ready
