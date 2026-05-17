import 'dart:convert';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import 'notification_design_tokens.dart';

class PremiumNotificationContent {
  const PremiumNotificationContent({
    required this.type,
    required this.category,
    required this.groupId,
    required this.title,
    required this.body,
    required this.screen,
    required this.priority,
    required this.actions,
    required this.data,
    this.imageUrl = '',
  });

  factory PremiumNotificationContent.fromRemoteMessage(RemoteMessage message) {
    final Map<String, dynamic> data = _expandedData(message.data);
    final String referenceType = _first(data, <String>[
      'referenceType',
      'Reference_Type',
    ]);
    final String rawType = _first(data, <String>[
      'type',
      'notificationType',
      'Notification_Type',
      'actionType',
    ]);
    final String type = _normalizeType(rawType, referenceType);
    final String category = _categoryFor(type);
    final String propertyName = _first(data, <String>[
      'propertyName',
      'Property_Title',
      'Property_Name',
      'Property_Display_Label',
    ]);
    final String societyName = _first(data, <String>[
      'societyName',
      'Society_Name',
    ]);
    final String amount = _first(data, <String>[
      'amount',
      'Bill_Final_Amount',
      'Bill_Amount',
      'Booking_Amount',
    ]);
    final String residentImage = _first(data, <String>[
      'residentImage',
      'Resident_Image_URL',
      'tenantImage',
      'Tenant_Image_URL',
    ]);
    final String tenantName = _first(data, <String>[
      'tenantName',
      'Tenant_Name',
      'Name',
    ]);
    final String status = _first(data, <String>[
      'status',
      'Booking_Status',
      'Bill_Status_Label',
      'Ticket_Status_Label',
      'Enquiry_Status_Label',
    ]);
    final String backendTitle = message.notification?.title ??
        _first(data, <String>['title', 'Title']);
    final String backendBody =
        message.notification?.body ?? _first(data, <String>['body', 'Message']);
    final _Copy copy = _copyFor(
      type: type,
      backendTitle: backendTitle,
      backendBody: backendBody,
      propertyName: propertyName,
      societyName: societyName,
      amount: amount,
      tenantName: tenantName,
      status: status,
    );

    final String groupId = _first(data, <String>['groupId', 'group']);
    final String screen = _first(data, <String>['screen']);

    return PremiumNotificationContent(
      type: type,
      category: category,
      groupId: groupId.isEmpty ? '${category}_group' : groupId,
      title: copy.title,
      body: copy.body,
      screen: screen.isEmpty ? _screenFor(type) : screen,
      priority: _priorityFor(type, data),
      actions: _actionsFor(type),
      imageUrl: residentImage.isNotEmpty
          ? residentImage
          : _first(data, <String>[
              'image',
              'imageUrl',
              'residentImage',
              'Resident_Image_URL',
              'tenantImage',
              'Tenant_Image_URL',
              'propertyImage',
              'property_image',
              'Property_Image_URL',
              'Property_Image_Document',
              'Property_Image',
              'Property_Image_1',
              'Property_Image_2',
              'Property_Image_3',
              'Image_URL',
              'Notification_Image',
              'notificationImage',
              'societyBanner',
              'Society_Banner',
              'ticketImage',
              'Ticket_Image',
              'visitorPhoto',
              'Visitor_Photo',
              'big_picture',
              'picture',
            ]),
      data: data,
    );
  }

  final String type;
  final String category;
  final String groupId;
  final String title;
  final String body;
  final String screen;
  final String priority;
  final List<AndroidNotificationAction> actions;
  final String imageUrl;
  final Map<String, dynamic> data;

  int get stableId {
    final String id = _first(data, <String>[
      'notificationId',
      'Vendor_NotificationID',
      'NotificationID',
      'bookingId',
      'BookingID',
      'billId',
      'BillID',
      'ticketId',
      'TicketID',
      'enquiryId',
      'EnquiryID',
      'propertyId',
      'PropertyID',
      'referenceId',
      'Reference_ID',
      'ReferenceID',
    ]);
    return id.isEmpty ? payload.hashCode : '$type-$id'.hashCode;
  }

  bool get isUrgent => priority == 'urgent' || priority == 'max';

  Priority get androidPriority {
    return NotificationDesignTokens.priorityFor(priority);
  }

  Importance get androidImportance {
    return NotificationDesignTokens.importanceFor(priority);
  }

  String get payload {
    return jsonEncode(<String, dynamic>{
      'type': type,
      'category': category,
      'screen': screen,
      'groupId': groupId,
      'priority': priority,
      'data': data,
    });
  }

  static String _first(Map<String, dynamic> data, List<String> keys) {
    for (final String key in keys) {
      final String value = '${data[key] ?? ''}'.trim();
      if (value.isNotEmpty) return value;
    }
    return '';
  }

