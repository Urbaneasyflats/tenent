import 'app_models.dart';

bool? _readBool(dynamic value) {
  if (value is bool) return value;
  if (value is num) return value != 0;
  if (value is String) {
    final String normalized = value.trim().toLowerCase();
    if (normalized == 'true' || normalized == '1') return true;
    if (normalized == 'false' || normalized == '0') return false;
  }
  return null;
}

int? _readInt(dynamic value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value.trim());
  return null;
}

double? _readDouble(dynamic value) {
  if (value is num) return value.toDouble();
  if (value is String) return double.tryParse(value.trim());
  return null;
}

// ---------------------------------------------------------------------------
// Vendor
// ---------------------------------------------------------------------------

class VendorData {
  const VendorData({
    required this.vendorId,
    required this.fullName,
    required this.phone,
    required this.email,
    required this.vendorType,
    this.imageUrl,
    this.imageId,
    this.societyId,
    this.propertyId,
    this.billCollectionSummary,
    this.supportTicketSummary,
    this.propertySummary,
    this.rentalContractSummary,
    this.walletInfo,
  });

  factory VendorData.fromJson(Map<String, dynamic> json) {
    final Map<String, dynamic>? imageInformation =
        json['Image_Information'] as Map<String, dynamic>?;

    return VendorData(
      vendorId: json['VendorID'] as String? ?? '',
      fullName: json['Full_Name'] as String? ?? '',
      phone: json['Phone'] as String? ?? json['PhoneNumber'] as String? ?? '',
      email: json['EmailID'] as String? ?? '',
      vendorType: json['Vendor_Type'] as int? ?? 0,
      imageUrl:
          json['Image_Original_URL'] as String? ??
          imageInformation?['Image_Original_URL'] as String? ??
          imageInformation?['Image_URL'] as String? ??
          imageInformation?['URL'] as String?,
      imageId:
          json['ImageID'] as String? ??
          json['Image_ID'] as String? ??
          imageInformation?['ImageID'] as String? ??
          imageInformation?['Image_ID'] as String?,
      societyId: json['SocietyID'] as String?,
      propertyId: json['PropertyID'] as String?,
      billCollectionSummary:
          json['Bill_Collection_Summary'] is Map<String, dynamic>
          ? BillCollectionSummaryData.fromJson(
              json['Bill_Collection_Summary'] as Map<String, dynamic>,
            )
          : null,
      supportTicketSummary:
          json['Support_Ticket_Summary'] is Map<String, dynamic>
          ? SupportTicketSummaryData.fromJson(
              json['Support_Ticket_Summary'] as Map<String, dynamic>,
            )
          : null,
      propertySummary: json['Property_Summary'] is Map<String, dynamic>
          ? PropertySummaryData.fromJson(
              json['Property_Summary'] as Map<String, dynamic>,
            )
          : null,
      rentalContractSummary:
          json['Rental_Contract_Summary'] is Map<String, dynamic>
          ? RentalContractSummaryData.fromJson(
              json['Rental_Contract_Summary'] as Map<String, dynamic>,
            )
          : null,
      walletInfo: json['Wallet_Information'] is Map<String, dynamic>
          ? WalletSummaryData.fromJson(
              json['Wallet_Information'] as Map<String, dynamic>,
            )
          : null,
    );
  }

  final String vendorId;
  final String fullName;
  final String phone;
  final String email;
  final int vendorType;
  final String? imageUrl;
  final String? imageId;
  final String? societyId;
  final String? propertyId;
  final BillCollectionSummaryData? billCollectionSummary;
  final SupportTicketSummaryData? supportTicketSummary;
  final PropertySummaryData? propertySummary;
  final RentalContractSummaryData? rentalContractSummary;
  final WalletSummaryData? walletInfo;
}

class WalletSummaryData {
  const WalletSummaryData({
    required this.availableAmount,
    required this.creditedAmount,
    required this.debitedAmount,
  });

  factory WalletSummaryData.fromJson(Map<String, dynamic> json) {
    return WalletSummaryData(
      availableAmount: (json['Available_Amount'] as num?)?.toDouble() ?? 0,
      creditedAmount: (json['Credited_Amount'] as num?)?.toDouble() ?? 0,
      debitedAmount: (json['Debited_Amount'] as num?)?.toDouble() ?? 0,
    );
  }

  final double availableAmount;
  final double creditedAmount;
  final double debitedAmount;
}

class BillCollectionSummaryData {
  const BillCollectionSummaryData({
    required this.totalCollectedAmount,
    required this.totalPendingAmount,
    required this.totalOverdueAmount,
    required this.currentMonthCollected,
    required this.currentMonthPending,
    required this.currentMonthOverdue,
    required this.todaysCollection,
    this.totalSecurityBillAmount,
    this.pendingSecurityAmount,
    this.collectedSecurityAmount,
  });

  factory BillCollectionSummaryData.fromJson(Map<String, dynamic> json) {
    return BillCollectionSummaryData(
      totalCollectedAmount:
          (json['Total_Collected_Amount'] as num?)?.toDouble() ?? 0,
      totalPendingAmount:
          (json['Total_Pending_Amount'] as num?)?.toDouble() ?? 0,
      totalOverdueAmount:
          (json['Total_Overdue_Amount'] as num?)?.toDouble() ?? 0,
      currentMonthCollected:
          (json['Current_Month_Collected'] as num?)?.toDouble() ?? 0,
      currentMonthPending:
          (json['Current_Month_Pending'] as num?)?.toDouble() ?? 0,
      currentMonthOverdue:
          (json['Current_Month_Overdue'] as num?)?.toDouble() ?? 0,
      todaysCollection: (json['Todays_Collection'] as num?)?.toDouble() ?? 0,
      totalSecurityBillAmount: (json['Total_Security_Bill_Amount'] as num?)
          ?.toDouble(),
      pendingSecurityAmount: (json['Pending_Security_Amount'] as num?)
          ?.toDouble(),
      collectedSecurityAmount: (json['Collected_Security_Amount'] as num?)
          ?.toDouble(),
    );
  }

  final double totalCollectedAmount;
  final double totalPendingAmount;
  final double totalOverdueAmount;
  final double currentMonthCollected;
  final double currentMonthPending;
  final double currentMonthOverdue;
  final double todaysCollection;
  final double? totalSecurityBillAmount;
  final double? pendingSecurityAmount;
  final double? collectedSecurityAmount;
}

class SupportTicketSummaryData {
  const SupportTicketSummaryData({
    required this.openTicketsCount,
    required this.inProgressTicketsCount,
    required this.resolvedTicketsCount,
    required this.criticalOpenTicketsCount,
  });

  factory SupportTicketSummaryData.fromJson(Map<String, dynamic> json) {
    return SupportTicketSummaryData(
      openTicketsCount: json['Open_Tickets_Count'] as int? ?? 0,
      inProgressTicketsCount: json['InProgress_Tickets_Count'] as int? ?? 0,
      resolvedTicketsCount: json['Resolved_Tickets_Count'] as int? ?? 0,
      criticalOpenTicketsCount:
          json['Critical_Open_Tickets_Count'] as int? ?? 0,
    );
  }

  final int openTicketsCount;
  final int inProgressTicketsCount;
  final int resolvedTicketsCount;
  final int criticalOpenTicketsCount;
}

class PropertySummaryData {
  const PropertySummaryData({
    required this.totalPropertiesCount,
    required this.approvedPropertiesCount,
    required this.rejectedPropertiesCount,
    required this.pendingPropertiesCount,
  });

  factory PropertySummaryData.fromJson(Map<String, dynamic> json) {
    return PropertySummaryData(
      totalPropertiesCount: json['Total_Properties_Count'] as int? ?? 0,
      approvedPropertiesCount: json['Approved_Properties_Count'] as int? ?? 0,
      rejectedPropertiesCount: json['Rejected_Properties_Count'] as int? ?? 0,
      pendingPropertiesCount: json['Pending_Properties_Count'] as int? ?? 0,
    );
  }

  final int totalPropertiesCount;
  final int approvedPropertiesCount;
  final int rejectedPropertiesCount;
  final int pendingPropertiesCount;
}

class RentalContractSummaryData {
  const RentalContractSummaryData({
    required this.activeContractsCount,
    required this.expiredContractsCount,
    required this.pendingRenewalCount,
    required this.totalMonthlyRent,
  });

  factory RentalContractSummaryData.fromJson(Map<String, dynamic> json) {
    return RentalContractSummaryData(
      activeContractsCount: json['Active_Contracts_Count'] as int? ?? 0,
      expiredContractsCount: json['Expired_Contracts_Count'] as int? ?? 0,
      pendingRenewalCount: json['Pending_Renewal_Count'] as int? ?? 0,
      totalMonthlyRent: (json['Total_Monthly_Rent'] as num?)?.toDouble() ?? 0,
    );
  }

  final int activeContractsCount;
  final int expiredContractsCount;
  final int pendingRenewalCount;
  final double totalMonthlyRent;
}

// ---------------------------------------------------------------------------
// Public Discovery
// ---------------------------------------------------------------------------

class PublicBannerData {
  const PublicBannerData({
    required this.bannerId,
    this.title,
    this.imageUrl,
    this.navigationUrl,
  });

  factory PublicBannerData.fromJson(Map<String, dynamic> json) {
    final Map<String, dynamic>? webImage =
        json['Web_Image_Information'] as Map<String, dynamic>?;

    return PublicBannerData(
      bannerId: json['BannerID'] as String? ?? json['_id'] as String? ?? '',
      title: json['Title'] as String?,
      imageUrl: webImage?['Image_Original_URL'] as String?,
      navigationUrl:
          json['URL'] as String? ??
          json['Link'] as String? ??
          json['Banner_URL'] as String? ??
          json['Navigation_URL'] as String? ??
          json['Redirect_URL'] as String?,
    );
  }

  final String bannerId;
  final String? title;
  final String? imageUrl;
  final String? navigationUrl;
}

class PublicCityData {
  const PublicCityData({required this.cityId, required this.cityName});

  factory PublicCityData.fromJson(Map<String, dynamic> json) {
    return PublicCityData(
      cityId: json['CityID'] as String? ?? '',
      cityName: json['City_Name'] as String? ?? '',
    );
  }

