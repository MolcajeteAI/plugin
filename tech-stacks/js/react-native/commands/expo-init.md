---
description: Initialize Expo project with React Native, TypeScript, and modern tooling
---

# Initialize Expo Project

Initialize a new React Native app with Expo, TypeScript strict mode, NativeWind, and modern tooling.

Use the Task tool to launch the **component-builder** agent with instructions:

1. Ask user for project details using AskUserQuestion tool:
   - Project name
   - Include Gluestack-ui? (yes/no)
   - State management (Zustand, Jotai, none)
   - Package manager (npm, pnpm, yarn)
   - Initialize EAS? (yes/no)

2. Create project using Expo:
   ```bash
   npx create-expo-app@latest {project-name}
   cd {project-name}
   ```

3. Create project structure:
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
   │   ├── ui/
   │   │   └── Button/
   │   │       ├── Button.tsx
   │   │       ├── index.ts
   │   │       └── __tests__/
   │   │           └── Button.test.tsx
   │   └── ThemedView.tsx
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
   ├── __tests__/
   │   ├── components/
   │   └── e2e/
   ├── app.json
   ├── tsconfig.json
   ├── biome.json
   ├── tailwind.config.js
   └── package.json
   ```

4. Update `tsconfig.json` with strict configuration:
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

5. Install NativeWind:
   ```bash
   npx expo install nativewind
   npm install --dev tailwindcss
   npx tailwindcss init
   ```

6. Create `tailwind.config.js`:
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

7. Update `babel.config.js`:
   ```javascript
   module.exports = function(api) {
     api.cache(true);
     return {
       presets: ['babel-preset-expo'],
       plugins: ["nativewind/babel"],
     };
   };
   ```

8. Create `biome.json` with strict rules (reference **biome-setup** skill from js/common)

9. Create `jest.config.js`:
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

10. Update `package.json` scripts:
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
        "validate": "npm run type-check && npm run lint && npm test"
      }
    }
    ```

11. Install dependencies:
    - Core: expo, react-native, typescript
    - Testing: jest-expo, @testing-library/react-native
    - Biome
    - Selected state management
    - TanStack Query, React Hook Form, Zod

12. If Gluestack-ui selected:
    ```bash
    npx gluestack-ui init
    ```

13. If EAS selected:
    ```bash
    npm install -g eas-cli
    eas login
    eas build:configure
    ```

14. Create starter components and screens

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
- Tests pass with 80%+ coverage

Reference the **expo-configuration**, **nativewind-patterns**, and **expo-router-patterns** skills.
