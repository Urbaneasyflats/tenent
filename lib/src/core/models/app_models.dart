import 'package:flutter/material.dart';

enum AppRole {
  societyManager,
  propertyManager,
  treasurer,
  president,
  owner,
  tenant,
  pgResident,
  visitor,
  blockSecretary,
}

extension AppRoleX on AppRole {
  String get label {
    return switch (this) {
      AppRole.societyManager => 'Society Manager',
      AppRole.propertyManager => 'Property Manager',
      AppRole.treasurer => 'Treasurer',
      AppRole.president => 'Society President',
      AppRole.owner => 'Owner',
      AppRole.tenant => 'Tenant',
      AppRole.pgResident => 'PG Resident',
      AppRole.visitor => 'Visitor',
      AppRole.blockSecretary => 'Block Secretary',
    };
  }

  String get description {
    return switch (this) {
      AppRole.societyManager =>
        'Run society operations, residents, communication, security, and billing.',
      AppRole.propertyManager =>
        'Manage properties, enquiries, contracts, rent bills, and support.',
      AppRole.treasurer =>
        'Track collections, bills, reminders, and finance operations.',
      AppRole.president =>
        'Manage residents, properties, security, and society operations.',
      AppRole.owner => 'Review property dues, visitors, and support updates.',
      AppRole.tenant =>
        'Use everyday resident services from a mobile-first shell.',
      AppRole.pgResident =>
        'Follow PG rent, visitors, and stay-related updates.',
      AppRole.visitor => 'Track approved visits and reach support quickly.',
      AppRole.blockSecretary =>
        'Monitor block residents, block issues, and security alerts.',
    };
  }

  IconData get icon {
    return switch (this) {
      AppRole.societyManager => Icons.apartment_outlined,
      AppRole.propertyManager => Icons.home_work_outlined,
      AppRole.treasurer => Icons.account_balance_wallet_outlined,
      AppRole.president => Icons.apartment_outlined,
      AppRole.owner => Icons.home_work_outlined,
      AppRole.tenant => Icons.person_outline,
      AppRole.pgResident => Icons.groups_2_outlined,
      AppRole.visitor => Icons.badge_outlined,
      AppRole.blockSecretary => Icons.shield_outlined,
    };
  }

  bool get supportsBilling => this != AppRole.visitor;

  bool get isSocietyScope {
    return switch (this) {
      AppRole.societyManager ||
      AppRole.treasurer ||
      AppRole.president ||
      AppRole.blockSecretary => true,
      _ => false,
    };
  }

  bool get isPropertyScope {
    return switch (this) {
      AppRole.propertyManager || AppRole.owner => true,
      _ => false,
    };
  }

  bool get isResidentScope {
    return switch (this) {
      AppRole.tenant || AppRole.pgResident || AppRole.visitor => true,
      _ => false,
    };
  }

  String get visitorSectionTitle {
    return this == AppRole.visitor ? 'My Visits' : 'Visitors';
  }

  String get billingSectionTitle {
    return switch (this) {
      AppRole.societyManager => 'Society Bills',
      AppRole.propertyManager => 'Rental Bills',
      AppRole.treasurer => 'Billing Overview',
      AppRole.president => 'Society Bills',
      AppRole.owner => 'My Bills',
      AppRole.tenant => 'My Bills',
      AppRole.pgResident => 'My Bills',
      AppRole.visitor => 'No Billing Access',
      AppRole.blockSecretary => 'Block Billing Snapshot',
    };
  }

  String get homeHeadline {
    return switch (this) {
      AppRole.societyManager =>
        'A mobile control center for residents, billing, communication, and security.',
      AppRole.propertyManager =>
        'A mobile workspace for property inventory, contracts, enquiries, and collections.',
      AppRole.treasurer =>
        'Financial control for daily maintenance operations.',
      AppRole.president =>
        'A compact mobile command center for society management.',
      AppRole.owner => 'Your dues, visitors, and updates in one place.',
      AppRole.tenant => 'Resident services simplified for quick mobile use.',
      AppRole.pgResident =>
        'Stay details, rent, and visitors without the web clutter.',
      AppRole.visitor =>
        'Visit readiness, support, and host updates on the go.',
      AppRole.blockSecretary =>
        'Block-level coordination for residents, security, and issues.',
    };
  }
}

