import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/api/property_service.dart';
import '../../core/models/api_models.dart';
import '../../core/models/app_models.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/custom_button.dart';
import '../../core/widgets/custom_card.dart';
import '../../core/widgets/page_header.dart';
import '../../core/widgets/tone_badge.dart';

class PropertyEnquiriesPage extends StatefulWidget {
  const PropertyEnquiriesPage({super.key});

  @override
  State<PropertyEnquiriesPage> createState() => _PropertyEnquiriesPageState();
}

class _PropertyEnquiriesPageState extends State<PropertyEnquiriesPage> {
  final TextEditingController _searchController = TextEditingController();
  Timer? _searchDebounce;

  bool _isLoadingProperties = true;
  bool _isLoadingEnquiries = false;
  String? _errorMessage;

  String? _selectedPropertyId;
  List<PropertyRecord> _properties = <PropertyRecord>[];

  List<PropertyEnquiryData> _enquiries = <PropertyEnquiryData>[];
  int _totalCount = 0;
  int _newCount = 0;
  int _resolvedCount = 0;

  // Filters
  int? _statusFilter;     // null=All, 1=New, 2=Resolved
  DateTime? _startDate;
  DateTime? _endDate;

  // Pagination
  static const int _pageSize = 20;
  int _skip = 0;
  bool _hasMore = false;

