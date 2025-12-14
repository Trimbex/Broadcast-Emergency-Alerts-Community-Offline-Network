# Voice Command Troubleshooting Guide

## ❌ "Failed to start voice command listener"

If you see this error when tapping the voice button, here are the solutions:

---

## 🔍 Root Causes & Solutions

### 1. **Microphone Permission Not Granted**

**Symptom:** Error appears immediately when tapping button

**Fix for iOS Simulator:**
```
1. Go to Settings app
2. Find "Beacon" app
3. Tap it
4. Enable "Microphone" permission
5. Go back to app and try again
```

**Fix for iOS Device:**
```
1. Go to iPhone Settings
2. Privacy > Microphone
3. Find "Beacon" 
4. Toggle ON
5. Restart the app
```

**Fix for Android:**
```
1. Go to Android Settings
2. Apps > Beacon > Permissions
3. Enable "Microphone"
4. Restart the app
```

**Test Permission Status:**
Open terminal and run:
```bash
flutter logs
```
Look for this log when you tap the button:
```
❌ Speech Recognition: Microphone permission denied
```
If you see this, the issue is definitely permissions.

---

### 2. **Speech Recognition Not Available**

**Symptom:** Error after permission is granted

**Cause:** Device doesn't support speech recognition or it's not initialized

**Fix:**
```bash
# Clean and rebuild
flutter clean
flutter pub get
flutter run
```

**For Simulator Issues:**
- Use **iPhone 14 or newer** simulator (older models have issues)
- Use **iOS 16.4 or newer**
- **Avoid Android emulator** - use physical Android device if possible

**Check if Available:**
Look in console for:
```
✅ Speech Service: Initialized successfully
```

If you see:
```
⚠️ Speech Service: Speech recognition not available
```

Try:
1. Update iOS (Settings > General > Software Update)
2. Try a different simulator
3. Test on physical device

---

### 3. **SpeechService Not Initialized**

**Symptom:** No debug logs about speech service, or initialization fails

**Root Cause:** The voice command handler wasn't initialized before use

**Status:** ✅ **FIXED** - Code updated to properly wait for initialization

**Verify it's working:**
Watch console output when app starts:
```
✅ TTS: Initialized
✅ Speech Service: Initialized successfully
✅ BEACON Voice: All commands registered
```

If you don't see these messages, restart the app.

---

### 4. **Language/Locale Issues**

**Symptom:** Speech recognition works but no text is recognized

**Cause:** Device language is not English

**Fix:**
```
iPhone Settings:
1. Settings > General > Language & Region
2. Change to "English"
3. Region > United States (or other English region)
4. Restart app
```

**Note:** Currently only supports **en_US** locale. Multi-language support coming soon.

---

### 5. **No Internet Connection**

**Symptom:** Voice recognition fails even with permissions

**Cause:** Some speech-to-text engines require internet

**Fix:**
- Connect to WiFi or mobile data
- Some devices need internet to process speech

---

## 🧪 Step-by-Step Debugging

### Step 1: Check Console Logs
```bash
# Keep this running while testing
flutter logs
```

### Step 2: Tap Voice Button & Check Logs

Look for one of these patterns:

**✅ Success Path:**
```
🎤 Starting voice command listener...
❌ Speech Recognition: Microphone permission denied
```
→ **Fix:** Grant microphone permission

```
⚠️ Speech Service: Speech recognition not available
```
→ **Fix:** Use newer iOS/simulator or physical device

```
❌ Speech Recognition: Failed to start: ...
```
→ **Fix:** Check error message in logs for details

### Step 3: Verify Each Stage

| Stage | What to Look For |
|-------|-----------------|
| **1. Permission** | `✅ Permission granted` in logs |
| **2. Service Init** | `✅ Speech Service: Initialized` |
| **3. Handler Init** | `✅ BEACON Voice: All commands registered` |
| **4. Listening Start** | `🎤 Speech Recognition: Started listening` |
| **5. Text Recognized** | `📝 Speech Recognition: "your spoken text"` |
| **6. Command Match** | `✅ Matched command: ShowResources` |
| **7. Execution** | `⚡ Executing: ShowResources` |

---

## 🔧 Manual Testing in Console

### Test 1: Check Permissions
Open your main.dart and add this temporarily:
```dart
import 'package:permission_handler/permission_handler.dart';

// In your main function or a test widget:
Future<void> testPermissions() async {
  final status = await Permission.microphone.request();
  print('Microphone permission: $status');
}
```

### Test 2: Test Speech Service Directly
Create a test file:
```dart
import 'package:beacon/services/speech_service.dart';

Future<void> testSpeechService() async {
  final service = SpeechService();
  final initialized = await service.initialize();
  print('Speech Service initialized: $initialized');
  
  final listening = await service.startListening();
  print('Started listening: $listening');
}
```

---

## 📋 Quick Checklist

Before asking for help, confirm:

- [ ] Microphone permission is granted
- [ ] Device/simulator is using English language
- [ ] iOS version is 16.4 or newer (for simulator)
- [ ] Connected to internet (if required)
- [ ] App was restarted after granting permissions
- [ ] `flutter clean && flutter pub get && flutter run` completed
- [ ] Console shows `✅ Speech Service: Initialized successfully`
- [ ] Console shows `✅ BEACON Voice: All commands registered`

---

## 🎯 Testing Commands (Once Working)

Once voice listener starts successfully, try these commands:

| Command | Expected |
|---------|----------|
| "show resources" | Navigate to Resources page |
| "show network" | Navigate to Network Dashboard |
| "show profile" | Navigate to Profile page |
| "call emergency" | Navigate to Profile (shows confirmation) |
| "send message" | Navigate to Chat page |
| "share location" | Shows notification |

---

## 📱 Platform-Specific Issues

### iOS Simulator
- ✅ Works best
- Needs: iOS 16.4+
- Use: iPhone 14 or newer

### iOS Device  
- ✅ Works great
- Needs: Microphone permission in Settings
- Needs: Internet (for some STT engines)

### Android Simulator
- ⚠️ Unreliable
- Microphone simulation can be buggy
- **Better option:** Use physical Android device

### Android Device
- ✅ Works great
- Needs: Microphone permission in Settings
- Needs: Internet connection

---

## 🆘 Still Having Issues?

### Collect Debug Info

Run this to gather debugging information:
```bash
flutter --version
adb shell dumpsys package com.beacon
flutter logs > /tmp/flutter_logs.txt 2>&1
# Then tap voice button and reproduce error
cat /tmp/flutter_logs.txt | grep -E "(Voice|Speech|BEACON|permission)"
```

### Share This Info
1. What platform? (iOS simulator/device, Android simulator/device)
2. Device/simulator model? (iPhone 14 Pro, Pixel 6, etc.)
3. iOS/Android version?
4. What's the exact error message?
5. What do the console logs show?

---

## ✨ Recent Fixes Applied

**Version 1.1:**
- ✅ Fixed initialization timing issue (now awaiting initialize())
- ✅ Added better error messages to user
- ✅ Improved console logging for debugging
- ✅ Fixed microphone permission request flow

---

## 🚀 If Everything Works

Great! Now you can:
1. Test different voice commands
2. Try commands in noisy environments
3. Test on physical devices
4. Integrate voice commands into other screens
5. Customize keywords for your use case

Happy voice commanding! 🎤
