import 'package:flutter/material.dart';

import '../../core/api/support_service.dart';
import '../../core/api/vendor_service.dart';
import '../../core/models/api_models.dart';
import '../../core/models/app_models.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/custom_button.dart';
import '../../core/widgets/custom_card.dart';
import '../../core/widgets/custom_tab_bar.dart';
import '../../core/widgets/page_header.dart';
import '../../core/widgets/tone_badge.dart';

const String _bookingTitlePrefix = 'Booking Request - ';
const String _bookingMarker = 'Request_Type: Amenity_Booking';

class BookingsPage extends StatefulWidget {
  const BookingsPage({super.key});

  @override
  State<BookingsPage> createState() => _BookingsPageState();
}

class _BookingsPageState extends State<BookingsPage> {
  static const int _bookingSupportCategory = 5;

  final TextEditingController _searchController = TextEditingController();
  BookingRequestStatus? _selectedStatus;
  VendorData? _vendor;
  List<_BookingRequest> _requests = <_BookingRequest>[];
  bool _isLoading = true;
  String? _errorMessage;

  static const List<_AmenityInfo> _amenities = <_AmenityInfo>[
    _AmenityInfo('Clubhouse', 'Large gathering or event booking', 'Manual approval'),
    _AmenityInfo('Party Lawn', 'Outdoor celebrations and community events', 'Manual approval'),
    _AmenityInfo('Guest Parking', 'Temporary visitor parking slot requests', 'Managed by security'),
    _AmenityInfo('Service Elevator', 'Move-in, move-out, or vendor access slots', 'Time-window approval'),
  ];

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _bootstrap() async {
    try {
      _vendor = await VendorService.fetchVendorInfo();
    } catch (_) {
      _vendor = null;
    }
    await _loadRequests();
  }

