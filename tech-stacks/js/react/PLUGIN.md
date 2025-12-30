# React Tech-Stack Plugin

React 19 frontend development with Vite for SPAs and Next.js for full-stack web applications.

## Overview

This plugin extends the `js/common` foundation with React-specific tooling, patterns, and workflows. It supports two primary build systems:

- **Vite** - For SPAs and serverless deployments (Vercel, Netlify, Cloudflare)
- **Next.js** - For full-stack web apps with SSR/SSG capabilities

## Core Principles

1. **Type Safety First** - Strict TypeScript, no `any` types
2. **React 19 Features** - Server Components, Actions, use() hook
3. **Component-Driven** - Build UIs from isolated, testable components
4. **Accessibility First** - WCAG 2.1 compliance with Radix UI
5. **Performance Optimized** - Code splitting, lazy loading, memoization

## Tech Stack

| Category | Technology | Version |
|----------|------------|---------|
| UI Library | React | 19.x |
| Build (SPA) | Vite | 6.x |
| Build (Full-Stack) | Next.js | 15.x |
| Styling | Tailwind CSS | 4.x |
| UI Components | Radix UI / shadcn/ui | Latest |
| State (Client) | Zustand | 5.x |
| State (Server) | TanStack Query | 5.x |
| Testing (Unit) | Vitest + Testing Library | Latest |
| Testing (E2E) | Playwright | 1.40+ |

## Project Types

### Vite SPA

Use for:
- Single-page applications
- Serverless deployments
- Static sites with client-side routing
- Micro-frontends

```bash
/react:spa-init
```

### Next.js App

Use for:
- Full-stack web applications
- SSR/SSG requirements
- API routes
- SEO-critical sites

```bash
/react:nextjs-init
```

## Commands

### Project Management

| Command | Description |
|---------|-------------|
| `/react:spa-init` | Initialize Vite SPA project |
| `/react:nextjs-init` | Initialize Next.js project |

### Development

| Command | Description |
|---------|-------------|
| `/react:preview` | Preview production build locally |
| `/react:analyze` | Analyze bundle size |

### Testing

| Command | Description |
|---------|-------------|
| `/react:test-component` | Test React components |
| `/react:test-e2e` | Run Playwright E2E tests |
| `/react:test-visual` | Visual regression testing |

### Refactoring

| Command | Description |
|---------|-------------|
| `/react:refactor-atomic-design` | Refactor existing project to Atomic Design structure |

### Build & Deploy

| Command | Description |
|---------|-------------|
| `/react:build-spa` | Build Vite SPA |
| `/react:build-nextjs` | Build Next.js app |
| `/react:deploy-vercel` | Deploy to Vercel |
| `/react:deploy-netlify` | Deploy to Netlify |
| `/react:deploy-cloudflare` | Deploy to Cloudflare Pages |

### Inherited Commands (from js/common)

All commands from the base JavaScript stack are available:

- `/react:type-check` - TypeScript type checking
- `/react:lint` - Run linter (Biome or ESLint)
- `/react:format` - Format code
- `/react:test` - Run unit tests
- `/react:test-coverage` - Coverage report
- `/react:validate` - Run all quality checks
- `/react:audit` - Security audit

## Agents

### component-builder

**Use PROACTIVELY** to build React components with TypeScript and modern patterns.

Capabilities:
- React component development
- Custom hooks patterns
- Server Components (React 19)
- React 19 features (Actions, use() hook)

### state-architect

Designs state management solutions with Zustand, Jotai, or TanStack Query.

Capabilities:
- State management design
- Zustand store patterns
- TanStack Query data fetching
- Context optimization

### ui-designer

Implements UI components with Radix UI, shadcn/ui, and Tailwind CSS.

Capabilities:
- UI component design
- Accessibility implementation
- Responsive design
- Tailwind patterns

### performance-optimizer

Optimizes React app performance (bundle size, rendering, lazy loading).

Capabilities:
- Bundle analysis
- Code splitting
- Lazy loading
- Rendering optimization

### e2e-tester

Creates and maintains Playwright E2E tests.

Capabilities:
- Playwright testing
- Visual testing
- Accessibility testing
- E2E patterns

### code-analyzer

Analyzes component structure and generates refactoring plans for Atomic Design migration.

Capabilities:
- Component scanning and analysis
- Atomic level classification
- Refactoring plan generation
- Import statement updates
- Storybook story generation

## Skills

### React Development
- **react-19-patterns** - Server Components, Actions, use() hook
- **hooks-best-practices** - Custom hooks, dependency management
- **component-patterns** - Composition, compound components
- **performance-patterns** - Memoization, code splitting

