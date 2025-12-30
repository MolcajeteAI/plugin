---
description: Initialize Next.js 15 project with App Router, TypeScript, Atomic Design, and Storybook
---

# Initialize Next.js Project

Initialize a new Next.js 15 project with App Router, TypeScript strict mode, Atomic Design component structure, and Storybook.

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

1.5. Check PRD configuration for component organization preference:

   Look for `componentOrganization` setting in:
   - `.molcajete/prd/tech-stack.md` (YAML frontmatter)
   - `.molcajete/prd/tech-stack.yaml`

   **Valid values:**
   - `atomic` (default) - Atomic Design pattern with atoms/, molecules/, organisms/, templates/
   - `flat` - Simple flat components/ directory
   - `feature-based` - Feature modules with shared components

   ```yaml
   # Example .molcajete/prd/tech-stack.yaml
   techStack:
     framework: react-nextjs
     componentOrganization: atomic  # or 'flat' or 'feature-based'
   ```

   If no config found or value is `atomic`, proceed with Atomic Design (Step 3).
   If `flat`, use flat structure (Step 3a).
   If `feature-based`, use feature-based structure (Step 3b).

2. Create project using create-next-app:
   ```bash
   npx create-next-app@latest {project-name} --typescript --tailwind --eslint --app --src-dir --import-alias "@/*"
   cd {project-name}
   ```

3. Create project structure with Atomic Design pattern:
   ```
   project/
   ├── src/
   │   ├── app/
   │   │   ├── layout.tsx            # Root layout - uses templates
   │   │   ├── page.tsx              # Home page
   │   │   ├── globals.css
   │   │   └── api/
   │   │       └── health/
   │   │           └── route.ts
   │   ├── components/
   │   │   ├── atoms/
   │   │   │   ├── Button/
   │   │   │   │   ├── Button.tsx
   │   │   │   │   ├── Button.stories.tsx
   │   │   │   │   ├── index.ts
   │   │   │   │   └── __tests__/
   │   │   │   │       └── Button.test.tsx
   │   │   │   ├── Input/
   │   │   │   ├── Label/
   │   │   │   └── index.ts          # Barrel export for atoms
   │   │   ├── molecules/
   │   │   │   ├── FormField/
   │   │   │   ├── SearchForm/
   │   │   │   └── index.ts          # Barrel export for molecules
   │   │   ├── organisms/
   │   │   │   ├── Header/
   │   │   │   ├── LoginForm/
   │   │   │   └── index.ts          # Barrel export for organisms
   │   │   ├── templates/
   │   │   │   ├── MainLayout/
   │   │   │   │   ├── MainLayout.tsx
   │   │   │   │   └── index.ts
   │   │   │   ├── DashboardLayout/
   │   │   │   ├── AuthLayout/
   │   │   │   └── index.ts          # Barrel export for templates
   │   │   └── index.ts              # Main barrel export
   │   ├── hooks/
   │   │   └── useAuth.ts
   │   ├── stores/
   │   │   └── userStore.ts
   │   ├── lib/
   │   │   ├── utils.ts
   │   │   └── db.ts                 # If database selected
   │   └── types/
   ├── .storybook/
   │   ├── main.ts
   │   └── preview.ts
   ├── tests/
   │   └── e2e/
   ├── public/
   ├── prisma/                       # If Prisma selected
   │   └── schema.prisma
   ├── next.config.ts
   ├── tsconfig.json
   ├── biome.json
   └── package.json
   ```

   **Note:** Next.js uses `src/app/` for pages via file-based routing. Templates in `src/components/templates/` are reusable layout patterns that Next.js layouts import and use.

