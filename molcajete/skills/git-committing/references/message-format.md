# Commit Message Format

## Structure

```
<Verb> <what changed>

Feature: <feature name>
Usecase: <UC-XXXX-NNN>

Summary:
- <change detail 1>
- <change detail 2>
- <change detail 3>
```

The first line is the subject. The body is optional but recommended for non-trivial changes.

When the commit relates to a tracked feature or use case, include `Feature:` and `Usecase:` lines in the body before the summary. Derive these from the task brief, plan file path, or `prd/specs/` context. If the commit is a chore or not tied to any feature, omit both lines.

## First Line Rules

### Start with an Imperative Verb

Use present tense verbs that describe what the commit does. Capitalize the first letter.

| Verb | Use When |
|---|---|
| **Adds** | New features, files, or functionality |
| **Fixes** | Bug fixes or corrections |
| **Updates** | Changes to existing features |
| **Removes** | Deletion of features, files, or code |
| **Refactors** | Code restructuring without behavior change |
| **Improves** | Performance or quality enhancements |
| **Moves** | File or code relocation |
| **Renames** | Renaming files, variables, or functions |
| **Replaces** | Swapping one implementation for another |
| **Simplifies** | Reducing complexity |

### Maximum 50 Characters

If the subject line exceeds 50 characters, it is too long. Move details to the body.

```
# Good — under 50 chars
Adds user authentication

# Bad — too long
Adds user authentication with JWT tokens and refresh token rotation
```

### Describe What Changed

Focus on the change itself, not the problem:
- Good: "Fixes login redirect after authentication"
- Bad: "Fixes bug where users were stuck on login page"

### Use Simple Language

Aim for clarity, not sophistication:
- Good: "Adds user search feature"
- Bad: "Implements user discovery mechanism"

### Conventional Commit Prefixes — Match Project Convention

Prefixes like `feat:`, `fix:`, `test:`, `chore:`, `docs:` are widely used. Use the appropriate prefix based on the staged changes, but adapt to the project's style — check `git log --oneline -20`. If the project's history does not use prefixes, skip them and use the verb-only format instead.

```
# Project USES prefixes — follow the convention
feat: Add user dashboard
fix: Resolve payment error
chore: Update dependencies

# Project DOES NOT use prefixes — use verb-only style
Adds user dashboard
Fixes payment processing error
Updates dependencies to latest versions
```

Common prefixes and their meaning:

| Prefix | Use When |
|---|---|
| `feat:` | New features or functionality |
| `fix:` | Bug fixes |
| `test:` | Adding or updating tests |
| `chore:` | Maintenance, dependencies, config |
| `docs:` | Documentation changes |
| `refactor:` | Code restructuring without behavior change |
| `perf:` | Performance improvements |

When using prefixes, still follow the imperative verb and 50-character rules for the rest of the subject line.

## Body Rules

### When to Include a Body

Include the body when:
- The change affects multiple files or areas
- The reasoning is not obvious from the diff
- Multiple steps or trade-offs were involved
- The change has side effects or implications

### Body Format

**Feature/Usecase metadata:** When the commit relates to a tracked feature, add `Feature:` and `Usecase:` lines before the summary. Derive the feature name and UC ID from the task brief, plan path, or `prd/specs/` folder name.

**Summary bullets:** Use hyphens to describe what changed and why.

```
Refactors authentication flow

Feature: Email authentication
Usecase: UC-0Fcy-001

Summary:
- Separates login and registration logic
- Makes code easier to test independently
- Removes duplicate token validation
- Prepares for OAuth integration
```

For chores or changes not tied to a feature, omit the metadata lines:

```
Updates dependencies to latest versions

Summary:
- Bumps React from 18.2 to 18.3
- Bumps TypeScript from 5.3 to 5.4
```

### When NOT to Include a Body

Simple, obvious changes need only the subject:

```
Fixes typo in README
```

## What NOT to Include

### Tool or AI Attribution

- Bad: "Generated with AI"
- Bad: "Created by Claude"
- Bad: "AI-assisted commit"
- Bad: Any co-author line mentioning AI tools

### Over-Explanation of Simple Changes

If the diff is clear, keep it short:
- Good: "Fixes typo in README"
- Bad: "Fixes typo in README (changed 'teh' to 'the' on line 42)"

### Paragraphs in the Body

Use bullets, not prose:

```
# Bad
Refactors authentication flow to separate login and registration logic,
making the code easier to test independently while also removing
duplicate token validation that was causing maintenance issues.

# Good
Refactors authentication flow

- Separates login and registration logic
- Makes code easier to test independently
- Removes duplicate token validation
```

## Issue References

Place issue references at the end of the subject line in parentheses:

```
Fixes payment processing error (#123)
```

Do not use issue tracker language as the subject:
- Bad: "Resolves #123"
- Good: "Fixes payment processing error (#123)"
