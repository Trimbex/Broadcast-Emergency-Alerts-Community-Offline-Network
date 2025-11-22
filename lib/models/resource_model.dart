class ResourceModel {
  final String id;
  final String name;
  final String category;
  final int quantity;
  final String location;
  final String provider;
  final String status;
  final String? deviceId; // ID of the device that shared this resource

  ResourceModel({
    required this.id,
    required this.name,
    required this.category,
    required this.quantity,
    required this.location,
    required this.provider,
    required this.status,
    this.deviceId,
  });

  // Create a copy with updated fields
  ResourceModel copyWith({
    String? id,
    String? name,
    String? category,
    int? quantity,
    String? location,
    String? provider,
    String? status,
    String? deviceId,
  }) {
    return ResourceModel(
      id: id ?? this.id,
      name: name ?? this.name,
      category: category ?? this.category,
      quantity: quantity ?? this.quantity,
      location: location ?? this.location,
      provider: provider ?? this.provider,
      status: status ?? this.status,
      deviceId: deviceId ?? this.deviceId,
    );
  }

  // Convert to JSON for P2P transmission
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'category': category,
      'quantity': quantity,
      'location': location,
      'provider': provider,
      'status': status,
      'deviceId': deviceId,
    };
  }

  // Create from JSON received via P2P
  factory ResourceModel.fromJson(Map<String, dynamic> json) {
    return ResourceModel(
      id: json['id'] as String,
      name: json['name'] as String,
      category: json['category'] as String,
      quantity: json['quantity'] as int,
      location: json['location'] as String,
      provider: json['provider'] as String,
      status: json['status'] as String,
      deviceId: json['deviceId'] as String?,
    );
  }
}