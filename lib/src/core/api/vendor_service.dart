import '../models/api_models.dart';
import 'api_client.dart';
import 'api_config.dart';

class VendorService {
  VendorService._();

  static const Duration startupTimeout = Duration(seconds: 12);

  static Future<VendorData?> fetchVendorInfo() async {
    final ApiResponse response = await ApiClient.instance
        .post(ApiConfig.fetchVendorInfo)
        .timeout(startupTimeout);

    if (response.success && response.data != null) {
      return VendorData.fromJson(response.data as Map<String, dynamic>);
    }
    return null;
  }

  static Future<ApiResponse> setVendorProfile({
    required String fullName,
    required String email,
    String? imageId,
  }) async {
    return ApiClient.instance.post(
      ApiConfig.setVendorProfile,
      <String, dynamic>{
        'Full_Name': fullName,
        'EmailID': email,
        'Whether_Image_Available': imageId != null,
        if (imageId != null) 'ImageID': imageId,
      },
    );
  }

  static Future<ApiResponse> requestAccountDeletion({String reason = ''}) {
    return ApiClient.instance.post(
      ApiConfig.requestAccountDeletion,
      <String, dynamic>{'Reason': reason},
    );
  }
}
