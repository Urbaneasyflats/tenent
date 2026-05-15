import 'dart:async';
import 'dart:io';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

import '../../../firebase_options.dart';
import '../api/auth_service.dart';
import 'notification_analytics.dart';
import 'notification_design_tokens.dart';
import 'premium_notification_renderer.dart';

// Must be a top-level function — runs in a separate isolate when app is terminated.
@pragma('vm:entry-point')
Future<void> _onBackgroundMessage(RemoteMessage message) async {
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (_) {}
  if (message.notification == null) {
    await PushNotificationService.showBackgroundNotification(message);
  }
}

class PushNotificationService {
  PushNotificationService._();

  static const String _channelId = 'urbaneasyflats_main_bell';
  static const String _channelName = 'UrbanEasyFlats Alerts';
  static const String _notificationSound = 'notification_bell';
  static const String _notificationLogo = 'notification_logo';

  static final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();
  static final Map<String, int> _groupCounts = <String, int>{};
  static final Map<int, DateTime> _recentRenders = <int, DateTime>{};

  static const AndroidNotificationChannel _androidChannel =
      AndroidNotificationChannel(
        _channelId,
        _channelName,
        importance: Importance.high,
        enableVibration: true,
        playSound: true,
        sound: RawResourceAndroidNotificationSound(_notificationSound),
      );

  static void Function(String? payload)? _onNotificationTap;
  static bool _initialized = false;
  static bool _localNotificationsReady = false;
  static bool _isSyncingToken = false;

