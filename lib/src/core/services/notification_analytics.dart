import 'package:flutter/foundation.dart';

class NotificationAnalytics {
  const NotificationAnalytics._();

  static Future<void> track(
    String event, {
    Map<String, Object?> values = const <String, Object?>{},
  }) async {
    if (!kDebugMode) return;
    debugPrint('NotificationAnalytics: $event $values');
  }
}
