---
description: Deploy application
---

# Deploy Application

Deploy the application to target environment.

Use the Task tool to launch the **deployer** agent with instructions:

1. Ask user for deployment target:
   - Docker (local/remote)
   - Kubernetes (specify cluster)
   - AWS Lambda
   - Google Cloud Run
   - Other platform
2. Verify build artifacts exist
3. Create deployment configuration if needed
4. Deploy to target environment
5. Validate deployment (health checks)
6. Display deployment URL/status
7. Show logs if deployment fails

**Deployment Steps:**
- Build/verify artifacts
- Configure environment
- Deploy to platform
- Validate health checks
- Monitor initial logs

Reference the deployment-strategies skill.
