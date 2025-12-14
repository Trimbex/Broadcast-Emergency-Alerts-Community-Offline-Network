import 'package:flutter/material.dart';
import '../services/database_service.dart';
import 'base_viewmodel.dart';

/// Emergency contact model
class EmergencyContact {
  final int id;
  final String name;
  final String relation;
  final String phone;

  EmergencyContact({
    required this.id,
    required this.name,
    required this.relation,
    required this.phone,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'relation': relation,
      'phone': phone,
    };
  }
}

/// ViewModel for ProfilePage
/// Manages user profile and emergency contacts
class ProfileViewModel extends BaseViewModel {
  final dynamic _databaseService;
  final dynamic _p2pService;

  ProfileViewModel({
    required dynamic p2pService,
    dynamic databaseService,
  })  : _p2pService = p2pService,
        _databaseService = databaseService ?? DatabaseService.instance;

  // UI State
  String _name = '';
  String _phone = '';
  String _bloodType = '';
  String _medicalConditions = '';
  List<EmergencyContact> _emergencyContacts = [];
  String? _deviceId;

  // Getters
  String get name => _name;
  String get phone => _phone;
  String get bloodType => _bloodType;
  String get medicalConditions => _medicalConditions;
  List<EmergencyContact> get emergencyContacts =>
      List.unmodifiable(_emergencyContacts);
  String? get deviceId => _deviceId;

  /// Initialize profile data
  Future<void> initialize() async {
    setLoading(true);
    clearError();

    try {
      // Get device ID
      _deviceId = _p2pService.localDeviceId ??
          DateTime.now().millisecondsSinceEpoch.toString();
      debugPrint('📱 Initialized device ID: $_deviceId');

      // Load profile data
      await _loadProfileData();

      setLoading(false);
    } catch (e) {
      setError('Error loading profile: $e');
      setLoading(false);
    }
  }

  /// Load profile data from database
  Future<void> _loadProfileData() async {
    try {
      // Load user profile
      final profile = await _databaseService.getUserProfile();

      if (profile != null) {
        _name = profile['name']?.toString() ?? '';
        _phone = profile['phone']?.toString() ?? '';
        _bloodType = profile['blood_type']?.toString() ?? '';
        _medicalConditions = profile['medical_conditions']?.toString() ?? '';
      }

      // Load emergency contacts
      if (_deviceId != null) {
        final contacts = await _databaseService.getEmergencyContacts(_deviceId!);
        _emergencyContacts = contacts.map<EmergencyContact>((contact) {
          return EmergencyContact(
            id: contact['id'] as int,
            name: contact['name'] as String,
            relation: contact['relation'] as String? ?? '',
            phone: contact['phone'] as String,
          );
        }).toList();

        debugPrint('✅ Loaded ${_emergencyContacts.length} emergency contacts');
      }

      safeNotifyListeners();
    } catch (e) {
      debugPrint('❌ Error loading profile data: $e');
      rethrow;
    }
  }

  /// Update profile field
  void updateField({
    String? name,
    String? phone,
    String? bloodType,
    String? medicalConditions,
  }) {
    if (name != null) _name = name;
    if (phone != null) _phone = phone;
    if (bloodType != null) _bloodType = bloodType;
    if (medicalConditions != null) _medicalConditions = medicalConditions;
    safeNotifyListeners();
  }

  /// Save profile to database
  Future<bool> saveProfile() async {
    try {
      // Validate phone number if provided
      if (_phone.isNotEmpty) {
        final phoneError = validatePhoneNumber(_phone);
        if (phoneError != null) {
          setError(phoneError);
          return false;
        }
      }

      // Ensure deviceId is available
      if (_deviceId == null) {
        setError('Device ID not initialized');
        return false;
      }

      await _databaseService.saveUserProfile(
        deviceId: _deviceId!,
        name: _name,
        phone: _phone,
        bloodType: _bloodType,
        medicalConditions: _medicalConditions,
      );

      clearError();
      return true;
    } catch (e) {
      setError('Failed to save profile: $e');
      return false;
    }
  }

  /// Validate phone number
  String? validatePhoneNumber(String phone) {
    if (phone.isEmpty) {
      return 'Phone number is required';
    }
    if (!RegExp(r'^[0-9]+$').hasMatch(phone)) {
      return 'Phone number must contain only digits';
    }
    if (phone.length < 7) {
      return 'Phone number must be at least 7 digits';
    }
    return null;
  }

  /// Add emergency contact
  Future<bool> addEmergencyContact({
    required String name,
    required String phone,
    required String relation,
  }) async {
    if (_deviceId == null) {
      setError('Device ID not initialized');
      return false;
    }

    try {
      // Validate phone
      final phoneError = validatePhoneNumber(phone);
      if (phoneError != null) {
        setError(phoneError);
        return false;
      }

      // Validate name
      if (name.trim().isEmpty) {
        setError('Name is required');
        return false;
      }

      await _databaseService.saveEmergencyContact(
        deviceId: _deviceId!,
        name: name.trim(),
        phone: phone.trim(),
        relation: relation.trim(),
      );

      // Reload contacts
      await _loadProfileData();
      clearError();
      return true;
    } catch (e) {
      setError('Failed to add contact: $e');
      return false;
    }
  }

  /// Delete emergency contact
  Future<bool> deleteEmergencyContact(int contactId) async {
    try {
      await _databaseService.deleteEmergencyContact(contactId);

      // Remove from local list
      _emergencyContacts.removeWhere((c) => c.id == contactId);
      safeNotifyListeners();

      clearError();
      return true;
    } catch (e) {
      setError('Failed to delete contact: $e');
      return false;
    }
  }

  /// Reload profile data
  Future<void> reload() async {
    setLoading(true);
    try {
      await _loadProfileData();
      clearError();
    } catch (e) {
      setError('Failed to reload profile: $e');
    } finally {
      setLoading(false);
    }
  }
}
