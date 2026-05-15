import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationDesignTokens {
  const NotificationDesignTokens._();

  static const Duration imageTimeout = Duration(seconds: 4);
  static const Duration imageCacheTtl = Duration(hours: 12);
  static const Duration duplicateWindow = Duration(seconds: 12);
  static const int maxImageBytes = 5 * 1024 * 1024;
  static const int maxCachedImages = 24;

  static const String fallbackScreen = 'notifications';
  static const String defaultGroupId = 'updates_group';

  static const String actionView = 'View';
  static const String actionCall = 'Call';
  static const String actionPay = 'Pay';
  static const String actionBill = 'Bill';
  static const String actionRetry = 'Retry';
  static const String actionReceipt = 'Receipt';
  static const String actionReason = 'Reason';
  static const String actionSimilar = 'Similar';

  static Importance importanceFor(String priority) {
    return switch (priority) {
      'urgent' || 'max' => Importance.max,
      'high' => Importance.high,
      'low' => Importance.low,
      _ => Importance.defaultImportance,
    };
  }

  static Priority priorityFor(String priority) {
    return switch (priority) {
      'urgent' || 'max' => Priority.max,
      'high' => Priority.high,
      'low' => Priority.low,
      _ => Priority.defaultPriority,
    };
  }
}
