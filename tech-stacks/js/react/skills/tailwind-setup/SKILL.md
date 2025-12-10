---
name: tailwind-setup
description: Tailwind CSS 4.x configuration and patterns. Use when setting up or customizing Tailwind CSS.
---

# Tailwind CSS Setup Skill

This skill covers Tailwind CSS 4.x configuration for React applications.

## When to Use

Use this skill when:
- Setting up Tailwind CSS
- Customizing theme and colors
- Creating utility patterns
- Configuring dark mode

## Core Principle

**UTILITY FIRST** - Build designs with utility classes. Extract components only when patterns repeat.

## Installation

### Vite

```bash
npm install -D tailwindcss postcss autoprefixer
npx tailwindcss init -p
```

### Next.js

```bash
# Included with create-next-app --tailwind
# Or install manually:
npm install -D tailwindcss postcss autoprefixer
npx tailwindcss init -p
```

## Configuration

```typescript
// tailwind.config.ts
import type { Config } from 'tailwindcss';

const config: Config = {
  content: [
    './src/**/*.{js,ts,jsx,tsx,mdx}',
    './app/**/*.{js,ts,jsx,tsx,mdx}',
    './components/**/*.{js,ts,jsx,tsx,mdx}',
  ],
  darkMode: 'class',
  theme: {
    extend: {
      colors: {
        border: 'hsl(var(--border))',
        background: 'hsl(var(--background))',
        foreground: 'hsl(var(--foreground))',
        primary: {
          DEFAULT: 'hsl(var(--primary))',
          foreground: 'hsl(var(--primary-foreground))',
        },
        secondary: {
          DEFAULT: 'hsl(var(--secondary))',
          foreground: 'hsl(var(--secondary-foreground))',
        },
        destructive: {
          DEFAULT: 'hsl(var(--destructive))',
          foreground: 'hsl(var(--destructive-foreground))',
        },
        muted: {
          DEFAULT: 'hsl(var(--muted))',
          foreground: 'hsl(var(--muted-foreground))',
        },
        accent: {
          DEFAULT: 'hsl(var(--accent))',
          foreground: 'hsl(var(--accent-foreground))',
        },
      },
      fontFamily: {
        sans: ['var(--font-sans)', 'system-ui', 'sans-serif'],
        mono: ['var(--font-mono)', 'monospace'],
      },
      borderRadius: {
        lg: 'var(--radius)',
        md: 'calc(var(--radius) - 2px)',
        sm: 'calc(var(--radius) - 4px)',
      },
      keyframes: {
        'accordion-down': {
          from: { height: '0' },
          to: { height: 'var(--radix-accordion-content-height)' },
        },
        'accordion-up': {
          from: { height: 'var(--radix-accordion-content-height)' },
          to: { height: '0' },
        },
      },
      animation: {
        'accordion-down': 'accordion-down 0.2s ease-out',
        'accordion-up': 'accordion-up 0.2s ease-out',
      },
    },
  },
  plugins: [
    require('@tailwindcss/typography'),
    require('@tailwindcss/forms'),
    require('tailwindcss-animate'),
  ],
};

export default config;
```

## CSS Variables Setup

```css
/* globals.css */
@tailwind base;
@tailwind components;
@tailwind utilities;

@layer base {
  :root {
    --background: 0 0% 100%;
    --foreground: 222.2 84% 4.9%;
    --card: 0 0% 100%;
    --card-foreground: 222.2 84% 4.9%;
    --popover: 0 0% 100%;
    --popover-foreground: 222.2 84% 4.9%;
    --primary: 222.2 47.4% 11.2%;
    --primary-foreground: 210 40% 98%;
    --secondary: 210 40% 96.1%;
    --secondary-foreground: 222.2 47.4% 11.2%;
    --muted: 210 40% 96.1%;
    --muted-foreground: 215.4 16.3% 46.9%;
    --accent: 210 40% 96.1%;
    --accent-foreground: 222.2 47.4% 11.2%;
    --destructive: 0 84.2% 60.2%;
    --destructive-foreground: 210 40% 98%;
    --border: 214.3 31.8% 91.4%;
    --input: 214.3 31.8% 91.4%;
    --ring: 222.2 84% 4.9%;
    --radius: 0.5rem;
  }

  .dark {
    --background: 222.2 84% 4.9%;
    --foreground: 210 40% 98%;
    --card: 222.2 84% 4.9%;
    --card-foreground: 210 40% 98%;
    --popover: 222.2 84% 4.9%;
    --popover-foreground: 210 40% 98%;
    --primary: 210 40% 98%;
    --primary-foreground: 222.2 47.4% 11.2%;
    --secondary: 217.2 32.6% 17.5%;
    --secondary-foreground: 210 40% 98%;
    --muted: 217.2 32.6% 17.5%;
    --muted-foreground: 215 20.2% 65.1%;
    --accent: 217.2 32.6% 17.5%;
    --accent-foreground: 210 40% 98%;
    --destructive: 0 62.8% 30.6%;
    --destructive-foreground: 210 40% 98%;
    --border: 217.2 32.6% 17.5%;
    --input: 217.2 32.6% 17.5%;
    --ring: 212.7 26.8% 83.9%;
  }
}

@layer base {
  * {
    @apply border-border;
  }
  body {
    @apply bg-background text-foreground;
  }
}
```

