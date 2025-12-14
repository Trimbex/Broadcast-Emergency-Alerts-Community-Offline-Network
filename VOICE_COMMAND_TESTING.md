# Voice Command Testing Guide

Voice commands are now fully integrated into your BEACON app's landing page. This guide shows you how to test them.

## ✅ Integration Status

✅ **Voice commands integrated into landing page**
✅ **All compiler errors resolved**
✅ **Ready for testing on device/simulator**

---

## 🎤 How to Test Voice Commands

### Step 1: Start the App

```bash
flutter run
```

The app will start on your device/simulator (iOS or Android).

### Step 2: Microphone Permissions

On first launch, grant microphone permissions when prompted:
- **iOS**: Settings → Beacon → Microphone → Allow
- **Android**: Grant microphone permission when app requests

### Step 3: Tap the Voice Command FAB

On the landing page, you'll see a **floating action button (FAB)** in the bottom-right corner:
- 🔴 **Red** = Active/Listening
- 🔵 **Blue** = Inactive

Tap the FAB to start listening for voice commands.

---

## 🗣️ Test Commands

Try saying these exact phrases:

| Command | Expected Result |
|---------|-----------------|
| **"call emergency"** | 🚨 Navigates to Profile page (Emergency contact) |
| **"emergency call"** | 🚨 Navigates to Profile page |
| **"help"** | 🚨 Navigates to Profile page |
| **"call 911"** | 🚨 Navigates to Profile page |
| **"show resources"** | 📦 Navigates to Resources page |
| **"show network"** | 🌐 Navigates to Network Dashboard |
| **"show profile"** | 👤 Navigates to Profile page |
| **"send message"** | 💬 Navigates to Chat page |
| **"share location"** | 📍 Shows "Location shared!" notification |

---

## 🔍 What to Watch For

### Console Output (Xcode or Flutter DevTools)

You should see debug logs like:

```
🎤 [VoiceCommandListener] Starting to listen...
🎤 Command Recognized: show resources
✅ Command Executed: ShowResources
```

### UI Feedback

Each stage will show feedback:

1. **Recognized**: SnackBar says "Recognized: ShowResources"
2. **Executed**: SnackBar says "Executed: ShowResources" (green)
3. **Failed**: SnackBar says "Failed: ..." (red) if something goes wrong

### Navigation

The app will automatically navigate to the correct page after executing a command.

---

## 🧪 Detailed Testing Steps

### Test 1: Basic Voice Recognition

1. Tap the FAB
2. Clearly say: **"show resources"**
3. Wait 2-3 seconds
4. **Expected**: 
   - Console shows recognized text
   - UI shows "Recognized: ShowResources"
   - App navigates to Resources page

### Test 2: Emergency Command (with Confirmation)

1. Tap the FAB
2. Say: **"call emergency"**
3. **Expected**:
   - Console shows: "CallEmergency command matched"
   - A confirmation dialog appears (before executing)
   - After confirming, app navigates to Profile page

### Test 3: Multiple Commands in Sequence

1. Test multiple commands one after another
2. Tap FAB → Say "show network" → Wait for navigation
3. Go back to landing page
4. Tap FAB → Say "show profile" → Wait for navigation
5. Go back and repeat

### Test 4: No Match Scenario

1. Tap FAB
2. Say something unrelated: **"hello world"** or **"what time is it"**
3. **Expected**:
   - Console shows: "❌ Command not recognized"
   - UI shows failure SnackBar (red)
   - App stays on landing page

### Test 5: Microphone Issues

1. Deny microphone permission and try to use voice commands
2. **Expected**: Error message in console and UI

---

## 📊 Command Matching Details

The system uses **keyword matching**. Here's how it works:

```
User says: "call the emergency contact"
↓
System searches for commands with matching keywords:
  - CallEmergency has keyword "call emergency" ✓
  - ShareLocation has keyword "share location" ✗
↓
Match found! Execute CallEmergency command
↓
Show confirmation dialog (because requiresConfirmation = true)
↓
After confirmation, navigate to Profile page
```

### Exact Keywords Per Command

**CallEmergency (Requires Confirmation)**
- "call emergency"
- "emergency call"  
- "help"
- "call 911"

**ShareLocation**
- "share location"
- "share my location"
- "send location"

