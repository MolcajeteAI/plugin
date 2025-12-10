---
name: vitest-configuration
description: Vitest setup and best practices. Use when configuring Vitest for TypeScript projects.
---

# Vitest Configuration Skill

This skill covers Vitest configuration for TypeScript projects.

## When to Use

Use this skill when:
- Setting up testing infrastructure
- Configuring coverage thresholds
- Setting up test environments
- Migrating from Jest to Vitest

## Core Principle

**FAST, NATIVE ESM TESTING** - Vitest provides Jest-compatible API with native ESM support and Vite-powered performance.

## Installation

```bash
npm install -D vitest @vitest/coverage-v8
```

## Basic Configuration

### vitest.config.ts

```typescript
import { defineConfig } from 'vitest/config';

export default defineConfig({
  test: {
    globals: true,
    environment: 'node',
    include: ['src/**/__tests__/**/*.test.{ts,tsx}'],
    exclude: ['node_modules', 'dist'],
    coverage: {
      provider: 'v8',
      reporter: ['text', 'json', 'html'],
      exclude: [
        'node_modules/',
        'dist/',
        '**/*.test.ts',
        '**/__tests__/**',
        '**/*.d.ts',
      ],
      thresholds: {
        lines: 80,
        functions: 80,
        branches: 80,
        statements: 80,
      },
    },
    typecheck: {
      enabled: true,
      tsconfig: './tsconfig.json',
    },
  },
});
```

## Package.json Scripts

```json
{
  "scripts": {
    "test": "vitest run",
    "test:watch": "vitest",
    "test:coverage": "vitest run --coverage",
    "test:ui": "vitest --ui"
  }
}
```

## Test Environments

### Node Environment (Default)

```typescript
export default defineConfig({
  test: {
    environment: 'node',
  },
});
```

### JSDOM Environment (For DOM Testing)

```bash
npm install -D jsdom
```

```typescript
export default defineConfig({
  test: {
    environment: 'jsdom',
  },
});
```

### Happy-DOM Environment (Faster Alternative)

```bash
npm install -D happy-dom
```

```typescript
export default defineConfig({
  test: {
    environment: 'happy-dom',
  },
});
```

### Per-File Environment

```typescript
// In test file header
// @vitest-environment jsdom

import { describe, it, expect } from 'vitest';
```

## Global Setup and Teardown

### Setup Files

```typescript
// vitest.config.ts
export default defineConfig({
  test: {
    setupFiles: ['./src/test/setup.ts'],
    globalSetup: ['./src/test/global-setup.ts'],
  },
});
```

```typescript
// src/test/setup.ts
import { beforeAll, afterAll, afterEach } from 'vitest';

beforeAll(() => {
  // Runs once before all tests
});

afterEach(() => {
  // Runs after each test
});

afterAll(() => {
  // Runs once after all tests
});
```

```typescript
// src/test/global-setup.ts
export default async function setup() {
  // Global setup (runs before all test files)
  console.log('Starting test suite');
}

export async function teardown() {
  // Global teardown (runs after all test files)
  console.log('Test suite complete');
}
```

## Coverage Configuration

### Comprehensive Coverage Setup

```typescript
export default defineConfig({
  test: {
    coverage: {
      provider: 'v8',
      reporter: ['text', 'json', 'html', 'lcov'],
      reportsDirectory: './coverage',
      exclude: [
        'node_modules/',
        'dist/',
        '**/*.test.ts',
        '**/*.test.tsx',
        '**/__tests__/**',
        '**/__mocks__/**',
        '**/*.d.ts',
        '**/types/**',
        '**/index.ts', // Re-export files
      ],
      thresholds: {
        lines: 80,
        functions: 80,
        branches: 80,
        statements: 80,
      },
      // Fail if coverage drops
      thresholds: {
        '100': true, // Enforce 100% on new code
      },
    },
  },
});
```

## TypeScript Integration

### Type Checking in Tests

```typescript
export default defineConfig({
  test: {
    typecheck: {
      enabled: true,
      tsconfig: './tsconfig.json',
      include: ['**/*.test.ts', '**/*.test.tsx'],
    },
  },
});
```

### tsconfig.json for Tests

```json
{
  "compilerOptions": {
    "types": ["vitest/globals"]
  },
  "include": ["src/**/*", "src/**/__tests__/**/*"]
}
```

## Path Aliases

