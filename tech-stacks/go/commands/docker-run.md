---
description: Run Docker container
---

# Run Docker Container

Run the Docker container locally for testing.

Use the Task tool to launch the **deployer** agent with instructions:

1. Verify Docker image exists (build if needed)
2. Run container: `docker run -p 8080:8080 app:latest`
3. Test container functionality
4. Show container logs
5. Verify health checks (if configured)
6. Stop container when done

**Docker Run Options:**
- `-p` - Port mapping
- `-e` - Environment variables
- `-v` - Volume mounts
- `--rm` - Remove container after exit
- `-d` - Detached mode

Reference the docker-patterns skill.
