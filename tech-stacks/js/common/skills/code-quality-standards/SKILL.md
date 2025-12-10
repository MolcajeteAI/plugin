---
name: code-quality-standards
description: Quality gates and enforcement. Use when defining and enforcing code quality standards.
---

# Code Quality Standards Skill

This skill covers quality gates and enforcement for TypeScript projects.

## When to Use

Use this skill when:
- Defining quality standards
- Setting up quality gates
- Reviewing code quality
- Configuring CI/CD quality checks

## Core Principle

**ZERO WARNINGS POLICY** - All warnings are treated as errors. No exceptions without documented justification.

## Quality Gates

### Required Checks (Must Pass)

| Check | Command | Requirement |
|-------|---------|-------------|
| Type Check | `npm run type-check` | Zero errors |
| Linting | `npm run lint` | Zero errors, zero warnings |
| Formatting | `npm run format:check` | All files formatted |
| Tests | `npm test` | All tests pass |

### Recommended Checks

| Check | Command | Requirement |
|-------|---------|-------------|
| Coverage | `npm run test:coverage` | 80% minimum |
| Security | `npm audit` | No high/critical |
| Licenses | License check | Approved licenses only |

## Package.json Scripts

```json
{
  "scripts": {
    "type-check": "tsc --noEmit",
    "lint": "biome check .",
    "lint:fix": "biome check --write .",
    "format": "biome format --write .",
    "format:check": "biome format .",
    "test": "vitest run",
    "test:coverage": "vitest run --coverage",
    "validate": "npm run type-check && npm run lint && npm run format:check && npm test",
    "pre-commit": "lint-staged && npm run type-check"
  }
}
```

## Type Safety Standards

### Required TypeScript Configuration

```json
{
  "compilerOptions": {
    "strict": true,
    "noImplicitAny": true,
    "noUncheckedIndexedAccess": true
  }
}
```

### Forbidden Patterns

```typescript
// ❌ Never use any
function bad(data: any) { }
const x: any = value;

// ❌ No implicit any
function bad(data) { }  // Error: implicit any

// ❌ No @ts-ignore without justification
// @ts-ignore
riskyCode();

// ✅ Acceptable with justification
// @ts-expect-error - External library has incorrect types (issue #123)
externalLib.brokenMethod();
```

## Linting Standards

### Biome Configuration

```json
{
  "linter": {
    "rules": {
      "recommended": true,
      "suspicious": {
        "noExplicitAny": "error"
      },
      "correctness": {
        "noUnusedVariables": "error"
      }
    }
  }
}
```

### ESLint Configuration

```typescript
{
  rules: {
    '@typescript-eslint/no-explicit-any': 'error',
    '@typescript-eslint/no-unused-vars': 'error',
    '@typescript-eslint/explicit-function-return-type': 'error',
  }
}
```

## Code Style Standards

### Naming Conventions

```typescript
// Variables: camelCase
const userName = 'Alice';
const isActive = true;

// Constants: UPPER_SNAKE_CASE
const MAX_RETRIES = 3;
const API_BASE_URL = 'https://api.example.com';

// Functions: camelCase
function calculateTotal() { }
const processData = () => { };

// Classes: PascalCase
class UserService { }
class ApiClient { }

// Interfaces/Types: PascalCase
interface UserData { }
type ApiResponse<T> = { };

// Enums: PascalCase with PascalCase values
enum Status {
  Active = 'ACTIVE',
  Inactive = 'INACTIVE',
}
```

### File Naming

```
src/
├── components/
│   ├── Button.tsx           # PascalCase for components
│   └── user-profile.tsx     # kebab-case acceptable
├── utils/
│   └── format-date.ts       # kebab-case for utilities
├── services/
│   └── api-client.ts        # kebab-case for services
└── types/
    └── user.ts              # lowercase for type files
```

## Test Standards

### Test File Location

```
src/
├── utils/
│   ├── format.ts
│   └── __tests__/
│       └── format.test.ts
```

### Test Structure

```typescript
describe('FunctionName', () => {
  describe('when condition', () => {
    it('should do expected behavior', () => {
      // Arrange
      // Act
      // Assert
    });
  });
});
```

### Coverage Requirements

- Lines: 80% minimum
- Functions: 80% minimum
- Branches: 80% minimum
- Statements: 80% minimum

## Documentation Standards

### Required Documentation

```typescript
/**
 * Brief description of the function.
 *
 * @param input - Description of input parameter
 * @returns Description of return value
 * @throws {ErrorType} Description of when thrown
 *
 * @example
 * ```typescript
 * const result = functionName('input');
 * ```
 */
export function functionName(input: string): Result {
  // implementation
}
```

### When Documentation Required

- All exported functions
- All exported classes
- All exported interfaces
- Complex internal logic

## CI/CD Quality Pipeline

```yaml
name: Quality Checks

on: [push, pull_request]

jobs:
  quality:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - uses: actions/setup-node@v4
        with:
          node-version: '22'
          cache: 'npm'

      - run: npm ci

      - name: Type Check
        run: npm run type-check

      - name: Lint
        run: npm run lint

      - name: Format Check
        run: npm run format:check

      - name: Test
        run: npm run test:coverage

      - name: Security Audit
        run: npm audit --audit-level=high
```

## Quality Metrics

### Code Health Indicators

| Metric | Good | Warning | Critical |
|--------|------|---------|----------|
| Type Errors | 0 | >0 | >0 |
| Lint Warnings | 0 | 1-5 | >5 |
| Test Coverage | >80% | 60-80% | <60% |
| Vulnerabilities | 0 high | 0 critical | Any critical |

### Monitoring Quality

```bash
# Generate quality report
npm run validate

# Check specific metrics
npm run type-check  # Type errors
npm run lint        # Lint issues
npm run test:coverage  # Coverage percentage
npm audit           # Vulnerabilities
```

## Exceptions Process

### When Exceptions Allowed

1. External library type issues
2. Generated code
3. Legacy code (with migration plan)
4. Platform-specific code

### Exception Documentation

```typescript
// File: src/legacy/old-module.ts
// QUALITY EXCEPTION: Legacy code pending migration
// Issue: #456
// Owner: @developer
// Review Date: 2024-06-01

/* eslint-disable @typescript-eslint/no-explicit-any */
// Legacy code here
/* eslint-enable @typescript-eslint/no-explicit-any */
```

## Best Practices Summary

1. **Zero warnings** - All warnings are errors
2. **Type everything** - No implicit or explicit any
3. **Test everything** - 80% coverage minimum
4. **Document exports** - Public API documented
5. **Automate checks** - CI/CD enforces standards
6. **Review exceptions** - Track and expire
7. **Consistent style** - Automated formatting

## Code Review Checklist

- [ ] Type check passes with zero errors
- [ ] Lint passes with zero warnings
- [ ] Code is properly formatted
- [ ] Tests pass with 80%+ coverage
- [ ] No new security vulnerabilities
- [ ] Public API documented
- [ ] Exceptions documented with issues
