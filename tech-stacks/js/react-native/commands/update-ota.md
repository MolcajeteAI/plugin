---
description: Push over-the-air (OTA) update using EAS Update
---

# Push OTA Update

Push over-the-air update to published apps using EAS Update.

Use the Task tool to launch the **component-builder** agent with instructions:

1. Check if EAS Update is configured in `app.json`:
   ```json
   {
     "expo": {
       "updates": {
         "url": "https://u.expo.dev/[your-project-id]"
       },
       "runtimeVersion": {
         "policy": "appVersion"
       }
     }
   }
   ```

2. Verify EAS Update is set up:
   ```bash
   eas update:configure
   ```

3. Ask user for update details using AskUserQuestion:
   - Branch (production, staging, preview)
   - Message describing the update
   - Channel (if using multiple channels)

4. Run pre-update checks:
   ```bash
   npm run type-check
   npm run lint
   npm test
   ```

5. Publish the update:
   ```bash
   eas update --branch {branch} --message "{message}"
   ```

6. Monitor update status:
   - Provide update ID
   - Show update URL
   - Confirm deployment

7. Verify update is live:
   - Check EAS dashboard
   - Test on device (may need app restart)

8. Provide rollback instructions if needed:
   ```bash
   eas update:rollback --branch {branch}
   ```

**Important Notes:**
- OTA updates only work for JavaScript/TypeScript changes
- Native code changes require a new build
- Users receive updates on next app launch

Reference the **eas-update-setup** skill.
