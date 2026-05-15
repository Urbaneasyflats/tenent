import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

import 'api_client.dart' show ApiClient, ApiResponse;
import 'api_config.dart';
import 'auth_storage.dart';

class UploadService {
  UploadService._();

  static MediaType? _mediaTypeFromPath(String path) {
    final String ext = path.split('.').last.toLowerCase();
    return switch (ext) {
      'jpg' || 'jpeg' => MediaType('image', 'jpeg'),
      'png' => MediaType('image', 'png'),
      'gif' => MediaType('image', 'gif'),
      'webp' => MediaType('image', 'webp'),
      'pdf' => MediaType('application', 'pdf'),
      'mp4' => MediaType('video', 'mp4'),
      'mp3' => MediaType('audio', 'mpeg'),
      _ => null,
    };
  }

  static Future<Map<String, dynamic>?> _uploadMultipart(
    File file, {
    required String endpoint,
    Map<String, String> fields = const <String, String>{},
    String fileField = 'file',
  }) async {
    final Uri url = Uri.parse('${ApiConfig.uploadBaseUrl}$endpoint');

    final http.MultipartRequest request = http.MultipartRequest('POST', url);

    // Match web app: upload endpoint does not require auth fields.
    request.fields.addAll(fields);

    final MediaType? contentType = _mediaTypeFromPath(file.path);
    final http.MultipartFile multipartFile =
        await http.MultipartFile.fromPath(
      fileField,
      file.path,
      contentType: contentType,
    );
    request.files.add(multipartFile);

    final http.StreamedResponse streamedResponse;
    try {
      streamedResponse = await request.send();
    } on SocketException {
      throw Exception(ApiClient.offlineMessage);
    } on TimeoutException {
      throw Exception(ApiClient.offlineMessage);
    } on http.ClientException {
      throw Exception(ApiClient.offlineMessage);
    }
    final String responseBody =
        await streamedResponse.stream.bytesToString();

    final Map<String, dynamic> json;
    try {
      json = jsonDecode(responseBody) as Map<String, dynamic>;
    } on FormatException {
      throw Exception('Unable to upload file. Please try again later.');
    } on TypeError {
      throw Exception('Unable to upload file. Please try again later.');
    }

    final bool success = json['success'] as bool? ?? false;
    if (!success) {
      final Map<String, dynamic> extras =
          (json['extras'] as Map<String, dynamic>?) ?? <String, dynamic>{};
      final String? message =
          extras['Message'] as String? ?? extras['msg'] as String?;
      throw Exception(message ?? 'Upload failed. Please try again later.');
    }

    final Map<String, dynamic> extras =
        (json['extras'] as Map<String, dynamic>?) ?? <String, dynamic>{};
    return extras['Data'] as Map<String, dynamic>?;
  }

  static Future<String?> uploadImage(File file) async {
    final Map<String, dynamic>? data = await _uploadMultipart(
      file,
      endpoint: ApiConfig.uploadImage,
      fields: const <String, String>{'Image_Type': '1'},
      fileField: 'file',
    );
    final String? id = _readString(data, <String>['ImageID']);
    if (id == null && data != null) {
      throw Exception('Server did not return an image ID');
    }
    return id;
  }

  static Future<String?> fetchImageInfo(String imageId) async {
    final ApiResponse response = await _postToUploadBase(
      ApiConfig.fetchImageInfo,
      <String, dynamic>{'ImageID': imageId},
    );

    if (response.success && response.data != null) {
      final Map<String, dynamic> data =
          response.data as Map<String, dynamic>;
      return data['Image_Original_URL'] as String?;
    }
    return null;
  }

  static Future<ApiResponse> removeImage(String imageId) async {
    return _postToUploadBase(
      ApiConfig.removeImage,
      <String, dynamic>{'ImageID': imageId},
    );
  }

  static Future<String?> uploadVideo(
    File file, {
    String? imageId,
  }) async {
    final Map<String, String> fields = <String, String>{
      'Whether_Image_Available':
          (imageId != null && imageId.trim().isNotEmpty).toString(),
      if (imageId != null && imageId.trim().isNotEmpty)
        'ImageID': imageId.trim(),
    };
    final Map<String, dynamic>? data = await _uploadMultipart(
      file,
      endpoint: ApiConfig.uploadVideo,
      fields: fields,
      fileField: 'file',
    );
    return _readString(data, <String>['VideoID']);
  }