  final String cityId;
  final String cityName;
}

class PropertyStateData {
  const PropertyStateData({required this.stateId, required this.stateName});

  factory PropertyStateData.fromJson(Map<String, dynamic> json) {
    return PropertyStateData(
      stateId: json['StateID'] as String? ?? '',
      stateName: json['State_Name'] as String? ?? '',
    );
  }

  final String stateId;
  final String stateName;
}

class PropertyCityData {
  const PropertyCityData({required this.cityId, required this.cityName});

  factory PropertyCityData.fromJson(Map<String, dynamic> json) {
    return PropertyCityData(
      cityId: json['CityID'] as String? ?? '',
      cityName: json['City_Name'] as String? ?? '',
    );
  }

  final String cityId;
  final String cityName;
}

class SubscriptionPlanData {
  const SubscriptionPlanData({
    required this.subscriptionId,
    required this.subscriptionType,
    required this.title,
    required this.description,
    required this.price,
    required this.duration,
    required this.isActive,
  });

  factory SubscriptionPlanData.fromJson(Map<String, dynamic> json) {
    return SubscriptionPlanData(
      subscriptionId: json['SubscriptionID'] as String? ?? '',
      subscriptionType: json['Subscription_Type'] as int? ?? 0,
      title: json['Title'] as String? ?? '',
      description: json['Description'] as String? ?? '',
      price: (json['Price'] as num?)?.toDouble() ?? 0,
      duration: json['Duration'] as int? ?? 0,
      isActive: json['Status'] as bool? ?? true,
    );
  }

  final String subscriptionId;
  final int subscriptionType;
  final String title;
  final String description;
  final double price;
  final int duration;
  final bool isActive;
}

class SubscriptionCalculationData {
  const SubscriptionCalculationData({
    required this.subscriptionPrice,
    required this.activeRentalContractsCount,
    required this.freeContractsCount,
    required this.extraContractsCount,
    required this.totalAvailableContracts,
    required this.amountPerContract,
    required this.extraContractsAmount,
    required this.subtotal,
    required this.gstPercentage,
    required this.gstAmount,
    required this.totalAmount,
  });

  factory SubscriptionCalculationData.fromJson(Map<String, dynamic> json) {
    return SubscriptionCalculationData(
      subscriptionPrice: (json['Subscription_Price'] as num?)?.toDouble() ?? 0,
      activeRentalContractsCount:
          json['Active_Rental_Contracts_Count'] as int? ?? 0,
      freeContractsCount: json['Free_Contracts_Count'] as int? ?? 0,
      extraContractsCount: json['Extra_Contracts_Count'] as int? ?? 0,
      totalAvailableContracts: json['Total_Available_Contracts'] as int? ?? 0,
      amountPerContract: (json['Amount_Per_Contract'] as num?)?.toDouble() ?? 0,
      extraContractsAmount:
          (json['Extra_Contracts_Amount'] as num?)?.toDouble() ?? 0,
      subtotal: (json['Subtotal'] as num?)?.toDouble() ?? 0,
      gstPercentage: (json['GST_Percentage'] as num?)?.toDouble() ?? 0,
      gstAmount: (json['GST_Amount'] as num?)?.toDouble() ?? 0,
      totalAmount: (json['Total_Amount'] as num?)?.toDouble() ?? 0,
    );
  }

  final double subscriptionPrice;
  final int activeRentalContractsCount;
  final int freeContractsCount;
  final int extraContractsCount;
  final int totalAvailableContracts;
  final double amountPerContract;
  final double extraContractsAmount;
  final double subtotal;
  final double gstPercentage;
  final double gstAmount;
  final double totalAmount;
}

class ResidentContractsCalculationData {
  const ResidentContractsCalculationData({
    required this.amountPerContract,
    required this.numberOfContracts,
    required this.subtotal,
    required this.gstPercentage,
    required this.gstAmount,
    required this.totalAmount,
  });

  factory ResidentContractsCalculationData.fromJson(Map<String, dynamic> json) {
    return ResidentContractsCalculationData(
      amountPerContract: (json['Amount_Per_Contract'] as num?)?.toDouble() ?? 0,
      numberOfContracts: json['No_Of_Contracts'] as int? ?? 0,
      subtotal: (json['Subtotal'] as num?)?.toDouble() ?? 0,
      gstPercentage: (json['GST_Percentage'] as num?)?.toDouble() ?? 0,
      gstAmount: (json['GST_Amount'] as num?)?.toDouble() ?? 0,
      totalAmount: (json['Total_Amount'] as num?)?.toDouble() ?? 0,
    );
  }

  final double amountPerContract;
  final int numberOfContracts;
  final double subtotal;
  final double gstPercentage;
  final double gstAmount;
  final double totalAmount;
}

class ResidentContractsPurchaseData {
  const ResidentContractsPurchaseData({
    required this.purchaseId,
    required this.amount,
    required this.currency,
    required this.calculation,
    required this.isFreePurchase,
    this.razorpayOrderId,
    this.razorpayKeyId,
  });

  factory ResidentContractsPurchaseData.fromJson(Map<String, dynamic> json) {
    return ResidentContractsPurchaseData(
      purchaseId: json['Vendor_Property_Contract_PurchaseID'] as String? ?? '',
      amount: (json['Amount'] as num?)?.toDouble() ?? 0,
      currency: json['Currency'] as String? ?? 'INR',
      calculation: ResidentContractsCalculationData.fromJson(
        (json['Calculation_Data'] as Map<String, dynamic>?) ??
            <String, dynamic>{},
      ),
      isFreePurchase: json['Is_Free_Purchase'] as bool? ?? false,
      razorpayOrderId: json['Razorpay_Order_ID'] as String?,
      razorpayKeyId: json['Razorpay_Key_ID'] as String?,
    );
  }

  final String purchaseId;
  final double amount;
  final String currency;
  final ResidentContractsCalculationData calculation;
  final bool isFreePurchase;
  final String? razorpayOrderId;
  final String? razorpayKeyId;
}

class SocietyResidentsCalculationData {
  const SocietyResidentsCalculationData({
    required this.amountPerResident,
    required this.numberOfResidents,
    required this.subtotal,
    required this.gstPercentage,
    required this.gstAmount,
    required this.totalAmount,
    this.residentsCountDifference,
    this.validityEndDate,
  });

  factory SocietyResidentsCalculationData.fromJson(Map<String, dynamic> json) {
    return SocietyResidentsCalculationData(
      amountPerResident: (json['Amount_Per_Resident'] as num?)?.toDouble() ?? 0,
      numberOfResidents: json['No_Of_Residents'] as int? ?? 0,
      residentsCountDifference: json['Residents_Count_Difference'] as int?,
      subtotal: (json['Subtotal'] as num?)?.toDouble() ?? 0,
      gstPercentage: (json['GST_Percentage'] as num?)?.toDouble() ?? 0,
      gstAmount: (json['GST_Amount'] as num?)?.toDouble() ?? 0,
      totalAmount: (json['Total_Amount'] as num?)?.toDouble() ?? 0,
      validityEndDate: json['Validity_End_Date'] as String?,
    );
  }

  final double amountPerResident;
  final int numberOfResidents;
  final int? residentsCountDifference;
  final double subtotal;
  final double gstPercentage;
  final double gstAmount;
  final double totalAmount;
  final String? validityEndDate;
}

class SocietyResidentsPurchaseData {
  const SocietyResidentsPurchaseData({
    required this.purchaseId,
    required this.amount,
    required this.currency,
    required this.calculation,
    required this.isFreePurchase,
    this.razorpayOrderId,
    this.razorpayKeyId,
  });

  factory SocietyResidentsPurchaseData.fromJson(Map<String, dynamic> json) {
    return SocietyResidentsPurchaseData(
      purchaseId: json['Society_Resident_PurchaseID'] as String? ?? '',
      amount: (json['Amount'] as num?)?.toDouble() ?? 0,
      currency: json['Currency'] as String? ?? 'INR',
      calculation: SocietyResidentsCalculationData.fromJson(
        (json['Calculation_Data'] as Map<String, dynamic>?) ??
            <String, dynamic>{},
      ),
      isFreePurchase: json['Is_Free_Purchase'] as bool? ?? false,
      razorpayOrderId: json['Razorpay_Order_ID'] as String?,
      razorpayKeyId: json['Razorpay_Key_ID'] as String?,
    );
  }

  final String purchaseId;
  final double amount;
  final String currency;
  final SocietyResidentsCalculationData calculation;
  final bool isFreePurchase;
  final String? razorpayOrderId;
  final String? razorpayKeyId;
}

// ---------------------------------------------------------------------------
// Bill
// ---------------------------------------------------------------------------

class BillData {
  const BillData({
    required this.billId,
    required this.billTitle,
    required this.amount,
    required this.dueDate,
    required this.billStatus,
    this.billType,
    this.unitLabel,
    this.note,
    this.paidDate,
    required this.payload,
  });

  factory BillData.fromJson(Map<String, dynamic> json) {
    return BillData(
      billId: json['BillID'] as String? ?? json['_id'] as String? ?? '',
      billTitle:
          json['Bill_Title'] as String? ?? json['Title'] as String? ?? 'Bill',
      amount:
          _toDouble(json['Bill_Final_Amount']) ??
          _toDouble(json['Amount']) ??
          _toDouble(json['Bill_Amount']) ??
          0,
      dueDate:
          DateTime.tryParse(
            json['Due_Date'] as String? ??
                json['Bill_Due_Date'] as String? ??
                '',
          ) ??
          DateTime.now(),
      billStatus: json['Bill_Status'] as int? ?? 1,
      billType: json['Bill_Type'] as int?,
      unitLabel:
          json['Flat_Or_Unit_No'] as String? ?? json['Flat_No'] as String?,
      note: json['Description'] as String? ?? json['Note'] as String?,
      paidDate: json['Paid_Date'] as String?,
      payload: json,
    );
  }

  final String billId;
  final String billTitle;
  final double amount;
  final DateTime dueDate;
  final int billStatus;
  final int? billType;
  final String? unitLabel;
  final String? note;
  final String? paidDate;
  final Map<String, dynamic> payload;

