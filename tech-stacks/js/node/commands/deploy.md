---
description: Deploy to cloud platform (Vercel, Railway, Fly.io, etc.)
---

# Deploy to Platform

Deploy the application to a cloud platform.

Use the Task tool to launch the **deployer** agent with instructions:

1. Ask user for deployment target using AskUserQuestion tool:
   - Railway (recommended for full-stack)
   - Fly.io (recommended for containers)
   - Vercel (recommended for serverless)
   - Render
   - AWS Lambda
   - Google Cloud Run
   - DigitalOcean App Platform

2. Run pre-deployment checks:
   ```bash
   npm run type-check
   npm run lint
   npm run test
   npm run build
   ```

3. Based on platform, follow deployment steps:

## Railway Deployment

```bash
# Install Railway CLI
npm install -g @railway/cli

# Login
railway login

# Link project
railway link

# Deploy
railway up
```

Configuration (railway.toml):
```toml
[build]
builder = "dockerfile"
dockerfilePath = "Dockerfile"

[deploy]
healthcheckPath = "/health"
healthcheckTimeout = 30
restartPolicyType = "on_failure"
```

## Fly.io Deployment

```bash
# Install Fly CLI
curl -L https://fly.io/install.sh | sh

# Login
fly auth login

# Launch (first time)
fly launch

# Deploy
fly deploy
```

Configuration (fly.toml):
```toml
app = "my-app"
primary_region = "iad"

[build]
dockerfile = "Dockerfile"

[http_service]
internal_port = 3000
force_https = true
```

## Vercel Deployment

```bash
# Install Vercel CLI
npm install -g vercel

# Login
vercel login

# Deploy
vercel --prod
```

Configuration (vercel.json):
```json
{
  "functions": {
    "api/**/*.ts": {
      "memory": 1024,
      "maxDuration": 30
    }
  }
}
```

## Render Deployment

```yaml
# render.yaml
services:
  - type: web
    name: api
    runtime: docker
    dockerfilePath: ./Dockerfile
    healthCheckPath: /health
    envVars:
      - key: DATABASE_URL
        fromDatabase:
          name: db
          property: connectionString
```

4. Set environment variables in platform dashboard

5. Verify deployment:
   ```bash
   curl https://your-app.platform.app/health
   ```

6. Set up monitoring and alerts

**Quality Requirements:**
- All pre-deployment checks pass
- Health check endpoint responds
- Environment variables configured
- SSL/TLS enabled

Reference the **serverless-patterns** and **docker-backend-patterns** skills.
