---
description: Deploy to Netlify
model: haiku
---

# Deploy to Netlify

Deploy the React application to Netlify.

Execute the following workflow:

1. Ensure Netlify CLI is installed:
   ```bash
   npm install -g netlify-cli
   ```

2. Login to Netlify:
   ```bash
   netlify login
   ```

3. Run quality checks:
   ```bash
   npm run validate
   ```

4. Build the project:
   ```bash
   npm run build
   ```

5. Deploy to preview:
   ```bash
   netlify deploy
   ```

6. Deploy to production:
   ```bash
   netlify deploy --prod
   ```

## Project Configuration

Create `netlify.toml`:

```toml
[build]
  command = "npm run build"
  publish = "dist"

# For SPA routing
[[redirects]]
  from = "/*"
  to = "/index.html"
  status = 200

# Environment variables
[build.environment]
  NODE_VERSION = "22"

# Headers
[[headers]]
  for = "/*"
  [headers.values]
    X-Frame-Options = "DENY"
    X-Content-Type-Options = "nosniff"

# Cache static assets
[[headers]]
  for = "/assets/*"
  [headers.values]
    Cache-Control = "public, max-age=31536000, immutable"
```

For Next.js:

```toml
[build]
  command = "npm run build"
  publish = ".next"

[[plugins]]
  package = "@netlify/plugin-nextjs"
```

## Environment Variables

Set via CLI:

```bash
netlify env:set VITE_API_URL "https://api.production.com"
netlify env:set DATABASE_URL "postgresql://..."
```

Or via dashboard at https://app.netlify.com/sites/[site]/settings/env

## GitHub Integration

1. Go to https://app.netlify.com
2. Click "Add new site" > "Import an existing project"
3. Connect GitHub repository
4. Configure build settings
5. Deploy

## Build Settings (via UI)

For Vite SPA:
- Build command: `npm run build`
- Publish directory: `dist`

For Next.js:
- Build command: `npm run build`
- Publish directory: `.next`
- Add Next.js plugin

## Functions (Serverless)

Create serverless functions in `netlify/functions/`:

```typescript
// netlify/functions/hello.ts
import type { Handler } from '@netlify/functions';

export const handler: Handler = async (event, context) => {
  return {
    statusCode: 200,
    body: JSON.stringify({ message: 'Hello from Netlify!' }),
  };
};
```

## Custom Domain

```bash
# Add domain
netlify domains:add example.com
```

Or via dashboard: Sites > Domain settings > Add custom domain

## Deployment Checklist

- [ ] All tests pass
- [ ] Build succeeds locally
- [ ] netlify.toml configured
- [ ] Environment variables set
- [ ] Preview deployment verified
- [ ] Production deployment verified

## Rollback

Via dashboard: Deploys > Select previous deploy > Publish deploy

## CI/CD with GitHub Actions

```yaml
name: Deploy to Netlify

on:
  push:
    branches: [main]

jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Setup Node
        uses: actions/setup-node@v4
        with:
          node-version: '22'

      - name: Install dependencies
        run: npm ci

      - name: Build
        run: npm run build

      - name: Deploy to Netlify
        uses: nwtgck/actions-netlify@v3
        with:
          publish-dir: './dist'
          production-deploy: true
        env:
          NETLIFY_AUTH_TOKEN: ${{ secrets.NETLIFY_AUTH_TOKEN }}
          NETLIFY_SITE_ID: ${{ secrets.NETLIFY_SITE_ID }}
```

**Notes:**
- Automatic HTTPS
- Global CDN
- Deploy previews for PRs
- Serverless functions
- Edge functions

Reference the **vite-deployment** skill.
