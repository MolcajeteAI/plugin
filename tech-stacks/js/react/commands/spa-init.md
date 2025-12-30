---
description: Initialize Vite SPA project with React 19, TypeScript, Atomic Design, and Storybook
---

# Initialize Vite SPA Project

Initialize a new React SPA with Vite, TypeScript strict mode, Atomic Design component structure, and Storybook.

Use the Task tool to launch the **component-builder** agent with instructions:

1. Ask user for project details using AskUserQuestion tool:
   - Project name
   - CSS solution (Tailwind CSS, CSS Modules, styled-components)
   - State management (Zustand, Jotai, none)
   - UI library (shadcn/ui, Radix UI, none)
   - Router (React Router, TanStack Router)
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
     framework: react
     componentOrganization: atomic  # or 'flat' or 'feature-based'
   ```

   If no config found or value is `atomic`, proceed with Atomic Design (Step 3).
   If `flat`, use flat structure (Step 3a).
   If `feature-based`, use feature-based structure (Step 3b).

2. Create project using Vite:
   ```bash
   npm create vite@latest {project-name} -- --template react-ts
   cd {project-name}
   ```

3. Create project structure with Atomic Design pattern:
   ```
   project/
   ├── src/
   │   ├── components/
   │   │   ├── atoms/
   │   │   │   ├── Button/
   │   │   │   │   ├── Button.tsx
   │   │   │   │   ├── Button.stories.tsx
   │   │   │   │   ├── index.ts
   │   │   │   │   └── __tests__/
   │   │   │   │       └── Button.test.tsx
   │   │   │   └── index.ts          # Barrel export
   │   │   ├── molecules/
   │   │   │   └── index.ts          # Barrel export
   │   │   ├── organisms/
   │   │   │   └── index.ts          # Barrel export
   │   │   ├── templates/
   │   │   │   └── index.ts          # Barrel export
   │   │   └── index.ts              # Main barrel export
   │   ├── hooks/
   │   ├── stores/        # If state management selected
   │   ├── pages/
   │   │   └── Home/
   │   │       └── HomePage.tsx
   │   ├── lib/
   │   │   └── utils.ts
   │   ├── types/
   │   ├── App.tsx
   │   └── main.tsx
   ├── .storybook/
   │   ├── main.ts
   │   └── preview.ts
   ├── tests/
   │   └── e2e/
   ├── public/
   ├── index.html
   ├── vite.config.ts
   ├── tsconfig.json
   ├── biome.json
   └── package.json
   ```

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
   // Export templates as they are created
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
   │   ├── pages/
   │   ├── lib/
   │   ├── types/
   │   ├── App.tsx
   │   └── main.tsx
   ├── tests/
   ├── public/
   ├── vite.config.ts
   ├── tsconfig.json
   ├── biome.json
   └── package.json
   ```

   **Note:** Flat structure does not include Storybook setup by default. Skip Step 10 (Storybook).

3b. **ALTERNATIVE: Feature-Based Structure** (if `componentOrganization: feature-based`):
   ```
   project/
   ├── src/
   │   ├── features/
   │   │   ├── auth/
   │   │   │   ├── components/
   │   │   │   │   ├── LoginForm/
   │   │   │   │   │   ├── LoginForm.tsx
   │   │   │   │   │   └── index.ts
   │   │   │   │   └── index.ts
   │   │   │   ├── hooks/
   │   │   │   │   └── useAuth.ts
   │   │   │   └── index.ts
   │   │   ├── dashboard/
   │   │   │   ├── components/
   │   │   │   ├── hooks/
   │   │   │   └── index.ts
   │   │   └── index.ts
   │   ├── shared/
   │   │   └── components/
   │   │       ├── Button/
   │   │       │   ├── Button.tsx
   │   │       │   └── index.ts
   │   │       ├── Input/
   │   │       └── index.ts
   │   ├── pages/
   │   ├── lib/
   │   ├── types/
   │   ├── App.tsx
   │   └── main.tsx
   ├── tests/
   ├── public/
   ├── vite.config.ts
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

6. Create `vite.config.ts`:
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

7. Create `biome.json` with strict rules (reference **biome-setup** skill)

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

10. Set up Storybook with Vite (Atomic Design only - skip for flat/feature-based):

    Install Storybook:
    ```bash
    npx storybook@latest init --type react_vite --no-dev
    ```

    Install additional addons:
    ```bash
    npm install -D @storybook/addon-a11y @storybook/addon-viewport
    ```

    Create `.storybook/main.ts`:
    ```typescript
    import type { StorybookConfig } from '@storybook/react-vite';

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
        name: '@storybook/react-vite',
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
        "storybook": "storybook dev -p 6006",
        "build-storybook": "storybook build",
        "validate": "npm run type-check && npm run lint && npm test"
      }
    }
    ```

12. Install dependencies based on selections:
    - React 19, TypeScript, Vite (core)
    - Vitest, @testing-library/react, @testing-library/jest-dom
    - Biome
    - Storybook with addons
    - Selected CSS solution
    - Selected state management
    - Selected UI library
    - Selected router

13. If Tailwind CSS selected:
    - Install tailwindcss, postcss, autoprefixer
    - Create tailwind.config.ts and postcss.config.js
    - Add Tailwind directives to CSS

14. If shadcn/ui selected:
    - Run `npx shadcn@latest init`
    - Configure components.json
    - Install initial components (Button, etc.)

15. Create example Button atom component:

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

16. Initialize git repository

17. Run validation:
    - `npm run type-check`
    - `npm run lint`
    - `npm test`
    - `npm run storybook` (verify Storybook runs)

18. Display next steps to user

**Quality Requirements:**
- All TypeScript strict flags enabled
- Zero TypeScript errors or warnings
- Zero linter warnings
- NO `any` types allowed
- Tests pass with 80%+ coverage
- Storybook builds without errors

Reference the **vite-configuration**, **react-19-patterns**, **tailwind-setup**, and **atomic-design** skills.
