---
description: Deploy to EAS and submit to app stores
---

# Deploy to EAS

Deploy app to EAS and optionally submit to App Store / Google Play.

Use the Task tool to launch the **component-builder** agent with instructions:

1. Ensure EAS is configured:
   ```bash
   eas --version
   eas whoami
   ```

2. Ask user for deployment options using AskUserQuestion:
   - Platform (iOS, Android, both)
   - Submit to store? (yes/no)
   - Build profile (production recommended for store submission)

3. If builds needed:
   ```bash
   eas build --platform {platform} --profile production
   ```

4. Wait for builds to complete

5. If submitting to iOS App Store:
   ```bash
   eas submit --platform ios
   ```
   - Configure App Store Connect credentials if needed
   - Select the build to submit
   - Choose submission options

6. If submitting to Google Play Store:
   ```bash
   eas submit --platform android
   ```
   - Configure Google Play credentials if needed
   - Select the build to submit
   - Choose track (internal, alpha, beta, production)

7. Monitor submission status:
   - Provide App Store Connect / Play Console links
   - Report submission status
   - Note any review requirements

8. Provide next steps:
   - App review timelines
   - How to check status
   - Rollout instructions

Reference the **eas-build-setup** skill.
