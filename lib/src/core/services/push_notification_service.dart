import 'dart:async';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../api/auth_service.dart';

// Must be a top-level function — runs in a separate isolate when app is terminated.
@pragma('vm:entry-point')
Future<void> _onBackgroundMessage(RemoteMessage message) async {
  // FCM shows the notification automatically for notification messages.
  // No Firebase.initializeApp() needed here for basic use.
}

class PushNotificationService {
  PushNotificationService._();

  static const String _channelId = 'urbaneasyflats_main';
  static const String _channelName = 'UrbanEasyFlats Alerts';

  static final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  static const AndroidNotificationChannel _androidChannel =
      AndroidNotificationChannel(
    _channelId,
    _channelName,
    importance: Importance.high,
    enableVibration: true,
  );

  static VoidCallback? _onNotificationTap;
  static bool _initialized = false;

  /// Call once from app.dart after Firebase.initializeApp() succeeds.
  /// [onNotificationTap] is called when the user taps any notification.
  static Future<void> initialize({VoidCallback? onNotificationTap}) async {
    if (_initialized) return;
    _initialized = true;
    _onNotificationTap = onNotificationTap;

    // Register background handler before anything else.
    FirebaseMessaging.onBackgroundMessage(_onBackgroundMessage);

    await _setupLocalNotifications();
    await _requestPermission();
    await _registerToken();

    // Re-register when token rotates (e.g. app reinstall, token expiry).
    FirebaseMessaging.instance.onTokenRefresh.listen((String token) {
      AuthService.registerPushToken(token).catchError((_) {});
    });

    // App in foreground — FCM does NOT show a heads-up banner automatically.
    // Show it ourselves via flutter_local_notifications.
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    // App was in background and user tapped the notification.
    FirebaseMessaging.onMessageOpenedApp.listen((_) {
      _onNotificationTap?.call();
    });

    // App was terminated and user tapped the notification to launch it.
    final RemoteMessage? initialMessage =
        await FirebaseMessaging.instance.getInitialMessage();
    if (initialMessage != null) {
      // Defer until the first frame is rendered and navigator is ready.
      Future.delayed(const Duration(milliseconds: 300), () {
        _onNotificationTap?.call();
      });
    }
  }

  static Future<void> _setupLocalNotifications() async {
    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const DarwinInitializationSettings iosSettings =
        DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    await _localNotifications.initialize(
      const InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      ),
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        // User tapped the local notification shown in the foreground.
        _onNotificationTap?.call();
      },
    );

    // Create the Android notification channel at high importance so
    // foreground notifications show as heads-up banners.
    await _localNotifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(_androidChannel);
  }

  static Future<void> _requestPermission() async {
    final NotificationSettings settings =
        await FirebaseMessaging.instance.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (kDebugMode) {
      debugPrint(
        'PushNotifications: permission=${settings.authorizationStatus.name}',
      );
    }
  }

  static Future<void> _registerToken() async {
    try {
      final String? token = await FirebaseMessaging.instance.getToken();
      if (token != null && token.isNotEmpty) {
        await AuthService.registerPushToken(token);
        if (kDebugMode) {
          debugPrint('PushNotifications: token registered (${token.substring(0, 20)}…)');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('PushNotifications: token registration failed — $e');
      }
    }
  }

  static Future<void> _handleForegroundMessage(RemoteMessage message) async {
    final RemoteNotification? notification = message.notification;
    if (notification == null) return;

    await _localNotifications.show(
      notification.hashCode,
      notification.title,
      notification.body,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId,
          _channelName,
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
    );
  }
}
