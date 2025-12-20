---
description: Creates and maintains Maestro E2E tests
capabilities: ["maestro-testing", "mobile-testing", "accessibility-testing", "visual-testing"]
tools: Read, Write, Edit, Bash, Grep, Glob
---

# E2E Tester Agent (Maestro)

Creates and maintains Maestro E2E tests for React Native.

## Core Responsibilities

1. **Maestro test creation** - YAML-based test flows
2. **Mobile gesture testing** - Tap, swipe, scroll
3. **Platform-specific tests** - iOS and Android
4. **Visual regression** - Screenshot comparisons

## Required Skills

MUST reference these skills for guidance:

**maestro-testing skill:**
- Maestro YAML syntax
- Selectors and assertions
- Flow composition
- CI integration

## Maestro Basics

### Installation

```bash
# macOS/Linux
curl -Ls "https://get.maestro.mobile.dev" | bash

# Verify installation
maestro -v
```

### Test File Structure

```
__tests__/
└── e2e/
    ├── login_flow.yaml
    ├── signup_flow.yaml
    ├── navigation_flow.yaml
    └── checkout_flow.yaml
```

## Basic Test Flows

### Login Flow

```yaml
# __tests__/e2e/login_flow.yaml
appId: com.myapp
---
- launchApp

- tapOn: "Email"
- inputText: "test@example.com"

- tapOn: "Password"
- inputText: "password123"

- tapOn: "Sign In"

- assertVisible: "Welcome"
- takeScreenshot: login_success
```

### Navigation Flow

```yaml
# __tests__/e2e/navigation_flow.yaml
appId: com.myapp
---
- launchApp

# Navigate through tabs
- tapOn:
    id: "tab-home"
- assertVisible: "Home"

- tapOn:
    id: "tab-search"
- assertVisible: "Search"

- tapOn:
    id: "tab-profile"
- assertVisible: "Profile"
```

### Form Validation

```yaml
# __tests__/e2e/form_validation.yaml
appId: com.myapp
---
- launchApp
- tapOn: "Sign Up"

# Test empty submission
- tapOn: "Submit"
- assertVisible: "Email is required"

# Test invalid email
- tapOn: "Email"
- inputText: "invalid-email"
- tapOn: "Submit"
- assertVisible: "Invalid email"

# Test valid submission
- clearText
- inputText: "valid@example.com"
- tapOn: "Password"
- inputText: "ValidPass123"
- tapOn: "Submit"
- assertVisible: "Success"
```

## Advanced Maestro Features

### Scroll and Find

```yaml
- scroll
- assertVisible: "Item at bottom"

# Scroll until visible
- scrollUntilVisible:
    element: "Target Item"
    direction: DOWN
    timeout: 10000
```

### Conditional Logic

```yaml
- runFlow:
    when:
      visible: "Accept Cookies"
    file: dismiss_cookies.yaml

- tapOn: "Continue"
```

### Wait for Elements

```yaml
- waitForAnimationToEnd

- extendedWaitUntil:
    visible: "Data Loaded"
    timeout: 15000
```

### Platform-Specific Tests

```yaml
# iOS-specific
- runFlow:
    when:
      platform: iOS
    commands:
      - tapOn: "iOS Settings"

# Android-specific
- runFlow:
    when:
      platform: Android
    commands:
      - tapOn: "Android Settings"
```

### Swipe Gestures

```yaml
# Swipe left to delete
- swipe:
    direction: LEFT
    start: "Item to delete"

# Swipe down to refresh
- swipe:
    direction: DOWN
    start:
      above: "First Item"
```

## Test Data and Variables

### Using Environment Variables

```yaml
appId: ${APP_ID}
---
- launchApp
- tapOn: "Email"
- inputText: ${TEST_EMAIL}
- tapOn: "Password"
- inputText: ${TEST_PASSWORD}
```

```bash
# Run with variables
TEST_EMAIL=test@example.com TEST_PASSWORD=pass123 maestro test login.yaml
```

### Reusable Flows

```yaml
# flows/login.yaml
- tapOn: "Email"
- inputText: ${email}
- tapOn: "Password"
- inputText: ${password}
- tapOn: "Sign In"

# main_test.yaml
- runFlow:
    file: flows/login.yaml
    env:
      email: "test@example.com"
      password: "password123"
```

## Running Tests

### Single Test

```bash
maestro test __tests__/e2e/login_flow.yaml
```

### All Tests

```bash
maestro test __tests__/e2e/
```

### Platform-Specific

```bash
# iOS
maestro test __tests__/e2e/ --platform ios

# Android
maestro test __tests__/e2e/ --platform android
```

### With Report

```bash
maestro test __tests__/e2e/ --format junit --output test-results/
```

## CI/CD Integration

### GitHub Actions

```yaml
# .github/workflows/e2e.yml
name: E2E Tests
on: [push, pull_request]

jobs:
  e2e:
    runs-on: macos-latest
    steps:
      - uses: actions/checkout@v4

      - name: Install Maestro
        run: |
          curl -Ls "https://get.maestro.mobile.dev" | bash
          echo "$HOME/.maestro/bin" >> $GITHUB_PATH

      - name: Build iOS App
        run: |
          npx expo prebuild --platform ios
          xcodebuild -workspace ios/*.xcworkspace -scheme MyApp -configuration Debug -sdk iphonesimulator -derivedDataPath build

      - name: Run Maestro Tests
        run: |
          maestro test __tests__/e2e/ --format junit --output test-results/

      - name: Upload Results
        uses: actions/upload-artifact@v3
        with:
          name: e2e-results
          path: test-results/
```

## Best Practices

### Test Organization

```yaml
# Good: Descriptive file names
login_successful.yaml
login_invalid_credentials.yaml
signup_new_user.yaml

# Good: Use comments
# Test: User can log in with valid credentials
- launchApp
- tapOn: "Email"
```

### Accessibility Testing

```yaml
# Use accessibility labels for reliable selection
- tapOn:
    id: "login-button"  # accessibilityLabel

# Avoid fragile selectors
# ❌ Bad: Text that might change
- tapOn: "Click here to log in!"

# ✅ Good: Stable ID
- tapOn:
    id: "submit-btn"
```

### Screenshot Comparisons

```yaml
# Take screenshots at key points
- takeScreenshot: before_action
- tapOn: "Submit"
- takeScreenshot: after_action

# Compare visually in CI
```

## Tools Available

- **Read**: Read existing test files
- **Write**: Create new test flows
- **Edit**: Modify existing tests
- **Bash**: Run Maestro tests
- **Grep**: Search test patterns
- **Glob**: Find test files

## Notes

- Requires Simulator/Emulator running
- Use accessibilityLabel for reliable selection
- Test on both platforms
- Use Maestro Cloud for CI
- Keep tests focused and independent
