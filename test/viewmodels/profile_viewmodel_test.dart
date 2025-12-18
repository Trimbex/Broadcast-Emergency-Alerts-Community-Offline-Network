import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:flutter_application/viewmodels/profile_viewmodel.dart';
import '../mocks/mock_services.mocks.dart';

void main() {
  group('ProfileViewModel Tests', () {
    late MockP2PService mockP2PService;
    late MockDatabaseService mockDatabaseService;
    late ProfileViewModel viewModel;

    setUp(() {
      mockP2PService = MockP2PService();
      mockDatabaseService = MockDatabaseService();
      
      // Default stub for localDeviceId (often accessed during init or save)
      when(mockP2PService.localDeviceId).thenReturn('device123');
      // Stub for emergency contacts
      when(mockDatabaseService.getEmergencyContacts(any)).thenAnswer((_) async => []);

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
      when(mockDatabaseService.getUserProfile()).thenAnswer((_) async => {
        'name': 'John Doe',
        'phone': '1234567890',
        'blood_type': 'O+',
        'medical_conditions': 'None',
        'device_id': 'device123',
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
      when(mockDatabaseService.getUserProfile()).thenAnswer((_) async => null); // Start empty
      when(mockDatabaseService.saveUserProfile(
        name: anyNamed('name'),
        deviceId: anyNamed('deviceId'),
        phone: anyNamed('phone'),
        role: anyNamed('role'),
        bloodType: anyNamed('bloodType'),
        medicalConditions: anyNamed('medicalConditions'),
      )).thenAnswer((_) async {});

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
      verify(mockDatabaseService.saveUserProfile(
        name: 'John Doe',
        deviceId: 'device123',
        phone: '1234567890',
        role: anyNamed('role'),
        bloodType: anyNamed('bloodType'),
        medicalConditions: anyNamed('medicalConditions'),
      )).called(1);
    });

    test('Save profile with invalid phone should fail', () async {
      // Arrange
      when(mockDatabaseService.getUserProfile()).thenAnswer((_) async => null);
      await viewModel.initialize();
      viewModel.updateField(
        name: 'John Doe',
        phone: 'invalid', // Invalid phone
      );

      // Act
      final result = await viewModel.saveProfile();

      // Assert
      expect(result, isFalse);
      expect(viewModel.errorMessage, isNotNull);
      verifyNever(mockDatabaseService.saveUserProfile(
        name: anyNamed('name'),
        deviceId: anyNamed('deviceId'),
        phone: anyNamed('phone'),
      ));
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
      when(mockDatabaseService.getUserProfile()).thenAnswer((_) async => {'name': 'User'});
      when(mockDatabaseService.saveEmergencyContact(
        name: anyNamed('name'),
        phone: anyNamed('phone'),
        relation: anyNamed('relation'),
        deviceId: anyNamed('deviceId'),
      )).thenAnswer((_) async {});
      when(mockDatabaseService.getEmergencyContacts(any)).thenAnswer((_) async => []); // Return empty list after add for reload

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
      verify(mockDatabaseService.saveEmergencyContact(
        name: 'Emergency Contact',
        phone: '1234567890',
        relation: 'Friend',
        deviceId: 'device123',
      )).called(1);
    });

    test('Add emergency contact with invalid phone should fail', () async {
      // Arrange
      when(mockDatabaseService.getUserProfile()).thenAnswer((_) async => {'name': 'User'});
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
      verifyNever(mockDatabaseService.saveEmergencyContact(
        name: anyNamed('name'),
        phone: anyNamed('phone'),
        relation: anyNamed('relation'),
        deviceId: anyNamed('deviceId'),
      ));
    });

    test('Delete emergency contact should remove from list', () async {
      // Arrange
      when(mockDatabaseService.getUserProfile()).thenAnswer((_) async => {'name': 'User'});
      // Initial contacts
      when(mockDatabaseService.getEmergencyContacts(any)).thenAnswer((_) async => [{
        'id': 1,
        'name': 'Contact 1',
        'phone': '1234567890',
        'relation': 'Friend',
        'device_id': 'device123',
      }]);
      // After delete (empty)
      when(mockDatabaseService.deleteEmergencyContact(any)).thenAnswer((_) async {});
      
      await viewModel.initialize();
      expect(viewModel.emergencyContacts.length, equals(1));
      
      // Update stub for reload after delete
      when(mockDatabaseService.getEmergencyContacts(any)).thenAnswer((_) async => []);

      // Act
      final result = await viewModel.deleteEmergencyContact(1);

      // Assert
      expect(result, isTrue);
      expect(viewModel.emergencyContacts, isEmpty);
      verify(mockDatabaseService.deleteEmergencyContact(1)).called(1);
    });
  });
}