enum AuthSource { propertyManagement, society, tenant }

extension AuthSourceX on AuthSource {
  String get label {
    return switch (this) {
      AuthSource.propertyManagement => 'Property Management',
      AuthSource.society => 'Society Management',
      AuthSource.tenant => 'Tenant/Resident',
    };
  }

  String get description {
    return switch (this) {
      AuthSource.propertyManagement =>
        'Sign in to manage properties, enquiries, contracts, and rent billing.',
      AuthSource.society =>
        'Sign in to run society operations, residents, security, and billing.',
      AuthSource.tenant =>
        'Sign in to view your bills, announcements, contracts, and support.',
    };
  }

  IconData get icon {
    return switch (this) {
      AuthSource.propertyManagement => Icons.home_work_outlined,
      AuthSource.society => Icons.apartment_outlined,
      AuthSource.tenant => Icons.person_outline,
    };
  }

  int get vendorType {
    return switch (this) {
      AuthSource.society => 1,
      AuthSource.propertyManagement => 2,
      AuthSource.tenant => 3,
    };
  }
}

AppRole roleFromVendorType(int? vendorType, {AuthSource? fallbackSource}) {
  return switch (vendorType) {
    1 => AppRole.societyManager,
    2 => AppRole.propertyManager,
    3 => AppRole.tenant,
    _ => switch (fallbackSource) {
      AuthSource.propertyManagement => AppRole.propertyManager,
      AuthSource.society => AppRole.societyManager,
      AuthSource.tenant => AppRole.tenant,
      null => AppRole.tenant,
    },
  };
}

enum UiTone { brand, success, warning, danger, neutral }

enum BillStatus { paid, pending, overdue, partial }

extension BillStatusX on BillStatus {
  String get label {
    return switch (this) {
      BillStatus.paid => 'Paid',
      BillStatus.pending => 'Pending',
      BillStatus.overdue => 'Overdue',
      BillStatus.partial => 'Partial',
    };
  }

  UiTone get tone {
    return switch (this) {
      BillStatus.paid => UiTone.success,
      BillStatus.pending => UiTone.warning,
      BillStatus.overdue => UiTone.danger,
      BillStatus.partial => UiTone.brand,
    };
  }
}

enum VisitStatus {
  approved,
  checkedIn,
  checkedOut,
  scheduled,
  waiting,
  denied,
  cancelled,
}

extension VisitStatusX on VisitStatus {
  String get label {
    return switch (this) {
      VisitStatus.approved => 'Approved',
      VisitStatus.checkedIn => 'Checked In',
      VisitStatus.checkedOut => 'Checked Out',
      VisitStatus.scheduled => 'Scheduled',
      VisitStatus.waiting => 'Waiting',
      VisitStatus.denied => 'Denied',
      VisitStatus.cancelled => 'Cancelled',
    };
  }

  UiTone get tone {
    return switch (this) {
      VisitStatus.approved => UiTone.success,
      VisitStatus.checkedIn => UiTone.brand,
      VisitStatus.checkedOut => UiTone.neutral,
      VisitStatus.scheduled => UiTone.warning,
      VisitStatus.waiting => UiTone.warning,
      VisitStatus.denied => UiTone.danger,
      VisitStatus.cancelled => UiTone.danger,
    };
  }
}

enum TicketStatus { open, inProgress, resolved, rejected }

extension TicketStatusX on TicketStatus {
  String get label {
    return switch (this) {
      TicketStatus.open => 'Open',
      TicketStatus.inProgress => 'In Progress',
      TicketStatus.resolved => 'Resolved',
      TicketStatus.rejected => 'Rejected',
    };
  }

