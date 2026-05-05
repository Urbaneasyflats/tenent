import '../models/api_models.dart';
import '../models/app_models.dart';
import 'api_client.dart';
import 'api_config.dart';

class BillingService {
  BillingService._();

  /// Filter bills for the current tenant/vendor.
  static Future<({List<BillRecord> bills, int count})> filterTenantBills({
    int skip = 0,
    int limit = 50,
    BillStatus? statusFilter,
    String? search,
    int? billType,
  }) async {
    final result = await filterTenantBillsDetailed(
      skip: skip,
      limit: limit,
      statusFilter: statusFilter,
      search: search,
      billType: billType,
    );
    return (bills: result.bills, count: result.count);
  }

  static Future<
      ({
        List<BillRecord> bills,
        int count,
        double pendingAmount,
        double paidAmount,
        double overdueAmount,
      })> filterTenantBillsDetailed({
    int skip = 0,
    int limit = 50,
    BillStatus? statusFilter,
    String? search,
    int? billType,
  }) async {
    final ApiResponse response = await ApiClient.instance.post(
      ApiConfig.filterTenantBills,
      <String, dynamic>{
        'Skip': skip,
        'Limit': limit,
        'Whether_Bill_Status_Filter': statusFilter != null,
        if (statusFilter != null)
          'Bill_Status': _billStatusToApi(statusFilter),
        'Whether_Search_Filter': search != null && search.isNotEmpty,
        if (search != null && search.isNotEmpty) 'Search': search,
        'Whether_Bill_Type_Filter': billType != null,
        if (billType != null) 'Bill_Type': billType,
      },
    );

    final ({List<BillRecord> bills, int count}) parsed =
        _parseBillResponse(response);
    return (
      bills: parsed.bills,
      count: parsed.count,
      pendingAmount:
          (response.extras['Total_Pending_To_Pay'] as num?)?.toDouble() ?? 0,
      paidAmount: (response.extras['Total_Paid'] as num?)?.toDouble() ?? 0,
      overdueAmount:
          (response.extras['Total_Overdue_To_Pay'] as num?)?.toDouble() ?? 0,
    );
  }

  /// Filter society resident bills with summary totals (for society manager,
  /// treasurer, president roles — supports bill type, block, building, search).
  static Future<
      ({
        List<BillRecord> bills,
        int count,
        double pendingAmount,
        double collectedAmount,
        double overdueAmount,
        double todayCollection,
        double monthCollection,
        double monthOverdue,
        double monthPending,
      })> filterSocietyResidentBills({
    required String societyId,
    int skip = 0,
    int limit = 10,
    BillStatus? statusFilter,
    int? billType,
    String? blockId,
    String? buildingId,
    String? search,
  }) async {
    final ApiResponse response = await ApiClient.instance.post(
      ApiConfig.filterResidentBills,
      <String, dynamic>{
        'SocietyID': societyId,
        'Skip': skip,
        'Limit': limit,
        'Whether_Bill_Status_Filter': statusFilter != null,
        if (statusFilter != null)
          'Bill_Status': _billStatusToApi(statusFilter),
        'Whether_Bill_Type_Filter': billType != null,
        if (billType != null) 'Bill_Type': billType,
        'Whether_Block_Filter': blockId != null && blockId.isNotEmpty,
        if (blockId != null && blockId.isNotEmpty) 'BlockID': blockId,
        'Whether_Building_Filter': buildingId != null && buildingId.isNotEmpty,
        if (buildingId != null && buildingId.isNotEmpty) 'BuildingID': buildingId,
        'Whether_Search_Filter': search != null && search.isNotEmpty,
        if (search != null && search.isNotEmpty) 'Search': search,
      },
    );

    final ({List<BillRecord> bills, int count}) parsed =
        _parseBillResponse(response);
    return (
      bills: parsed.bills,
      count: parsed.count,
      pendingAmount:
          (response.extras['Total_Pending_Amount'] as num?)?.toDouble() ?? 0,
      collectedAmount:
          (response.extras['Total_Collected_Amount'] as num?)?.toDouble() ?? 0,
      overdueAmount:
          (response.extras['Total_Overdue_Amount'] as num?)?.toDouble() ?? 0,
      todayCollection:
          (response.extras['Today_Collection'] as num?)?.toDouble() ?? 0,
      monthCollection:
          (response.extras['Current_Month_Collection'] as num?)?.toDouble() ??
              0,
      monthOverdue:
          (response.extras['Current_Month_Overdue_Amount'] as num?)
              ?.toDouble() ??
              0,
      monthPending:
          (response.extras['Current_Month_Pending_Amount'] as num?)
              ?.toDouble() ??
              0,
    );
  }

  /// Filter property contract bills (for property owners).
  static Future<({List<BillRecord> bills, int count})>
      filterPropertyContractBills({
    required String propertyId,
    int skip = 0,
    int limit = 50,
    BillStatus? statusFilter,
  }) async {
    final result = await filterPropertyContractBillsDetailed(
      propertyId: propertyId,
      skip: skip,
      limit: limit,
      statusFilter: statusFilter,
    );
    return (bills: result.bills, count: result.count);
  }