  BillRecord toBillRecord() {
    final Map<String, dynamic>? residentInfo =
        payload['Society_Resident_Information'] is Map<String, dynamic>
        ? payload['Society_Resident_Information'] as Map<String, dynamic>
        : null;
    final Map<String, dynamic>? contractInfo =
        payload['Property_Rental_Contract_Information'] is Map<String, dynamic>
        ? payload['Property_Rental_Contract_Information']
              as Map<String, dynamic>
        : null;
    final Map<String, dynamic>? paymentImageInfo =
        payload['Bill_Payment_Image_Information'] is Map<String, dynamic>
        ? payload['Bill_Payment_Image_Information'] as Map<String, dynamic>
        : null;

    // Treat empty strings as absent so fallback chain works properly.
    String _nonEmpty(String? v) => (v != null && v.trim().isNotEmpty) ? v : '';

    final String resolvedUnit = _nonEmpty(unitLabel).isNotEmpty
        ? unitLabel!
        : _nonEmpty(residentInfo?['Flat_No'] as String?).isNotEmpty
        ? residentInfo!['Flat_No'] as String
        : _nonEmpty(contractInfo?['Flat_Or_Unit_No'] as String?).isNotEmpty
        ? contractInfo!['Flat_Or_Unit_No'] as String
        : 'N/A';

    return BillRecord(
      id: billId,
      title: billTitle,
      unitLabel: resolvedUnit,
      amount: amount,
      dueDate: dueDate,
      status: _mapBillStatus(billStatus),
      category: _mapBillType(billType),
      note: note,
      billTypeCode: billType,
      finalAmount: _toDouble(payload['Bill_Final_Amount']) ?? amount,
      billDate: _parseDate(
        payload['Bill_Date'] as String? ?? payload['Created_At'] as String?,
      ),
      paidDate: _parseDate(payload['Bill_Paid_Date'] as String? ?? paidDate),
      paymentType: payload['Bill_Payment_Type'] as int?,
      manualOnlinePaymentMode:
          payload['Bill_Manual_Online_Payment_Mode'] as int?,
      paymentNote:
          payload['Bill_Payment_Description'] as String? ??
          payload['Description'] as String?,
      billAmount:
          _toDouble(payload['Bill_Amount']) ?? _toDouble(payload['Amount']),
      maintenanceAmount: _toDouble(payload['Bill_Maintainance_Amount']),
      tokenAmount: _toDouble(payload['Bill_Token_Amount']),
      paymentImageUrl: paymentImageInfo?['Image_Original_URL'] as String?,
      walletCredited:
          payload['Whether_Bill_Amount_Credited_To_Wallet'] as bool?,
      walletCreditTime: _parseDate(
        payload['Bill_Amount_Wallet_Credit_Time'] as String?,
      ),
      walletCreditedTime: _parseDate(
        payload['Bill_Amount_Wallet_Credited_Time'] as String?,
      ),
      residentName:
          residentInfo?['Name'] as String? ??
          contractInfo?['Tenant_Name'] as String?,
      residentPhone:
          residentInfo?['PhoneNumber'] as String? ??
          contractInfo?['Tenant_PhoneNumber'] as String?,
      residentEmail:
          residentInfo?['EmailID'] as String? ??
          contractInfo?['Tenant_EmailID'] as String?,
      residentTypeLabel: _residentTypeLabel(
        residentInfo?['Resident_Type'] as int?,
      ),
      societyName: residentInfo?['Society_Name'] as String?,
      blockName: residentInfo?['Block_Name'] as String?,
      buildingName: residentInfo?['Building_Name'] as String?,
      propertyTitle: contractInfo?['Property_Title'] as String?,
      ownerName: contractInfo?['Owner_Name'] as String?,
      ownerPhone: contractInfo?['Owner_PhoneNumber'] as String?,
      ownerEmail: contractInfo?['Owner_EmailID'] as String?,
      contractStartDate: _parseDate(
        contractInfo?['Contract_Start_Date'] as String?,
      ),
      contractEndDate: _parseDate(
        contractInfo?['Contract_End_Date'] as String?,
      ),
      rentAmount: _toDouble(contractInfo?['Monthly_Rent']),
      depositAmount: _toDouble(contractInfo?['Security_Deposit']),
      vacateDate: _parseDate(contractInfo?['Vacate_Date'] as String?),
    );
  }

  static BillStatus _mapBillStatus(int status) {
    return switch (status) {
      1 => BillStatus.pending,
      2 => BillStatus.paid,
      3 => BillStatus.overdue,
      4 => BillStatus.partial,
      _ => BillStatus.pending,
    };
  }

  static String _mapBillType(int? type) {
    return switch (type) {
      1 => 'Maintenance',
      2 => 'Rental Amount',
      3 => 'Security Deposit',
      4 => 'Other',
      _ => 'Bill',
    };
  }

  static DateTime? _parseDate(String? value) {
    if (value == null || value.isEmpty) {
      return null;
    }
    return DateTime.tryParse(value);
  }

  static double? _toDouble(dynamic value) {
    return (value as num?)?.toDouble();
  }

  static String? _residentTypeLabel(int? residentType) {
    return switch (residentType) {
      1 => 'Owner',
      2 => 'Tenant',
      3 => 'PG Resident',
      _ => null,
    };
  }
}

// ---------------------------------------------------------------------------
// Support Ticket
// ---------------------------------------------------------------------------

class SupportTicketData {
  const SupportTicketData({
    required this.ticketId,
    required this.title,
    required this.description,
    required this.ticketStatus,
    required this.priority,
    required this.category,
    this.updatedAt,
    this.assignee,
    this.createdAt,
    this.targetName,
    this.imageUrl,
    this.societyName,
    this.blockName,
    this.buildingName,
    this.flatNo,
    this.propertyTitle,
    this.propertyFlatNo,
    this.tenantName,
    this.tenantPhone,
  });

  factory SupportTicketData.fromJson(Map<String, dynamic> json) {
    final Map<String, dynamic>? imageInfo =
        json['Image_Information'] is Map<String, dynamic>
        ? json['Image_Information'] as Map<String, dynamic>
        : null;
    final Map<String, dynamic>? vendorTypeData =
        json['Vendor_Ticket_Type_Data'] is Map<String, dynamic>
        ? json['Vendor_Ticket_Type_Data'] as Map<String, dynamic>
        : null;
    final Map<String, dynamic>? societyData =
        json['Society_Data'] is Map<String, dynamic>
        ? json['Society_Data'] as Map<String, dynamic>
        : null;
    final Map<String, dynamic>? blockData =
        json['Block_Data'] is Map<String, dynamic>
        ? json['Block_Data'] as Map<String, dynamic>
        : null;
    final Map<String, dynamic>? buildingData =
        json['Building_Data'] is Map<String, dynamic>
        ? json['Building_Data'] as Map<String, dynamic>
        : null;
    final Map<String, dynamic>? residentData =
        json['Resident_Data'] is Map<String, dynamic>
        ? json['Resident_Data'] as Map<String, dynamic>
        : null;
    // For property manager tickets: Property_Data and Rental_Contract_Data
    final Map<String, dynamic>? propertyData =
        json['Property_Data'] is Map<String, dynamic>
        ? json['Property_Data'] as Map<String, dynamic>
        : null;
    final Map<String, dynamic>? contractData =
        json['Rental_Contract_Data'] is Map<String, dynamic>
        ? json['Rental_Contract_Data'] as Map<String, dynamic>
        : null;

    return SupportTicketData(
      ticketId:
          json['Support_TicketID'] as String? ?? json['_id'] as String? ?? '',
      title: json['Title'] as String? ?? '',
      description: json['Description'] as String? ?? '',
      ticketStatus: json['Ticket_Status'] as int? ?? 1,
      priority: json['Priority'] as int? ?? 1,
      category: json['Category'] as int? ?? 1,
      updatedAt: json['updatedAt'] as String? ?? json['Updated_At'] as String?,
      assignee: json['Assignee_Name'] as String?,
      createdAt:
          json['createdAt'] as String? ??
          json['created_at'] as String? ??
          json['Created_At'] as String?,
      targetName: vendorTypeData?['Name'] as String?,
      imageUrl: imageInfo?['Image_Original_URL'] as String?,
      societyName: societyData?['Name'] as String?,
      blockName: blockData?['Name'] as String?,
      buildingName: buildingData?['Name'] as String?,
      flatNo: residentData?['Flat_No'] as String?,
      propertyTitle: propertyData?['Property_Title'] as String?,
      propertyFlatNo: propertyData?['Flat_Or_Unit_No'] as String?,
      tenantName: contractData?['Tenant_Name'] as String?,
      tenantPhone: contractData?['Tenant_PhoneNumber'] as String?,
    );
  }

  final String ticketId;
  final String title;
  final String description;
  final int ticketStatus;
  final int priority;
  final int category;
  final String? updatedAt;
  final String? assignee;
  final String? createdAt;
  final String? targetName;
  final String? imageUrl;
  final String? societyName;
  final String? blockName;
  final String? buildingName;
  final String? flatNo;
  final String? propertyTitle;
  final String? propertyFlatNo;
  final String? tenantName;
  final String? tenantPhone;

  TicketRecord toTicketRecord() {
    return TicketRecord(
      id: ticketId,
      title: title,
      description: description,
      status: _mapTicketStatus(ticketStatus),
      priority: _mapPriority(priority),
      category: _mapCategory(category),
      updatedAt: DateTime.tryParse(updatedAt ?? '') ?? DateTime.now(),
      assignee: assignee,
      createdAt: DateTime.tryParse(createdAt ?? ''),
      targetName: targetName,
      imageUrl: imageUrl,
      societyName: societyName,
      blockName: blockName,
      buildingName: buildingName,
      flatNo: flatNo,
      propertyTitle: propertyTitle,
      propertyFlatNo: propertyFlatNo,
      tenantName: tenantName,
      tenantPhone: tenantPhone,
    );
  }

  static TicketStatus _mapTicketStatus(int status) {
    return switch (status) {
      1 => TicketStatus.open,
      2 => TicketStatus.inProgress,
      3 => TicketStatus.resolved,
      4 => TicketStatus.rejected,
      _ => TicketStatus.open,
    };
  }

