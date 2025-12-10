---
description: Initialize TypeScript project with strict type checking configuration
---

# Initialize TypeScript Project

Initialize a new TypeScript project with strict configuration and modern tooling.

Use the Task tool to launch the **developer** agent with instructions:

1. Ask user for project details using AskUserQuestion tool:
   - Project name
   - Project type (library, cli, service)
   - Linter choice (Biome or ESLint + Prettier)
   - Test framework (Vitest - default)
   - Package manager (npm, pnpm, yarn)

2. Create project structure:
   ```
   project/
   ├── src/
   │   ├── index.ts
   │   └── __tests__/
   │       └── index.test.ts
   ├── dist/              # Build output (gitignored)
   ├── tsconfig.json
   ├── package.json
   ├── .gitignore
   ├── .editorconfig
   └── README.md
   ```

3. Create `tsconfig.json` following **typescript-strict-config** skill:
   - All strict flags enabled
   - No implicit any
   - No unchecked indexed access
   - Target: ES2022, Module: ESNext

4. Create `package.json` with scripts:
   ```json
   {
     "type": "module",
     "scripts": {
       "dev": "tsx watch src/index.ts",
       "build": "tsup src/index.ts --format esm,cjs --dts",
       "type-check": "tsc --noEmit",
       "lint": "biome check .",
       "format": "biome format --write .",
       "test": "vitest run",
       "test:watch": "vitest",
       "test:coverage": "vitest run --coverage",
       "validate": "npm run type-check && npm run lint && npm test"
     }
   }
   ```

5. Create linter configuration:
   - If Biome: Create `biome.json` with strict rules
   - If ESLint: Create `eslint.config.ts` (flat config) + `.prettierrc`

6. Create `vitest.config.ts` following **vitest-configuration** skill

7. Create `.gitignore`:
   ```
   node_modules/
   dist/
   coverage/
   .env
   .env.local
   *.log
   .DS_Store
   ```

8. Create `.editorconfig`:
   ```ini
   root = true

   [*]
   charset = utf-8
   end_of_line = lf
   indent_style = space
   indent_size = 2
   insert_final_newline = true
   trim_trailing_whitespace = true
   ```

9. Create `README.md` with:
   - Project description
   - Installation instructions
   - Development commands
   - Testing instructions

10. Create starter `src/index.ts`:
    ```typescript
    export function greet(name: string): string {
      return `Hello, ${name}!`;
    }
    ```

11. Create starter `src/__tests__/index.test.ts`:
    ```typescript
    import { describe, it, expect } from 'vitest';
    import { greet } from '../index';

    describe('greet', () => {
      it('should greet by name', () => {
        expect(greet('World')).toBe('Hello, World!');
      });
    });
    ```

12. Initialize package manager:
    - Run `npm install` (or pnpm/yarn)
    - Install dependencies (TypeScript, Vitest, linter, etc.)

13. Initialize git repository:
    - Run `git init`
    - Create initial commit

14. Run validation:
    - `npm run type-check` - Must pass with zero errors
    - `npm run lint` - Must pass with zero warnings
    - `npm test` - Must pass all tests

15. Display next steps to user

**Quality Requirements:**
- All TypeScript strict flags enabled
- Zero TypeScript errors or warnings
- Zero linter warnings
- All tests passing
- NO `any` types allowed

Reference the **typescript-strict-config**, **eslint-flat-config**, **biome-setup**, and **vitest-configuration** skills.
