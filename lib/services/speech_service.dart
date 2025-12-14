import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:permission_handler/permission_handler.dart';

class SpeechService {
  static final SpeechService _instance = SpeechService._internal();
  factory SpeechService() => _instance;
  SpeechService._internal();

  final FlutterTts _flutterTts = FlutterTts();
  final stt.SpeechToText _speechToText = stt.SpeechToText();

  bool _isListening = false;
  bool _isSpeaking = false;
  String _recognizedText = '';

  // Getters
  bool get isListening => _isListening;
  bool get isSpeaking => _isSpeaking;
  String get recognizedText => _recognizedText;

  /// Initialize the speech service
  Future<bool> initialize() async {
    try {
      print('🎤 Initializing SpeechService...');
      
      // Initialize TTS
      await _initializeTTS();

      // Initialize STT
      print('🎤 Initializing speech-to-text...');
      final available = await _speechToText.initialize(
        onError: (error) {
          print('❌ Speech Recognition Error callback: $error');
          debugPrint('❌ Speech Recognition Error: $error');
          _isListening = false;
        },
        onStatus: (status) {
          print('📢 Speech Recognition Status callback: $status');
          debugPrint('📢 Speech Recognition Status: $status');
        },
      );

      print('🎤 Speech-to-text initialization result: $available');

      if (available) {
        debugPrint('✅ Speech Service: Initialized successfully');
        print('✅ SpeechService initialized successfully');
        return true;
      } else {
        debugPrint('⚠️ Speech Service: Speech recognition not available');
        print('⚠️ SpeechService: Speech-to-text not available - check if device supports it');
        return false;
      }
    } catch (e) {
      print('❌ SpeechService initialization error: $e');
      print('   Error type: ${e.runtimeType}');
      debugPrint('❌ Speech Service: Failed to initialize: $e');
      return false;
    }
  }

  /// Initialize Text-to-Speech
  Future<void> _initializeTTS() async {
    try {
      await _flutterTts.setLanguage('en-US');
      await _flutterTts.setSpeechRate(0.5);
      await _flutterTts.setPitch(1.0);
      
      // Set callbacks
      _flutterTts.setStartHandler(() {
        _isSpeaking = true;
        debugPrint('🔊 TTS: Started speaking');
      });

      _flutterTts.setCompletionHandler(() {
        _isSpeaking = false;
        debugPrint('✅ TTS: Finished speaking');
      });

      _flutterTts.setErrorHandler((msg) {
        _isSpeaking = false;
        debugPrint('❌ TTS Error: $msg');
      });

      debugPrint('✅ TTS: Initialized');
    } catch (e) {
      debugPrint('❌ TTS: Failed to initialize: $e');
    }
  }

  /// Speak the given text
  Future<void> speak(String text) async {
    if (text.isEmpty) {
      debugPrint('⚠️ TTS: No text to speak');
      return;
    }

    try {
      if (_isSpeaking) {
        await stop();
      }

      await _flutterTts.speak(text);
      debugPrint('🔊 TTS: Speaking: "$text"');
    } catch (e) {
      debugPrint('❌ TTS: Failed to speak: $e');
    }
  }

