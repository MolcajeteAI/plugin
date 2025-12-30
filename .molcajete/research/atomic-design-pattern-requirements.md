# Integrating Atomic Design Pattern into React and React Native Tech-Stacks

## Executive Summary

This document provides detailed guidance for integrating the Atomic Design Pattern into the existing React and React Native tech-stack plugins. The implementation will establish a default component organization hierarchy (Atoms, Molecules, Organisms, Templates, Pages) that promotes reusability, consistency, and scalability across projects. Additionally, Atoms, Molecules, and Organisms will be integrated with Storybook for component documentation and testing.

---

## Table of Contents

1. [Overview of Atomic Design Pattern](#1-overview-of-atomic-design-pattern)
2. [Current Tech-Stack Structure Analysis](#2-current-tech-stack-structure-analysis)
3. [Proposed Directory Structure](#3-proposed-directory-structure)
4. [Implementation Plan for React Tech-Stack](#4-implementation-plan-for-react-tech-stack)
5. [Implementation Plan for React Native Tech-Stack](#5-implementation-plan-for-react-native-tech-stack)
6. [Storybook Integration](#6-storybook-integration)
7. [Files to Modify](#7-files-to-modify)
8. [PRD Override Mechanism](#8-prd-override-mechanism)
9. [Best Practices and Guidelines](#9-best-practices-and-guidelines)
10. [Example Components](#10-example-components)

---

## 1. Overview of Atomic Design Pattern

### The Five-Level Hierarchy

| Level | Alternative Name | Description | Examples | State | Storybook |
|-------|------------------|-------------|----------|-------|-----------|
| **Atoms** | Elements | Basic building blocks | Buttons, Input fields, Labels, Icons | Stateless | Yes |
| **Molecules** | Widgets | Functional units combining atoms | Search forms, Input groups, Card headers | Minimal state | Yes |
| **Organisms** | Modules | Complex UI sections | Headers, Footers, Navigation bars, Sidebars | Can have state | Yes |
| **Templates** | Layouts | Page-level layout structures | Content layouts, Dashboard layouts | Layout state only | No |
| **Pages** | - | Specific template instances with real content | Home page, Profile page, Settings page | Full state | No |

### Key Benefits

1. **Consistency** - Reusing components ensures uniform design across the application
2. **Maintainability** - Smaller, isolated pieces are easier to update and debug
3. **Scalability** - Complex systems grow organically from simple, well-tested parts
4. **Testability** - Each level can be tested in isolation
5. **Documentation** - Storybook provides living documentation for UI components

### Core Principles for Implementation

- **Composition First**: Build small, composable components that combine to form larger structures
- **Single Responsibility**: Each component should do one thing well
- **Props for Flexibility**: Make components configurable rather than rigid
- **State Elevation**: Keep state at higher levels, pass down as props
- **Type Safety**: Strict TypeScript interfaces for all components

---

## 2. Current Tech-Stack Structure Analysis

### React Tech-Stack (Vite SPA Structure)

```
src/
├── components/
│   └── Button/
│       ├── Button.tsx
│       ├── Button.stories.tsx
│       └── __tests__/
│           └── Button.test.tsx
├── hooks/
├── stores/
├── pages/
├── App.tsx
└── main.tsx
```

### React Tech-Stack (Next.js Structure)

```
src/
├── app/
│   ├── layout.tsx
│   ├── page.tsx
│   └── api/
├── components/
│   └── Button/
├── hooks/
└── stores/
```

### React Native Tech-Stack (Expo Structure)

```
├── app/
│   ├── (auth)/
│   ├── (tabs)/
│   └── _layout.tsx
├── components/
│   ├── ui/
│   ├── forms/
│   └── layouts/
├── hooks/
├── store/
└── constants/
```

---

## 3. Proposed Directory Structure

### React (Vite SPA) with Atomic Design

```
src/
├── components/
│   ├── atoms/
│   │   ├── Button/
│   │   │   ├── Button.tsx
│   │   │   ├── Button.stories.tsx
│   │   │   ├── index.ts
│   │   │   └── __tests__/
│   │   │       └── Button.test.tsx
│   │   ├── Input/
│   │   │   ├── Input.tsx
│   │   │   ├── Input.stories.tsx
│   │   │   ├── index.ts
│   │   │   └── __tests__/
│   │   │       └── Input.test.tsx
│   │   ├── Label/
│   │   ├── Icon/
│   │   ├── Text/
│   │   ├── Image/
│   │   └── index.ts          # Re-exports all atoms
│   ├── molecules/
│   │   ├── SearchForm/
│   │   │   ├── SearchForm.tsx
│   │   │   ├── SearchForm.stories.tsx
│   │   │   ├── index.ts
│   │   │   └── __tests__/
│   │   │       └── SearchForm.test.tsx
│   │   ├── InputGroup/
│   │   ├── Card/
│   │   ├── MenuItem/
│   │   └── index.ts          # Re-exports all molecules
│   ├── organisms/
│   │   ├── Header/
│   │   │   ├── Header.tsx
│   │   │   ├── Header.stories.tsx
│   │   │   ├── index.ts
│   │   │   └── __tests__/
│   │   │       └── Header.test.tsx
│   │   ├── Footer/
│   │   ├── Navigation/
│   │   ├── Sidebar/
│   │   ├── LoginForm/
│   │   └── index.ts          # Re-exports all organisms
│   ├── templates/
│   │   ├── MainLayout/
│   │   │   ├── MainLayout.tsx
│   │   │   └── index.ts
│   │   ├── DashboardLayout/
│   │   ├── AuthLayout/
│   │   └── index.ts          # Re-exports all templates
│   └── index.ts              # Main barrel export
├── pages/                    # Page components (specific instances)
│   ├── Home/
│   │   └── Home.tsx
│   ├── Dashboard/
│   └── Profile/
├── hooks/
├── stores/
├── lib/
├── types/
├── App.tsx
└── main.tsx
```

### React (Next.js App Router) with Atomic Design

```
src/
├── components/
│   ├── atoms/
│   │   ├── Button/
│   │   │   ├── Button.tsx
│   │   │   ├── Button.stories.tsx
│   │   │   ├── index.ts
│   │   │   └── __tests__/
│   │   │       └── Button.test.tsx
│   │   ├── Input/
│   │   ├── Label/
│   │   └── index.ts
│   ├── molecules/
│   │   ├── SearchForm/
│   │   ├── InputGroup/
│   │   └── index.ts
│   ├── organisms/
│   │   ├── Header/
│   │   ├── Footer/
│   │   └── index.ts
│   ├── templates/
│   │   ├── MainLayout/
│   │   ├── DashboardLayout/
│   │   └── index.ts
│   └── index.ts
├── app/                      # Pages (Next.js file-based routing)
│   ├── layout.tsx            # Uses templates
│   ├── page.tsx              # Home page
│   ├── dashboard/
│   │   └── page.tsx
│   └── api/
├── hooks/
├── stores/
└── lib/
```

### React Native (Expo) with Atomic Design

```
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
│   │   └── index.ts
│   ├── molecules/
│   │   ├── SearchBar/
│   │   ├── ListItem/
│   │   ├── FormField/
│   │   └── index.ts
│   ├── organisms/
│   │   ├── Header/
│   │   ├── TabBar/
│   │   ├── LoginForm/
│   │   └── index.ts
│   ├── templates/
│   │   ├── ScreenLayout/
│   │   ├── AuthLayout/
│   │   ├── TabLayout/
│   │   └── index.ts
│   └── index.ts
├── app/                      # Pages (Expo Router file-based routing)
│   ├── (auth)/
│   │   ├── login.tsx
│   │   └── _layout.tsx
│   ├── (tabs)/
│   │   ├── _layout.tsx
│   │   ├── index.tsx
│   │   └── profile.tsx
│   └── _layout.tsx
├── hooks/
├── store/
├── lib/
└── constants/
```

---

## 4. Implementation Plan for React Tech-Stack

### Files to Create

#### 4.1. New Skill: `skills/atomic-design/SKILL.md`

```markdown
---
name: atomic-design
description: Atomic Design Pattern for organizing React components into atoms, molecules, organisms, templates, and pages. Use when structuring component hierarchies.
---

# Atomic Design Pattern Skill

This skill covers the Atomic Design methodology for organizing React components.

## When to Use

Use this skill when:
- Setting up a new project structure
- Creating new components
- Refactoring existing component organization
- Building component libraries

## The Hierarchy

### Atoms (Elements)

Basic building blocks that cannot be broken down further.

**Characteristics:**
- Stateless or minimal state
- Single responsibility
- Highly reusable
- No dependencies on other components
- Added to Storybook

**Examples:** Button, Input, Label, Icon, Text, Image, Badge, Avatar

```typescript
// src/components/atoms/Button/Button.tsx
interface ButtonProps {
  variant: 'primary' | 'secondary' | 'danger';
  size?: 'sm' | 'md' | 'lg';
  disabled?: boolean;
  onClick?: () => void;
  children: React.ReactNode;
}

export function Button({
  variant,
  size = 'md',
  disabled = false,
  onClick,
  children,
}: ButtonProps): React.ReactElement {
  return (
    <button
      type="button"
      className={cn(buttonVariants({ variant, size }))}
      disabled={disabled}
      onClick={onClick}
    >
      {children}
    </button>
  );
}
```

### Molecules (Widgets)

Functional units that combine atoms into cohesive groups.

**Characteristics:**
- Combine 2+ atoms
- Single functional purpose
- May have minimal internal state
- Props-driven behavior
- Added to Storybook

**Examples:** SearchForm, InputGroup, Card, MenuItem, FormField

```typescript
// src/components/molecules/SearchForm/SearchForm.tsx
import { Input, Button, Icon } from '@/components/atoms';

interface SearchFormProps {
  onSearch: (query: string) => void;
  placeholder?: string;
}

export function SearchForm({
  onSearch,
  placeholder = 'Search...',
}: SearchFormProps): React.ReactElement {
  const [query, setQuery] = useState('');

  const handleSubmit = (e: FormEvent): void => {
    e.preventDefault();
    onSearch(query);
  };

  return (
    <form onSubmit={handleSubmit} className="flex gap-2">
      <Input
        value={query}
        onChange={(e) => setQuery(e.target.value)}
        placeholder={placeholder}
      />
      <Button variant="primary" type="submit">
        <Icon name="search" />
      </Button>
    </form>
  );
}
```

### Organisms (Modules)

Complex UI sections composed of molecules and/or atoms.

**Characteristics:**
- Larger interface sections
- Can have their own state and functionality
- May connect to global state
- Handle business logic at section level
- Added to Storybook

**Examples:** Header, Footer, Navigation, Sidebar, LoginForm, ProductCard

```typescript
// src/components/organisms/Header/Header.tsx
import { Logo, Button } from '@/components/atoms';
import { SearchForm, Navigation } from '@/components/molecules';

interface HeaderProps {
  onSearch: (query: string) => void;
  isAuthenticated: boolean;
  onLogin: () => void;
  onLogout: () => void;
}

export function Header({
  onSearch,
  isAuthenticated,
  onLogin,
  onLogout,
}: HeaderProps): React.ReactElement {
  return (
    <header className="flex items-center justify-between p-4 border-b">
      <Logo />
      <Navigation />
      <SearchForm onSearch={onSearch} />
      {isAuthenticated ? (
        <Button variant="secondary" onClick={onLogout}>Logout</Button>
      ) : (
        <Button variant="primary" onClick={onLogin}>Login</Button>
      )}
    </header>
  );
}
```

### Templates (Layouts)

Page-level structures that define content placement.

**Characteristics:**
- Define page layout structure
- Accept children or slot props
- No real content, only placeholders
- Handle responsive behavior
- NOT added to Storybook

**Examples:** MainLayout, DashboardLayout, AuthLayout, TwoColumnLayout

```typescript
// src/components/templates/MainLayout/MainLayout.tsx
import { Header, Footer } from '@/components/organisms';

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
      <Footer />
    </div>
  );
}
```

### Pages

Specific instances of templates with real content.

**Characteristics:**
- Use templates for structure
- Contain actual content
- Connect to data sources
- Handle page-level state
- NOT added to Storybook

**Examples:** HomePage, DashboardPage, ProfilePage, SettingsPage

```typescript
// src/pages/Home/Home.tsx (Vite) or src/app/page.tsx (Next.js)
import { MainLayout } from '@/components/templates';
import { HeroSection, FeatureGrid, Testimonials } from '@/components/organisms';

export function HomePage(): React.ReactElement {
  return (
    <MainLayout>
      <HeroSection
        title="Welcome to Our App"
        subtitle="Build amazing things"
      />
      <FeatureGrid features={features} />
      <Testimonials items={testimonials} />
    </MainLayout>
  );
}
```

## Barrel Exports Pattern

Each directory level should have an `index.ts` for clean imports:

```typescript
// src/components/atoms/index.ts
export { Button } from './Button';
export { Input } from './Input';
export { Label } from './Label';
export { Icon } from './Icon';

// src/components/molecules/index.ts
export { SearchForm } from './SearchForm';
export { InputGroup } from './InputGroup';
export { Card } from './Card';

// src/components/organisms/index.ts
export { Header } from './Header';
export { Footer } from './Footer';
export { Navigation } from './Navigation';

// src/components/templates/index.ts
export { MainLayout } from './MainLayout';
export { DashboardLayout } from './DashboardLayout';

// src/components/index.ts
export * from './atoms';
export * from './molecules';
export * from './organisms';
export * from './templates';
```

## Decision Guide: Which Level?

| Question | Answer | Level |
|----------|--------|-------|
| Can it be broken down further? | No | Atom |
| Does it combine atoms? | Yes | Molecule |
| Is it a larger section with business logic? | Yes | Organism |
| Does it define page structure? | Yes | Template |
| Does it have real content? | Yes | Page |

## Best Practices

1. **Start with atoms** - Build your design system foundation first
2. **Keep atoms stateless** - Or with only UI state (hover, focus)
3. **Molecules are functional groups** - They serve one purpose
4. **Organisms can connect to stores** - But prefer props
5. **Templates are content-agnostic** - They only define structure
6. **Pages wire everything together** - Data, state, and UI

## Notes

- This pattern is enabled by default in the React tech-stack
- To disable, specify `atomicDesign: false` in your PRD
- All atoms, molecules, and organisms should have Storybook stories
```

#### 4.2. Update `PLUGIN.md` Project Structure Section

The project structure section in `PLUGIN.md` should be updated to show the Atomic Design hierarchy.

#### 4.3. Update `commands/spa-init.md` and `commands/nextjs-init.md`

Add instructions to create the atomic directory structure by default.

#### 4.4. Update `agents/component-builder.md`

Add guidance on which atomic level to use when creating components.

---

## 5. Implementation Plan for React Native Tech-Stack

### Files to Create

#### 5.1. New Skill: `skills/atomic-design-mobile/SKILL.md`

Similar to React but with mobile-specific considerations:

```markdown
---
name: atomic-design-mobile
description: Atomic Design Pattern for organizing React Native components. Mobile-specific patterns for atoms, molecules, organisms, and templates.
---

# Atomic Design Pattern (Mobile) Skill

## Mobile-Specific Considerations

### Atoms
- Must have minimum 44x44 touch targets
- Include accessibility props (accessibilityLabel, accessibilityRole)
- Support platform-specific styling

### Molecules
- Handle keyboard avoidance
- Support gesture handlers

### Organisms
- Platform-aware (iOS/Android differences)
- Handle safe areas

### Templates
- Screen-level layouts
- Handle keyboard, status bar, navigation
```

#### 5.2. Update `PLUGIN.md`, `commands/expo-init.md`, and `agents/component-builder.md`

---

## 6. Storybook Integration

### 6.1. Storybook Setup for React (Vite)

Add to `commands/spa-init.md`:

```bash
# Install Storybook
npx storybook@latest init --type react_vite

# Install addons
npm install -D @storybook/addon-a11y @storybook/addon-viewport
```

### 6.2. Storybook Setup for React (Next.js)

Add to `commands/nextjs-init.md`:

```bash
# Install Storybook
npx storybook@latest init --type nextjs

# Install addons
npm install -D @storybook/addon-a11y @storybook/addon-viewport
```

### 6.3. Storybook Setup for React Native

Add to `commands/expo-init.md`:

```bash
# Install React Native Storybook
npx -p @storybook/cli sb init --type react_native
```

### 6.4. Story File Template

```typescript
// Button.stories.tsx
import type { Meta, StoryObj } from '@storybook/react';
import { Button } from './Button';

const meta: Meta<typeof Button> = {
  title: 'Atoms/Button',
  component: Button,
  tags: ['autodocs'],
  argTypes: {
    variant: {
      control: 'select',
      options: ['primary', 'secondary', 'danger'],
    },
    size: {
      control: 'select',
      options: ['sm', 'md', 'lg'],
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

export const Disabled: Story = {
  args: {
    variant: 'primary',
    children: 'Disabled Button',
    disabled: true,
  },
};
```

### 6.5. Storybook Directory Structure

Configure `.storybook/main.ts` to organize stories by atomic level:

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
};

export default config;
```

---

## 7. Files to Modify

### React Tech-Stack (`/tech-stacks/js/react/`)

| File | Modification |
|------|--------------|
| `PLUGIN.md` | Update project structure section to show atomic hierarchy |
| `commands/spa-init.md` | Add atomic directory creation, Storybook setup |
| `commands/nextjs-init.md` | Add atomic directory creation, Storybook setup |
| `agents/component-builder.md` | Add atomic level decision guidance |
| `skills/component-patterns/SKILL.md` | Reference atomic design skill |
| **NEW** `skills/atomic-design/SKILL.md` | Create new skill file |

### React Native Tech-Stack (`/tech-stacks/js/react-native/`)

| File | Modification |
|------|--------------|
| `PLUGIN.md` | Update project structure section to show atomic hierarchy |
| `commands/expo-init.md` | Add atomic directory creation, Storybook setup |
| `agents/component-builder.md` | Add atomic level decision guidance |
| **NEW** `skills/atomic-design-mobile/SKILL.md` | Create new skill file |

---

## 8. PRD Override Mechanism

### Disabling Atomic Design

Projects can opt out of Atomic Design by specifying in their PRD:

```yaml
# project.prd.yaml
techStack:
  framework: react
  componentOrganization: flat  # Options: atomic (default), flat, feature-based
```

### Alternative: Feature-Based Organization

```yaml
techStack:
  framework: react
  componentOrganization: feature-based
```

Results in:
```
src/
├── features/
│   ├── auth/
│   │   ├── components/
│   │   ├── hooks/
│   │   └── stores/
│   ├── dashboard/
│   └── profile/
├── shared/
│   └── components/
```

### Implementation in Init Commands

The init commands should check for PRD settings:

```typescript
// In spa-init or nextjs-init logic
const componentOrganization = prd?.techStack?.componentOrganization ?? 'atomic';

if (componentOrganization === 'atomic') {
  // Create atomic structure
} else if (componentOrganization === 'flat') {
  // Create flat structure
} else if (componentOrganization === 'feature-based') {
  // Create feature-based structure
}
```

---

## 9. Best Practices and Guidelines

### Component Classification Checklist

**Is it an Atom?**
- [ ] Cannot be broken down into smaller components
- [ ] Single HTML element or very simple composition
- [ ] No business logic
- [ ] Stateless or only UI state

**Is it a Molecule?**
- [ ] Combines 2+ atoms
- [ ] Single functional purpose
- [ ] Minimal internal state
- [ ] No data fetching

**Is it an Organism?**
- [ ] Larger interface section
- [ ] May have business logic
- [ ] May connect to stores
- [ ] Relatively standalone

**Is it a Template?**
- [ ] Defines page structure
- [ ] Uses slots/children for content
- [ ] No real data

**Is it a Page?**
- [ ] Uses a template
- [ ] Has real content
- [ ] Connects to data sources

### Naming Conventions

```
atoms/
  Button/         # PascalCase
  button.stories  # lowercase for stories
  Button.test     # PascalCase for tests

molecules/
  SearchForm/     # Descriptive compound names
  InputGroup/

organisms/
  HeaderNavigation/  # Clear section names
  ProductCard/

templates/
  MainLayout/     # Always end with "Layout"
  DashboardLayout/

pages/
  HomePage/       # Always end with "Page"
  DashboardPage/
```

### Import Strategy

```typescript
// Prefer relative within same level
import { Button } from '../Button';

// Use path alias across levels
import { Button, Input } from '@/components/atoms';
import { SearchForm } from '@/components/molecules';
import { Header } from '@/components/organisms';
import { MainLayout } from '@/components/templates';
```

---

## 10. Example Components

### Atom: Button

```typescript
// src/components/atoms/Button/Button.tsx
import { forwardRef } from 'react';
import { cn } from '@/lib/utils';

interface ButtonProps extends React.ButtonHTMLAttributes<HTMLButtonElement> {
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
          'focus-visible:outline-none focus-visible:ring-2',
          {
            'bg-blue-600 text-white hover:bg-blue-700': variant === 'primary',
            'bg-gray-200 text-gray-900 hover:bg-gray-300': variant === 'secondary',
            'bg-red-600 text-white hover:bg-red-700': variant === 'danger',
            'bg-transparent hover:bg-gray-100': variant === 'ghost',
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
        {loading && <Spinner className="mr-2 h-4 w-4" />}
        {children}
      </button>
    );
  }
);
Button.displayName = 'Button';
```

### Molecule: FormField

```typescript
// src/components/molecules/FormField/FormField.tsx
import { Label, Input, Text } from '@/components/atoms';

interface FormFieldProps {
  label: string;
  name: string;
  type?: string;
  placeholder?: string;
  error?: string;
  required?: boolean;
}

export function FormField({
  label,
  name,
  type = 'text',
  placeholder,
  error,
  required,
}: FormFieldProps): React.ReactElement {
  return (
    <div className="space-y-1">
      <Label htmlFor={name}>
        {label}
        {required && <span className="text-red-500 ml-1">*</span>}
      </Label>
      <Input
        id={name}
        name={name}
        type={type}
        placeholder={placeholder}
        aria-invalid={!!error}
        aria-describedby={error ? `${name}-error` : undefined}
      />
      {error && (
        <Text id={`${name}-error`} className="text-red-500 text-sm">
          {error}
        </Text>
      )}
    </div>
  );
}
```

### Organism: LoginForm

```typescript
// src/components/organisms/LoginForm/LoginForm.tsx
import { useState } from 'react';
import { Button } from '@/components/atoms';
import { FormField } from '@/components/molecules';

interface LoginFormProps {
  onSubmit: (email: string, password: string) => Promise<void>;
}

export function LoginForm({ onSubmit }: LoginFormProps): React.ReactElement {
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [loading, setLoading] = useState(false);
  const [errors, setErrors] = useState<Record<string, string>>({});

  const handleSubmit = async (e: React.FormEvent): Promise<void> => {
    e.preventDefault();
    setLoading(true);
    try {
      await onSubmit(email, password);
    } catch (error) {
      setErrors({ form: 'Invalid credentials' });
    } finally {
      setLoading(false);
    }
  };

  return (
    <form onSubmit={handleSubmit} className="space-y-4 max-w-md">
      <FormField
        label="Email"
        name="email"
        type="email"
        placeholder="you@example.com"
        error={errors.email}
        required
      />
      <FormField
        label="Password"
        name="password"
        type="password"
        placeholder="********"
        error={errors.password}
        required
      />
      {errors.form && (
        <div className="text-red-500 text-sm">{errors.form}</div>
      )}
      <Button variant="primary" type="submit" loading={loading} className="w-full">
        Sign In
      </Button>
    </form>
  );
}
```

### Template: AuthLayout

```typescript
// src/components/templates/AuthLayout/AuthLayout.tsx
interface AuthLayoutProps {
  children: React.ReactNode;
  title: string;
  subtitle?: string;
}

export function AuthLayout({
  children,
  title,
  subtitle,
}: AuthLayoutProps): React.ReactElement {
  return (
    <div className="min-h-screen flex items-center justify-center bg-gray-50">
      <div className="max-w-md w-full space-y-8 p-8 bg-white rounded-lg shadow">
        <div className="text-center">
          <h1 className="text-3xl font-bold">{title}</h1>
          {subtitle && <p className="mt-2 text-gray-600">{subtitle}</p>}
        </div>
        {children}
      </div>
    </div>
  );
}
```

### Page: LoginPage

```typescript
// src/pages/Login/LoginPage.tsx (Vite) or src/app/login/page.tsx (Next.js)
import { AuthLayout } from '@/components/templates';
import { LoginForm } from '@/components/organisms';
import { useAuth } from '@/hooks/useAuth';

export function LoginPage(): React.ReactElement {
  const { login } = useAuth();

  return (
    <AuthLayout
      title="Welcome Back"
      subtitle="Sign in to your account"
    >
      <LoginForm onSubmit={login} />
    </AuthLayout>
  );
}
```

---

## Summary

This document outlines a complete strategy for integrating Atomic Design Pattern into the React and React Native tech-stacks. The implementation includes:

1. **New directory structure** following the five-level atomic hierarchy
2. **New skills** (`atomic-design` and `atomic-design-mobile`) with detailed guidance
3. **Updated init commands** to create the structure by default
4. **Storybook integration** for atoms, molecules, and organisms
5. **PRD override mechanism** for projects that prefer alternative organization
6. **Detailed examples** for each atomic level

The changes will establish a consistent, scalable approach to component organization that promotes reusability and maintainability across all projects using these tech-stacks.
