import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_application/viewmodels/profile_viewmodel.dart';
import '../mocks/mock_services.dart';

void main() {
  group('ProfileViewModel Tests', () {
    late MockP2PService mockP2PService;
    late MockDatabaseService mockDatabaseService;
    late ProfileViewModel viewModel;

    setUp(() {
      mockP2PService = MockP2PService();
      mockDatabaseService = MockDatabaseService();
      viewModel = ProfileViewModel(
        p2pService: mockP2PService,
        databaseService: mockDatabaseService,
      );
    });

    tearDown(() {
      viewModel.dispose();
    });

    test('Initial state should be empty', () {
      expect(viewModel.name, isEmpty);
      expect(viewModel.phone, isEmpty);
      expect(viewModel.bloodType, isEmpty);
      expect(viewModel.emergencyContacts, isEmpty);
    });

    test('Initialize should load profile from database', () async {
      // Arrange
      mockP2PService.localDeviceId = 'device123';
      mockDatabaseService.setUserProfile({
        'name': 'John Doe',
        'phone': '1234567890',
        'blood_type': 'O+',
        'medical_conditions': 'None',
      });

      // Act
      await viewModel.initialize();

      // Assert
      expect(viewModel.name, equals('John Doe'));
      expect(viewModel.phone, equals('1234567890'));
      expect(viewModel.bloodType, equals('O+'));
      expect(viewModel.deviceId, equals('device123'));
    });

    test('Update field should modify profile data', () {
      // Act
      viewModel.updateField(name: 'Jane Doe');
      viewModel.updateField(phone: '9876543210');

      // Assert
      expect(viewModel.name, equals('Jane Doe'));
      expect(viewModel.phone, equals('9876543210'));
    });

    test('Save profile with valid data should succeed', () async {
      // Arrange
      mockP2PService.localDeviceId = 'device123';
      await viewModel.initialize();
      viewModel.updateField(
        name: 'John Doe',
        phone: '1234567890',
      );

      // Act
      final result = await viewModel.saveProfile();

      // Assert
      expect(result, isTrue);
      expect(viewModel.errorMessage, isNull);
    });

    test('Save profile with invalid phone should fail', () async {
      // Arrange
      mockP2PService.localDeviceId = 'device123';
      await viewModel.initialize();
      viewModel.updateField(
        name: 'John Doe',
        phone: 'invalid',
      );

      // Act
      final result = await viewModel.saveProfile();

      // Assert
      expect(result, isFalse);
      expect(viewModel.errorMessage, isNotNull);
    });

    test('Validate phone number should reject invalid formats', () {
      expect(viewModel.validatePhoneNumber('abc'), isNotNull);
      expect(viewModel.validatePhoneNumber('123'), isNotNull);
      expect(viewModel.validatePhoneNumber(''), isNotNull);
    });

    test('Validate phone number should accept valid formats', () {
      expect(viewModel.validatePhoneNumber('1234567890'), isNull);
      expect(viewModel.validatePhoneNumber('12345678901'), isNull);
    });

    test('Add emergency contact with valid data should succeed', () async {
      // Arrange
      mockP2PService.localDeviceId = 'device123';
      await viewModel.initialize();

      // Act
      final result = await viewModel.addEmergencyContact(
        name: 'Emergency Contact',
        phone: '1234567890',
        relation: 'Friend',
      );

      // Assert
      expect(result, isTrue);
      expect(viewModel.errorMessage, isNull);
    });

    test('Add emergency contact with invalid phone should fail', () async {
      // Arrange
      mockP2PService.localDeviceId = 'device123';
      await viewModel.initialize();

      // Act
      final result = await viewModel.addEmergencyContact(
        name: 'Emergency Contact',
        phone: 'invalid',
        relation: 'Friend',
      );

      // Assert
      expect(result, isFalse);
      expect(viewModel.errorMessage, isNotNull);
    });

    test('Delete emergency contact should remove from list', () async {
      // Arrange
      mockP2PService.localDeviceId = 'device123';
      mockDatabaseService.addEmergencyContact({
        'id': 1,
        'name': 'Contact 1',
        'phone': '1234567890',
        'relation': 'Friend',
      });
      await viewModel.initialize();
      expect(viewModel.emergencyContacts.length, equals(1));

      // Act
      final result = await viewModel.deleteEmergencyContact(1);

      // Assert
      expect(result, isTrue);
      expect(viewModel.emergencyContacts, isEmpty);
    });
  });
}
