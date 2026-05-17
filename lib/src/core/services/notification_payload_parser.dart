import 'dart:convert';

import 'notification_type_enum.dart';

class NotificationPayload {
  const NotificationPayload({
    required this.type,
    required this.screen,
    required this.data,
    required this.raw,
  });

  factory NotificationPayload.fromEncoded(String? payload) {
    if (payload == null || payload.trim().isEmpty) {
      return const NotificationPayload(
        type: NotificationType.unknown,
        screen: '',
        data: <String, dynamic>{},
        raw: <String, dynamic>{},
      );
    }

    try {
      final Object? decoded = jsonDecode(payload);
      if (decoded is! Map) {
        return const NotificationPayload(
          type: NotificationType.unknown,
          screen: '',
          data: <String, dynamic>{},
          raw: <String, dynamic>{},
        );
      }

      final Map<String, dynamic> raw = Map<String, dynamic>.from(decoded);
      final Map<String, dynamic> data = raw['data'] is Map
          ? Map<String, dynamic>.from(raw['data'] as Map)
          : <String, dynamic>{};
      final String typeString = _first(raw, data, <String>[
        'type',
        'notificationType',
        'Notification_Type',
        'actionType',
      ]);
      final String screen = _first(raw, data, <String>[
        'screen',
        'route',
        'routeName',
      ]);

      return NotificationPayload(
        type: NotificationType.fromString(typeString),
        screen: screen,
        data: data,
        raw: raw,
      );
    } catch (_) {
      return const NotificationPayload(
        type: NotificationType.unknown,
        screen: '',
        data: <String, dynamic>{},
        raw: <String, dynamic>{},
      );
    }
  }

  final NotificationType type;
  final String screen;
  final Map<String, dynamic> data;
  final Map<String, dynamic> raw;

  String get routeKey => screen.isEmpty ? type.name : screen;

  String get propertyId => _first(data, raw, <String>[
        'propertyId',
        'PropertyID',
        'Property_Id',
        'property_id',
      ]);

  String get bookingId => _first(data, raw, <String>[
        'bookingId',
        'BookingID',
      ]);

  String get ticketId => _first(data, raw, <String>[
        'ticketId',
        'TicketID',
      ]);

  String get announcementId => _first(data, raw, <String>[
        'announcementId',
        'AnnouncementID',
      ]);

  String get notificationId => _first(data, raw, <String>[
        'notificationId',
        'notification_id',
        'NotificationID',
        'Vendor_NotificationID',
        'id',
      ]);

  String get dedupeKey {
    final String id = notificationId;
    if (id.isNotEmpty) {
      return '${type.name}:$id';
    }
    return '${type.name}:${bookingId}:${ticketId}:${announcementId}:${propertyId}';
  }

  static String _first(
    Map<String, dynamic> primary,
    Map<String, dynamic> fallback,
    List<String> keys,
  ) {
    for (final String key in keys) {
      final String value = '${primary[key] ?? fallback[key] ?? ''}'.trim();
      if (value.isNotEmpty) {
        return value;
      }
    }
    return '';
  }
}
