# JavaScript/TypeScript Common Foundation Plugin

Shared foundation providing TypeScript development infrastructure, testing, linting, and quality gates. This is an **internal plugin** not directly exposed to users - it is inherited by `node` and `react` stacks.

## Plugin ID

`common` (internal - not user-visible)

## Description

The js/common plugin provides the foundational TypeScript development tooling shared across all JavaScript/TypeScript tech-stacks. It enforces strict type safety, modern ESM patterns, and zero-tolerance quality gates.

## Core Development Philosophy

### 1. Type Safety First
- **ZERO TOLERANCE for `any` types** - implicit or explicit
- Use `unknown` with type guards for truly unknown values
- Every value must have an explicit, meaningful type
- All TypeScript strict flags enabled

### 2. Zero Warnings Policy
- All warnings are treated as errors
- Linter warnings must be fixed, not suppressed
- Type-checker warnings must be resolved
- No `// @ts-ignore` or `// eslint-disable` without justification

### 3. Modern ESM
- ES Modules only (`import`/`export`)
- No CommonJS (`require`/`module.exports`)
- Package.json `"type": "module"`
- Explicit file extensions in imports

### 4. Well-Known Libraries
- Prefer established, community-supported solutions
- Avoid custom implementations of solved problems
- Use tools with strong TypeScript support

### 5. Quality Gates
- Type-check, lint, format, and test before builds
- Pre-commit hooks enforce standards
- CI/CD validates all quality checks

---

## Specialized Agents

### 1. developer

**Use PROACTIVELY** to implement TypeScript code with strict type safety.

**Capabilities:**
- typescript-development
- type-safe-coding
- esm-module-design
- error-handling

**Tools:** AskUserQuestion, Read, Write, Edit, Bash, Grep, Glob

---

### 2. tester

**Use PROACTIVELY** to write tests with Vitest.

**Capabilities:**
- unit-testing
- integration-testing
- test-coverage-analysis
- mocking-strategies

**Tools:** Read, Write, Edit, Bash, Grep, Glob

---

### 3. security

Performs security audits using npm audit, Snyk, and manual code review (READ-ONLY).

**Capabilities:**
- dependency-scanning
- vulnerability-detection
- license-compliance
- security-code-review

**Tools:** Read, Bash, Grep, Glob

---

### 4. quality-guardian

Enforces code quality standards (type-checking, linting, formatting).

**Capabilities:**
- type-checking
- lint-enforcement
- format-validation
- pre-commit-hooks

**Tools:** Read, Bash, Grep, Glob

---

### 5. documenter

Generates and maintains TypeScript documentation.

**Capabilities:**
- tsdoc-generation
- readme-creation
- api-documentation
- changelog-maintenance

**Tools:** Read, Write, Edit, Bash, Grep, Glob

---

## Skills

### Core Development
1. **typescript-strict-config** - Strict TypeScript configuration with all safety flags
2. **esm-module-patterns** - Modern ESM import/export patterns
3. **type-safety-patterns** - Generic types, type guards, branded types
4. **error-handling-patterns** - Type-safe error handling with discriminated unions

### Tooling
5. **eslint-flat-config** - ESLint 9.x flat configuration patterns
6. **biome-setup** - Biome linter/formatter setup
7. **vitest-configuration** - Vitest setup and best practices
8. **build-tools** - tsup, tsx, and bundler configuration

### Testing
9. **testing-patterns** - Unit testing with Vitest
10. **mocking-strategies** - Vi mocks, test doubles, fixtures
11. **coverage-standards** - Coverage thresholds and reporting

### Security
12. **dependency-security** - npm audit, Snyk, Socket usage
13. **license-compliance** - License checking and compatibility

### Quality
14. **code-quality-standards** - Quality gates and enforcement
15. **pre-commit-hooks** - Husky, lint-staged setup

---

## Commands

### Project Management
- `init` - Initialize TypeScript project with strict config
- `install` - Install and audit dependencies

### Development
- `dev` - Run development environment
- `build` - Build project (TSC or bundler)
- `type-check` - Run TypeScript compiler checks
- `lint` - Run linter (ESLint or Biome)
- `format` - Format code (Prettier or Biome)
- `format-check` - Check formatting without changes

### Testing
- `test` - Run test suite (Vitest)
- `test-watch` - Run tests in watch mode
- `test-coverage` - Generate coverage report
- `test-ui` - Open Vitest UI

### Security
- `audit` - Security audit (npm audit + Snyk)
- `audit-fix` - Auto-fix vulnerabilities
- `license-check` - Check dependency licenses

### Quality
- `validate` - Run all checks (type-check, lint, format-check, test)
- `pre-commit` - Pre-commit quality gate

---

## Tech Stack Keywords

- typescript
- javascript
- esm
- vitest
- eslint
- biome
- nodejs

---

## Agent Chaining Examples

### Standard Development Workflow
```
developer → tester → quality-guardian → security
```
1. **developer** implements feature with strict typing
2. **tester** writes tests for new functionality
3. **quality-guardian** verifies all quality checks pass
4. **security** scans for vulnerabilities

### Documentation Workflow
```
developer → documenter → quality-guardian
```
1. **developer** implements feature
2. **documenter** generates/updates documentation
3. **quality-guardian** validates documentation standards

### Pre-Release Workflow
```
quality-guardian → security → tester
```
1. **quality-guardian** runs full validation
2. **security** performs security audit
3. **tester** runs full test suite with coverage

---

## TypeScript Configuration Standards

### Required tsconfig.json Flags

```json
{
  "compilerOptions": {
    "strict": true,
    "noImplicitAny": true,
    "strictNullChecks": true,
    "strictFunctionTypes": true,
    "strictBindCallApply": true,
    "strictPropertyInitialization": true,
    "noImplicitThis": true,
    "noImplicitReturns": true,
    "noFallthroughCasesInSwitch": true,
    "noUncheckedIndexedAccess": true,
    "noUnusedLocals": true,
    "noUnusedParameters": true,
    "exactOptionalPropertyTypes": true,
    "noPropertyAccessFromIndexSignature": true,
    "useUnknownInCatchVariables": true,
    "allowUnusedLabels": false,
    "allowUnreachableCode": false
  }
}
```

### Forbidden Patterns

```typescript
// NEVER use any
function bad(data: any) { }           // ❌
function bad(data) { }                // ❌ implicit any
const x: any = value;                 // ❌

// Use unknown + type guards instead
function good(data: unknown) {        // ✅
  if (isValidData(data)) {
    // data is now typed
  }
}
```

---

## Test File Organization

Tests are placed in `__tests__/` subdirectories relative to the file being tested:

```
src/
├── components/
│   ├── Button.tsx
│   └── __tests__/
│       └── Button.test.tsx
├── utils/
│   ├── format.ts
│   └── __tests__/
│       └── format.test.ts
```

---

## Linter Choice

Users choose during project initialization:

### Option A: Biome (Default - Recommended)
- Single tool for linting and formatting
- 10-100x faster than ESLint + Prettier
- TypeScript-first design
- Zero dependencies

### Option B: ESLint 9.x + Prettier
- Full ESLint plugin ecosystem
- Flat config (`eslint.config.ts`)
- Use when specific ESLint plugins required

---

## Requirements

### Core
- Node.js >= 22 LTS
- npm >= 10 or pnpm >= 9

### Recommended
- TypeScript >= 5.7
- Vitest >= 2.0
- Biome >= 1.9 OR (ESLint >= 9.0 + Prettier >= 3.0)

### Optional
- Snyk - Vulnerability scanning
- Husky - Git hooks
- lint-staged - Pre-commit linting

---

## Version

1.0.0
