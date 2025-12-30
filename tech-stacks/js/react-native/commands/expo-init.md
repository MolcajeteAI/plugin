---
description: Initialize Expo project with React Native, TypeScript, Atomic Design, and modern tooling
---

# Initialize Expo Project

Initialize a new React Native app with Expo, TypeScript strict mode, NativeWind, Atomic Design component structure, and modern tooling.

Use the Task tool to launch the **component-builder** agent with instructions:

1. Ask user for project details using AskUserQuestion tool:
   - Project name
   - Include Gluestack-ui? (yes/no)
   - State management (Zustand, Jotai, none)
   - Package manager (npm, pnpm, yarn)
   - Initialize EAS? (yes/no)

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
     framework: react-native-expo
     componentOrganization: atomic  # or 'flat' or 'feature-based'
   ```

   If no config found or value is `atomic`, proceed with Atomic Design (Step 3).
   If `flat`, use flat structure (Step 3a).
   If `feature-based`, use feature-based structure (Step 3b).

2. Create project using Expo:
   ```bash
   npx create-expo-app@latest {project-name}
   cd {project-name}
   ```

3. Create project structure with Atomic Design pattern:
   ```
   project/
   ├── app/
   │   ├── (auth)/
   │   │   ├── login.tsx
   │   │   └── _layout.tsx
   │   ├── (tabs)/
   │   │   ├── _layout.tsx
   │   │   ├── index.tsx
   │   │   └── profile.tsx
   │   ├── _layout.tsx
   │   └── +not-found.tsx
   ├── components/
   │   ├── atoms/
   │   │   ├── Button/
   │   │   │   ├── Button.tsx
   │   │   │   ├── Button.stories.tsx
   │   │   │   ├── index.ts
   │   │   │   └── __tests__/
   │   │   │       └── Button.test.tsx
   │   │   └── index.ts          # Barrel export
   │   ├── molecules/
   │   │   └── index.ts          # Barrel export
   │   ├── organisms/
   │   │   └── index.ts          # Barrel export
   │   ├── templates/
   │   │   ├── ScreenLayout/
   │   │   │   ├── ScreenLayout.tsx
   │   │   │   └── index.ts
   │   │   └── index.ts          # Barrel export
   │   └── index.ts              # Main barrel export
   ├── hooks/
   │   └── useAuth.ts
   ├── store/           # If state management selected
   │   └── authStore.ts
   ├── lib/
   │   ├── api.ts
   │   └── utils.ts
   ├── constants/
   │   ├── Colors.ts
   │   └── Sizes.ts
   ├── assets/
   │   ├── images/
   │   └── fonts/
   ├── .storybook/
   │   ├── main.ts
   │   └── preview.ts
   ├── __tests__/
   │   ├── components/
   │   └── e2e/
   ├── app.json
   ├── tsconfig.json
   ├── biome.json
   ├── tailwind.config.js
   └── package.json
   ```

4. Create barrel exports for each atomic level:

   **components/atoms/index.ts:**
   ```typescript
   export { Button } from './Button';
   export type { ButtonProps } from './Button/Button';
   ```

   **components/molecules/index.ts:**
   ```typescript
   // Export molecules as they are created
   ```

   **components/organisms/index.ts:**
   ```typescript
   // Export organisms as they are created
   ```

   **components/templates/index.ts:**
   ```typescript
   export { ScreenLayout } from './ScreenLayout';
   ```

   **components/index.ts:**
   ```typescript
   export * from './atoms';
   export * from './molecules';
   export * from './organisms';
   export * from './templates';
   ```

3a. **ALTERNATIVE: Flat Structure** (if `componentOrganization: flat`):
   ```
   project/
   ├── app/
   │   ├── (auth)/
   │   │   ├── login.tsx
   │   │   └── _layout.tsx
   │   ├── (tabs)/
   │   │   ├── _layout.tsx
   │   │   ├── index.tsx
   │   │   └── profile.tsx
   │   ├── _layout.tsx
   │   └── +not-found.tsx
   ├── components/
   │   ├── Button/
   │   │   ├── Button.tsx
   │   │   ├── index.ts
   │   │   └── __tests__/
   │   │       └── Button.test.tsx
   │   ├── Input/
   │   ├── Header/
   │   ├── LoginForm/
   │   └── index.ts              # Barrel export
   ├── hooks/
   ├── store/
   ├── lib/
   ├── constants/
   ├── assets/
   ├── app.json
   ├── tsconfig.json
   ├── biome.json
   ├── tailwind.config.js
   └── package.json
   ```

   **Note:** Flat structure does not include Storybook setup by default. Skip Step 13 (Storybook).

3b. **ALTERNATIVE: Feature-Based Structure** (if `componentOrganization: feature-based`):
   ```
   project/
   ├── app/
   │   ├── (auth)/
   │   │   ├── login.tsx
   │   │   └── _layout.tsx
   │   ├── (tabs)/
   │   │   ├── _layout.tsx
   │   │   ├── index.tsx
   │   │   └── profile.tsx
   │   ├── _layout.tsx
   │   └── +not-found.tsx
   ├── features/
   │   ├── auth/
   │   │   ├── components/
   │   │   │   ├── LoginForm/
   │   │   │   └── index.ts
   │   │   ├── hooks/
   │   │   └── index.ts
   │   ├── profile/
   │   │   ├── components/
   │   │   ├── hooks/
   │   │   └── index.ts
   │   └── index.ts
   ├── shared/
   │   └── components/
   │       ├── Button/
   │       ├── Input/
   │       └── index.ts
   ├── hooks/
   ├── lib/
   ├── constants/
   ├── assets/
   ├── app.json
   ├── tsconfig.json
   ├── biome.json
   ├── tailwind.config.js
   └── package.json
   ```

   **Note:** Feature-based structure does not include Storybook setup by default. Skip Step 13 (Storybook).

5. Update `tsconfig.json` with strict configuration:
   ```json
   {
     "extends": "expo/tsconfig.base",
     "compilerOptions": {
       "strict": true,
       "noImplicitAny": true,
       "strictNullChecks": true,
       "noUncheckedIndexedAccess": true,
       "noUnusedLocals": true,
       "noUnusedParameters": true,
       "noImplicitReturns": true,
       "baseUrl": ".",
       "paths": {
         "@/*": ["./*"]
       }
     }
   }
   ```

6. Install NativeWind:
   ```bash
   npx expo install nativewind
   npm install --dev tailwindcss
   npx tailwindcss init
   ```

7. Create `tailwind.config.js`:
   ```javascript
   /** @type {import('tailwindcss').Config} */
   module.exports = {
     content: [
       "./app/**/*.{js,jsx,ts,tsx}",
       "./components/**/*.{js,jsx,ts,tsx}"
     ],
     presets: [require("nativewind/preset")],
     theme: {
       extend: {},
     },
     plugins: [],
   }
   ```

8. Update `babel.config.js`:
   ```javascript
   module.exports = function(api) {
     api.cache(true);
     return {
       presets: ['babel-preset-expo'],
       plugins: ["nativewind/babel"],
     };
   };
   ```

9. Create `biome.json` with strict rules (reference **biome-setup** skill from js/common)

10. Create `jest.config.js`:
   ```javascript
   module.exports = {
     preset: 'jest-expo',
     transformIgnorePatterns: [
       'node_modules/(?!((jest-)?react-native|@react-native(-community)?)|expo(nent)?|@expo(nent)?/.*|@expo-google-fonts/.*|react-navigation|@react-navigation/.*|@unimodules/.*|unimodules|sentry-expo|native-base|react-native-svg)'
     ],
     collectCoverageFrom: [
       '**/*.{ts,tsx}',
       '!**/coverage/**',
       '!**/node_modules/**',
       '!**/babel.config.js',
       '!**/jest.setup.js'
     ],
     coverageThreshold: {
       global: {
         lines: 80,
         functions: 80,
         branches: 80,
         statements: 80,
       },
     },
   };
   ```

11. Update `package.json` scripts:
    ```json
    {
      "scripts": {
        "start": "expo start",
        "android": "expo start --android",
        "ios": "expo start --ios",
        "web": "expo start --web",
        "type-check": "tsc --noEmit",
        "lint": "biome check .",
        "lint:fix": "biome check --write .",
        "format": "biome format --write .",
        "test": "jest",
        "test:watch": "jest --watch",
        "test:coverage": "jest --coverage",
        "validate": "npm run type-check && npm run lint && npm test",
        "storybook": "expo start --dev-client",
        "storybook:ios": "expo start --dev-client --ios",
        "storybook:android": "expo start --dev-client --android"
      }
    }
    ```

12. Install dependencies:
    - Core: expo, react-native, typescript
    - Testing: jest-expo, @testing-library/react-native
    - Biome
    - Selected state management
    - TanStack Query, React Hook Form, Zod

13. Set up Storybook React Native (Atomic Design only - skip for flat/feature-based):

    Install Storybook:
    ```bash
    npx -p @storybook/cli sb init --type react_native
    npm install -D @storybook/addon-ondevice-controls @storybook/addon-ondevice-actions
    ```

    Create `.storybook/main.ts`:
    ```typescript
    import type { StorybookConfig } from '@storybook/react-native';

    const config: StorybookConfig = {
      stories: [
        '../components/atoms/**/*.stories.@(ts|tsx)',
        '../components/molecules/**/*.stories.@(ts|tsx)',
        '../components/organisms/**/*.stories.@(ts|tsx)',
      ],
      addons: [
        '@storybook/addon-ondevice-controls',
        '@storybook/addon-ondevice-actions',
      ],
    };

    export default config;
    ```

    Create `.storybook/preview.ts`:
    ```typescript
    import type { Preview } from '@storybook/react-native';

    const preview: Preview = {
      parameters: {
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

    **Note:** React Native Storybook runs on-device rather than in a web browser. Use the on-device addons for controls and actions.

14. If Gluestack-ui selected:
    ```bash
    npx gluestack-ui init
    ```

15. If EAS selected:
    ```bash
    npm install -g eas-cli
    eas login
    eas build:configure
    ```

16. Create example Button atom component with accessibility:

    **components/atoms/Button/Button.tsx:**
    ```typescript
    import { Pressable, Text, ActivityIndicator, StyleSheet } from 'react-native';

    export interface ButtonProps {
      variant: 'primary' | 'secondary' | 'danger';
      size?: 'sm' | 'md' | 'lg';
      loading?: boolean;
      disabled?: boolean;
      onPress?: () => void;
      children: string;
      accessibilityLabel?: string;
    }

    export function Button({
      variant,
      size = 'md',
      loading,
      disabled,
      onPress,
      children,
      accessibilityLabel,
    }: ButtonProps): React.ReactElement {
      const isDisabled = disabled || loading;

      return (
        <Pressable
          style={({ pressed }) => [
            styles.base,
            styles[variant],
            styles[size],
            isDisabled && styles.disabled,
            pressed && !isDisabled && styles.pressed,
          ]}
          onPress={onPress}
          disabled={isDisabled}
          accessibilityLabel={accessibilityLabel || children}
          accessibilityRole="button"
          accessibilityState={{ disabled: isDisabled }}
        >
          {loading && (
            <ActivityIndicator
              color={variant === 'secondary' ? '#374151' : '#ffffff'}
              style={styles.spinner}
            />
          )}
          <Text style={[styles.text, styles[`${variant}Text`]]}>
            {children}
          </Text>
        </Pressable>
      );
    }

    const styles = StyleSheet.create({
      base: {
        flexDirection: 'row',
        alignItems: 'center',
        justifyContent: 'center',
        borderRadius: 8,
        minHeight: 44, // Minimum touch target (Apple HIG)
        minWidth: 44,
      },
      primary: {
        backgroundColor: '#2563eb',
      },
      secondary: {
        backgroundColor: '#e5e7eb',
      },
      danger: {
        backgroundColor: '#dc2626',
      },
      sm: {
        paddingHorizontal: 12,
        paddingVertical: 6,
      },
      md: {
        paddingHorizontal: 16,
        paddingVertical: 10,
      },
      lg: {
        paddingHorizontal: 24,
        paddingVertical: 14,
      },
      disabled: {
        opacity: 0.5,
      },
      pressed: {
        opacity: 0.8,
      },
      spinner: {
        marginRight: 8,
      },
      text: {
        fontWeight: '600',
        textAlign: 'center',
      },
      primaryText: {
        color: '#ffffff',
      },
      secondaryText: {
        color: '#1f2937',
      },
      dangerText: {
        color: '#ffffff',
      },
    });
    ```

    **components/atoms/Button/Button.stories.tsx:**
    ```typescript
    import type { Meta, StoryObj } from '@storybook/react-native';
    import { Button } from './Button';

    const meta: Meta<typeof Button> = {
      title: 'Atoms/Button',
      component: Button,
      argTypes: {
        variant: {
          control: 'select',
          options: ['primary', 'secondary', 'danger'],
        },
        size: {
          control: 'select',
          options: ['sm', 'md', 'lg'],
        },
        loading: { control: 'boolean' },
        disabled: { control: 'boolean' },
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
    ```

    **components/atoms/Button/index.ts:**
    ```typescript
    export { Button } from './Button';
    export type { ButtonProps } from './Button';
    ```

    **components/atoms/Button/__tests__/Button.test.tsx:**
    ```typescript
    import { render, screen, fireEvent } from '@testing-library/react-native';
    import { Button } from '../Button';

    describe('Button', () => {
      it('renders children correctly', () => {
        render(<Button variant="primary" onPress={jest.fn()}>Click me</Button>);
        expect(screen.getByText('Click me')).toBeTruthy();
      });

      it('calls onPress when pressed', () => {
        const handlePress = jest.fn();
        render(<Button variant="primary" onPress={handlePress}>Click</Button>);

        fireEvent.press(screen.getByRole('button'));

        expect(handlePress).toHaveBeenCalledTimes(1);
      });

      it('does not call onPress when disabled', () => {
        const handlePress = jest.fn();
        render(<Button variant="primary" onPress={handlePress} disabled>Click</Button>);

        fireEvent.press(screen.getByRole('button'));

        expect(handlePress).not.toHaveBeenCalled();
      });

      it('shows loading indicator when loading', () => {
        render(<Button variant="primary" loading>Loading</Button>);
        expect(screen.getByRole('button')).toHaveAccessibilityState({ disabled: true });
      });

      it('has correct accessibility properties', () => {
        render(
          <Button variant="primary" accessibilityLabel="Submit form">Submit</Button>
        );
        expect(screen.getByLabelText('Submit form')).toBeTruthy();
      });

      it('has minimum touch target size', () => {
        // Button should have minHeight and minWidth of 44 for accessibility
        const { getByRole } = render(<Button variant="primary">A</Button>);
        const button = getByRole('button');
        // Style assertions would be checked visually or with snapshot testing
        expect(button).toBeTruthy();
      });
    });
    ```

    **Mobile-Specific Requirements (documented):**
    - Minimum 44x44pt touch targets (Apple HIG, Material Design)
    - `accessibilityLabel` for screen readers
    - `accessibilityRole="button"` for semantic meaning
    - `accessibilityState={{ disabled }}` for state announcement
    - Pressed state feedback via opacity change

17. Create ScreenLayout template component

18. Initialize git repository

19. Run validation:
    - `npm run type-check`
    - `npm run lint`
    - `npm test`

20. Display next steps to user

**Quality Requirements:**
- All TypeScript strict flags enabled
- Zero TypeScript errors or warnings
- Zero linter warnings
- NO `any` types allowed
- Tests pass with 80%+ coverage

Reference the **expo-configuration**, **nativewind-patterns**, and **expo-router-patterns** skills.
