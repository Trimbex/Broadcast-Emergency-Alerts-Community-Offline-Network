class UserProfileModel {
  final String id;
  final String name;
  final String? email;
  final String? phoneNumber;
  final String? emergencyContact;
  final String? bloodType;
  final String? medicalInfo;
  final DateTime createdAt;
  final DateTime updatedAt;

  UserProfileModel({
    required this.id,
    required this.name,
    this.email,
    this.phoneNumber,
    this.emergencyContact,
    this.bloodType,
    this.medicalInfo,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'phoneNumber': phoneNumber,
      'emergencyContact': emergencyContact,
      'bloodType': bloodType,
      'medicalInfo': medicalInfo,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'updatedAt': updatedAt.millisecondsSinceEpoch,
    };
  }

  factory UserProfileModel.fromJson(Map<String, dynamic> json) {
    return UserProfileModel(
      id: json['id'] as String,
      name: json['name'] as String,
      email: json['email'] as String?,
      phoneNumber: json['phoneNumber'] as String?,
      emergencyContact: json['emergencyContact'] as String?,
      bloodType: json['bloodType'] as String?,
      medicalInfo: json['medicalInfo'] as String?,
      createdAt: DateTime.fromMillisecondsSinceEpoch(json['createdAt'] as int),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(json['updatedAt'] as int),
    );
  }

  UserProfileModel copyWith({
    String? id,
    String? name,
    String? email,
    String? phoneNumber,
    String? emergencyContact,
    String? bloodType,
    String? medicalInfo,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return UserProfileModel(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      emergencyContact: emergencyContact ?? this.emergencyContact,
      bloodType: bloodType ?? this.bloodType,
      medicalInfo: medicalInfo ?? this.medicalInfo,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

