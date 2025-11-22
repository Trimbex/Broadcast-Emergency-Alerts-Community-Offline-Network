import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../widgets/voice_command_button.dart';
import '../widgets/theme_toggle_button.dart';
import '../models/resource_model.dart';
import '../services/p2p_service.dart';
import '../theme/beacon_colors.dart';

class ResourceSharingPage extends StatefulWidget {
  const ResourceSharingPage({super.key});

  @override
  State<ResourceSharingPage> createState() => _ResourceSharingPageState();
}

class _ResourceSharingPageState extends State<ResourceSharingPage> {
  String _selectedCategory = 'All';
  final List<String> _categories = ['All', 'Medical', 'Food', 'Shelter', 'Water', 'Other'];
  
  // Stream subscription for network resources
  StreamSubscription<ResourceModel>? _resourceSubscription;
  StreamSubscription<Map<String, dynamic>>? _resourceRequestSubscription;
  

  @override
  void initState() {
    super.initState();
    // Listen to resource updates from network
    final p2pService = Provider.of<P2PService>(context, listen: false);
    _resourceSubscription = p2pService.resourceStream.listen((resource) {
      if (mounted) {
        setState(() {});
      }
    });
    
    // Listen to resource requests
    _resourceRequestSubscription = p2pService.resourceRequestStream.listen((requestData) {
      if (mounted) {
        _showResourceRequestDialog(requestData);
      }
    });
  }

