import '../models/api_models.dart';
import 'api_client.dart';
import 'api_config.dart';

class PropertyWishlistService {
  PropertyWishlistService._();

  static Future<({Set<String> propertyIds, List<PropertyData> properties})>
  filterWishlist({
    int skip = 0,
    int limit = 1000,
  }) async {
    final ApiResponse response = await ApiClient.instance.post(
      ApiConfig.filterWishlistProperties,
      <String, dynamic>{
        'Skip': skip,
        'Limit': limit,
      },
    );

    if (!response.success) {
      throw Exception(response.message ?? 'Failed to fetch wishlist.');
    }

    final List<dynamic> rawPropertyIds =
        response.extras['PropertyIDs'] as List<dynamic>? ?? <dynamic>[];
    final Set<String> propertyIds = rawPropertyIds
        .map((dynamic value) => value.toString().trim())
        .where((String value) => value.isNotEmpty)
        .toSet();

    final List<dynamic> rawData =
        response.extras['Data'] as List<dynamic>? ?? <dynamic>[];
    final List<PropertyData> properties = rawData
        .whereType<Map<String, dynamic>>()
        .map(PropertyData.fromJson)
        .toList();

    return (propertyIds: propertyIds, properties: properties);
  }

  static Future<void> addProperty(String propertyId) async {
    final ApiResponse response = await ApiClient.instance.post(
      ApiConfig.addPropertyWishlist,
      <String, dynamic>{'PropertyID': propertyId},
    );

    if (!response.success) {
      throw Exception(response.message ?? 'Failed to add wishlist.');
    }
  }

  static Future<void> removeProperty(String propertyId) async {
    final ApiResponse response = await ApiClient.instance.post(
      ApiConfig.removePropertyWishlist,
      <String, dynamic>{'PropertyID': propertyId},
    );

    if (!response.success) {
      throw Exception(response.message ?? 'Failed to remove wishlist.');
    }
  }
}
