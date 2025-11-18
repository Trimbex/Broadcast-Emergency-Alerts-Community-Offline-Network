import 'dart:io';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import 'package:encrypt/encrypt.dart' as encrypt_lib;
import 'package:crypto/crypto.dart';
import 'dart:convert';
import '../models/user_profile_model.dart';
import '../models/device_model.dart';
import '../models/resource_model.dart';
import '../models/network_activity_model.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;
  
  // Encryption key (in production, this should be stored securely)
  static const String _encryptionPassword = 'beacon_secure_key_2024';
  late encrypt_lib.Key _encryptionKey;
  late encrypt_lib.IV _iv;
  late encrypt_lib.Encrypter _encrypter;

  DatabaseHelper._init() {
    // Initialize encryption
    final keyBytes = sha256.convert(utf8.encode(_encryptionPassword)).bytes;
    _encryptionKey = encrypt_lib.Key.fromBase64(base64.encode(keyBytes));
    _iv = encrypt_lib.IV.fromLength(16);
    _encrypter = encrypt_lib.Encrypter(encrypt_lib.AES(_encryptionKey));
  }

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
      version: 1,
      onCreate: _createDB,
    );
  }

  Future<void> _createDB(Database db, int version) async {
    const idType = 'TEXT PRIMARY KEY';
    const textType = 'TEXT NOT NULL';
    const textTypeNullable = 'TEXT';
    const integerType = 'INTEGER NOT NULL';

    // User Profile Table
    await db.execute('''
      CREATE TABLE user_profiles (
        id $idType,
        name $textType,
        email $textTypeNullable,
        phoneNumber $textTypeNullable,
        emergencyContact $textTypeNullable,
        bloodType $textTypeNullable,
        medicalInfo $textTypeNullable,
        createdAt $integerType,
        updatedAt $integerType
      )
    ''');

    // Devices Table
    await db.execute('''
      CREATE TABLE devices (
        id $idType,
        name $textType,
        status $textType,
        distance $textType,
        batteryLevel $integerType,
        ipAddress $textTypeNullable,
        lastSeen $integerType,
        isConnected $integerType
      )
    ''');

    // Resources Table
    await db.execute('''
      CREATE TABLE resources (
        id $idType,
        name $textType,
        category $textType,
        quantity $integerType,
        location $textType,
        provider $textType,
        status $textType,
        providerId $textTypeNullable,
        createdAt $integerType,
        updatedAt $integerType
      )
    ''');

    // Network Activities Table
    await db.execute('''
      CREATE TABLE network_activities (
        id $idType,
        activityType $textType,
        deviceId $textType,
        deviceName $textType,
        details $textTypeNullable,
        timestamp $integerType
      )
    ''');
  }

  // User Profile Operations
  Future<UserProfileModel?> getUserProfile(String id) async {
    final db = await database;
    final maps = await db.query(
      'user_profiles',
      where: 'id = ?',
      whereArgs: [id],
    );

    if (maps.isEmpty) return null;
    return UserProfileModel.fromJson(maps.first);
  }

  Future<UserProfileModel?> getCurrentUserProfile() async {
    final db = await database;
    final maps = await db.query('user_profiles', limit: 1);
    
    if (maps.isEmpty) return null;
    return UserProfileModel.fromJson(maps.first);
  }

  Future<void> insertUserProfile(UserProfileModel profile) async {
    final db = await database;
    await db.insert(
      'user_profiles',
      profile.toJson(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> updateUserProfile(UserProfileModel profile) async {
    final db = await database;
    await db.update(
      'user_profiles',
      profile.toJson(),
      where: 'id = ?',
      whereArgs: [profile.id],
    );
  }

  // Device Operations
  Future<List<DeviceModel>> getAllDevices() async {
    final db = await database;
    final maps = await db.query('devices', orderBy: 'lastSeen DESC');
    return maps.map((map) => DeviceModel.fromJson(map)).toList();
  }

  Future<List<DeviceModel>> getConnectedDevices() async {
    final db = await database;
    final maps = await db.query(
      'devices',
      where: 'isConnected = ?',
      whereArgs: [1],
      orderBy: 'lastSeen DESC',
    );
    return maps.map((map) => DeviceModel.fromJson(map)).toList();
  }

  Future<void> insertDevice(DeviceModel device) async {
    final db = await database;
    await db.insert(
      'devices',
      device.toJson(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> updateDevice(DeviceModel device) async {
    final db = await database;
    await db.update(
      'devices',
      device.toJson(),
      where: 'id = ?',
      whereArgs: [device.id],
    );
  }

  Future<void> deleteDevice(String id) async {
    final db = await database;
    await db.delete(
      'devices',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> disconnectAllDevices() async {
    final db = await database;
    await db.update(
      'devices',
      {'isConnected': 0},
      where: 'isConnected = ?',
      whereArgs: [1],
    );
  }

  // Resource Operations
  Future<List<ResourceModel>> getAllResources() async {
    final db = await database;
    final maps = await db.query('resources', orderBy: 'createdAt DESC');
    return maps.map((map) => ResourceModel.fromJson(map)).toList();
  }

  Future<List<ResourceModel>> getResourcesByCategory(String category) async {
    final db = await database;
    final maps = await db.query(
      'resources',
      where: 'category = ?',
      whereArgs: [category],
      orderBy: 'createdAt DESC',
    );
    return maps.map((map) => ResourceModel.fromJson(map)).toList();
  }

  Future<void> insertResource(ResourceModel resource) async {
    final db = await database;
    await db.insert(
      'resources',
      resource.toJson(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> updateResource(ResourceModel resource) async {
    final db = await database;
    await db.update(
      'resources',
      resource.toJson(),
      where: 'id = ?',
      whereArgs: [resource.id],
    );
  }

  Future<void> deleteResource(String id) async {
    final db = await database;
    await db.delete(
      'resources',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Network Activity Operations
  Future<List<NetworkActivityModel>> getAllActivities() async {
    final db = await database;
    final maps = await db.query('network_activities', orderBy: 'timestamp DESC', limit: 100);
    return maps.map((map) => NetworkActivityModel.fromJson(map)).toList();
  }

  Future<void> insertActivity(NetworkActivityModel activity) async {
    final db = await database;
    await db.insert(
      'network_activities',
      activity.toJson(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> clearOldActivities({int daysToKeep = 30}) async {
    final db = await database;
    final cutoffTime = DateTime.now().subtract(Duration(days: daysToKeep));
    await db.delete(
      'network_activities',
      where: 'timestamp < ?',
      whereArgs: [cutoffTime.millisecondsSinceEpoch],
    );
  }

  // Database Encryption (when app is inactive)
  String encryptData(String plainText) {
    final encrypted = _encrypter.encrypt(plainText, iv: _iv);
    return encrypted.base64;
  }

  String decryptData(String encryptedText) {
    final encrypted = encrypt_lib.Encrypted.fromBase64(encryptedText);
    return _encrypter.decrypt(encrypted, iv: _iv);
  }

  // Close database
  Future<void> close() async {
    final db = await database;
    await db.close();
  }

  // Clear all data
  Future<void> clearAllData() async {
    final db = await database;
    await db.delete('user_profiles');
    await db.delete('devices');
    await db.delete('resources');
    await db.delete('network_activities');
  }
}

