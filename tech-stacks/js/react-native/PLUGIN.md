# React Native Tech-Stack Plugin

React Native mobile development with Expo, NativeWind, and modern mobile tooling.

## Overview

This plugin extends the `js/common` foundation with React Native-specific tooling, patterns, and workflows. It focuses on modern mobile development using Expo SDK for the best developer experience.

## Core Principles

1. **Type Safety First** - Strict TypeScript, no `any` types
2. **Expo First** - Leverage Expo SDK for best DX
3. **Mobile Performance** - Optimize for 60fps, minimize bundle size
4. **Tailwind-Style DX** - NativeWind for familiar styling
5. **Accessibility First** - Screen reader support, touch targets

## Tech Stack

| Category | Technology | Version |
|----------|------------|---------|
| Framework | React Native | 0.76+ |
| SDK | Expo | 52+ |
| Routing | Expo Router | 4.x |
| Styling | NativeWind | 4.x |
| Components | Gluestack-ui | 2.x |
| State (Client) | Zustand | 5.x |
| State (Server) | TanStack Query | 5.x |
| Forms | React Hook Form | 7.x |
| Testing (Unit) | Jest + Testing Library | Latest |
| Testing (E2E) | Maestro | Latest |
| Linting | Biome | Latest |

## Project Types

### Expo App (Recommended)

Use for:
- Mobile apps (iOS + Android)
- Expo Router navigation
- EAS Build deployment
- OTA updates

```bash
/react-native:expo-init
```

## Commands

### Project Management

| Command | Description |
|---------|-------------|
| `/react-native:expo-init` | Initialize Expo project |
| `/react-native:preview` | Preview with Expo Go |

### Testing

| Command | Description |
|---------|-------------|
| `/react-native:test-component` | Test React Native components |
| `/react-native:test-e2e` | Run Maestro E2E tests |

### Refactoring

| Command | Description |
|---------|-------------|
| `/react-native:refactor-atomic-design` | Refactor existing project to Atomic Design structure |

### Build & Deploy

| Command | Description |
|---------|-------------|
| `/react-native:build-ios` | Build iOS app with EAS |
| `/react-native:build-android` | Build Android app |
| `/react-native:build-all` | Build both platforms |
| `/react-native:deploy-eas` | Deploy to EAS |
| `/react-native:update-ota` | Push OTA update |
| `/react-native:analyze` | Analyze bundle size |

### Inherited Commands (from js/common)

All commands from the base JavaScript stack are available:

- `/react-native:type-check` - TypeScript type checking
- `/react-native:lint` - Run Biome linter
- `/react-native:format` - Format code
- `/react-native:test` - Run unit tests
- `/react-native:test-coverage` - Coverage report
- `/react-native:validate` - Run all quality checks

## Agents

### component-builder

**Use PROACTIVELY** to build React Native components with TypeScript and mobile patterns.

Capabilities:
- Mobile component development
- React Native APIs (Platform, Dimensions)
- Platform-specific code
- Custom hooks for mobile

### ui-designer

Implements UI with NativeWind, Gluestack-ui, and mobile accessibility.

Capabilities:
- NativeWind styling
- Gluestack-ui components
- Mobile accessibility (screen readers)
- Responsive mobile design

### navigation-architect

Designs navigation with Expo Router (file-based routing).

Capabilities:
- Expo Router patterns
- Deep linking
- Route guards
- Navigation state

### performance-optimizer

Optimizes React Native app performance.

Capabilities:
- Bundle size optimization
- FlashList implementation
- Animation performance
- Memory management

### e2e-tester

Creates and maintains Maestro E2E tests.

Capabilities:
- Maestro testing
- Mobile gestures
- Platform-specific testing
- Visual regression

### code-analyzer

Analyzes component structure and generates refactoring plans for Atomic Design migration with mobile-specific criteria.

Capabilities:
- Component scanning and analysis
- Atomic level classification with mobile criteria
- Accessibility prop detection
- Refactoring plan generation
- Import statement updates
- React Native Storybook story generation

## Skills

