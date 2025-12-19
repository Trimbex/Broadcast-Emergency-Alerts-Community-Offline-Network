import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../widgets/common/theme_toggle_button.dart';
import '../widgets/resource_sharing_page/resource_card.dart';
import '../widgets/resource_sharing_page/stat_item.dart';
import '../models/resource_model.dart';
import '../services/p2p_service.dart';
import '../viewmodels/resource_sharing_viewmodel.dart';
import '../theme/beacon_colors.dart';

class ResourceSharingPage extends StatefulWidget {
  const ResourceSharingPage({super.key});

  @override
  State<ResourceSharingPage> createState() => _ResourceSharingPageState();
}

class _ResourceSharingPageState extends State<ResourceSharingPage> {
  ResourceSharingViewModel? _viewModel;

  @override
  void initState() {
    super.initState();
    final p2pService = Provider.of<P2PService>(context, listen: false);
    _viewModel = ResourceSharingViewModel(p2pService: p2pService);
    _viewModel!.initialize();
  }

  @override
  void dispose() {
    _viewModel?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_viewModel == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return ChangeNotifierProvider<ResourceSharingViewModel>.value(
      value: _viewModel!,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Resource Sharing'),
          actions: const [
            ThemeToggleButton(isCompact: true),
            SizedBox(width: 8),
          ],
        ),
        body: Consumer2<ResourceSharingViewModel, P2PService>(
          builder: (context, viewModel, p2pService, child) {
            // Listen to resource requests
            viewModel.resourceRequestStream.listen((requestData) {
              if (mounted) {
                _showResourceRequestDialog(requestData);
              }
            });

            return _buildResourcesView(viewModel, p2pService, viewModel.filteredResources);
          },
        ),
      ),
    );
  }


  Widget _buildResourcesView(
    ResourceSharingViewModel viewModel,
    P2PService p2pService,
    List<ResourceModel> filteredResources,
  ) {
    return Column(
      children: [
        // Category Filter
        Container(
          height: 60,
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: viewModel.categories.length,
            itemBuilder: (context, index) {
              final category = viewModel.categories[index];
              final isSelected = category == viewModel.selectedCategory;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: FilterChip(
                  label: Text(category),
                  selected: isSelected,
                  onSelected: (selected) {
                    viewModel.setCategory(category);
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
              ResourceStatItem(
                icon: Icons.inventory,
                label: 'Total Items',
                value: '${filteredResources.length}',
              ),
              Container(
                width: 1,
                height: 40,
                color: BeaconColors.border(context),
              ),
              ResourceStatItem(
                icon: Icons.check_circle,
                label: 'Available',
                value: '${filteredResources.where((r) => r.status != 'Unavailable').length}',
              ),
              Container(
                width: 1,
                height: 40,
                color: BeaconColors.border(context),
              ),
              ResourceStatItem(
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
                  child: SingleChildScrollView(
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
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: filteredResources.length,
                  itemBuilder: (context, index) {
                    final resource = filteredResources[index];
                    return ResourceCard(
                      resource: resource,
                      p2pService: p2pService,
                      onRequest: () => _requestResource(resource, p2pService),
                    );
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
            ],
          ),
        ),
      ],
    );
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
    final viewModel = _viewModel;
    if (viewModel == null) return;

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
                items: viewModel.categories
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