  static TicketPriority _mapPriority(int priority) {
    return switch (priority) {
      1 => TicketPriority.low,
      2 => TicketPriority.medium,
      3 => TicketPriority.high,
      4 => TicketPriority.urgent,
      _ => TicketPriority.low,
    };
  }

  static String _mapCategory(int category) {
    return switch (category) {
      1 => 'Maintenance',
      2 => 'Billing',
      3 => 'Security',
      4 => 'Amenities',
      5 => 'Others',
      6 => 'Others',
      _ => 'Others',
    };
  }
}

// ---------------------------------------------------------------------------
// Announcement
// ---------------------------------------------------------------------------

class AnnouncementData {
  const AnnouncementData({
    required this.announcementId,
    required this.title,
    required this.description,
    required this.priority,
    this.createdAt,
    this.isRead = false,
    this.blockIds = const <String>[],
    this.buildingIds = const <String>[],
    this.blockNames = const <String>[],
    this.buildingNames = const <String>[],
  });

  factory AnnouncementData.fromJson(Map<String, dynamic> json) {
    final List<dynamic> blockIdArray =
        (json['BlockID_Array'] as List<dynamic>?) ?? const <dynamic>[];
    final List<dynamic> buildingIdArray =
        (json['BuildingID_Array'] as List<dynamic>?) ?? const <dynamic>[];
    final List<dynamic> blockDataArray =
        (json['Block_Array_Data'] as List<dynamic>?) ?? const <dynamic>[];
    final List<dynamic> buildingDataArray =
        (json['Building_Array_Data'] as List<dynamic>?) ?? const <dynamic>[];

    return AnnouncementData(
      announcementId:
          json['Society_AnnouncementID'] as String? ??
          json['Vendor_AnnouncementID'] as String? ??
          json['_id'] as String? ??
          '',
      title: json['Title'] as String? ?? '',
      description: json['Description'] as String? ?? '',
      priority: json['Priority'] as int? ?? 1,
      createdAt:
          json['createdAt'] as String? ??
          json['Created_At'] as String? ??
          json['created_at'] as String?,
      isRead:
          json['Is_Read'] as bool? ?? json['Whether_Read'] as bool? ?? false,
      blockIds: blockIdArray.map((dynamic item) => '$item').toList(),
      buildingIds: buildingIdArray.map((dynamic item) => '$item').toList(),
      blockNames: blockDataArray
          .whereType<Map<String, dynamic>>()
          .map((Map<String, dynamic> item) => item['Name'] as String? ?? '')
          .where((String item) => item.isNotEmpty)
          .toList(),
      buildingNames: buildingDataArray
          .whereType<Map<String, dynamic>>()
          .map((Map<String, dynamic> item) => item['Name'] as String? ?? '')
          .where((String item) => item.isNotEmpty)
          .toList(),
    );
  }

  final String announcementId;
  final String title;
  final String description;
  final int priority;
  final String? createdAt;
  final bool isRead;
  final List<String> blockIds;
  final List<String> buildingIds;
  final List<String> blockNames;
  final List<String> buildingNames;

  AnnouncementRecord toAnnouncementRecord() {
    return AnnouncementRecord(
      id: announcementId,
      title: title,
      message: description,
      category: AnnouncementCategory.maintenance,
      createdAt: DateTime.tryParse(createdAt ?? '') ?? DateTime.now(),
      unread: !isRead,
      priorityLabel: _mapPriorityLabel(priority),
      blockIds: blockIds,
      buildingIds: buildingIds,
      blockNames: blockNames,
      buildingNames: buildingNames,
    );
  }

  static String _mapPriorityLabel(int priority) {
    return switch (priority) {
      1 => 'Low',
      2 => 'Medium',
      3 => 'High',
      _ => 'Low',
    };
  }
}

// ---------------------------------------------------------------------------
// Incident
// ---------------------------------------------------------------------------

class IncidentData {
  const IncidentData({
    required this.incidentId,
    required this.title,
    required this.description,
    required this.incidentStatus,
    required this.priority,
    required this.isActive,
    this.location,
    this.createdAt,
    this.blockName,
    this.buildingName,
    this.imageUrl,
  });

  factory IncidentData.fromJson(Map<String, dynamic> json) {
    return IncidentData(
      incidentId:
          json['Society_IncidentID'] as String? ?? json['_id'] as String? ?? '',
      title: json['Title'] as String? ?? '',
      description: json['Description'] as String? ?? '',
      incidentStatus: json['Incident_Status'] as int? ?? 1,
      priority: json['Priority'] as int? ?? 1,
      isActive: json['Status'] as bool? ?? true,
      location: json['Location'] as String?,
      createdAt: json['createdAt'] as String? ?? json['Created_At'] as String?,
      blockName: json['Block_Data'] is Map<String, dynamic>
          ? (json['Block_Data'] as Map<String, dynamic>)['Name'] as String?
          : json['Block_Name'] as String?,
      buildingName: json['Building_Data'] is Map<String, dynamic>
          ? (json['Building_Data'] as Map<String, dynamic>)['Name'] as String?
          : json['Building_Name'] as String?,
      imageUrl: json['Image_Information'] is Map<String, dynamic>
          ? (json['Image_Information']
                    as Map<String, dynamic>)['Image_Original_URL']
                as String?
          : null,
    );
  }

  final String incidentId;
  final String title;
  final String description;
  final int incidentStatus;
  final int priority;
  final bool isActive;
  final String? location;
  final String? createdAt;
  final String? blockName;
  final String? buildingName;
  final String? imageUrl;

  TicketRecord toTicketRecord() {
    return TicketRecord(
      id: incidentId,
      title: title,
      description: description,
      status: _mapIncidentStatus(incidentStatus),
      priority: _mapPriority(priority),
      category: 'Incident${location != null ? ' - $location' : ''}',
      updatedAt: DateTime.tryParse(createdAt ?? '') ?? DateTime.now(),
    );
  }

  IncidentRecord toIncidentRecord() {
    return IncidentRecord(
      id: incidentId,
      title: title,
      description: description,
      status: _mapIncidentRecordStatus(incidentStatus),
      priority: _mapIncidentRecordPriority(priority),
      createdAt: DateTime.tryParse(createdAt ?? '') ?? DateTime.now(),
      isActive: isActive,
      location: location,
      blockName: blockName,
      buildingName: buildingName,
      imageUrl: imageUrl,
    );
  }

  static TicketStatus _mapIncidentStatus(int status) {
    return switch (status) {
      1 => TicketStatus.open,
      2 => TicketStatus.inProgress,
      3 => TicketStatus.resolved,
      _ => TicketStatus.open,
    };
  }

  static TicketPriority _mapPriority(int priority) {
    return switch (priority) {
      1 => TicketPriority.low,
      2 => TicketPriority.medium,
      3 => TicketPriority.high,
      4 => TicketPriority.urgent,
      _ => TicketPriority.low,
    };
  }

  static IncidentStatus _mapIncidentRecordStatus(int status) {
    return switch (status) {
      1 => IncidentStatus.open,
      2 => IncidentStatus.investigating,
      3 => IncidentStatus.resolved,
      _ => IncidentStatus.open,
    };
  }

  static IncidentPriority _mapIncidentRecordPriority(int priority) {
    return switch (priority) {
      1 => IncidentPriority.low,
      2 => IncidentPriority.medium,
      3 => IncidentPriority.high,
      4 => IncidentPriority.critical,
      _ => IncidentPriority.low,
    };
  }
}

// ---------------------------------------------------------------------------
// Property
// ---------------------------------------------------------------------------

class PropertyData {
  const PropertyData({
    required this.propertyId,
    required this.title,
    required this.description,
    required this.propertyType,
    required this.propertyStatus,
    this.rent = 0,
    this.deposit = 0,
    this.imageUrl,
    this.locationAddress,
    this.address,
    this.bedrooms,
    this.bathrooms,
    this.balconies,
    this.floor,
    this.area,
    this.furnishedType,
    this.facing,
    this.amenities,
    this.category,
    this.subType,
    this.pgSharingType,
    this.flatUnitNo,
    this.maintenance,
    this.brokerage,
    this.availableFrom,
    this.ownerName,
    this.ownerPhone,
    this.ownerEmail,
    this.state,
    this.city,
    this.images,
    this.imageIds,
    this.noOfVacancy,
    this.latitude,
    this.longitude,
    this.distanceKm,
    this.stateId,
    this.cityId,
    this.amenityIds,
    this.propertyRulesDescription,
    this.floorPlanDocumentId,
    this.floorPlanDocumentUrl,
    this.isSubscribed = false,
    this.wasSubscribedAtLeastOnce = false,
    this.currentSubscriptionId,
    this.currentSubscriptionTitle,
    this.currentSubscriptionExpiryDate,
    this.totalPurchasedResidentContractsCreationCount,
    this.availableResidentContractsCreationCount,
    this.freeResidentContractsCount,
    this.usedResidentContractsCount,
    this.totalResidentContractsCount,
    this.carpetArea,
    this.noOfFloors,
    this.gender,
    this.locality,
    this.pincode,
    this.ownerAddress,
    this.electricityBillType,
    this.waterBillType,
    this.gasBillType,
    this.internetBillType,
    this.whetherParkingAvailable,
    this.parkingType,
    this.parkingSlots,
    this.parkingCharges,
    this.metroOrBusStation,
    this.hospital,
    this.schoolOrCollege,
    this.shoppingMall,
    this.restaurant,
    this.atmOrBank,
    this.preferredTenantType,
    this.petPolicy,
    this.smokingPolicy,
    this.visitorsPolicy,
    this.subscriptionExpired,
    this.whetherVerifiedPlus,
    this.totalLeads,
    this.totalUnseenLeads,
    this.whetherEnquired = false,
    this.whetherBooked = false,
    this.tenantPropertyStatus,
  });