4. Create barrel exports for each atomic level:

   **src/components/atoms/index.ts:**
   ```typescript
   export { Button } from './Button';
   export type { ButtonProps } from './Button/Button';
   ```

   **src/components/molecules/index.ts:**
   ```typescript
   // Export molecules as they are created
   ```

   **src/components/organisms/index.ts:**
   ```typescript
   // Export organisms as they are created
   ```

   **src/components/templates/index.ts:**
   ```typescript
   export { MainLayout } from './MainLayout';
   ```

   **src/components/index.ts:**
   ```typescript
   export * from './atoms';
   export * from './molecules';
   export * from './organisms';
   export * from './templates';
   ```

3a. **ALTERNATIVE: Flat Structure** (if `componentOrganization: flat`):
   ```
   project/
   ├── src/
   │   ├── app/
   │   │   ├── layout.tsx
   │   │   ├── page.tsx
   │   │   ├── globals.css
   │   │   └── api/
   │   ├── components/
   │   │   ├── Button/
   │   │   │   ├── Button.tsx
   │   │   │   ├── index.ts
   │   │   │   └── __tests__/
   │   │   │       └── Button.test.tsx
   │   │   ├── Input/
   │   │   ├── Header/
   │   │   ├── LoginForm/
   │   │   └── index.ts              # Barrel export
   │   ├── hooks/
   │   ├── stores/
   │   ├── lib/
   │   └── types/
   ├── tests/
   ├── public/
   ├── next.config.ts
   ├── tsconfig.json
   ├── biome.json
   └── package.json
   ```

   **Note:** Flat structure does not include Storybook setup by default. Skip Step 10 (Storybook).

3b. **ALTERNATIVE: Feature-Based Structure** (if `componentOrganization: feature-based`):
   ```
   project/
   ├── src/
   │   ├── app/
   │   │   ├── layout.tsx
   │   │   ├── page.tsx
   │   │   ├── globals.css
   │   │   ├── dashboard/
   │   │   │   └── page.tsx
   │   │   └── api/
   │   ├── features/
   │   │   ├── auth/
   │   │   │   ├── components/
   │   │   │   │   ├── LoginForm/
   │   │   │   │   └── index.ts
   │   │   │   ├── hooks/
   │   │   │   └── index.ts
   │   │   ├── dashboard/
   │   │   │   ├── components/
   │   │   │   ├── hooks/
   │   │   │   └── index.ts
   │   │   └── index.ts
   │   ├── shared/
   │   │   └── components/
   │   │       ├── Button/
   │   │       ├── Input/
   │   │       └── index.ts
   │   ├── lib/
   │   └── types/
   ├── tests/
   ├── public/
   ├── next.config.ts
   ├── tsconfig.json
   ├── biome.json
   └── package.json
   ```

   **Note:** Feature-based structure does not include Storybook setup by default. Skip Step 10 (Storybook).

5. Update `tsconfig.json` with strict configuration:
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

6. Create `next.config.ts`:
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

7. Replace ESLint with Biome:
   - Remove eslint config
   - Create `biome.json` with strict rules (reference **biome-setup** skill)

8. Create `vitest.config.ts`:
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

9. Create `src/test/setup.ts`:
   ```typescript
   import '@testing-library/jest-dom/vitest';
   ```

10. Set up Storybook with Next.js (Atomic Design only - skip for flat/feature-based):

    Install Storybook:
    ```bash
    npx storybook@latest init --type nextjs --no-dev
    ```

    Install additional addons:
    ```bash
    npm install -D @storybook/addon-a11y @storybook/addon-viewport
    ```

    Create `.storybook/main.ts`:
    ```typescript
    import type { StorybookConfig } from '@storybook/nextjs';

    const config: StorybookConfig = {
      stories: [
        '../src/components/atoms/**/*.stories.@(ts|tsx)',
        '../src/components/molecules/**/*.stories.@(ts|tsx)',
        '../src/components/organisms/**/*.stories.@(ts|tsx)',
      ],
      addons: [
        '@storybook/addon-links',
        '@storybook/addon-essentials',
        '@storybook/addon-interactions',
        '@storybook/addon-a11y',
        '@storybook/addon-viewport',
      ],
      framework: {
        name: '@storybook/nextjs',
        options: {},
      },
      docs: {
        autodocs: 'tag',
      },
    };

    export default config;
    ```

    Create `.storybook/preview.ts`:
    ```typescript
    import type { Preview } from '@storybook/react';

    const preview: Preview = {
      parameters: {
        actions: { argTypesRegex: '^on[A-Z].*' },
        controls: {
          matchers: {
            color: /(background|color)$/i,
            date: /Date$/i,
          },
        },
      },
    };

    export default preview;
    ```