  @override
  void initState() {
    super.initState();
    _loadProperties();
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // Data loading
  // ---------------------------------------------------------------------------
  Future<void> _loadProperties() async {
    setState(() {
      _isLoadingProperties = true;
      _errorMessage = null;
    });
    try {
      final result = await PropertyService.filterPropertiesLite(limit: 200);
      if (!mounted) {
        return;
      }
      final List<Map<String, dynamic>> lite = result.properties;
      final List<PropertyRecord> props = lite.map((Map<String, dynamic> m) {
        return PropertyRecord(
          id: m['PropertyID'] as String? ?? '',
          title: m['Property_Title'] as String? ?? 'Untitled',
          type: '',
          status: PropertyStatus.approved,
          rent: 0,
          deposit: 0,
        );
      }).toList();

      setState(() {
        _properties = props;
        _isLoadingProperties = false;
        if (_selectedPropertyId == null && props.isNotEmpty) {
          _selectedPropertyId = props.first.id;
        }
      });
      if (_selectedPropertyId != null) {
        await _loadEnquiries(reset: true);
      }
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _errorMessage = error.toString().replaceFirst('Exception: ', '');
        _isLoadingProperties = false;
      });
    }
  }

  Future<void> _loadEnquiries({bool reset = false}) async {
    if (_selectedPropertyId == null) {
      return;
    }
    if (!mounted) {
      return;
    }
    final int skip = reset ? 0 : _skip;
    setState(() {
      _isLoadingEnquiries = true;
      if (reset) {
        _errorMessage = null;
      }
    });

    try {
      final result = await PropertyService.filterPropertyEnquiries(
        _selectedPropertyId!,
        skip: skip,
        limit: _pageSize,
        search: _searchController.text.trim().isEmpty
            ? null
            : _searchController.text.trim(),
        enquiryStatus: _statusFilter,
        startDate: _startDate,
        endDate: _endDate,
      );
      if (!mounted) {
        return;
      }
      setState(() {
        if (reset) {
          _enquiries = result.enquiries;
        } else {
          _enquiries = <PropertyEnquiryData>[..._enquiries, ...result.enquiries];
        }
        _totalCount = result.count;
        _newCount = result.newCount;
        _resolvedCount = result.resolvedCount;
        _skip = skip + result.enquiries.length;
        _hasMore = (_skip) < result.count;
        _isLoadingEnquiries = false;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _errorMessage = error.toString().replaceFirst('Exception: ', '');
        _isLoadingEnquiries = false;
      });
    }
  }

  void _onSearchChanged(String value) {
    setState(() {});
    _searchDebounce?.cancel();
    _searchDebounce = Timer(
      const Duration(milliseconds: 400),
      () => _loadEnquiries(reset: true),
    );
  }

  void _clearFilters() {
    _searchController.clear();
    setState(() {
      _statusFilter = null;
      _startDate = null;
      _endDate = null;
    });
    _loadEnquiries(reset: true);
  }

  bool get _hasActiveFilters =>
      _searchController.text.isNotEmpty ||
      _statusFilter != null ||
      _startDate != null ||
      _endDate != null;

  // ---------------------------------------------------------------------------
  // Date picker helpers
  // ---------------------------------------------------------------------------
  Future<void> _pickStartDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _startDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        _startDate = picked;
        // Reset end date if it's before start
        if (_endDate != null && _endDate!.isBefore(picked)) {
          _endDate = null;
        }
      });
      if (_endDate != null) {
        _loadEnquiries(reset: true);
      }
    }
  }

  Future<void> _pickEndDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _endDate ?? (_startDate ?? DateTime.now()),
      firstDate: _startDate ?? DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        _endDate = picked;
      });
      if (_startDate != null) {
        _loadEnquiries(reset: true);
      }
    }
  }

  // ---------------------------------------------------------------------------
  // Actions
  // ---------------------------------------------------------------------------
  Future<void> _resolveEnquiry(PropertyEnquiryData enquiry) async {
    try {
      await PropertyService.updateEnquiryStatus(enquiry.enquiryId, 2);
      _showMessage('Enquiry marked as resolved.');
      await _loadEnquiries(reset: true);
    } catch (error) {
      _showMessage(error.toString().replaceFirst('Exception: ', ''));
    }
  }

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 16,
        title: const Text('Property Enquiries'),
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1, thickness: 1, color: AppTheme.border),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: () => _loadEnquiries(reset: true),
        child: ListView(
          padding: AppTheme.pagePadding,
          children: <Widget>[
            const PageHeader(
              title: 'Enquiries',
              description:
                  'Lead queue and follow-up status updates for property listings.',
            ),
            const SizedBox(height: 16),

            // ── Property selector ──────────────────────────────────────────
            if (_isLoadingProperties)
              const Center(child: CircularProgressIndicator())
            else if (_properties.isEmpty)
              const CustomCard(
                child: Text(
                  'Create a property first to start receiving enquiries.',
                ),
              )
            else ...<Widget>[
              DropdownButtonFormField<String>(
                value: _selectedPropertyId,
                isExpanded: true,
                decoration: const InputDecoration(labelText: 'Property'),
                items: _properties.map((PropertyRecord p) {
                  return DropdownMenuItem<String>(
                    value: p.id,
                    child: Text(p.title, overflow: TextOverflow.ellipsis),
                  );
                }).toList(),
                onChanged: (String? value) {
                  setState(() {
                    _selectedPropertyId = value;
                    _enquiries = <PropertyEnquiryData>[];
                    _skip = 0;
                  });
                  _loadEnquiries(reset: true);
                },
              ),
              const SizedBox(height: 12),

              // ── Summary bar ──────────────────────────────────────────────
              if (!_isLoadingEnquiries || _enquiries.isNotEmpty)
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: <Widget>[
                      _SummaryTile(
                        label: 'Total',
                        count: _totalCount,
                        tone: UiTone.brand,
                      ),
                      const SizedBox(width: 12),
                      _SummaryTile(
                        label: 'New',
                        count: _newCount,
                        tone: UiTone.warning,
                      ),
                      const SizedBox(width: 12),
                      _SummaryTile(
                        label: 'Resolved',
                        count: _resolvedCount,
                        tone: UiTone.success,
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 16),

              // ── Search ───────────────────────────────────────────────────
              TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  labelText: 'Search',
                  hintText: 'Name, email or phone…',
                  prefixIcon: const Icon(Icons.search_rounded),
                  suffixIcon: _searchController.text.isEmpty
                      ? null
                      : IconButton(
                          onPressed: () {
                            _searchController.clear();
                            _loadEnquiries(reset: true);
                          },
                          icon: const Icon(Icons.close_rounded),
                        ),
                ),
                onChanged: _onSearchChanged,
                onSubmitted: (_) => _loadEnquiries(reset: true),
              ),
              const SizedBox(height: 12),

              // ── Status filter ────────────────────────────────────────────
              DropdownButtonFormField<int?>(
                value: _statusFilter,
                decoration: const InputDecoration(labelText: 'Status'),
                items: const <DropdownMenuItem<int?>>[
                  DropdownMenuItem<int?>(
                    value: null,
                    child: Text('All Status'),
                  ),
                  DropdownMenuItem<int?>(
                    value: 1,
                    child: Text('New'),
                  ),
                  DropdownMenuItem<int?>(
                    value: 2,
                    child: Text('Resolved'),
                  ),
                ],
                onChanged: (int? value) {
                  setState(() {
                    _statusFilter = value;
                  });
                  _loadEnquiries(reset: true);
                },
              ),
              const SizedBox(height: 12),

              // ── Date range ───────────────────────────────────────────────
              Row(
                children: <Widget>[
                  Expanded(
                    child: GestureDetector(
                      onTap: _pickStartDate,
                      child: AbsorbPointer(
                        child: TextField(
                          readOnly: true,
                          decoration: InputDecoration(
                            labelText: 'From',
                            hintText: 'Start date',
                            prefixIcon:
                                const Icon(Icons.calendar_today_outlined),
                            suffixIcon: _startDate != null
                                ? IconButton(
                                    icon: const Icon(Icons.close_rounded),
                                    onPressed: () {
                                      setState(() {
                                        _startDate = null;
                                      });
                                      _loadEnquiries(reset: true);
                                    },
                                  )
                                : null,
                          ),
                          controller: TextEditingController(
                            text: _startDate == null
                                ? ''
                                : _formatDate(_startDate!),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: GestureDetector(
                      onTap: _pickEndDate,
                      child: AbsorbPointer(
                        child: TextField(
                          readOnly: true,
                          decoration: InputDecoration(
                            labelText: 'To',
                            hintText: 'End date',
                            prefixIcon:
                                const Icon(Icons.calendar_today_outlined),
                            suffixIcon: _endDate != null
                                ? IconButton(
                                    icon: const Icon(Icons.close_rounded),
                                    onPressed: () {
                                      setState(() {
                                        _endDate = null;
                                      });
                                      _loadEnquiries(reset: true);
                                    },
                                  )
                                : null,
                          ),
                          controller: TextEditingController(
                            text: _endDate == null
                                ? ''
                                : _formatDate(_endDate!),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              // ── Clear filters ────────────────────────────────────────────
              if (_hasActiveFilters) ...<Widget>[
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton.icon(
                    onPressed: _clearFilters,
                    icon: const Icon(Icons.filter_alt_off_outlined, size: 18),
                    label: const Text('Clear Filters'),
                  ),
                ),
              ],
              const SizedBox(height: 16),

              // ── Error ────────────────────────────────────────────────────
              if (_errorMessage != null && _enquiries.isEmpty)
                CustomCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        'Unable to load enquiries',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _errorMessage!,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: AppTheme.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 16),
                      CustomButton(
                        label: 'Retry',
                        icon: const Icon(Icons.refresh_rounded),
                        onPressed: () => _loadEnquiries(reset: true),
                      ),
                    ],
                  ),
                ),

              // ── Loading (initial) ────────────────────────────────────────
              if (_isLoadingEnquiries && _enquiries.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 48),
                  child: Center(child: CircularProgressIndicator()),
                ),

              // ── Empty ────────────────────────────────────────────────────
              if (!_isLoadingEnquiries &&
                  _errorMessage == null &&
                  _enquiries.isEmpty)
                CustomCard(
                  child: Text(
                    _hasActiveFilters
                        ? 'No enquiries match the current filters.'
                        : 'No enquiries found for this property.',
                  ),
                ),

              // ── Enquiry cards ────────────────────────────────────────────
              ..._enquiries.map((PropertyEnquiryData enquiry) {
                final bool isNew = enquiry.status == 1;
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
                                  Text(
                                    enquiry.name,
                                    style: theme.textTheme.titleMedium
                                        ?.copyWith(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  if (enquiry.createdAt != null) ...<Widget>[
                                    const SizedBox(height: 4),
                                    Text(
                                      'Received: ${_formatDateTime(enquiry.createdAt!)}',
                                      style: theme.textTheme.bodySmall
                                          ?.copyWith(
                                        color: AppTheme.textMuted,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                            ToneBadge(
                              label: isNew ? 'New' : 'Resolved',
                              tone: isNew ? UiTone.warning : UiTone.success,
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: <Widget>[
                            if (enquiry.phone.isNotEmpty)
                              ToneBadge(
                                label: enquiry.phone,
                                tone: UiTone.neutral,
                              ),
                            if ((enquiry.email ?? '').isNotEmpty)
                              ToneBadge(
                                label: enquiry.email!,
                                tone: UiTone.neutral,
                              ),
                          ],
                        ),
                        if (isNew) ...<Widget>[
                          const SizedBox(height: 14),
                          SizedBox(
                            width: double.infinity,
                            child: CustomButton(
                              label: 'Mark Resolved',
                              icon: const Icon(Icons.check_circle_outline),
                              onPressed: () => _resolveEnquiry(enquiry),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                );
              }),

              // ── Load more ────────────────────────────────────────────────
              if (_hasMore) ...<Widget>[
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: _isLoadingEnquiries
                        ? null
                        : () => _loadEnquiries(reset: false),
                    icon: _isLoadingEnquiries
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.expand_more_rounded),
                    label: Text(
                      'Load More (${_totalCount - _enquiries.length} remaining)',
                    ),
                  ),
                ),
              ] else if (_enquiries.isNotEmpty && !_isLoadingEnquiries) ...<Widget>[
                const SizedBox(height: 8),
                Center(
                  child: Text(
                    'All ${_enquiries.length} enquiries loaded',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: AppTheme.textMuted,
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 16),
            ],
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------
  String _formatDate(DateTime dt) {
    return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
  }

  String _formatDateTime(DateTime dt) {
    final String date = _formatDate(dt);
    final String h = dt.hour.toString().padLeft(2, '0');
    final String m = dt.minute.toString().padLeft(2, '0');
    return '$date $h:$m';
  }

  void _showMessage(String message) {
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }
}

// ---------------------------------------------------------------------------
// Private widgets
// ---------------------------------------------------------------------------
class _SummaryTile extends StatelessWidget {
  const _SummaryTile({
    required this.label,
    required this.count,
    required this.tone,
  });

  final String label;
  final int count;
  final UiTone tone;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 110,
      child: CustomCard(
        padding: CustomCardPadding.sm,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            ToneBadge(label: label, tone: tone, size: ToneBadgeSize.small),
            const SizedBox(height: 10),
            Text(
              '$count',
              style: Theme.of(context)
                  .textTheme
                  .titleLarge
                  ?.copyWith(fontWeight: FontWeight.w700),
            ),
          ],
        ),
      ),
    );
  }
}
