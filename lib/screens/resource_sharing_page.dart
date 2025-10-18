import 'package:flutter/material.dart';
import '../widgets/voice_command_button.dart';
import '../models/resource_model.dart';

class ResourceSharingPage extends StatefulWidget {
  const ResourceSharingPage({super.key});

  @override
  State<ResourceSharingPage> createState() => _ResourceSharingPageState();
}

class _ResourceSharingPageState extends State<ResourceSharingPage> {
  String _selectedCategory = 'All';
  final List<String> _categories = ['All', 'Medical', 'Food', 'Shelter', 'Water', 'Other'];

  final List<ResourceModel> _resources = [
    ResourceModel(
      id: '1',
      name: 'First Aid Kit',
      category: 'Medical',
      quantity: 5,
      location: 'Community Center - 0.5 km',
      provider: 'Sarah Johnson',
      status: 'Available',
    ),
    ResourceModel(
      id: '2',
      name: 'Bottled Water (24-pack)',
      category: 'Water',
      quantity: 12,
      location: 'Emergency Shelter - 1.2 km',
      provider: 'Emergency Center',
      status: 'Available',
    ),
    ResourceModel(
      id: '3',
      name: 'Emergency Shelter Space',
      category: 'Shelter',
      quantity: 20,
      location: 'High School Gym - 2.0 km',
      provider: 'Emergency Center',
      status: 'Available',
    ),
    ResourceModel(
      id: '4',
      name: 'Canned Food',
      category: 'Food',
      quantity: 30,
      location: 'Relief Center - 1.5 km',
      provider: 'Mike Chen',
      status: 'Available',
    ),
    ResourceModel(
      id: '5',
      name: 'Blankets',
      category: 'Shelter',
      quantity: 15,
      location: 'Community Hall - 0.8 km',
      provider: 'Lisa Rodriguez',
      status: 'Limited',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final filteredResources = _selectedCategory == 'All'
        ? _resources
        : _resources.where((r) => r.category == _selectedCategory).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Resource Sharing'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              // Search functionality
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Category Filter
          Container(
            height: 60,
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _categories.length,
              itemBuilder: (context, index) {
                final category = _categories[index];
                final isSelected = category == _selectedCategory;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(category),
                    selected: isSelected,
                    onSelected: (selected) {
                      setState(() {
                        _selectedCategory = category;
                      });
                    },
                    backgroundColor: Colors.grey[200],
                    selectedColor: Theme.of(context).colorScheme.primaryContainer,
                  ),
                );
              },
            ),
          ),

          // Resource Statistics
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatItem(
                  icon: Icons.inventory,
                  label: 'Total Items',
                  value: '${filteredResources.length}',
                ),
                Container(
                  width: 1,
                  height: 40,
                  color: Colors.grey[300],
                ),
                _buildStatItem(
                  icon: Icons.check_circle,
                  label: 'Available',
                  value: '${filteredResources.where((r) => r.status == 'Available').length}',
                ),
                Container(
                  width: 1,
                  height: 40,
                  color: Colors.grey[300],
                ),
                _buildStatItem(
                  icon: Icons.people,
                  label: 'Providers',
                  value: '${filteredResources.map((r) => r.provider).toSet().length}',
                ),
              ],
            ),
          ),

          // Resource List
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: filteredResources.length,
              itemBuilder: (context, index) {
                return _buildResourceCard(filteredResources[index]);
              },
            ),
          ),

          // Bottom Action Bar
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withValues(alpha: 0.2),
                  spreadRadius: 1,
                  blurRadius: 5,
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _showAddResourceDialog,
                    icon: const Icon(Icons.add),
                    label: const Text('Share Resource'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                const VoiceCommandButton(isCompact: true),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Column(
      children: [
        Icon(icon, size: 24, color: const Color(0xFF1976D2)),
        const SizedBox(height: 6),
        Text(
          value,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Color(0xFF1976D2),
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w400,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildResourceCard(ResourceModel resource) {
    final IconData categoryIcon = _getCategoryIcon(resource.category);
    final Color statusColor = resource.status == 'Available' 
        ? const Color(0xFF4CAF50) 
        : const Color(0xFFFF9800);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF1976D2), Color(0xFF42A5F5)],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(categoryIcon, size: 26, color: Colors.white),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        resource.name,
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: statusColor.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: statusColor.withValues(alpha: 0.3),
                              ),
                            ),
                            child: Text(
                              resource.status,
                              style: TextStyle(
                                color: statusColor,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.grey[100],
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              'Qty: ${resource.quantity}',
                              style: TextStyle(
                                color: Colors.grey[700],
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Icon(Icons.location_on, size: 16, color: Colors.grey[500]),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    resource.location,
                    style: TextStyle(
                      color: Colors.grey[700],
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.person, size: 16, color: Colors.grey[500]),
                const SizedBox(width: 6),
                Text(
                  'Provided by ${resource.provider}',
                  style: TextStyle(
                    color: Colors.grey[700],
                    fontSize: 13,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              height: 44,
              child: ElevatedButton(
                onPressed: () => _requestResource(resource),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1976D2),
                  foregroundColor: Colors.white,
                ),
                child: const Text(
                  'Request Resource',
                  style: TextStyle(fontWeight: FontWeight.w500),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'Medical':
        return Icons.medical_services;
      case 'Food':
        return Icons.restaurant;
      case 'Shelter':
        return Icons.home;
      case 'Water':
        return Icons.water_drop;
      default:
        return Icons.category;
    }
  }

  void _requestResource(ResourceModel resource) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Request Resource'),
        content: Text('Do you want to request ${resource.name}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Request sent for ${resource.name}'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
  }

  void _showAddResourceDialog() {
    final nameController = TextEditingController();
    final quantityController = TextEditingController();
    final locationController = TextEditingController();
    String selectedCategory = 'Medical';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Share a Resource'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Resource Name',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: selectedCategory,
                decoration: const InputDecoration(
                  labelText: 'Category',
                  border: OutlineInputBorder(),
                ),
                items: _categories
                    .where((c) => c != 'All')
                    .map((category) => DropdownMenuItem(
                          value: category,
                          child: Text(category),
                        ))
                    .toList(),
                onChanged: (value) {
                  selectedCategory = value!;
                },
              ),
              const SizedBox(height: 12),
              TextField(
                controller: quantityController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Quantity',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: locationController,
                decoration: const InputDecoration(
                  labelText: 'Location',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Resource shared successfully'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            child: const Text('Share'),
          ),
        ],
      ),
    );
  }
}