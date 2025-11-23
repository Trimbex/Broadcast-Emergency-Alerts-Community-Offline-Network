import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';

class NotificationService {
  static final NotificationService instance = NotificationService._init();
  static FlutterLocalNotificationsPlugin? _notifications;

  NotificationService._init();

  Future<void> initialize() async {
    try {
      _notifications = FlutterLocalNotificationsPlugin();

      // Request notification permission
      await _requestPermission();

      // Android initialization settings
      const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');

      // iOS initialization settings
      const iosSettings = DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );

      // Initialization settings
      const initSettings = InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      );

      // Initialize notifications
      final initialized = await _notifications!.initialize(
        initSettings,
        onDidReceiveNotificationResponse: _onNotificationTapped,
      );

      if (initialized == true) {
        // Create notification channel for Android
        await _createNotificationChannel();
        debugPrint('✅ Notifications: Initialized successfully');
      } else {
        debugPrint('⚠️ Notifications: Initialization returned false');
      }
    } catch (e) {
      debugPrint('❌ Notifications: Failed to initialize: $e');
      // Don't throw - allow app to continue without notifications
    }
  }

  Future<void> _requestPermission() async {
    // Request basic notification permission (Android 13+)
    final androidImplementation = _notifications!
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    
    if (androidImplementation != null) {
      try {
        // Request notification permission for Android 13+
        await androidImplementation.requestNotificationsPermission();
      } catch (e) {
        debugPrint('⚠️ Notifications: Failed to request notification permission: $e');
      }
      
      // Note: Exact alarm permission is only needed for scheduled/recurring notifications
      // Since we only use immediate notifications (show()), we don't need this permission
      
      try {
        // Request full-screen intent permission (for emergency notifications)
        // This allows notifications to appear over lock screen (Android 10+)
        await androidImplementation.requestFullScreenIntentPermission();
      } catch (e) {
        debugPrint('⚠️ Notifications: Failed to request full-screen intent permission: $e');
        // Not critical - notifications will still work, just won't show over lock screen
      }
    } else {
      // Fallback for iOS or other platforms
      if (await Permission.notification.isDenied) {
        await Permission.notification.request();
      }
    }
  }

  Future<void> _createNotificationChannel() async {
    const androidChannel = AndroidNotificationChannel(
      'beacon_emergency_channel',
      'BEACON Emergency Notifications',
      description: 'Notifications for emergency messages and resource requests',
      importance: Importance.high,
      playSound: true,
      enableVibration: true,
      showBadge: true,
    );

    await _notifications!
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(androidChannel);
  }

  void _onNotificationTapped(NotificationResponse response) {
    debugPrint('Notification tapped: ${response.payload}');
    // Handle notification tap - could navigate to specific screen
  }

  /// Show notification for incoming message
  Future<void> showMessageNotification({
    required String senderName,
    required String message,
    required bool isEmergency,
    String? payload,
  }) async {
    if (_notifications == null) {
      debugPrint('⚠️ Notifications: Service not initialized');
      return;
    }
    
    try {

    const androidDetails = AndroidNotificationDetails(
      'beacon_emergency_channel',
      'BEACON Emergency Notifications',
      channelDescription: 'Notifications for emergency messages and resource requests',
      importance: Importance.high,
      priority: Priority.high,
      playSound: true,
      enableVibration: true,
      icon: '@mipmap/ic_launcher',
      styleInformation: BigTextStyleInformation(''),
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    final title = isEmergency
        ? '🚨 EMERGENCY: $senderName'
        : 'New message from $senderName';

      await _notifications!.show(
        DateTime.now().millisecondsSinceEpoch % 100000,
        title,
        message,
        details,
        payload: payload,
      );
    } catch (e) {
      debugPrint('❌ Notifications: Failed to show message notification: $e');
    }
  }

  /// Show notification for resource request
  Future<void> showResourceRequestNotification({
    required String requesterName,
    required String resourceName,
    required String resourceCategory,
    String? payload,
  }) async {
    if (_notifications == null) {
      debugPrint('⚠️ Notifications: Service not initialized');
      return;
    }
    
    try {

    const androidDetails = AndroidNotificationDetails(
      'beacon_emergency_channel',
      'BEACON Emergency Notifications',
      channelDescription: 'Notifications for emergency messages and resource requests',
      importance: Importance.high,
      priority: Priority.high,
      playSound: true,
      enableVibration: true,
      icon: '@mipmap/ic_launcher',
      styleInformation: BigTextStyleInformation(''),
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

      await _notifications!.show(
        DateTime.now().millisecondsSinceEpoch % 100000,
        'Resource Request',
        '$requesterName requested: $resourceName ($resourceCategory)',
        details,
        payload: payload,
      );
    } catch (e) {
      debugPrint('❌ Notifications: Failed to show resource request notification: $e');
    }
  }

  /// Cancel all notifications
  Future<void> cancelAll() async {
    await _notifications?.cancelAll();
  }

  /// Cancel specific notification
  Future<void> cancel(int id) async {
    await _notifications?.cancel(id);
  }
}

