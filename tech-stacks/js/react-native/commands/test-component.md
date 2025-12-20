---
description: Test React Native components with Jest and Testing Library
---

# Test React Native Components

Run unit tests for React Native components using Jest and React Native Testing Library.

Use the Task tool to launch the **component-builder** agent with instructions:

1. Check if testing dependencies are installed:
   ```bash
   npm list jest-expo @testing-library/react-native
   ```

2. If not installed:
   ```bash
   npm install --save-dev jest-expo @testing-library/react-native @testing-library/jest-native
   ```

3. Ask user for test scope using AskUserQuestion:
   - Run all tests
   - Run specific component tests
   - Run with coverage
   - Run in watch mode

4. Run tests based on selection:
   ```bash
   # All tests
   npm test

   # Specific component
   npm test -- Button

   # With coverage
   npm run test:coverage

   # Watch mode
   npm run test:watch
   ```

5. Analyze test results:
   - Report passing/failing tests
   - Show coverage metrics
   - Identify uncovered code paths

6. If tests fail:
   - Analyze failure reasons
   - Suggest fixes

Reference the **component-testing-mobile** skill.
