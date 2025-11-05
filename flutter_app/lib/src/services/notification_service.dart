import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/foundation.dart';

/// Background message handler (must be top-level function)
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  if (kDebugMode) {
    print(' Background message: ${message.messageId}');
  }
}

class NotificationService {
  // Singleton pattern
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  bool _isInitialized = false;

  /// Initialize Firebase Messaging and Local Notifications
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // Request permission for iOS (Android auto-grants)
      NotificationSettings settings = await _messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );

      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        print(' Notification permission granted');

        // Get FCM token for this device
        String? token = await _messaging.getToken();
        if (token != null) {
          print(' FCM Token: $token');
          // You can call an API endpoint like: POST /users/fcm-token
        }

        // Initialize local notifications for Android
        const AndroidInitializationSettings androidSettings =
            AndroidInitializationSettings('@mipmap/ic_launcher');

        const InitializationSettings initSettings =
            InitializationSettings(android: androidSettings);

        await _localNotifications.initialize(
          initSettings,
          onDidReceiveNotificationResponse: (details) {
            if (kDebugMode) {
              print(' Notification tapped: ${details.payload}');
            }
            // Handle notification tap - navigate to specific screen if needed
          },
        );

        // Register background handler
        FirebaseMessaging.onBackgroundMessage(
            _firebaseMessagingBackgroundHandler);

        // Handle foreground messages
        FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

        // Handle notification opened app
        FirebaseMessaging.onMessageOpenedApp.listen(_handleMessageOpenedApp);

        _isInitialized = true;
      } else {
        print(' Notification permission denied');
      }
    } catch (e) {
      print(' Notification initialization error: $e');
    }
  }

  /// Handle messages when app is in foreground
  void _handleForegroundMessage(RemoteMessage message) {
    if (kDebugMode) {
      print(' Foreground message: ${message.notification?.title}');
    }

    if (message.notification != null) {
      _showLocalNotification(
        title: message.notification!.title ?? 'Energy Alert',
        body: message.notification!.body ?? 'Check your energy usage',
        payload: message.data['screen'] ?? '',
      );
    }
  }

  /// Handle when notification opened the app from terminated/background state
  void _handleMessageOpenedApp(RemoteMessage message) {
    if (kDebugMode) {
      print(' Notification opened app: ${message.notification?.title}');
    }
    // Navigate to specific screen based on message.data
  }

  /// Show local notification (for foreground messages)
  Future<void> _showLocalNotification({
    required String title,
    required String body,
    String payload = '',
  }) async {
    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
      'energy_alerts',
      'Energy Alerts',
      channelDescription: 'Notifications for high energy usage and alerts',
      importance: Importance.high,
      priority: Priority.high,
      showWhen: true,
      icon: '@mipmap/ic_launcher',
    );

    const NotificationDetails details =
        NotificationDetails(android: androidDetails);

    await _localNotifications.show(
      DateTime.now().millisecond,
      title,
      body,
      details,
      payload: payload,
    );
  }

  /// Show alert for peak usage (triggered by app logic)
  Future<void> showPeakUsageAlert(double watts, {String appliance = ''}) async {
    await _showLocalNotification(
      title: '⚡ High Energy Usage Detected!',
      body: appliance.isNotEmpty
          ? '$appliance is using ${watts.toStringAsFixed(1)}W. Consider reducing usage.'
          : 'Current usage: ${watts.toStringAsFixed(1)}W. Consider reducing appliance use.',
      payload: 'dashboard',
    );
  }

  /// Show achievement unlocked notification
  Future<void> showAchievementNotification(String achievement) async {
    await _showLocalNotification(
      title: 'Achievement Unlocked!',
      body: 'You earned: $achievement',
      payload: 'profile',
    );
  }

  /// Show daily summary notification
  Future<void> showDailySummary({
    required double avgWatts,
    required double peakWatts,
    required int totalReadings,
  }) async {
    await _showLocalNotification(
      title: 'Daily Energy Summary',
      body:
          'Avg: ${avgWatts.toStringAsFixed(1)}W | Peak: ${peakWatts.toStringAsFixed(1)}W | Readings: $totalReadings',
      payload: 'history',
    );
  }
}
