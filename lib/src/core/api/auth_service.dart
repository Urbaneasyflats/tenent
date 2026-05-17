import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import 'api_client.dart';
import 'api_config.dart';
import 'auth_storage.dart';

class AuthService {
  AuthService._();

  static const String offlineMessage = ApiClient.offlineMessage;
  static const Duration startupTimeout = Duration(seconds: 12);

  static Future<void> ensureStorageInitialized() => AuthStorage.init();

  /// Initialize app: generate DeviceID + get ApiKey.
  /// Call this at app startup before any other API calls.
  static Future<bool> initializeApp() async {
    await AuthStorage.init();

    // If we already have a DeviceID and ApiKey, skip
    if (AuthStorage.deviceId != null &&
        AuthStorage.deviceId!.isNotEmpty &&
        AuthStorage.apiKey != null &&
        AuthStorage.apiKey!.isNotEmpty) {
      try {
        await _syncStoredPushToken();
      } catch (_) {}
      return true;
    }

    try {
      final String? deviceId = await generateDeviceId();
      if (deviceId == null) return false;

      final String? apiKey = await getApiKey(deviceId);
      if (apiKey != null) {
        try {
          await _syncStoredPushToken();
        } catch (_) {}
      }
      return apiKey != null;
    } catch (_) {
      return false;
    }
  }

  /// Step 1: Generate a DeviceID from the server.
  static Future<String?> generateDeviceId() async {
    final Uri url =
        Uri.parse('${ApiConfig.baseUrl}${ApiConfig.generateDeviceId}');
    final http.Response response;
    try {
      response = await http.post(
        url,
        headers: <String, String>{'Content-Type': 'application/json'},
        body: jsonEncode(<String, dynamic>{}),
      ).timeout(startupTimeout);
    } on SocketException {
      throw Exception(offlineMessage);
    } on TimeoutException {
      throw Exception(offlineMessage);
    } on http.ClientException {
      throw Exception(offlineMessage);
    }

    final Map<String, dynamic> json;
    try {
      json = jsonDecode(response.body) as Map<String, dynamic>;
    } on FormatException {
      throw Exception('Unable to load data. Please try again later.');
    } on TypeError {
      throw Exception('Unable to load data. Please try again later.');
    }
    final Map<String, dynamic> extras =
        (json['extras'] as Map<String, dynamic>?) ?? <String, dynamic>{};
    final String? deviceId = extras['DeviceID'] as String?;

    if (deviceId != null) {
      await AuthStorage.setDeviceId(deviceId);
    }
    return deviceId;
  }

  /// Step 2: Get ApiKey via splash screen.
  static Future<String?> getApiKey(String deviceId) async {
    final Uri url =
        Uri.parse('${ApiConfig.baseUrl}${ApiConfig.splashScreen}');
    final http.Response response;
    try {
      response = await http.post(
        url,
        headers: <String, String>{'Content-Type': 'application/json'},
        body: jsonEncode(<String, dynamic>{
          'DeviceID': deviceId,
          'DeviceType': 3,
          'DeviceName': 'Mobile-Client',
          'AppVersion': 1,
        }),
      ).timeout(startupTimeout);
    } on SocketException {
      throw Exception(offlineMessage);
    } on TimeoutException {
      throw Exception(offlineMessage);
    } on http.ClientException {
      throw Exception(offlineMessage);
    }

    final Map<String, dynamic> json;
    try {
      json = jsonDecode(response.body) as Map<String, dynamic>;
    } on FormatException {
      throw Exception('Unable to load data. Please try again later.');
    } on TypeError {
      throw Exception('Unable to load data. Please try again later.');
    }
    final Map<String, dynamic> extras =
        (json['extras'] as Map<String, dynamic>?) ?? <String, dynamic>{};
    final Map<String, dynamic>? data =
        extras['Data'] as Map<String, dynamic>?;
    final String? apiKey = data?['ApiKey'] as String?;

    if (apiKey != null) {
      await AuthStorage.setApiKey(apiKey);
    }
    return apiKey;
  }

