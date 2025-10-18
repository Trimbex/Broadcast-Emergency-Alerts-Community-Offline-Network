class ResourceModel {
  final String id;
  final String name;
  final String category;
  final int quantity;
  final String location;
  final String provider;
  final String status;

  ResourceModel({
    required this.id,
    required this.name,
    required this.category,
    required this.quantity,
    required this.location,
    required this.provider,
    required this.status,
  });
}