### Mobile Development
- **nativewind-patterns** - Tailwind CSS for React Native
- **gluestack-ui-setup** - Component library setup
- **expo-router-patterns** - File-based navigation
- **expo-configuration** - Expo config and plugins

### Performance
- **react-native-performance** - Mobile optimization
- **flashlist-patterns** - High performance lists
- **reanimated-patterns** - Smooth animations

### State Management
- **zustand-mobile-patterns** - Client state for mobile
- **tanstack-query-mobile** - Server state and caching
- **form-handling-mobile** - Forms with validation

### Platform Features
- **secure-storage-patterns** - Secure token storage
- **platform-specific-code** - iOS/Android differences

### Testing
- **maestro-testing** - E2E testing setup
- **component-testing-mobile** - Jest patterns
- **accessibility-mobile** - a11y testing

### Deployment
- **eas-build-setup** - EAS Build configuration
- **eas-update-setup** - OTA updates

## Project Structure

```
project/
├── app/
│   ├── (auth)/
│   │   ├── login.tsx
│   │   ├── register.tsx
│   │   └── _layout.tsx
│   ├── (tabs)/
│   │   ├── _layout.tsx
│   │   ├── index.tsx
│   │   └── profile.tsx
│   └── _layout.tsx
├── components/
│   ├── atoms/
│   │   ├── Button/
│   │   │   ├── Button.tsx
│   │   │   ├── Button.stories.tsx
│   │   │   ├── index.ts
│   │   │   └── __tests__/
│   │   │       └── Button.test.tsx
│   │   ├── Input/
│   │   ├── Text/
│   │   ├── Icon/
│   │   └── index.ts          # Barrel export for atoms
│   ├── molecules/
│   │   ├── SearchBar/
│   │   ├── FormField/
│   │   ├── ListItem/
│   │   └── index.ts          # Barrel export for molecules
│   ├── organisms/
│   │   ├── Header/
│   │   ├── TabBar/
│   │   ├── LoginForm/
│   │   └── index.ts          # Barrel export for organisms
│   ├── templates/
│   │   ├── ScreenLayout/
│   │   │   ├── ScreenLayout.tsx
│   │   │   └── index.ts
│   │   ├── AuthLayout/
│   │   ├── TabLayout/
│   │   └── index.ts          # Barrel export for templates
│   └── index.ts              # Main barrel export
├── hooks/
│   ├── useAuth.ts
│   └── __tests__/
│       └── useAuth.test.ts
├── lib/
│   ├── api.ts
│   └── utils.ts
├── store/
│   └── authStore.ts
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
│   └── e2e/
│       └── login.yaml
├── app.json
├── eas.json
├── tsconfig.json
├── biome.json
├── tailwind.config.js
└── package.json
```

**Component Organization:** Uses [Atomic Design](https://bradfrost.com/blog/post/atomic-web-design/) pattern:
- **atoms/** - Basic building blocks (Button, Input, Text, Icon)
- **molecules/** - Functional units combining atoms (SearchBar, FormField, ListItem)
- **organisms/** - Complex UI sections (Header, TabBar, LoginForm)
- **templates/** - Screen-level layout structures (ScreenLayout, AuthLayout, TabLayout)
- **app/** - Screens via Expo Router file-based routing (uses templates)

**Note:** Expo projects do not use a `src/` directory. Templates handle mobile-specific concerns like safe areas, status bar, and keyboard avoidance.

## Quality Requirements

All React Native projects must pass:

- TypeScript type-check (zero errors)
- Biome linter (zero warnings)
- Tests (80%+ coverage)
- Accessibility audit
- Bundle size limits

## Deployment Targets

- EAS Build (iOS and Android)
- App Store (iOS)
- Google Play Store (Android)
- TestFlight (iOS beta)
- Firebase App Distribution

## Getting Started

1. Initialize a new project:
   ```bash
   /react-native:expo-init
   ```

2. Develop components:
   ```bash
   # Use the component-builder agent
   ```

3. Run quality checks:
   ```bash
   /react-native:validate
   ```

4. Build and deploy:
   ```bash
   /react-native:build-all
   /react-native:deploy-eas
   ```
