---
description: Analyze React Native bundle size
---

# Analyze Bundle Size

Analyze the bundle size and identify optimization opportunities.

Use the Task tool to launch the **performance-optimizer** agent with instructions:

1. Check for bundle analysis tools:
   ```bash
   npm list react-native-bundle-visualizer
   ```

2. If not installed:
   ```bash
   npm install --save-dev react-native-bundle-visualizer
   ```

3. Run bundle analysis:
   ```bash
   npx react-native-bundle-visualizer
   ```

4. Alternative: Use Metro bundler stats:
   ```bash
   npx expo export --dump-sourcemap
   ```

5. Analyze the bundle:
   - Identify large dependencies
   - Find duplicate packages
   - Spot unused code

6. Provide optimization recommendations:
   - Large packages that could be replaced
   - Code splitting opportunities
   - Lazy loading suggestions
   - Tree-shaking improvements

7. Check for common issues:
   - Moment.js (suggest date-fns or dayjs)
   - Lodash (suggest individual imports or lodash-es)
   - Large icon libraries (suggest selective imports)

8. Report findings:
   - Total bundle size
   - Size by module
   - Recommendations with estimated savings

Reference the **react-native-performance** skill.
