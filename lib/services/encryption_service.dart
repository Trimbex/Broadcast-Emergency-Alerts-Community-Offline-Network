import 'dart:convert';
import 'dart:typed_data';
import 'package:encrypt/encrypt.dart' as encrypt_pkg;

/// Service for handling AES Encryption/Decryption
/// Uses a static key to ensure all Beacon apps can communicate offline.
class EncryptionService {
  static final EncryptionService instance = EncryptionService._internal();
  EncryptionService._internal();

  // 32 chars = 256 bit key
  // Hardcoded for this prototype to ensure all devices share the key for P2P.
  static const String _keyString = 'BeaconEmergencyAppSafeKey2024Secure';
  
  // 16 chars = 128 bit IV
  // Using static IV to avoid database schema requiring new columns for IV storage.
  static const String _ivString = 'BeaconInitVector'; 

  late final encrypt_pkg.Key _key;
  late final encrypt_pkg.IV _iv;
  late final encrypt_pkg.Encrypter _encrypter;

  bool _isInitialized = false;

  void initialize() {
    if (_isInitialized) return;
    
    // Ensure key is exactly 32 chars (pad if needed)
    String paddedKey = _keyString;
    if (paddedKey.length < 32) paddedKey = paddedKey.padRight(32, '.');
    if (paddedKey.length > 32) paddedKey = paddedKey.substring(0, 32);

    // Ensure IV is exactly 16 chars
    String paddedIV = _ivString;
    if (paddedIV.length < 16) paddedIV = paddedIV.padRight(16, '.');
    if (paddedIV.length > 16) paddedIV = paddedIV.substring(0, 16);

    _key = encrypt_pkg.Key(Uint8List.fromList(utf8.encode(paddedKey)));
    _iv = encrypt_pkg.IV(Uint8List.fromList(utf8.encode(paddedIV)));
    _encrypter = encrypt_pkg.Encrypter(encrypt_pkg.AES(_key));
    
    _isInitialized = true;
    print('🔐 EncryptionService initialized');
  }

  /// Encrypts plain text
  String encrypt(String plainText) {
    if (!_isInitialized) initialize();
    if (plainText.isEmpty) return plainText;
    
    try {
      final encrypted = _encrypter.encrypt(plainText, iv: _iv);
      final cipherText = encrypted.base64;
      // DEBUG: Show encryption happening
      // print('🔒 ENC: "$plainText" -> "$cipherText"'); 
      print('🔒 Encrypting data...'); 
      return cipherText;
    } catch (e) {
      print('❌ Encryption failed: $e');
      return plainText; // Fallback to plain text to prevent crash
    }
  }

  /// Decrypts encrypted text (base64)
  String decrypt(String encryptedText) {
    if (!_isInitialized) initialize();
    if (encryptedText.isEmpty) return encryptedText;

    try {
      final encrypted = encrypt_pkg.Encrypted.fromBase64(encryptedText);
      final decrypted = _encrypter.decrypt(encrypted, iv: _iv);
      // DEBUG: Show decryption happening
      // print('🔓 DEC: "$encryptedText" -> "$decrypted"');
      print('🔓 Decrypting data...');
      return decrypted;
    } catch (e) {
      // Common error if text wasn't actually encrypted or key changed
      // Return original text assuming it's legacy data (plain text)
      return encryptedText;
    }
  }
}