  /// Call once from app.dart after Firebase.initializeApp() succeeds.
  /// [onNotificationTap] is called when the user taps any notification.
  static Future<void> initialize({
    void Function(String? payload)? onNotificationTap,
  }) async {
    _onNotificationTap = onNotificationTap;
    if (_initialized) {
      unawaited(syncToken());
      return;
    }
    _initialized = true;

    // Register background handler before anything else.
    FirebaseMessaging.onBackgroundMessage(_onBackgroundMessage);

    await _setupLocalNotifications();
    await _requestPermission();
    unawaited(_registerTokenWithRetry());

    // Re-register when token rotates (e.g. app reinstall, token expiry).
    FirebaseMessaging.instance.onTokenRefresh.listen((String token) {
      AuthService.registerPushToken(token).catchError((_) {});
    });

    // App in foreground — FCM does NOT show a heads-up banner automatically.
    // Show it ourselves via flutter_local_notifications.
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    // App was in background and user tapped the notification.
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      final String payload =
          PremiumNotificationContent.fromRemoteMessage(message).payload;
      _onNotificationTap?.call(payload);
    });

    // App was terminated and user tapped the notification to launch it.
    final RemoteMessage? initialMessage = await FirebaseMessaging.instance
        .getInitialMessage();
    if (initialMessage != null) {
      // Defer until the first frame is rendered and navigator is ready.
      Future.delayed(const Duration(milliseconds: 300), () {
        final String payload =
            PremiumNotificationContent.fromRemoteMessage(initialMessage).payload;
        _onNotificationTap?.call(payload);
      });
    }
  }

  static Future<void> _setupLocalNotifications() async {
    if (_localNotificationsReady) return;
    _localNotificationsReady = true;
    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const DarwinInitializationSettings iosSettings =
        DarwinInitializationSettings(
          requestAlertPermission: false,
          requestBadgePermission: false,
          requestSoundPermission: false,
        );

    await _localNotifications.initialize(
      const InitializationSettings(android: androidSettings, iOS: iosSettings),
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        // User tapped the local notification shown in the foreground.
        if (kDebugMode) {
          debugPrint(
            'PushNotifications: clicked action=${response.actionId} payload=${response.payload != null}',
          );
        }
        final String actionId = response.actionId ?? '';
        unawaited(
          NotificationAnalytics.track(
            actionId.isEmpty
                ? 'notification_clicked'
                : 'notification_action_clicked',
            values: <String, Object?>{
              'action': actionId,
              'hasPayload': response.payload != null,
            },
          ),
        );
        _onNotificationTap?.call(response.payload);
      },
    );

    // Create the Android notification channel at high importance so
    // foreground notifications show as heads-up banners.
    await _localNotifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(_androidChannel);
  }

  static Future<void> _requestPermission() async {
    final NotificationSettings settings = await FirebaseMessaging.instance
        .requestPermission(alert: true, badge: true, sound: true);

    if (kDebugMode) {
      debugPrint(
        'PushNotifications: permission=${settings.authorizationStatus.name}',
      );
    }
  }

  static Future<void> _registerTokenWithRetry() async {
    const List<Duration> retryDelays = <Duration>[
      Duration.zero,
      Duration(seconds: 5),
      Duration(seconds: 15),
      Duration(seconds: 45),
    ];

    for (final Duration delay in retryDelays) {
      if (delay > Duration.zero) {
        await Future<void>.delayed(delay);
      }

      try {
        final bool synced = await syncToken();
        if (!synced) continue;
        return;
      } catch (e) {
        if (kDebugMode) {
          debugPrint('PushNotifications: token registration failed — $e');
        }
      }
    }
  }

  static Future<bool> syncToken() async {
    if (_isSyncingToken) {
      return false;
    }
    _isSyncingToken = true;
    try {
      final String? token = await FirebaseMessaging.instance.getToken();
      if (token == null || token.isEmpty) {
        return false;
      }

      await AuthService.registerPushToken(token);
      if (kDebugMode) {
        debugPrint('PushNotifications: token registered');
      }
      return true;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('PushNotifications: token registration failed');
      }
      return false;
    } finally {
      _isSyncingToken = false;
    }
  }

  static Future<void> _handleForegroundMessage(RemoteMessage message) async {
    await _showPremiumNotification(message);
  }

  static Future<void> showBackgroundNotification(RemoteMessage message) async {
    await _setupLocalNotifications();
    await _showPremiumNotification(message);
  }

  static Future<void> _showPremiumNotification(RemoteMessage message) async {
    final PremiumNotificationContent content =
        PremiumNotificationContent.fromRemoteMessage(message);
    if (content.title.trim().isEmpty && content.body.trim().isEmpty) return;
    if (_shouldSkipDuplicate(content.stableId)) {
      unawaited(
        NotificationAnalytics.track(
          'notification_duplicate_skipped',
          values: <String, Object?>{'type': content.type},
        ),
      );
      return;
    }
    if (kDebugMode) {
      debugPrint(
        'PushNotifications: received type=${content.type} group=${content.groupId} image=${content.imageUrl.isNotEmpty}',
      );
    }
    unawaited(
      NotificationAnalytics.track(
        'notification_received',
        values: <String, Object?>{
          'type': content.type,
          'groupId': content.groupId,
          'hasImage': content.imageUrl.isNotEmpty,
        },
      ),
    );

    final String? bigPicturePath =
        await _downloadNotificationImage(content.imageUrl);
    final AndroidBitmap<Object> bigPicture = bigPicturePath == null
        ? const DrawableResourceAndroidBitmap(_notificationLogo)
        : FilePathAndroidBitmap(bigPicturePath);

    await _localNotifications.show(
      content.stableId,
      content.title,
      content.body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId,
          _channelName,
          importance: content.androidImportance,
          priority: content.androidPriority,
          largeIcon: const DrawableResourceAndroidBitmap(_notificationLogo),
          styleInformation: BigPictureStyleInformation(
            bigPicture,
            largeIcon: const DrawableResourceAndroidBitmap(_notificationLogo),
            contentTitle: content.title,
            summaryText: content.body,
            hideExpandedLargeIcon: false,
          ),
          actions: content.actions,
          groupKey: content.groupId,
          playSound: true,
          sound: const RawResourceAndroidNotificationSound(_notificationSound),
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      payload: content.payload,
    );
    await _showGroupSummary(content);
    if (kDebugMode) {
      debugPrint('PushNotifications: rendered type=${content.type}');
    }
    unawaited(
      NotificationAnalytics.track(
        'notification_rendered',
        values: <String, Object?>{
          'type': content.type,
          'groupId': content.groupId,
          'imageRendered': bigPicturePath != null,
        },
      ),
    );
  }

  static bool _shouldSkipDuplicate(int stableId) {
    final DateTime now = DateTime.now();
    _recentRenders.removeWhere(
      (_, DateTime renderedAt) =>
          now.difference(renderedAt) > NotificationDesignTokens.duplicateWindow,
    );
    final DateTime? lastRender = _recentRenders[stableId];
    if (lastRender != null &&
        now.difference(lastRender) < NotificationDesignTokens.duplicateWindow) {
      return true;
    }
    _recentRenders[stableId] = now;
    return false;
  }

  static Future<void> _showGroupSummary(
    PremiumNotificationContent content,
  ) async {
    final int count = (_groupCounts[content.groupId] ?? 0) + 1;
    _groupCounts[content.groupId] = count;
    if (count < 2) return;

    await _localNotifications.show(
      content.groupId.hashCode,
      _summaryTitle(content.category, count),
      _summaryBody(content.category),
      NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId,
          _channelName,
          importance: Importance.defaultImportance,
          priority: Priority.defaultPriority,
          groupKey: content.groupId,
          setAsGroupSummary: true,
          largeIcon: const DrawableResourceAndroidBitmap(_notificationLogo),
          styleInformation: InboxStyleInformation(
            <String>[content.body],
            contentTitle: _summaryTitle(content.category, count),
            summaryText: _summaryBody(content.category),
          ),
          playSound: false,
        ),
      ),
      payload: content.payload,
    );
    unawaited(
      NotificationAnalytics.track(
        'grouped_notification_created',
        values: <String, Object?>{
          'category': content.category,
          'groupId': content.groupId,
          'count': count,
        },
      ),
    );
  }

  static String _summaryTitle(String category, int count) {
    final String label = switch (category) {
      'bookings' => 'booking updates',
      'payments' => 'payment updates',
      'tickets' => 'ticket updates',
      'announcements' => 'notices',
      'enquiries' => 'property enquiries',
      _ => 'updates',
    };
    return '$count new $label';
  }

  static String _summaryBody(String category) {
    return switch (category) {
      'bookings' => 'Open bookings to review the latest activity.',
      'payments' => 'Open payments for bills and receipts.',
      'tickets' => 'Open support to continue the conversation.',
      'announcements' => 'Open notices for full details.',
      'enquiries' => 'Open enquiries to respond faster.',
      _ => 'Open UrbanEasyFlats for details.',
    };
  }

  static Future<String?> _downloadNotificationImage(String imageUrl) async {
    final Uri? uri = Uri.tryParse(imageUrl.trim());
    if (uri == null || !uri.hasScheme) return null;
    final Directory directory = await getTemporaryDirectory();
    await _cleanupNotificationImageCache(directory);
    final File file = _notificationImageFile(directory, uri);
    if (await file.exists()) {
      final DateTime modified = await file.lastModified();
      if (DateTime.now().difference(modified) <
          NotificationDesignTokens.imageCacheTtl) {
        return file.path;
      }
    }

    for (int attempt = 0; attempt < 2; attempt += 1) {
      final String? path = await _tryDownloadNotificationImage(uri, file);
      if (path != null) return path;
      await Future<void>.delayed(const Duration(milliseconds: 250));
    }
    unawaited(
      NotificationAnalytics.track(
        'notification_image_failed',
        values: <String, Object?>{'host': uri.host},
      ),
    );
    return null;
  }

  static Future<String?> _tryDownloadNotificationImage(
    Uri uri,
    File file,
  ) async {
    try {
      final http.Response response = await http.get(uri).timeout(
            NotificationDesignTokens.imageTimeout,
          );
      if (response.statusCode < 200 || response.statusCode >= 300) {
        if (kDebugMode) {
          debugPrint('PushNotifications: image failed status=${response.statusCode}');
        }
        return null;
      }
      if (response.bodyBytes.length > NotificationDesignTokens.maxImageBytes) {
        if (kDebugMode) {
          debugPrint('PushNotifications: image skipped because it is too large');
        }
        return null;
      }
      await file.writeAsBytes(response.bodyBytes, flush: true);
      return file.path;
    } catch (_) {
      if (kDebugMode) {
        debugPrint('PushNotifications: image download failed');
      }
      return null;
    }
  }

  static File _notificationImageFile(Directory directory, Uri uri) {
    final String key = '${uri.host}_${uri.path}_${uri.query}'.hashCode.toString();
    return File('${directory.path}/urbaneasy_notification_$key.jpg');
  }

  static Future<void> _cleanupNotificationImageCache(
    Directory directory,
  ) async {
    try {
      final List<FileSystemEntity> entities = await directory
          .list()
          .where(
            (FileSystemEntity entity) =>
                entity is File &&
                entity.path.contains('urbaneasy_notification_'),
          )
          .toList();
      if (entities.length <= NotificationDesignTokens.maxCachedImages) return;
      entities.sort((FileSystemEntity a, FileSystemEntity b) {
        return a.statSync().modified.compareTo(b.statSync().modified);
      });
      final int removeCount =
          entities.length - NotificationDesignTokens.maxCachedImages;
      for (final FileSystemEntity entity in entities.take(removeCount)) {
        await entity.delete();
      }
    } catch (_) {}
  }
}
