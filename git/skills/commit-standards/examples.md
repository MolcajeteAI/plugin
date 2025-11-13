# Commit Message Examples

## Single-line Commits

For simple, obvious changes, a single line is enough.

### Good Examples
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

## Multi-line Commits

For complex changes, add bullet points explaining why.

### Example 1: Feature Addition
```
Adds email verification for new users

- Sends verification link on registration
- Blocks login until email is verified
- Adds resend verification option
- Stores verification token in database
```

### Example 2: Bug Fix
```
Fixes race condition in payment processing

- Adds transaction locking
- Prevents duplicate charges
- Retries failed transactions once
- Logs all payment attempts for debugging
```

### Example 3: Refactoring
```
Refactors error handling across API

- Creates central error handler
- Standardizes error response format
- Removes duplicate error code
- Makes errors easier to debug
```

### Example 4: Performance Improvement
```
Improves database query performance

- Adds indexes on frequently queried columns
- Reduces N+1 queries with eager loading
- Caches user permissions
- Cuts average response time from 800ms to 200ms
```

### Example 5: Configuration Change
```
Updates CI pipeline for faster builds

- Parallelizes test execution
- Caches dependencies between runs
- Skips builds for documentation changes
- Reduces average build time from 15min to 6min
```

## Common Scenarios

### Adding Tests
```
Adds tests for authentication flow

- Covers login success and failure cases
- Tests token expiration
- Validates error messages
```

### Updating Documentation
```
Updates API documentation for v2 endpoints

- Documents new pagination format
- Adds examples for error responses
- Updates authentication section
```

### Dependency Updates
```
Updates React from v17 to v18

- Migrates to new root API
- Updates test setup
- Removes deprecated lifecycle methods
```

### Configuration Changes
```
Adds environment-specific config

- Separates dev, staging, and prod configs
- Moves secrets to environment variables
- Updates deployment scripts
```

### Breaking Changes
```
Removes legacy API endpoints

- Drops v1 endpoints (deprecated 6 months ago)
- Updates documentation
- Adds migration guide
```

## Anti-Patterns to Avoid

### Too Vague
```
❌ Updates code
❌ Fixes issues
❌ Changes things
❌ WIP
```

### Too Technical
```
❌ Refactors UserAuthenticationServiceFactoryBean implementation

Better: Simplifies user authentication setup
```

### Mentions Tools/AI
```
❌ Adds feature (generated with Claude)
❌ AI-assisted refactoring
❌ Claude suggested fixes
```

### Over-explains Simple Changes
```
❌ Fixes typo in README

Changed 'teh' to 'the' on line 42 because it was misspelled and causing confusion for readers who might think it's a technical term.

Better: Fixes typo in README
```

### Uses Issue Tracker Language
```
❌ Resolves #123

This commit addresses the bug reported in issue #123 where users were experiencing problems with the login flow.

Better: Fixes login redirect after authentication (#123)
```

### Conventional Commit Prefix
```
❌ feat: add user dashboard
❌ fix: resolve payment error
❌ chore: update dependencies

Better:
Adds user dashboard
Fixes payment processing error
Updates dependencies to latest versions
```
