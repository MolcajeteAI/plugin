---
name: component-testing
description: React component testing with Vitest and Testing Library. Use when writing unit tests for components.
---

# Component Testing Skill

This skill covers React component testing patterns with Vitest and Testing Library.

## When to Use

Use this skill when:
- Writing unit tests for React components
- Testing user interactions
- Verifying component behavior
- Testing hooks and context

## Core Principle

**TEST USER BEHAVIOR** - Test what users see and do, not implementation details. Your tests should not break when you refactor.

## Setup

### Installation

```bash
npm install -D vitest @testing-library/react @testing-library/jest-dom @testing-library/user-event jsdom
```

### Configuration

```typescript
// vitest.config.ts
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

```typescript
// src/test/setup.ts
import '@testing-library/jest-dom/vitest';
```

## Basic Component Test

```typescript
import { describe, it, expect } from 'vitest';
import { render, screen } from '@testing-library/react';
import { Button } from '../Button';

describe('Button', () => {
  it('renders children correctly', () => {
    render(<Button>Click me</Button>);

    expect(screen.getByRole('button')).toHaveTextContent('Click me');
  });

  it('applies variant class', () => {
    render(<Button variant="primary">Primary</Button>);

    expect(screen.getByRole('button')).toHaveClass('bg-primary');
  });

  it('is disabled when disabled prop is true', () => {
    render(<Button disabled>Disabled</Button>);

    expect(screen.getByRole('button')).toBeDisabled();
  });
});
```

## User Interaction Tests

```typescript
import { describe, it, expect, vi } from 'vitest';
import { render, screen } from '@testing-library/react';
import userEvent from '@testing-library/user-event';
import { Counter } from '../Counter';

describe('Counter', () => {
  it('increments count when button clicked', async () => {
    const user = userEvent.setup();
    render(<Counter />);

    const button = screen.getByRole('button', { name: /increment/i });
    await user.click(button);

    expect(screen.getByText('Count: 1')).toBeInTheDocument();
  });

  it('calls onChange with new count', async () => {
    const user = userEvent.setup();
    const handleChange = vi.fn();
    render(<Counter onChange={handleChange} />);

    await user.click(screen.getByRole('button', { name: /increment/i }));

    expect(handleChange).toHaveBeenCalledWith(1);
  });
});
```

## Form Testing

```typescript
import { describe, it, expect, vi } from 'vitest';
import { render, screen, waitFor } from '@testing-library/react';
import userEvent from '@testing-library/user-event';
import { LoginForm } from '../LoginForm';

describe('LoginForm', () => {
  it('submits form with email and password', async () => {
    const user = userEvent.setup();
    const handleSubmit = vi.fn();
    render(<LoginForm onSubmit={handleSubmit} />);

    await user.type(screen.getByLabelText(/email/i), 'test@example.com');
    await user.type(screen.getByLabelText(/password/i), 'password123');
    await user.click(screen.getByRole('button', { name: /sign in/i }));

    await waitFor(() => {
      expect(handleSubmit).toHaveBeenCalledWith({
        email: 'test@example.com',
        password: 'password123',
      });
    });
  });

  it('shows validation error for invalid email', async () => {
    const user = userEvent.setup();
    render(<LoginForm onSubmit={vi.fn()} />);

    await user.type(screen.getByLabelText(/email/i), 'invalid-email');
    await user.click(screen.getByRole('button', { name: /sign in/i }));

    expect(await screen.findByText(/invalid email/i)).toBeInTheDocument();
  });

  it('disables submit button while loading', async () => {
    render(<LoginForm onSubmit={vi.fn()} isLoading />);

    expect(screen.getByRole('button', { name: /sign in/i })).toBeDisabled();
  });
});
```

## Query Priority

Use queries in this order of preference:

```typescript
// 1. Accessible queries (best)
screen.getByRole('button', { name: /submit/i });
screen.getByRole('textbox', { name: /email/i });
screen.getByRole('heading', { level: 1 });

// 2. Semantic queries
screen.getByLabelText(/email/i);
screen.getByPlaceholderText(/enter email/i);
screen.getByText(/welcome/i);
screen.getByAltText(/profile picture/i);

// 3. Test ID (last resort)
screen.getByTestId('custom-element');
```

## Async Testing

```typescript
import { describe, it, expect, vi } from 'vitest';
import { render, screen, waitFor } from '@testing-library/react';
import { UserProfile } from '../UserProfile';

