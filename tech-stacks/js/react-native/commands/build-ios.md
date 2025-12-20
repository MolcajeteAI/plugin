---
description: Build iOS app using EAS Build
---

# Build iOS App

Build iOS app using EAS Build service.

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
   - development (development build with dev client)
   - preview (ad-hoc distribution for testing)
   - production (App Store ready)

6. Start iOS build:
   ```bash
   eas build --platform ios --profile {profile}
   ```

7. Monitor build progress:
   - Provide build URL for tracking
   - Wait for completion
   - Provide download link when ready

8. If production build:
   - Remind about App Store credentials
   - Guide through signing certificate setup

Reference the **eas-build-setup** skill.