  UiTone get tone {
    return switch (this) {
      TicketStatus.open => UiTone.warning,
      TicketStatus.inProgress => UiTone.brand,
      TicketStatus.resolved => UiTone.success,
      TicketStatus.rejected => UiTone.neutral,
    };
  }
}

enum TicketPriority { low, medium, high, urgent }

extension TicketPriorityX on TicketPriority {
  String get label {
    return switch (this) {
      TicketPriority.low => 'Low',
      TicketPriority.medium => 'Medium',
      TicketPriority.high => 'High',
      TicketPriority.urgent => 'Critical',
    };
  }

  UiTone get tone {
    return switch (this) {
      TicketPriority.low => UiTone.success,
      TicketPriority.medium => UiTone.warning,
      TicketPriority.high => UiTone.brand,
      TicketPriority.urgent => UiTone.danger,
    };
  }
}

enum PropertyStatus { pending, approved, rejected, inactive }

extension PropertyStatusX on PropertyStatus {
  String get label {
    return switch (this) {
      PropertyStatus.pending => 'Pending',
      PropertyStatus.approved => 'Approved',
      PropertyStatus.rejected => 'Rejected',
      PropertyStatus.inactive => 'Inactive',
    };
  }

  UiTone get tone {
    return switch (this) {
      PropertyStatus.pending => UiTone.warning,
      PropertyStatus.approved => UiTone.success,
      PropertyStatus.rejected => UiTone.danger,
      PropertyStatus.inactive => UiTone.neutral,
    };
  }
}

enum PropertyType { apartment, villa, pg, commercial }

extension PropertyTypeX on PropertyType {
  String get label {
    return switch (this) {
      PropertyType.apartment => 'Apartment',
      PropertyType.villa => 'Villa',
      PropertyType.pg => 'PG',
      PropertyType.commercial => 'Commercial',
    };
  }
}

enum ContractStatus { active, expired, closed, readyToVacate }

extension ContractStatusX on ContractStatus {
  String get label {
    return switch (this) {
      ContractStatus.active => 'Active',
      ContractStatus.expired => 'Expired',
      ContractStatus.closed => 'Closed',
      ContractStatus.readyToVacate => 'Ready to Vacate',
    };
  }

  UiTone get tone {
    return switch (this) {
      ContractStatus.active => UiTone.success,
      ContractStatus.expired => UiTone.warning,
      ContractStatus.closed => UiTone.neutral,
      ContractStatus.readyToVacate => UiTone.danger,
    };
  }
}

enum ResidentType { owner, tenant, pgResident }

extension ResidentTypeX on ResidentType {
  String get label {
    return switch (this) {
      ResidentType.owner => 'Owner',
      ResidentType.tenant => 'Tenant',
      ResidentType.pgResident => 'PG Resident',
    };
  }

  UiTone get tone {
    return switch (this) {
      ResidentType.owner => UiTone.brand,
      ResidentType.tenant => UiTone.success,
      ResidentType.pgResident => UiTone.warning,
    };
  }
}

enum FlatType { bhk1, bhk2, bhk3, bhk4, studio, duplex, penthouse, villa }

extension FlatTypeX on FlatType {
  String get label {
    return switch (this) {
      FlatType.bhk1 => '1 BHK',
      FlatType.bhk2 => '2 BHK',
      FlatType.bhk3 => '3 BHK',
      FlatType.bhk4 => '4 BHK',
      FlatType.studio => 'Studio',
      FlatType.duplex => 'Duplex',
      FlatType.penthouse => 'Penthouse',
      FlatType.villa => 'Villa',
    };
  }
}

enum TransactionType { credit, debit }

extension TransactionTypeX on TransactionType {
  String get label {
    return switch (this) {
      TransactionType.credit => 'Credit',
      TransactionType.debit => 'Debit',
    };
  }

  UiTone get tone {
    return switch (this) {
      TransactionType.credit => UiTone.success,
      TransactionType.debit => UiTone.danger,
    };
  }
}

enum WithdrawalStatus { pending, processing, completed, failed }