  Future<void> _loadRequests() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final ({List<TicketRecord> tickets, int count}) result =
          await SupportService.filterTenantTickets(limit: 100);
      if (!mounted) {
        return;
      }
      setState(() {
        _requests = result.tickets
            .where((TicketRecord ticket) =>
                ticket.title.startsWith(_bookingTitlePrefix) ||
                ticket.description.contains(_bookingMarker))
            .map(_BookingRequest.fromTicket)
            .toList()
          ..sort((_BookingRequest a, _BookingRequest b) => b.updatedAt.compareTo(a.updatedAt));
        _isLoading = false;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _errorMessage = error.toString().replaceFirst('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final String search = _searchController.text.trim().toLowerCase();
    final List<_BookingRequest> visibleRequests = _requests.where((_BookingRequest item) {
      final bool matchesStatus = _selectedStatus == null || item.status == _selectedStatus;
      final bool matchesSearch = search.isEmpty ||
          item.amenity.toLowerCase().contains(search) ||
          item.purpose.toLowerCase().contains(search) ||
          item.slotLabel.toLowerCase().contains(search) ||
          (item.note ?? '').toLowerCase().contains(search);
      return matchesStatus && matchesSearch;
    }).toList();

    int countFor(BookingRequestStatus status) =>
        _requests.where((_BookingRequest item) => item.status == status).length;

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 16,
        title: const Text('Amenity Bookings'),
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1, thickness: 1, color: AppTheme.border),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openRequestSheet,
        icon: const Icon(Icons.event_available_outlined),
        label: const Text('Request Slot'),
      ),
      body: RefreshIndicator(
        onRefresh: _bootstrap,
        child: ListView(
          padding: AppTheme.pagePadding,
          children: <Widget>[
            const PageHeader(
              title: 'Amenity Bookings',
              description:
                  'The website route is still a placeholder, but mobile now stores booking requests through the live support-ticket API while final approval remains a manual workflow.',
            ),
            const SizedBox(height: 16),
            CustomCard(
              color: AppTheme.primarySoft,
              borderColor: AppTheme.primaryTone,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  const Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: <Widget>[
                      ToneBadge(label: 'Live request storage', tone: UiTone.success),
                      ToneBadge(label: 'Manual approval', tone: UiTone.warning),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Requests are saved as backend support tickets so they remain visible and trackable from mobile.',
                    style: theme.textTheme.bodyMedium?.copyWith(color: AppTheme.textSecondary),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: <Widget>[
                Expanded(child: _metric('Requested', '${countFor(BookingRequestStatus.requested)}', UiTone.warning)),
                const SizedBox(width: 12),
                Expanded(child: _metric('Approved', '${countFor(BookingRequestStatus.approved)}', UiTone.brand)),
                const SizedBox(width: 12),
                Expanded(child: _metric('Completed', '${countFor(BookingRequestStatus.completed)}', UiTone.success)),
              ],
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                labelText: 'Search requests or amenities',
                suffixIcon: IconButton(onPressed: () => setState(() {}), icon: const Icon(Icons.search_rounded)),
              ),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 16),
            CustomTabBar(
              style: CustomTabBarStyle.pill,
              currentIndex: _selectedStatus == null ? 0 : BookingRequestStatus.values.indexOf(_selectedStatus!) + 1,
              onChanged: (int index) {
                setState(() {
                  _selectedStatus = index == 0 ? null : BookingRequestStatus.values[index - 1];
                });
              },
              tabs: <CustomTabItem>[
                const CustomTabItem(label: 'All'),
                ...BookingRequestStatus.values.map((BookingRequestStatus status) => CustomTabItem(label: status.label)),
              ],
            ),
            const SizedBox(height: 16),
            Text('Available Amenities', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 12),
            ..._amenities.map((_AmenityInfo item) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: CustomCard(
                    padding: CustomCardPadding.sm,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Row(
                          children: <Widget>[
                            Expanded(child: Text(item.title, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700))),
                            ToneBadge(label: item.policy, tone: UiTone.brand),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(item.subtitle, style: theme.textTheme.bodyMedium?.copyWith(color: AppTheme.textSecondary)),
                      ],
                    ),
                  ),
                )),
            const SizedBox(height: 8),
            Text('Request History', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 12),
            if (_isLoading)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 32),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_errorMessage != null)
              _message('Unable to load requests', _errorMessage!, UiTone.danger, action: CustomButton(label: 'Retry', icon: const Icon(Icons.refresh_rounded), onPressed: _bootstrap))
            else if ((_vendor?.societyId?.isEmpty ?? true) && (_vendor?.propertyId?.isEmpty ?? true))
              _message('Booking context unavailable', 'This account is not linked to an active society or property context, so booking requests cannot be created yet.', UiTone.warning)
            else if (visibleRequests.isEmpty)
              const CustomCard(padding: CustomCardPadding.sm, child: Text('No booking requests match the current filters.'))
            else
              ...visibleRequests.map((_BookingRequest request) => _requestCard(theme, request)),
          ],
        ),
      ),
    );
  }

  Widget _metric(String label, String value, UiTone tone) {
    return CustomCard(
      padding: CustomCardPadding.sm,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          ToneBadge(label: label, tone: tone, size: ToneBadgeSize.small),
          const SizedBox(height: 14),
          Text(value, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }

  Widget _message(String title, String message, UiTone tone, {Widget? action}) {
    return CustomCard(
      color: AppTheme.toneSoft(tone),
      borderColor: AppTheme.toneColor(tone).withValues(alpha: 0.2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          ToneBadge(label: title, tone: tone),
          const SizedBox(height: 10),
          Text(message, style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppTheme.textSecondary)),
          if (action != null) ...<Widget>[const SizedBox(height: 16), action],
        ],
      ),
    );
  }

  Widget _requestCard(ThemeData theme, _BookingRequest request) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: CustomCard(
        padding: CustomCardPadding.sm,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(request.amenity, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                      const SizedBox(height: 4),
                      Text(request.purpose, style: theme.textTheme.bodyMedium?.copyWith(color: AppTheme.textSecondary)),
                    ],
                  ),
                ),
                ToneBadge(label: request.status.label, tone: request.status.tone),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: <Widget>[
                ToneBadge(label: request.slotLabel, tone: UiTone.neutral),
                ToneBadge(label: request.priority.label, tone: request.priority.tone),
                ToneBadge(label: 'Ticket ${request.ticketId}', tone: UiTone.neutral),
              ],
            ),
            if ((request.note ?? '').isNotEmpty) ...<Widget>[
              const SizedBox(height: 12),
              Text(request.note!, style: theme.textTheme.bodyMedium?.copyWith(color: AppTheme.textSecondary)),
            ],
            const SizedBox(height: 14),
            Row(
              children: <Widget>[
                Expanded(child: CustomButton(label: 'Details', variant: CustomButtonVariant.outline, onPressed: () => _showDetails(request))),
                const SizedBox(width: 10),
                Expanded(child: CustomButton(label: _primaryActionLabel(request.status), onPressed: () => _handlePrimaryAction(request))),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _primaryActionLabel(BookingRequestStatus status) => switch (status) {
        BookingRequestStatus.requested => 'Request Again',
        BookingRequestStatus.approved => 'Request Again',
        BookingRequestStatus.completed => 'Rebook',
        BookingRequestStatus.cancelled => 'Request Again',
      };

  Future<void> _handlePrimaryAction(_BookingRequest request) async {
    await _openRequestSheet(existing: request);
  }

  Future<void> _showDetails(_BookingRequest request) async {
    await showDialog<void>(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: Text(request.amenity),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            _detail('Purpose', request.purpose),
            _detail('Slot', request.slotLabel),
            _detail('Status', request.status.label),
            _detail('Priority', request.priority.label),
            _detail('Updated', '${formatCompactDate(request.updatedAt)} ${formatClock(request.updatedAt)}'),
            _detail('Ticket', request.ticketId),
            if ((request.note ?? '').isNotEmpty) _detail('Notes', request.note!),
          ],
        ),
        actions: <Widget>[TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Close'))],
      ),
    );
  }

  Widget _detail(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          SizedBox(width: 88, child: Text(label, style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppTheme.textSecondary, fontWeight: FontWeight.w600))),
          const SizedBox(width: 12),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  Future<void> _openRequestSheet({_BookingRequest? existing}) async {
    final TextEditingController purposeController = TextEditingController(text: existing?.purpose ?? '');
    final TextEditingController noteController = TextEditingController(text: existing?.note ?? '');
    String selectedAmenity = existing?.amenity ?? _amenities.first.title;
    String selectedSlot = _slotFrom(existing?.slotLabel);
    DateTime selectedDate = existing?.requestedDate ?? DateTime.now().add(const Duration(days: 1));
    int priority = _priorityToApi(existing?.priority ?? TicketPriority.medium);
    int ticketType = (_vendor?.societyId?.isNotEmpty ?? false) ? 1 : 2;
    bool sheetClosed = false;

    final NavigatorState navigator = Navigator.of(context);
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (BuildContext context) {
        bool isSubmitting = false;
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            void safeSetModalState(VoidCallback callback) {
              if (!mounted || sheetClosed) {
                return;
              }
              setModalState(callback);
            }

            Future<void> submit() async {
              final ({int ticketType, String targetId})? target = _resolveTargetContext(ticketType);
              if (purposeController.text.trim().isEmpty || target == null) {
                _showMessage('Purpose and an active society or property context are required.');
                return;
              }
              safeSetModalState(() => isSubmitting = true);
              try {
                await SupportService.createSupportTicket(
                  ticketType: target.ticketType,
                  ticketTypeId: target.targetId,
                  title: '$_bookingTitlePrefix$selectedAmenity',
                  description: _buildDescription(selectedAmenity, '${formatCompactDate(selectedDate)} | $selectedSlot', purposeController.text.trim(), noteController.text.trim()),
                  category: _bookingSupportCategory,
                  priority: priority,
                );
                if (!mounted || sheetClosed) return;
                sheetClosed = true;
                navigator.pop();
                _showMessage('Booking request created successfully.');
                await _loadRequests();
              } catch (error) {
                _showMessage(error.toString().replaceFirst('Exception: ', ''));
                safeSetModalState(() => isSubmitting = false);
              }
            }

            return SafeArea(
              child: Padding(
                padding: EdgeInsets.fromLTRB(16, 12, 16, MediaQuery.of(context).viewInsets.bottom + 24),
                child: ListView(
                  shrinkWrap: true,
                  children: <Widget>[
                    Text(existing == null ? 'Request Amenity Slot' : 'Rebook Amenity Slot', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
                    const SizedBox(height: 16),
                    if ((_vendor?.societyId?.isNotEmpty ?? false) && (_vendor?.propertyId?.isNotEmpty ?? false))
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: DropdownButtonFormField<int>(
                          value: ticketType,
                          decoration: const InputDecoration(labelText: 'Booking context'),
                        items: const <DropdownMenuItem<int>>[
                          DropdownMenuItem<int>(value: 1, child: Text('Society')),
                          DropdownMenuItem<int>(value: 2, child: Text('Property')),
                        ],
                        onChanged: (int? value) => safeSetModalState(() => ticketType = value ?? 1),
                      ),
                    ),
                    DropdownButtonFormField<String>(
                      value: selectedAmenity,
                      decoration: const InputDecoration(labelText: 'Amenity'),
                      items: _amenities.map((_AmenityInfo item) => DropdownMenuItem<String>(value: item.title, child: Text(item.title))).toList(),
                      onChanged: (String? value) => safeSetModalState(() => selectedAmenity = value ?? _amenities.first.title),
                    ),
                    const SizedBox(height: 12),
                    TextField(controller: purposeController, decoration: const InputDecoration(labelText: 'Purpose')),
                    const SizedBox(height: 12),
                    CustomButton(
                      label: formatCompactDate(selectedDate),
                      variant: CustomButtonVariant.outline,
                      icon: const Icon(Icons.calendar_today_outlined),
                      onPressed: () async {
                        final DateTime? picked = await showDatePicker(
                          context: context,
                          initialDate: selectedDate,
                          firstDate: DateTime.now(),
                          lastDate: DateTime.now().add(const Duration(days: 180)),
                        );
                        if (picked != null) {
                          safeSetModalState(() => selectedDate = picked);
                        }
                      },
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: selectedSlot,
                      isExpanded: true,
                      decoration: const InputDecoration(labelText: 'Time Slot'),
                      items: const <DropdownMenuItem<String>>[
                        DropdownMenuItem<String>(value: '9:00 AM to 11:00 AM', child: Text('9:00 AM to 11:00 AM')),
                        DropdownMenuItem<String>(value: '12:00 PM to 2:00 PM', child: Text('12:00 PM to 2:00 PM')),
                        DropdownMenuItem<String>(value: '4:00 PM to 6:00 PM', child: Text('4:00 PM to 6:00 PM')),
                        DropdownMenuItem<String>(value: '6:00 PM to 8:00 PM', child: Text('6:00 PM to 8:00 PM')),
                      ],
                      onChanged: (String? value) => safeSetModalState(() => selectedSlot = value ?? '6:00 PM to 8:00 PM'),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<int>(
                      value: priority,
                      decoration: const InputDecoration(labelText: 'Priority'),
                      items: const <DropdownMenuItem<int>>[
                        DropdownMenuItem<int>(value: 1, child: Text('Low')),
                        DropdownMenuItem<int>(value: 2, child: Text('Medium')),
                        DropdownMenuItem<int>(value: 3, child: Text('High')),
                        DropdownMenuItem<int>(value: 4, child: Text('Urgent')),
                      ],
                      onChanged: (int? value) => safeSetModalState(() => priority = value ?? 2),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: noteController,
                      minLines: 2,
                      maxLines: 4,
                      decoration: const InputDecoration(labelText: 'Notes', hintText: 'Guest count, vendor name, or staff instruction'),
                    ),
                    const SizedBox(height: 20),
                    CustomButton(label: existing == null ? 'Save Request' : 'Create Rebooking', isLoading: isSubmitting, onPressed: isSubmitting ? null : submit),
                  ],
                ),
              ),
            );
          },
        );
      },
    ).whenComplete(() {
      sheetClosed = true;
    });

    purposeController.dispose();
    noteController.dispose();
  }

  ({int ticketType, String targetId})? _resolveTargetContext(int ticketType) {
    if (ticketType == 1 && (_vendor?.societyId?.isNotEmpty ?? false)) {
      return (ticketType: 1, targetId: _vendor!.societyId!);
    }
    if (ticketType == 2 && (_vendor?.propertyId?.isNotEmpty ?? false)) {
      return (ticketType: 2, targetId: _vendor!.propertyId!);
    }
    return null;
  }

  int _priorityToApi(TicketPriority priority) => switch (priority) {
        TicketPriority.low => 1,
        TicketPriority.medium => 2,
        TicketPriority.high => 3,
        TicketPriority.urgent => 4,
      };

  String _buildDescription(String amenity, String slotLabel, String purpose, String note) {
    return <String>[
      _bookingMarker,
      'Amenity: $amenity',
      'Slot: $slotLabel',
      'Purpose: $purpose',
      if (note.trim().isNotEmpty) 'Notes: ${note.trim()}',
      'Workflow: Amenity Booking',
    ].join('\n');
  }

  String _slotFrom(String? slotLabel) => (slotLabel ?? '').contains('|') ? slotLabel!.split('|').last.trim() : '6:00 PM to 8:00 PM';

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }
}