  static Map<String, dynamic> _expandedData(Map<String, dynamic> source) {
    final Map<String, dynamic> data = <String, dynamic>{...source};
    for (final String key in <String>['meta', 'metadata', 'Meta', 'payload']) {
      final Object? raw = data[key];
      if (raw is! String || raw.trim().isEmpty) continue;
      try {
        final Object? decoded = jsonDecode(raw);
        if (decoded is Map) {
          data.addAll(Map<String, dynamic>.from(decoded));
        }
      } catch (_) {}
    }
    return data;
  }

  static String _normalizeType(String rawType, String referenceType) {
    final String raw = rawType.toLowerCase().trim();
    final String reference = referenceType.toLowerCase().trim();
    final String combined = '$raw $reference';

    if (combined.contains('property_enquiry') ||
        combined.contains('enquiry') ||
        combined.contains('lead')) {
      return 'enquiry';
    }
    if (combined.contains('property_booking') || combined.contains('booking')) {
      if (combined.contains('reject')) return 'booking_rejected';
      if (combined.contains('approve') || combined.contains('confirm')) {
        return 'booking_approved';
      }
      if (combined.contains('accept')) return 'booking_accepted';
      return 'booking';
    }
    if (combined.contains('bill') || combined.contains('rent')) {
      if (combined.contains('failed')) return 'payment_failed';
      if (combined.contains('success') || combined.contains('captured')) {
        return 'payment_success';
      }
      return 'rent_due';
    }
    if (combined.contains('rental_contract') ||
        combined.contains('agreement') ||
        combined.contains('contract')) {
      return 'agreement';
    }
    if (combined.contains('announcement') || combined.contains('notice')) {
      return 'society_notice';
    }
    if (combined.contains('emergency')) return 'emergency_alert';
    if (combined.contains('support') || combined.contains('ticket')) {
      return 'ticket';
    }
    if (combined.contains('maintenance')) return 'maintenance';
    if (combined.contains('visitor')) return 'visitor';
    if (combined.contains('wallet')) return 'wallet';
    return raw.isEmpty ? 'general' : raw;
  }

  static String _categoryFor(String type) {
    if (type.contains('booking')) return 'bookings';
    if (type == 'rent_due' || type.contains('payment') || type == 'wallet') {
      return 'payments';
    }
    if (type == 'ticket' || type == 'maintenance') return 'tickets';
    if (type == 'society_notice' || type == 'emergency_alert' || type == 'security_alert') {
      return 'announcements';
    }
    if (type == 'enquiry') return 'enquiries';
    if (type == 'visitor' || type == 'security_alert') return 'security';
    if (type == 'agreement') return 'contracts';
    return 'updates';
  }

  static String _screenFor(String type) {
    return switch (type) {
      'enquiry' => 'property_enquiry_detail',
      'booking' => 'booking_detail',
      'booking_accepted' ||
      'booking_approved' ||
      'booking_rejected' =>
        'tenant_booking_detail',
      'rent_due' => 'bill_detail',
      'payment_success' || 'payment_failed' || 'wallet' => 'payment_history',
      'agreement' => 'rental_contract_detail',
      'society_notice' || 'emergency_alert' || 'security_alert' => 'announcement_detail',
      'ticket' || 'maintenance' => 'support_ticket_detail',
      'visitor' => 'visitor_detail',
      _ => 'notifications',
    };
  }

  static String _priorityFor(String type, Map<String, dynamic> data) {
    final String explicit = _first(data, <String>['priority', 'Priority_Label'])
        .toLowerCase()
        .trim();
    if (explicit.contains('urgent') || explicit.contains('emergency')) {
      return 'urgent';
    }
    if (type == 'emergency_alert' || type == 'visitor') return 'urgent';
    if (type.contains('booking') ||
        type == 'rent_due' ||
        type == 'payment_failed') {
      return 'high';
    }
    if (type == 'general') return 'low';
    return 'normal';
  }