### Build Tools
- **vite-configuration** - Vite 6.x setup for SPAs
- **nextjs-configuration** - Next.js 15 app router setup
- **bundle-optimization** - Tree shaking, code splitting

### State Management
- **zustand-patterns** - Client state management
- **tanstack-query-setup** - Server state and caching
- **jotai-patterns** - Atomic state management

### UI Development
- **radix-ui-patterns** - Accessible primitives
- **shadcn-ui-setup** - Component library setup
- **tailwind-setup** - Tailwind CSS configuration
- **responsive-design** - Mobile-first patterns

### Testing
- **component-testing** - Testing Library patterns
- **playwright-setup** - E2E testing setup
- **visual-regression** - Visual testing strategies
- **accessibility-testing** - a11y testing

### Deployment
- **vite-deployment** - SPA deployment
- **nextjs-deployment** - Next.js deployment

## Project Structure

### Vite SPA

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
│   │   │   ├── AuthLayout/
│   │   │   └── index.ts          # Barrel export for templates
│   │   └── index.ts              # Main barrel export
│   ├── hooks/
│   │   ├── useAuth.ts
│   │   └── __tests__/
│   │       └── useAuth.test.ts
│   ├── stores/
│   │   └── userStore.ts
│   ├── pages/
│   │   ├── Home/
│   │   │   └── HomePage.tsx
│   │   └── Dashboard/
│   │       └── DashboardPage.tsx
│   ├── lib/
│   │   └── utils.ts
│   ├── types/
│   ├── App.tsx
│   └── main.tsx
├── .storybook/
│   ├── main.ts
│   └── preview.ts
├── public/
├── tests/
│   └── e2e/
│       └── home.spec.ts
├── index.html
├── vite.config.ts
├── tsconfig.json
├── biome.json
└── package.json
```

**Component Organization:** Uses [Atomic Design](https://bradfrost.com/blog/post/atomic-web-design/) pattern:
- **atoms/** - Basic building blocks (Button, Input, Label)
- **molecules/** - Functional units combining atoms (FormField, SearchForm)
- **organisms/** - Complex UI sections (Header, LoginForm)
- **templates/** - Page-level layout structures (MainLayout, AuthLayout)
- **pages/** - Specific template instances with real content

### Next.js App

```
project/
├── src/
│   ├── app/
│   │   ├── layout.tsx            # Uses templates from components/
│   │   ├── page.tsx
│   │   └── api/
│   │       └── route.ts
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
│   │   │   ├── DashboardLayout/
│   │   │   ├── AuthLayout/
│   │   │   └── index.ts          # Barrel export for templates
│   │   └── index.ts              # Main barrel export
│   ├── hooks/
│   │   └── useAuth.ts
│   └── stores/
│       └── userStore.ts
├── .storybook/
│   ├── main.ts
│   └── preview.ts
├── public/
├── tests/
│   └── e2e/
│       └── home.spec.ts
├── next.config.ts
├── tsconfig.json
├── biome.json
└── package.json
```

**Component Organization:** Uses [Atomic Design](https://bradfrost.com/blog/post/atomic-web-design/) pattern:
- **atoms/** - Basic building blocks (Button, Input, Label)
- **molecules/** - Functional units combining atoms (FormField, SearchForm)
- **organisms/** - Complex UI sections (Header, LoginForm)
- **templates/** - Page-level layout structures (MainLayout, AuthLayout)
- **app/** - Pages via Next.js file-based routing (uses templates)

**Note:** Next.js layouts (`app/layout.tsx`) import and use templates from `components/templates/`. Templates are reusable component patterns; Next.js layouts are route-specific wrappers.

## Quality Requirements

All React projects must pass:

- TypeScript type-check (zero errors)
- Linter (zero warnings)
- Tests (80%+ coverage)
- Accessibility audit (axe-core)
- Bundle size limits

## Deployment Targets

- Vercel (recommended for Next.js)
- Netlify
- Cloudflare Pages
- AWS Amplify
- Firebase Hosting
- GitHub Pages
- Azure Static Web Apps
- Render

## Getting Started

1. Initialize a new project:
   ```bash
   /react:spa-init    # For Vite SPA
   /react:nextjs-init # For Next.js
   ```

2. Develop components:
   ```bash
   # Use the component-builder agent
   ```

3. Run quality checks:
   ```bash
   /react:validate
   ```

4. Deploy:
   ```bash
   /react:deploy-vercel
   ```