  factory PropertyData.fromJson(Map<String, dynamic> json) {
    final List<dynamic>? rawImages =
        (json['Images'] as List<dynamic>?) ??
        (json['Property_Image_Array_Information'] as List<dynamic>?);
    final List<String>? imagesList = rawImages
        ?.map((dynamic e) {
          if (e is Map<String, dynamic>) {
            return e['Image_Original_URL'] as String? ??
                e['Image_URL'] as String? ??
                '';
          }
          return e.toString();
        })
        .where((String value) => value.isNotEmpty)
        .toList();
    final List<String>? imageIds = rawImages
        ?.map((dynamic e) {
          if (e is Map<String, dynamic>) {
            return e['ImageID'] as String? ?? '';
          }
          return '';
        })
        .where((String value) => value.isNotEmpty)
        .toList();
    final List<int>? amenityIds = (json['Amenities'] as List<dynamic>?)
        ?.map((dynamic e) => (e as num?)?.toInt() ?? 0)
        .where((int value) => value > 0)
        .toList();
    final String? amenitiesValue = switch (json['Amenities']) {
      String value => value,
      List<dynamic> value => value.map((dynamic item) => '$item').join(', '),
      _ => null,
    };
    final Map<String, dynamic>? floorPlanDocument =
        json['Floor_Plan_Document_Information'] as Map<String, dynamic>?;
    final Map<String, dynamic>? currentSubscription =
        json['Current_Subscription_Data'] as Map<String, dynamic>?;
    final Map<String, dynamic>? subscriptionData =
        currentSubscription?['Subsciption_Data'] as Map<String, dynamic>? ??
        currentSubscription?['Subscription_Data'] as Map<String, dynamic>?;

    return PropertyData(
      propertyId: json['PropertyID'] as String? ?? json['_id'] as String? ?? '',
      title:
          json['Title'] as String? ?? json['Property_Title'] as String? ?? '',
      description:
          json['Description'] as String? ??
          json['Property_Description'] as String? ??
          '',
      propertyType: json['Property_Type'] as int? ?? 1,
      propertyStatus: json['Property_Status'] as int? ?? 1,
      rent:
          (json['Rent'] as num?)?.toDouble() ??
          (json['Monthly_Rent'] as num?)?.toDouble() ??
          0,
      deposit:
          (json['Deposit'] as num?)?.toDouble() ??
          (json['Security_Deposit'] as num?)?.toDouble() ??
          0,
      imageUrl:
          json['Image_Original_URL'] as String? ??
          (imagesList != null && imagesList.isNotEmpty
              ? imagesList.first
              : null),
      locationAddress: json['Location_Address'] as String?,
      address:
          json['Address'] as String? ??
          json['Full_Address'] as String? ??
          json['Owner_Address'] as String?,
      bedrooms: json['Bedrooms'] as int?,
      bathrooms: json['Bathrooms'] as int?,
      balconies: json['Balconies'] as int?,
      floor: json['Floor'] as int? ?? json['Floor_No'] as int?,
      area:
          (json['Area'] as num?)?.toDouble() ??
          (json['Total_Area'] as num?)?.toDouble() ??
          (json['Carpet_Area'] as num?)?.toDouble(),
      furnishedType: json['Furnished_Type'] as int?,
      facing: json['Facing'] as String?,
      amenities: amenitiesValue,
      category: json['Category'] as int?,
      subType: json['Sub_Type'] as int?,
      pgSharingType: json['PG_Sharing_Type'] as int?,
      flatUnitNo: json['Flat_Or_Unit_No'] as String?,
      maintenance:
          (json['Maintenance'] as num?)?.toDouble() ??
          (json['Maintainance_Charge'] as num?)?.toDouble(),
      brokerage:
          (json['Brokerage'] as num?)?.toDouble() ??
          (json['Brokerage_Percentage'] as num?)?.toDouble(),
      availableFrom: json['Available_From'] as String?,
      ownerName: json['Owner_Name'] as String?,
      ownerPhone: json['Owner_Phone'] as String?,
      ownerEmail: json['Owner_Email'] as String?,
      state:
          json['State'] as String? ??
          (json['State_Information'] as Map<String, dynamic>?)?['State_Name']
              as String?,
      city:
          json['City'] as String? ??
          (json['City_Information'] as Map<String, dynamic>?)?['City_Name']
              as String?,
      images: imagesList,
      imageIds: imageIds,
      noOfVacancy:
          // Public website displays this field as "Vacancies Available".
          _readInt(json['Available_Resident_Contracts_Creation_Count']) ??
          _readInt(json['No_Of_Vacancy']) ??
          _readInt(json['No_Of_Vacancies']) ??
          _readInt(json['Vacancy']) ??
          _readInt(json['Vacancies']) ??
          _readInt(json['Available_Vacancy']) ??
          _readInt(json['Available_Vacancies']) ??
          _readInt(json['Available_Rooms']) ??
          _readInt(json['No_Of_Rooms_Available']),
      latitude: (json['Latitude'] as num?)?.toDouble(),
      longitude: (json['Longitude'] as num?)?.toDouble(),
      distanceKm:
          _readDouble(json['distance']) ??
          _readDouble(json['Distance']) ??
          _readDouble(json['Distance_In_KM']) ??
          _readDouble(json['Distance_KM']),
      stateId: json['StateID'] as String?,
      cityId: json['CityID'] as String?,
      amenityIds: amenityIds,
      propertyRulesDescription: json['Property_Rules_Description'] as String?,
      floorPlanDocumentId: floorPlanDocument?['DocumentID'] as String?,
      floorPlanDocumentUrl: floorPlanDocument?['Document_URL'] as String?,
      isSubscribed:
          _readBool(json['Whether_Subscribed']) ??
          _readBool(json['Whether_Currently_Subscribed']) ??
          false,
      wasSubscribedAtLeastOnce:
          _readBool(json['Whether_Subscribed_Atleast_Once']) ?? false,
      currentSubscriptionId:
          currentSubscription?['Vendor_SubscriptionID'] as String? ??
          subscriptionData?['SubscriptionID'] as String?,
      currentSubscriptionTitle: subscriptionData?['Title'] as String?,
      currentSubscriptionExpiryDate:
          currentSubscription?['Subscription_Expiry_Date'] as String?,
      totalPurchasedResidentContractsCreationCount:
          _readInt(json['Total_Purchased_Resident_Contracts_Creation_Count']),
      availableResidentContractsCreationCount:
          _readInt(json['Available_Resident_Contracts_Creation_Count']),
      freeResidentContractsCount:
          _readInt(json['Total_Free_Resident_Contracts_Count']),
      usedResidentContractsCount:
          _readInt(json['Used_Resident_Contracts_Creation_Count']),
      totalResidentContractsCount:
          _readInt(json['Total_Resident_Contracts_Creation_Count']),
      carpetArea: (json['Carpet_Area'] as num?)?.toDouble(),
      noOfFloors: json['No_Of_Floors'] as int?,
      gender: json['Gender'] as int?,
      locality: json['Locality'] as String?,
      pincode: json['Pincode'] as String?,
      ownerAddress: json['Owner_Address'] as String?,
      electricityBillType: json['Electricity_Bill_Type'] as int?,
      waterBillType: json['Water_Bill_Type'] as int?,
      gasBillType: json['Gas_Bill_Type'] as int?,
      internetBillType: json['Internet_Bill_Type'] as int?,
      whetherParkingAvailable: _readBool(json['Whether_Parking_Available']),
      parkingType: json['Parking_Type'] as int?,
      parkingSlots: json['Parking_Slots'] as int?,
      parkingCharges: (json['Parking_Charges'] as num?)?.toDouble(),
      metroOrBusStation: json['Metro_Or_Bus_Station'] as String?,
      hospital: json['Hospital'] as String?,
      schoolOrCollege: json['School_Or_College'] as String?,
      shoppingMall: json['Shopping_Mall'] as String?,
      restaurant: json['Restaurant'] as String?,
      atmOrBank: json['ATM_Or_Bank'] as String?,
      preferredTenantType: json['Preferred_Tenant_Type'] as int?,
      petPolicy: json['Pet_Policy'] as int?,
      smokingPolicy: json['Smoking_Policy'] as int?,
      visitorsPolicy: json['Visitors_Policy'] as int?,
      subscriptionExpired: _readBool(json['Subscription_Expired']),
      whetherVerifiedPlus: _readBool(json['Whether_Verified_Plus']),
      totalLeads: json['Total_Leads'] as int?,
      totalUnseenLeads: json['Total_Unseen_Leads'] as int?,
      whetherEnquired: _readBool(json['Whether_Enquired']) ?? false,
      whetherBooked: _readBool(json['Whether_Booked']) ?? false,
      tenantPropertyStatus: json['Tenant_Property_Status'] as String?,
    );
  }

  final String propertyId;
  final String title;
  final String description;
  final int propertyType;
  final int propertyStatus;
  final double rent;
  final double deposit;
  final String? imageUrl;
  final String? locationAddress;
  final String? address;
  final int? bedrooms;
  final int? bathrooms;
  final int? balconies;
  final int? floor;
  final double? area;
  final int? furnishedType;
  final String? facing;
  final String? amenities;
  final int? category;
  final int? subType;
  final int? pgSharingType;
  final String? flatUnitNo;
  final double? maintenance;
  final double? brokerage;
  final String? availableFrom;
  final String? ownerName;
  final String? ownerPhone;
  final String? ownerEmail;
  final String? state;
  final String? city;
  final List<String>? images;
  final List<String>? imageIds;
  final int? noOfVacancy;
  final double? latitude;
  final double? longitude;
  final double? distanceKm;
  final String? stateId;
  final String? cityId;
  final List<int>? amenityIds;
  final String? propertyRulesDescription;
  final String? floorPlanDocumentId;
  final String? floorPlanDocumentUrl;
  final bool isSubscribed;
  final bool wasSubscribedAtLeastOnce;
  final String? currentSubscriptionId;
  final String? currentSubscriptionTitle;
  final String? currentSubscriptionExpiryDate;
  final int? totalPurchasedResidentContractsCreationCount;
  final int? availableResidentContractsCreationCount;
  final int? freeResidentContractsCount;
  final int? usedResidentContractsCount;
  final int? totalResidentContractsCount;
  final double? carpetArea;
  final int? noOfFloors;
  final int? gender;
  final String? locality;
  final String? pincode;
  final String? ownerAddress;
  final int? electricityBillType;
  final int? waterBillType;
  final int? gasBillType;
  final int? internetBillType;
  final bool? whetherParkingAvailable;
  final int? parkingType;
  final int? parkingSlots;
  final double? parkingCharges;
  final String? metroOrBusStation;
  final String? hospital;
  final String? schoolOrCollege;
  final String? shoppingMall;
  final String? restaurant;
  final String? atmOrBank;
  final int? preferredTenantType;
  final int? petPolicy;
  final int? smokingPolicy;
  final int? visitorsPolicy;
  final bool? subscriptionExpired;
  final bool? whetherVerifiedPlus;
  final int? totalLeads;
  final int? totalUnseenLeads;
  final bool whetherEnquired;
  final bool whetherBooked;
  final String? tenantPropertyStatus;

