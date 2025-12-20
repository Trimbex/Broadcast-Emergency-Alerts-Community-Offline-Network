import 'dart:convert';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import '../models/message_model.dart';
import '../models/resource_model.dart';
import 'encryption_service.dart';

class DatabaseService {
  static final DatabaseService instance = DatabaseService._init();
  static Database? _database;

  DatabaseService._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('beacon_database.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 2,
      onCreate: _createDB,
      onUpgrade: _upgradeDB,
    );
  }

  Future<void> _upgradeDB(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      // Add new columns to user_profile table
      try {
        await db.execute('ALTER TABLE user_profile ADD COLUMN phone TEXT');
        await db.execute('ALTER TABLE user_profile ADD COLUMN blood_type TEXT');
        await db.execute('ALTER TABLE user_profile ADD COLUMN medical_conditions TEXT');
      } catch (e) {
        // Columns might already exist, ignore error
      }

      // Create emergency_contacts table if it doesn't exist
      try {
        await db.execute('''
          CREATE TABLE IF NOT EXISTS emergency_contacts (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT NOT NULL,
            relation TEXT,
            phone TEXT NOT NULL,
            device_id TEXT NOT NULL,
            created_at INTEGER NOT NULL,
            updated_at INTEGER NOT NULL
          )
        ''');
      } catch (e) {
        // Table might already exist, ignore error
      }

      // Alter emergency_contacts table to make relation nullable
      try {
        await db.execute('ALTER TABLE emergency_contacts MODIFY relation TEXT');
      } catch (e) {
        // Column might already be nullable, ignore error
      }
    }
  }

  Future<void> _createDB(Database db, int version) async {
    // User Profile Table
    await db.execute('''
      CREATE TABLE user_profile (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        role TEXT,
        phone TEXT,
        blood_type TEXT,
        medical_conditions TEXT,
        device_id TEXT UNIQUE NOT NULL,
        created_at INTEGER NOT NULL,
        updated_at INTEGER NOT NULL
      )
    ''');

    // Emergency Contacts Table
    await db.execute('''
      CREATE TABLE emergency_contacts (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        relation TEXT,
        phone TEXT NOT NULL,
        device_id TEXT NOT NULL,
        created_at INTEGER NOT NULL,
        updated_at INTEGER NOT NULL
      )
    ''');

    // Messages Table
    await db.execute('''
      CREATE TABLE messages (
        id TEXT PRIMARY KEY,
        conversation_id TEXT NOT NULL,
        sender_id TEXT NOT NULL,
        sender_name TEXT,
        text TEXT NOT NULL,
        timestamp INTEGER NOT NULL,
        is_me INTEGER NOT NULL,
        is_emergency INTEGER NOT NULL,
        message_type TEXT DEFAULT 'text',
        metadata TEXT
      )
    ''');

    // User Resources Table
    await db.execute('''
      CREATE TABLE user_resources (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        category TEXT NOT NULL,
        quantity INTEGER NOT NULL,
        location TEXT NOT NULL,
        provider TEXT NOT NULL,
        status TEXT NOT NULL,
        device_id TEXT NOT NULL,
        created_at INTEGER NOT NULL,
        updated_at INTEGER NOT NULL
      )
    ''');
  }

  // --- User Profile Operations ---

  Future<void> saveUserProfile({
    required String name,
    String? role,
    required String deviceId,
    String? phone,
    String? bloodType,
    String? medicalConditions,
  }) async {
    final db = await instance.database;
    final now = DateTime.now().millisecondsSinceEpoch;

    // Check if profile exists
    final result = await db.query('user_profile');
    
    final data = {
      'name': name,
      'role': role ?? '',
      'phone': phone != null ? EncryptionService.instance.encrypt(phone) : '',
      'blood_type': bloodType != null ? EncryptionService.instance.encrypt(bloodType) : '',
      'medical_conditions': medicalConditions != null ? EncryptionService.instance.encrypt(medicalConditions) : '',
      'device_id': deviceId,
      'updated_at': now,
    };
    
    if (result.isEmpty) {
      data['created_at'] = now;
      await db.insert('user_profile', data);
    } else {
      await db.update(
        'user_profile',
        data,
        where: 'id = ?',
        whereArgs: [result.first['id']],
      );
    }
  }

  Future<Map<String, dynamic>?> getUserProfile() async {
    final db = await instance.database;
    final result = await db.query('user_profile');
    if (result.isNotEmpty) {
      final profile = Map<String, dynamic>.from(result.first);
      // Decrypt sensitive fields
      if (profile['phone'] != null) profile['phone'] = EncryptionService.instance.decrypt(profile['phone']);
      if (profile['blood_type'] != null) profile['blood_type'] = EncryptionService.instance.decrypt(profile['blood_type']);
      if (profile['medical_conditions'] != null) profile['medical_conditions'] = EncryptionService.instance.decrypt(profile['medical_conditions']);
      return profile;
    }
    return null;
  }

  // --- Emergency Contacts Operations ---

  Future<void> saveEmergencyContact({
    required String name,
    required String relation,
    required String phone,
    required String deviceId,
  }) async {
    final db = await instance.database;
    final now = DateTime.now().millisecondsSinceEpoch;

    await db.insert('emergency_contacts', {
      'name': name,
      'relation': relation,
      'phone': EncryptionService.instance.encrypt(phone),
      'device_id': deviceId,
      'created_at': now,
      'updated_at': now,
    });
  }

  Future<List<Map<String, dynamic>>> getEmergencyContacts(String deviceId) async {
    final db = await instance.database;
    final result = await db.query(
      'emergency_contacts',
      where: 'device_id = ?',
      whereArgs: [deviceId],
      orderBy: 'created_at ASC',
    );
    return result.map((contact) {
      final decrypted = Map<String, dynamic>.from(contact);
      if (decrypted['phone'] != null) decrypted['phone'] = EncryptionService.instance.decrypt(decrypted['phone']);
      return decrypted;
    }).toList();
  }

  Future<void> updateEmergencyContact({
    required int id,
    required String name,
    required String relation,
    required String phone,
  }) async {
    final db = await instance.database;
    final now = DateTime.now().millisecondsSinceEpoch;

    await db.update(
      'emergency_contacts',
      {
        'name': name,
        'relation': relation,
        'phone': EncryptionService.instance.encrypt(phone),
        'updated_at': now,
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> deleteEmergencyContact(int id) async {
    final db = await instance.database;
    await db.delete(
      'emergency_contacts',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // --- Message Operations ---

  Future<void> saveMessage(MessageModel message, String conversationId) async {
    final db = await instance.database;
    await db.insert(
      'messages',
      {
        'id': message.id,
        'conversation_id': conversationId,
        'sender_id': message.senderId,
        'sender_name': message.senderName,
        'text': EncryptionService.instance.encrypt(message.text),
        'timestamp': message.timestamp.millisecondsSinceEpoch,
        'is_me': message.isMe ? 1 : 0,
        'is_emergency': message.isEmergency ? 1 : 0,
        'message_type': message.messageType,
        'metadata': message.metadata != null ? jsonEncode(message.metadata) : null,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<MessageModel>> getMessages(String conversationId) async {
    final db = await instance.database;
    final result = await db.query(
      'messages',
      where: 'conversation_id = ?',
      whereArgs: [conversationId],
      orderBy: 'timestamp ASC',
    );

    return result.map((json) => MessageModel(
      id: json['id'] as String,
      senderId: json['sender_id'] as String,
      text: EncryptionService.instance.decrypt(json['text'] as String),
      timestamp: DateTime.fromMillisecondsSinceEpoch(json['timestamp'] as int),
      isMe: (json['is_me'] as int) == 1,
      senderName: json['sender_name'] as String?,
      isEmergency: (json['is_emergency'] as int) == 1,
      messageType: json['message_type'] as String?,
      metadata: json['metadata'] != null ? jsonDecode(json['metadata'] as String) : null,
    )).toList();
  }

  // --- Resource Operations ---

  Future<void> saveUserResource(ResourceModel resource) async {
    final db = await instance.database;
    final now = DateTime.now().millisecondsSinceEpoch;
    
    // Check if exists to determine created_at
    final exists = await db.query('user_resources', where: 'id = ?', whereArgs: [resource.id]);
    
    final data = {
      'id': resource.id,
      'name': resource.name,
      'category': resource.category,
      'quantity': resource.quantity,
      'location': resource.location,
      'provider': resource.provider,
      'status': resource.status,
      'device_id': resource.deviceId ?? 'unknown',
      'updated_at': now,
    };

    if (exists.isEmpty) {
      data['created_at'] = now;
      await db.insert('user_resources', data);
    } else {
       // Keep original created_at
      data['created_at'] = exists.first['created_at'] as int;
      await db.update(
        'user_resources',
        data,
        where: 'id = ?',
        whereArgs: [resource.id],
      );
    }
  }

  Future<List<ResourceModel>> getUserResources(String deviceId) async {
    final db = await instance.database;
    final result = await db.query(
      'user_resources',
      where: 'device_id = ?',
      whereArgs: [deviceId],
      orderBy: 'updated_at DESC',
    );

    return result.map((json) => ResourceModel(
      id: json['id'] as String,
      name: json['name'] as String,
      category: json['category'] as String,
      quantity: json['quantity'] as int,
      location: json['location'] as String,
      provider: json['provider'] as String,
      status: json['status'] as String,
      deviceId: json['device_id'] as String?,
    )).toList();
  }
  
  Future<void> deleteResource(String resourceId) async {
    final db = await instance.database;
    await db.delete(
      'user_resources',
      where: 'id = ?',
      whereArgs: [resourceId],
    );
  }

  Future<void> close() async {
    final db = _database;
    if (db != null) {
      await db.close();
    }
  }
}