  @override
  void dispose() {
    _resourceSubscription?.cancel();
    _resourceRequestSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p2pService = Provider.of<P2PService>(context);
    
    // Get all network resources (includes both local and remote)
    final allResources = p2pService.networkResources;
    
    // Remove duplicates (same id and deviceId)
    final uniqueResources = <String, ResourceModel>{};
    for (var resource in allResources) {
      final key = '${resource.id}_${resource.deviceId ?? "unknown"}';
      if (!uniqueResources.containsKey(key)) {
        uniqueResources[key] = resource;
      }
    }
    
    final filteredResources = _selectedCategory == 'All'
        ? uniqueResources.values.toList()
        : uniqueResources.values.where((r) => r.category == _selectedCategory).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Resource Sharing'),
        actions: const [
          ThemeToggleButton(isCompact: true),
          SizedBox(width: 8),
        ],
      ),
      body: _buildResourcesView(p2pService, filteredResources),
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Column(
      children: [
        Icon(icon, size: 24, color: BeaconColors.primary),
        const SizedBox(height: 6),
        Text(
          value,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: BeaconColors.primary,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }

  Widget _buildResourceCard(ResourceModel resource) {
    final p2pService = Provider.of<P2PService>(context, listen: false);
    final IconData categoryIcon = _getCategoryIcon(resource.category);
    final Color statusColor = resource.status == 'Available' 
        ? BeaconColors.success 
        : BeaconColors.warning;
    
    // Check if resource is from network (another device) or local
    final isFromNetwork = resource.deviceId != null && 
                         resource.deviceId != p2pService.localDeviceId;

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
                    gradient: LinearGradient(
                      colors: BeaconColors.accentGradient(context),
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
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              resource.name,
                              style: const TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          if (isFromNetwork)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: BeaconColors.secondary.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: BeaconColors.secondary,
                                  width: 1,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.network_check,
                                    size: 12,
                                    color: BeaconColors.secondary,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Network',
                                    style: TextStyle(
                                      color: BeaconColors.secondary,
                                      fontSize: 10,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
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
                              color: statusColor.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: statusColor.withOpacity(0.3),
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
                              color: BeaconColors.surface(context),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              'Qty: ${resource.quantity}',
                              style: Theme.of(context).textTheme.bodySmall,
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
                Icon(Icons.location_on, size: 16, color: BeaconColors.textSecondary(context)),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    resource.location,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.person, size: 16, color: BeaconColors.textSecondary(context)),
                const SizedBox(width: 6),
                Text(
                  'Provided by ${resource.provider}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
            const SizedBox(height: 14),
            // Only show request button if resource is not from current user
            if (isFromNetwork && resource.status != 'Unavailable')
              SizedBox(
                width: double.infinity,
                height: 44,
                child: ElevatedButton(
                  onPressed: () => _requestResource(resource, p2pService),
                  style: ElevatedButton.styleFrom(
                    foregroundColor: Colors.white,
                  ),
                  child: const Text(
                    'Request Resource',
                    style: TextStyle(fontWeight: FontWeight.w500),
                  ),
                ),
              )
            else if (!isFromNetwork)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: BeaconColors.surface(context),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.info_outline, size: 18, color: BeaconColors.textSecondary(context)),
                    const SizedBox(width: 8),
                    Text(
                      'Your Resource',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildResourcesView(P2PService p2pService, List<ResourceModel> filteredResources) {
    return Column(
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
                  backgroundColor: BeaconColors.surface(context),
                  selectedColor: BeaconColors.primary.withOpacity(0.2),
                ),
              );
            },
          ),
        ),

        // Resource Statistics
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
          decoration: BoxDecoration(
            color: BeaconColors.surface(context),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
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
                color: BeaconColors.border(context),
              ),
              _buildStatItem(
                icon: Icons.check_circle,
                label: 'Available',
                value: '${filteredResources.where((r) => r.status != 'Unavailable').length}',
              ),
              Container(
                width: 1,
                height: 40,
                color: BeaconColors.border(context),
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
          child: filteredResources.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.inventory_2_outlined, size: 64, color: BeaconColors.textSecondary(context)),
                      const SizedBox(height: 16),
                      Text(
                        'No resources available',
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Tap the people icon to request resources from connected devices',
                        style: Theme.of(context).textTheme.bodySmall,
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                )
              : ListView.builder(
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
            color: BeaconColors.surface(context),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
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

  void _requestResource(ResourceModel resource, P2PService p2pService) {
    // Find the endpointId for this resource
    String? endpointId;
    if (resource.deviceId != null) {
      for (var device in p2pService.connectedDevices) {
        // Check both device.id and endpointId to match
        if (device.id == resource.deviceId || device.endpointId == resource.deviceId) {
          endpointId = device.endpointId;
          break;
        }
      }
    }
    
    if (endpointId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Device not found. Please ensure the device is connected.'),
          backgroundColor: BeaconColors.error,
        ),
      );
      return;
    }
    
    // If quantity > 1, show quantity selector
    if (resource.quantity > 1) {
      final quantityController = TextEditingController(text: '1');
      
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Request Resource'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Resource: ${resource.name}'),
              const SizedBox(height: 16),
              Text('Available Quantity: ${resource.quantity}'),
              const SizedBox(height: 16),
              TextField(
                controller: quantityController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Requested Quantity',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                final requestedQty = int.tryParse(quantityController.text);
                if (requestedQty == null || requestedQty <= 0) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Please enter a valid quantity'),
                      backgroundColor: BeaconColors.error,
                    ),
                  );
                  return;
                }
                if (requestedQty > resource.quantity) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Quantity cannot exceed ${resource.quantity}'),
                      backgroundColor: BeaconColors.error,
                    ),
                  );
                  return;
                }
                
                Navigator.pop(context);
                if (endpointId != null) {
                  p2pService.requestSpecificResource(
                    endpointId,
                    resource.id,
                    requestedQty,
                    p2pService.localDeviceName ?? 'Unknown',
                  );
                }
                
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Request sent for ${resource.name} (Qty: $requestedQty)'),
                    backgroundColor: BeaconColors.success,
                  ),
                );
              },
              child: const Text('Send Request'),
            ),
          ],
        ),
      );
    } else {
      // Quantity is 1, just confirm
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
                if (endpointId != null) {
                  p2pService.requestSpecificResource(
                    endpointId,
                    resource.id,
                    1,
                    p2pService.localDeviceName ?? 'Unknown',
                  );
                }
                
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Request sent for ${resource.name}'),
                    backgroundColor: BeaconColors.success,
                  ),
                );
              },
              child: const Text('Confirm'),
            ),
          ],
        ),
      );
    }
  }

  void _showResourceRequestDialog(Map<String, dynamic> requestData) {
    final resource = requestData['resource'] as ResourceModel;
    final requestedQuantity = requestData['requestedQuantity'] as int;
    final requesterName = requestData['requesterName'] as String;
    final endpointId = requestData['endpointId'] as String;
    final resourceId = requestData['resourceId'] as String;
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Resource Request'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('$requesterName is requesting:'),
            const SizedBox(height: 8),
            Text(
              '${resource.name}',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 4),
            Text('Quantity: $requestedQuantity / ${resource.quantity}'),
            const SizedBox(height: 4),
            Text('Location: ${resource.location}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              final p2pService = Provider.of<P2PService>(context, listen: false);
              p2pService.respondToResourceRequest(endpointId, resourceId, false, 0, requesterName);
              
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Request denied'),
                  backgroundColor: BeaconColors.warning,
                ),
              );
            },
            child: const Text('Deny'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              final p2pService = Provider.of<P2PService>(context, listen: false);
              
              // Update resource
              p2pService.updateResourceAfterApproval(resourceId, requestedQuantity, requesterName);
              
              // Send response
              p2pService.respondToResourceRequest(endpointId, resourceId, true, requestedQuantity, requesterName);
              
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Request approved! ${resource.name} provided to $requesterName'),
                  backgroundColor: BeaconColors.success,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: BeaconColors.success,
            ),
            child: const Text('Approve'),
          ),
        ],
      ),
    );
  }

  void _showAddResourceDialog() {
    final p2pService = Provider.of<P2PService>(context, listen: false);
    final nameController = TextEditingController();
    final quantityController = TextEditingController();
    final locationController = TextEditingController();
    String selectedCategory = 'Medical';

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
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
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (nameController.text.isEmpty ||
                  quantityController.text.isEmpty ||
                  locationController.text.isEmpty) {
                ScaffoldMessenger.of(dialogContext).showSnackBar(
                  const SnackBar(
                    content: Text('Please fill all fields'),
                    backgroundColor: BeaconColors.error,
                  ),
                );
                return;
              }

              final quantity = int.tryParse(quantityController.text);
              if (quantity == null || quantity <= 0) {
                ScaffoldMessenger.of(dialogContext).showSnackBar(
                  const SnackBar(
                    content: Text('Please enter a valid quantity'),
                    backgroundColor: BeaconColors.error,
                  ),
                );
                return;
              }

              final newResource = ResourceModel(
                id: DateTime.now().millisecondsSinceEpoch.toString(),
                name: nameController.text,
                category: selectedCategory,
                quantity: quantity,
                location: locationController.text,
                provider: p2pService.localDeviceName ?? 'Unknown',
                status: 'Available',
              );

              // Broadcast to network (this will also add it to _networkResources)
              p2pService.broadcastResource(newResource);

              Navigator.pop(dialogContext);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Resource shared successfully'),
                  backgroundColor: BeaconColors.success,
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