**ShowResources**
- "show resources"
- "resources"
- "open resources"
- "resources page"

**ShowNetwork**
- "show network"
- "network"
- "connected devices"
- "show devices"

**ShowProfile**
- "show profile"
- "profile"
- "my profile"
- "open profile"

**SendMessage**
- "send message"
- "message"
- "chat"

---

## 🐛 Troubleshooting

### Issue: No microphone detected

**Solution**: 
- Check iOS/Android settings for microphone permission
- Run `flutter clean` and `flutter pub get`
- Restart the app

### Issue: Voice command not recognized

**Solution**:
- Speak clearly and slowly
- Use exact keyword phrases from the list above
- Check console for what text was recognized
- Try phrases with different keyword variations

### Issue: App crashes on voice input

**Solution**:
- Ensure device supports both TTS (flutter_tts) and STT (speech_to_text)
- Check device language settings (some older devices don't support all languages)
- Try on iOS simulator instead of Android emulator (more reliable)

### Issue: Commands execute but don't navigate

**Solution**:
- Check console logs for navigation errors
- Verify route names are correct in pubspec.yaml or navigation setup
- Check if the target page exists

### Issue: Seeing "Lost connection to device"

**Solution**:
- Run app again: `flutter run`
- Or hot restart: Press `R` in terminal where Flutter is running

---

## 📱 Testing on Device vs Simulator

### iOS Simulator
✅ **Recommended** - Most reliable for voice commands
- Microphone simulation works well
- Quick testing iteration

### iOS Device
✅ **Works** - Real microphone testing
- Requires actual spoken input
- Good for real-world testing

### Android Emulator
⚠️ **May have issues** - Microphone simulation can be unreliable
- Consider physical Android device instead

### Android Device
✅ **Works** - Real microphone testing
- Requires actual spoken input

---

## 📝 Logging & Debugging

### View Console Logs

**In VS Code:**
```
Open: Debug Console (Shift + Cmd + Y)
Search for: "🎤" or "✅" or "❌"
```

**In Xcode:**
```
Window → Devices and Simulators → [Your Device]
Open Console
Search for: "BEACON Voice"
```

### Key Log Patterns

| Pattern | Meaning |
|---------|---------|
| 🎤 Listening... | App is waiting for speech input |
| 🎤 Recognized: | App detected speech text |
| ⚡ Matching... | App is searching for command match |
| ✅ Matched: | Found matching command |
| ⚡ Executing: | Running command action |
| ✅ Executed: | Command completed successfully |
| ❌ Failed: | Command failed with error message |

---

## 🚀 Next Steps After Testing

Once you verify commands work:

1. **Add voice commands to other screens** (chat, resources, network)
2. **Enhance confirmation dialogs** for critical commands
3. **Add sound feedback** (beep on recognized, error sound on fail)
4. **Test in noisy environments** (cars, crowds)
5. **Optimize keywords** based on user testing feedback

---

## 📚 Related Files

- **Voice Command Handler**: [lib/services/voice_command_handler.dart](lib/services/voice_command_handler.dart)
- **BEACON Commands**: [lib/services/beacon_voice_commands.dart](lib/services/beacon_voice_commands.dart)
- **Voice Listener Widget**: [lib/widgets/common/voice_command_listener.dart](lib/widgets/common/voice_command_listener.dart)
- **Landing Page** (Integration): [lib/screens/landing_Page.dart](lib/screens/landing_Page.dart)
- **Speech Service** (TTS/STT): [lib/services/speech_service.dart](lib/services/speech_service.dart)

---

## ✨ Tips for Best Results

1. **Speak naturally** - No need to speak unnaturally slowly
2. **Use consistent keywords** - Stick to the exact phrases listed
3. **Test in quiet environment first** - Background noise can affect recognition
4. **Keep device near you** - Microphone needs clear audio
5. **Test multiple times** - Speech recognition accuracy improves with variety

---

## 💡 Future Enhancements

- ✨ Fuzzy matching for typos ("call 911" could become "call 911 please")
- ✨ Voice authentication before critical commands
- ✨ User-defined custom voice commands
- ✨ Command chaining ("show resources and share location")
- ✨ Voice feedback confirmation ("Okay, calling emergency contact...")
- ✨ Multi-language support

---

Happy testing! 🎉
