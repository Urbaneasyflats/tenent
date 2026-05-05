import '../models/api_models.dart';
import 'api_client.dart';
import 'api_config.dart';

class BlockBuildingService {
  BlockBuildingService._();

  // Blocks
  static Future<({List<BlockData> blocks, int count})> filterBlocks(
    String societyId, {
    int skip = 0,
    int limit = 100,
    bool? status,
    String? search,
  }) async {
    final ApiResponse response = await ApiClient.instance.post(
      ApiConfig.filterAllBlocks,
      <String, dynamic>{
        'Skip': skip,
        'Limit': limit,
        'Whether_Society_Filter': societyId.isNotEmpty,
        'SocietyID': societyId,
        'Whether_Status_Filter': status != null,
        if (status != null) 'Status': status,
        'Whether_Search_Filter': search != null && search.isNotEmpty,
        'Search': search ?? '',
      },
    );

    if (!response.success || response.data == null) {
      return (blocks: <BlockData>[], count: 0);
    }

    final List<dynamic> dataList = response.data as List<dynamic>;
    final List<BlockData> blocks = dataList
        .map((dynamic item) =>
            BlockData.fromJson(item as Map<String, dynamic>))
        .toList();

    return (blocks: blocks, count: response.count ?? blocks.length);
  }

  static Future<ApiResponse> createBlock(
      String societyId, String name) async {
    return ApiClient.instance.post(
      ApiConfig.createBlock,
      <String, dynamic>{'SocietyID': societyId, 'Name': name},
    );
  }

  static Future<ApiResponse> editBlock(String blockId, String name) async {
    return ApiClient.instance.post(
      ApiConfig.editBlock,
      <String, dynamic>{'BlockID': blockId, 'Name': name},
    );
  }

  static Future<ApiResponse> toggleBlock(String blockId,
      {required bool active}) async {
    return ApiClient.instance.post(
      active ? ApiConfig.activeBlock : ApiConfig.inactiveBlock,
      <String, dynamic>{'BlockID': blockId},
    );
  }

  // Buildings
  static Future<({List<BuildingData> buildings, int count})> filterBuildings(
    String societyId, {
    int skip = 0,
    int limit = 100,
    String? blockId,
    bool? status,
    String? search,
  }) async {
    final ApiResponse response = await ApiClient.instance.post(
      ApiConfig.filterAllBuildings,
      <String, dynamic>{
        'Skip': skip,
        'Limit': limit,
        'Whether_Society_Filter': societyId.isNotEmpty,
        'SocietyID': societyId,
        'Whether_Block_Filter': blockId != null && blockId.isNotEmpty,
        if (blockId != null && blockId.isNotEmpty) 'BlockID': blockId,
        'Whether_Status_Filter': status != null,
        if (status != null) 'Status': status,
        'Whether_Search_Filter': search != null && search.isNotEmpty,
        'Search': search ?? '',
      },
    );

    if (!response.success || response.data == null) {
      return (buildings: <BuildingData>[], count: 0);
    }

    final List<dynamic> dataList = response.data as List<dynamic>;
    final List<BuildingData> buildings = dataList
        .map((dynamic item) =>
            BuildingData.fromJson(item as Map<String, dynamic>))
        .toList();

    return (buildings: buildings, count: response.count ?? buildings.length);
  }

  static Future<ApiResponse> createBuilding(
      Map<String, dynamic> buildingData) async {
    return ApiClient.instance.post(ApiConfig.createBuilding, buildingData);
  }

  static Future<ApiResponse> editBuilding(
      Map<String, dynamic> buildingData) async {
    return ApiClient.instance.post(ApiConfig.editBuilding, buildingData);
  }

  static Future<ApiResponse> toggleBuilding(String buildingId,
      {required bool active}) async {
    return ApiClient.instance.post(
      active ? ApiConfig.activeBuilding : ApiConfig.inactiveBuilding,
      <String, dynamic>{'BuildingID': buildingId},
    );
  }
}