  /// Start listening for speech
  Future<bool> startListening() async {
    try {
      // Request microphone permission
      final microphoneStatus = await Permission.microphone.request();
      print('🎤 Microphone permission status: $microphoneStatus');
      if (!microphoneStatus.isGranted) {
        debugPrint('❌ Speech Recognition: Microphone permission denied');
        return false;
      }

      print('✅ Microphone permission confirmed: GRANTED');

      // Check if speech-to-text is available
      if (!_speechToText.isAvailable) {
        debugPrint('❌ Speech Recognition: Not available on this device');
        print('⚠️ Speech-to-text not available - this is a device/simulator limitation');
        return false;
      }

      print('✅ Speech-to-text is available');

      if (_isListening) {
        await stopListening();
      }

      _isListening = true;
      _recognizedText = '';

      print('🎤 About to call _speechToText.listen()...');
      try {
        await _speechToText.listen(
          onResult: (result) {
            _recognizedText = result.recognizedWords;
            debugPrint('📝 Speech Recognition: "${result.recognizedWords}"');
            print('✅ Got speech result: "${result.recognizedWords}"');
          },
          localeId: 'en_US',
          pauseFor: const Duration(seconds: 3),
          listenFor: const Duration(seconds: 30),
          cancelOnError: true,
          partialResults: true,
        );

        print('✅ _speechToText.listen() call succeeded');
        debugPrint('🎤 Speech Recognition: Started listening');
        return true;
      } catch (listenError) {
        print('❌ Error in _speechToText.listen(): $listenError');
        print('   Error type: ${listenError.runtimeType}');
        debugPrint('❌ Speech Recognition: Failed to listen: $listenError');
        _isListening = false;
        return false;
      }
    } catch (e) {
      _isListening = false;
      print('❌ Speech Recognition: Exception in startListening: $e');
      print('   Error type: ${e.runtimeType}');
      print('   Stack: ${StackTrace.current}');
      debugPrint('❌ Speech Recognition: Failed to start: $e');
      return false;
    }
  }

  /// Stop listening for speech
  Future<void> stopListening() async {
    try {
      if (_isListening) {
        await _speechToText.stop();
        _isListening = false;
        debugPrint('🛑 Speech Recognition: Stopped listening');
      }
    } catch (e) {
      debugPrint('❌ Speech Recognition: Failed to stop: $e');
    }
  }

  /// Cancel speech recognition
  Future<void> cancelListening() async {
    try {
      if (_isListening) {
        await _speechToText.cancel();
        _isListening = false;
        _recognizedText = '';
        debugPrint('❌ Speech Recognition: Cancelled');
      }
    } catch (e) {
      debugPrint('❌ Speech Recognition: Failed to cancel: $e');
    }
  }

  /// Stop speaking
  Future<void> stop() async {
    try {
      await _flutterTts.stop();
      _isSpeaking = false;
      debugPrint('🛑 TTS: Stopped speaking');
    } catch (e) {
      debugPrint('❌ TTS: Failed to stop: $e');
    }
  }

  /// Get available languages for TTS
  Future<List<String>> getAvailableLanguages() async {
    try {
      final languages = await _flutterTts.getLanguages as List<dynamic>;
      return languages.map((lang) => lang.toString()).toList();
    } catch (e) {
      debugPrint('❌ TTS: Failed to get languages: $e');
      return [];
    }
  }

  /// Set TTS language
  Future<void> setLanguage(String languageCode) async {
    try {
      await _flutterTts.setLanguage(languageCode);
      debugPrint('✅ TTS: Language set to $languageCode');
    } catch (e) {
      debugPrint('❌ TTS: Failed to set language: $e');
    }
  }

  /// Set TTS speech rate (0.0 to 2.0, where 1.0 is normal)
  Future<void> setSpeechRate(double rate) async {
    try {
      await _flutterTts.setSpeechRate(rate.clamp(0.0, 2.0));
      debugPrint('✅ TTS: Speech rate set to $rate');
    } catch (e) {
      debugPrint('❌ TTS: Failed to set speech rate: $e');
    }
  }

  /// Set TTS pitch (0.5 to 2.0, where 1.0 is normal)
  Future<void> setPitch(double pitch) async {
    try {
      await _flutterTts.setPitch(pitch.clamp(0.5, 2.0));
      debugPrint('✅ TTS: Pitch set to $pitch');
    } catch (e) {
      debugPrint('❌ TTS: Failed to set pitch: $e');
    }
  }

  /// Pause speech
  Future<void> pause() async {
    try {
      await _flutterTts.pause();
      debugPrint('⏸️ TTS: Paused');
    } catch (e) {
      debugPrint('❌ TTS: Failed to pause: $e');
    }
  }

  /// Check if speech-to-text is available
  bool get isSpeechToTextAvailable => _speechToText.isAvailable;

  /// Get last recognized text
  String getRecognizedText() => _recognizedText;

  /// Clear recognized text
  void clearRecognizedText() {
    _recognizedText = '';
  }
}
