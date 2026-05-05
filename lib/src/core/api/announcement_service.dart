import '../models/api_models.dart';
import '../models/app_models.dart';
import 'api_client.dart';
import 'api_config.dart';

class AnnouncementService {
  AnnouncementService._();

  /// Filter announcements for tenant.
  static Future<({List<AnnouncementRecord> announcements, int count})>
      filterTenantAnnouncements({
    int skip = 0,
    int limit = 50,
    String? search,
  }) async {
    final ApiResponse response = await ApiClient.instance.post(
      ApiConfig.filterTenantAnnouncements,
      <String, dynamic>{
        'Skip': skip,
        'Limit': limit,
        'Whether_Search_Filter': search != null && search.isNotEmpty,
        'Search': search ?? '',
      },
    );

    return _parseAnnouncementResponse(response);
  }

  /// Filter announcements for a society.
  static Future<({List<AnnouncementRecord> announcements, int count})>
      filterSocietyAnnouncements({
    required String societyId,
    int skip = 0,
    int limit = 50,
    String? search,
    int? priority,
    String? blockId,
    String? buildingId,
  }) async {
    final ApiResponse response = await ApiClient.instance.post(
      ApiConfig.filterSocietyAnnouncements,
      <String, dynamic>{
        'SocietyID': societyId,
        'Skip': skip,
        'Limit': limit,
        'Whether_Search_Filter': search != null && search.isNotEmpty,
        if (search != null) 'Search': search,
        'Whether_Priority_Filter': priority != null,
        if (priority != null) 'Priority': priority,
        'Whether_BlockID_Filter': blockId != null && blockId.isNotEmpty,
        if (blockId != null && blockId.isNotEmpty) 'BlockID': <String>[blockId],
        'Whether_BuildingID_Filter':
            buildingId != null && buildingId.isNotEmpty,
        if (buildingId != null && buildingId.isNotEmpty)
          'BuildingID': <String>[buildingId],
      },
    );

    return _parseAnnouncementResponse(response);
  }

  static Future<ApiResponse> createAnnouncement({
    required String societyId,
    required String title,
    required String description,
    required int priority,
    List<String> blockIds = const <String>[],
    List<String> buildingIds = const <String>[],
  }) async {
    return ApiClient.instance.post(
      ApiConfig.createAnnouncement,
      <String, dynamic>{
        'SocietyID': societyId,
        'Title': title,
        'Description': description,
        'Priority': priority,
        'Whether_Block_Array_Available': blockIds.isNotEmpty,
        'BlockID_Array': blockIds,
        'Whether_Building_Array_Available': buildingIds.isNotEmpty,
        'BuildingID_Array': buildingIds,
      },
    );
  }

  static Future<ApiResponse> editAnnouncement({
    required String announcementId,
    required String title,
    required String description,
    required int priority,
    List<String> blockIds = const <String>[],
    List<String> buildingIds = const <String>[],
  }) async {
    return ApiClient.instance.post(
      ApiConfig.editAnnouncement,
      <String, dynamic>{
        'Society_AnnouncementID': announcementId,
        'Title': title,
        'Description': description,
        'Priority': priority,
        'Whether_Block_Array_Available': blockIds.isNotEmpty,
        'BlockID_Array': blockIds,
        'Whether_Building_Array_Available': buildingIds.isNotEmpty,
        'BuildingID_Array': buildingIds,
      },
    );
  }

  static ({List<AnnouncementRecord> announcements, int count})
      _parseAnnouncementResponse(ApiResponse response) {
    if (!response.success || response.data == null) {
      return (announcements: <AnnouncementRecord>[], count: 0);
    }

    final List<dynamic> dataList = response.data as List<dynamic>;
    final List<AnnouncementRecord> announcements = dataList
        .map((dynamic item) =>
            AnnouncementData.fromJson(item as Map<String, dynamic>)
                .toAnnouncementRecord())
        .toList();

    return (
      announcements: announcements,
      count: response.count ?? announcements.length,
    );
  }
}
