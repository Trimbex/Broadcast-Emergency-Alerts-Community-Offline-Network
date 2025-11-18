class NetworkActivityModel {
  final String id;
  final String activityType; // 'connection', 'disconnection', 'resource_shared', 'resource_requested', 'message_sent'
  final String deviceId;
  final String deviceName;
  final String? details;
  final DateTime timestamp;

  NetworkActivityModel({
    required this.id,
    required this.activityType,
    required this.deviceId,
    required this.deviceName,
    this.details,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'activityType': activityType,
      'deviceId': deviceId,
      'deviceName': deviceName,
      'details': details,
      'timestamp': timestamp.millisecondsSinceEpoch,
    };
  }

  factory NetworkActivityModel.fromJson(Map<String, dynamic> json) {
    return NetworkActivityModel(
      id: json['id'] as String,
      activityType: json['activityType'] as String,
      deviceId: json['deviceId'] as String,
      deviceName: json['deviceName'] as String,
      details: json['details'] as String?,
      timestamp: DateTime.fromMillisecondsSinceEpoch(json['timestamp'] as int),
    );
  }
}