## Common Patterns

### Container with Max Width

```typescript
function Container({ children }: { children: React.ReactNode }): React.ReactElement {
  return (
    <div className="container mx-auto px-4 sm:px-6 lg:px-8">
      {children}
    </div>
  );
}
```

### Responsive Grid

```typescript
function Grid({ children }: { children: React.ReactNode }): React.ReactElement {
  return (
    <div className="grid grid-cols-1 gap-4 sm:grid-cols-2 lg:grid-cols-3 xl:grid-cols-4">
      {children}
    </div>
  );
}
```

### Flex Layouts

```typescript
// Horizontal center
<div className="flex items-center justify-center">

// Space between
<div className="flex items-center justify-between">

// Vertical stack
<div className="flex flex-col space-y-4">

// Horizontal stack with gap
<div className="flex items-center gap-4">
```

### Card Pattern

```typescript
function Card({ children }: { children: React.ReactNode }): React.ReactElement {
  return (
    <div className="rounded-lg border bg-card p-6 shadow-sm">
      {children}
    </div>
  );
}
```

### Button Variants

```typescript
// Primary
<button className="bg-primary text-primary-foreground hover:bg-primary/90 h-10 px-4 rounded-md">

// Secondary
<button className="bg-secondary text-secondary-foreground hover:bg-secondary/80 h-10 px-4 rounded-md">

// Outline
<button className="border border-input bg-background hover:bg-accent h-10 px-4 rounded-md">

// Ghost
<button className="hover:bg-accent hover:text-accent-foreground h-10 px-4 rounded-md">
```

### Form Input

```typescript
<input
  type="text"
  className="flex h-10 w-full rounded-md border border-input bg-background px-3 py-2 text-sm ring-offset-background file:border-0 file:bg-transparent file:text-sm file:font-medium placeholder:text-muted-foreground focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring focus-visible:ring-offset-2 disabled:cursor-not-allowed disabled:opacity-50"
/>
```

## Dark Mode

### Class-Based (Recommended)

```typescript
// tailwind.config.ts
darkMode: 'class',

// Toggle dark mode
function ThemeToggle(): React.ReactElement {
  const [theme, setTheme] = useState<'light' | 'dark'>('light');

  useEffect(() => {
    document.documentElement.classList.toggle('dark', theme === 'dark');
  }, [theme]);

  return (
    <button onClick={() => setTheme(theme === 'light' ? 'dark' : 'light')}>
      Toggle Theme
    </button>
  );
}
```

### Using dark: Modifier

```typescript
<div className="bg-white dark:bg-gray-900 text-gray-900 dark:text-gray-100">
  Adapts to dark mode
</div>
```

## Responsive Design

```typescript
// Mobile first breakpoints
// sm: 640px
// md: 768px
// lg: 1024px
// xl: 1280px
// 2xl: 1536px

<div className="
  text-sm
  sm:text-base
  md:text-lg
  lg:text-xl
">
  Responsive text
</div>

<div className="
  w-full
  sm:w-1/2
  md:w-1/3
  lg:w-1/4
">
  Responsive width
</div>
```

## Custom Components

### Creating Reusable Classes

```css
/* globals.css */
@layer components {
  .btn {
    @apply inline-flex items-center justify-center rounded-md text-sm font-medium transition-colors focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring focus-visible:ring-offset-2 disabled:opacity-50 disabled:pointer-events-none;
  }

  .btn-primary {
    @apply bg-primary text-primary-foreground hover:bg-primary/90;
  }

  .btn-secondary {
    @apply bg-secondary text-secondary-foreground hover:bg-secondary/80;
  }
}
```

## cn() Utility

```typescript
// lib/utils.ts
import { type ClassValue, clsx } from 'clsx';
import { twMerge } from 'tailwind-merge';

export function cn(...inputs: ClassValue[]): string {
  return twMerge(clsx(inputs));
}

// Usage
<div className={cn(
  'base-class',
  isActive && 'active-class',
  variant === 'primary' ? 'primary-class' : 'secondary-class'
)}>
```

## Best Practices

1. **Mobile first** - Start with mobile, add breakpoints
2. **Use design tokens** - CSS variables for consistency
3. **Extract components** - When patterns repeat 3+ times
4. **Use cn()** - For conditional/merged classes
5. **Avoid @apply overuse** - Utilities in JSX are fine

## Notes

- Tailwind CSS 4.x uses native CSS nesting
- PurgeCSS is built-in (only used classes in bundle)
- Use VS Code Tailwind CSS IntelliSense extension
- PostCSS config is required
