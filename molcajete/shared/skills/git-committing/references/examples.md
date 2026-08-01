# Commit Message Examples

## Single-Line Commits

For simple, obvious changes, a single line is enough.

```
feat: Add user profile page
```

```
chore: Update dependencies to latest versions
```

```
refactor: Simplify database connection logic
```

## Multi-Line Commit (No PRD Context)

For changes without feature/UC/scenario context, add bullet points describing what was done and omit the refs block.

```
chore: Update React from v17 to v18

- Migrates to new root API
- Updates test setup
- Removes deprecated lifecycle methods
```

## Multi-Line Commits (With PRD Context)

When the commit is part of a task with feature/UC/scenario context, include the spec references block.

### Feature Addition

```
feat: Add email verification for new users

- Sends verification link on registration
- Blocks login until email is verified
- Adds resend verification option
- Stores verification token in database

FEAT-0R7a
- UC-0R8a: Verify email address
  - SC-0R9a: Verification link sent on registration
  - SC-0R9b: Login blocked until verified
  - SC-0R9c: Resend verification link
```

### Multiple Use Cases in One Commit

```
feat: Add user registration endpoint

- Creates registration handler with validation
- Adds bcrypt password hashing
- Sends welcome email on success

FEAT-0R7c
- UC-0R8f: Register new user
  - SC-0R9k: Valid registration with all fields
  - SC-0R9l: Duplicate email rejected
- UC-0R8g: Send welcome email
  - SC-0R9m: Welcome email sent after registration
```
