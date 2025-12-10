---
name: accessibility-testing
description: Accessibility testing with axe-core and Playwright. Use when implementing a11y tests.
---

# Accessibility Testing Skill

This skill covers accessibility testing patterns for React applications.

## When to Use

Use this skill when:
- Testing WCAG compliance
- Automating accessibility audits
- Testing keyboard navigation
- Validating screen reader compatibility

## Core Principle

**ACCESSIBLE BY DEFAULT** - Build accessibility into your testing pipeline. Catch issues before they reach users.

## Testing Library + axe-core

### Installation

```bash
npm install -D @testing-library/jest-dom axe-core @axe-core/react vitest-axe
```

### Setup

```typescript
// src/test/setup.ts
import '@testing-library/jest-dom/vitest';
import 'vitest-axe/extend-expect';
```

### Component Accessibility Test

```typescript
import { describe, it, expect } from 'vitest';
import { render } from '@testing-library/react';
import { axe, toHaveNoViolations } from 'vitest-axe';
import { Button } from '../Button';

expect.extend(toHaveNoViolations);

describe('Button accessibility', () => {
  it('has no accessibility violations', async () => {
    const { container } = render(<Button>Click me</Button>);

    const results = await axe(container);

    expect(results).toHaveNoViolations();
  });

  it('is accessible when disabled', async () => {
    const { container } = render(<Button disabled>Disabled</Button>);

    const results = await axe(container);

    expect(results).toHaveNoViolations();
  });

  it('is accessible with icon', async () => {
    const { container } = render(
      <Button aria-label="Add item">
        <PlusIcon />
      </Button>
    );

    const results = await axe(container);

    expect(results).toHaveNoViolations();
  });
});
```

### Form Accessibility Test

```typescript
import { describe, it, expect } from 'vitest';
import { render, screen } from '@testing-library/react';
import userEvent from '@testing-library/user-event';
import { axe, toHaveNoViolations } from 'vitest-axe';
import { LoginForm } from '../LoginForm';

expect.extend(toHaveNoViolations);

describe('LoginForm accessibility', () => {
  it('has no accessibility violations', async () => {
    const { container } = render(<LoginForm onSubmit={vi.fn()} />);

    const results = await axe(container);

    expect(results).toHaveNoViolations();
  });

  it('has accessible form labels', () => {
    render(<LoginForm onSubmit={vi.fn()} />);

    expect(screen.getByLabelText(/email/i)).toBeInTheDocument();
    expect(screen.getByLabelText(/password/i)).toBeInTheDocument();
  });

  it('shows accessible error messages', async () => {
    const user = userEvent.setup();
    render(<LoginForm onSubmit={vi.fn()} />);

    await user.click(screen.getByRole('button', { name: /sign in/i }));

    const emailInput = screen.getByLabelText(/email/i);
    expect(emailInput).toHaveAccessibleDescription(/required/i);
  });

  it('manages focus on validation error', async () => {
    const user = userEvent.setup();
    render(<LoginForm onSubmit={vi.fn()} />);

    await user.click(screen.getByRole('button', { name: /sign in/i }));

    expect(screen.getByLabelText(/email/i)).toHaveFocus();
  });
});
```

## Playwright Accessibility Testing

### Installation

```bash
npm install -D @axe-core/playwright
```

### Basic Accessibility Test

```typescript
import { test, expect } from '@playwright/test';
import AxeBuilder from '@axe-core/playwright';

test.describe('Accessibility', () => {
  test('homepage has no violations', async ({ page }) => {
    await page.goto('/');

    const accessibilityScanResults = await new AxeBuilder({ page }).analyze();

    expect(accessibilityScanResults.violations).toEqual([]);
  });

  test('login page has no violations', async ({ page }) => {
    await page.goto('/login');

    const accessibilityScanResults = await new AxeBuilder({ page }).analyze();

    expect(accessibilityScanResults.violations).toEqual([]);
  });
});
```

### WCAG Level Testing