  static Future<String?> fetchVideoInfo(String videoId) async {
    final ApiResponse response = await _postToUploadBase(
      ApiConfig.fetchVideoInfo,
      <String, dynamic>{'VideoID': videoId},
    );

    if (response.success && response.data != null) {
      final Map<String, dynamic> data =
          response.data as Map<String, dynamic>;
      return _readString(
        data,
        <String>['Video_Original_URL', 'Video_URL'],
      );
    }
    return null;
  }

  static Future<ApiResponse> removeVideo(String videoId) async {
    return _postToUploadBase(
      ApiConfig.removeVideo,
      <String, dynamic>{'VideoID': videoId},
    );
  }

  static Future<String?> uploadAudio(File file) async {
    final Map<String, dynamic>? data = await _uploadMultipart(
      file,
      endpoint: ApiConfig.uploadAudio,
      fileField: 'file',
    );
    return _readString(data, <String>['AudioID']);
  }

  static Future<String?> fetchAudioInfo(String audioId) async {
    final ApiResponse response = await _postToUploadBase(
      ApiConfig.fetchAudioInfo,
      <String, dynamic>{'AudioID': audioId},
    );

    if (response.success && response.data != null) {
      final Map<String, dynamic> data =
          response.data as Map<String, dynamic>;
      return _readString(data, <String>['Audio_URL']);
    }
    return null;
  }

  static Future<ApiResponse> removeAudio(String audioId) async {
    return _postToUploadBase(
      ApiConfig.removeAudio,
      <String, dynamic>{'AudioID': audioId},
    );
  }

  static Future<String?> uploadDocument(File file) async {
    final Map<String, dynamic>? data = await _uploadMultipart(
      file,
      endpoint: ApiConfig.uploadDocument,
      fileField: 'file',
    );
    return _readString(data, <String>['DocumentID']);
  }

  static Future<String?> fetchDocumentInfo(String documentId) async {
    final ApiResponse response = await _postToUploadBase(
      ApiConfig.fetchDocumentInfo,
      <String, dynamic>{'DocumentID': documentId},
    );

    if (response.success && response.data != null) {
      final Map<String, dynamic> data =
          response.data as Map<String, dynamic>;
      return data['Document_URL'] as String?;
    }
    return null;
  }

  static Future<ApiResponse> removeDocument(String documentId) async {
    return _postToUploadBase(
      ApiConfig.removeDocument,
      <String, dynamic>{'DocumentID': documentId},
    );
  }

  static Future<ApiResponse> _postToUploadBase(
    String endpoint,
    Map<String, dynamic> body,
  ) async {
    final Map<String, dynamic> requestBody = <String, dynamic>{...body};

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

    final Uri url = Uri.parse('${ApiConfig.uploadBaseUrl}$endpoint');
    final http.Response response;
    try {
      response = await http.post(
        url,
        headers: <String, String>{
          'Content-Type': 'application/json',
        },
        body: jsonEncode(requestBody),
      );
    } on SocketException {
      throw Exception(ApiClient.offlineMessage);
    } on TimeoutException {
      throw Exception(ApiClient.offlineMessage);
    } on http.ClientException {
      throw Exception(ApiClient.offlineMessage);
    }

    final Map<String, dynamic> json;
    try {
      json = jsonDecode(response.body) as Map<String, dynamic>;
    } on FormatException {
      throw Exception('Unable to load data. Please try again later.');
    } on TypeError {
      throw Exception('Unable to load data. Please try again later.');
    }
    return ApiResponse(
      success: json['success'] as bool? ?? false,
      extras: (json['extras'] as Map<String, dynamic>?) ??
          <String, dynamic>{},
    );
  }

  static String? _readString(
    Map<String, dynamic>? data,
    List<String> keys,
  ) {
    if (data == null) {
      return null;
    }

    for (final String key in keys) {
      final String? value = data[key] as String?;
      if (value != null && value.isNotEmpty) {
        return value;
      }
    }
    return null;
  }
}