  /// Filter property contract bills with summary totals (for property manager
  /// billing page direct fetch with search + contract filter).
  static Future<
      ({
        List<BillRecord> bills,
        int count,
        double pendingAmount,
        double collectedAmount,
        double overdueAmount,
        double todayCollection,
        double monthCollection,
        double monthOverdue,
        double monthPending,
        double totalSecurityBill,
        double pendingSecurity,
        double collectedSecurity,
      })> filterPropertyContractBillsDetailed({
    required String propertyId,
    int skip = 0,
    int limit = 50,
    BillStatus? statusFilter,
    String? contractId,
    String? search,
  }) async {
    final ApiResponse response = await ApiClient.instance.post(
      ApiConfig.filterPropertyContractBills,
      <String, dynamic>{
        'PropertyID': propertyId,
        'Skip': skip,
        'Limit': limit,
        'Whether_Bill_Status_Filter': statusFilter != null,
        if (statusFilter != null)
          'Bill_Status': _billStatusToApi(statusFilter),
        'Whether_Contract_Filter': contractId != null && contractId.isNotEmpty,
        if (contractId != null && contractId.isNotEmpty)
          'Rental_ContractID': contractId,
        'Whether_Search_Filter': search != null && search.isNotEmpty,
        if (search != null && search.isNotEmpty) 'Search': search,
      },
    );

    final ({List<BillRecord> bills, int count}) parsed =
        _parseBillResponse(response);
    return (
      bills: parsed.bills,
      count: parsed.count,
      pendingAmount:
          (response.extras['Total_Pending_Amount'] as num?)?.toDouble() ?? 0,
      collectedAmount:
          (response.extras['Total_Collected_Amount'] as num?)?.toDouble() ?? 0,
      overdueAmount:
          (response.extras['Total_Overdue_Amount'] as num?)?.toDouble() ?? 0,
      todayCollection:
          (response.extras['Today_Collection'] as num?)?.toDouble() ?? 0,
      monthCollection:
          (response.extras['Current_Month_Collection'] as num?)?.toDouble() ??
              0,
      monthOverdue:
          (response.extras['Current_Month_Overdue_Amount'] as num?)
              ?.toDouble() ??
              0,
      monthPending:
          (response.extras['Current_Month_Pending_Amount'] as num?)
              ?.toDouble() ??
              0,
      totalSecurityBill:
          (response.extras['Total_Security_Bill_Amount'] as num?)?.toDouble() ??
              0,
      pendingSecurity:
          (response.extras['Pending_Security_Amount'] as num?)?.toDouble() ?? 0,
      collectedSecurity:
          (response.extras['Collected_Security_Amount'] as num?)?.toDouble() ??
              0,
    );
  }

  /// Fetch complete information for a single bill.
  static Future<BillRecord?> fetchBillInfo(String billId) async {
    final ApiResponse response = await ApiClient.instance.post(
      ApiConfig.fetchBillInfo,
      <String, dynamic>{'BillID': billId},
    );

    if (response.success && response.data != null) {
      return BillData.fromJson(response.data as Map<String, dynamic>)
          .toBillRecord();
    }
    return null;
  }

  static ({List<BillRecord> bills, int count}) _parseBillResponse(
    ApiResponse response,
  ) {
    if (!response.success || response.data == null) {
      return (bills: <BillRecord>[], count: 0);
    }

    final List<dynamic> dataList = response.data as List<dynamic>;
    final List<BillRecord> bills = dataList
        .map((dynamic item) =>
            BillData.fromJson(item as Map<String, dynamic>).toBillRecord())
        .toList();

    return (bills: bills, count: response.count ?? bills.length);
  }

  /// Collect bill amount (payment).
  static Future<ApiResponse> collectBillPayment(
    String billId, {
    required int paymentType,
  }) async {
    return ApiClient.instance.post(
      ApiConfig.collectBillAmount,
      <String, dynamic>{
        'BillID': billId,
        'Payment_Type': paymentType,
      },
    );
  }

  /// Collect bill amount with manual online payment.
  static Future<ApiResponse> collectBillManualOnline(
    String billId, {
    required int paymentType,
    int? manualOnlinePaymentMode,
    String? paymentDescription,
    bool whetherPaymentImageAvailable = false,
    String? imageId,
  }) async {
    return ApiClient.instance.post(
      ApiConfig.collectBillManualOnline,
      <String, dynamic>{
        'BillID': billId,
        'Payment_Type': paymentType,
        if (manualOnlinePaymentMode != null)
          'Manual_Online_Payment_Mode': manualOnlinePaymentMode,
        if (paymentDescription != null && paymentDescription.isNotEmpty)
          'Bill_Payment_Description': paymentDescription,
        'Whether_Bill_Payment_Image_Available': whetherPaymentImageAvailable,
        if (whetherPaymentImageAvailable && imageId != null)
          'ImageID': imageId,
      },
    );
  }

  /// Generate bills for all society residents.
  static Future<ApiResponse> generateSocietyBills(String societyId) async {
    return ApiClient.instance.post(
      ApiConfig.generateSocietyBills,
      <String, dynamic>{'SocietyID': societyId},
    );
  }

  /// Generate bills for property rental contracts.
  static Future<ApiResponse> generatePropertyBills(String propertyId) async {
    return ApiClient.instance.post(
      ApiConfig.generatePropertyBills,
      <String, dynamic>{'PropertyID': propertyId},
    );
  }

  /// Send bill WhatsApp reminder.
  static Future<ApiResponse> sendBillWhatsAppReminder(String billId) async {
    return ApiClient.instance.post(
      ApiConfig.sendBillWhatsAppReminder,
      <String, dynamic>{'BillID': billId},
    );
  }

  static int _billStatusToApi(BillStatus status) {
    return switch (status) {
      BillStatus.pending => 1,
      BillStatus.paid => 2,
      BillStatus.overdue => 3,
      BillStatus.partial => 4,
    };
  }
}
