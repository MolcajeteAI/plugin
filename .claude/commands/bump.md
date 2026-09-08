---
description: Bump the plugin version (revision by default), commit, and tag
model: sonnet
allowed-tools:
  - Read
  - Bash
  - Glob
  - Grep
---

# /bump

Bump the plugin version. This command runs only when the user asks for a bump — never as part of a change.

## Input

The user provides:
- **Bump level**: `revision`, `minor`, or `major` (default: `revision`)

Never infer the level from the changes. When the user names no level, use `revision`.

## Skill

Load and apply: `.claude/skills/versioning/SKILL.md`

## Workflow

### Step 1: Check the tree

Run `git status --porcelain`. If uncommitted changes exist, stop and tell the user — the bump commit carries only the version edits, so pending work must be committed first.

### Step 2: Bump

Run the bump script. It updates `molcajete/.claude-plugin/plugin.json`, `molcajete/package.json`, and the `CLAUDE.md` version line, commits "Bumps version to X.Y.Z", and tags `vX.Y.Z`.

```bash
./scripts/bump.sh <level>
```

### Step 3: Summary

Output the previous version, the new version, and the tag name.
