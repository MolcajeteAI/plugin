---
name: versioning
description: Version bump conventions for the m plugin — on request only, revision by default
---

# Versioning

## When to Bump

**Never bump the version on your own.** A bump happens only when the user asks — "bump version". A change commit never carries a version edit; the bump is always its own commit.

## Semantic Versioning

The `m` plugin follows semantic versioning (`MAJOR.MINOR.REVISION`):

| Bump | When |
|------|------|
| `revision` | Bug fixes, typo corrections, minor skill/command refinements — **the default when the user names no level** |
| `minor` | New commands, new skills, notable skill enhancements |
| `major` | Breaking changes to command interfaces, skill restructuring, plugin format changes |

## Version Location

The canonical version lives in `molcajete/.claude-plugin/plugin.json` under the `"version"` field. `molcajete/package.json` and the version line in the root `CLAUDE.md` mirror it.

## Bump Script

`scripts/bump.sh` does the whole bump: it updates all three version locations, commits "Bumps version to X.Y.Z", and tags `vX.Y.Z`.

```bash
./scripts/bump.sh            # revision: 3.25.0 -> 3.25.1
./scripts/bump.sh revision   # same
./scripts/bump.sh minor      # 3.25.0 -> 3.26.0
./scripts/bump.sh major      # 3.25.0 -> 4.0.0
```

## Workflow

1. The user asks for a bump.
2. Commit every pending change first — the bump commit carries only the version edits.
3. Run `scripts/bump.sh <level>`, with no level when the user named none.
