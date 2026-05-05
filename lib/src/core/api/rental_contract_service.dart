import '../models/api_models.dart';
import '../models/app_models.dart';
import 'api_client.dart';
import 'api_config.dart';
import 'auth_storage.dart';

class RentalContractService {
  RentalContractService._();

  static Future<({List<RentalContractRecord> contracts, int count})>
      filterRentalContracts({
    int skip = 0,
    int limit = 50,
    ContractStatus? status,
    String? propertyId,
  }) async {
    final ApiResponse response = await ApiClient.instance.post(
      ApiConfig.filterAllRentalContracts,
      <String, dynamic>{
        'Skip': skip,
        'Limit': limit,
        'Whether_Status_Filter': status != null,
        if (status != null) 'Contract_Status': _statusToApi(status),
        'Whether_Property_Filter': propertyId != null,
        if (propertyId != null) 'PropertyID': propertyId,
      },
    );

    return _parseContractResponse(response);
  }

  static Future<({List<RentalContractRecord> contracts, int count})>
      filterContractsForProperty(
    String propertyId, {
    int skip = 0,
    int limit = 50,
  }) async {
    final ApiResponse response = await ApiClient.instance.post(
      ApiConfig.filterRentalContractsForProperty,
      <String, dynamic>{
        'PropertyID': propertyId,
        'Skip': skip,
        'Limit': limit,
      },
    );

    return _parseContractResponse(response);
  }

  static Future<({List<RentalContractRecord> contracts, int count})>
      filterTenantRentalContracts({
    int skip = 0,
    int limit = 50,
    bool? active,
    String? search,
  }) async {
    final ApiResponse response = await ApiClient.instance.post(
      ApiConfig.filterAllRentalContracts,
      <String, dynamic>{
        'Skip': skip,
        'Limit': limit,
        'Whether_Status_Filter': active != null,
        if (active != null) 'Status': active,
        'Whether_Selected_Vendor_Filter': false,
        'Selected_VendorID': '',
        'Whether_Tenant_Vendor_Filter': true,
        'Tenant_VendorID': AuthStorage.vendorId ?? '',
        'Whether_Property_Filter': false,
        'PropertyID': '',
        'Whether_Rental_Contract_Status_Filter': false,
        'Rental_Contract_Status': 1,
        'Whether_Tenant_Status_Filter': false,
        'Tenant_Status': 1,
        'Whether_Search_Filter': search != null && search.isNotEmpty,
        if (search != null) 'Search': search,
      },
    );

    return _parseContractResponse(response);
  }

  static Future<ApiResponse> createRentalContract(
      Map<String, dynamic> contractData) async {
    return ApiClient.instance.post(
        ApiConfig.createRentalContract, contractData);
  }

  static Future<ApiResponse> editRentalContract(
      Map<String, dynamic> contractData) async {
    return ApiClient.instance.post(
        ApiConfig.editRentalContract, contractData);
  }

  static Future<ApiResponse> activateContract(String contractId) async {
    return ApiClient.instance.post(
      ApiConfig.activeRentalContract,
      <String, dynamic>{'Rental_ContractID': contractId},
    );
  }

  static Future<ApiResponse> inactivateContract(String contractId) async {
    return ApiClient.instance.post(
      ApiConfig.inactiveRentalContract,
      <String, dynamic>{'Rental_ContractID': contractId},
    );
  }

  static Future<ApiResponse> markReadyToVacate(
      String contractId, String vacateDate) async {
    return ApiClient.instance.post(
      ApiConfig.updateRentalContractReadyToVacate,
      <String, dynamic>{
        'Rental_ContractID': contractId,
        'Vacate_Date': vacateDate,
      },
    );
  }

  static Future<ApiResponse> updateTenantDocuments({
    required String contractId,
    required bool whetherTenantIdProofAvailable,
    String tenantIdProofDocumentId = '',
    required bool whetherTenantAddressProofAvailable,
    String tenantAddressProofDocumentId = '',
    bool whetherOwnerIdProofAvailable = false,
    String ownerIdProofDocumentId = '',
    bool whetherOwnerPropertyOwnershipProofAvailable = false,
    String ownerPropertyOwnershipProofDocumentId = '',
    bool whetherOwnerBankProofAvailable = false,
    String ownerBankProofDocumentId = '',
  }) async {
    return ApiClient.instance.post(
      ApiConfig.updateRentalContractTenantDocuments,
      <String, dynamic>{
        'Rental_ContractID': contractId,
        'Whether_Tenant_ID_Proof_Available': whetherTenantIdProofAvailable,
        'Tenant_ID_Proof_DocumentID': tenantIdProofDocumentId,
        'Whether_Tenant_Address_Proof_Available':
            whetherTenantAddressProofAvailable,
        'Tenant_Address_Proof_DocumentID': tenantAddressProofDocumentId,
        'Whether_Owner_ID_Proof_Available': whetherOwnerIdProofAvailable,
        'Owner_ID_Proof_DocumentID': ownerIdProofDocumentId,
        'Whether_Owner_Property_Ownership_Proof_Available':
            whetherOwnerPropertyOwnershipProofAvailable,
        'Owner_Property_Ownership_Proof_DocumentID':
            ownerPropertyOwnershipProofDocumentId,
        'Whether_Owner_Bank_Proof_Available': whetherOwnerBankProofAvailable,
        'Owner_Bank_Proof_DocumentID': ownerBankProofDocumentId,
      },
    );
  }

