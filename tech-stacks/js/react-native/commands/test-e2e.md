---
description: Run Maestro E2E tests for React Native app
---

# Run Maestro E2E Tests

Run end-to-end tests using Maestro.

Use the Task tool to launch the **e2e-tester** agent with instructions:

1. Check if Maestro is installed:
   ```bash
   maestro -v
   ```

2. If not installed, guide user to install:
   ```bash
   # macOS/Linux
   curl -Ls "https://get.maestro.mobile.dev" | bash

   # Windows
   # Download from https://maestro.mobile.dev
   ```

3. Find Maestro test files:
   ```bash
   find __tests__/e2e -name "*.yaml"
   ```

4. Ask user for test options using AskUserQuestion:
   - Platform (iOS, Android)
   - Run all tests or specific flow
   - Generate report

5. Run tests on selected platform:
   ```bash
   # iOS Simulator
   maestro test __tests__/e2e/

   # Android Emulator
   maestro test __tests__/e2e/ --platform android
   ```

6. Generate report if requested:
   ```bash
   maestro test __tests__/e2e/ --format junit --output test-results/
   ```

7. Analyze results and provide feedback

Reference the **maestro-testing** skill.
