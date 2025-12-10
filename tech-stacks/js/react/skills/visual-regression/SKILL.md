---
name: visual-regression
description: Visual regression testing with Playwright and Percy. Use when implementing screenshot-based testing.
---

# Visual Regression Testing Skill

This skill covers visual regression testing patterns for React applications.

## When to Use

Use this skill when:
- Catching unintended visual changes
- Testing component appearance across browsers
- Validating responsive layouts
- Maintaining design consistency

## Core Principle

**CATCH VISUAL BUGS** - Visual regression tests detect unintended changes to UI appearance that functional tests miss.

## Playwright Visual Testing

### Setup

```typescript
// playwright.config.ts
import { defineConfig } from '@playwright/test';

export default defineConfig({
  testDir: './tests/visual',
  snapshotDir: './tests/visual/__snapshots__',
  updateSnapshots: 'missing',
  expect: {
    toHaveScreenshot: {
      maxDiffPixels: 100,
      threshold: 0.2,
    },
  },
  projects: [
    {
      name: 'Desktop Chrome',
      use: {
        browserName: 'chromium',
        viewport: { width: 1280, height: 720 },
      },
    },
    {
      name: 'Mobile Safari',
      use: {
        browserName: 'webkit',
        viewport: { width: 375, height: 667 },
      },
    },
  ],
});
```

### Basic Screenshot Test

```typescript
import { test, expect } from '@playwright/test';

test.describe('Visual Regression', () => {
  test('homepage matches snapshot', async ({ page }) => {
    await page.goto('/');
    await page.waitForLoadState('networkidle');

    await expect(page).toHaveScreenshot('homepage.png');
  });

  test('dashboard matches snapshot', async ({ page }) => {
    await page.goto('/dashboard');
    await page.waitForLoadState('networkidle');

    await expect(page).toHaveScreenshot('dashboard.png');
  });
});
```

### Component Screenshot

```typescript
test('button component variants', async ({ page }) => {
  await page.goto('/storybook/button');

  // Screenshot specific element
  const button = page.getByRole('button', { name: 'Primary' });
  await expect(button).toHaveScreenshot('button-primary.png');

  // Screenshot component container
  const container = page.locator('[data-testid="button-variants"]');
  await expect(container).toHaveScreenshot('button-variants.png');
});
```

### Handling Dynamic Content

```typescript
test('page with dynamic content', async ({ page }) => {
  await page.goto('/profile');

  // Mask dynamic elements
  await expect(page).toHaveScreenshot('profile.png', {
    mask: [
      page.locator('[data-testid="timestamp"]'),
      page.locator('[data-testid="avatar"]'),
      page.locator('.dynamic-ad'),
    ],
  });
});

test('page with animations', async ({ page }) => {
  await page.goto('/animated-page');

  // Disable animations
  await page.emulateMedia({ reducedMotion: 'reduce' });

  // Or wait for animations to complete
  await page.waitForFunction(() => {
    const animations = document.getAnimations();
    return animations.every((a) => a.playState === 'finished');
  });

  await expect(page).toHaveScreenshot('animated-page.png');
});
```

### Responsive Screenshots

```typescript
const viewports = [
  { width: 375, height: 667, name: 'mobile' },
  { width: 768, height: 1024, name: 'tablet' },
  { width: 1280, height: 720, name: 'desktop' },
  { width: 1920, height: 1080, name: 'wide' },
];

test.describe('Responsive layouts', () => {
  for (const viewport of viewports) {
    test(`homepage at ${viewport.name}`, async ({ page }) => {
      await page.setViewportSize({ width: viewport.width, height: viewport.height });
      await page.goto('/');
      await page.waitForLoadState('networkidle');

      await expect(page).toHaveScreenshot(`homepage-${viewport.name}.png`);
    });
  }
});
```

### Full Page Screenshots

```typescript
test('full page screenshot', async ({ page }) => {
  await page.goto('/long-page');
  await page.waitForLoadState('networkidle');

  await expect(page).toHaveScreenshot('long-page-full.png', {
    fullPage: true,
  });
});
```

## Percy Integration

### Installation

```bash
npm install -D @percy/cli @percy/playwright
```

### Configuration

```yaml
# .percy.yml
version: 2
snapshot:
  widths:
    - 375
    - 768
    - 1280
  minHeight: 1024
  percyCSS: |
    .hide-in-percy {
      visibility: hidden;
    }
discovery:
  allowedHostnames:
    - localhost
    - cdn.example.com
```

### Percy Tests

```typescript
import { test } from '@playwright/test';
import percySnapshot from '@percy/playwright';

test.describe('Percy Visual Tests', () => {
  test('homepage', async ({ page }) => {
    await page.goto('/');
    await page.waitForLoadState('networkidle');

    await percySnapshot(page, 'Homepage');
  });

  test('dashboard states', async ({ page }) => {
    await page.goto('/dashboard');

    // Empty state
    await percySnapshot(page, 'Dashboard - Empty');

    // With data
    await page.evaluate(() => {
      // Inject mock data
    });
    await percySnapshot(page, 'Dashboard - With Data');

    // Loading state
    await page.evaluate(() => {
      document.body.classList.add('loading');
    });
    await percySnapshot(page, 'Dashboard - Loading');
  });
});
```

