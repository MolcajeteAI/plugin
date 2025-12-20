---
description: Preview React Native app with Expo Go
---

# Preview with Expo Go

Start the development server and preview the app on a device or simulator.

Use the Task tool to launch the **component-builder** agent with instructions:

1. Check if Expo CLI is available:
   ```bash
   npx expo --version
   ```

2. Start the development server:
   ```bash
   npx expo start
   ```

3. Ask user for preview target using AskUserQuestion:
   - iOS Simulator
   - Android Emulator
   - Expo Go (scan QR code)
   - Web browser

4. Launch on selected target:
   ```bash
   # iOS Simulator
   npx expo start --ios

   # Android Emulator
   npx expo start --android

   # Web
   npx expo start --web
   ```

5. If using Expo Go:
   - Display QR code in terminal
   - Instruct user to scan with Expo Go app

6. Monitor for errors and provide feedback

Reference the **expo-configuration** skill.