extension WithdrawalStatusX on WithdrawalStatus {
  String get label {
    return switch (this) {
      WithdrawalStatus.pending => 'Pending',
      WithdrawalStatus.processing => 'Processing',
      WithdrawalStatus.completed => 'Completed',
      WithdrawalStatus.failed => 'Failed',
    };
  }

  UiTone get tone {
    return switch (this) {
      WithdrawalStatus.pending => UiTone.warning,
      WithdrawalStatus.processing => UiTone.brand,
      WithdrawalStatus.completed => UiTone.success,
      WithdrawalStatus.failed => UiTone.danger,
    };
  }
}

enum EnquiryStatus { enquiryNew, resolved }

extension EnquiryStatusX on EnquiryStatus {
  String get label {
    return switch (this) {
      EnquiryStatus.enquiryNew => 'New',
      EnquiryStatus.resolved => 'Resolved',
    };
  }

  UiTone get tone {
    return switch (this) {
      EnquiryStatus.enquiryNew => UiTone.warning,
      EnquiryStatus.resolved => UiTone.success,
    };
  }

  int get apiCode {
    return switch (this) {
      EnquiryStatus.enquiryNew => 1,
      EnquiryStatus.resolved => 2,
    };
  }

  static EnquiryStatus fromCode(int code) {
    return switch (code) {
      2 => EnquiryStatus.resolved,
      _ => EnquiryStatus.enquiryNew,
    };
  }
}

enum IncidentStatus { open, investigating, resolved }

extension IncidentStatusX on IncidentStatus {
  String get label {
    return switch (this) {
      IncidentStatus.open => 'Open',
      IncidentStatus.investigating => 'Investigating',
      IncidentStatus.resolved => 'Resolved',
    };
  }

  UiTone get tone {
    return switch (this) {
      IncidentStatus.open => UiTone.warning,
      IncidentStatus.investigating => UiTone.brand,
      IncidentStatus.resolved => UiTone.success,
    };
  }
}

enum IncidentPriority { low, medium, high, critical }

extension IncidentPriorityX on IncidentPriority {
  String get label {
    return switch (this) {
      IncidentPriority.low => 'Low',
      IncidentPriority.medium => 'Medium',
      IncidentPriority.high => 'High',
      IncidentPriority.critical => 'Critical',
    };
  }

  UiTone get tone {
    return switch (this) {
      IncidentPriority.low => UiTone.success,
      IncidentPriority.medium => UiTone.warning,
      IncidentPriority.high => UiTone.danger,
      IncidentPriority.critical => UiTone.danger,
    };
  }
}

enum AnnouncementCategory { maintenance, meeting, social, emergency, financial }

extension AnnouncementCategoryX on AnnouncementCategory {
  String get label {
    return switch (this) {
      AnnouncementCategory.maintenance => 'Maintenance',
      AnnouncementCategory.meeting => 'Meeting',
      AnnouncementCategory.social => 'Social',
      AnnouncementCategory.emergency => 'Emergency',
      AnnouncementCategory.financial => 'Financial',
    };
  }

  IconData get icon {
    return switch (this) {
      AnnouncementCategory.maintenance => Icons.plumbing_outlined,
      AnnouncementCategory.meeting => Icons.event_outlined,
      AnnouncementCategory.social => Icons.celebration_outlined,
      AnnouncementCategory.emergency => Icons.warning_amber_outlined,
      AnnouncementCategory.financial => Icons.receipt_long_outlined,
    };
  }
}

class DashboardMetric {
  const DashboardMetric({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.tone,
  });

  final String title;
  final String value;
  final String subtitle;
  final UiTone tone;
}

