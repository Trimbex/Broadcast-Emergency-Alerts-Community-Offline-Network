import 'package:flutter_test/flutter_test.dart';
import '../../lib/services/encryption_service.dart';

void main() {
  group('EncryptionService Tests', () {
    test('Encrypting then decrypting returns original text', () {
      const originalText = 'Hello World of Encryption!';
      
      final encrypted = EncryptionService.instance.encrypt(originalText);
      final decrypted = EncryptionService.instance.decrypt(encrypted);
      
      expect(decrypted, equals(originalText));
    });

    test('Encryption should produce different text (ciphertext)', () {
      const originalText = 'Secret Message';
      final encrypted = EncryptionService.instance.encrypt(originalText);
      
      expect(encrypted, isNot(equals(originalText)));
      expect(encrypted.length, greaterThan(0));
    });

    test('Empty string returns empty string', () {
      expect(EncryptionService.instance.encrypt(''), isEmpty);
      expect(EncryptionService.instance.decrypt(''), isEmpty);
    });

    test('Determinism (Static IV check)', () {
      // Since we use a static IV for this prototype, 
      // the same plaintext should produce the same ciphertext.
      const text = 'Same Text';
      final enc1 = EncryptionService.instance.encrypt(text);
      final enc2 = EncryptionService.instance.encrypt(text);
      
      expect(enc1, equals(enc2));
    });

    test('Decrypting garbage returns garbage or handles error gracefully', () {
      // If we pass a random base64 string that wasn't encrypted by us
      // it might crash or return garbage. Our service catches errors and returns original.
      const garbage = 'NotEncryptedString';
      final result = EncryptionService.instance.decrypt(garbage);
      
      // Our implementation returns the original text on error
      expect(result, equals(garbage));
    });
  });
}