  static Future<ApiResponse> closeContract(String contractId) async {
    return ApiClient.instance.post(
      ApiConfig.closeRentalContract,
      <String, dynamic>{'Rental_ContractID': contractId},
    );
  }

  static Future<ApiResponse> createSecurityDepositBill(
    String contractId, {
    bool isPaid = true,
  }) async {
    return ApiClient.instance.post(
      ApiConfig.createRentalContractSecurityDepositBill,
      <String, dynamic>{
        'Rental_ContractID': contractId,
        'Whether_Paid': isPaid,
      },
    );
  }

  static Future<ApiResponse> createFirstMonthBill(
    String contractId, {
    bool isPaid = true,
  }) async {
    return ApiClient.instance.post(
      ApiConfig.createRentalContractFirstMonthBill,
      <String, dynamic>{
        'Rental_ContractID': contractId,
        'Whether_Paid': isPaid,
      },
    );
  }

  static Future<List<WhatsAppTemplateData>> filterWhatsAppTemplates() async {
    final ApiResponse response = await ApiClient.instance.post(
      ApiConfig.filterRentalContractWhatsAppTemplates,
      <String, dynamic>{},
    );

    if (!response.success || response.data == null) {
      return <WhatsAppTemplateData>[];
    }

    final List<dynamic> dataList = response.data as List<dynamic>;
    return dataList
        .map((dynamic item) =>
            WhatsAppTemplateData.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  static Future<ApiResponse> sendWhatsAppTemplate({
    required String contractId,
    required int templateId,
  }) async {
    return ApiClient.instance.post(
      ApiConfig.sendRentalContractWhatsAppTemplate,
      <String, dynamic>{
        'Rental_ContractID': contractId,
        'Template_ID': templateId,
      },
    );
  }

  static Future<ResidentContractsCalculationData> calculateResidentContracts({
    required String propertyId,
    required int numberOfContracts,
  }) async {
    final ApiResponse response = await ApiClient.instance.post(
      ApiConfig.calculatePropertyResidentContracts,
      <String, dynamic>{
        'PropertyID': propertyId,
        'No_Of_Resident_Contracts': numberOfContracts,
      },
    );

    if (!response.success || response.data == null) {
      throw Exception(
        response.message ??
            response.status ??
            'Unable to calculate resident contract pricing.',
      );
    }

    return ResidentContractsCalculationData.fromJson(
      response.data as Map<String, dynamic>,
    );
  }

  static Future<ResidentContractsPurchaseData> purchaseResidentContracts({
    required String propertyId,
    required int numberOfContracts,
  }) async {
    final ApiResponse response = await ApiClient.instance.post(
      ApiConfig.purchasePropertyResidentContracts,
      <String, dynamic>{
        'PropertyID': propertyId,
        'No_Of_Resident_Contracts': numberOfContracts,
      },
    );

    if (!response.success) {
      throw Exception(
        response.message ??
            response.status ??
            'Unable to start the resident contract purchase.',
      );
    }

    return ResidentContractsPurchaseData.fromJson(response.extras);
  }

  static ({List<RentalContractRecord> contracts, int count})
      _parseContractResponse(ApiResponse response) {
    if (!response.success || response.data == null) {
      return (contracts: <RentalContractRecord>[], count: 0);
    }

    final List<dynamic> dataList = response.data as List<dynamic>;
    final List<RentalContractRecord> contracts = dataList
        .map((dynamic item) =>
            RentalContractData.fromJson(item as Map<String, dynamic>)
                .toContractRecord())
        .toList();

    return (contracts: contracts, count: response.count ?? contracts.length);
  }

  static int _statusToApi(ContractStatus status) {
    return switch (status) {
      ContractStatus.active => 1,
      ContractStatus.expired => 2,
      ContractStatus.closed => 3,
      ContractStatus.readyToVacate => 4,
    };
  }
}
