---
description: Run visual regression tests
model: haiku
---

# Run Visual Regression Tests

Run visual regression tests to catch unintended UI changes.

Execute the following workflow:

1. Run visual regression tests with Playwright:
   ```bash
   npx playwright test --grep "@visual"
   ```

2. Update snapshots when intentional changes are made:
   ```bash
   npx playwright test --update-snapshots
   ```

3. Run visual tests for specific component:
   ```bash
   npx playwright test visual.spec.ts --grep "Button"
   ```

## Visual Test Structure

```typescript
import { test, expect } from '@playwright/test';

test.describe('Visual Regression @visual', () => {
  test('home page matches snapshot', async ({ page }) => {
    await page.goto('/');

    await expect(page).toHaveScreenshot('home-page.png', {
      fullPage: true,
      maxDiffPixelRatio: 0.01,
    });
  });

  test('button variants match snapshots', async ({ page }) => {
    await page.goto('/storybook/button');

    const primaryButton = page.getByTestId('button-primary');
    await expect(primaryButton).toHaveScreenshot('button-primary.png');

    const secondaryButton = page.getByTestId('button-secondary');
    await expect(secondaryButton).toHaveScreenshot('button-secondary.png');
  });

  test('responsive layouts match snapshots', async ({ page }) => {
    await page.goto('/');

    // Mobile
    await page.setViewportSize({ width: 375, height: 667 });
    await expect(page).toHaveScreenshot('home-mobile.png');

    // Tablet
    await page.setViewportSize({ width: 768, height: 1024 });
    await expect(page).toHaveScreenshot('home-tablet.png');

    // Desktop
    await page.setViewportSize({ width: 1920, height: 1080 });
    await expect(page).toHaveScreenshot('home-desktop.png');
  });
});
```

## Configuration

Add to `playwright.config.ts`:

```typescript
export default defineConfig({
  expect: {
    toHaveScreenshot: {
      maxDiffPixelRatio: 0.01,
      threshold: 0.2,
    },
  },
  // Create separate project for visual tests
  projects: [
    {
      name: 'visual',
      testMatch: '**/visual*.spec.ts',
      use: { ...devices['Desktop Chrome'] },
    },
  ],
});
```

## Snapshot Storage

Snapshots are stored in:
```
tests/
├── e2e/
│   ├── visual.spec.ts
│   └── visual.spec.ts-snapshots/
│       ├── home-page-chromium-linux.png
│       ├── home-mobile-chromium-linux.png
│       └── ...
```

## Best Practices

1. **Stable selectors** - Use data-testid for visual test targets
2. **Wait for animations** - Ensure animations complete before screenshot
3. **Consistent state** - Reset state between tests
4. **Environment consistency** - Same fonts, icons across environments
5. **Threshold tuning** - Adjust pixel ratio for anti-aliasing differences

## Handling Flaky Tests

```typescript
// Wait for fonts to load
await page.waitForLoadState('networkidle');

// Wait for animations
await page.waitForTimeout(500);

// Hide dynamic content
await page.evaluate(() => {
  document.querySelectorAll('[data-dynamic]').forEach((el) => {
    el.style.visibility = 'hidden';
  });
});
```

**Notes:**
- Commit baseline snapshots to git
- Review snapshot changes in PRs
- Run visual tests in CI with consistent environment

Reference the **visual-regression** skill for detailed patterns.
