---
description: Analyze bundle size and dependencies
model: haiku
---

# Analyze Bundle Size

Analyze the production bundle to identify large dependencies and optimization opportunities.

Execute the following workflow:

1. Detect project type:
   - Check for `next.config.ts` → Next.js project
   - Check for `vite.config.ts` → Vite project

2. Install analysis tools if needed:

   **For Vite:**
   ```bash
   npm install -D rollup-plugin-visualizer
   ```

   **For Next.js:**
   ```bash
   npm install -D @next/bundle-analyzer
   ```

3. Configure analysis:

   **For Vite (vite.config.ts):**
   ```typescript
   import { visualizer } from 'rollup-plugin-visualizer';

   export default defineConfig({
     plugins: [
       react(),
       visualizer({
         filename: 'stats.html',
         open: true,
         gzipSize: true,
         brotliSize: true,
       }),
     ],
   });
   ```

   **For Next.js (next.config.ts):**
   ```typescript
   const withBundleAnalyzer = require('@next/bundle-analyzer')({
     enabled: process.env.ANALYZE === 'true',
   });

   export default withBundleAnalyzer(config);
   ```

4. Run analysis:

   **For Vite:**
   ```bash
   npm run build
   # Opens stats.html automatically
   ```

   **For Next.js:**
   ```bash
   ANALYZE=true npm run build
   ```

5. Generate report showing:
   - Total bundle size (raw and gzipped)
   - Largest dependencies
   - Code splitting effectiveness
   - Potential duplicates

6. Provide optimization recommendations:
   - Large libraries to lazy load
   - Dependencies that could be replaced
   - Code that could be split
   - Tree shaking opportunities

7. Common issues to check:
   - moment.js → Use date-fns or dayjs
   - lodash → Import individual functions
   - Large icon libraries → Import specific icons
   - Unused dependencies → Remove them

**Target Metrics:**
- Initial JS: < 100KB (gzipped)
- Per-route JS: < 50KB (gzipped)
- Total bundle: < 500KB (gzipped)

Reference the **bundle-optimization** skill for detailed optimization patterns.
