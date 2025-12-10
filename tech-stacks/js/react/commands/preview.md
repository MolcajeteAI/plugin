---
description: Preview production build locally
model: haiku
---

# Preview Production Build

Preview the production build locally to verify it works correctly before deployment.

Execute the following workflow:

1. Detect project type:
   - Check for `next.config.ts` → Next.js project
   - Check for `vite.config.ts` → Vite project

2. Build the project:

   **For Vite:**
   ```bash
   npm run build
   ```

   **For Next.js:**
   ```bash
   npm run build
   ```

3. Start preview server:

   **For Vite:**
   ```bash
   npm run preview
   ```
   Opens at http://localhost:4173

   **For Next.js:**
   ```bash
   npm run start
   ```
   Opens at http://localhost:3000

4. Display preview URL and instructions:
   - How to test the build
   - Check for console errors
   - Verify all routes work
   - Test on different viewports

5. Remind user to verify:
   - All pages load correctly
   - API routes respond
   - Assets load properly
   - No console errors
   - Performance is acceptable

**Notes:**
- Production build should be tested before deployment
- Check for hydration mismatches in Next.js
- Verify environment variables are set correctly