11. Create `package.json` scripts:
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
        "storybook": "storybook dev -p 6006",
        "build-storybook": "storybook build",
        "validate": "npm run type-check && npm run lint && npm test"
      }
    }
    ```

12. Install additional dependencies:
    - Vitest, @testing-library/react, @testing-library/jest-dom
    - Biome
    - Storybook with addons
    - Selected state management
    - Selected UI library
    - Selected data fetching library
    - Selected database ORM
    - Selected auth solution

13. If shadcn/ui selected:
    - Run `npx shadcn@latest init`
    - Configure components.json
    - Install initial components

14. If Prisma selected:
    - Initialize Prisma: `npx prisma init`
    - Create basic schema
    - Generate client

15. Create MainLayout template:

    **src/components/templates/MainLayout/MainLayout.tsx:**
    ```typescript
    import { Header } from '@/components/organisms';

    interface MainLayoutProps {
      children: React.ReactNode;
    }

    export function MainLayout({ children }: MainLayoutProps): React.ReactElement {
      return (
        <div className="min-h-screen flex flex-col">
          <Header />
          <main className="flex-1 container mx-auto px-4 py-8">
            {children}
          </main>
          <footer className="border-t py-4">
            <div className="container mx-auto px-4 text-center text-sm text-gray-500">
              Built with Next.js and Atomic Design
            </div>
          </footer>
        </div>
      );
    }
    ```

    **src/components/templates/MainLayout/index.ts:**
    ```typescript
    export { MainLayout } from './MainLayout';
    ```

    **Note on Templates vs Next.js Layouts:**
    - **Templates** (`src/components/templates/`) are reusable component patterns that define visual structure
    - **Next.js Layouts** (`src/app/layout.tsx`, `src/app/dashboard/layout.tsx`) are route-specific wrappers that can import and use templates
    - Templates are portable and can be used across multiple layouts or even different projects
    - Next.js layouts handle route-specific concerns like metadata, loading states, and error boundaries

16. Update `src/app/layout.tsx` to use template:
    ```typescript
    import type { Metadata } from 'next';
    import { MainLayout } from '@/components/templates';
    import './globals.css';

    export const metadata: Metadata = {
      title: 'My App',
      description: 'Built with Next.js and Atomic Design',
    };

    export default function RootLayout({
      children,
    }: {
      children: React.ReactNode;
    }): React.ReactElement {
      return (
        <html lang="en">
          <body>
            <MainLayout>{children}</MainLayout>
          </body>
        </html>
      );
    }
    ```

17. Create example Button atom component:

    **src/components/atoms/Button/Button.tsx:**
    ```typescript
    import { forwardRef } from 'react';
    import { cn } from '@/lib/utils';

    export interface ButtonProps extends React.ButtonHTMLAttributes<HTMLButtonElement> {
      variant: 'primary' | 'secondary' | 'danger' | 'ghost';
      size?: 'sm' | 'md' | 'lg';
      loading?: boolean;
    }

    export const Button = forwardRef<HTMLButtonElement, ButtonProps>(
      ({ variant, size = 'md', loading, className, children, disabled, ...props }, ref) => {
        return (
          <button
            ref={ref}
            type="button"
            className={cn(
              'inline-flex items-center justify-center rounded-md font-medium transition-colors',
              'focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-offset-2',
              {
                'bg-blue-600 text-white hover:bg-blue-700 focus-visible:ring-blue-500': variant === 'primary',
                'bg-gray-200 text-gray-900 hover:bg-gray-300 focus-visible:ring-gray-500': variant === 'secondary',
                'bg-red-600 text-white hover:bg-red-700 focus-visible:ring-red-500': variant === 'danger',
                'bg-transparent hover:bg-gray-100 focus-visible:ring-gray-500': variant === 'ghost',
                'px-3 py-1.5 text-sm': size === 'sm',
                'px-4 py-2 text-base': size === 'md',
                'px-6 py-3 text-lg': size === 'lg',
                'opacity-50 cursor-not-allowed': disabled || loading,
              },
              className
            )}
            disabled={disabled || loading}
            {...props}
          >
            {loading && (
              <svg
                className="mr-2 h-4 w-4 animate-spin"
                xmlns="http://www.w3.org/2000/svg"
                fill="none"
                viewBox="0 0 24 24"
              >
                <circle
                  className="opacity-25"
                  cx="12"
                  cy="12"
                  r="10"
                  stroke="currentColor"
                  strokeWidth="4"
                />
                <path
                  className="opacity-75"
                  fill="currentColor"
                  d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z"
                />
              </svg>
            )}
            {children}
          </button>
        );
      }
    );
    Button.displayName = 'Button';
    ```

    **src/components/atoms/Button/Button.stories.tsx:**
    ```typescript
    import type { Meta, StoryObj } from '@storybook/react';
    import { Button } from './Button';

    const meta: Meta<typeof Button> = {
      title: 'Atoms/Button',
      component: Button,
      tags: ['autodocs'],
      parameters: {
        layout: 'centered',
      },
      argTypes: {
        variant: {
          control: 'select',
          options: ['primary', 'secondary', 'danger', 'ghost'],
          description: 'The visual style of the button',
        },
        size: {
          control: 'select',
          options: ['sm', 'md', 'lg'],
          description: 'The size of the button',
        },
        loading: {
          control: 'boolean',
          description: 'Shows a loading spinner',
        },
        disabled: {
          control: 'boolean',
          description: 'Disables the button',
        },
      },
    };

    export default meta;
    type Story = StoryObj<typeof Button>;

    export const Primary: Story = {
      args: {
        variant: 'primary',
        children: 'Primary Button',
      },
    };

    export const Secondary: Story = {
      args: {
        variant: 'secondary',
        children: 'Secondary Button',
      },
    };

    export const Danger: Story = {
      args: {
        variant: 'danger',
        children: 'Delete',
      },
    };

    export const Ghost: Story = {
      args: {
        variant: 'ghost',
        children: 'Ghost Button',
      },
    };

    export const Loading: Story = {
      args: {
        variant: 'primary',
        children: 'Saving...',
        loading: true,
      },
    };

    export const Disabled: Story = {
      args: {
        variant: 'primary',
        children: 'Disabled Button',
        disabled: true,
      },
    };

    export const AllSizes: Story = {
      render: () => (
        <div className="flex items-center gap-4">
          <Button variant="primary" size="sm">Small</Button>
          <Button variant="primary" size="md">Medium</Button>
          <Button variant="primary" size="lg">Large</Button>
        </div>
      ),
    };

    export const AllVariants: Story = {
      render: () => (
        <div className="flex items-center gap-4">
          <Button variant="primary">Primary</Button>
          <Button variant="secondary">Secondary</Button>
          <Button variant="danger">Danger</Button>
          <Button variant="ghost">Ghost</Button>
        </div>
      ),
    };
    ```

    **src/components/atoms/Button/index.ts:**
    ```typescript
    export { Button } from './Button';
    export type { ButtonProps } from './Button';
    ```

    **src/components/atoms/Button/__tests__/Button.test.tsx:**
    ```typescript
    import { describe, it, expect, vi } from 'vitest';
    import { render, screen, fireEvent } from '@testing-library/react';
    import { Button } from '../Button';

    describe('Button', () => {
      it('renders children correctly', () => {
        render(<Button variant="primary">Click me</Button>);
        expect(screen.getByRole('button')).toHaveTextContent('Click me');
      });

      it('applies variant styles', () => {
        const { rerender } = render(<Button variant="primary">Button</Button>);
        expect(screen.getByRole('button')).toHaveClass('bg-blue-600');

        rerender(<Button variant="secondary">Button</Button>);
        expect(screen.getByRole('button')).toHaveClass('bg-gray-200');

        rerender(<Button variant="danger">Button</Button>);
        expect(screen.getByRole('button')).toHaveClass('bg-red-600');
      });

      it('applies size styles', () => {
        const { rerender } = render(<Button variant="primary" size="sm">Button</Button>);
        expect(screen.getByRole('button')).toHaveClass('px-3', 'py-1.5', 'text-sm');

        rerender(<Button variant="primary" size="md">Button</Button>);
        expect(screen.getByRole('button')).toHaveClass('px-4', 'py-2', 'text-base');

        rerender(<Button variant="primary" size="lg">Button</Button>);
        expect(screen.getByRole('button')).toHaveClass('px-6', 'py-3', 'text-lg');
      });

      it('calls onClick when clicked', () => {
        const handleClick = vi.fn();
        render(<Button variant="primary" onClick={handleClick}>Click</Button>);

        fireEvent.click(screen.getByRole('button'));

        expect(handleClick).toHaveBeenCalledTimes(1);
      });

      it('disables button when disabled prop is true', () => {
        render(<Button variant="primary" disabled>Disabled</Button>);
        expect(screen.getByRole('button')).toBeDisabled();
      });

      it('disables button when loading prop is true', () => {
        render(<Button variant="primary" loading>Loading</Button>);
        expect(screen.getByRole('button')).toBeDisabled();
      });

      it('shows loading spinner when loading', () => {
        render(<Button variant="primary" loading>Loading</Button>);
        expect(screen.getByRole('button').querySelector('svg')).toBeInTheDocument();
      });

      it('does not call onClick when disabled', () => {
        const handleClick = vi.fn();
        render(<Button variant="primary" onClick={handleClick} disabled>Click</Button>);

        fireEvent.click(screen.getByRole('button'));

        expect(handleClick).not.toHaveBeenCalled();
      });

      it('forwards ref to button element', () => {
        const ref = vi.fn();
        render(<Button variant="primary" ref={ref}>Button</Button>);
        expect(ref).toHaveBeenCalled();
      });

      it('has type="button" by default', () => {
        render(<Button variant="primary">Button</Button>);
        expect(screen.getByRole('button')).toHaveAttribute('type', 'button');
      });
    });
    ```

18. Create Server Component example:
    ```typescript
    // src/app/page.tsx
    export default async function HomePage(): Promise<React.ReactElement> {
      return (
        <div>
          <h1 className="text-4xl font-bold">Welcome</h1>
          <p className="mt-4 text-gray-600">
            Your Next.js app with Atomic Design is ready.
          </p>
        </div>
      );
    }
    ```

19. If NextAuth.js selected:
    - Install and configure auth
    - Create auth API routes

20. Initialize git repository

21. Run validation:
    - `npm run type-check`
    - `npm run lint`
    - `npm test`
    - `npm run storybook` (verify Storybook runs)

22. Display next steps to user

**Quality Requirements:**
- All TypeScript strict flags enabled
- Zero TypeScript errors or warnings
- Zero linter warnings
- NO `any` types allowed
- Server Components by default
- Tests pass with 80%+ coverage
- Storybook builds without errors

Reference the **nextjs-configuration**, **react-19-patterns**, **tailwind-setup**, and **atomic-design** skills.
