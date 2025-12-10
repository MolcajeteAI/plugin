---
description: Run Docker container locally
---

# Run Docker Container

Run the application in a Docker container locally.

Use the Task tool to launch the **deployer** agent with instructions:

1. Check if image exists:
   ```bash
   docker images app:latest
   ```

2. If not, build first:
   ```bash
   docker build -t app:latest .
   ```

3. Run with docker-compose (recommended):
   ```bash
   docker-compose up -d
   ```

4. Or run standalone container:
   ```bash
   docker run -d \
     --name app \
     -p 3000:3000 \
     --env-file .env.local \
     app:latest
   ```

5. Run with database:
   ```bash
   docker run -d \
     --name app \
     -p 3000:3000 \
     --network app-network \
     -e DATABASE_URL=postgresql://postgres:password@db:5432/app \
     app:latest
   ```

6. View logs:
   ```bash
   docker logs -f app
   ```

7. Check health:
   ```bash
   docker inspect --format='{{.State.Health.Status}}' app
   curl http://localhost:3000/health
   ```

8. Stop container:
   ```bash
   docker stop app
   docker rm app
   ```

9. Stop all services:
   ```bash
   docker-compose down
   ```

**docker-compose.yml Template:**
```yaml
version: '3.8'

services:
  api:
    build: .
    ports:
      - "3000:3000"
    environment:
      - DATABASE_URL=postgresql://postgres:password@db:5432/app
      - NODE_ENV=production
    depends_on:
      db:
        condition: service_healthy

  db:
    image: postgres:16-alpine
    environment:
      - POSTGRES_USER=postgres
      - POSTGRES_PASSWORD=password
      - POSTGRES_DB=app
    volumes:
      - postgres_data:/var/lib/postgresql/data
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U postgres"]
      interval: 10s
      timeout: 5s
      retries: 5

volumes:
  postgres_data:
```

**Quality Requirements:**
- Container starts successfully
- Health check passes
- Logs show no errors
- API responds correctly

Reference the **docker-backend-patterns** skill.