  PropertyRecord toPropertyRecord() {
    return PropertyRecord(
      id: propertyId,
      title: title,
      type: _mapPropertyType(propertyType),
      status: _mapPropertyStatus(propertyStatus),
      rent: rent,
      deposit: deposit,
      imageUrl:
          imageUrl ??
          (images != null && images!.isNotEmpty ? images!.first : null),
      address: address,
      bedrooms: bedrooms,
      bathrooms: bathrooms,
      isSubscribed: isSubscribed,
      subscriptionExpired: subscriptionExpired,
      whetherVerifiedPlus: whetherVerifiedPlus,
      noOfVacancy: noOfVacancy,
    );
  }

  static PropertyStatus _mapPropertyStatus(int status) {
    return switch (status) {
      1 => PropertyStatus.pending,
      2 => PropertyStatus.approved,
      3 => PropertyStatus.rejected,
      4 => PropertyStatus.inactive,
      _ => PropertyStatus.pending,
    };
  }

  static String _mapPropertyType(int type) {
    return switch (type) {
      1 => 'Apartment',
      2 => 'Villa',
      3 => 'PG',
      4 => 'Commercial',
      _ => 'Property',
    };
  }
}

// ---------------------------------------------------------------------------
// Rental Contract
// ---------------------------------------------------------------------------

class ContractDocumentData {
  const ContractDocumentData({
    required this.documentId,
    required this.documentName,
    required this.documentUrl,
  });

  factory ContractDocumentData.fromJson(Map<String, dynamic> json) {
    return ContractDocumentData(
      documentId: json['DocumentID'] as String? ?? '',
      documentName: json['Document_Name'] as String? ?? 'Document',
      documentUrl: json['Document_URL'] as String? ?? '',
    );
  }

  final String documentId;
  final String documentName;
  final String documentUrl;

  ContractDocumentRecord toRecord() {
    return ContractDocumentRecord(
      documentId: documentId,
      documentName: documentName,
      documentUrl: documentUrl,
    );
  }
}

class WhatsAppTemplateData {
  const WhatsAppTemplateData({
    required this.templateId,
    required this.templateName,
    required this.templateCode,
    required this.templateDescription,
    required this.templateVariables,
  });

  factory WhatsAppTemplateData.fromJson(Map<String, dynamic> json) {
    return WhatsAppTemplateData(
      templateId: json['Template_ID'] as int? ?? 0,
      templateName: json['Template_Name'] as String? ?? '',
      templateCode: json['Template_Code'] as String? ?? '',
      templateDescription: json['Template_Description'] as String? ?? '',
      templateVariables:
          ((json['Template_Variables'] as List<dynamic>?) ?? const <dynamic>[])
              .map((dynamic item) => item.toString())
              .toList(),
    );
  }

  final int templateId;
  final String templateName;
  final String templateCode;
  final String templateDescription;
  final List<String> templateVariables;
}

class RentalContractData {
  const RentalContractData({
    required this.contractId,
    required this.tenantName,
    required this.ownerName,
    required this.propertyTitle,
    required this.rent,
    required this.deposit,
    required this.startDate,
    required this.endDate,
    required this.contractStatus,
    this.flatNo,
    this.tenantPhone,
    this.tenantEmail,
    this.ownerPhone,
    this.ownerEmail,
    this.ownerAddress,
    this.tokenAmount,
    this.maintenanceAmount,
    this.billDay,
    this.specialTerms,
    this.propertyId,
    this.tenantStatus,
    this.vacateDate,
    this.tenantIdProof,
    this.tenantAddressProof,
    this.ownerIdProof,
    this.ownerPropertyOwnershipProof,
    this.ownerBankProof,
    this.whetherMaintenanceIncluded,
    this.whetherFirstMonthRentPaid,
    this.whetherSecurityDepositPaid,
  });

  factory RentalContractData.fromJson(Map<String, dynamic> json) {
    final Map<String, dynamic>? propertyData =
        json['Property_Data'] is Map<String, dynamic>
        ? json['Property_Data'] as Map<String, dynamic>
        : null;
    return RentalContractData(
      contractId:
          json['Rental_ContractID'] as String? ?? json['_id'] as String? ?? '',
      tenantName: json['Tenant_Name'] as String? ?? '',
      ownerName: json['Owner_Name'] as String? ?? '',
      propertyTitle:
          json['Property_Title'] as String? ??
          propertyData?['Property_Title'] as String? ??
          json['Title'] as String? ??
          '',
      rent:
          (json['Rent'] as num?)?.toDouble() ??
          (json['Monthly_Rent'] as num?)?.toDouble() ??
          0,
      deposit:
          (json['Deposit'] as num?)?.toDouble() ??
          (json['Security_Deposit'] as num?)?.toDouble() ??
          0,
      startDate:
          DateTime.tryParse(
            json['Contract_Start_Date'] as String? ??
                json['Start_Date'] as String? ??
                '',
          ) ??
          DateTime.now(),
      endDate:
          DateTime.tryParse(
            json['Contract_End_Date'] as String? ??
                json['End_Date'] as String? ??
                '',
          ) ??
          DateTime.now(),
      contractStatus: json['Contract_Status'] as int? ?? 1,
      flatNo: json['Flat_Or_Unit_No'] as String?,
      tenantPhone:
          json['Tenant_PhoneNumber'] as String? ??
          json['Tenant_Phone'] as String?,
      tenantEmail: json['Tenant_EmailID'] as String?,
      ownerPhone:
          json['Owner_PhoneNumber'] as String? ??
          json['Owner_Phone'] as String?,
      ownerEmail: json['Owner_EmailID'] as String?,
      ownerAddress: json['Owner_Address'] as String?,
      tokenAmount: (json['Token_Amount'] as num?)?.toDouble(),
      maintenanceAmount:
          (json['Maintainance_Charge'] as num?)?.toDouble() ??
          (json['Maintenance_Amount'] as num?)?.toDouble(),
      billDay: json['Bill_Day'] as int?,
      specialTerms: json['Special_Terms'] as String?,
      propertyId: json['PropertyID'] as String?,
      tenantStatus: json['Tenant_Status'] as int?,
      vacateDate: DateTime.tryParse(json['Vacate_Date'] as String? ?? ''),
      tenantIdProof: _parseDocument(
        json['Tenant_ID_Proof_Information'] as Map<String, dynamic>?,
      ),
      tenantAddressProof: _parseDocument(
        json['Tenant_Address_Proof_Information'] as Map<String, dynamic>?,
      ),
      ownerIdProof: _parseDocument(
        json['Owner_ID_Proof_Information'] as Map<String, dynamic>?,
      ),
      ownerPropertyOwnershipProof: _parseDocument(
        json['Owner_Property_Ownership_Proof_Information']
            as Map<String, dynamic>?,
      ),
      ownerBankProof: _parseDocument(
        json['Owner_Bank_Proof_Information'] as Map<String, dynamic>?,
      ),
      whetherMaintenanceIncluded:
          json['Whether_Maintainance_Included'] as bool?,
      whetherFirstMonthRentPaid: json['Whether_First_Month_Rent_Paid'] as bool?,
      whetherSecurityDepositPaid: json['Whether_Secrity_Deposit_Paid'] as bool?,
    );
  }

  final String contractId;
  final String tenantName;
  final String ownerName;
  final String propertyTitle;
  final double rent;
  final double deposit;
  final DateTime startDate;
  final DateTime endDate;
  final int contractStatus;
  final String? flatNo;
  final String? tenantPhone;
  final String? tenantEmail;
  final String? ownerPhone;
  final String? ownerEmail;
  final String? ownerAddress;
  final double? tokenAmount;
  final double? maintenanceAmount;
  final int? billDay;
  final String? specialTerms;
  final String? propertyId;
  final int? tenantStatus;
  final DateTime? vacateDate;
  final ContractDocumentData? tenantIdProof;
  final ContractDocumentData? tenantAddressProof;
  final ContractDocumentData? ownerIdProof;
  final ContractDocumentData? ownerPropertyOwnershipProof;
  final ContractDocumentData? ownerBankProof;
  final bool? whetherMaintenanceIncluded;
  final bool? whetherFirstMonthRentPaid;
  final bool? whetherSecurityDepositPaid;

  RentalContractRecord toContractRecord() {
    return RentalContractRecord(
      id: contractId,
      tenantName: tenantName,
      ownerName: ownerName,
      propertyTitle: propertyTitle,
      rent: rent,
      deposit: deposit,
      startDate: startDate,
      endDate: endDate,
      status: _mapContractStatus(contractStatus),
      flatNo: flatNo,
      tenantPhone: tenantPhone,
      tenantEmail: tenantEmail,
      ownerPhone: ownerPhone,
      ownerEmail: ownerEmail,
      ownerAddress: ownerAddress,
      tokenAmount: tokenAmount,
      maintenanceAmount: maintenanceAmount,
      billDay: billDay,
      specialTerms: specialTerms,
      propertyId: propertyId,
      tenantStatus: tenantStatus,
      vacateDate: vacateDate,
      tenantIdProof: tenantIdProof?.toRecord(),
      tenantAddressProof: tenantAddressProof?.toRecord(),
      ownerIdProof: ownerIdProof?.toRecord(),
      ownerPropertyOwnershipProof: ownerPropertyOwnershipProof?.toRecord(),
      ownerBankProof: ownerBankProof?.toRecord(),
      whetherMaintenanceIncluded: whetherMaintenanceIncluded,
      whetherFirstMonthRentPaid: whetherFirstMonthRentPaid,
      whetherSecurityDepositPaid: whetherSecurityDepositPaid,
    );
  }

