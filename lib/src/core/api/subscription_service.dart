import '../models/api_models.dart';
import 'api_client.dart';
import 'api_config.dart';

class SubscriptionService {
  SubscriptionService._();

  static Future<({List<SubscriptionPlanData> plans, int count})>
      filterSubscriptions({
    required int propertyType,
    int skip = 0,
    int limit = 10,
  }) async {
    final ApiResponse response = await ApiClient.instance.post(
      ApiConfig.filterSubscriptions,
      <String, dynamic>{
        'Whether_Subscription_Type_Filter': true,
        'Subscription_Type': propertyType,
        'Skip': skip,
        'Limit': limit,
      },
    );

    if (!response.success || response.data == null) {
      return (plans: <SubscriptionPlanData>[], count: 0);
    }

    final List<dynamic> dataList = response.data as List<dynamic>;
    final List<SubscriptionPlanData> plans = dataList
        .map((dynamic item) =>
            SubscriptionPlanData.fromJson(item as Map<String, dynamic>))
        .where((SubscriptionPlanData item) => item.isActive)
        .toList();

    return (plans: plans, count: response.count ?? plans.length);
  }

  static Future<SubscriptionCalculationData?> calculateSubscription({
    required String propertyId,
    required String subscriptionId,
    int extraResidentContracts = 0,
  }) async {
    final ApiResponse response = await ApiClient.instance.post(
      ApiConfig.calculateSubscription,
      <String, dynamic>{
        'PropertyID': propertyId,
        'SubscriptionID': subscriptionId,
        'Extra_Resident_Contracts': extraResidentContracts,
      },
    );

    if (!response.success || response.data == null) {
      return null;
    }

    return SubscriptionCalculationData.fromJson(
      response.data as Map<String, dynamic>,
    );
  }

  static Future<ApiResponse> purchaseSubscription({
    required String propertyId,
    required String subscriptionId,
    int extraResidentContracts = 0,
  }) async {
    return ApiClient.instance.post(
      ApiConfig.purchaseSubscription,
      <String, dynamic>{
        'PropertyID': propertyId,
        'SubscriptionID': subscriptionId,
        'Extra_Resident_Contracts': extraResidentContracts,
      },
    );
  }
}
