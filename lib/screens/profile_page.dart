import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../widgets/common/theme_toggle_button.dart';
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
    _initializeDeviceId();
    _loadProfileData();
  }

  void _initializeDeviceId() {
    try {
      final p2pService = Provider.of<P2PService>(context, listen: false);
      _deviceId = p2pService.localDeviceId ?? DateTime.now().millisecondsSinceEpoch.toString();
      debugPrint('📱 Initialized device ID: $_deviceId');
    } catch (e) {
      debugPrint('❌ Error initializing device ID: $e');
      _deviceId = DateTime.now().millisecondsSinceEpoch.toString();
    }
  }

  Future<void> _loadProfileData() async {
    try {
      debugPrint('📱 _loadProfileData called with device ID: $_deviceId');

      // Load user profile
      final profile = await DatabaseService.instance.getUserProfile();
      List<Map<String, dynamic>> contacts = [];

      // Load emergency contacts using the initialized device ID
      if (_deviceId != null) {
        contacts = await DatabaseService.instance.getEmergencyContacts(_deviceId!);
        debugPrint('📱 Loaded ${contacts.length} emergency contacts from database');
        for (var contact in contacts) {
          debugPrint('   - ${contact['name']} (${contact['phone']})');
        }
      }

      // Update state with all loaded data at once
      if (mounted) {
        setState(() {
          if (profile != null) {
            _nameController.text = profile['name']?.toString() ?? '';
            _phoneController.text = profile['phone']?.toString() ?? '';
            _bloodTypeController.text = profile['blood_type']?.toString() ?? '';
            _medicalConditionsController.text = profile['medical_conditions']?.toString() ?? '';
          }

          _emergencyContacts = contacts.map((contact) {
            try {
              return EmergencyContact(
                id: contact['id'] as int,
                name: contact['name'] as String,
                relation: contact['relation'] as String? ?? '',
                phone: contact['phone'] as String,
              );
            } catch (e) {
              debugPrint('❌ Error parsing contact: $e');
              rethrow;
            }
          }).toList();

          debugPrint('✅ Emergency contacts updated in state: ${_emergencyContacts.map((c) => c.name).toList()}');
          debugPrint('✅ Emergency contacts count: ${_emergencyContacts.length}');
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('❌ Error loading profile: $e');
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading profile: $e'),
            backgroundColor: BeaconColors.error,
          ),
        );
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

  // Validation helper methods
  String? _validatePhoneNumber(String phone) {
    if (phone.isEmpty) {
      return 'Phone number is required';
    }
    if (!RegExp(r'^[0-9]+$').hasMatch(phone)) {
      return 'Phone number must contain only digits';
    }
    if (phone.length < 7) {
      return 'Phone number must be at least 7 digits';
    }
    return null;
  }

  String? _getPhoneErrorText(String phone) {
    if (phone.isEmpty) return null;
    return _validatePhoneNumber(phone);
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
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [ThemeToggleButton(isCompact: true), IconButton(icon: Icon(Icons.save), onPressed: _saveProfile)],
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
                  _emergencyContacts.isEmpty
                      ? Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: BeaconColors.primary.withValues(alpha: 0.3),
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.contacts_outlined,
                                size: 48,
                                color: BeaconColors.primary.withValues(alpha: 0.5),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                'No emergency contacts added yet',
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: BeaconColors.primary.withValues(alpha: 0.7),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Add at least one emergency contact for quick access',
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: Colors.grey,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        )
                      : GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 1,
                            childAspectRatio: 3.5,
                            crossAxisSpacing: 12,
                            mainAxisSpacing: 12,
                          ),
                          itemCount: _emergencyContacts.length,
                          itemBuilder: (context, index) {
                            final contact = _emergencyContacts[index];
                            return GestureDetector(
                              onLongPress: () => _editEmergencyContact(index),
                              child: Card(
                                elevation: 2,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Container(
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(12),
                                    gradient: LinearGradient(
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                      colors: BeaconColors.accentGradient(context),
                                    ),
                                  ),
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Container(
                                              width: 40,
                                              height: 40,
                                              decoration: BoxDecoration(
                                                shape: BoxShape.circle,
                                                color: Colors.white.withValues(alpha: 0.2),
                                              ),
                                              child: Center(
                                                child: Text(
                                                  contact.name[0].toUpperCase(),
                                                  style: const TextStyle(
                                                    color: Colors.white,
                                                    fontSize: 16,
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                ),
                                              ),
                                            ),
                                            Expanded(
                                              child: Padding(
                                                padding: const EdgeInsets.symmetric(horizontal: 12),
                                                child: Column(
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  mainAxisAlignment: MainAxisAlignment.center,
                                                  children: [
                                                    Text(
                                                      contact.name,
                                                      style: const TextStyle(
                                                        color: Colors.white,
                                                        fontSize: 14,
                                                        fontWeight: FontWeight.w600,
                                                      ),
                                                      maxLines: 1,
                                                      overflow: TextOverflow.ellipsis,
                                                    ),
                                                    const SizedBox(height: 2),
                                                    Text(
                                                      contact.relation.isNotEmpty ? contact.relation : 'No relation',
                                                      style: TextStyle(
                                                        color: Colors.white.withValues(alpha: 0.7),
                                                        fontSize: 11,
                                                      ),
                                                      maxLines: 1,
                                                      overflow: TextOverflow.ellipsis,
                                                    ),
                                                    const SizedBox(height: 2),
                                                    Text(
                                                      contact.phone,
                                                      style: TextStyle(
                                                        color: Colors.white.withValues(alpha: 0.8),
                                                        fontSize: 11,
                                                        fontWeight: FontWeight.w500,
                                                      ),
                                                      maxLines: 1,
                                                      overflow: TextOverflow.ellipsis,
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                            PopupMenuButton<String>(
                                              onSelected: (value) {
                                                if (value == 'edit') {
                                                  _editEmergencyContact(index);
                                                } else if (value == 'delete') {
                                                  _deleteEmergencyContact(index);
                                                }
                                              },
                                              itemBuilder: (context) => [
                                                const PopupMenuItem(
                                                  value: 'edit',
                                                  child: Row(
                                                    children: [
                                                      Icon(Icons.edit, size: 16),
                                                      SizedBox(width: 8),
                                                      Text('Edit'),
                                                    ],
                                                  ),
                                                ),
                                                const PopupMenuItem(
                                                  value: 'delete',
                                                  child: Row(
                                                    children: [
                                                      Icon(Icons.delete, size: 16),
                                                      SizedBox(width: 8),
                                                      Text('Delete'),
                                                    ],
                                                  ),
                                                ),
                                              ],
                                              icon: const Icon(
                                                Icons.more_vert,
                                                color: Colors.white,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            );
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
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Add Emergency Contact'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: InputDecoration(
                    labelText: 'Name *',
                    border: const OutlineInputBorder(),
                    hintText: 'Enter contact name',
                    errorText: null,
                  ),
                  onChanged: (value) => setState(() {}),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: relationController,
                  decoration: InputDecoration(
                    labelText: 'Relation',
                    border: const OutlineInputBorder(),
                    hintText: 'e.g., Mother, Father, Friend',
                    errorText: null,
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: InputDecoration(
                    labelText: 'Phone Number *',
                    border: const OutlineInputBorder(),
                    hintText: 'Enter phone number (digits only)',
                    errorText: _getPhoneErrorText(phoneController.text),
                  ),
                  onChanged: (value) => setState(() {}),
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
              onPressed: () async {
                final nameError = nameController.text.trim().isEmpty ? 'Name is required' : null;
                final phoneError = _validatePhoneNumber(phoneController.text.trim());

                if (nameError != null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(nameError),
                      backgroundColor: BeaconColors.error,
                    ),
                  );
                  return;
                }

                if (phoneError != null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(phoneError),
                      backgroundColor: BeaconColors.error,
                    ),
                  );
                  return;
                }

                try {
                  // Use the state's context, not the dialog's context
                  final mainContext = this.context;
                  final p2pService = Provider.of<P2PService>(mainContext, listen: false);
                  final deviceId = p2pService.localDeviceId ?? _deviceId ?? DateTime.now().millisecondsSinceEpoch.toString();

                  debugPrint('📱 Adding emergency contact with deviceId: $deviceId');
                  debugPrint('📱 Contact: ${nameController.text.trim()}, ${phoneController.text.trim()}');

                  await DatabaseService.instance.saveEmergencyContact(
                    name: nameController.text.trim(),
                    relation: relationController.text.trim(),
                    phone: phoneController.text.trim(),
                    deviceId: deviceId,
                  );

                  debugPrint('✅ Contact saved to database');

                  // Pop the dialog first
                  if (mounted) {
                    Navigator.pop(context);
                  }

                  // Then reload the data
                  if (mounted) {
                    await _loadProfileData();
                    debugPrint('✅ Profile data reloaded, contacts count: ${_emergencyContacts.length}');
                  }

                  // Show success message
                  if (mounted) {
                    ScaffoldMessenger.of(mainContext).showSnackBar(
                      const SnackBar(
                        content: Text('Emergency contact added successfully'),
                        backgroundColor: BeaconColors.success,
                      ),
                    );
                  }
                } catch (e) {
                  debugPrint('❌ Error adding contact: $e');
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
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Edit Emergency Contact'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: InputDecoration(
                    labelText: 'Name *',
                    border: const OutlineInputBorder(),
                    hintText: 'Enter contact name',
                    errorText: null,
                  ),
                  onChanged: (value) => setState(() {}),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: relationController,
                  decoration: InputDecoration(
                    labelText: 'Relation',
                    border: const OutlineInputBorder(),
                    hintText: 'e.g., Mother, Father, Friend',
                    errorText: null,
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: InputDecoration(
                    labelText: 'Phone Number *',
                    border: const OutlineInputBorder(),
                    hintText: 'Enter phone number (digits only)',
                    errorText: _getPhoneErrorText(phoneController.text),
                  ),
                  onChanged: (value) => setState(() {}),
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
              onPressed: () async {
                final nameError = nameController.text.trim().isEmpty ? 'Name is required' : null;
                final phoneError = _validatePhoneNumber(phoneController.text.trim());

                if (nameError != null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(nameError),
                      backgroundColor: BeaconColors.error,
                    ),
                  );
                  return;
                }

                if (phoneError != null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(phoneError),
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

                  debugPrint('✅ Contact updated in database');

                  // Pop the dialog first
                  if (mounted) {
                    Navigator.pop(context);
                  }

                  // Then reload the data
                  if (mounted) {
                    await _loadProfileData(); // Reload to refresh the list
                    debugPrint('✅ Profile data reloaded after update');
                  }

                  // Show success message
                  if (mounted) {
                    ScaffoldMessenger.of(this.context).showSnackBar(
                      const SnackBar(
                        content: Text('Emergency contact updated successfully'),
                        backgroundColor: BeaconColors.success,
                      ),
                    );
                  }
                } catch (e) {
                  debugPrint('❌ Error updating contact: $e');
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