### Percy with Storybook

```bash
npm install -D @percy/storybook
```

```javascript
// .storybook/main.js
module.exports = {
  addons: ['@percy/storybook'],
};
```

```bash
# Run Percy on Storybook
npx percy storybook ./storybook-static
```

## Component Visual Testing

### Storybook Integration

```typescript
// Button.stories.tsx
import type { Meta, StoryObj } from '@storybook/react';
import { Button } from './Button';

const meta: Meta<typeof Button> = {
  title: 'Components/Button',
  component: Button,
  parameters: {
    chromatic: { disableSnapshot: false },
  },
};

export default meta;
type Story = StoryObj<typeof Button>;

export const AllVariants: Story = {
  render: () => (
    <div className="flex flex-col gap-4">
      <div className="flex gap-2">
        <Button variant="default">Default</Button>
        <Button variant="secondary">Secondary</Button>
        <Button variant="destructive">Destructive</Button>
        <Button variant="outline">Outline</Button>
        <Button variant="ghost">Ghost</Button>
      </div>
      <div className="flex gap-2">
        <Button size="sm">Small</Button>
        <Button size="default">Default</Button>
        <Button size="lg">Large</Button>
      </div>
      <div className="flex gap-2">
        <Button disabled>Disabled</Button>
        <Button isLoading>Loading</Button>
      </div>
    </div>
  ),
};

// Interaction states for visual testing
export const HoverState: Story = {
  args: { children: 'Hover Me' },
  parameters: {
    pseudo: { hover: true },
  },
};

export const FocusState: Story = {
  args: { children: 'Focus Me' },
  parameters: {
    pseudo: { focus: true },
  },
};
```

### Visual Test Fixture

```typescript
// tests/visual/fixtures.ts
import { test as base } from '@playwright/test';

interface VisualTestFixtures {
  visualPage: typeof page;
}

export const test = base.extend<VisualTestFixtures>({
  visualPage: async ({ page }, use) => {
    // Disable animations globally
    await page.addStyleTag({
      content: `
        *, *::before, *::after {
          animation-duration: 0s !important;
          animation-delay: 0s !important;
          transition-duration: 0s !important;
          transition-delay: 0s !important;
        }
      `,
    });

    // Set consistent date/time
    await page.addInitScript(() => {
      const fixedDate = new Date('2024-01-15T10:00:00Z');
      // @ts-ignore
      Date = class extends Date {
        constructor(...args: []) {
          if (args.length === 0) {
            super(fixedDate);
          } else {
            // @ts-ignore
            super(...args);
          }
        }
        static now() {
          return fixedDate.getTime();
        }
      };
    });

    await use(page);
  },
});

export { expect } from '@playwright/test';
```

## Dark Mode Testing

```typescript
test.describe('Dark mode visual tests', () => {
  test('homepage in light mode', async ({ page }) => {
    await page.goto('/');
    await expect(page).toHaveScreenshot('homepage-light.png');
  });

  test('homepage in dark mode', async ({ page }) => {
    await page.goto('/');

    // Enable dark mode
    await page.evaluate(() => {
      document.documentElement.classList.add('dark');
    });

    await expect(page).toHaveScreenshot('homepage-dark.png');
  });

  test('component in both modes', async ({ page }) => {
    await page.goto('/components/card');

    const card = page.locator('[data-testid="card"]');

    // Light mode
    await expect(card).toHaveScreenshot('card-light.png');

    // Dark mode
    await page.evaluate(() => {
      document.documentElement.classList.add('dark');
    });
    await expect(card).toHaveScreenshot('card-dark.png');
  });
});
```

## CI Integration

### GitHub Actions

```yaml
# .github/workflows/visual.yml
name: Visual Regression

on: [push, pull_request]

jobs:
  visual-tests:
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

      - name: Run visual tests
        run: npx playwright test tests/visual/

      - name: Upload snapshots
        uses: actions/upload-artifact@v4
        if: failure()
        with:
          name: visual-snapshots
          path: |
            tests/visual/__snapshots__/
            test-results/
```

### Percy CI

```yaml
# .github/workflows/percy.yml
name: Percy

on: [push, pull_request]

jobs:
  percy:
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

      - name: Percy snapshot
        run: npx percy exec -- npx playwright test tests/visual/
        env:
          PERCY_TOKEN: ${{ secrets.PERCY_TOKEN }}
```

## Commands

```bash
# Run visual tests
npx playwright test tests/visual/

# Update snapshots
npx playwright test tests/visual/ --update-snapshots

# Run specific visual test
npx playwright test tests/visual/homepage.spec.ts

# Run with Percy
npx percy exec -- npx playwright test tests/visual/

# View report
npx playwright show-report
```

## Best Practices

1. **Stable selectors** - Use data-testid for visual test targets
2. **Mask dynamic content** - Hide timestamps, ads, avatars
3. **Disable animations** - Prevent flaky screenshots
4. **Test critical paths** - Focus on key user journeys
5. **Review changes** - Don't auto-approve snapshot updates
6. **Version snapshots** - Commit snapshots to git

## Notes

- Visual tests are slower than unit tests
- Run on CI with consistent environment
- Use threshold for minor rendering differences
- Percy provides cross-browser comparison
