---
description: Run Playwright E2E tests
model: haiku
---

# Run Playwright E2E Tests

Run end-to-end tests using Playwright.

Execute the following workflow:

1. Ensure Playwright is installed:
   ```bash
   npx playwright install
   ```

2. Run all E2E tests:
   ```bash
   npx playwright test
   ```

3. Run with UI mode (interactive):
   ```bash
   npx playwright test --ui
   ```

4. Run specific test file:
   ```bash
   npx playwright test tests/e2e/auth.spec.ts
   ```

5. Run tests in headed mode (visible browser):
   ```bash
   npx playwright test --headed
   ```

6. Run in specific browser:
   ```bash
   npx playwright test --project=chromium
   npx playwright test --project=firefox
   npx playwright test --project=webkit
   ```

7. Debug a specific test:
   ```bash
   npx playwright test --debug tests/e2e/auth.spec.ts
   ```

8. Show test report:
   ```bash
   npx playwright show-report
   ```

## Test File Convention

E2E tests should be in `tests/e2e/`:

```
tests/
├── e2e/
│   ├── pages/           # Page Objects
│   │   ├── LoginPage.ts
│   │   └── DashboardPage.ts
│   ├── auth.spec.ts
│   ├── dashboard.spec.ts
│   └── visual.spec.ts
└── playwright.config.ts
```

## Test Structure Template

```typescript
import { test, expect } from '@playwright/test';

test.describe('Authentication', () => {
  test('logs in successfully', async ({ page }) => {
    await page.goto('/login');

    await page.getByLabel('Email').fill('user@example.com');
    await page.getByLabel('Password').fill('password123');
    await page.getByRole('button', { name: 'Sign in' }).click();

    await expect(page).toHaveURL('/dashboard');
    await expect(page.getByRole('heading', { name: 'Dashboard' })).toBeVisible();
  });

  test('shows error with invalid credentials', async ({ page }) => {
    await page.goto('/login');

    await page.getByLabel('Email').fill('user@example.com');
    await page.getByLabel('Password').fill('wrongpassword');
    await page.getByRole('button', { name: 'Sign in' }).click();

    await expect(page.getByRole('alert')).toContainText('Invalid credentials');
  });
});
```

## Configuration (playwright.config.ts)

```typescript
import { defineConfig, devices } from '@playwright/test';

export default defineConfig({
  testDir: './tests/e2e',
  fullyParallel: true,
  forbidOnly: !!process.env.CI,
  retries: process.env.CI ? 2 : 0,
  workers: process.env.CI ? 1 : undefined,
  reporter: 'html',
  use: {
    baseURL: 'http://localhost:3000',
    trace: 'on-first-retry',
  },
  projects: [
    { name: 'chromium', use: { ...devices['Desktop Chrome'] } },
    { name: 'firefox', use: { ...devices['Desktop Firefox'] } },
    { name: 'webkit', use: { ...devices['Desktop Safari'] } },
  ],
  webServer: {
    command: 'npm run dev',
    url: 'http://localhost:3000',
    reuseExistingServer: !process.env.CI,
  },
});
```

**Notes:**
- Use stable selectors (role, label, testid)
- Avoid hard-coded waits
- Keep tests independent
- Run in parallel for speed

Reference the **playwright-setup** skill for detailed patterns.
