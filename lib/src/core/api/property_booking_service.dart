import 'api_client.dart';
import 'api_config.dart';

class PropertyBookingService {
  PropertyBookingService._();

  static Future<PropertyBookingOrderResponse> createOrder({
    required String propertyId,
  }) async {
    final ApiResponse response;
    try {
      response = await ApiClient.instance.post(
        ApiConfig.createPropertyBookingOrder,
        <String, dynamic>{'PropertyID': propertyId},
      );
    } catch (error) {
      final String message = error.toString();
      if (message.contains('invalid response') ||
          message.contains('invalid JSON') ||
          message.contains(ApiConfig.createPropertyBookingOrder)) {
        throw Exception(
          'Booking service is not available yet. Please deploy or restart the backend, then try again.',
        );
      }
      rethrow;
    }
    if (!response.success) {
      throw Exception(response.message ?? 'Unable to start booking.');
    }
    return PropertyBookingOrderResponse.fromJson(response.extras);
  }

  static Future<PropertyBookingData> verifyPayment({
    required String bookingId,
    required String orderId,
    required String paymentId,
    required String signature,
  }) async {
    final ApiResponse response = await ApiClient.instance.post(
      ApiConfig.verifyPropertyBookingPayment,
      <String, dynamic>{
        'BookingID': bookingId,
        'Razorpay_Order_ID': orderId,
        'Razorpay_Payment_ID': paymentId,
        'Razorpay_Signature': signature,
      },
    );
    if (!response.success) {
      throw Exception(response.message ?? 'Unable to verify payment.');
    }
    return PropertyBookingData.fromJson(
      response.data as Map<String, dynamic>? ?? <String, dynamic>{},
    );
  }

  static Future<({List<PropertyBookingData> bookings, int count})>
      filterTenantBookings({
    int skip = 0,
    int limit = 20,
    String? status,
    String? statusGroup,
  }) async {
    final ApiResponse response = await ApiClient.instance.post(
      ApiConfig.filterTenantPropertyBookings,
      <String, dynamic>{
        'Skip': skip,
        'Limit': limit,
        'Whether_Booking_Status_Filter': status != null && status.isNotEmpty,
        'Booking_Status': status ?? '',
        if (statusGroup != null && statusGroup.isNotEmpty)
          'Booking_Status_Group': statusGroup,
      },
    );
    if (!response.success) {
      throw Exception(response.message ?? 'Unable to fetch bookings.');
    }
    final List<dynamic> data =
        response.extras['Data'] as List<dynamic>? ?? <dynamic>[];
    return (
      bookings: data
          .whereType<Map<String, dynamic>>()
          .map(PropertyBookingData.fromJson)
          .toList(),
      count: response.count ?? 0,
    );
  }

  static Future<({List<PropertyBookingData> bookings, int count})>
      filterManagerBookings({
    int skip = 0,
    int limit = 20,
    String? status,
    String? statusGroup,
    String search = '',
  }) async {
    final ApiResponse response = await ApiClient.instance.post(
      ApiConfig.filterManagerPropertyBookings,
      <String, dynamic>{
        'Skip': skip,
        'Limit': limit,
        'Whether_Booking_Status_Filter': status != null && status.isNotEmpty,
        'Booking_Status': status ?? '',
        if (statusGroup != null && statusGroup.isNotEmpty)
          'Booking_Status_Group': statusGroup,
        'Whether_Search_Filter': search.trim().isNotEmpty,
        'Search': search.trim(),
      },
    );
    if (!response.success) {
      throw Exception(response.message ?? 'Unable to fetch bookings.');
    }
    final List<dynamic> data =
        response.extras['Data'] as List<dynamic>? ?? <dynamic>[];
    return (
      bookings: data
          .whereType<Map<String, dynamic>>()
          .map(PropertyBookingData.fromJson)
          .toList(),
      count: response.count ?? 0,
    );
  }

  static Future<PropertyBookingData> fetchDetails(String bookingId) async {
    final ApiResponse response = await ApiClient.instance.post(
      ApiConfig.fetchPropertyBookingDetails,
      <String, dynamic>{'BookingID': bookingId},
    );
    if (!response.success) {
      throw Exception(response.message ?? 'Unable to fetch booking details.');
    }
    return PropertyBookingData.fromJson(
      response.data as Map<String, dynamic>? ?? <String, dynamic>{},
    );
  }