enum BookingRequestStatus { requested, approved, completed, cancelled }

extension on BookingRequestStatus {
  String get label => switch (this) {
        BookingRequestStatus.requested => 'Requested',
        BookingRequestStatus.approved => 'Approved',
        BookingRequestStatus.completed => 'Completed',
        BookingRequestStatus.cancelled => 'Cancelled',
      };

  UiTone get tone => switch (this) {
        BookingRequestStatus.requested => UiTone.warning,
        BookingRequestStatus.approved => UiTone.brand,
        BookingRequestStatus.completed => UiTone.success,
        BookingRequestStatus.cancelled => UiTone.danger,
      };
}

class _AmenityInfo {
  const _AmenityInfo(this.title, this.subtitle, this.policy);
  final String title;
  final String subtitle;
  final String policy;
}

class _BookingRequest {
  const _BookingRequest({
    required this.ticketId,
    required this.amenity,
    required this.purpose,
    required this.slotLabel,
    required this.status,
    required this.priority,
    required this.updatedAt,
    required this.requestedDate,
    this.note,
  });

  factory _BookingRequest.fromTicket(TicketRecord ticket) {
    String? readField(String label) {
      final String prefix = '$label:';
      for (final String line in ticket.description.split('\n')) {
        final String trimmed = line.trim();
        if (trimmed.startsWith(prefix)) {
          return trimmed.substring(prefix.length).trim();
        }
      }
      return null;
    }

    final String slotLabel = readField('Slot') ?? 'Schedule shared in ticket';
    return _BookingRequest(
      ticketId: ticket.id,
      amenity: readField('Amenity') ?? ticket.title.replaceFirst(_bookingTitlePrefix, '').trim(),
      purpose: readField('Purpose') ?? ticket.description,
      slotLabel: slotLabel,
      status: ticket.status.toBookingStatus(),
      priority: ticket.priority,
      updatedAt: ticket.updatedAt,
      requestedDate: _tryParseDate(slotLabel.split('|').first.trim()) ?? ticket.updatedAt,
      note: readField('Notes'),
    );
  }

