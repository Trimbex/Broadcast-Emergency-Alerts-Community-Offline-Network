class ResourceModel {
  final String id;
  final String name;
  final String category;
  final int quantity;
  final String location;
  final String provider;
  final String status;
  final String? providerId;
  final DateTime createdAt;
  final DateTime updatedAt;

  ResourceModel({
    required this.id,
    required this.name,
    required this.category,
    required this.quantity,
    required this.location,
    required this.provider,
    required this.status,
    this.providerId,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  // Convert to JSON for database storage
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'category': category,
      'quantity': quantity,
      'location': location,
      'provider': provider,
      'status': status,
      'providerId': providerId,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'updatedAt': updatedAt.millisecondsSinceEpoch,
    };
  }

  // Create from JSON
  factory ResourceModel.fromJson(Map<String, dynamic> json) {
    return ResourceModel(
      id: json['id'] as String,
      name: json['name'] as String,
      category: json['category'] as String,
      quantity: json['quantity'] as int,
      location: json['location'] as String,
      provider: json['provider'] as String,
      status: json['status'] as String,
      providerId: json['providerId'] as String?,
      createdAt: DateTime.fromMillisecondsSinceEpoch(json['createdAt'] as int),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(json['updatedAt'] as int),
    );
  }

  ResourceModel copyWith({
    String? id,
    String? name,
    String? category,
    int? quantity,
    String? location,
    String? provider,
    String? status,
    String? providerId,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ResourceModel(
      id: id ?? this.id,
      name: name ?? this.name,
      category: category ?? this.category,
      quantity: quantity ?? this.quantity,
      location: location ?? this.location,
      provider: provider ?? this.provider,
      status: status ?? this.status,
      providerId: providerId ?? this.providerId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}