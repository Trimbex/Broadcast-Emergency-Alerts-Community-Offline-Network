import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../widgets/voice_command_button.dart';
import '../models/resource_model.dart';
import '../models/device_model.dart' as device_model;
import '../services/p2p_service.dart';

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
  
  // Track which devices we're requesting resources from
  final Set<String> _requestingFromDevices = {};
  
  // Show devices section
  bool _showDevices = false;

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
        actions: [
          IconButton(
            icon: Icon(_showDevices ? Icons.list : Icons.people),
            onPressed: () {
              setState(() {
                _showDevices = !_showDevices;
              });
            },
            tooltip: _showDevices ? 'Show Resources' : 'Show Devices',
          ),
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              // Search functionality
            },
          ),
        ],
      ),
      body: _showDevices ? _buildDevicesView(p2pService) : _buildResourcesView(p2pService, filteredResources),
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
    final p2pService = Provider.of<P2PService>(context, listen: false);
    final IconData categoryIcon = _getCategoryIcon(resource.category);
    final Color statusColor = resource.status == 'Available' 
        ? const Color(0xFF4CAF50) 
        : const Color(0xFFFF9800);
    
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
                                color: Colors.blue[50],
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: Colors.blue[200]!,
                                  width: 1,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.network_check,
                                    size: 12,
                                    color: Colors.blue[700],
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Network',
                                    style: TextStyle(
                                      color: Colors.blue[700],
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
            // Only show request button if resource is not from current user
            if (isFromNetwork && resource.status != 'Unavailable')
              SizedBox(
                width: double.infinity,
                height: 44,
                child: ElevatedButton(
                  onPressed: () => _requestResource(resource, p2pService),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1976D2),
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
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.info_outline, size: 18, color: Colors.grey[600]),
                    const SizedBox(width: 8),
                    Text(
                      'Your Resource',
                      style: TextStyle(
                        color: Colors.grey[700],
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildDevicesView(P2PService p2pService) {
    final connectedDevices = p2pService.connectedDevices;
    
    if (connectedDevices.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.people_outline, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'No devices connected',
              style: TextStyle(fontSize: 18, color: Colors.grey[600]),
            ),
            const SizedBox(height: 8),
            Text(
              'Connect to devices in the Network Dashboard',
              style: TextStyle(fontSize: 14, color: Colors.grey[500]),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }
    
    return Column(
      children: [
        // Header
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.blue[50],
            border: Border(
              bottom: BorderSide(color: Colors.grey[300]!),
            ),
          ),
          child: Row(
            children: [
              Icon(Icons.info_outline, color: Colors.blue[700], size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Tap on a device to request their resources',
                  style: TextStyle(
                    color: Colors.blue[900],
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
        ),
        
        // Devices List
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: connectedDevices.length,
            itemBuilder: (context, index) {
              return _buildDeviceCard(connectedDevices[index], p2pService);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildDeviceCard(device_model.DeviceModel device, P2PService p2pService) {
    final isRequesting = _requestingFromDevices.contains(device.endpointId);
    final hasResources = device.endpointId != null 
        ? p2pService.getResourcesByEndpointId(device.endpointId!).isNotEmpty
        : false;
    
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: isRequesting ? null : () => _requestResourcesFromDevice(device, p2pService),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Avatar
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF1976D2), Color(0xFF42A5F5)],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(
                    device.name.isNotEmpty ? device.name[0].toUpperCase() : '?',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              
              // Device Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      device.name,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.location_on, size: 14, color: Colors.grey[600]),
                        const SizedBox(width: 4),
                        Text(
                          device.distance,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                        if (hasResources) ...[
                          const SizedBox(width: 12),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.green[100],
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.inventory, size: 12, color: Colors.green[700]),
                                const SizedBox(width: 4),
                                Text(
                                  '${device.endpointId != null ? p2pService.getResourcesByEndpointId(device.endpointId!).length : 0} resources',
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: Colors.green[700],
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              
              // Action Button
              if (isRequesting)
                const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              else
                IconButton(
                  icon: const Icon(Icons.download),
                  onPressed: () => _requestResourcesFromDevice(device, p2pService),
                  tooltip: 'Request resources',
                ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _requestResourcesFromDevice(device_model.DeviceModel device, P2PService p2pService) async {
    if (device.endpointId == null) return;
    
    setState(() {
      _requestingFromDevices.add(device.endpointId!);
    });
    
    try {
      await p2pService.requestResourcesFromDevice(device.endpointId!);
      
      // Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Requested resources from ${device.name}'),
            duration: const Duration(seconds: 2),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to request resources: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _requestingFromDevices.remove(device.endpointId!);
        });
      }
    }
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
          child: filteredResources.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.inventory_2_outlined, size: 64, color: Colors.grey[400]),
                      const SizedBox(height: 16),
                      Text(
                        'No resources available',
                        style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Tap the people icon to request resources from connected devices',
                        style: TextStyle(fontSize: 14, color: Colors.grey[500]),
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
          backgroundColor: Colors.red,
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
                      backgroundColor: Colors.red,
                    ),
                  );
                  return;
                }
                if (requestedQty > resource.quantity) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Quantity cannot exceed ${resource.quantity}'),
                      backgroundColor: Colors.red,
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
                    backgroundColor: Colors.green,
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
                  backgroundColor: Colors.orange,
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
                  backgroundColor: Colors.green,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
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
                    backgroundColor: Colors.red,
                  ),
                );
                return;
              }

              final quantity = int.tryParse(quantityController.text);
              if (quantity == null || quantity <= 0) {
                ScaffoldMessenger.of(dialogContext).showSnackBar(
                  const SnackBar(
                    content: Text('Please enter a valid quantity'),
                    backgroundColor: Colors.red,
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