  static ContractDocumentData? _parseDocument(Map<String, dynamic>? json) {
    if (json == null || (json['Document_URL'] as String? ?? '').isEmpty) {
      return null;
    }
    return ContractDocumentData.fromJson(json);
  }

  static ContractStatus _mapContractStatus(int status) {
    return switch (status) {
      1 => ContractStatus.active,
      2 => ContractStatus.expired,
      3 => ContractStatus.closed,
      4 => ContractStatus.readyToVacate,
      _ => ContractStatus.active,
    };
  }
}

// ---------------------------------------------------------------------------
// Block & Building
// ---------------------------------------------------------------------------

class BlockData {
  const BlockData({
    required this.blockId,
    required this.name,
    required this.societyId,
    this.status = true,
  });

  factory BlockData.fromJson(Map<String, dynamic> json) {
    return BlockData(
      blockId: json['BlockID'] as String? ?? json['_id'] as String? ?? '',
      name: json['Name'] as String? ?? '',
      societyId: json['SocietyID'] as String? ?? '',
      status: json['Status'] as bool? ?? (json['Is_Active'] as bool? ?? true),
    );
  }

  final String blockId;
  final String name;
  final String societyId;
  final bool status;
}

class BuildingData {
  const BuildingData({
    required this.buildingId,
    required this.name,
    required this.societyId,
    this.blockId,
    this.status = true,
  });

  factory BuildingData.fromJson(Map<String, dynamic> json) {
    return BuildingData(
      buildingId: json['BuildingID'] as String? ?? json['_id'] as String? ?? '',
      name: json['Name'] as String? ?? '',
      societyId: json['SocietyID'] as String? ?? '',
      blockId: json['BlockID'] as String?,
      status: json['Status'] as bool? ?? (json['Is_Active'] as bool? ?? true),
    );
  }

  final String buildingId;
  final String name;
  final String societyId;
  final String? blockId;
  final bool status;
}

// ---------------------------------------------------------------------------
// Resident
// ---------------------------------------------------------------------------

class ResidentData {
  const ResidentData({
    required this.residentId,
    required this.societyId,
    required this.name,
    required this.phone,
    required this.flatNo,
    required this.residentType,
    required this.isActive,
    this.email,
    this.flatType,
    this.rent,
    this.blockName,
    this.buildingName,
    this.blockId,
    this.buildingId,
  });

  factory ResidentData.fromJson(Map<String, dynamic> json) {
    final Map<String, dynamic>? blockData =
        json['Block_Data'] is Map<String, dynamic>
        ? json['Block_Data'] as Map<String, dynamic>
        : null;
    final Map<String, dynamic>? buildingData =
        json['Building_Data'] is Map<String, dynamic>
        ? json['Building_Data'] as Map<String, dynamic>
        : null;

    return ResidentData(
      residentId:
          json['Society_ResidentID'] as String? ?? json['_id'] as String? ?? '',
      societyId: json['SocietyID'] as String? ?? '',
      name: json['Full_Name'] as String? ?? json['Name'] as String? ?? '',
      phone: json['Phone'] as String? ?? json['PhoneNumber'] as String? ?? '',
      flatNo:
          json['Flat_No'] as String? ??
          json['Flat_Or_Unit_No'] as String? ??
          '',
      residentType: json['Resident_Type'] as int? ?? 1,
      isActive: json['Is_Active'] as bool? ?? (json['Status'] as bool? ?? true),
      email: json['EmailID'] as String?,
      flatType: json['Flat_Type'] as int?,
      rent: (json['Monthly_Rent'] as num?)?.toDouble(),
      blockName: json['Block_Name'] as String? ?? blockData?['Name'] as String?,
      buildingName:
          json['Building_Name'] as String? ?? buildingData?['Name'] as String?,
      blockId: json['BlockID'] as String?,
      buildingId: json['BuildingID'] as String?,
    );
  }

  final String residentId;
  final String societyId;
  final String name;
  final String phone;
  final String flatNo;
  final int residentType;
  final bool isActive;
  final String? email;
  final int? flatType;
  final double? rent;
  final String? blockName;
  final String? buildingName;
  final String? blockId;
  final String? buildingId;

  ResidentRecord toResidentRecord() {
    return ResidentRecord(
      id: residentId,
      societyId: societyId,
      name: name,
      phone: phone,
      flatNo: flatNo,
      residentType: residentType == 1
          ? ResidentType.owner
          : residentType == 3
          ? ResidentType.pgResident
          : ResidentType.tenant,
      status: isActive,
      email: email,
      flatType: _mapFlatType(flatType),
      rent: rent,
      blockName: blockName,
      buildingName: buildingName,
      blockId: blockId,
      buildingId: buildingId,
    );
  }

  static String? _mapFlatType(int? type) {
    return switch (type) {
      1 => '1 BHK',
      2 => '2 BHK',
      3 => '3 BHK',
      4 => '4 BHK',
      5 => 'Studio',
      6 => 'Duplex',
      7 => 'Penthouse',
      8 => 'Villa',
      _ => null,
    };
  }
}

// ---------------------------------------------------------------------------
// Bank Account
// ---------------------------------------------------------------------------

class BankAccountData {
  const BankAccountData({
    required this.accountId,
    required this.accountType,
    required this.holderName,
    required this.isDefault,
    required this.isActive,
    this.accountNumber,
    this.ifscCode,
    this.upiId,
    this.bankName,
    this.branchName,
    this.isVerified,
    this.createdAt,
  });

  factory BankAccountData.fromJson(Map<String, dynamic> json) {
    final Map<String, dynamic>? ifscDetails =
        json['IFSC_Details'] as Map<String, dynamic>?;

    return BankAccountData(
      accountId:
          json['BankAccountID'] as String? ??
          json['Bank_AccountID'] as String? ??
          json['_id'] as String? ??
          '',
      accountType: json['Account_Type'] as int? ?? 1,
      holderName:
          json['Account_Holder_Name'] as String? ??
          json['Holder_Name'] as String? ??
          '',
      isDefault:
          json['Whether_Default'] as bool? ??
          json['Is_Default'] as bool? ??
          false,
      isActive: json['Status'] as bool? ?? json['Is_Active'] as bool? ?? true,
      accountNumber: json['Account_Number'] as String?,
      ifscCode: json['IFSC_Code'] as String?,
      upiId: json['UPI_ID'] as String?,
      bankName:
          json['Bank_Name'] as String? ?? ifscDetails?['Bank_Name'] as String?,
      branchName:
          json['Branch_Name'] as String? ??
          ifscDetails?['Branch_Name'] as String?,
      isVerified: json['Whether_Verified'] as bool?,
      createdAt: DateTime.tryParse(
        json['createdAt'] as String? ?? json['created_at'] as String? ?? '',
      ),
    );
  }

  final String accountId;
  final int accountType; // 1=bank, 2=upi
  final String holderName;
  final bool isDefault;
  final bool isActive;
  final String? accountNumber;
  final String? ifscCode;
  final String? upiId;
  final String? bankName;
  final String? branchName;
  final bool? isVerified;
  final DateTime? createdAt;

  BankAccountRecord toBankAccountRecord() {
    final String masked = accountNumber != null && accountNumber!.length > 4
        ? '****${accountNumber!.substring(accountNumber!.length - 4)}'
        : accountNumber ?? '';

    return BankAccountRecord(
      id: accountId,
      type: accountType == 2 ? 'upi' : 'bank',
      holderName: holderName,
      isDefault: isDefault,
      status: isActive,
      maskedNumber: masked,
      ifscCode: ifscCode,
      upiId: upiId,
      bankName: bankName,
    );
  }
}

// ---------------------------------------------------------------------------
// Wallet Transaction
// ---------------------------------------------------------------------------

class WalletTransactionData {
  const WalletTransactionData({
    required this.transactionId,
    required this.type,
    required this.amount,
    required this.previousBalance,
    required this.newBalance,
    required this.date,
    this.description,
  });

  factory WalletTransactionData.fromJson(Map<String, dynamic> json) {
    return WalletTransactionData(
      transactionId:
          json['TransactionID'] as String? ?? json['_id'] as String? ?? '',
      type: json['Transaction_Type'] as int? ?? 1,
      amount: (json['Amount'] as num?)?.toDouble() ?? 0,
      previousBalance: (json['Previous_Balance'] as num?)?.toDouble() ?? 0,
      newBalance: (json['New_Balance'] as num?)?.toDouble() ?? 0,
      date:
          DateTime.tryParse(
            json['createdAt'] as String? ?? json['Date'] as String? ?? '',
          ) ??
          DateTime.now(),
      description: json['Description'] as String?,
    );
  }

  final String transactionId;
  final int type; // 1=credit, 2=debit
  final double amount;
  final double previousBalance;
  final double newBalance;
  final DateTime date;
  final String? description;
}

// ---------------------------------------------------------------------------
// Withdrawal
// ---------------------------------------------------------------------------

class WithdrawalData {
  const WithdrawalData({
    required this.withdrawalId,
    required this.amount,
    required this.status,
    required this.date,
    this.previousBalance,
    this.newBalance,
    this.utr,
    this.failureReason,
    this.payoutMode,
    this.bankAccountName,
    this.bankAccountNumber,
    this.bankName,
    this.upiId,
    this.bankAccountType,
  });

  factory WithdrawalData.fromJson(Map<String, dynamic> json) {
    final Map<String, dynamic>? bankAccountDetails =
        json['Bank_Account_Details'] as Map<String, dynamic>?;

    return WithdrawalData(
      withdrawalId:
          json['WithdrawalID'] as String? ?? json['_id'] as String? ?? '',
      amount: (json['Amount'] as num?)?.toDouble() ?? 0,
      status: json['Withdrawal_Status'] as int? ?? 1,
      date:
          DateTime.tryParse(
            json['createdAt'] as String? ?? json['Date'] as String? ?? '',
          ) ??
          DateTime.now(),
      previousBalance: (json['Previous_Balance'] as num?)?.toDouble(),
      newBalance: (json['New_Balance'] as num?)?.toDouble(),
      utr: json['UTR'] as String?,
      failureReason: json['Failure_Reason'] as String?,
      payoutMode: json['Payout_Mode'] as String?,
      bankAccountName:
          json['Bank_Account_Name'] as String? ??
          bankAccountDetails?['Account_Holder_Name'] as String?,
      bankAccountNumber:
          json['Bank_Account_Number'] as String? ??
          bankAccountDetails?['Account_Number'] as String?,
      bankName: bankAccountDetails?['Bank_Name'] as String?,
      upiId: bankAccountDetails?['UPI_ID'] as String?,
      bankAccountType: bankAccountDetails?['Account_Type'] as int?,
    );
  }