```typescript
test('page meets WCAG 2.1 AA', async ({ page }) => {
  await page.goto('/');

  const accessibilityScanResults = await new AxeBuilder({ page })
    .withTags(['wcag2a', 'wcag2aa', 'wcag21a', 'wcag21aa'])
    .analyze();

  expect(accessibilityScanResults.violations).toEqual([]);
});

test('page meets WCAG 2.1 AAA', async ({ page }) => {
  await page.goto('/');

  const accessibilityScanResults = await new AxeBuilder({ page })
    .withTags(['wcag2a', 'wcag2aa', 'wcag2aaa', 'wcag21a', 'wcag21aa', 'wcag21aaa'])
    .analyze();

  expect(accessibilityScanResults.violations).toEqual([]);
});
```

### Scoped Accessibility Test

```typescript
test('main content is accessible', async ({ page }) => {
  await page.goto('/');

  const accessibilityScanResults = await new AxeBuilder({ page })
    .include('main')
    .analyze();

  expect(accessibilityScanResults.violations).toEqual([]);
});

test('modal is accessible', async ({ page }) => {
  await page.goto('/');
  await page.click('button[aria-label="Open settings"]');

  const accessibilityScanResults = await new AxeBuilder({ page })
    .include('[role="dialog"]')
    .analyze();

  expect(accessibilityScanResults.violations).toEqual([]);
});
```

### Excluding Known Issues

```typescript
test('page is accessible (excluding known issues)', async ({ page }) => {
  await page.goto('/');

  const accessibilityScanResults = await new AxeBuilder({ page })
    .exclude('.third-party-widget')
    .disableRules(['color-contrast']) // Temporarily disable if fixing
    .analyze();

  expect(accessibilityScanResults.violations).toEqual([]);
});
```

## Keyboard Navigation Testing

```typescript
test.describe('Keyboard navigation', () => {
  test('can navigate form with keyboard', async ({ page }) => {
    await page.goto('/login');

    // Tab to email input
    await page.keyboard.press('Tab');
    await expect(page.getByLabel('Email')).toBeFocused();

    // Tab to password input
    await page.keyboard.press('Tab');
    await expect(page.getByLabel('Password')).toBeFocused();

    // Tab to submit button
    await page.keyboard.press('Tab');
    await expect(page.getByRole('button', { name: /sign in/i })).toBeFocused();
  });

  test('can navigate menu with arrow keys', async ({ page }) => {
    await page.goto('/');

    // Open menu
    await page.getByRole('button', { name: /menu/i }).click();

    // Navigate with arrow keys
    await page.keyboard.press('ArrowDown');
    await expect(page.getByRole('menuitem', { name: /home/i })).toBeFocused();

    await page.keyboard.press('ArrowDown');
    await expect(page.getByRole('menuitem', { name: /about/i })).toBeFocused();

    // Select with Enter
    await page.keyboard.press('Enter');
    await expect(page).toHaveURL('/about');
  });

  test('escape closes modal', async ({ page }) => {
    await page.goto('/');

    // Open modal
    await page.getByRole('button', { name: /open modal/i }).click();
    await expect(page.getByRole('dialog')).toBeVisible();

    // Close with Escape
    await page.keyboard.press('Escape');
    await expect(page.getByRole('dialog')).not.toBeVisible();
  });

  test('focus is trapped in modal', async ({ page }) => {
    await page.goto('/');

    await page.getByRole('button', { name: /open modal/i }).click();

    const dialog = page.getByRole('dialog');
    const focusableElements = dialog.locator(
      'button, [href], input, select, textarea, [tabindex]:not([tabindex="-1"])'
    );

    const count = await focusableElements.count();

    // Tab through all focusable elements
    for (let i = 0; i < count + 1; i++) {
      await page.keyboard.press('Tab');
    }

    // Focus should wrap back to first element in dialog
    const firstFocusable = focusableElements.first();
    await expect(firstFocusable).toBeFocused();
  });
});
```

## Screen Reader Testing

### ARIA Attributes Test

