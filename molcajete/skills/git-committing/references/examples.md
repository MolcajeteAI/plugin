# Commit Message Examples

## Single-Line Commits

For simple, obvious changes, a single line is enough.

```
Adds user profile page
```

```
Fixes navigation menu on mobile
```

```
Updates dependencies to latest versions
```

```
Removes deprecated API endpoints
```

```
Refactors database connection logic
```

## Multi-Line Commits (Feature-Linked)

When commits relate to a tracked feature, include `Feature:` and `Usecase:` metadata before the summary.

### Feature Addition

```
Adds email verification for new users

Feature: User onboarding
Usecase: UC-0Fy0-001

Summary:
- Sends verification link on registration
- Blocks login until email is verified
- Adds resend verification option
- Stores verification token in database
```

### Bug Fix

```
Fixes race condition in payment processing

Feature: Payment gateway
Usecase: UC-0Kp2-003

Summary:
- Adds transaction locking
- Prevents duplicate charges
- Retries failed transactions once
- Logs all payment attempts for debugging
```

### Refactoring

```
Refactors error handling across API

Feature: Console authentication
Usecase: UC-0Fcy-001

Summary:
- Creates central error handler
- Standardizes error response format
- Removes duplicate error code
- Makes errors easier to debug
```

### Adding Tests

```
Adds tests for authentication flow

Feature: Email authentication
Usecase: UC-0Fcy-002

Summary:
- Covers login success and failure cases
- Tests token expiration
- Validates error messages
```

## Multi-Line Commits (No Feature)

When commits are chores or not tied to a specific feature, omit the metadata lines.

### Performance Improvement

```
Improves database query performance

Summary:
- Adds indexes on frequently queried columns
- Reduces N+1 queries with eager loading
- Caches user permissions
- Cuts average response time from 800ms to 200ms
```

### Configuration Change

```
Updates CI pipeline for faster builds

Summary:
- Parallelizes test execution
- Caches dependencies between runs
- Skips builds for documentation changes
- Reduces average build time from 15min to 6min
```

### Dependency Updates

```
Updates React from v17 to v18

Summary:
- Migrates to new root API
- Updates test setup
- Removes deprecated lifecycle methods
```

### Breaking Changes

```
Removes legacy API endpoints

Summary:
- Drops v1 endpoints (deprecated 6 months ago)
- Updates documentation
- Adds migration guide
```

## Anti-Patterns

### Too Vague

```
# BAD — no information about what changed
Updates code
Fixes issues
Changes things
WIP
```

### Too Technical for Subject Line

```
# BAD — move details to body
Refactors UserAuthenticationServiceFactoryBean implementation

# GOOD
Simplifies user authentication setup
```

### Mentions AI or Tools

```
# BAD — never attribute to AI
Adds feature (generated with Claude)
AI-assisted refactoring
Claude suggested fixes

# GOOD — just describe the change
Adds user dashboard
Refactors authentication logic
Fixes login redirect
```

### Over-Explains Simple Changes

```
# BAD
Fixes typo in README

Changed 'teh' to 'the' on line 42 because it was misspelled.

# GOOD
Fixes typo in README
```

### Introduces Prefixes When the Project Does Not Use Them

```
# BAD — project history has no prefixes, do not introduce them
feat: add user dashboard
fix: resolve payment error
chore: update dependencies

# GOOD — match the project's existing style
Adds user dashboard
Fixes payment processing error
Updates dependencies to latest versions
```

### Drops Prefixes When the Project Uses Them

```
# BAD — project history uses prefixes, do not drop them
Adds user dashboard
Fixes payment error

# GOOD — match the project's existing style
feat: Add user dashboard
fix: Fix payment error
```

### Uses Co-Author Attribution for AI

```
# BAD — never do this
Adds user authentication

Co-Authored-By: Claude <noreply@anthropic.com>

# GOOD — no attribution
Adds user authentication

Summary:
- Creates login and registration pages
- Adds JWT token handling
- Stores user session in localStorage
```
