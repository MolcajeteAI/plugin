# Commit Message Format

## Structure

```
<Verb> <what changed>

- <why detail 1>
- <why detail 2>
- <why detail 3>
```

## First Line Rules

### Start with an Imperative Verb
Use present tense verbs that describe what the commit does (capitalize the first letter):
- **Adds** - New features, files, or functionality
- **Fixes** - Bug fixes or corrections
- **Updates** - Changes to existing features
- **Removes** - Deletion of features, files, or code
- **Refactors** - Code restructuring without changing behavior
- **Improves** - Performance or quality enhancements
- **Moves** - File or code relocation

### Keep It Short
- Maximum 50 characters for the first line
- If you need more, use the body (bullet points)

### Describe What Changed
Focus on the change itself, not the problem:
- ✅ "Fixes login redirect after authentication"
- ❌ "Fixes bug where users were stuck on login page"

### Use Simple Language
Aim for clarity, not sophistication:
- ✅ "Adds user search feature"
- ❌ "Implements comprehensive user discovery mechanism"

### No Conventional Commit Prefixes
Avoid prefixes like `feat:`, `fix:`, `test:`, etc. The verb already communicates this.

## Body (Optional)

Use bullet points to explain **why** when:
- The change affects multiple areas
- The reasoning isn't obvious
- Multiple steps were involved
- Trade-offs were made

```
Refactors authentication flow

- Separates login and registration logic
- Makes code easier to test independently
- Removes duplicate token validation
- Prepares for OAuth integration
```

## What NOT to Include

### Don't Mention Tools or AI
- ❌ "Generated with AI"
- ❌ "Created by Claude"
- ❌ "AI-assisted commit"

### Don't Over-explain Simple Changes
If the diff is clear, keep it short:
- ✅ "Fixes typo in README"
- ❌ "Fixes typo in README (changed 'teh' to 'the')"

### Don't Use Issue Tracker Language
Let the issue tracker reference speak for itself:
- ✅ "Fixes payment processing error (#123)"
- ❌ "Resolves #123 - Payment processing was broken due to..."

## Examples

### Good Examples

```
Adds dark mode toggle

- Saves preference to localStorage
- Applies theme on page load
- Updates CSS variables for colors
```

```
Fixes broken image uploads

- Validates file size before upload
- Handles network errors properly
- Shows error message to user
```

```
Updates API endpoint from v1 to v2

- Migrates to new response format
- Updates error handling
- Maintains backward compatibility
```

### Bad Examples

```
feat: add comprehensive user management system

Implemented a sophisticated and robust user management solution that handles authentication, authorization, and profile management with extensive error handling and validation mechanisms.
```
**Why bad:**
- Uses conventional commit prefix
- First line too long
- Uses fancy words ("comprehensive", "sophisticated", "robust")
- Body is a paragraph, not bullets
- Doesn't explain what specifically changed

```
Fixed stuff
```
**Why bad:**
- Too vague
- Doesn't describe what was fixed

```
Update
```
**Why bad:**
- No context about what was updated
