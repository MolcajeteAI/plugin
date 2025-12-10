---
description: Build Next.js app for production
model: haiku
---

# Build Next.js App

Build the Next.js application for production deployment.

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
   - Lint with configured linter
   - Generate optimized production build
   - Create `.next/` directory
   - Static export if configured

4. Build output:
   ```
   .next/
   ├── cache/
   ├── server/
   │   ├── app/
   │   └── pages/
   ├── static/
   │   ├── chunks/
   │   └── css/
   └── BUILD_ID
   ```

5. Start production server:
   ```bash
   npm run start
   ```

6. For static export (if applicable):
   ```bash
   npm run build
   # Output: out/
   ```

## Build Configuration

```typescript
// next.config.ts
import type { NextConfig } from 'next';

const config: NextConfig = {
  reactStrictMode: true,
  typescript: {
    ignoreBuildErrors: false, // NEVER ignore
  },
  eslint: {
    ignoreDuringBuilds: false, // NEVER ignore
  },
  output: 'standalone', // For Docker deployments
  images: {
    remotePatterns: [
      {
        protocol: 'https',
        hostname: 'example.com',
      },
    ],
  },
};

export default config;
```

## Static Export Configuration

```typescript
// next.config.ts
const config: NextConfig = {
  output: 'export',
  images: {
    unoptimized: true, // Required for static export
  },
  trailingSlash: true,
};
```

## Build Analysis

Enable bundle analysis:

```bash
ANALYZE=true npm run build
```

## Environment Variables

```bash
# .env.production
NEXT_PUBLIC_API_URL=https://api.production.com
DATABASE_URL=postgresql://...
```

## CI/CD Integration

```yaml
# GitHub Actions
- name: Build
  run: npm run build
  env:
    DATABASE_URL: ${{ secrets.DATABASE_URL }}
    NEXT_PUBLIC_API_URL: ${{ secrets.API_URL }}

- name: Upload build
  uses: actions/upload-artifact@v4
  with:
    name: nextjs-build
    path: .next/
```

## Standalone Build (for Docker)

With `output: 'standalone'`:

```dockerfile
FROM node:22-alpine AS runner
WORKDIR /app

COPY --from=builder /app/.next/standalone ./
COPY --from=builder /app/.next/static ./.next/static
COPY --from=builder /app/public ./public

ENV NODE_ENV=production
EXPOSE 3000
CMD ["node", "server.js"]
```

**Quality Requirements:**
- Zero TypeScript errors
- Zero linter warnings
- All tests pass
- Build succeeds without errors

Reference the **nextjs-configuration** and **nextjs-deployment** skills.
