# Speech and Text-to-Speech Support

This document outlines the implementation of text-to-speech (TTS) and speech recognition capabilities in the BEACON emergency network application.

## Overview

The Speech Service provides:
- **Text-to-Speech (TTS)**: Convert text to spoken audio
- **Speech-to-Text (STT)**: Convert spoken audio to text
- **Voice Commands**: Execute actions via voice input
- **Accessibility**: Enhanced accessibility for voice-based interaction

## Components

### 1. SpeechService (`lib/services/speech_service.dart`)

The core service handling all speech-related operations.

#### Features:
- Singleton pattern for app-wide access
- Non-blocking initialization
- Microphone permission handling
- Error handling and recovery
- Debug logging with emoji indicators

#### Key Methods:

```dart
// Initialize the service
Future<bool> initialize()

// Text-to-Speech
Future<void> speak(String text)
Future<void> stop()
Future<void> pause()

// Speech Recognition
Future<bool> startListening()
Future<void> stopListening()
Future<void> cancelListening()

// Configuration
Future<void> setLanguage(String languageCode)
Future<void> setSpeechRate(double rate)  // 0.0-2.0
Future<void> setPitch(double pitch)       // 0.5-2.0

// Getters
bool get isListening
bool get isSpeaking
String get recognizedText
bool get isSpeechToTextAvailable
```

### 2. Voice Input Button (`lib/widgets/common/voice_input_button.dart`)

Reusable UI components for voice interaction.

#### VoiceInputButton
A floating action button for speech recognition:

```dart
VoiceInputButton(
  onTextRecognized: (text) {
    // Handle recognized text
    print('User said: $text');
  },
  speakConfirmation: true,  // Optional audio confirmation
)
```

**Features:**
- Visual feedback (animated button state)
- Automatic TTS confirmation
- Error handling
- Color customization

#### VoiceCommandButton
A button that executes an action and reads the label:

```dart
VoiceCommandButton(
  icon: Icons.send,
  label: 'Send Message',
  onPressed: () => sendMessage(),
  readLabel: true,  // Speak the button label
)
```

### 3. Speech Status Indicator (`lib/widgets/common/speech_status_indicator.dart`)

Visual indicator for speech activity:

```dart
SpeechStatusIndicator(
  isListening: speechService.isListening,
  isSpeaking: speechService.isSpeaking,
  recognizedText: speechService.recognizedText,
)
```

**Features:**
- Real-time status display
- Animated listening indicator
- Recognized text preview
- Contextual colors

## Integration

### In P2PService
The P2PService automatically initializes the SpeechService:

```dart
// Initialization happens in P2PService.initialize()
try {
  await SpeechService().initialize();
} catch (e) {
  debugPrint('Speech service initialization failed: $e');
}
```

## Usage Examples

### Example 1: Voice Message Input
```dart
class ChatPage extends StatefulWidget {
  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  late SpeechService _speechService;
  String _messageText = '';

  @override
  void initState() {
    super.initState();
    _speechService = SpeechService();
  }

  void _sendVoiceMessage() async {
    final success = await _speechService.startListening();
    if (success) {
      // Wait for user to finish speaking
      await Future.delayed(Duration(seconds: 5));
      
      final recognizedText = _speechService.getRecognizedText();
      if (recognizedText.isNotEmpty) {
        _sendMessage(recognizedText);
        await _speechService.speak('Message sent: $recognizedText');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: VoiceInputButton(
        onTextRecognized: (text) {
          _sendMessage(text);
        },
      ),
    );
  }
}
```

### Example 2: Voice Commands
```dart
class EmergencyPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        VoiceCommandButton(
          icon: Icons.phone,
          label: 'Call Emergency',
          onPressed: () => callEmergency(),
          readLabel: true,
        ),
        VoiceCommandButton(
          icon: Icons.location_on,
          label: 'Share Location',
          onPressed: () => shareLocation(),
          readLabel: true,
        ),
      ],
    );
  }
}
```

### Example 3: Text-to-Speech Notifications
```dart
// In notification handling
Future<void> handleIncomingMessage(MessageModel message) async {
  final speechService = SpeechService();
  
  // Read message aloud
  await speechService.speak(
    'Message from ${message.senderName}: ${message.text}'
  );
  
  // Show visual notification
  NotificationService.instance.showMessageNotification(
    senderName: message.senderName ?? 'Unknown',
    message: message.text,
    isEmergency: false,
  );
}
```

## Permissions Required

### Android
Add to `android/app/build.gradle`:
```gradle
android {
  ...
  minSdkVersion 21
}
```

Add to `android/app/src/main/AndroidManifest.xml`:
```xml
<uses-permission android:name="android.permission.RECORD_AUDIO" />
<uses-permission android:name="android.permission.INTERNET" />
```

### iOS
Add to `ios/Runner/Info.plist`:
```xml
<key>NSMicrophoneUsageDescription</key>
<string>This app needs microphone access for voice commands and speech recognition.</string>
<key>NSSpeechRecognitionUsageDescription</key>
<string>This app uses speech recognition to process your voice commands.</string>
</key>
```

## Best Practices

### 1. Always Handle Initialization Errors
```dart
try {
  await speechService.initialize();
} catch (e) {
  debugPrint('Speech service failed: $e');
  // Provide fallback UI without voice features
}
```

### 2. Check Availability Before Using STT
```dart
if (speechService.isSpeechToTextAvailable) {
  await speechService.startListening();
} else {
  showDialog(context: context, builder: (_) => 
    AlertDialog(title: Text('Speech recognition not available')),
  );
}
```

### 3. Clean Up Resources
```dart
@override
void dispose() {
  speechService.stopListening();
  speechService.stop();
  super.dispose();
}
```

### 4. Provide Visual Feedback
```dart
// Always show status during speech operations
SpeechStatusIndicator(
  isListening: speechService.isListening,
  isSpeaking: speechService.isSpeaking,
  recognizedText: speechService.recognizedText,
)
```

### 5. Set Appropriate Language
```dart
// Match app language to speech service
if (appLanguage == 'es') {
  await speechService.setLanguage('es_ES');
} else {
  await speechService.setLanguage('en_US');
}
```

## Performance Considerations

- **STT Timeout**: Default 30 seconds, configurable
- **Pause Duration**: 3 seconds between speech detection
- **Memory**: Service uses streaming for large texts
- **Battery**: Speaking uses device speakers (not high power)

## Troubleshooting

### Speech Recognition Not Working
1. Check microphone permission: `Permission.microphone.request()`
2. Verify internet connection (some engines require cloud)
3. Check device language settings
4. Test with `SpeechService().initialize()`

### Text-to-Speech Not Working
1. Verify TTS engine is installed on device
2. Check language availability
3. Test with short text first
4. Check volume settings

### Permission Denied Errors
1. Request permissions explicitly before using speech features
2. Handle permission denial gracefully
3. Provide UI fallback when permissions denied

## Dependencies

- `flutter_tts: ^4.2.3` - Text-to-Speech
- `speech_to_text: ^6.6.2` - Speech Recognition
- `permission_handler: ^11.3.1` - Permission management

## Future Enhancements

- [ ] Offline speech recognition support
- [ ] Custom voice commands dictionary
- [ ] Multi-language support with automatic detection
- [ ] Voice activity detection (VAD)
- [ ] Real-time transcription display
- [ ] Voice authentication
- [ ] Audio playback speed control
- [ ] Batch speech processing
