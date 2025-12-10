---
description: Initialize Next.js 15 project with App Router, TypeScript, and modern tooling
---

# Initialize Next.js Project

Initialize a new Next.js 15 project with App Router, TypeScript strict mode, and modern tooling.

Use the Task tool to launch the **component-builder** agent with instructions:

1. Ask user for project details using AskUserQuestion tool:
   - Project name
   - CSS solution (Tailwind CSS, CSS Modules, styled-components)
   - State management (Zustand, Jotai, none)
   - UI library (shadcn/ui, Radix UI, none)
   - Data fetching (TanStack Query, tRPC, native)
   - Database (Prisma, Drizzle, none)
   - Authentication (NextAuth.js, Clerk, none)
   - Package manager (npm, pnpm, yarn)

2. Create project using create-next-app:
   ```bash
   npx create-next-app@latest {project-name} --typescript --tailwind --eslint --app --src-dir --import-alias "@/*"
   cd {project-name}
   ```

3. Create project structure:
   ```
   project/
   ├── src/
   │   ├── app/
   │   │   ├── layout.tsx
   │   │   ├── page.tsx
   │   │   ├── globals.css
   │   │   └── api/
   │   │       └── health/
   │   │           └── route.ts
   │   ├── components/
   │   │   └── Button/
   │   │       ├── Button.tsx
   │   │       ├── index.ts
   │   │       └── __tests__/
   │   │           └── Button.test.tsx
   │   ├── hooks/
   │   ├── stores/
   │   ├── lib/
   │   │   ├── utils.ts
   │   │   └── db.ts     # If database selected
   │   └── types/
   ├── tests/
   │   └── e2e/
   ├── public/
   ├── prisma/            # If Prisma selected
   │   └── schema.prisma
   ├── next.config.ts
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
       "jsx": "preserve",
       "incremental": true,
       "plugins": [{ "name": "next" }],
       "baseUrl": ".",
       "paths": {
         "@/*": ["./src/*"]
       }
     },
     "include": ["next-env.d.ts", "**/*.ts", "**/*.tsx", ".next/types/**/*.ts"],
     "exclude": ["node_modules"]
   }
   ```

5. Create `next.config.ts`:
   ```typescript
   import type { NextConfig } from 'next';

   const config: NextConfig = {
     reactStrictMode: true,
     typescript: {
       ignoreBuildErrors: false, // NEVER ignore TS errors
     },
     eslint: {
       ignoreDuringBuilds: false, // NEVER ignore lint errors
     },
     experimental: {
       typedRoutes: true,
     },
   };

   export default config;
   ```

6. Replace ESLint with Biome:
   - Remove eslint config
   - Create `biome.json` with strict rules (reference **biome-setup** skill)

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
       exclude: ['node_modules', '.next'],
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

8. Create `package.json` scripts:
   ```json
   {
     "scripts": {
       "dev": "next dev",
       "build": "next build",
       "start": "next start",
       "type-check": "tsc --noEmit",
       "lint": "biome check .",
       "lint:fix": "biome check --write .",
       "format": "biome format --write .",
       "test": "vitest run",
       "test:watch": "vitest",
       "test:coverage": "vitest run --coverage",
       "test:e2e": "playwright test",
       "validate": "npm run type-check && npm run lint && npm test"
     }
   }
   ```

9. Install additional dependencies:
   - Vitest, @testing-library/react, @testing-library/jest-dom
   - Biome
   - Selected state management
   - Selected UI library
   - Selected data fetching library
   - Selected database ORM
   - Selected auth solution

10. If shadcn/ui selected:
    - Run `npx shadcn@latest init`
    - Configure components.json
    - Install initial components

11. If Prisma selected:
    - Initialize Prisma: `npx prisma init`
    - Create basic schema
    - Generate client

12. If NextAuth.js selected:
    - Install and configure auth
    - Create auth API routes

13. Create Server Component example:
    ```typescript
    // src/app/page.tsx
    export default async function HomePage(): Promise<React.ReactElement> {
      return (
        <main className="container mx-auto p-4">
          <h1 className="text-4xl font-bold">Welcome</h1>
        </main>
      );
    }
    ```

14. Create Client Component example:
    ```typescript
    'use client';
    // src/components/Counter/Counter.tsx
    ```

15. Initialize git repository

16. Run validation:
    - `npm run type-check`
    - `npm run lint`
    - `npm test`

17. Display next steps to user

**Quality Requirements:**
- All TypeScript strict flags enabled
- Zero TypeScript errors or warnings
- Zero linter warnings
- NO `any` types allowed
- Server Components by default

Reference the **nextjs-configuration**, **react-19-patterns**, and **tailwind-setup** skills.
