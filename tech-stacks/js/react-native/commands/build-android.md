---
description: Build Android app using EAS Build
---

# Build Android App

Build Android app using EAS Build service.

Use the Task tool to launch the **component-builder** agent with instructions:

1. Check if EAS CLI is installed:
   ```bash
   eas --version
   ```

2. If not installed:
   ```bash
   npm install -g eas-cli
   ```

3. Login to Expo account:
   ```bash
   eas login
   ```

4. Configure EAS Build (if not already):
   ```bash
   eas build:configure
   ```

5. Ask user for build profile using AskUserQuestion:
   - development (APK for testing)
   - preview (APK for internal distribution)
   - production (AAB for Play Store)

6. Start Android build:
   ```bash
   eas build --platform android --profile {profile}
   ```

7. Monitor build progress:
   - Provide build URL for tracking
   - Wait for completion
   - Provide download link when ready

8. If production build:
   - Generate AAB (Android App Bundle)
   - Remind about signing keystore
   - Guide through keystore setup if needed

Reference the **eas-build-setup** skill.
