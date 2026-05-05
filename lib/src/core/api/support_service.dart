import '../models/api_models.dart';
import '../models/app_models.dart';
import 'api_client.dart';
import 'api_config.dart';

class SupportService {
  SupportService._();

  /// Create a new support ticket.
  static Future<ApiResponse> createSupportTicket({
    required int ticketType,
    required String ticketTypeId,
    required String title,
    required String description,
    required int category,
    required int priority,
    String? imageId,
  }) async {
    return ApiClient.instance.post(
      ApiConfig.createSupportTicket,
      <String, dynamic>{
        'Vendor_Ticket_Type': ticketType,
        'Vendor_Ticket_TypeID': ticketTypeId,
        'Title': title,
        'Description': description,
        'Category': category,
        'Priority': priority,
        'Whether_Image_Available': imageId != null,
        if (imageId != null) 'ImageID': imageId,
      },
    );
  }

  /// Filter support tickets for tenant.
  static Future<({List<TicketRecord> tickets, int count})>
      filterTenantTickets({
    int skip = 0,
    int limit = 50,
    int? category,
    int? priority,
    int? ticketStatus,
    String? search,
  }) async {
    final ApiResponse response = await ApiClient.instance.post(
      ApiConfig.filterTenantTickets,
      <String, dynamic>{
        'Skip': skip,
        'Limit': limit,
        'Whether_Category_Filter': category != null,
        if (category != null) 'Category': category,
        'Whether_Priority_Filter': priority != null,
        if (priority != null) 'Priority': priority,
        'Whether_Ticket_Status_Filter': ticketStatus != null,
        if (ticketStatus != null) 'Ticket_Status': ticketStatus,
        'Whether_Search_Filter': search != null && search.isNotEmpty,
        if (search != null) 'Search': search,
      },
    );

    return _parseTicketResponse(response);
  }

  /// Filter support tickets for a society.
  static Future<({List<TicketRecord> tickets, int count})>
      filterSocietyTickets({
    required String societyId,
    int skip = 0,
    int limit = 50,
    int? category,
    int? priority,
    int? ticketStatus,
    String? search,
  }) async {
    final ApiResponse response = await ApiClient.instance.post(
      ApiConfig.filterSocietyTickets,
      <String, dynamic>{
        'SocietyID': societyId,
        'Skip': skip,
        'Limit': limit,
        'Whether_Category_Filter': category != null,
        if (category != null) 'Category': category,
        'Whether_Priority_Filter': priority != null,
        if (priority != null) 'Priority': priority,
        'Whether_Ticket_Status_Filter': ticketStatus != null,
        if (ticketStatus != null) 'Ticket_Status': ticketStatus,
        'Whether_Search_Filter': search != null && search.isNotEmpty,
        if (search != null) 'Search': search,
      },
    );

    return _parseTicketResponse(response);
  }

  /// Filter support tickets for property scope.
  static Future<({List<TicketRecord> tickets, int count})>
      filterPropertyTickets({
    int skip = 0,
    int limit = 50,
    int? category,
    int? priority,
    int? ticketStatus,
    String? search,
  }) async {
    final ApiResponse response = await ApiClient.instance.post(
      ApiConfig.filterPropertyTickets,
      <String, dynamic>{
        'Skip': skip,
        'Limit': limit,
        'Whether_Category_Filter': category != null,
        if (category != null) 'Category': category,
        'Whether_Priority_Filter': priority != null,
        if (priority != null) 'Priority': priority,
        'Whether_Ticket_Status_Filter': ticketStatus != null,
        if (ticketStatus != null) 'Ticket_Status': ticketStatus,
        'Whether_Search_Filter': search != null && search.isNotEmpty,
        if (search != null) 'Search': search,
      },
    );

    return _parseTicketResponse(response);
  }

  /// Update ticket status.
  static Future<ApiResponse> updateTicketStatus({
    required String ticketId,
    required int status,
  }) async {
    return ApiClient.instance.post(
      ApiConfig.updateTicketStatus,
      <String, dynamic>{
        'Support_TicketID': ticketId,
        'Ticket_Status': status,
      },
    );
  }

  static ({List<TicketRecord> tickets, int count}) _parseTicketResponse(
    ApiResponse response,
  ) {
    if (!response.success || response.data == null) {
      return (tickets: <TicketRecord>[], count: 0);
    }

    final List<dynamic> dataList = response.data as List<dynamic>;
    final List<TicketRecord> tickets = dataList
        .map((dynamic item) =>
            SupportTicketData.fromJson(item as Map<String, dynamic>)
                .toTicketRecord())
        .toList();

    return (tickets: tickets, count: response.count ?? tickets.length);
  }
}
