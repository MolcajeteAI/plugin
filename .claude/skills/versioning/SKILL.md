---
name: versioning
description: Version bump conventions and changelog update rules for the m plugin
---

# Versioning

## Semantic Versioning

The `m` plugin follows semantic versioning (`MAJOR.MINOR.PATCH`):

| Bump | When |
|------|------|
| `patch` | Bug fixes, typo corrections, minor skill/command refinements |
| `minor` | New commands, new skills, notable skill enhancements |
| `major` | Breaking changes to command interfaces, skill restructuring, plugin format changes |

## Version Location

The canonical version lives in `molcajete/.claude-plugin/plugin.json` under the `"version"` field.

## Bump Script

Use `scripts/bump.sh` to increment the version:

```bash
./scripts/bump.sh patch   # 2.3.9 -> 2.3.10
./scripts/bump.sh minor   # 2.3.9 -> 2.4.0
./scripts/bump.sh major   # 2.3.9 -> 3.0.0
```

## Changelog

After bumping, update `prd/changelog.md` with:

1. The new version number and date as a heading
2. A categorized list of changes using these sections:

| Section | Content |
|---------|---------|
| Added | New commands, skills, or features |
| Changed | Updates to existing commands or skills |
| Fixed | Bug fixes and corrections |
| Removed | Deleted commands, skills, or deprecated items |

## Workflow

1. Make all changes to commands/skills
2. Run `scripts/bump.sh <level>`
3. Add changelog entry to `prd/changelog.md`
4. Commit with message: `Bumps version to X.Y.Z`
