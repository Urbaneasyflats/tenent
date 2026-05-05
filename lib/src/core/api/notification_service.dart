import '../models/api_models.dart';
import 'api_client.dart';
import 'api_config.dart';

class NotificationService {
  NotificationService._();

  static Future<({List<NotificationData> notifications, int count, int unreadCount})>
      filterNotifications({
    int skip = 0,
    int limit = 10,
    bool? read,
    String? search,
  }) async {
    final ApiResponse response = await ApiClient.instance.post(
      ApiConfig.filterNotifications,
      <String, dynamic>{
        'Skip': skip,
        'Limit': limit,
        'Whether_Read_Filter': read != null,
        if (read != null) 'Whether_Read': read,
        'Whether_Search_Filter': search != null && search.isNotEmpty,
        if (search != null) 'Search': search,
      },
    );

    if (!response.success || response.data == null) {
      return (notifications: <NotificationData>[], count: 0, unreadCount: 0);
    }

    final List<dynamic> dataList = response.data as List<dynamic>;
    final List<NotificationData> notifications = dataList
        .map((dynamic item) =>
            NotificationData.fromJson(item as Map<String, dynamic>))
        .toList();

    return (
      notifications: notifications,
      count: response.count ?? notifications.length,
      unreadCount:
          (response.extras['Unread_Count'] as num?)?.toInt() ??
          notifications.where((NotificationData n) => !n.isRead).length,
    );
  }

  static Future<ApiResponse> markAsRead(String notificationId) async {
    return ApiClient.instance.post(
      ApiConfig.markNotificationAsRead,
      <String, dynamic>{'Vendor_NotificationID': notificationId},
    );
  }

  static Future<ApiResponse> markAllAsRead() async {
    return ApiClient.instance.post(ApiConfig.markAllNotificationsAsRead);
  }
}