  static Future<PropertyBookingData> managerAccept(String bookingId) async {
    final ApiResponse response = await ApiClient.instance.post(
      ApiConfig.managerAcceptPropertyBooking,
      <String, dynamic>{'BookingID': bookingId},
    );
    if (!response.success) {
      throw Exception(response.message ?? 'Unable to accept booking.');
    }
    return PropertyBookingData.fromJson(
      response.data as Map<String, dynamic>? ?? <String, dynamic>{},
    );
  }

  static Future<PropertyBookingData> managerReject({
    required String bookingId,
    required String reason,
  }) async {
    final ApiResponse response = await ApiClient.instance.post(
      ApiConfig.managerRejectPropertyBooking,
      <String, dynamic>{'BookingID': bookingId, 'Reason': reason.trim()},
    );
    if (!response.success) {
      throw Exception(response.message ?? 'Unable to reject booking.');
    }
    return PropertyBookingData.fromJson(
      response.data as Map<String, dynamic>? ?? <String, dynamic>{},
    );
  }
}

class PropertyBookingOrderResponse {
  const PropertyBookingOrderResponse({
    required this.booking,
    required this.bookingId,
    required this.bookingNumber,
    required this.razorpayOrderId,
    required this.razorpayKeyId,
    required this.amountInPaise,
    required this.amount,
    required this.currency,
  });

  factory PropertyBookingOrderResponse.fromJson(Map<String, dynamic> json) {
    return PropertyBookingOrderResponse(
      booking: PropertyBookingData.fromJson(
        json['Data'] as Map<String, dynamic>? ?? <String, dynamic>{},
      ),
      bookingId: json['BookingID'] as String? ?? '',
      bookingNumber: json['Booking_Number'] as String? ?? '',
      razorpayOrderId: json['Razorpay_Order_ID'] as String? ?? '',
      razorpayKeyId: json['Razorpay_Key_ID'] as String? ?? '',
      amountInPaise: (json['Amount_In_Paise'] as num?)?.toInt() ?? 0,
      amount: (json['Amount'] as num?)?.toDouble() ?? 0,
      currency: json['Currency'] as String? ?? 'INR',
    );
  }

  final PropertyBookingData booking;
  final String bookingId;
  final String bookingNumber;
  final String razorpayOrderId;
  final String razorpayKeyId;
  final int amountInPaise;
  final double amount;
  final String currency;
}

class PropertyBookingData {
  const PropertyBookingData({
    required this.bookingId,
    required this.bookingNumber,
    required this.propertyId,
    required this.propertyType,
    required this.propertyTypeLabel,
    required this.bookingAmount,
    required this.paymentStatus,
    required this.bookingStatus,
    required this.propertyInfo,
    required this.tenantInfo,
    required this.managerInfo,
    required this.activityLogs,
    this.razorpayOrderId = '',
    this.razorpayPaymentId = '',
    this.razorpayRefundId = '',
    this.refundStatus = '',
    this.refundReason = '',
    this.managerReason = '',
    this.adminReason = '',
    this.bookingDate,
    this.paymentDate,
    this.refundDate,
  });

  factory PropertyBookingData.fromJson(Map<String, dynamic> json) {
    final List<dynamic> logs =
        json['Activity_Logs'] as List<dynamic>? ?? <dynamic>[];
    return PropertyBookingData(
      bookingId: json['BookingID'] as String? ?? '',
      bookingNumber: json['Booking_Number'] as String? ?? '',
      propertyId: json['PropertyID'] as String? ?? '',
      propertyType:
          (_readMap(json['Property_Info'])['Property_Type'] as num?)?.toInt() ??
              1,
      propertyTypeLabel:
          _readMap(json['Property_Info'])['Property_Type_Label'] as String? ?? '',
      bookingAmount: (json['Booking_Amount'] as num?)?.toDouble() ?? 0,
      paymentStatus: json['Payment_Status'] as String? ?? '',
      bookingStatus: json['Booking_Status'] as String? ?? '',
      razorpayOrderId: json['Razorpay_Order_ID'] as String? ?? '',
      razorpayPaymentId: json['Razorpay_Payment_ID'] as String? ?? '',
      razorpayRefundId: json['Razorpay_Refund_ID'] as String? ?? '',
      refundStatus: json['Refund_Status'] as String? ?? '',
      refundReason: json['Refund_Reason'] as String? ?? '',
      managerReason: json['Manager_Action_Reason'] as String? ?? '',
      adminReason: json['Admin_Action_Reason'] as String? ?? '',
      bookingDate: _readDate(json['Booking_Date'] ?? json['created_at']),
      paymentDate: _readDate(json['Payment_Date']),
      refundDate: _readDate(json['Refund_Date']),
      propertyInfo: _readMap(json['Property_Info']),
      tenantInfo: _readMap(json['Tenant_Info']),
      managerInfo: _readMap(json['Manager_Info']),
      activityLogs: logs
          .whereType<Map<String, dynamic>>()
          .map(PropertyBookingActivity.fromJson)
          .toList(),
    );
  }