class AppShortcut {
  const AppShortcut({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.actionKey,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final String actionKey;
}

class BillRecord {
  const BillRecord({
    required this.id,
    required this.title,
    required this.unitLabel,
    required this.amount,
    required this.dueDate,
    required this.status,
    required this.category,
    this.note,
    this.billTypeCode,
    this.finalAmount,
    this.billDate,
    this.paidDate,
    this.paymentType,
    this.manualOnlinePaymentMode,
    this.paymentNote,
    this.billAmount,
    this.maintenanceAmount,
    this.tokenAmount,
    this.paymentImageUrl,
    this.walletCredited,
    this.walletCreditTime,
    this.walletCreditedTime,
    this.residentName,
    this.residentPhone,
    this.residentEmail,
    this.residentTypeLabel,
    this.societyName,
    this.blockName,
    this.buildingName,
    this.propertyTitle,
    this.ownerName,
    this.ownerPhone,
    this.ownerEmail,
    this.contractStartDate,
    this.contractEndDate,
    this.rentAmount,
    this.depositAmount,
    this.vacateDate,
  });

  final String id;
  final String title;
  final String unitLabel;
  final double amount;
  final DateTime dueDate;
  final BillStatus status;
  final String category;
  final String? note;
  final int? billTypeCode;
  final double? finalAmount;
  final DateTime? billDate;
  final DateTime? paidDate;
  final int? paymentType;
  final int? manualOnlinePaymentMode;
  final String? paymentNote;
  final double? billAmount;
  final double? maintenanceAmount;
  final double? tokenAmount;
  final String? paymentImageUrl;
  final bool? walletCredited;
  final DateTime? walletCreditTime;
  final DateTime? walletCreditedTime;
  final String? residentName;
  final String? residentPhone;
  final String? residentEmail;
  final String? residentTypeLabel;
  final String? societyName;
  final String? blockName;
  final String? buildingName;
  final String? propertyTitle;
  final String? ownerName;
  final String? ownerPhone;
  final String? ownerEmail;
  final DateTime? contractStartDate;
  final DateTime? contractEndDate;
  final double? rentAmount;
  final double? depositAmount;
  final DateTime? vacateDate;
}

class VisitorRecord {
  const VisitorRecord({
    required this.id,
    required this.name,
    required this.host,
    required this.unitLabel,
    required this.purpose,
    required this.time,
    required this.status,
    required this.preApproved,
  });

  final String id;
  final String name;
  final String host;
  final String unitLabel;
  final String purpose;
  final DateTime time;
  final VisitStatus status;
  final bool preApproved;
}

class TicketRecord {
  const TicketRecord({
    required this.id,
    required this.title,
    required this.description,
    required this.status,
    required this.priority,
    required this.category,
    required this.updatedAt,
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

  final String id;
  final String title;
  final String description;
  final TicketStatus status;
  final TicketPriority priority;
  final String category;
  final DateTime updatedAt;
  final String? assignee;
  final DateTime? createdAt;
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
}

class AnnouncementRecord {
  const AnnouncementRecord({
    required this.id,
    required this.title,
    required this.message,
    required this.category,
    required this.createdAt,
    required this.unread,
    required this.priorityLabel,
    this.blockIds = const <String>[],
    this.buildingIds = const <String>[],
    this.blockNames = const <String>[],
    this.buildingNames = const <String>[],
  });

  final String id;
  final String title;
  final String message;
  final AnnouncementCategory category;
  final DateTime createdAt;
  final bool unread;
  final String priorityLabel;
  final List<String> blockIds;
  final List<String> buildingIds;
  final List<String> blockNames;
  final List<String> buildingNames;
}

class ModuleStatusItem {
  const ModuleStatusItem({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.phaseLabel,
    required this.actionKey,
    this.readyNow = false,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final String phaseLabel;
  final String actionKey;
  final bool readyNow;
}

class PropertyRecord {
  const PropertyRecord({
    required this.id,
    required this.title,
    required this.type,
    required this.status,
    required this.rent,
    required this.deposit,
    this.imageUrl,
    this.address,
    this.bedrooms,
    this.bathrooms,
    this.isSubscribed = false,
    this.subscriptionExpired,
    this.whetherVerifiedPlus,
    this.noOfVacancy,
  });

  final String id;
  final String title;
  final String type;
  final PropertyStatus status;
  final double rent;
  final double deposit;
  final String? imageUrl;
  final String? address;
  final int? bedrooms;
  final int? bathrooms;
  final bool isSubscribed;
  final bool? subscriptionExpired;
  final bool? whetherVerifiedPlus;
  final int? noOfVacancy;
}

class RentalContractRecord {
  const RentalContractRecord({
    required this.id,
    required this.tenantName,
    required this.ownerName,
    required this.propertyTitle,
    required this.rent,
    required this.deposit,
    required this.startDate,
    required this.endDate,
    required this.status,
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

  final String id;
  final String tenantName;
  final String ownerName;
  final String propertyTitle;
  final double rent;
  final double deposit;
  final DateTime startDate;
  final DateTime endDate;
  final ContractStatus status;
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
  final ContractDocumentRecord? tenantIdProof;
  final ContractDocumentRecord? tenantAddressProof;
  final ContractDocumentRecord? ownerIdProof;
  final ContractDocumentRecord? ownerPropertyOwnershipProof;
  final ContractDocumentRecord? ownerBankProof;
  final bool? whetherMaintenanceIncluded;
  final bool? whetherFirstMonthRentPaid;
  final bool? whetherSecurityDepositPaid;
}

class ContractDocumentRecord {
  const ContractDocumentRecord({
    required this.documentId,
    required this.documentName,
    required this.documentUrl,
  });

  final String documentId;
  final String documentName;
  final String documentUrl;
}

class ResidentRecord {
  const ResidentRecord({
    required this.id,
    required this.societyId,
    required this.name,
    required this.phone,
    required this.flatNo,
    required this.residentType,
    required this.status,
    this.email,
    this.flatType,
    this.rent,
    this.blockName,
    this.buildingName,
    this.blockId,
    this.buildingId,
  });

  final String id;
  final String societyId;
  final String name;
  final String phone;
  final String flatNo;
  final ResidentType residentType;
  final bool status; // true=active
  final String? email;
  final String? flatType;
  final double? rent;
  final String? blockName;
  final String? buildingName;
  final String? blockId;
  final String? buildingId;
}

class BankAccountRecord {
  const BankAccountRecord({
    required this.id,
    required this.type,
    required this.holderName,
    required this.isDefault,
    required this.status,
    this.maskedNumber,
    this.ifscCode,
    this.upiId,
    this.bankName,
  });

  final String id;
  final String type; // 'bank' or 'upi'
  final String holderName;
  final bool isDefault;
  final bool status;
  final String? maskedNumber;
  final String? ifscCode;
  final String? upiId;
  final String? bankName;
}

class NotificationRecord {
  const NotificationRecord({
    required this.id,
    required this.title,
    required this.message,
    required this.type,
    required this.isRead,
    required this.createdAt,
  });

  final String id;
  final String title;
  final String message;
  final String type;
  final bool isRead;
  final DateTime createdAt;
}

class IncidentRecord {
  const IncidentRecord({
    required this.id,
    required this.title,
    required this.description,
    required this.status,
    required this.priority,
    required this.createdAt,
    required this.isActive,
    this.location,
    this.blockName,
    this.buildingName,
    this.imageUrl,
  });

  final String id;
  final String title;
  final String description;
  final IncidentStatus status;
  final IncidentPriority priority;
  final DateTime createdAt;
  final bool isActive;
  final String? location;
  final String? blockName;
  final String? buildingName;
  final String? imageUrl;
}

String formatCompactDate(DateTime date) {
  final DateTime localDate = date.toLocal();
  const List<String> months = <String>[
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];
  return '${localDate.day} ${months[localDate.month - 1]} ${localDate.year}';
}

String formatClock(DateTime date) {
  final DateTime localDate = date.toLocal();
  final int hour = localDate.hour % 12 == 0 ? 12 : localDate.hour % 12;
  final String minute = localDate.minute.toString().padLeft(2, '0');
  final String suffix = localDate.hour >= 12 ? 'PM' : 'AM';
  return '$hour:$minute $suffix';
}
