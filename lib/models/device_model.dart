class DeviceModel {
  final String id;
  final String name;
  final String status;
  final String distance;
  final int batteryLevel;
  final String? ipAddress;
  final DateTime lastSeen;
  final bool isConnected;

  DeviceModel({
    required this.id,
    required this.name,
    required this.status,
    required this.distance,
    required this.batteryLevel,
    this.ipAddress,
    DateTime? lastSeen,
    this.isConnected = false,
  }) : lastSeen = lastSeen ?? DateTime.now();

  // Convert to JSON for database storage
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'status': status,
      'distance': distance,
      'batteryLevel': batteryLevel,
      'ipAddress': ipAddress,
      'lastSeen': lastSeen.millisecondsSinceEpoch,
      'isConnected': isConnected ? 1 : 0,
    };
  }

  // Create from JSON
  factory DeviceModel.fromJson(Map<String, dynamic> json) {
    return DeviceModel(
      id: json['id'] as String,
      name: json['name'] as String,
      status: json['status'] as String,
      distance: json['distance'] as String,
      batteryLevel: json['batteryLevel'] as int,
      ipAddress: json['ipAddress'] as String?,
      lastSeen: DateTime.fromMillisecondsSinceEpoch(json['lastSeen'] as int),
      isConnected: (json['isConnected'] as int) == 1,
    );
  }

  DeviceModel copyWith({
    String? id,
    String? name,
    String? status,
    String? distance,
    int? batteryLevel,
    String? ipAddress,
    DateTime? lastSeen,
    bool? isConnected,
  }) {
    return DeviceModel(
      id: id ?? this.id,
      name: name ?? this.name,
      status: status ?? this.status,
      distance: distance ?? this.distance,
      batteryLevel: batteryLevel ?? this.batteryLevel,
      ipAddress: ipAddress ?? this.ipAddress,
      lastSeen: lastSeen ?? this.lastSeen,
      isConnected: isConnected ?? this.isConnected,
    );
  }
}