  final String bookingId;
  final String bookingNumber;
  final String propertyId;
  final int propertyType;
  final String propertyTypeLabel;
  final double bookingAmount;
  final String paymentStatus;
  final String bookingStatus;
  final String razorpayOrderId;
  final String razorpayPaymentId;
  final String razorpayRefundId;
  final String refundStatus;
  final String refundReason;
  final String managerReason;
  final String adminReason;
  final DateTime? bookingDate;
  final DateTime? paymentDate;
  final DateTime? refundDate;
  final Map<String, dynamic> propertyInfo;
  final Map<String, dynamic> tenantInfo;
  final Map<String, dynamic> managerInfo;
  final List<PropertyBookingActivity> activityLogs;

  String get propertyTitle => propertyInfo['Property_Title'] as String? ?? '';
  String get propertyImageUrl => _readImageUrl(propertyInfo);
  String get location => propertyInfo['Location_Address'] as String? ?? '';
  String get tenantName => tenantInfo['Full_Name'] as String? ?? '';
  String get tenantPhone => tenantInfo['PhoneNumber'] as String? ?? '';
  String get tenantEmail => tenantInfo['EmailID'] as String? ?? '';
  String get managerName => managerInfo['Full_Name'] as String? ?? '';
}

class PropertyBookingActivity {
  const PropertyBookingActivity({
    required this.action,
    required this.actorType,
    required this.oldStatus,
    required this.newStatus,
    required this.notes,
    this.time,
  });

  factory PropertyBookingActivity.fromJson(Map<String, dynamic> json) {
    return PropertyBookingActivity(
      action: json['Action'] as String? ?? '',
      actorType: json['Actor_Type'] as String? ?? '',
      oldStatus: json['Old_Status'] as String? ?? '',
      newStatus: json['New_Status'] as String? ?? '',
      notes: json['Notes'] as String? ?? '',
      time: _readDate(json['Time'] ?? json['created_at']),
    );
  }

  final String action;
  final String actorType;
  final String oldStatus;
  final String newStatus;
  final String notes;
  final DateTime? time;
}

Map<String, dynamic> _readMap(dynamic value) {
  return value is Map<String, dynamic> ? value : <String, dynamic>{};
}

DateTime? _readDate(dynamic value) {
  if (value == null) return null;
  return DateTime.tryParse(value.toString());
}

String _readImageUrl(Map<String, dynamic> source) {
  const List<String> directKeys = <String>[
    'Image_URL',
    'imageUrl',
    'image',
    'Property_Image_URL',
    'Property_Image',
    'Property_Image_1',
    'Property_Image_2',
    'Property_Image_3',
    'Property_Image_Document',
    'Notification_Image',
    'Cover_Image',
    'Thumbnail_URL',
  ];

  for (final String key in directKeys) {
    final String value = _readImageValue(source[key]);
    if (_isNetworkImage(value)) return value;
  }

  const List<String> collectionKeys = <String>[
    'Images',
    'Property_Images',
    'Property_Image_Documents',
    'Gallery',
    'Documents',
  ];
  for (final String key in collectionKeys) {
    final dynamic value = source[key];
    if (value is List) {
      for (final dynamic item in value) {
        final String image = _readImageValue(item);
        if (_isNetworkImage(image)) return image;
      }
    }
  }

  return '';
}

String _readImageValue(dynamic value) {
  if (value == null) return '';
  if (value is String) return value.trim();
  if (value is Map) {
    for (final String key in <String>[
      'url',
      'URL',
      'Url',
      'Location',
      'location',
      'File_URL',
      'FileURL',
      'Image_URL',
      'Document_URL',
      'secure_url',
    ]) {
      final String nested = _readImageValue(value[key]);
      if (nested.isNotEmpty) return nested;
    }
  }
  return '';
}

bool _isNetworkImage(String value) {
  final Uri? uri = Uri.tryParse(value.trim());
  return uri != null &&
      uri.hasScheme &&
      uri.host.isNotEmpty &&
      (uri.scheme == 'http' || uri.scheme == 'https');
}
