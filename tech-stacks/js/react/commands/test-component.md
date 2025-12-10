---
description: Test React components with Vitest and Testing Library
model: haiku
---

# Test React Components

Run component tests using Vitest and React Testing Library.

Execute the following workflow:

1. Run component tests:
   ```bash
   npm run test
   ```

2. For watch mode (during development):
   ```bash
   npm run test:watch
   ```

3. For coverage report:
   ```bash
   npm run test:coverage
   ```

4. For interactive UI:
   ```bash
   npm run test:ui
   ```

5. To run specific test file:
   ```bash
   npx vitest run src/components/Button/__tests__/Button.test.tsx
   ```

6. To run tests matching a pattern:
   ```bash
   npx vitest run --grep "Button"
   ```

## Test File Convention

Tests should be placed in `__tests__/` directories:

```
src/components/
├── Button/
│   ├── Button.tsx
│   └── __tests__/
│       └── Button.test.tsx
```

## Test Structure Template

```typescript
import { describe, it, expect, vi } from 'vitest';
import { render, screen, fireEvent } from '@testing-library/react';
import { Button } from '../Button';

describe('Button', () => {
  it('renders children correctly', () => {
    render(<Button>Click me</Button>);

    expect(screen.getByRole('button')).toHaveTextContent('Click me');
  });

  it('calls onClick when clicked', () => {
    const handleClick = vi.fn();
    render(<Button onClick={handleClick}>Click</Button>);

    fireEvent.click(screen.getByRole('button'));

    expect(handleClick).toHaveBeenCalledTimes(1);
  });

  it('is disabled when disabled prop is true', () => {
    render(<Button disabled>Disabled</Button>);

    expect(screen.getByRole('button')).toBeDisabled();
  });
});
```

## Query Priority (Best Practices)

1. `getByRole` - Accessible queries (best)
2. `getByLabelText` - Form inputs
3. `getByPlaceholderText` - Inputs without labels
4. `getByText` - Non-interactive elements
5. `getByTestId` - Last resort

## Coverage Requirements

- Lines: 80% minimum
- Functions: 80% minimum
- Branches: 80% minimum
- Statements: 80% minimum

**Notes:**
- Test behavior, not implementation
- Use verb-first test names: "renders...", "calls...", "throws..."
- Avoid testing implementation details
- Mock external dependencies

Reference the **component-testing** and **testing-patterns** skills.