  static Future<void> updateFcmToken(String fcmToken) async {
    final String normalizedToken = fcmToken.trim();
    if (normalizedToken.isEmpty) {
      return;
    }

    if (AuthStorage.apiKey == null ||
        AuthStorage.apiKey!.isEmpty ||
        AuthStorage.vendorId == null ||
        AuthStorage.vendorId!.isEmpty) {
      return;
    }

    final ApiResponse response = await ApiClient.instance.post(
      ApiConfig.updateFcmToken,
      <String, dynamic>{'FCM_Token': normalizedToken},
    );

    if (!response.success) {
      throw Exception(
        response.status ?? 'Failed to update FCM token.',
      );
    }
  }

  /// Step 3: Request OTP for phone number.
  static Future<ApiResponse> generateOtp(
    String phone, {
    required int vendorType,
  }) async {
    return ApiClient.instance.post(ApiConfig.generateOtp, <String, dynamic>{
      'Vendor_Type': vendorType,
      'CountryCode': '+91',
      'PhoneNumber': phone,
    });
  }

  /// Step 4: Validate OTP and get session credentials.
  static Future<ApiResponse> validateOtp(
    String phone,
    String otp, {
    required int vendorType,
  }) async {
    final ApiResponse response = await ApiClient.instance.post(
      ApiConfig.validateOtp,
      <String, dynamic>{
        'Vendor_Type': vendorType,
        'CountryCode': '+91',
        'PhoneNumber': phone,
        'OTP': int.tryParse(otp) ?? otp,
      },
    );

    if (response.success && response.data != null) {
      final Map<String, dynamic> data =
          response.data as Map<String, dynamic>;
      final String? sessionId = data['SessionID'] as String?;
      final String? vendorId = data['VendorID'] as String?;
      final int? vendorType = data['Vendor_Type'] as int?;
      final bool blocked = data['Whether_Account_Blocked_By_Admin'] == true;
      final String blockReason = (data['Account_Block_Reason'] as String?) ?? '';

      if (sessionId != null && vendorId != null) {
        await AuthStorage.saveLoginCredentials(
          sessionId: sessionId,
          vendorId: vendorId,
          vendorType: vendorType,
        );
        await AuthStorage.setWhetherAccountBlockedByAdmin(blocked);
        await AuthStorage.setAccountBlockReason(blockReason);
        await _syncStoredPushToken();
      }
    }

    return response;
  }

  static Future<void> registerPushToken(String pushToken) async {
    final String normalizedToken = pushToken.trim();
    if (normalizedToken.isEmpty) {
      return;
    }

    await AuthStorage.setPushToken(normalizedToken);
    await _syncStoredPushToken();
  }

  /// Logout: clear stored credentials.
  static Future<void> logout() async {
    await _clearRemotePushToken();
    await AuthStorage.clearAll();
  }

  static Future<void> _clearRemotePushToken() async {
    if (AuthStorage.apiKey == null ||
        AuthStorage.apiKey!.isEmpty ||
        AuthStorage.sessionId == null ||
        AuthStorage.sessionId!.isEmpty ||
        AuthStorage.vendorId == null ||
        AuthStorage.vendorId!.isEmpty) {
      return;
    }

    try {
      await ApiClient.instance.post(
        ApiConfig.clearFcmToken,
        <String, dynamic>{
          'FCM_Token': AuthStorage.pushToken ?? '',
        },
      );
    } catch (_) {}
  }

  static Future<void> _syncStoredPushToken() async {
    final String? pushToken = AuthStorage.pushToken?.trim();
    if (pushToken == null || pushToken.isEmpty) {
      return;
    }

    final String syncKey = '${AuthStorage.vendorId ?? ''}:$pushToken';
    if (AuthStorage.lastSyncedPushToken == syncKey) {
      return;
    }

    await updateFcmToken(pushToken);
    await AuthStorage.setLastSyncedPushToken(syncKey);
  }
}
