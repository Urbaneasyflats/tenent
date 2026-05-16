import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import 'api_config.dart';
import 'auth_storage.dart';

class ApiResponse {
  const ApiResponse({
    required this.success,
    required this.extras,
  });

  final bool success;
  final Map<String, dynamic> extras;

  int? get code => extras['code'] as int?;
  String? get status => extras['Status'] as String?;
  String? get message => extras['msg'] as String?;
  dynamic get data => extras['Data'];
  int? get count => extras['Count'] as int?;
}

typedef LogoutCallback = void Function();

class ApiClient {
  ApiClient._();

  static const String offlineMessage =
      "hey! Looks like your internet isnt connected.";

  static final ApiClient instance = ApiClient._();

  LogoutCallback? onSessionExpired;

  bool _isRefreshing = false;
  final List<Completer<ApiResponse>> _pendingRequests =
      <Completer<ApiResponse>>[];

  Future<ApiResponse> post(
    String endpoint, [
    Map<String, dynamic>? body,
  ]) async {
    final Map<String, dynamic> requestBody = <String, dynamic>{
      ...?body,
    };

    // Auto-inject credentials
    final String? apiKey = AuthStorage.apiKey;
    final String? sessionId = AuthStorage.sessionId;
    final String? vendorId = AuthStorage.vendorId;

    if (apiKey != null && apiKey.isNotEmpty) {
      requestBody['ApiKey'] = apiKey;
    }
    if (sessionId != null && sessionId.isNotEmpty) {
      requestBody['SessionID'] = sessionId;
    }
    if (vendorId != null && vendorId.isNotEmpty) {
      requestBody['VendorID'] = vendorId;
    }

    final Uri url = Uri.parse('${ApiConfig.baseUrl}$endpoint');

    final http.Response response;
    try {
      response = await http.post(
        url,
        headers: <String, String>{
          'Content-Type': 'application/json',
        },
        body: jsonEncode(requestBody),
      ).timeout(AuthServiceTimeouts.network);
    } on SocketException {
      throw Exception(offlineMessage);
    } on TimeoutException {
      throw Exception(offlineMessage);
    } on http.ClientException {
      throw Exception(offlineMessage);
    }

    final Map<String, dynamic> json = _decodeResponse(response, endpoint);
    final bool success = json['success'] as bool? ?? false;
    final Map<String, dynamic> extras =
        (json['extras'] as Map<String, dynamic>?) ?? <String, dynamic>{};

    final ApiResponse apiResponse = ApiResponse(
      success: success,
      extras: extras,
    );

    // Handle error codes
    if (!success) {
      final int? code = apiResponse.code;

      if (code == 1) {
        // Session expired
        await AuthStorage.clearAll();
        onSessionExpired?.call();
        return apiResponse;
      }

      if (code == 2 &&
          (apiResponse.message ?? '').toLowerCase().contains('api key')) {
        // Invalid API key - refresh and retry
        return _handleApiKeyRefresh(endpoint, body);
      }
    }

    return apiResponse;
  }

  Future<ApiResponse> _handleApiKeyRefresh(
    String endpoint,
    Map<String, dynamic>? originalBody,
  ) async {
    if (_isRefreshing) {
      // Queue this request to retry after refresh completes
      final Completer<ApiResponse> completer = Completer<ApiResponse>();
      _pendingRequests.add(completer);
      return completer.future;
    }

    _isRefreshing = true;

    try {
      // Step 1: Generate new DeviceID
      final Uri deviceUrl =
          Uri.parse('${ApiConfig.baseUrl}${ApiConfig.generateDeviceId}');
      final http.Response deviceResponse = await http.post(
        deviceUrl,
        headers: <String, String>{'Content-Type': 'application/json'},
        body: jsonEncode(<String, dynamic>{}),
      ).timeout(AuthServiceTimeouts.network);
      final Map<String, dynamic> deviceJson = _decodeResponse(
        deviceResponse,
        ApiConfig.generateDeviceId,
      );
      final Map<String, dynamic> deviceExtras =
          (deviceJson['extras'] as Map<String, dynamic>?) ??
              <String, dynamic>{};
      final String? newDeviceId = deviceExtras['DeviceID'] as String?;

      if (newDeviceId != null) {
        await AuthStorage.setDeviceId(newDeviceId);
      }

      // Step 2: Get new ApiKey via Splash
      final Uri splashUrl =
          Uri.parse('${ApiConfig.baseUrl}${ApiConfig.splashScreen}');
      final http.Response splashResponse = await http.post(
        splashUrl,
        headers: <String, String>{'Content-Type': 'application/json'},
        body: jsonEncode(<String, dynamic>{
          'DeviceID': newDeviceId ?? AuthStorage.deviceId,
          'DeviceType': 3,
          'DeviceName': 'Mobile-Client',
          'AppVersion': 1,
        }),
      ).timeout(AuthServiceTimeouts.network);
      final Map<String, dynamic> splashJson = _decodeResponse(
        splashResponse,
        ApiConfig.splashScreen,
      );
      final Map<String, dynamic> splashExtras =
          (splashJson['extras'] as Map<String, dynamic>?) ??
              <String, dynamic>{};
      final Map<String, dynamic>? splashData =
          splashExtras['Data'] as Map<String, dynamic>?;
      final String? newApiKey = splashData?['ApiKey'] as String?;

      if (newApiKey != null) {
        await AuthStorage.setApiKey(newApiKey);
      }

      _isRefreshing = false;

      // Retry the original request
      final ApiResponse retryResponse = await post(endpoint, originalBody);

      // Resolve all pending requests by retrying them
      // (they will re-read the new ApiKey from storage)
      for (final Completer<ApiResponse> completer in _pendingRequests) {
        completer.complete(retryResponse);
      }
      _pendingRequests.clear();

      return retryResponse;
    } on SocketException {
      final Exception error = Exception(offlineMessage);
      _isRefreshing = false;
      for (final Completer<ApiResponse> completer in _pendingRequests) {
        completer.completeError(error);
      }
      _pendingRequests.clear();
      throw error;
    } on TimeoutException {
      final Exception error = Exception(offlineMessage);
      _isRefreshing = false;
      for (final Completer<ApiResponse> completer in _pendingRequests) {
        completer.completeError(error);
      }
      _pendingRequests.clear();
      throw error;
    } on http.ClientException {
      final Exception error = Exception(offlineMessage);
      _isRefreshing = false;
      for (final Completer<ApiResponse> completer in _pendingRequests) {
        completer.completeError(error);
      }
      _pendingRequests.clear();
      throw error;
    } catch (e) {
      _isRefreshing = false;
      for (final Completer<ApiResponse> completer in _pendingRequests) {
        completer.completeError(e);
      }
      _pendingRequests.clear();
      rethrow;
    }
  }

  Map<String, dynamic> _decodeResponse(http.Response response, String endpoint) {
    final String contentType = response.headers['content-type'] ?? '';
    final String body = response.body.trimLeft();
    final bool looksJson = body.startsWith('{') || body.startsWith('[');

    if (!contentType.toLowerCase().contains('json') && !looksJson) {
      throw Exception('Unable to load data. Please try again later.');
    }

    try {
      final dynamic decoded = jsonDecode(response.body);
      if (decoded is Map<String, dynamic>) {
        return decoded;
      }
    } on FormatException {
      throw Exception('Unable to load data. Please try again later.');
    }

    throw Exception('Unable to load data. Please try again later.');
  }
}

class AuthServiceTimeouts {
  AuthServiceTimeouts._();

  static const Duration network = Duration(seconds: 12);
}
