---
name: git-committing
description: >-
  Standards for structuring git commits during automated task execution. Covers
  message format, project style detection, atomic commit principles, scope
  assessment, and commit splitting. Read by build agents before committing work.
---

# Git Committing

Standards for how agents create git commits during task execution. This skill defines message format, style detection, atomicity rules, and scope assessment. It does not define a user-facing command — it is reference material for agents that commit as part of their work.


## Style Detection

Before writing any commit message, detect the project's existing style:

1. Run `git log --oneline -20` and examine the output
2. **Prefixes**: Default to conventional prefixes (`feat:`, `fix:`, `chore:`, etc.). Only drop them and use verb-only format if the majority of recent commits do NOT use prefixes.
3. **Verb tense**: Match the existing pattern. Most projects use either "Adds" (third person) or "Add" (imperative). Follow what's already there.
4. **Casing**: Match subject line casing — some projects capitalize after the prefix, some don't.

The detected style applies to all commits in the session. Do not mix styles.

## Message Format

### Structure

```
<prefix>: <what changed>

- <what was done detail 1>
- <what was done detail 2>

<FEAT-XXXX>
- <UC-XXXX>: <use case name>
  - <SC-XXXX>: <scenario name>
  - <SC-XXXX>: <scenario name>
```

The first line is the subject. The body (bullet points) is optional but recommended for non-trivial changes. The spec references block is mandatory when the commit has PRD context (see Spec References below). Separate each section with a blank line.

### Subject Line Rules

1. **Start with a verb** — capitalize the first letter (or follow prefix convention):
   - **Adds** — new files, features, or functionality
   - **Fixes** — bug fixes or corrections
   - **Updates** — changes to existing features
   - **Removes** — deletion of features, files, or code
   - **Refactors** — code restructuring without behavior change
   - **Improves** — performance or quality enhancements
   - **Moves** — file or code relocation
   - **Renames** — renaming files, variables, or functions
   - **Replaces** — swapping one implementation for another
   - **Simplifies** — reducing complexity

2. **Maximum 50 characters** — if it exceeds 50, move details to the body.

3. **Describe what changed**, not what was wrong — "Fixes login redirect after authentication", not "Fixes bug where users were stuck on login page".

4. **Use simple language** — "Adds user search feature", not "Implements user discovery mechanism".

### Conventional Commit Prefixes

Use conventional prefixes by default (see Style Detection). Only drop them if the project's history shows the majority of commits without prefixes.

| Prefix | Use When |
|--------|----------|
| `feat:` | New features or functionality |
| `fix:` | Bug fixes |
| `test:` | Adding or updating tests |
| `chore:` | Maintenance, dependencies, config |
| `docs:` | Documentation changes |
| `refactor:` | Code restructuring without behavior change |
| `perf:` | Performance improvements |

### Body Rules

Use bullet points to explain **why** when:
- The change affects multiple files or areas
- The reasoning is not obvious from the diff
- Multiple steps or trade-offs were involved

Bullets (hyphens), never prose. A paragraph body — "Refactors authentication flow to separate login and registration logic, making the code easier to test…" — becomes one hyphen bullet per aspect.

For simple, obvious changes, a single subject line is enough.

### Issue References

Place issue references at the end of the subject line in parentheses:

```
Fixes payment processing error (#123)
```

Do not use issue tracker language as the subject — "Resolves #123" says nothing about what changed.

## Spec References

When a commit is part of a task that has PRD context (feature, use cases, scenarios), include a spec references block at the end of the commit body, in the shape given under Structure above.

### Rules

1. Place the refs block **after** the description body, separated by a blank line
2. Feature ID alone on its own line (no label prefix like "Feature:" — just the ID)
3. Use cases as top-level bullets with their name
4. Scenarios indented under their parent use case with their name
5. Only include use cases and scenarios relevant to this commit, not the entire feature
6. **Mandatory** when the commit is part of a task with feature/UC/scenario context
7. **Omit** for commits with no PRD context (dependency updates, config changes, tooling)

IDs are the base-62 codes from the spec, not sequential numbers:

```
feat: Add user registration endpoint

- Creates registration handler with input validation
- Adds bcrypt password hashing
- Stores new user in database

FEAT-0R7e
- UC-0R8h: Register new user
  - SC-0R9n: Valid registration with all fields
  - SC-0R9o: Duplicate email rejected
```

A commit with no PRD context ends at the body — no refs block, no empty placeholder:

```
chore: Update dependencies to latest versions

- Bumps express from 4.18 to 4.19
- Updates jest to v30
```

## No AI Attribution

**Mandatory — no exceptions.**

- Never add "Generated with Claude Code" or similar
- Never add "Co-Authored-By: Claude" or any AI co-author line
- Never add AI emoji, "AI-assisted", or tool mentions

Commits must look like normal human development. Focus on what changed, not how it was produced.

## Atomic Commits

Each commit represents one logical change — one bug fix, one feature, or one refactoring. Never mix unrelated changes (a bug fix AND a new feature; a dependency update AND a refactor). Prefer small, frequent commits over large ones.

## Scope Assessment

After completing work, assess whether the changes should be one commit or multiple. Judge by intent, not by file count — a version bump + changelog + the feature it describes, or a new command + its skill + plugin registration, is **one** logical concern regardless of how many files it touches.

### Splitting Strategy

When changes need splitting:

1. Identify the independent concerns and their affected files
2. Group files by concern — each group becomes one commit
3. Order commits by dependency: infrastructure first, then features, then fixes
4. Stage and commit each group separately with its own message

## Pre-Commit Checklist

Read the diff before committing. It must contain no debug code (`console.log`, print statements, debugger), no commented-out code, no temporary test data or hardcoded values, no unintended file changes, and no secrets (API keys, passwords, tokens, `.env` files). Stage specific files, not `git add .`.

## References

| Reference | Purpose |
|-----------|---------|
| [references/examples.md](./references/examples.md) | Worked commit message examples, with and without PRD context |
