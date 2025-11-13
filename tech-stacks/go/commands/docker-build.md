---
description: Build optimized Docker image
---

# Build Docker Image

Create an optimized Docker image for the application.

Use the Task tool to launch the **deployer** agent with instructions:

1. Check if Dockerfile exists
2. If not, create multi-stage Dockerfile:
   - Build stage: golang:alpine
   - Runtime stage: alpine or distroless
3. Optimize for size (CGO_ENABLED=0, static binary)
4. Build Docker image: `docker build -t app:latest .`
5. Show image size
6. Test container locally: `docker run app:latest`
7. Suggest improvements if needed

**Best Practices:**
- Multi-stage builds
- Static binaries (CGO_ENABLED=0)
- Small base images (Alpine/distroless)
- Layer caching
- Health checks

Reference the docker-patterns skill.
