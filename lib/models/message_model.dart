class MessageModel {
  final String id;
  final String senderId;
  final String text;
  final DateTime timestamp;
  final bool isMe;
  final String? senderName;
  final bool isEmergency;
  final String? messageType; // 'text', 'location', 'resource', 'emergency'
  final Map<String, dynamic>? metadata;

  MessageModel({
    required this.id,
    required this.senderId,
    required this.text,
    required this.timestamp,
    required this.isMe,
    this.senderName,
    this.isEmergency = false,
    this.messageType = 'text',
    this.metadata,
  });

  // Convert to/from JSON for network transmission
  Map<String, dynamic> toJson() => {
    'id': id,
    'senderId': senderId,
    'text': text,
    'timestamp': timestamp.toIso8601String(),
    'isMe': isMe,
    'senderName': senderName,
    'isEmergency': isEmergency,
    'messageType': messageType,
    'metadata': metadata,
  };

  factory MessageModel.fromJson(Map<String, dynamic> json) => MessageModel(
    id: json['id'],
    senderId: json['senderId'],
    text: json['text'],
    timestamp: DateTime.parse(json['timestamp']),
    isMe: json['isMe'] ?? false,
    senderName: json['senderName'],
    isEmergency: json['isEmergency'] ?? false,
    messageType: json['messageType'] ?? 'text',
    metadata: json['metadata'],
  );

  // Create a copy with updated fields
  MessageModel copyWith({
    String? id,
    String? senderId,
    String? text,
    DateTime? timestamp,
    bool? isMe,
    String? senderName,
    bool? isEmergency,
    String? messageType,
    Map<String, dynamic>? metadata,
  }) {
    return MessageModel(
      id: id ?? this.id,
      senderId: senderId ?? this.senderId,
      text: text ?? this.text,
      timestamp: timestamp ?? this.timestamp,
      isMe: isMe ?? this.isMe,
      senderName: senderName ?? this.senderName,
      isEmergency: isEmergency ?? this.isEmergency,
      messageType: messageType ?? this.messageType,
      metadata: metadata ?? this.metadata,
    );
  }
}
