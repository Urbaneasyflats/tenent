import '../models/api_models.dart';
import '../models/app_models.dart';
import 'api_client.dart';
import 'api_config.dart';

class IncidentService {
  IncidentService._();

  /// Filter tenant incidents as incident records.
  static Future<({List<IncidentRecord> incidents, int count})>
      filterTenantIncidentRecords({
    int skip = 0,
    int limit = 50,
    String? search,
    IncidentStatus? status,
    String? blockId,
    String? buildingId,
  }) async {
    final ApiResponse response = await ApiClient.instance.post(
      ApiConfig.filterTenantIncidents,
      <String, dynamic>{
        'Skip': skip,
        'Limit': limit,
        'Whether_Search_Filter': search != null && search.isNotEmpty,
        if (search != null) 'Search': search,
        'Whether_Incident_Status_Filter': status != null,
        if (status != null) 'Incident_Status': _statusToApi(status),
        'Whether_BlockID_Filter': blockId != null && blockId.isNotEmpty,
        if (blockId != null && blockId.isNotEmpty) 'BlockID': blockId,
        'Whether_BuildingID_Filter':
            buildingId != null && buildingId.isNotEmpty,
        if (buildingId != null && buildingId.isNotEmpty)
          'BuildingID': buildingId,
      },
    );

    return _parseIncidentRecordResponse(response);
  }

  /// Filter incidents for tenant.
  static Future<({List<TicketRecord> incidents, int count})>
      filterTenantIncidents({
    int skip = 0,
    int limit = 50,
  }) async {
    final ApiResponse response = await ApiClient.instance.post(
      ApiConfig.filterTenantIncidents,
      <String, dynamic>{
        'Skip': skip,
        'Limit': limit,
      },
    );

    return _parseIncidentResponse(response);
  }

  /// Filter incidents for a society as incident records.
  static Future<({List<IncidentRecord> incidents, int count})>
      filterSocietyIncidentRecords({
    required String societyId,
    int skip = 0,
    int limit = 50,
    String? search,
    IncidentStatus? status,
    String? blockId,
    String? buildingId,
  }) async {
    final ApiResponse response = await ApiClient.instance.post(
      ApiConfig.filterSocietyIncidents,
      <String, dynamic>{
        'SocietyID': societyId,
        'Skip': skip,
        'Limit': limit,
        'Whether_Search_Filter': search != null && search.isNotEmpty,
        if (search != null) 'Search': search,
        'Whether_Incident_Status_Filter': status != null,
        if (status != null) 'Incident_Status': _statusToApi(status),
        'Whether_BlockID_Filter': blockId != null && blockId.isNotEmpty,
        if (blockId != null && blockId.isNotEmpty) 'BlockID': blockId,
        'Whether_BuildingID_Filter':
            buildingId != null && buildingId.isNotEmpty,
        if (buildingId != null && buildingId.isNotEmpty)
          'BuildingID': buildingId,
      },
    );

    return _parseIncidentRecordResponse(response);
  }

  /// Filter incidents for a society.
  static Future<({List<TicketRecord> incidents, int count})>
      filterSocietyIncidents({
    required String societyId,
    int skip = 0,
    int limit = 50,
  }) async {
    final ApiResponse response = await ApiClient.instance.post(
      ApiConfig.filterSocietyIncidents,
      <String, dynamic>{
        'SocietyID': societyId,
        'Skip': skip,
        'Limit': limit,
      },
    );

    return _parseIncidentResponse(response);
  }

  static Future<ApiResponse> createIncident({
    required String societyId,
    required String title,
    required String description,
    required String location,
    required int priority,
    String blockId = '',
    String buildingId = '',
    String imageId = '',
  }) async {
    return ApiClient.instance.post(
      ApiConfig.createIncident,
      <String, dynamic>{
        'SocietyID': societyId,
        'Title': title,
        'Description': description,
        'Location': location,
        'Priority': priority,
        'Whether_Block_Available': blockId.isNotEmpty,
        'BlockID': blockId,
        'Whether_Building_Available': buildingId.isNotEmpty,
        'BuildingID': buildingId,
        'Whether_Image_Available': imageId.isNotEmpty,
        'ImageID': imageId,
      },
    );
  }

  static Future<ApiResponse> editIncident({
    required String incidentId,
    required String title,
    required String description,
    required String location,
    required int priority,
    String blockId = '',
    String buildingId = '',
    String imageId = '',
  }) async {
    return ApiClient.instance.post(
      ApiConfig.editIncident,
      <String, dynamic>{
        'Society_IncidentID': incidentId,
        'Title': title,
        'Description': description,
        'Location': location,
        'Priority': priority,
        'Whether_Block_Available': blockId.isNotEmpty,
        'BlockID': blockId,
        'Whether_Building_Available': buildingId.isNotEmpty,
        'BuildingID': buildingId,
        'Whether_Image_Available': imageId.isNotEmpty,
        'ImageID': imageId,
      },
    );
  }

  static Future<ApiResponse> toggleIncident(
    String incidentId, {
    required bool active,
  }) async {
    return ApiClient.instance.post(
      active ? ApiConfig.activeIncident : ApiConfig.inactiveIncident,
      <String, dynamic>{'Society_IncidentID': incidentId},
    );
  }

  static Future<ApiResponse> updateIncidentStatus({
    required String incidentId,
    required int status,
  }) async {
    return ApiClient.instance.post(
      ApiConfig.updateIncidentStatus,
      <String, dynamic>{
        'Society_IncidentID': incidentId,
        'Incident_Status': status,
      },
    );
  }

  static ({List<TicketRecord> incidents, int count}) _parseIncidentResponse(
    ApiResponse response,
  ) {
    if (!response.success || response.data == null) {
      return (incidents: <TicketRecord>[], count: 0);
    }

    final List<dynamic> dataList = response.data as List<dynamic>;
    final List<TicketRecord> incidents = dataList
        .map((dynamic item) =>
            IncidentData.fromJson(item as Map<String, dynamic>)
                .toTicketRecord())
        .toList();

    return (incidents: incidents, count: response.count ?? incidents.length);
  }

  static ({List<IncidentRecord> incidents, int count})
      _parseIncidentRecordResponse(ApiResponse response) {
    if (!response.success || response.data == null) {
      return (incidents: <IncidentRecord>[], count: 0);
    }

    final List<dynamic> dataList = response.data as List<dynamic>;
    final List<IncidentRecord> incidents = dataList
        .map((dynamic item) =>
            IncidentData.fromJson(item as Map<String, dynamic>)
                .toIncidentRecord())
        .toList();

    return (incidents: incidents, count: response.count ?? incidents.length);
  }

  static int _statusToApi(IncidentStatus status) {
    return switch (status) {
      IncidentStatus.open => 1,
      IncidentStatus.investigating => 2,
      IncidentStatus.resolved => 3,
    };
  }
}