  static List<AndroidNotificationAction> _actionsFor(String type) {
    return switch (type) {
      'enquiry' => const <AndroidNotificationAction>[
          AndroidNotificationAction('view_enquiry', 'View'),
          AndroidNotificationAction('call_tenant', 'Call'),
        ],
      'booking' => const <AndroidNotificationAction>[
          AndroidNotificationAction('view_booking', 'View'),
          AndroidNotificationAction('call_tenant', 'Call'),
        ],
      'booking_rejected' => const <AndroidNotificationAction>[
          AndroidNotificationAction('view_reason', 'Reason'),
          AndroidNotificationAction('find_similar', 'Similar'),
        ],
      'booking_accepted' || 'booking_approved' =>
        const <AndroidNotificationAction>[
          AndroidNotificationAction('view_booking', 'View'),
          AndroidNotificationAction('view_property', 'Property'),
        ],
      'rent_due' => const <AndroidNotificationAction>[
          AndroidNotificationAction('pay_now', 'Pay'),
          AndroidNotificationAction('view_bill', 'Bill'),
        ],
      'payment_failed' => const <AndroidNotificationAction>[
          AndroidNotificationAction('retry_payment', 'Retry'),
          AndroidNotificationAction('view_bill', 'Bill'),
        ],
      'payment_success' => const <AndroidNotificationAction>[
          AndroidNotificationAction('view_receipt', 'Receipt'),
          AndroidNotificationAction('view_history', 'History'),
        ],
      'society_notice' => const <AndroidNotificationAction>[
          AndroidNotificationAction('view_notice', 'View'),
        ],
      'emergency_alert' => const <AndroidNotificationAction>[
          AndroidNotificationAction('view_alert', 'View'),
          AndroidNotificationAction('call_security', 'Security'),
        ],
      'security_alert' => const <AndroidNotificationAction>[
          AndroidNotificationAction('view_alert', 'View'),
          AndroidNotificationAction('call_security', 'Security'),
        ],
      'ticket' || 'maintenance' => const <AndroidNotificationAction>[
          AndroidNotificationAction('open_ticket', 'Open'),
          AndroidNotificationAction('reply', 'Reply'),
        ],
      'visitor' => const <AndroidNotificationAction>[
          AndroidNotificationAction('approve_visitor', 'Approve'),
          AndroidNotificationAction('reject_visitor', 'Reject'),
          AndroidNotificationAction('call_visitor', 'Call'),
        ],
      _ => const <AndroidNotificationAction>[
          AndroidNotificationAction('open', 'Open'),
        ],
    };
  }

  static _Copy _copyFor({
    required String type,
    required String backendTitle,
    required String backendBody,
    required String propertyName,
    required String societyName,
    required String amount,
    required String tenantName,
    required String status,
  }) {
    final String place = propertyName.isNotEmpty
        ? propertyName
        : (societyName.isNotEmpty ? societyName : 'UrbanEasyFlats');
    return switch (type) {
      'enquiry' => _Copy(
          tenantName.isEmpty
              ? 'New enquiry for $place'
              : '$tenantName is interested in $place',
          'New lead - view details and call back from the app.',
        ),
      'booking' => _Copy(
          tenantName.isEmpty ? 'New booking request' : '$tenantName booked it',
          'Pending - review $place and respond quickly.',
        ),
      'booking_accepted' => _Copy(
          'Almost there',
          'Accepted - $place is waiting for admin approval.',
        ),
      'booking_approved' => _Copy(
          'Pack your bags',
          'Confirmed - your booking for $place is ready.',
        ),
      'booking_rejected' => _Copy(
          'Booking could not move ahead',
          backendBody.isEmpty
              ? 'Rejected - open your booking to see the reason.'
              : backendBody,
        ),
      'rent_due' => _Copy(
          backendTitle.isNotEmpty
              ? backendTitle
              : (amount.isEmpty ? 'Rent bill is ready' : 'Rs $amount rent is due'),
          backendBody.isNotEmpty
              ? backendBody
              : (status.isEmpty ? 'Due soon - pay securely from the app.' : status),
        ),
      'payment_success' => _Copy(
          backendTitle.isNotEmpty
              ? backendTitle
              : (amount.isEmpty ? 'Payment successful' : 'Rs $amount paid successfully'),
          backendBody.isNotEmpty
              ? backendBody
              : 'Receipt is ready in your payment history.',
        ),
      'payment_failed' => _Copy(
          backendTitle.isNotEmpty ? backendTitle : 'Payment could not be completed',
          backendBody.isNotEmpty
              ? backendBody
              : 'Please retry or open the bill for details.',
        ),
      'agreement' => _Copy(
          'Agreement update for $place',
          'Open the contract to review the latest details.',
        ),
      'society_notice' => _Copy(
          societyName.isEmpty ? 'New society notice' : 'New notice from $societyName',
          backendBody.isEmpty ? 'Open the notice for details.' : backendBody,
        ),
      'emergency_alert' => _Copy(
          'Emergency alert',
          backendBody.isEmpty ? 'Open immediately for details.' : backendBody,
        ),
      'ticket' => _Copy(
          'Your request has an update',
          backendBody.isEmpty ? 'Open the ticket for the latest status.' : backendBody,
        ),
      'maintenance' => _Copy(
          backendTitle.isNotEmpty ? backendTitle : 'Maintenance request updated',
          backendBody.isNotEmpty ? backendBody : 'Open the request for details.',
        ),
      'visitor' => _Copy(
          'Visitor approval needed',
          'Approve or reject this visitor request.',
        ),
      _ => _Copy(
          backendTitle.isEmpty ? 'UrbanEasyFlats update' : backendTitle,
          backendBody,
        ),
    };
  }
}

class _Copy {
  const _Copy(this.title, this.body);

  final String title;
  final String body;
}