  final String ticketId;
  final String amenity;
  final String purpose;
  final String slotLabel;
  final BookingRequestStatus status;
  final TicketPriority priority;
  final DateTime updatedAt;
  final DateTime requestedDate;
  final String? note;
}

extension on TicketStatus {
  BookingRequestStatus toBookingStatus() => switch (this) {
        TicketStatus.open => BookingRequestStatus.requested,
        TicketStatus.inProgress => BookingRequestStatus.approved,
        TicketStatus.resolved => BookingRequestStatus.completed,
        TicketStatus.rejected => BookingRequestStatus.cancelled,
      };
}

DateTime? _tryParseDate(String value) {
  final List<String> parts = value.split(' ');
  if (parts.length != 3) {
    return null;
  }
  final int? day = int.tryParse(parts[0]);
  final int? year = int.tryParse(parts[2]);
  final int? month = switch (parts[1].toLowerCase()) {
    'jan' => 1,
    'feb' => 2,
    'mar' => 3,
    'apr' => 4,
    'may' => 5,
    'jun' => 6,
    'jul' => 7,
    'aug' => 8,
    'sep' => 9,
    'oct' => 10,
    'nov' => 11,
    'dec' => 12,
    _ => null,
  };
  if (day == null || month == null || year == null) {
    return null;
  }
  return DateTime(year, month, day);
}
