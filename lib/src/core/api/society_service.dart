import '../models/api_models.dart';
import '../models/app_models.dart';
import 'api_client.dart';
import 'api_config.dart';

class SocietyService {
  SocietyService._();

  static const SocietyMaintenanceRates defaultMaintenanceRates =
      SocietyMaintenanceRates();
  static const SocietyBillingConfig defaultBillingConfig =
      SocietyBillingConfig();

  static Future<SocietyData?> fetchSocietyInfo() async {
    final ApiResponse response = await ApiClient.instance.post(
      ApiConfig.fetchSocietyInfo,
    );

    if (response.success && response.data != null) {
      return SocietyData.fromJson(response.data as Map<String, dynamic>);
    }
    return null;
  }

  static Future<ApiResponse> createSociety({
    required String name,
    required String countryCode,
    required String phoneNumber,
    required String emailId,
    required int estYear,
    required double latitude,
    required double longitude,
    required String locationAddress,
    required String address,
    required SocietyMaintenanceRates maintenanceRates,
    required SocietyBillingConfig billingConfig,
  }) async {
    return ApiClient.instance.post(ApiConfig.createSociety, <String, dynamic>{
      'Name': name.trim(),
      'CountryCode': countryCode.trim(),
      'PhoneNumber': phoneNumber.trim(),
      'EmailID': emailId.trim(),
      'Est_Year': estYear,
      'Latitude': latitude,
      'Longitude': longitude,
      'Location_Address': locationAddress.trim(),
      'Address': address.trim(),
      'Maintenance_Rates': maintenanceRates.toJson(),
      'Billing_Config': billingConfig.toJson(),
    });
  }

  static Future<ApiResponse> editSociety({
    required String societyId,
    required String name,
    required String countryCode,
    required String phoneNumber,
    required String emailId,
    required int estYear,
    required double latitude,
    required double longitude,
    required String locationAddress,
    required String address,
    required SocietyMaintenanceRates maintenanceRates,
    required SocietyBillingConfig billingConfig,
  }) async {
    return ApiClient.instance.post(ApiConfig.editSociety, <String, dynamic>{
      'SocietyID': societyId,
      'Name': name.trim(),
      'CountryCode': countryCode.trim(),
      'PhoneNumber': phoneNumber.trim(),
      'EmailID': emailId.trim(),
      'Est_Year': estYear,
      'Latitude': latitude,
      'Longitude': longitude,
      'Location_Address': locationAddress.trim(),
      'Address': address.trim(),
      'Maintenance_Rates': maintenanceRates.toJson(),
      'Billing_Config': billingConfig.toJson(),
    });
  }

  static List<String> validateSocietyForm({
    required String name,
    required String phoneNumber,
    required String emailId,
    required int estYear,
    double? latitude,
    double? longitude,
    required String locationAddress,
    required String address,
    required SocietyBillingConfig billingConfig,
  }) {
    final List<String> errors = <String>[];
    final int currentYear = DateTime.now().year;

    if (name.trim().isEmpty) {
      errors.add('Society name is required.');
    }
    if (phoneNumber.trim().length != 10) {
      errors.add('Enter a valid 10-digit phone number.');
    }
    if (emailId.trim().isEmpty || !emailId.contains('@')) {
      errors.add('Enter a valid email address.');
    }
    if (estYear < 1900 || estYear > currentYear) {
      errors.add('Enter a valid establishment year.');
    }
    if (latitude == null || latitude < -90 || latitude > 90) {
      errors.add('Enter a valid latitude between -90 and 90.');
    }
    if (longitude == null || longitude < -180 || longitude > 180) {
      errors.add('Enter a valid longitude between -180 and 180.');
    }
    if (locationAddress.trim().isEmpty) {
      errors.add('Location address is required.');
    }
    if (address.trim().isEmpty) {
      errors.add('Full address is required.');
    }
    if (billingConfig.billGenerationDate < 1 ||
        billingConfig.billGenerationDate > 31) {
      errors.add('Bill generation day must be between 1 and 31.');
    }
    if (billingConfig.paymentDueDays < 1 || billingConfig.paymentDueDays > 90) {
      errors.add('Payment due days must be between 1 and 90.');
    }
    return errors;
  }

