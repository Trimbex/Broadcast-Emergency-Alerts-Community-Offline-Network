class DeviceModel {
  final String id;
  final String name;
  final String status;
  final String distance;
  final int batteryLevel;
  final String? endpointId; // For P2P connections
  final DateTime? lastSeen;
  final Map<String, dynamic>? metadata;

  DeviceModel({
    required this.id,
    required this.name,
    required this.status,
    required this.distance,
    required this.batteryLevel,
    this.endpointId,
    this.lastSeen,
    this.metadata,
  });

  // Convert to/from JSON for network transmission
  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'status': status,
    'distance': distance,
    'batteryLevel': batteryLevel,
    'endpointId': endpointId,
    'lastSeen': lastSeen?.toIso8601String(),
    'metadata': metadata,
  };

  factory DeviceModel.fromJson(Map<String, dynamic> json) => DeviceModel(
    id: json['id'],
    name: json['name'],
    status: json['status'],
    distance: json['distance'],
    batteryLevel: json['batteryLevel'],
    endpointId: json['endpointId'],
    lastSeen: json['lastSeen'] != null ? DateTime.parse(json['lastSeen']) : null,
    metadata: json['metadata'],
  );

  // Create a copy with updated fields
  DeviceModel copyWith({
    String? id,
    String? name,
    String? status,
    String? distance,
    int? batteryLevel,
    String? endpointId,
    DateTime? lastSeen,
    Map<String, dynamic>? metadata,
  }) {
    return DeviceModel(
      id: id ?? this.id,
      name: name ?? this.name,
      status: status ?? this.status,
      distance: distance ?? this.distance,
      batteryLevel: batteryLevel ?? this.batteryLevel,
      endpointId: endpointId ?? this.endpointId,
      lastSeen: lastSeen ?? this.lastSeen,
      metadata: metadata ?? this.metadata,
    );
  }
}