// Mock fetch
vi.mock('../api', () => ({
  fetchUser: vi.fn(() =>
    Promise.resolve({ id: '1', name: 'John Doe' })
  ),
}));

describe('UserProfile', () => {
  it('displays loading state initially', () => {
    render(<UserProfile userId="1" />);

    expect(screen.getByText(/loading/i)).toBeInTheDocument();
  });

  it('displays user data after loading', async () => {
    render(<UserProfile userId="1" />);

    expect(await screen.findByText('John Doe')).toBeInTheDocument();
    expect(screen.queryByText(/loading/i)).not.toBeInTheDocument();
  });

  it('displays error when fetch fails', async () => {
    const { fetchUser } = await import('../api');
    vi.mocked(fetchUser).mockRejectedValueOnce(new Error('Failed'));

    render(<UserProfile userId="1" />);

    expect(await screen.findByText(/error/i)).toBeInTheDocument();
  });
});
```

## Testing with Context

```typescript
import { describe, it, expect } from 'vitest';
import { render, screen } from '@testing-library/react';
import { ThemeProvider } from '../ThemeContext';
import { ThemedButton } from '../ThemedButton';

function renderWithTheme(ui: React.ReactElement, theme = 'light') {
  return render(
    <ThemeProvider defaultTheme={theme}>
      {ui}
    </ThemeProvider>
  );
}

describe('ThemedButton', () => {
  it('renders with light theme styles', () => {
    renderWithTheme(<ThemedButton>Click</ThemedButton>, 'light');

    expect(screen.getByRole('button')).toHaveClass('bg-white');
  });

  it('renders with dark theme styles', () => {
    renderWithTheme(<ThemedButton>Click</ThemedButton>, 'dark');

    expect(screen.getByRole('button')).toHaveClass('bg-gray-900');
  });
});
```

## Testing Custom Hooks

```typescript
import { describe, it, expect } from 'vitest';
import { renderHook, act } from '@testing-library/react';
import { useCounter } from '../useCounter';

describe('useCounter', () => {
  it('initializes with default value', () => {
    const { result } = renderHook(() => useCounter());

    expect(result.current.count).toBe(0);
  });

  it('initializes with provided value', () => {
    const { result } = renderHook(() => useCounter(10));

    expect(result.current.count).toBe(10);
  });

  it('increments count', () => {
    const { result } = renderHook(() => useCounter());

    act(() => {
      result.current.increment();
    });

    expect(result.current.count).toBe(1);
  });

  it('resets to initial value', () => {
    const { result } = renderHook(() => useCounter(5));

    act(() => {
      result.current.increment();
      result.current.increment();
      result.current.reset();
    });

    expect(result.current.count).toBe(5);
  });
});
```

## Mocking

### Mocking Modules

```typescript
import { vi } from 'vitest';

// Mock entire module
vi.mock('../api');

// Mock with implementation
vi.mock('../utils', () => ({
  formatDate: vi.fn((date) => '2024-01-01'),
}));
```

### Mocking Functions

```typescript
const mockFn = vi.fn();
mockFn.mockReturnValue('default');
mockFn.mockReturnValueOnce('first call');
mockFn.mockResolvedValue({ data: 'async result' });
mockFn.mockRejectedValue(new Error('Failed'));
```

## Test Structure

### File Organization

```
src/
├── components/
│   ├── Button/
│   │   ├── Button.tsx
│   │   ├── index.ts
│   │   └── __tests__/
│   │       └── Button.test.tsx
```

### Test Naming

```typescript
// Use verb-first naming
it('renders children correctly', ...);
it('calls onClick when clicked', ...);
it('throws error for invalid input', ...);
it('displays loading state initially', ...);
```

## Best Practices

1. **Test behavior, not implementation** - Focus on what users experience
2. **Use accessible queries** - getByRole, getByLabelText first
3. **Avoid testing styles** - Test classes/attributes, not computed styles
4. **Keep tests focused** - One behavior per test
5. **Use userEvent over fireEvent** - More realistic interactions
6. **Wait for async operations** - Use findBy, waitFor

## Notes

- Testing Library encourages accessible components
- Avoid snapshot tests for components (too brittle)
- Mock at the boundary (API, not internal functions)
- Tests should give confidence to refactor
