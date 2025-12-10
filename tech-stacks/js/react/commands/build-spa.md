---
description: Build Vite SPA for production
model: haiku
---

# Build Vite SPA

Build the Vite SPA for production deployment.

Execute the following workflow:

1. Run quality checks first:
   ```bash
   npm run validate
   ```

2. Build for production:
   ```bash
   npm run build
   ```

3. The build process will:
   - Type-check with TypeScript
   - Bundle with Vite/Rollup
   - Minify and optimize
   - Generate source maps
   - Output to `dist/` directory

4. Build output structure:
   ```
   dist/
   ├── index.html
   ├── assets/
   │   ├── index-[hash].js
   │   ├── index-[hash].css
   │   └── vendor-[hash].js
   └── ...
   ```

5. Preview the build:
   ```bash
   npm run preview
   ```

6. Verify build:
   - Check console for errors
   - Test all routes
   - Verify assets load
   - Check performance

## Build Optimization

The build should include:

```typescript
// vite.config.ts
export default defineConfig({
  build: {
    target: 'ES2022',
    sourcemap: true,
    minify: 'esbuild',
    rollupOptions: {
      output: {
        manualChunks: {
          'vendor-react': ['react', 'react-dom'],
          'vendor-ui': ['@radix-ui/react-dialog', '@radix-ui/react-dropdown-menu'],
        },
      },
    },
  },
});
```

## Build Size Targets

| Metric | Target |
|--------|--------|
| Initial JS | < 100KB (gzipped) |
| Total JS | < 500KB (gzipped) |
| CSS | < 50KB (gzipped) |
| Images | Optimized |

## Environment Variables

Ensure production environment variables are set:

```bash
# .env.production
VITE_API_URL=https://api.production.com
VITE_APP_ENV=production
```

## CI/CD Integration

```yaml
# GitHub Actions
- name: Build
  run: npm run build
  env:
    VITE_API_URL: ${{ secrets.PROD_API_URL }}

- name: Upload artifacts
  uses: actions/upload-artifact@v4
  with:
    name: dist
    path: dist/
```

**Quality Requirements:**
- Zero TypeScript errors
- Zero linter warnings
- All tests pass
- Build succeeds without errors

Reference the **vite-configuration** and **bundle-optimization** skills.
