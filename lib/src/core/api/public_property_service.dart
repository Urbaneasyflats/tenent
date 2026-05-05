import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/api_models.dart';
import 'api_config.dart';
import 'auth_storage.dart';

class PublicPropertyService {
  PublicPropertyService._();

  static const String _baseUrl = ApiConfig.userBaseUrl;

  static Future<({List<PropertyData> properties, int count})> filterProperties({
    int skip = 0,
    int limit = 15,
    String search = '',
    int? propertyType,
    int? subType,
    int? categoryType,
    int? pgSharingType,
    String? cityId,
    double latitude = 0,
    double longitude = 0,
  }) async {
    final Map<String, dynamic> body = <String, dynamic>{
      'ApiKey': AuthStorage.apiKey ?? '',
      'Latitude': latitude,
      'Longitude': longitude,
      'Skip': skip,
      'Limit': limit,
      'Whether_Status_Filter': true,
      'Status': true,
      'Whether_Property_Type_Filter': propertyType != null,
      'Property_Type': propertyType ?? 1,
      'Whether_Category_Type_Filter': categoryType != null,
      'Category_Type': categoryType ?? 1,
      'Whether_Sub_Type_Filter': subType != null,
      'Sub_Type': subType ?? 1,
      'Whether_PG_Sharing_Type_Filter': pgSharingType != null,
      'PG_Sharing_Type': pgSharingType ?? 1,
      'Whether_Search_Filter': search.trim().isNotEmpty,
      'Search': search.trim(),
      'Whether_City_Filter': cityId != null && cityId.isNotEmpty,
      'CityID': cityId ?? '',
    };

    final ApiEnvelope response = await _post(
      ApiConfig.userFilterAllProperties,
      body,
    );
    if (!response.success) {
      final String message = response.message ?? 'Failed to fetch properties.';
      if (message.toLowerCase().contains('database error')) {
        return (properties: <PropertyData>[], count: 0);
      }
      throw Exception(message);
    }

    final List<dynamic> data =
        response.extras['Data'] as List<dynamic>? ?? <dynamic>[];
    final List<PropertyData> properties = data
        .whereType<Map<String, dynamic>>()
        .map(PropertyData.fromJson)
        .toList();

    return (properties: properties, count: response.count ?? 0);
  }

  static Future<List<PublicCityData>> filterCities({
    int skip = 0,
    int limit = 1000,
    String stateId = '',
    String search = '',
  }) async {
    final ApiEnvelope response =
        await _post(ApiConfig.userFilterAllCities, <String, dynamic>{
          'Skip': skip,
          'Limit': limit,
          'Whether_State_Filter': stateId.trim().isNotEmpty,
          'StateID': stateId.trim(),
          'Whether_Search_Filter': search.trim().isNotEmpty,
          'Search': search.trim(),
        });

    if (!response.success) {
      throw Exception(response.message ?? 'Failed to fetch cities.');
    }

    final List<dynamic> data =
        response.extras['Data'] as List<dynamic>? ?? <dynamic>[];
    return data
        .whereType<Map<String, dynamic>>()
        .map(PublicCityData.fromJson)
        .where((PublicCityData city) => city.cityId.isNotEmpty)
        .toList();
  }

  static Future<void> generateUserOtp(String phoneNumber) async {
    final ApiEnvelope response = await _post(
      ApiConfig.userGenerateOtp,
      <String, dynamic>{
        'CountryCode': '+91',
        'PhoneNumber': _normalizePhone(phoneNumber),
      },
    );

    if (!response.success) {
      throw Exception(response.message ?? 'Failed to send OTP.');
    }
  }

  static Future<void> createPropertyEnquiry({
    required String propertyId,
    required String name,
    required String email,
    required String phoneNumber,
    required String otp,
  }) async {
    final ApiEnvelope response =
        await _post(ApiConfig.userCreatePropertyEnquiry, <String, dynamic>{
          'PropertyID': propertyId,
          'Name': name.trim(),
          'EmailID': email.trim(),
          'CountryCode': '+91',
          'PhoneNumber': _normalizePhone(phoneNumber),
          'OTP': otp.trim(),
        });

    if (!response.success) {
      throw Exception(response.message ?? 'Failed to submit enquiry.');
    }
  }

  static Future<ApiEnvelope> _post(
    String endpoint,
    Map<String, dynamic> body,
  ) async {
    final http.Response response = await http.post(
      Uri.parse('$_baseUrl$endpoint'),
      headers: <String, String>{'Content-Type': 'application/json'},
      body: jsonEncode(body),
    );

    final Map<String, dynamic> json =
        jsonDecode(response.body) as Map<String, dynamic>;
    return ApiEnvelope.fromJson(json);
  }

  static String _normalizePhone(String value) {
    final String phone = value.replaceAll(RegExp(r'\D'), '');
    if (!RegExp(r'^[6-9]\d{9}$').hasMatch(phone)) {
      throw Exception('Enter a valid 10-digit mobile number.');
    }
    return phone;
  }
}

class ApiEnvelope {
  const ApiEnvelope({required this.success, required this.extras});

  factory ApiEnvelope.fromJson(Map<String, dynamic> json) {
    return ApiEnvelope(
      success: json['success'] as bool? ?? false,
      extras: json['extras'] as Map<String, dynamic>? ?? <String, dynamic>{},
    );
  }

  final bool success;
  final Map<String, dynamic> extras;

  int? get count => extras['Count'] as int?;
  String? get message =>
      extras['msg'] as String? ?? extras['Status'] as String?;
}
