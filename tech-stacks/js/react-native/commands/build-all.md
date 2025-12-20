---
description: Build iOS and Android apps using EAS Build
---

# Build All Platforms

Build both iOS and Android apps using EAS Build service.

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
   - development (dev builds for both platforms)
   - preview (internal testing builds)
   - production (store-ready builds)

6. Start builds for both platforms:
   ```bash
   eas build --platform all --profile {profile}
   ```

7. Monitor build progress:
   - Provide build URLs for tracking
   - Builds run in parallel on EAS
   - Report status of each platform

8. When complete:
   - Provide iOS download link (IPA or Simulator build)
   - Provide Android download link (APK or AAB)
   - Show build artifacts summary

Reference the **eas-build-setup** skill.