  static Future<({List<ResidentRecord> residents, int count})> filterResidents({
    required String societyId,
    int skip = 0,
    int limit = 50,
    String? search,
    bool? statusFilter,
    String? blockId,
    String? buildingId,
    String? tenantVendorId,
    int? residentType,
  }) async {
    final ApiResponse response = await ApiClient.instance.post(
      ApiConfig.filterResidents,
      <String, dynamic>{
        'SocietyID': societyId,
        'Whether_Society_Filter': societyId.isNotEmpty,
        'Skip': skip,
        'Limit': limit,
        'Whether_Search_Filter': search != null && search.isNotEmpty,
        'Search': search ?? '',
        'Whether_Status_Filter': statusFilter != null,
        if (statusFilter != null) 'Status': statusFilter,
        'Whether_Block_Filter': blockId != null && blockId.isNotEmpty,
        if (blockId != null && blockId.isNotEmpty) 'BlockID': blockId,
        'Whether_Building_Filter': buildingId != null && buildingId.isNotEmpty,
        if (buildingId != null && buildingId.isNotEmpty)
          'BuildingID': buildingId,
        'Whether_Tenant_Vendor_Filter':
            tenantVendorId != null && tenantVendorId.isNotEmpty,
        if (tenantVendorId != null && tenantVendorId.isNotEmpty)
          'Tenant_VendorID': tenantVendorId,
        'Whether_Resident_Type_Filter': residentType != null,
        if (residentType != null) 'Resident_Type': residentType,
      },
    );

    if (!response.success || response.data == null) {
      return (residents: <ResidentRecord>[], count: 0);
    }

    final List<dynamic> dataList = response.data as List<dynamic>;
    final List<ResidentRecord> residents = dataList
        .map(
          (dynamic item) => ResidentData.fromJson(
            item as Map<String, dynamic>,
          ).toResidentRecord(),
        )
        .toList();

    return (residents: residents, count: response.count ?? residents.length);
  }

  static Future<ApiResponse> createResident(
    Map<String, dynamic> residentData,
  ) async {
    return ApiClient.instance.post(ApiConfig.createResident, residentData);
  }

  static Future<ApiResponse> editResident(
    Map<String, dynamic> residentData,
  ) async {
    return ApiClient.instance.post(ApiConfig.editResident, residentData);
  }

  static Future<ApiResponse> activateResident(String residentId) async {
    return ApiClient.instance.post(ApiConfig.activeResident, <String, dynamic>{
      'Society_ResidentID': residentId,
    });
  }

  static Future<ApiResponse> inactivateResident(String residentId) async {
    return ApiClient.instance.post(
      ApiConfig.inactiveResident,
      <String, dynamic>{'Society_ResidentID': residentId},
    );
  }

  static Future<SocietyResidentsCalculationData> calculateResidents({
    required String societyId,
    required int numberOfResidents,
  }) async {
    final ApiResponse response = await ApiClient.instance.post(
      ApiConfig.calculateResidents,
      <String, dynamic>{
        'SocietyID': societyId,
        'No_Of_Residents': numberOfResidents,
      },
    );

    if (!response.success || response.data == null) {
      throw Exception(
        response.message ??
            response.status ??
            'Unable to calculate resident slot pricing.',
      );
    }

    return SocietyResidentsCalculationData.fromJson(
      response.data as Map<String, dynamic>,
    );
  }

  static Future<SocietyResidentsPurchaseData> purchaseResidents({
    required String societyId,
    required int numberOfResidents,
  }) async {
    final ApiResponse response = await ApiClient.instance.post(
      ApiConfig.purchaseResidents,
      <String, dynamic>{
        'SocietyID': societyId,
        'No_Of_Residents': numberOfResidents,
      },
    );

    if (!response.success) {
      throw Exception(
        response.message ??
            response.status ??
            'Unable to start the resident slot purchase.',
      );
    }

    return SocietyResidentsPurchaseData.fromJson(response.extras);
  }

  static Future<SocietyResidentsCalculationData> calculateResidentsRenewal({
    required String societyId,
    int? numberOfResidents,
  }) async {
    final Map<String, dynamic> payload = <String, dynamic>{
      'SocietyID': societyId,
    };
    if (numberOfResidents != null) {
      payload['No_Of_Residents'] = numberOfResidents;
    }

    final ApiResponse response = await ApiClient.instance.post(
      ApiConfig.calculateResidentsRenewal,
      payload,
    );

    if (!response.success || response.data == null) {
      throw Exception(
        response.message ??
            response.status ??
            'Unable to calculate resident slot renewal.',
      );
    }

    return SocietyResidentsCalculationData.fromJson(
      response.data as Map<String, dynamic>,
    );
  }

  static Future<SocietyResidentsPurchaseData> renewResidents({
    required String societyId,
    required int numberOfResidents,
  }) async {
    final ApiResponse response = await ApiClient.instance.post(
      ApiConfig.renewResidents,
      <String, dynamic>{
        'SocietyID': societyId,
        'No_Of_Residents': numberOfResidents,
      },
    );

    if (!response.success) {
      throw Exception(
        response.message ??
            response.status ??
            'Unable to start the resident slot renewal.',
      );
    }

    return SocietyResidentsPurchaseData.fromJson(response.extras);
  }
}
