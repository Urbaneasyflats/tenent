import '../models/api_models.dart';
import '../models/app_models.dart';
import 'api_client.dart';
import 'api_config.dart';
import 'auth_storage.dart';

class PropertyService {
  PropertyService._();

  static Future<({List<PropertyRecord> properties, int count})> filterProperties({
    int skip = 0,
    int limit = 50,
    int? typeFilter,
    String? search,
    String? stateId,
    String? cityId,
  }) async {
    final String selectedVendorId = AuthStorage.vendorId ?? '';
    final ApiResponse response = await ApiClient.instance.post(
      ApiConfig.filterAllProperties,
      <String, dynamic>{
        'Skip': skip,
        'Limit': limit,
        'Whether_Selected_Vendor_Filter': selectedVendorId.isNotEmpty,
        'Selected_VendorID': selectedVendorId,
        'Whether_Property_Type_Filter': typeFilter != null,
        'Property_Type': typeFilter ?? 1,
        'Whether_Search_Filter': search != null && search.isNotEmpty,
        'Search': search ?? '',
        'Whether_State_Filter': stateId != null && stateId.isNotEmpty,
        'StateID': stateId ?? '',
        'Whether_City_Filter': cityId != null && cityId.isNotEmpty,
        'CityID': cityId ?? '',
      },
    );

    if (!response.success || response.data == null) {
      return (properties: <PropertyRecord>[], count: 0);
    }

    final List<dynamic> dataList = response.data as List<dynamic>;
    final List<PropertyRecord> properties = dataList
        .map((dynamic item) =>
            PropertyData.fromJson(item as Map<String, dynamic>)
                .toPropertyRecord())
        .toList();

    return (properties: properties, count: response.count ?? properties.length);
  }

  static Future<({List<Map<String, dynamic>> properties, int count})>
      filterPropertiesLite({
    int skip = 0,
    int limit = 100,
  }) async {
    final ApiResponse response = await ApiClient.instance.post(
      ApiConfig.filterAllPropertiesLite,
      <String, dynamic>{
        'Skip': skip,
        'Limit': limit,
      },
    );

    if (!response.success || response.data == null) {
      return (properties: <Map<String, dynamic>>[], count: 0);
    }

    final List<dynamic> dataList = response.data as List<dynamic>;
    final List<Map<String, dynamic>> properties =
        dataList.map((dynamic item) => item as Map<String, dynamic>).toList();

    return (properties: properties, count: response.count ?? properties.length);
  }

  static Future<PropertyData?> fetchPropertyInfo(String propertyId) async {
    final ApiResponse response = await ApiClient.instance.post(
      ApiConfig.fetchPropertyInfo,
      <String, dynamic>{'PropertyID': propertyId},
    );

    if (response.success && response.data != null) {
      return PropertyData.fromJson(response.data as Map<String, dynamic>);
    }
    return null;
  }

  static Future<({List<PropertyStateData> states, int count})> filterStates({
    int skip = 0,
    int limit = 100,
    String? search,
  }) async {
    final ApiResponse response = await ApiClient.instance.post(
      ApiConfig.filterAllStates,
      <String, dynamic>{
        'Skip': skip,
        'Limit': limit,
        'Whether_Search_Filter': search != null && search.isNotEmpty,
        'Search': search ?? '',
      },
    );

    if (!response.success || response.data == null) {
      return (states: <PropertyStateData>[], count: 0);
    }

    final List<dynamic> dataList = response.data as List<dynamic>;
    final List<PropertyStateData> states = dataList
        .map((dynamic item) =>
            PropertyStateData.fromJson(item as Map<String, dynamic>))
        .toList();

    return (states: states, count: response.count ?? states.length);
  }

