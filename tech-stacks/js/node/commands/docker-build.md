---
description: Build optimized Docker image for Node.js application
---

# Build Docker Image

Build an optimized Docker image using multi-stage builds.

Use the Task tool to launch the **deployer** agent with instructions:

1. Check for existing Dockerfile, create if missing

2. Ensure Dockerfile uses multi-stage build pattern:
   - Stage 1: Dependencies
   - Stage 2: Build
   - Stage 3: Production runner

3. Build the image:
   ```bash
   docker build -t app:latest .
   ```

4. Build with specific tag:
   ```bash
   docker build -t app:$(git rev-parse --short HEAD) .
   ```

5. Build with build arguments:
   ```bash
   docker build \
     --build-arg NODE_ENV=production \
     -t app:latest .
   ```

6. Verify image size:
   ```bash
   docker images app:latest
   ```

7. Test the image locally:
   ```bash
   docker run --rm -p 3000:3000 --env-file .env.local app:latest
   ```

8. Check for vulnerabilities:
   ```bash
   docker scout cves app:latest
   ```

9. Verify health check:
   ```bash
   curl http://localhost:3000/health
   ```

**Dockerfile Template:**
```dockerfile
FROM node:22-alpine AS base
RUN apk add --no-cache libc6-compat
WORKDIR /app

FROM base AS deps
COPY package.json package-lock.json ./
RUN npm ci --only=production

FROM base AS build
COPY package.json package-lock.json ./
RUN npm ci
COPY . .
RUN npm run build

FROM base AS runner
ENV NODE_ENV=production
RUN addgroup --system --gid 1001 nodejs
RUN adduser --system --uid 1001 nodejs

COPY --from=deps /app/node_modules ./node_modules
COPY --from=build /app/dist ./dist
COPY --from=build /app/package.json ./

USER nodejs
EXPOSE 3000
ENV PORT=3000

HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
  CMD wget --no-verbose --tries=1 --spider http://localhost:3000/health || exit 1

CMD ["node", "dist/index.js"]
```

**Quality Requirements:**
- Multi-stage build for minimal image size
- Non-root user in production stage
- Health check configured
- No development dependencies in final image

Reference the **docker-backend-patterns** skill.
