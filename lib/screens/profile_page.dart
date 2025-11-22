import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../widgets/voice_command_button.dart';
import '../widgets/theme_toggle_button.dart';
import '../theme/beacon_colors.dart';
import '../services/theme_service.dart';
import '../services/database_service.dart';
import '../services/p2p_service.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _bloodTypeController = TextEditingController();
  final TextEditingController _medicalConditionsController = TextEditingController();

  List<EmergencyContact> _emergencyContacts = [];
  bool _isLoading = true;
  String? _deviceId;

  @override
  void initState() {
    super.initState();
    _loadProfileData();
  }

  Future<void> _loadProfileData() async {
    setState(() => _isLoading = true);

    try {
      // Get device ID from P2P service or generate one
      final p2pService = Provider.of<P2PService>(context, listen: false);
      _deviceId = p2pService.localDeviceId ?? DateTime.now().millisecondsSinceEpoch.toString();

      // Load user profile
      final profile = await DatabaseService.instance.getUserProfile();
      if (profile != null) {
        _nameController.text = profile['name']?.toString() ?? '';
        _phoneController.text = profile['phone']?.toString() ?? '';
        _bloodTypeController.text = profile['blood_type']?.toString() ?? '';
        _medicalConditionsController.text = profile['medical_conditions']?.toString() ?? '';
      }

      // Load emergency contacts
      if (_deviceId != null) {
        final contacts = await DatabaseService.instance.getEmergencyContacts(_deviceId!);
        _emergencyContacts = contacts.map((contact) => EmergencyContact(
          id: contact['id'] as int,
          name: contact['name'] as String,
          relation: contact['relation'] as String,
          phone: contact['phone'] as String,
        )).toList();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading profile: $e'),
            backgroundColor: BeaconColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _bloodTypeController.dispose();
    _medicalConditionsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Profile & Emergency Contacts'),
          actions: const [
            ThemeToggleButton(isCompact: true),
          ],
        ),
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile & Emergency Contacts'),
        actions: [
          const ThemeToggleButton(isCompact: true),
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _saveProfile,
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Profile Header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: BeaconColors.accentGradient(context),
                ),
              ),
              child: Column(
                children: [
                  Stack(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.2),
                              blurRadius: 20,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: CircleAvatar(
                          radius: 50,
                          backgroundColor: BeaconColors.surface(context),
                          child: Icon(
                            Icons.person,
                            size: 50,
                            color: BeaconColors.primary,
                          ),
                        ),
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: Container(
                          decoration: BoxDecoration(
                            color: BeaconColors.surface(context),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.1),
                                blurRadius: 8,
                              ),
                            ],
                          ),
                          child: IconButton(
                            padding: const EdgeInsets.all(8),
                            icon: const Icon(
                              Icons.camera_alt,
                              size: 18,
                              color: BeaconColors.primary,
                            ),
                            onPressed: () {
                              // Upload photo functionality
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Emergency Profile',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: Colors.white,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),

            // Personal Information Section
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Personal Information',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: BeaconColors.primary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: 'Full Name',
                      prefixIcon: Icon(Icons.person),
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _phoneController,
                    decoration: const InputDecoration(
                      labelText: 'Phone Number',
                      prefixIcon: Icon(Icons.phone),
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _bloodTypeController,
                    decoration: const InputDecoration(
                      labelText: 'Blood Type',
                      prefixIcon: Icon(Icons.bloodtype),
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _medicalConditionsController,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      labelText: 'Medical Conditions / Allergies',
                      prefixIcon: Icon(Icons.medical_information),
                      border: OutlineInputBorder(),
                      hintText: 'Enter any medical conditions or allergies',
                    ),
                  ),
                ],
              ),
            ),

            const Divider(thickness: 1),

            // Emergency Contacts Section
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Emergency Contacts',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: BeaconColors.primary,
                        ),
                      ),
                      ElevatedButton.icon(
                        onPressed: _addEmergencyContact,
                        icon: const Icon(Icons.add),
                        label: const Text('Add'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _emergencyContacts.length,
                    itemBuilder: (context, index) {
                      return _buildContactCard(_emergencyContacts[index], index);
                    },
                  ),
                ],
              ),
            ),

            const Divider(thickness: 1),

            // Settings Section
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Settings',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: BeaconColors.primary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Consumer<ThemeService>(
                    builder: (context, themeService, child) {
                      return SwitchListTile(
                        title: const Text('Dark Mode'),
                        subtitle: Text(
                          themeService.themeMode == ThemeMode.system
                              ? 'Following system settings'
                              : themeService.themeMode == ThemeMode.dark
                                  ? 'Dark mode enabled'
                                  : 'Light mode enabled',
                        ),
                        value: themeService.isDarkMode,
                        onChanged: (value) {
                          themeService.toggleTheme();
                        },
                      );
                    },
                  ),
                  SwitchListTile(
                    title: const Text('Enable Voice Commands'),
                    subtitle: const Text('Use voice for hands-free operation'),
                    value: true,
                    onChanged: (value) {
                      setState(() {});
                    },
                  ),
                  SwitchListTile(
                    title: const Text('Auto-share Location'),
                    subtitle: const Text('Share location in emergencies'),
                    value: true,
                    onChanged: (value) {
                      setState(() {});
                    },
                  ),
                  SwitchListTile(
                    title: const Text('Silent Mode'),
                    subtitle: const Text('Receive alerts without sound'),
                    value: false,
                    onChanged: (value) {
                      setState(() {});
                    },
                  ),
                ],
              ),
            ),

            // Voice Command Button
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: VoiceCommandButton(),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildContactCard(EmergencyContact contact, int index) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: BeaconColors.accentGradient(context),
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Text(
                  contact.name[0],
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    contact.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    contact.relation,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    contact.phone,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.edit, size: 20),
              color: BeaconColors.primary,
              onPressed: () => _editEmergencyContact(index),
            ),
            IconButton(
              icon: const Icon(Icons.delete, size: 20),
              color: BeaconColors.error,
              onPressed: () => _deleteEmergencyContact(index),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _saveProfile() async {
    if (_nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter your name'),
          backgroundColor: BeaconColors.error,
        ),
      );
      return;
    }

    try {
      // Get device ID
      final p2pService = Provider.of<P2PService>(context, listen: false);
      final deviceId = p2pService.localDeviceId ?? _deviceId ?? DateTime.now().millisecondsSinceEpoch.toString();

      // Save user profile
      await DatabaseService.instance.saveUserProfile(
        name: _nameController.text.trim(),
        role: '', // Can be extended later
        deviceId: deviceId,
        phone: _phoneController.text.trim(),
        bloodType: _bloodTypeController.text.trim(),
        medicalConditions: _medicalConditionsController.text.trim(),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile saved successfully'),
            backgroundColor: BeaconColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving profile: $e'),
            backgroundColor: BeaconColors.error,
          ),
        );
      }
    }
  }

  Future<void> _addEmergencyContact() async {
    final nameController = TextEditingController();
    final relationController = TextEditingController();
    final phoneController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Emergency Contact'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Name',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: relationController,
              decoration: const InputDecoration(
                labelText: 'Relation',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: phoneController,
              decoration: const InputDecoration(
                labelText: 'Phone Number',
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
            onPressed: () async {
              if (nameController.text.trim().isEmpty ||
                  relationController.text.trim().isEmpty ||
                  phoneController.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Please fill all fields'),
                    backgroundColor: BeaconColors.error,
                  ),
                );
                return;
              }

              try {
                final p2pService = Provider.of<P2PService>(context, listen: false);
                final deviceId = p2pService.localDeviceId ?? _deviceId ?? DateTime.now().millisecondsSinceEpoch.toString();

                await DatabaseService.instance.saveEmergencyContact(
                  name: nameController.text.trim(),
                  relation: relationController.text.trim(),
                  phone: phoneController.text.trim(),
                  deviceId: deviceId,
                );

                Navigator.pop(context);
                await _loadProfileData(); // Reload to get the new contact with ID
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error adding contact: $e'),
                      backgroundColor: BeaconColors.error,
                    ),
                  );
                }
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  Future<void> _editEmergencyContact(int index) async {
    final contact = _emergencyContacts[index];
    final nameController = TextEditingController(text: contact.name);
    final relationController = TextEditingController(text: contact.relation);
    final phoneController = TextEditingController(text: contact.phone);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Emergency Contact'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Name',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: relationController,
              decoration: const InputDecoration(
                labelText: 'Relation',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: phoneController,
              decoration: const InputDecoration(
                labelText: 'Phone Number',
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
            onPressed: () async {
              if (nameController.text.trim().isEmpty ||
                  relationController.text.trim().isEmpty ||
                  phoneController.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Please fill all fields'),
                    backgroundColor: BeaconColors.error,
                  ),
                );
                return;
              }

              try {
                await DatabaseService.instance.updateEmergencyContact(
                  id: contact.id!,
                  name: nameController.text.trim(),
                  relation: relationController.text.trim(),
                  phone: phoneController.text.trim(),
                );

                Navigator.pop(context);
                await _loadProfileData(); // Reload to refresh the list
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error updating contact: $e'),
                      backgroundColor: BeaconColors.error,
                    ),
                  );
                }
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteEmergencyContact(int index) async {
    final contact = _emergencyContacts[index];
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Contact'),
        content: const Text('Are you sure you want to delete this emergency contact?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                if (contact.id != null) {
                  await DatabaseService.instance.deleteEmergencyContact(contact.id!);
                }
                
                Navigator.pop(context);
                await _loadProfileData(); // Reload to refresh the list
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error deleting contact: $e'),
                      backgroundColor: BeaconColors.error,
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: BeaconColors.error),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}

class EmergencyContact {
  final int? id;
  final String name;
  final String relation;
  final String phone;

  EmergencyContact({
    this.id,
    required this.name,
    required this.relation,
    required this.phone,
  });
}