```typescript
import { defineConfig } from 'vitest/config';
import path from 'node:path';

export default defineConfig({
  test: {
    alias: {
      '@': path.resolve(__dirname, './src'),
      '@test': path.resolve(__dirname, './src/test'),
    },
  },
});
```

## Parallel Execution

```typescript
export default defineConfig({
  test: {
    // Run tests in parallel (default)
    pool: 'threads',
    poolOptions: {
      threads: {
        singleThread: false,
        maxThreads: 4,
        minThreads: 1,
      },
    },
    // Or run tests sequentially
    // sequence: {
    //   concurrent: false,
    // },
  },
});
```

## Test Filtering

### By Pattern

```bash
# Run tests matching pattern
vitest run --grep="user"

# Run specific file
vitest run src/utils/__tests__/format.test.ts
```

### By Annotation

```typescript
import { describe, it, expect } from 'vitest';

describe('feature', () => {
  it.skip('skipped test', () => {
    // This test is skipped
  });

  it.only('only this test runs', () => {
    // Only this test runs when using .only
  });

  it.todo('not yet implemented');
});
```

## Snapshot Testing

```typescript
import { describe, it, expect } from 'vitest';

describe('snapshots', () => {
  it('should match snapshot', () => {
    const result = { id: 1, name: 'test' };
    expect(result).toMatchSnapshot();
  });

  it('should match inline snapshot', () => {
    const result = { id: 1, name: 'test' };
    expect(result).toMatchInlineSnapshot(`
      {
        "id": 1,
        "name": "test",
      }
    `);
  });
});
```

### Snapshot Configuration

```typescript
export default defineConfig({
  test: {
    snapshotFormat: {
      printBasicPrototype: false,
    },
  },
});
```

## Mocking Configuration

### Auto-Mocking

```typescript
export default defineConfig({
  test: {
    mockReset: true, // Reset mocks before each test
    clearMocks: true, // Clear mock calls before each test
    restoreMocks: true, // Restore original implementations
  },
});
```

### Module Mocking Directory

```typescript
export default defineConfig({
  test: {
    deps: {
      interopDefault: true,
    },
  },
});
```

## Reporter Configuration

```typescript
export default defineConfig({
  test: {
    reporters: ['default', 'json', 'html'],
    outputFile: {
      json: './test-results/results.json',
      html: './test-results/results.html',
    },
  },
});
```

## Watch Mode Configuration

```typescript
export default defineConfig({
  test: {
    watch: true,
    watchExclude: ['**/node_modules/**', '**/dist/**'],
    forceRerunTriggers: ['**/vitest.config.ts', '**/vite.config.ts'],
  },
});
```

## CI Configuration

```typescript
export default defineConfig({
  test: {
    // CI-specific settings
    ...(process.env.CI
      ? {
          minWorkers: 1,
          maxWorkers: 2,
          coverage: {
            reporter: ['text', 'json', 'lcov'],
          },
        }
      : {}),
  },
});
```

## Vitest UI

```bash
npm install -D @vitest/ui
```

```bash
vitest --ui
```

Opens interactive UI at `http://localhost:51204/__vitest__/`

## Migration from Jest

### Configuration Mapping

| Jest | Vitest |
|------|--------|
| `testEnvironment` | `environment` |
| `setupFilesAfterEnv` | `setupFiles` |
| `testMatch` | `include` |
| `testPathIgnorePatterns` | `exclude` |
| `moduleNameMapper` | `alias` |
| `collectCoverageFrom` | `coverage.include` |

### Import Changes

```typescript
// Jest
import { jest } from '@jest/globals';

// Vitest
import { vi } from 'vitest';

// Jest mock
jest.fn();
jest.mock('./module');

// Vitest mock
vi.fn();
vi.mock('./module');
```

## Best Practices Summary

1. **Use TypeScript for configuration**
2. **Set coverage thresholds to 80%+**
3. **Enable type checking in tests**
4. **Use appropriate test environment**
5. **Configure parallel execution**
6. **Use setup files for common setup**
7. **Configure reporters for CI**

## Code Review Checklist

- [ ] vitest.config.ts uses TypeScript
- [ ] Coverage thresholds set (80%+)
- [ ] Type checking enabled
- [ ] Correct environment selected
- [ ] Setup files configured if needed
- [ ] Snapshot format configured
- [ ] CI-specific settings applied
