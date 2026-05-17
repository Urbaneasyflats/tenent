class ApiConfig {
  ApiConfig._();

  static const String baseUrl = 'https://api.urbaneasyflats.com/vendor';
  static const String userBaseUrl = 'https://api.urbaneasyflats.com/user';

  // Auth
  static const String generateDeviceId = '/Generate_DeviceID';
  static const String splashScreen = '/Splash_Vendor_Screen';
  static const String generateOtp = '/Generate_Vendor_OTP';
  static const String validateOtp = '/Validate_Vendor_OTP';
  static const String updateFcmToken = '/Update_Vendor_FCM_Token';
  static const String clearFcmToken = '/Clear_Vendor_FCM_Token';

  // Vendor
  static const String fetchVendorInfo = '/Fetch_Vendor_Complete_Information';
  static const String setVendorProfile = '/Set_Vendor_Profile';
  static const String requestAccountDeletion = '/Request_Account_Deletion';
  static const String requestAccountUnlock = '/Request_Account_Unlock';

  // Society
  static const String createSociety = '/Create_Society';
  static const String editSociety = '/Edit_Society';
  static const String fetchSocietyInfo =
      '/Fetch_Vendor_Society_Complete_Information';
  static const String filterResidents = '/Filter_All_Society_Residents';

  // Billing
  static const String filterTenantBills = '/Filter_All_Bills_WRT_Tenant';
  static const String filterResidentBills =
      '/Filter_All_Society_Residents_Bills';
  static const String filterPropertyContractBills =
      '/Filter_All_Property_Contract_Bills';
  static const String fetchBillInfo = '/Fetch_Bill_Complete_Information';
  static const String collectBillAmount = '/Collect_Bill_Amount';

  // Support
  static const String createSupportTicket = '/Create_Support_Ticket';
  static const String filterTenantTickets =
      '/Filter_All_Support_Ticket_WRT_Tenant';
  static const String filterSocietyTickets =
      '/Filter_All_Support_Ticket_WRT_Society';
  static const String filterPropertyTickets =
      '/Filter_All_Support_Ticket_WRT_Property';
  static const String updateTicketStatus = '/Upate_Support_Ticket_Status';

  // Announcements
  static const String filterTenantAnnouncements =
      '/Filter_All_Announcements_WRT_Tenant';
  static const String filterSocietyAnnouncements =
      '/Filter_All_Society_Announcements_WRT_Society';
  static const String createAnnouncement = '/Create_Society_Announcement';
  static const String editAnnouncement = '/Edit_Society_Announcement';

  // Incidents
  static const String filterTenantIncidents =
      '/Filter_All_Society_Incidents_WRT_Tenant';
  static const String filterSocietyIncidents =
      '/Filter_All_Society_Incidents_WRT_Society';
  static const String createIncident = '/Create_Society_Incident';
  static const String editIncident = '/Edit_Society_Incident';
  static const String activeIncident = '/Active_Society_Incident';
  static const String inactiveIncident = '/Inactive_Society_Incident';
  static const String updateIncidentStatus = '/Update_Society_Incident_Status';

  // Property
  static const String createProperty = '/Create_Property';
  static const String editProperty = '/Edit_Property';
  static const String activeProperty = '/Active_Property';
  static const String inactiveProperty = '/Inactive_Property';
  static const String filterAllProperties = '/Filter_All_Properties';
  static const String filterAllPropertiesLite = '/Filter_All_Properties_Lite';
  static const String fetchPropertyInfo =
      '/Fetch_Property_Complete_Information';
  static const String addPropertyWishlist = '/Add_Property_Wishlist';
  static const String removePropertyWishlist = '/Remove_Property_Wishlist';
  static const String filterWishlistProperties =
      '/Filter_All_Wishlist_Properties';
  static const String filterPropertyEnquiries =
      '/Filter_All_Property_Enquiries';
  static const String createAuthenticatedPropertyEnquiry =
      '/Create_Authenticated_Property_Enquiry';
  static const String updateEnquiryStatus = '/Update_Enquiry_Status';

  // Property bookings
  static const String createPropertyBookingOrder =
      '/Create_Property_Booking_Order';
  static const String verifyPropertyBookingPayment =
      '/Verify_Property_Booking_Payment';
  static const String filterTenantPropertyBookings =
      '/Filter_Tenant_Property_Bookings';
  static const String filterManagerPropertyBookings =
      '/Filter_Manager_Property_Bookings';
  static const String fetchPropertyBookingDetails =
      '/Fetch_Property_Booking_Details';
  static const String managerAcceptPropertyBooking =
      '/Manager_Accept_Property_Booking';
  static const String managerRejectPropertyBooking =
      '/Manager_Reject_Property_Booking';

  // Public user property discovery
  static const String userFilterAllProperties = '/Filter_All_Properties';
  static const String userGenerateOtp = '/Generate_User_OTP';
  static const String userCreatePropertyEnquiry = '/Create_Property_Enquiry';
  static const String userFilterAllCities = '/Filter_All_Cities';

  // Rental Contracts
  static const String createRentalContract = '/Create_Property_Rental_Contract';
  static const String editRentalContract = '/Edit_Property_Rental_Contract';
  static const String activeRentalContract = '/Active_Property_Rental_Contract';
  static const String inactiveRentalContract =
      '/Inactive_Property_Rental_Contract';
  static const String filterAllRentalContracts =
      '/Filter_All_Property_Rental_Contracts';
  static const String filterRentalContractsForProperty =
      '/Filter_All_Property_Rental_Contracts_WRT_Property';
  static const String updateRentalContractReadyToVacate =
      '/Update_Rental_Contract_Ready_To_Vacate';
  static const String updateRentalContractTenantDocuments =
      '/Update_Rental_Contract_Tenant_Documents';
  static const String closeRentalContract = '/Close_Rental_Contract';
  static const String createRentalContractSecurityDepositBill =
      '/Create_Property_Rental_Contract_Security_Deposit_Bill';
  static const String createRentalContractFirstMonthBill =
      '/Create_Property_Rental_Contract_First_Month_Bill';
  static const String filterRentalContractWhatsAppTemplates =
      '/Filter_All_Rental_Contract_WhatsApp_Templates';
  static const String sendRentalContractWhatsAppTemplate =
      '/Send_Rental_Contract_WhatsApp_Template';
  static const String calculatePropertyResidentContracts =
      '/Calculate_Property_Resident_Contracts';
  static const String purchasePropertyResidentContracts =
      '/Purchase_Property_Resident_Contracts';

  // Blocks & Buildings
  static const String createBlock = '/Create_Block';
  static const String editBlock = '/Edit_Block';
  static const String activeBlock = '/Active_Block';
  static const String inactiveBlock = '/Inactive_Block';
  static const String filterAllBlocks = '/Filter_All_Blocks';
  static const String createBuilding = '/Create_Building';
  static const String editBuilding = '/Edit_Building';
  static const String activeBuilding = '/Active_Building';
  static const String inactiveBuilding = '/Inactive_Building';
  static const String filterAllBuildings = '/Filter_All_Buildings';

  // Residents (expanded)
  static const String createResident = '/Create_Society_Resident';
  static const String editResident = '/Edit_Society_Resident';
  static const String activeResident = '/Active_Society_Resident';
  static const String inactiveResident = '/Inactive_Society_Resident';
  static const String calculateResidents = '/Calculate_Society_Residents';
  static const String purchaseResidents = '/Purchase_Society_Residents';
  static const String calculateResidentsRenewal =
      '/Calculate_Society_Residents_Renewal';
  static const String renewResidents = '/Renew_Society_Residents';

  // Wallet & Bank
  static const String filterBankAccounts = '/Filter_All_Vendor_Bank_Accounts';
  static const String createBankAccount = '/Create_Vendor_Bank_Account';
  static const String editBankAccount = '/Edit_Vendor_Bank_Account';
  static const String activeBankAccount = '/Active_Vendor_Bank_Account';
  static const String inactiveBankAccount = '/Inactive_Vendor_Bank_Account';
  static const String validateIfsc = '/Validate_IFSC';
  static const String validateUpi = '/Validate_UPI';
  static const String filterWalletTransactions =
      '/Filter_All_Wallet_Transactions';
  static const String filterWalletWithdrawals =
      '/Filter_All_Wallet_Withdrawals';
  static const String withdrawWalletAmount = '/Withdraw_Wallet_Amount';

  // Notifications
  static const String filterNotifications = '/Filter_All_Vendor_Notifications';
  static const String markNotificationAsRead =
      '/Mark_Vendor_Notification_As_Read';
  static const String markAllNotificationsAsRead =
      '/Mark_All_Vendor_Notifications_As_Read';

  // Subscriptions
  static const String filterSubscriptions = '/Filter_All_Subscriptions';
  static const String calculateSubscription =
      '/Calculate_Property_Subscription';
  static const String purchaseSubscription = '/Purchase_Property_Subscription';

  // Bill generation
  static const String generateSocietyBills = '/Generate_Society_Resident_Bills';
  static const String generatePropertyBills =
      '/Generate_Property_Rental_Contract_Bills';
  static const String collectBillManualOnline =
      '/Collect_Bill_Amount_Manual_Online';
  static const String sendBillWhatsAppReminder = '/Send_Bill_WhatsApp_Reminder';

  // Common
  static const String fetchAppCommonSettings = '/Fetch_App_Common_Settings';
  static const String filterAllStates = '/Filter_All_States';
  static const String filterAllCities = '/Filter_All_Cities';

  // Upload (separate base URL)
  static const String uploadBaseUrl = 'https://api.urbaneasyflats.com/upload';
  static const String uploadImage = '/Upload_Image';
  static const String fetchImageInfo = '/Fetch_Image_Complete_Information';
  static const String removeImage = '/Remove_Image';
  static const String uploadVideo = '/Upload_Video';
  static const String fetchVideoInfo = '/Fetch_Video_Complete_Information';
  static const String removeVideo = '/Remove_Video';
  static const String uploadAudio = '/Upload_Audio';
  static const String fetchAudioInfo = '/Fetch_Audio_Complete_Information';
  static const String removeAudio = '/Remove_Audio';
  static const String uploadDocument = '/Upload_Document';
  static const String fetchDocumentInfo =
      '/Fetch_Document_Complete_Information';
  static const String removeDocument = '/Remove_Document';
}
