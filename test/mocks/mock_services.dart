import 'dart:async';
import 'package:flutter_application/models/device_model.dart';
import 'package:flutter_application/models/message_model.dart';
import 'package:flutter_application/models/resource_model.dart';

/// Mock P2P Service for testing
class MockP2PService {
  bool isInitialized = false;
  bool initializeShouldFail = false;
  String? lastSentMessage;
  String? lastEmergencyAlert;
  int discoveryRestartCount = 0;
  final List<DeviceModel> _connectedDevices = [];
  final List<ResourceModel> _networkResources = [];
  final List<ResourceModel> broadcastedResources = [];
  Map<String, dynamic>? lastResourceRequest;
  String? localDeviceId;

  List<DeviceModel> get connectedDevices => _connectedDevices;

  List<ResourceModel> get networkResources => _networkResources;

  bool get isAdvertising => isInitialized;

  bool get isDiscovering => isInitialized;

  String? get localDeviceName => 'Test Device';

  void addConnectedDevice(DeviceModel device) {
    _connectedDevices.add(device);
  }

  void addResource(ResourceModel resource) {
    _networkResources.add(resource);
  }

  Future<bool> initialize(String deviceName) async {
    await Future.delayed(const Duration(milliseconds: 10));
    if (initializeShouldFail) {
      return false;
    }
    isInitialized = true;
    return true;
  }

  Future<bool> startAdvertising() async {
    await Future.delayed(const Duration(milliseconds: 10));
    return isInitialized;
  }

  Future<bool> startDiscovery() async {
    await Future.delayed(const Duration(milliseconds: 10));
    return isInitialized;
  }

  Future<void> stopDiscovery() async {
    await Future.delayed(const Duration(milliseconds: 10));
    discoveryRestartCount++;
  }

  Future<void> sendMessage(String endpointId, String message) async {
    lastSentMessage = message;
    await Future.delayed(const Duration(milliseconds: 10));
  }

  Future<void> broadcastEmergencyAlert(String message) async {
    lastEmergencyAlert = message;
    await Future.delayed(const Duration(milliseconds: 10));
  }

  Stream<MessageModel>? getMessageStream(String endpointId) {
    return Stream.value(MessageModel(
      id: '1',
      senderId: 'sender',
      senderName: 'Test',
      text: 'Test message',
      timestamp: DateTime.now(),
      isMe: false,
      messageType: 'text',
    ));
  }

  List<MessageModel> getMessageHistoryForDevice(String? endpointId, String? deviceId) {
    return [];
  }

  Future<void> broadcastResource(ResourceModel resource) async {
    broadcastedResources.add(resource);
    _networkResources.add(resource);
    await Future.delayed(const Duration(milliseconds: 10));
  }

  Future<void> requestSpecificResource(
    String endpointId,
    String resourceId,
    int requestedQuantity,
    String requesterName,
  ) async {
    lastResourceRequest = {
      'endpointId': endpointId,
      'resourceId': resourceId,
      'requestedQuantity': requestedQuantity,
      'requesterName': requesterName,
    };
    await Future.delayed(const Duration(milliseconds: 10));
  }

  Stream<ResourceModel> get resourceStream => const Stream.empty();

  Stream<Map<String, dynamic>> get resourceRequestStream => const Stream.empty();
}

/// Mock Database Service for testing
class MockDatabaseService {
  bool shouldThrowError = false;
  Map<String, dynamic>? _userProfile;
  final List<MessageModel> _messages = [];
  final List<Map<String, dynamic>> _emergencyContacts = [];

  void setUserProfile(Map<String, dynamic> profile) {
    _userProfile = profile;
  }

  void setMessages(List<MessageModel> messages) {
    _messages.clear();
    _messages.addAll(messages);
  }

  void addEmergencyContact(Map<String, dynamic> contact) {
    _emergencyContacts.add(contact);
  }

  Future<Map<String, dynamic>?> getUserProfile() async {
    await Future.delayed(const Duration(milliseconds: 10));
    if (shouldThrowError) {
      throw Exception('Database error');
    }
    return _userProfile;
  }

  Future<List<MessageModel>> getMessages(String peerId) async {
    await Future.delayed(const Duration(milliseconds: 10));
    if (shouldThrowError) {
      throw Exception('Database error');
    }
    return _messages;
  }

  Future<List<Map<String, dynamic>>> getEmergencyContacts(String deviceId) async {
    await Future.delayed(const Duration(milliseconds: 10));
    if (shouldThrowError) {
      throw Exception('Database error');
    }
    // Return a copy to avoid type issues
    return List<Map<String, dynamic>>.from(_emergencyContacts);
  }

  Future<void> saveUserProfile({
    required String deviceId,
    required String name,
    String? role,
    String? phone,
    String? bloodType,
    String? medicalConditions,
  }) async {
    await Future.delayed(const Duration(milliseconds: 10));
    if (shouldThrowError) {
      throw Exception('Database error');
    }
    _userProfile = {
      'name': name,
      'phone': phone,
      'blood_type': bloodType,
      'medical_conditions': medicalConditions,
    };
  }

  Future<void> saveEmergencyContact({
    required String deviceId,
    required String name,
    required String phone,
    required String relation,
  }) async {
    await Future.delayed(const Duration(milliseconds: 10));
    if (shouldThrowError) {
      throw Exception('Database error');
    }
    _emergencyContacts.add({
      'id': _emergencyContacts.length + 1,
      'name': name,
      'phone': phone,
      'relation': relation,
    });
  }

  Future<void> deleteEmergencyContact(int contactId) async {
    await Future.delayed(const Duration(milliseconds: 10));
    if (shouldThrowError) {
      throw Exception('Database error');
    }
    _emergencyContacts.removeWhere((c) => c['id'] == contactId);
  }

  Future<void> saveMessage(MessageModel message, String conversationId) async {
    await Future.delayed(const Duration(milliseconds: 10));
    _messages.add(message);
  }
}
