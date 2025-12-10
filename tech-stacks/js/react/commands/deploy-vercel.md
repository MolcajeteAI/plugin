---
description: Deploy to Vercel
model: haiku
---

# Deploy to Vercel

Deploy the React application to Vercel.

Execute the following workflow:

1. Ensure Vercel CLI is installed:
   ```bash
   npm install -g vercel
   ```

2. Login to Vercel (if not already):
   ```bash
   vercel login
   ```

3. Run quality checks:
   ```bash
   npm run validate
   ```

4. Deploy to preview:
   ```bash
   vercel
   ```

5. Deploy to production:
   ```bash
   vercel --prod
   ```

## Project Configuration

Create `vercel.json` for custom configuration:

```json
{
  "buildCommand": "npm run build",
  "outputDirectory": "dist",
  "framework": "vite",
  "rewrites": [
    { "source": "/(.*)", "destination": "/" }
  ]
}
```

For Next.js (auto-detected):

```json
{
  "framework": "nextjs"
}
```

## Environment Variables

Set environment variables in Vercel:

```bash
# Via CLI
vercel env add VITE_API_URL production
vercel env add DATABASE_URL production

# Or via dashboard
# https://vercel.com/[team]/[project]/settings/environment-variables
```

## GitHub Integration

1. Connect GitHub repository at vercel.com
2. Enable automatic deployments
3. Configure branch deployments:
   - Production: main
   - Preview: all other branches

## Build Settings

For Vite SPA:
- Framework Preset: Vite
- Build Command: `npm run build`
- Output Directory: `dist`
- Install Command: `npm install`

For Next.js:
- Framework Preset: Next.js
- Build Command: `npm run build`
- Output Directory: `.next`

## Custom Domain

```bash
# Add domain
vercel domains add example.com

# Or via dashboard
# https://vercel.com/[team]/[project]/settings/domains
```

## Deployment Checklist

- [ ] All tests pass
- [ ] Build succeeds locally
- [ ] Environment variables set
- [ ] Domain configured (if applicable)
- [ ] Preview deployment verified
- [ ] Production deployment verified

## Rollback

```bash
# List deployments
vercel ls

# Rollback to previous deployment
vercel rollback
```

## CI/CD with GitHub Actions

```yaml
name: Deploy to Vercel

on:
  push:
    branches: [main]

jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Deploy to Vercel
        uses: amondnet/vercel-action@v25
        with:
          vercel-token: ${{ secrets.VERCEL_TOKEN }}
          vercel-org-id: ${{ secrets.VERCEL_ORG_ID }}
          vercel-project-id: ${{ secrets.VERCEL_PROJECT_ID }}
          vercel-args: '--prod'
```

**Notes:**
- Vercel auto-detects framework (Next.js, Vite)
- Serverless Functions for API routes
- Edge Functions for middleware
- Automatic HTTPS and CDN

Reference the **vite-deployment** and **nextjs-deployment** skills.