  static Future<({List<PropertyCityData> cities, int count})> filterCities({
    int skip = 0,
    int limit = 100,
    String? stateId,
    String? search,
  }) async {
    final ApiResponse response = await ApiClient.instance.post(
      ApiConfig.filterAllCities,
      <String, dynamic>{
        'Skip': skip,
        'Limit': limit,
        'Whether_State_Filter': stateId != null && stateId.isNotEmpty,
        'StateID': stateId ?? '',
        'Whether_Search_Filter': search != null && search.isNotEmpty,
        'Search': search ?? '',
      },
    );

    if (!response.success || response.data == null) {
      return (cities: <PropertyCityData>[], count: 0);
    }

    final List<dynamic> dataList = response.data as List<dynamic>;
    final List<PropertyCityData> cities = dataList
        .map((dynamic item) =>
            PropertyCityData.fromJson(item as Map<String, dynamic>))
        .toList();

    return (cities: cities, count: response.count ?? cities.length);
  }

  static Future<Map<String, dynamic>> fetchAppCommonSettings() async {
    final ApiResponse response =
        await ApiClient.instance.post(ApiConfig.fetchAppCommonSettings);
    if (!response.success || response.data == null) {
      return <String, dynamic>{};
    }
    return response.data as Map<String, dynamic>;
  }

  static Future<ApiResponse> createProperty(
      Map<String, dynamic> propertyData) async {
    return ApiClient.instance.post(ApiConfig.createProperty, propertyData);
  }

  static Future<ApiResponse> editProperty(
      Map<String, dynamic> propertyData) async {
    return ApiClient.instance.post(ApiConfig.editProperty, propertyData);
  }

  static Future<ApiResponse> activateProperty(String propertyId) async {
    return ApiClient.instance.post(
      ApiConfig.activeProperty,
      <String, dynamic>{'PropertyID': propertyId},
    );
  }

  static Future<ApiResponse> inactivateProperty(String propertyId) async {
    return ApiClient.instance.post(
      ApiConfig.inactiveProperty,
      <String, dynamic>{'PropertyID': propertyId},
    );
  }

  static Future<
      ({
        List<PropertyEnquiryData> enquiries,
        int count,
        int newCount,
        int resolvedCount,
      })> filterPropertyEnquiries(
    String propertyId, {
    int skip = 0,
    int limit = 20,
    String? search,
    int? enquiryStatus,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final bool hasDateFilter = startDate != null && endDate != null;
    final ApiResponse response = await ApiClient.instance.post(
      ApiConfig.filterPropertyEnquiries,
      <String, dynamic>{
        'PropertyID': propertyId,
        'Skip': skip,
        'Limit': limit,
        'Whether_Search_Filter': search != null && search.isNotEmpty,
        if (search != null && search.isNotEmpty) 'Search': search,
        'Whether_Enquiry_Status_Filter': enquiryStatus != null,
        if (enquiryStatus != null) 'Enquiry_Status': enquiryStatus,
        'Whether_Date_Filter': hasDateFilter,
        if (hasDateFilter) 'Start_Date': startDate.toIso8601String(),
        if (hasDateFilter) 'End_Date': endDate.toIso8601String(),
      },
    );

    if (!response.success || response.data == null) {
      return (enquiries: <PropertyEnquiryData>[], count: 0, newCount: 0, resolvedCount: 0);
    }

    final List<dynamic> dataList = response.data as List<dynamic>;
    final List<PropertyEnquiryData> enquiries = dataList
        .map((dynamic item) =>
            PropertyEnquiryData.fromJson(item as Map<String, dynamic>))
        .toList();

    return (
      enquiries: enquiries,
      count: response.count ?? enquiries.length,
      newCount: (response.extras['New_Enquiry_Count'] as num?)?.toInt() ?? 0,
      resolvedCount:
          (response.extras['Resolved_Enquiry_Count'] as num?)?.toInt() ?? 0,
    );
  }

  static Future<ApiResponse> updateEnquiryStatus(
      String enquiryId, int status) async {
    return ApiClient.instance.post(
      ApiConfig.updateEnquiryStatus,
      <String, dynamic>{
        'EnquiryID': enquiryId,
        'Status': status,
      },
    );
  }
}