  final String withdrawalId;
  final double amount;
  final int status; // 1=pending, 2=success, 3=failed
  final DateTime date;
  final double? previousBalance;
  final double? newBalance;
  final String? utr;
  final String? failureReason;
  final String? payoutMode;
  final String? bankAccountName;
  final String? bankAccountNumber;
  final String? bankName;
  final String? upiId;
  final int? bankAccountType;
}

// ---------------------------------------------------------------------------
// Notification
// ---------------------------------------------------------------------------

class NotificationData {
  const NotificationData({
    required this.notificationId,
    required this.title,
    required this.message,
    required this.type,
    required this.isRead,
    required this.createdAt,
    this.referenceType = '',
    this.referenceId = '',
    this.data = const <String, dynamic>{},
  });

  factory NotificationData.fromJson(Map<String, dynamic> json) {
    final String referenceType = '${json['Reference_Type'] ?? ''}';
    return NotificationData(
      notificationId:
          json['Vendor_NotificationID'] as String? ??
          json['NotificationID'] as String? ??
          json['_id'] as String? ??
          '',
      title: json['Title'] as String? ?? '',
      message: json['Message'] as String? ?? json['Body'] as String? ?? '',
      type: _normalizeNotificationType(
        '${json['Notification_Type'] ?? json['Type'] ?? 'general'}',
        referenceType,
      ),
      isRead:
          json['Whether_Read'] as bool? ?? json['Is_Read'] as bool? ?? false,
      createdAt:
          DateTime.tryParse(
            json['createdAt'] as String? ??
                json['Created_At'] as String? ??
                json['created_at'] as String? ??
                '',
          ) ??
          DateTime.now(),
      referenceType: referenceType,
      referenceId: '${json['Reference_ID'] ?? ''}',
      data: json['Data'] is Map<String, dynamic>
          ? Map<String, dynamic>.from(json['Data'] as Map<String, dynamic>)
          : const <String, dynamic>{},
    );
  }

  final String notificationId;
  final String title;
  final String message;
  final String type;
  final bool isRead;
  final DateTime createdAt;
  final String referenceType;
  final String referenceId;
  final Map<String, dynamic> data;

  NotificationRecord toNotificationRecord() {
    return NotificationRecord(
      id: notificationId,
      title: title,
      message: message,
      type: type,
      isRead: isRead,
      createdAt: createdAt,
    );
  }

  static String _normalizeNotificationType(
    String rawType,
    String referenceType,
  ) {
    final String normalizedReference = referenceType.toLowerCase().trim();
    final String normalizedRaw = rawType.toLowerCase().trim();

    if (normalizedReference.contains('bill')) return 'billing';
    if (normalizedReference.contains('rental_contract')) return 'contract';
    if (normalizedReference.contains('announcement')) return 'announcement';
    if (normalizedReference.contains('support_ticket')) return 'support';
    if (normalizedReference.contains('property_enquiry') ||
        normalizedReference.contains('enquiry') ||
        normalizedReference.contains('lead')) {
      return 'enquiry';
    }

    return switch (normalizedRaw) {
      '1' || '5' => 'billing',
      '2' => 'contract',
      '3' => 'announcement',
      '4' => 'support',
      '6' => 'enquiry',
      '7' => 'system',
      _ => normalizedRaw.isEmpty ? 'general' : normalizedRaw,
    };
  }
}

// ---------------------------------------------------------------------------
// Property Enquiry
// ---------------------------------------------------------------------------

class PropertyEnquiryData {
  const PropertyEnquiryData({
    required this.enquiryId,
    required this.name,
    required this.phone,
    required this.status,
    this.email,
    this.propertyId,
    this.createdAt,
  });

  factory PropertyEnquiryData.fromJson(Map<String, dynamic> json) {
    return PropertyEnquiryData(
      enquiryId:
          json['Property_EnquiryID'] as String? ??
          json['EnquiryID'] as String? ??
          json['_id'] as String? ??
          '',
      name: json['Name'] as String? ?? json['Full_Name'] as String? ?? '',
      phone:
          json['FinalPhoneNumber'] as String? ??
          json['PhoneNumber'] as String? ??
          json['Phone'] as String? ??
          '',
      // Website uses Enquiry_Status (1=New, 2=Resolved); legacy field is Status (bool)
      status:
          json['Enquiry_Status'] as int? ??
          ((json['Status'] as bool?) == true ? 2 : 1),
      email: json['EmailID'] as String?,
      propertyId: json['PropertyID'] as String?,
      createdAt: DateTime.tryParse(
        json['Time'] as String? ?? json['created_at'] as String? ?? '',
      ),
    );
  }

  final String enquiryId;
  final String name;
  final String phone;
  final int status;
  final String? email;
  final String? propertyId;
  final DateTime? createdAt;
}

// ---------------------------------------------------------------------------
// Society
// ---------------------------------------------------------------------------

class SocietyMaintenanceRates {
  const SocietyMaintenanceRates({
    this.oneBhk = 0,
    this.twoBhk = 0,
    this.threeBhk = 0,
    this.fourBhk = 0,
    this.villa = 0,
  });

  factory SocietyMaintenanceRates.fromJson(Map<String, dynamic>? json) {
    return SocietyMaintenanceRates(
      oneBhk: (json?['OneBHK'] as num?)?.toDouble() ?? 0,
      twoBhk: (json?['TwoBHK'] as num?)?.toDouble() ?? 0,
      threeBhk: (json?['ThreeBHK'] as num?)?.toDouble() ?? 0,
      fourBhk: (json?['FourBHK'] as num?)?.toDouble() ?? 0,
      villa: (json?['Villa'] as num?)?.toDouble() ?? 0,
    );
  }

  final double oneBhk;
  final double twoBhk;
  final double threeBhk;
  final double fourBhk;
  final double villa;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'OneBHK': oneBhk,
      'TwoBHK': twoBhk,
      'ThreeBHK': threeBhk,
      'FourBHK': fourBhk,
      'Villa': villa,
    };
  }
}

class SocietyBillingConfig {
  const SocietyBillingConfig({
    this.billGenerationDate = 1,
    this.paymentDueDays = 15,
  });

  factory SocietyBillingConfig.fromJson(Map<String, dynamic>? json) {
    return SocietyBillingConfig(
      billGenerationDate: json?['Bill_Generation_Date'] as int? ?? 1,
      paymentDueDays: json?['Payment_Due_Days'] as int? ?? 15,
    );
  }

  final int billGenerationDate;
  final int paymentDueDays;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'Bill_Generation_Date': billGenerationDate,
      'Payment_Due_Days': paymentDueDays,
    };
  }
}

class SocietyData {
  const SocietyData({
    required this.societyId,
    required this.name,
    required this.address,
    this.countryCode,
    this.phone,
    this.email,
    this.estYear,
    this.latitude,
    this.longitude,
    this.locationAddress,
    this.maintenanceRates = const SocietyMaintenanceRates(),
    this.billingConfig = const SocietyBillingConfig(),
    this.isActive = true,
    this.freeResidentsCount,
    this.purchasedResidentsCount,
    this.totalResidentsCreationCount,
    this.availableResidentsCreationCount,
    this.usedResidentsCreationCount,
    this.purchasedResidentsExpiryDate,
    this.totalResidents,
    this.activeResidents,
    this.walletInfo,
  });

  factory SocietyData.fromJson(Map<String, dynamic> json) {
    return SocietyData(
      societyId: json['SocietyID'] as String? ?? json['_id'] as String? ?? '',
      name: json['Name'] as String? ?? '',
      address: json['Address'] as String? ?? '',
      countryCode: json['CountryCode'] as String?,
      phone: json['PhoneNumber'] as String?,
      email: json['EmailID'] as String?,
      estYear: json['Est_Year']?.toString(),
      latitude: (json['Latitude'] as num?)?.toDouble(),
      longitude: (json['Longitude'] as num?)?.toDouble(),
      locationAddress: json['Location_Address'] as String?,
      maintenanceRates: SocietyMaintenanceRates.fromJson(
        json['Maintenance_Rates'] as Map<String, dynamic>?,
      ),
      billingConfig: SocietyBillingConfig.fromJson(
        json['Billing_Config'] as Map<String, dynamic>?,
      ),
      isActive: json['Status'] as bool? ?? true,
      freeResidentsCount: json['Total_Free_Society_Residents_Count'] as int?,
      purchasedResidentsCount:
          json['Total_Purchased_Residents_Creation_Count'] as int?,
      totalResidentsCreationCount:
          json['Total_Residents_Creation_Count'] as int?,
      availableResidentsCreationCount:
          json['Available_Residents_Creation_Count'] as int?,
      usedResidentsCreationCount: json['Used_Residents_Creation_Count'] as int?,
      purchasedResidentsExpiryDate:
          json['Purchased_Residents_Expiry_Date'] as String?,
      totalResidents: json['Total_Residents'] as int?,
      activeResidents: json['Active_Residents'] as int?,
      walletInfo: json['Wallet_Information'] is Map<String, dynamic>
          ? WalletSummaryData.fromJson(
              json['Wallet_Information'] as Map<String, dynamic>,
            )
          : null,
    );
  }

  final String societyId;
  final String name;
  final String address;
  final String? countryCode;
  final String? phone;
  final String? email;
  final String? estYear;
  final double? latitude;
  final double? longitude;
  final String? locationAddress;
  final SocietyMaintenanceRates maintenanceRates;
  final SocietyBillingConfig billingConfig;
  final bool isActive;
  final int? freeResidentsCount;
  final int? purchasedResidentsCount;
  final int? totalResidentsCreationCount;
  final int? availableResidentsCreationCount;
  final int? usedResidentsCreationCount;
  final String? purchasedResidentsExpiryDate;
  final int? totalResidents;
  final int? activeResidents;
  final WalletSummaryData? walletInfo;
}
