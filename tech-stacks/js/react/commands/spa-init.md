---
description: Initialize Vite SPA project with React 19, TypeScript, and modern tooling
---

# Initialize Vite SPA Project

Initialize a new React SPA with Vite, TypeScript strict mode, and modern tooling.

Use the Task tool to launch the **component-builder** agent with instructions:

1. Ask user for project details using AskUserQuestion tool:
   - Project name
   - CSS solution (Tailwind CSS, CSS Modules, styled-components)
   - State management (Zustand, Jotai, none)
   - UI library (shadcn/ui, Radix UI, none)
   - Router (React Router, TanStack Router)
   - Package manager (npm, pnpm, yarn)

2. Create project using Vite:
   ```bash
   npm create vite@latest {project-name} -- --template react-ts
   cd {project-name}
   ```

3. Create project structure:
   ```
   project/
   ├── src/
   │   ├── components/
   │   │   └── Button/
   │   │       ├── Button.tsx
   │   │       ├── index.ts
   │   │       └── __tests__/
   │   │           └── Button.test.tsx
   │   ├── hooks/
   │   ├── stores/        # If state management selected
   │   ├── pages/
   │   │   └── Home.tsx
   │   ├── lib/
   │   │   └── utils.ts
   │   ├── App.tsx
   │   └── main.tsx
   ├── tests/
   │   └── e2e/
   ├── public/
   ├── index.html
   ├── vite.config.ts
   ├── tsconfig.json
   ├── biome.json
   └── package.json
   ```

4. Update `tsconfig.json` with strict configuration:
   ```json
   {
     "compilerOptions": {
       "target": "ES2022",
       "lib": ["ES2022", "DOM", "DOM.Iterable"],
       "module": "ESNext",
       "moduleResolution": "bundler",
       "strict": true,
       "noImplicitAny": true,
       "strictNullChecks": true,
       "noUncheckedIndexedAccess": true,
       "noUnusedLocals": true,
       "noUnusedParameters": true,
       "noImplicitReturns": true,
       "jsx": "react-jsx",
       "baseUrl": ".",
       "paths": {
         "@/*": ["./src/*"]
       }
     },
     "include": ["src"],
     "exclude": ["node_modules"]
   }
   ```

5. Create `vite.config.ts`:
   ```typescript
   import { defineConfig } from 'vite';
   import react from '@vitejs/plugin-react';
   import path from 'path';

   export default defineConfig({
     plugins: [react()],
     resolve: {
       alias: {
         '@': path.resolve(__dirname, './src'),
       },
     },
     build: {
       target: 'ES2022',
       sourcemap: true,
     },
   });
   ```

6. Create `biome.json` with strict rules (reference **biome-setup** skill)

7. Create `vitest.config.ts`:
   ```typescript
   import { defineConfig } from 'vitest/config';
   import react from '@vitejs/plugin-react';
   import path from 'path';

   export default defineConfig({
     plugins: [react()],
     test: {
       globals: true,
       environment: 'jsdom',
       setupFiles: ['./src/test/setup.ts'],
       include: ['src/**/__tests__/**/*.test.{ts,tsx}'],
       coverage: {
         provider: 'v8',
         thresholds: {
           lines: 80,
           functions: 80,
           branches: 80,
           statements: 80,
         },
       },
     },
     resolve: {
       alias: {
         '@': path.resolve(__dirname, './src'),
       },
     },
   });
   ```

8. Create `src/test/setup.ts`:
   ```typescript
   import '@testing-library/jest-dom/vitest';
   ```

9. Create `package.json` scripts:
   ```json
   {
     "scripts": {
       "dev": "vite",
       "build": "tsc && vite build",
       "preview": "vite preview",
       "type-check": "tsc --noEmit",
       "lint": "biome check .",
       "lint:fix": "biome check --write .",
       "format": "biome format --write .",
       "test": "vitest run",
       "test:watch": "vitest",
       "test:coverage": "vitest run --coverage",
       "test:ui": "vitest --ui",
       "validate": "npm run type-check && npm run lint && npm test"
     }
   }
   ```

10. Install dependencies based on selections:
    - React 19, TypeScript, Vite (core)
    - Vitest, @testing-library/react, @testing-library/jest-dom
    - Biome
    - Selected CSS solution
    - Selected state management
    - Selected UI library
    - Selected router

11. If Tailwind CSS selected:
    - Install tailwindcss, postcss, autoprefixer
    - Create tailwind.config.ts and postcss.config.js
    - Add Tailwind directives to CSS

12. If shadcn/ui selected:
    - Run `npx shadcn@latest init`
    - Configure components.json
    - Install initial components (Button, etc.)

13. Create starter components following patterns

14. Initialize git repository

15. Run validation:
    - `npm run type-check`
    - `npm run lint`
    - `npm test`

16. Display next steps to user

**Quality Requirements:**
- All TypeScript strict flags enabled
- Zero TypeScript errors or warnings
- Zero linter warnings
- NO `any` types allowed
- Tests pass with 80%+ coverage

Reference the **vite-configuration**, **react-19-patterns**, and **tailwind-setup** skills.