```typescript
test.describe('ARIA attributes', () => {
  test('buttons have accessible names', async ({ page }) => {
    await page.goto('/');

    const buttons = page.getByRole('button');
    const count = await buttons.count();

    for (let i = 0; i < count; i++) {
      const button = buttons.nth(i);
      const name = await button.getAttribute('aria-label') ||
                   await button.textContent();
      expect(name).toBeTruthy();
    }
  });

  test('images have alt text', async ({ page }) => {
    await page.goto('/');

    const images = page.getByRole('img');
    const count = await images.count();

    for (let i = 0; i < count; i++) {
      const image = images.nth(i);
      const alt = await image.getAttribute('alt');
      expect(alt).toBeTruthy();
    }
  });

  test('form fields have labels', async ({ page }) => {
    await page.goto('/contact');

    const inputs = page.locator('input:not([type="hidden"])');
    const count = await inputs.count();

    for (let i = 0; i < count; i++) {
      const input = inputs.nth(i);
      const id = await input.getAttribute('id');
      const ariaLabel = await input.getAttribute('aria-label');
      const ariaLabelledBy = await input.getAttribute('aria-labelledby');

      const hasLabel = id
        ? await page.locator(`label[for="${id}"]`).count() > 0
        : false;

      expect(hasLabel || ariaLabel || ariaLabelledBy).toBeTruthy();
    }
  });

  test('live regions announce changes', async ({ page }) => {
    await page.goto('/notifications');

    // Check for live region
    const liveRegion = page.locator('[aria-live]');
    await expect(liveRegion).toBeVisible();

    // Trigger notification
    await page.getByRole('button', { name: /show notification/i }).click();

    // Verify content in live region
    await expect(liveRegion).toContainText('Notification');
  });
});
```

## Accessibility Fixture

```typescript
// tests/a11y/fixtures.ts
import { test as base, expect } from '@playwright/test';
import AxeBuilder from '@axe-core/playwright';

interface A11yFixtures {
  makeAxeBuilder: () => AxeBuilder;
}

export const test = base.extend<A11yFixtures>({
  makeAxeBuilder: async ({ page }, use) => {
    const makeAxeBuilder = () =>
      new AxeBuilder({ page })
        .withTags(['wcag2a', 'wcag2aa', 'wcag21a', 'wcag21aa']);

    await use(makeAxeBuilder);
  },
});

export { expect };

// Usage
import { test, expect } from './fixtures';

test('page is accessible', async ({ page, makeAxeBuilder }) => {
  await page.goto('/');

  const accessibilityScanResults = await makeAxeBuilder().analyze();

  expect(accessibilityScanResults.violations).toEqual([]);
});
```

## Custom Matchers

```typescript
// tests/a11y/matchers.ts
import { expect } from '@playwright/test';
import AxeBuilder from '@axe-core/playwright';

expect.extend({
  async toBeAccessible(page) {
    const results = await new AxeBuilder({ page })
      .withTags(['wcag2a', 'wcag2aa'])
      .analyze();

    const pass = results.violations.length === 0;

    if (pass) {
      return {
        message: () => 'expected page to have accessibility violations',
        pass: true,
      };
    }

    const violations = results.violations
      .map((v) => `${v.id}: ${v.description}\n  ${v.nodes.map((n) => n.html).join('\n  ')}`)
      .join('\n\n');

    return {
      message: () => `expected page to be accessible:\n\n${violations}`,
      pass: false,
    };
  },
});

// Usage
test('page is accessible', async ({ page }) => {
  await page.goto('/');
  await expect(page).toBeAccessible();
});
```

## CI Integration

```yaml
# .github/workflows/a11y.yml
name: Accessibility

on: [push, pull_request]

jobs:
  accessibility:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - uses: actions/setup-node@v4
        with:
          node-version: '22'

      - name: Install dependencies
        run: npm ci

      - name: Install Playwright browsers
        run: npx playwright install --with-deps

      - name: Run accessibility tests
        run: npx playwright test tests/a11y/

      - name: Upload report
        uses: actions/upload-artifact@v4
        if: always()
        with:
          name: a11y-report
          path: playwright-report/
```

## Best Practices

1. **Test early** - Run accessibility tests in development
2. **Test all states** - Loading, error, empty, populated
3. **Test interactions** - Keyboard, focus, hover states
4. **Use semantic HTML** - Proper headings, landmarks, lists
5. **Test color contrast** - Especially for text on images
6. **Test with real devices** - Screen readers behave differently

## WCAG Quick Reference

| Level | Common Requirements |
|-------|---------------------|
| A | Alt text, form labels, keyboard access, no seizure triggers |
| AA | Color contrast (4.5:1), resize text, focus visible, skip links |
| AAA | Enhanced contrast (7:1), sign language, extended audio description |

## Notes

- axe-core catches ~57% of accessibility issues
- Manual testing still required for full coverage
- Test with actual assistive technology
- Document known issues and remediation plans
