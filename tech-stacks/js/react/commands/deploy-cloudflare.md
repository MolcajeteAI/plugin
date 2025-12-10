---
description: Deploy to Cloudflare Pages
model: haiku
---

# Deploy to Cloudflare Pages

Deploy the React application to Cloudflare Pages.

Execute the following workflow:

1. Ensure Wrangler CLI is installed:
   ```bash
   npm install -g wrangler
   ```

2. Login to Cloudflare:
   ```bash
   wrangler login
   ```

3. Run quality checks:
   ```bash
   npm run validate
   ```

4. Build the project:
   ```bash
   npm run build
   ```

5. Create Pages project (first time):
   ```bash
   wrangler pages project create my-app
   ```

6. Deploy:
   ```bash
   wrangler pages deploy dist
   ```

## Project Configuration

Create `wrangler.toml`:

```toml
name = "my-react-app"
compatibility_date = "2024-01-01"
pages_build_output_dir = "dist"

[build]
command = "npm run build"

# Environment variables
[vars]
VITE_API_URL = "https://api.production.com"
```

## GitHub Integration

1. Go to https://dash.cloudflare.com
2. Select Workers & Pages
3. Create application > Pages > Connect to Git
4. Select repository
5. Configure build settings:
   - Framework preset: Vite
   - Build command: `npm run build`
   - Build output directory: `dist`

For Next.js:
- Framework preset: Next.js
- Build command: `npm run build`
- Build output directory: `.next`

## Environment Variables

```bash
# Via Wrangler
wrangler pages secret put API_KEY
```

Or via dashboard: Workers & Pages > [Project] > Settings > Environment variables

## Functions (Edge)

Create edge functions in `functions/`:

```typescript
// functions/api/hello.ts
export async function onRequest(context: EventContext<unknown, string, unknown>) {
  return new Response(JSON.stringify({ message: 'Hello from the edge!' }), {
    headers: { 'Content-Type': 'application/json' },
  });
}
```

## Custom Domain

```bash
# Via dashboard
# Workers & Pages > [Project] > Custom domains > Add
```

## SPA Routing

Create `_routes.json` in `public/`:

```json
{
  "version": 1,
  "include": ["/*"],
  "exclude": ["/assets/*"]
}
```

Or create `functions/_middleware.ts`:

```typescript
export async function onRequest(context: EventContext<unknown, string, unknown>) {
  try {
    return await context.next();
  } catch {
    return context.env.ASSETS.fetch(new Request(`${context.request.url.split('/')[0]}/index.html`));
  }
}
```

## Headers Configuration

Create `_headers` in `public/`:

```
/*
  X-Frame-Options: DENY
  X-Content-Type-Options: nosniff

/assets/*
  Cache-Control: public, max-age=31536000, immutable
```

## Deployment Checklist

- [ ] All tests pass
- [ ] Build succeeds locally
- [ ] wrangler.toml configured
- [ ] Environment variables set
- [ ] Custom domain configured (optional)
- [ ] Preview deployment verified
- [ ] Production deployment verified

## Rollback

Via dashboard: Workers & Pages > [Project] > Deployments > Roll back to this deployment

## CI/CD with GitHub Actions

```yaml
name: Deploy to Cloudflare Pages

on:
  push:
    branches: [main]

jobs:
  deploy:
    runs-on: ubuntu-latest
    permissions:
      contents: read
      deployments: write
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

      - name: Deploy to Cloudflare Pages
        uses: cloudflare/pages-action@v1
        with:
          apiToken: ${{ secrets.CLOUDFLARE_API_TOKEN }}
          accountId: ${{ secrets.CLOUDFLARE_ACCOUNT_ID }}
          projectName: my-react-app
          directory: dist
          gitHubToken: ${{ secrets.GITHUB_TOKEN }}
```

**Notes:**
- Global edge network (300+ locations)
- Automatic HTTPS
- Unlimited bandwidth (free tier)
- Workers integration
- Web Analytics built-in

Reference the **vite-deployment** skill.
