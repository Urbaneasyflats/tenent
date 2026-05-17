enum NotificationType {
  rentReceived,
  securityDeposit,
  maintenanceAdded,
  maintenanceReceived,
  walletCredited,
  supportTicket,
  supportUpdate,
  announcement,
  securityAlert,
  booking,
  enquiry,
  contract,
  payment,
  system,
  unknown;

  static NotificationType fromString(String value) {
    final String normalized = value.toLowerCase().trim();
    return switch (normalized) {
      'rent_received' || 'rentreceived' || 'rent' => NotificationType.rentReceived,
      'security_deposit' || 'securitydeposit' => NotificationType.securityDeposit,
      'maintenance_added' || 'maintenanceadded' => NotificationType.maintenanceAdded,
      'maintenance_received' || 'maintenancereceived' =>
        NotificationType.maintenanceReceived,
      'wallet_credited' || 'walletcredited' => NotificationType.walletCredited,
      'support_ticket' || 'supportticket' || 'ticket' =>
        NotificationType.supportTicket,
      'support_update' || 'supportupdate' => NotificationType.supportUpdate,
      'announcement' || 'society_notice' || 'notice' =>
        NotificationType.announcement,
      'security_alert' || 'securityalert' => NotificationType.securityAlert,
      'booking' || 'booking_detail' => NotificationType.booking,
      'booking_approved' ||
      'booking_accepted' ||
      'booking_rejected' =>
        NotificationType.booking,
      'enquiry' || 'lead' => NotificationType.enquiry,
      'agreement' || 'contract' || 'rental_contract_detail' =>
        NotificationType.contract,
      'payment' || 'payment_success' || 'payment_failed' || 'rent_due' =>
        NotificationType.payment,
      'system' => NotificationType.system,
      _ => NotificationType.unknown,
    };
  }
}
