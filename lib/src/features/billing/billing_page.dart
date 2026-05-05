import 'dart:async';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/api/billing_service.dart';
import '../../core/api/block_building_service.dart';
import '../../core/api/razorpay_checkout_service.dart';
import '../../core/api/rental_contract_service.dart';
import '../../core/api/upload_service.dart';
import '../../core/api/vendor_service.dart';
import '../../core/models/api_models.dart';
import '../../core/models/app_models.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/pdf_saver.dart';
import '../../core/utils/rental_bill_pdf_service.dart';
import '../../core/utils/society_bills_excel_service.dart';
import '../../core/widgets/custom_button.dart';
import '../../core/widgets/custom_card.dart';
import '../../core/widgets/custom_tab_bar.dart';
import '../../core/widgets/fullscreen_image_viewer.dart';
import '../../core/widgets/page_header.dart';
import '../../core/widgets/tone_badge.dart';

class BillingPage extends StatefulWidget {
  const BillingPage({
    super.key,
    required this.role,
    required this.bills,
    this.isLoading = false,
    this.onRefresh,
  });

  final AppRole role;
  final List<BillRecord> bills;
  final bool isLoading;
  final VoidCallback? onRefresh;

  @override
  State<BillingPage> createState() => _BillingPageState();
}

class _BillingPageState extends State<BillingPage> {
  final TextEditingController _searchController = TextEditingController();

  BillStatus? _selectedFilter;
  VendorData? _vendor;
  Timer? _searchDebounce;

  // ---------------------------------------------------------------------------
  // Tenant flow state
  // ---------------------------------------------------------------------------
  int? _billTypeFilter;
  bool _isLoadingTenantBills = false;
  String? _tenantError;
  List<BillRecord> _tenantBills = <BillRecord>[];
  final Map<String, BillRecord> _billDetailsCache = <String, BillRecord>{};
  final Map<String, Future<BillRecord?>> _billDetailsFutures =
      <String, Future<BillRecord?>>{};
  double _tenantPendingAmount = 0;
  double _tenantPaidAmount = 0;
  double _tenantOverdueAmount = 0;

  // ---------------------------------------------------------------------------
  // Property Manager direct-fetch state
  // ---------------------------------------------------------------------------
  bool _isPmLoading = false;
  String? _pmError;
  List<BillRecord> _pmBills = <BillRecord>[];
  double _pmPendingAmount = 0;
  double _pmCollectedAmount = 0;
  double _pmOverdueAmount = 0;
  double _pmTodayCollection = 0;
  double _pmMonthCollection = 0;
  double _pmMonthOverdue = 0;
  double _pmMonthPending = 0;
  double _pmTotalSecurityBill = 0;
  double _pmPendingSecurity = 0;
  double _pmCollectedSecurity = 0;

  // PM filters
  String? _pmContractId;
  List<Map<String, String>> _pmContracts = <Map<String, String>>[];

  // ---------------------------------------------------------------------------
  // Society Manager direct-fetch state
  // ---------------------------------------------------------------------------
  bool _isSocietyLoading = false;
  String? _societyError;
  List<BillRecord> _societyBills = <BillRecord>[];
  double _societyPendingAmount = 0;
  double _societyCollectedAmount = 0;
  double _societyOverdueAmount = 0;
  double _societyTodayCollection = 0;
  double _societyMonthCollection = 0;
  double _societyMonthOverdue = 0;
  double _societyMonthPending = 0;
  int _societySkip = 0;
  int _societyTotalCount = 0;
  static const int _societyPageSize = 10;

  // Society filters
  int? _societyBillTypeFilter;
  BillStatus? _societyStatusFilter;
  String _societyBlockFilter = '';
  String _societyBuildingFilter = '';
  List<BlockData> _societyBlocks = <BlockData>[];
  List<BuildingData> _societyBuildings = <BuildingData>[];

  bool get _usesTenantWebsiteFlow => widget.role == AppRole.tenant;
  bool get _usesPmFlow => widget.role == AppRole.propertyManager;
  bool get _usesSocietyFlow => widget.role.isSocietyScope;

  @override
  void initState() {
    super.initState();
    _loadVendor();
    if (_usesTenantWebsiteFlow) {
      _loadTenantBills();
    }
    if (_usesSocietyFlow) {
      _loadSocietyBills();
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Load PM data after vendor is known — vendor is loaded async so we
    // trigger PM load once vendor arrives via _loadVendor().
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadVendor() async {
    try {
      _vendor = await VendorService.fetchVendorInfo();
    } catch (_) {
      _vendor = null;
    }
    if (_usesPmFlow) {
      await Future.wait(<Future<void>>[_loadPmBills(), _loadPmContracts()]);
    }
    if (_usesSocietyFlow && (_vendor?.societyId?.isNotEmpty ?? false)) {
      final String sid = _vendor!.societyId!;
      try {
        final blocksResult = await BlockBuildingService.filterBlocks(
          sid,
          limit: 200,
        );
        final buildingsResult = await BlockBuildingService.filterBuildings(
          sid,
          limit: 200,
        );
        if (mounted) {
          setState(() {
            _societyBlocks = blocksResult.blocks;
            _societyBuildings = buildingsResult.buildings;
          });
        }
      } catch (_) {}
    }
  }

  // ---------------------------------------------------------------------------
  // Tenant bills
  // ---------------------------------------------------------------------------
  Future<void> _loadTenantBills() async {
    setState(() {
      _isLoadingTenantBills = true;
      _tenantError = null;
    });

    try {
      final result = await BillingService.filterTenantBillsDetailed(
        limit: 100,
        search: _searchController.text.trim().isEmpty
            ? null
            : _searchController.text.trim(),
        billType: _billTypeFilter,
      );
      if (!mounted) {
        return;
      }

      setState(() {
        _tenantBills = result.bills;
        _tenantPendingAmount = result.pendingAmount;
        _tenantPaidAmount = result.paidAmount;
        _tenantOverdueAmount = result.overdueAmount;
        _isLoadingTenantBills = false;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _tenantError = error.toString().replaceFirst('Exception: ', '');
        _isLoadingTenantBills = false;
      });
    }
  }

  void _handleTenantSearchChanged(String value) {
    setState(() {});
    _searchDebounce?.cancel();
    _searchDebounce = Timer(
      const Duration(milliseconds: 300),
      _loadTenantBills,
    );
  }

  // ---------------------------------------------------------------------------
  // Society Manager bills
  // ---------------------------------------------------------------------------
  Future<void> _loadSocietyBills() async {
    if (_vendor?.societyId == null || _vendor!.societyId!.isEmpty) {
      return;
    }
    if (!mounted) {
      return;
    }
    setState(() {
      _isSocietyLoading = true;
      _societyError = null;
    });

    try {
      final result = await BillingService.filterSocietyResidentBills(
        societyId: _vendor!.societyId!,
        skip: _societySkip,
        limit: _societyPageSize,
        statusFilter: _societyStatusFilter,
        billType: _societyBillTypeFilter,
        blockId: _societyBlockFilter.isEmpty ? null : _societyBlockFilter,
        buildingId: _societyBuildingFilter.isEmpty
            ? null
            : _societyBuildingFilter,
        search: _searchController.text.trim().isEmpty
            ? null
            : _searchController.text.trim(),
      );
      if (!mounted) {
        return;
      }
      setState(() {
        _societyBills = result.bills;
        _societyTotalCount = result.count;
        _societyPendingAmount = result.pendingAmount;
        _societyCollectedAmount = result.collectedAmount;
        _societyOverdueAmount = result.overdueAmount;
        _societyTodayCollection = result.todayCollection;
        _societyMonthCollection = result.monthCollection;
        _societyMonthOverdue = result.monthOverdue;
        _societyMonthPending = result.monthPending;
        _isSocietyLoading = false;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _societyError = error.toString().replaceFirst('Exception: ', '');
        _isSocietyLoading = false;
      });
    }
  }

  void _handleSocietySearchChanged(String value) {
    setState(() {
      _societySkip = 0;
    });
    _searchDebounce?.cancel();
    _searchDebounce = Timer(
      const Duration(milliseconds: 400),
      _loadSocietyBills,
    );
  }

  // ---------------------------------------------------------------------------
  // Property Manager bills
  // ---------------------------------------------------------------------------
  Future<void> _loadPmBills() async {
    if (_vendor?.propertyId == null || _vendor!.propertyId!.isEmpty) {
      return;
    }
    if (!mounted) {
      return;
    }
    setState(() {
      _isPmLoading = true;
      _pmError = null;
    });

    try {
      final result = await BillingService.filterPropertyContractBillsDetailed(
        propertyId: _vendor!.propertyId!,
        limit: 100,
        search: _searchController.text.trim().isEmpty
            ? null
            : _searchController.text.trim(),
        statusFilter: _selectedFilter,
        contractId: _pmContractId,
      );
      if (!mounted) {
        return;
      }
      setState(() {
        _pmBills = result.bills;
        _pmPendingAmount = result.pendingAmount;
        _pmCollectedAmount = result.collectedAmount;
        _pmOverdueAmount = result.overdueAmount;
        _pmTodayCollection = result.todayCollection;
        _pmMonthCollection = result.monthCollection;
        _pmMonthOverdue = result.monthOverdue;
        _pmMonthPending = result.monthPending;
        _pmTotalSecurityBill = result.totalSecurityBill;
        _pmPendingSecurity = result.pendingSecurity;
        _pmCollectedSecurity = result.collectedSecurity;
        _isPmLoading = false;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _pmError = error.toString().replaceFirst('Exception: ', '');
        _isPmLoading = false;
      });
    }
  }

  Future<void> _loadPmContracts() async {
    if (_vendor?.propertyId == null || _vendor!.propertyId!.isEmpty) {
      return;
    }
    try {
      final result = await RentalContractService.filterContractsForProperty(
        _vendor!.propertyId!,
        limit: 200,
      );
      if (!mounted) {
        return;
      }
      setState(() {
        _pmContracts = result.contracts.map((RentalContractRecord c) {
          return <String, String>{
            'id': c.id,
            'label': '${c.tenantName} — ${c.propertyTitle}',
          };
        }).toList();
      });
    } catch (_) {
      // contracts are optional for filter — silently ignore
    }
  }

  void _handlePmSearchChanged(String value) {
    setState(() {});
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 400), _loadPmBills);
  }

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final List<BillRecord> sourceBills = _usesPmFlow
        ? _pmBills
        : (_usesTenantWebsiteFlow
              ? _tenantBills
              : (_usesSocietyFlow ? _societyBills : widget.bills));

    // Society, PM, and tenant flows apply server-side filtering; others filter locally.
    final List<BillRecord> visibleBills =
        (_usesPmFlow || _usesTenantWebsiteFlow || _usesSocietyFlow)
        ? sourceBills
        : sourceBills.where((BillRecord bill) {
            return _selectedFilter == null || bill.status == _selectedFilter;
          }).toList();

    final bool canGenerateBills =
        widget.role.isSocietyScope || widget.role == AppRole.propertyManager;

    if (!widget.role.supportsBilling) {
      return ListView(
        padding: AppTheme.pagePadding,
        children: <Widget>[
          PageHeader(
            title: widget.role.billingSectionTitle,
            description:
                'This role does not use the billing module in the current website navigation.',
          ),
          const SizedBox(height: 16),
          const CustomCard(
            child: Text(
              'Billing stays hidden for this role until the website feature is relevant.',
            ),
          ),
        ],
      );
    }

    final int pendingCount = sourceBills
        .where((BillRecord bill) => bill.status == BillStatus.pending)
        .length;
    final int overdueCount = sourceBills
        .where((BillRecord bill) => bill.status == BillStatus.overdue)
        .length;
    final double totalAmount = sourceBills.fold<double>(
      0,
      (double sum, BillRecord bill) => sum + bill.amount,
    );

    final bool isBusy = _usesPmFlow
        ? _isPmLoading
        : (_usesTenantWebsiteFlow
              ? _isLoadingTenantBills
              : (_usesSocietyFlow ? _isSocietyLoading : widget.isLoading));
    final String? activeError = _usesPmFlow
        ? _pmError
        : (_usesTenantWebsiteFlow
              ? _tenantError
              : (_usesSocietyFlow ? _societyError : null));

    final List<BillStatus> filterableStatuses = _usesTenantWebsiteFlow
        ? <BillStatus>[BillStatus.pending, BillStatus.paid, BillStatus.overdue]
        : BillStatus.values;

    Widget content = ListView(
      padding: AppTheme.pagePadding,
      children: <Widget>[
        PageHeader(
          title: widget.role.billingSectionTitle,
          description: _usesPmFlow
              ? 'Rental bills for all active contracts. Search, filter, and manage payments.'
              : (_usesTenantWebsiteFlow
                    ? 'Search, review, and pay tenant bills using the same website tenant flow.'
                    : 'View maintenance and rent records connected to the live backend.'),
        ),
        const SizedBox(height: 16),

        // ── Summary cards ────────────────────────────────────────────────────
        if (_usesPmFlow) ...<Widget>[
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: <Widget>[
                _SummaryCard(
                  label: 'Pending',
                  value: _compactRs(_pmPendingAmount),
                  tone: UiTone.warning,
                ),
                const SizedBox(width: 12),
                _SummaryCard(
                  label: 'Collected',
                  value: _compactRs(_pmCollectedAmount),
                  tone: UiTone.success,
                ),
                const SizedBox(width: 12),
                _SummaryCard(
                  label: 'Overdue',
                  value: _compactRs(_pmOverdueAmount),
                  tone: UiTone.danger,
                ),
                const SizedBox(width: 12),
                _SummaryCard(
                  label: "Today's Collection",
                  value: _compactRs(_pmTodayCollection),
                  tone: UiTone.brand,
                ),
                const SizedBox(width: 12),
                _SummaryCard(
                  label: 'Month Collection',
                  value: _compactRs(_pmMonthCollection),
                  tone: UiTone.success,
                ),
                const SizedBox(width: 12),
                _SummaryCard(
                  label: 'Month Overdue',
                  value: _compactRs(_pmMonthOverdue),
                  tone: UiTone.danger,
                ),
                const SizedBox(width: 12),
                _SummaryCard(
                  label: 'Month Pending',
                  value: _compactRs(_pmMonthPending),
                  tone: UiTone.warning,
                ),
                const SizedBox(width: 12),
                _SummaryCard(
                  label: 'Security Bills',
                  value: _compactRs(_pmTotalSecurityBill),
                  tone: UiTone.neutral,
                ),
                const SizedBox(width: 12),
                _SummaryCard(
                  label: 'Pending Security',
                  value: _compactRs(_pmPendingSecurity),
                  tone: UiTone.warning,
                ),
                const SizedBox(width: 12),
                _SummaryCard(
                  label: 'Collected Security',
                  value: _compactRs(_pmCollectedSecurity),
                  tone: UiTone.success,
                ),
              ],
            ),
          ),
        ] else if (_usesSocietyFlow) ...<Widget>[
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: <Widget>[
                _SummaryCard(
                  label: 'Pending',
                  value: _compactRs(_societyPendingAmount),
                  tone: UiTone.warning,
                ),
                const SizedBox(width: 12),
                _SummaryCard(
                  label: 'Collected',
                  value: _compactRs(_societyCollectedAmount),
                  tone: UiTone.success,
                ),
                const SizedBox(width: 12),
                _SummaryCard(
                  label: 'Overdue',
                  value: _compactRs(_societyOverdueAmount),
                  tone: UiTone.danger,
                ),
                const SizedBox(width: 12),
                _SummaryCard(
                  label: "Today's Collection",
                  value: _compactRs(_societyTodayCollection),
                  tone: UiTone.brand,
                ),
                const SizedBox(width: 12),
                _SummaryCard(
                  label: 'Month Collection',
                  value: _compactRs(_societyMonthCollection),
                  tone: UiTone.success,
                ),
                const SizedBox(width: 12),
                _SummaryCard(
                  label: 'Month Overdue',
                  value: _compactRs(_societyMonthOverdue),
                  tone: UiTone.danger,
                ),
                const SizedBox(width: 12),
                _SummaryCard(
                  label: 'Month Pending',
                  value: _compactRs(_societyMonthPending),
                  tone: UiTone.warning,
                ),
              ],
            ),
          ),
        ] else ...<Widget>[
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: <Widget>[
                if (_usesTenantWebsiteFlow) ...<Widget>[
                  _SummaryCard(
                    label: 'Pending To Pay',
                    value: 'Rs ${_tenantPendingAmount.toStringAsFixed(0)}',
                    tone: UiTone.warning,
                  ),
                  const SizedBox(width: 12),
                  _SummaryCard(
                    label: 'Total Paid',
                    value: 'Rs ${_tenantPaidAmount.toStringAsFixed(0)}',
                    tone: UiTone.success,
                  ),
                  const SizedBox(width: 12),
                  _SummaryCard(
                    label: 'Overdue To Pay',
                    value: 'Rs ${_tenantOverdueAmount.toStringAsFixed(0)}',
                    tone: UiTone.danger,
                  ),
                ] else ...<Widget>[
                  _SummaryCard(
                    label: 'Records',
                    value: '${sourceBills.length}',
                    tone: UiTone.brand,
                  ),
                  const SizedBox(width: 12),
                  _SummaryCard(
                    label: 'Pending',
                    value: '$pendingCount',
                    tone: UiTone.warning,
                  ),
                  const SizedBox(width: 12),
                  _SummaryCard(
                    label: 'Overdue',
                    value: '$overdueCount',
                    tone: UiTone.danger,
                  ),
                  const SizedBox(width: 12),
                  _SummaryCard(
                    label: 'Total',
                    value: 'Rs ${totalAmount.toStringAsFixed(0)}',
                    tone: UiTone.success,
                  ),
                ],
              ],
            ),
          ),
        ],
        const SizedBox(height: 16),

        // ── Filters ──────────────────────────────────────────────────────────
        if (_usesPmFlow) ...<Widget>[
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              labelText: 'Search bills',
              hintText: 'Tenant name, property, unit…',
              prefixIcon: const Icon(Icons.search_rounded),
              suffixIcon: _searchController.text.isEmpty
                  ? null
                  : IconButton(
                      onPressed: () {
                        _searchController.clear();
                        _loadPmBills();
                      },
                      icon: const Icon(Icons.close_rounded),
                    ),
            ),
            onChanged: _handlePmSearchChanged,
            onSubmitted: (_) => _loadPmBills(),
          ),
          const SizedBox(height: 12),
          if (_pmContracts.isNotEmpty)
            DropdownButtonFormField<String?>(
              value: _pmContractId,
              decoration: const InputDecoration(labelText: 'Contract'),
              isExpanded: true,
              items: <DropdownMenuItem<String?>>[
                const DropdownMenuItem<String?>(
                  value: null,
                  child: Text('All Contracts'),
                ),
                ..._pmContracts.map(
                  (Map<String, String> c) => DropdownMenuItem<String?>(
                    value: c['id'],
                    child: Text(c['label']!, overflow: TextOverflow.ellipsis),
                  ),
                ),
              ],
              onChanged: (String? value) {
                setState(() {
                  _pmContractId = value;
                });
                _loadPmBills();
              },
            ),
          if (_pmContracts.isNotEmpty) const SizedBox(height: 12),
        ],
        if (_usesTenantWebsiteFlow) ...<Widget>[
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              labelText: 'Search bills',
              hintText: 'Search by bill details',
              prefixIcon: const Icon(Icons.search_rounded),
              suffixIcon: _searchController.text.isEmpty
                  ? null
                  : IconButton(
                      onPressed: () {
                        _searchController.clear();
                        _loadTenantBills();
                      },
                      icon: const Icon(Icons.close_rounded),
                    ),
            ),
            onChanged: _handleTenantSearchChanged,
            onSubmitted: (_) => _loadTenantBills(),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<int?>(
            value: _billTypeFilter,
            decoration: const InputDecoration(labelText: 'Bill Type'),
            items: const <DropdownMenuItem<int?>>[
              DropdownMenuItem<int?>(value: null, child: Text('All Types')),
              DropdownMenuItem<int?>(value: 1, child: Text('Maintenance')),
              DropdownMenuItem<int?>(value: 2, child: Text('Rental')),
            ],
            onChanged: (int? value) {
              setState(() {
                _billTypeFilter = value;
              });
              _loadTenantBills();
            },
          ),
          const SizedBox(height: 16),
        ],
        if (_usesSocietyFlow) ...<Widget>[
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              labelText: 'Search bills',
              hintText: 'Resident name, flat no…',
              prefixIcon: const Icon(Icons.search_rounded),
              suffixIcon: _searchController.text.isEmpty
                  ? null
                  : IconButton(
                      onPressed: () {
                        _searchController.clear();
                        setState(() {
                          _societySkip = 0;
                        });
                        _loadSocietyBills();
                      },
                      icon: const Icon(Icons.close_rounded),
                    ),
            ),
            onChanged: _handleSocietySearchChanged,
            onSubmitted: (_) {
              setState(() {
                _societySkip = 0;
              });
              _loadSocietyBills();
            },
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<int?>(
            value: _societyBillTypeFilter,
            decoration: const InputDecoration(labelText: 'Bill Type'),
            items: const <DropdownMenuItem<int?>>[
              DropdownMenuItem<int?>(value: null, child: Text('All Types')),
              DropdownMenuItem<int?>(value: 1, child: Text('Maintenance')),
              DropdownMenuItem<int?>(value: 2, child: Text('Rental')),
            ],
            onChanged: (int? value) {
              setState(() {
                _societyBillTypeFilter = value;
                _societySkip = 0;
              });
              _loadSocietyBills();
            },
          ),
          if (_societyBlocks.isNotEmpty) ...<Widget>[
            const SizedBox(height: 12),
            DropdownButtonFormField<String?>(
              value: _societyBlockFilter.isEmpty ? null : _societyBlockFilter,
              decoration: const InputDecoration(labelText: 'Block'),
              isExpanded: true,
              items: <DropdownMenuItem<String?>>[
                const DropdownMenuItem<String?>(
                  value: null,
                  child: Text('All Blocks'),
                ),
                ..._societyBlocks.map(
                  (BlockData b) => DropdownMenuItem<String?>(
                    value: b.blockId,
                    child: Text(b.name),
                  ),
                ),
              ],
              onChanged: (String? value) {
                setState(() {
                  _societyBlockFilter = value ?? '';
                  _societyBuildingFilter = '';
                  _societySkip = 0;
                });
                _loadSocietyBills();
              },
            ),
          ],
          if (_societyBuildings.isNotEmpty) ...<Widget>[
            const SizedBox(height: 12),
            DropdownButtonFormField<String?>(
              value: _societyBuildingFilter.isEmpty
                  ? null
                  : _societyBuildingFilter,
              decoration: const InputDecoration(labelText: 'Building'),
              isExpanded: true,
              items: <DropdownMenuItem<String?>>[
                const DropdownMenuItem<String?>(
                  value: null,
                  child: Text('All Buildings'),
                ),
                ...(_societyBlockFilter.isEmpty
                        ? _societyBuildings
                        : _societyBuildings
                              .where(
                                (BuildingData b) =>
                                    b.blockId == _societyBlockFilter,
                              )
                              .toList())
                    .map(
                      (BuildingData b) => DropdownMenuItem<String?>(
                        value: b.buildingId,
                        child: Text(b.name),
                      ),
                    ),
              ],
              onChanged: (String? value) {
                setState(() {
                  _societyBuildingFilter = value ?? '';
                  _societySkip = 0;
                });
                _loadSocietyBills();
              },
            ),
          ],
          const SizedBox(height: 16),
        ],

        // ── Generate Bills + Export ──────────────────────────────────────────
        if (canGenerateBills) ...<Widget>[
          CustomCard(
            padding: CustomCardPadding.sm,
            child: Row(
              children: <Widget>[
                Expanded(
                  child: Text(
                    widget.role.isSocietyScope
                        ? 'Generate maintenance bills for the linked society account.'
                        : 'Generate rental bills for the linked property account.',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                if (_usesPmFlow && sourceBills.isNotEmpty)
                  IconButton(
                    tooltip: 'Export PDF Report',
                    icon: const Icon(Icons.picture_as_pdf_outlined),
                    onPressed: () =>
                        RentalBillPdfService.shareBillsReportPdf(sourceBills),
                  ),
                if (_usesSocietyFlow && sourceBills.isNotEmpty) ...<Widget>[
                  IconButton(
                    tooltip: 'Export PDF Report',
                    icon: const Icon(Icons.picture_as_pdf_outlined),
                    onPressed: () =>
                        RentalBillPdfService.shareBillsReportPdf(sourceBills),
                  ),
                  IconButton(
                    tooltip: 'Export Excel',
                    icon: const Icon(Icons.table_chart_outlined),
                    onPressed: () => SocietyBillsExcelService.exportToExcel(
                      bills: sourceBills,
                      pendingAmount: _societyPendingAmount,
                      collectedAmount: _societyCollectedAmount,
                      overdueAmount: _societyOverdueAmount,
                      todayCollection: _societyTodayCollection,
                      monthCollection: _societyMonthCollection,
                      monthOverdue: _societyMonthOverdue,
                      monthPending: _societyMonthPending,
                    ),
                  ),
                ],
                CustomButton(
                  label: 'Generate Bills',
                  icon: const Icon(Icons.auto_awesome_outlined),
                  onPressed: _generateBills,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],

        // ── Status tabs ──────────────────────────────────────────────────────
        if (!_usesPmFlow && !_usesSocietyFlow) ...<Widget>[
          CustomTabBar(
            style: CustomTabBarStyle.pill,
            currentIndex: _selectedFilter == null
                ? 0
                : filterableStatuses.indexOf(_selectedFilter!) + 1,
            onChanged: (int index) {
              setState(() {
                _selectedFilter = index == 0
                    ? null
                    : filterableStatuses[index - 1];
              });
            },
            tabs: <CustomTabItem>[
              const CustomTabItem(label: 'All'),
              ...filterableStatuses.map(
                (BillStatus status) => CustomTabItem(label: status.label),
              ),
            ],
          ),
          const SizedBox(height: 16),
        ],
        if (_usesPmFlow) ...<Widget>[
          CustomTabBar(
            style: CustomTabBarStyle.pill,
            currentIndex: _selectedFilter == null
                ? 0
                : BillStatus.values.indexOf(_selectedFilter!) + 1,
            onChanged: (int index) {
              setState(() {
                _selectedFilter = index == 0
                    ? null
                    : BillStatus.values[index - 1];
              });
              _loadPmBills();
            },
            tabs: <CustomTabItem>[
              const CustomTabItem(label: 'All'),
              ...BillStatus.values.map(
                (BillStatus s) => CustomTabItem(label: s.label),
              ),
            ],
          ),
          const SizedBox(height: 16),
        ],
        if (_usesSocietyFlow) ...<Widget>[
          CustomTabBar(
            style: CustomTabBarStyle.pill,
            currentIndex: _societyStatusFilter == null
                ? 0
                : BillStatus.values.indexOf(_societyStatusFilter!) + 1,
            onChanged: (int index) {
              setState(() {
                _societyStatusFilter = index == 0
                    ? null
                    : BillStatus.values[index - 1];
                _societySkip = 0;
              });
              _loadSocietyBills();
            },
            tabs: <CustomTabItem>[
              const CustomTabItem(label: 'All'),
              ...BillStatus.values.map(
                (BillStatus s) => CustomTabItem(label: s.label),
              ),
            ],
          ),
          const SizedBox(height: 16),
        ],

        // ── Loading / error / empty ──────────────────────────────────────────
        if (isBusy)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: Center(child: CircularProgressIndicator()),
          ),
        if (!isBusy && activeError != null)
          CustomCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  'Unable to load bills',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  activeError,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: AppTheme.textSecondary,
                  ),
                ),
                const SizedBox(height: 16),
                CustomButton(
                  label: 'Retry',
                  icon: const Icon(Icons.refresh_rounded),
                  onPressed: () {
                    if (_usesPmFlow) {
                      _loadPmBills();
                      return;
                    }
                    if (_usesTenantWebsiteFlow) {
                      _loadTenantBills();
                      return;
                    }
                    widget.onRefresh?.call();
                  },
                ),
              ],
            ),
          ),
        if (!isBusy && activeError == null && visibleBills.isEmpty)
          const CustomCard(
            padding: CustomCardPadding.sm,
            child: Text('No bills match this filter.'),
          ),

        // ── Bill cards ───────────────────────────────────────────────────────
        ...visibleBills.map((BillRecord bill) {
          final bool isOverdue = bill.status == BillStatus.overdue;
          final String billType = _billTypeLabel(bill.billTypeCode);
          // Tenant flow: website-matching card layout
          if (_usesTenantWebsiteFlow) {
            return _buildTenantBillCard(bill, theme, isOverdue, billType);
          }
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: CustomCard(
              padding: CustomCardPadding.sm,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  // Bill type chip
                  ToneBadge(
                    label: billType,
                    tone: bill.billTypeCode == 1
                        ? UiTone.brand
                        : bill.billTypeCode == 3
                        ? UiTone.warning
                        : UiTone.neutral,
                    size: ToneBadgeSize.small,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text(
                              bill.title,
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _buildBillSubtitle(bill),
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: AppTheme.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      ToneBadge(
                        label: bill.status.label,
                        tone: bill.status.tone,
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  // 3-column metadata: Amount, Bill Date, Due Date
                  Row(
                    children: <Widget>[
                      Expanded(
                        child: _MetaItem(
                          label: 'Amount',
                          value:
                              'Rs ${(bill.finalAmount ?? bill.amount).toStringAsFixed(0)}',
                        ),
                      ),
                      if (bill.billDate != null)
                        Expanded(
                          child: _MetaItem(
                            label: 'Bill Date',
                            value: formatCompactDate(bill.billDate!),
                          ),
                        ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text(
                              'Due',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: AppTheme.textMuted,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              formatCompactDate(bill.dueDate),
                              style: theme.textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.w600,
                                color: isOverdue
                                    ? const Color(0xFFDC2626)
                                    : null,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  // Flat/Unit info
                  if (bill.unitLabel.isNotEmpty) ...<Widget>[
                    const SizedBox(height: 10),
                    Row(
                      children: <Widget>[
                        const Icon(
                          Icons.home_outlined,
                          size: 14,
                          color: AppTheme.textMuted,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          bill.unitLabel,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: AppTheme.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ],
                  // Breakdown amounts
                  if ((bill.maintenanceAmount ?? 0) > 0 ||
                      (bill.depositAmount ?? 0) > 0) ...<Widget>[
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 12,
                      runSpacing: 4,
                      children: <Widget>[
                        if ((bill.maintenanceAmount ?? 0) > 0)
                          Text(
                            'Maintenance: Rs ${bill.maintenanceAmount!.toStringAsFixed(0)}',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: AppTheme.textMuted,
                            ),
                          ),
                        if ((bill.depositAmount ?? 0) > 0)
                          Text(
                            'Deposit: Rs ${bill.depositAmount!.toStringAsFixed(0)}',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: AppTheme.textMuted,
                            ),
                          ),
                      ],
                    ),
                  ],
                  if ((_usesTenantWebsiteFlow || _usesPmFlow) &&
                      ((bill.societyName ?? '').isNotEmpty ||
                          (bill.propertyTitle ?? '').isNotEmpty ||
                          (bill.ownerName ?? '').isNotEmpty ||
                          (bill.residentName ?? '').isNotEmpty)) ...<Widget>[
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: <Widget>[
                        if ((bill.societyName ?? '').isNotEmpty)
                          ToneBadge(
                            label: bill.societyName!,
                            tone: UiTone.brand,
                          ),
                        if ((bill.propertyTitle ?? '').isNotEmpty)
                          ToneBadge(
                            label: bill.propertyTitle!,
                            tone: UiTone.neutral,
                          ),
                        if (_usesPmFlow && (bill.residentName ?? '').isNotEmpty)
                          ToneBadge(
                            label: bill.residentName!,
                            tone: UiTone.brand,
                          ),
                        if (_usesTenantWebsiteFlow &&
                            (bill.ownerName ?? '').isNotEmpty)
                          ToneBadge(
                            label: 'Owner: ${bill.ownerName!}',
                            tone: UiTone.neutral,
                          ),
                      ],
                    ),
                  ],
                  if (bill.note != null) ...<Widget>[
                    const SizedBox(height: 12),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppTheme.surfaceMuted,
                        borderRadius: BorderRadius.circular(
                          AppTheme.radiusSmall,
                        ),
                      ),
                      child: Text(
                        bill.note!,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 14),
                  Row(
                    children: <Widget>[
                      Expanded(
                        child: CustomButton(
                          label: 'View Details',
                          variant: CustomButtonVariant.outline,
                          onPressed: () => _openBillDetails(bill),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: CustomButton(
                          label: bill.status == BillStatus.paid
                              ? 'Completed'
                              : (widget.role.isResidentScope ||
                                    widget.role == AppRole.owner)
                              ? 'Pay Now'
                              : 'Send Reminder',
                          onPressed: bill.status == BillStatus.paid
                              ? null
                              : () => _handleBillAction(bill),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        }),

        // ── Society pagination ───────────────────────────────────────────────
        if (_usesSocietyFlow &&
            _societyTotalCount > _societyPageSize) ...<Widget>[
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              TextButton.icon(
                onPressed: _societySkip == 0
                    ? null
                    : () {
                        setState(() {
                          _societySkip = (_societySkip - _societyPageSize)
                              .clamp(0, _societySkip);
                        });
                        _loadSocietyBills();
                      },
                icon: const Icon(Icons.chevron_left_rounded),
                label: const Text('Prev'),
              ),
              Text(
                'Showing ${_societySkip + 1}–${_societySkip + _societyBills.length} of $_societyTotalCount',
                style: theme.textTheme.bodyMedium,
              ),
              TextButton.icon(
                onPressed: _societySkip + _societyPageSize >= _societyTotalCount
                    ? null
                    : () {
                        setState(() {
                          _societySkip += _societyPageSize;
                        });
                        _loadSocietyBills();
                      },
                icon: const Icon(Icons.chevron_right_rounded),
                label: const Text('Next'),
              ),
            ],
          ),
        ],
      ],
    );

    if (widget.onRefresh != null || _usesPmFlow || _usesSocietyFlow) {
      content = RefreshIndicator(
        onRefresh: () async {
          if (_usesPmFlow) {
            await _loadPmBills();
            return;
          }
          if (_usesSocietyFlow) {
            setState(() {
              _societySkip = 0;
            });
            await _loadSocietyBills();
            return;
          }
          if (_usesTenantWebsiteFlow) {
            await _loadTenantBills();
          }
          widget.onRefresh?.call();
        },
        child: content,
      );
    }

    return content;
  }

  // ---------------------------------------------------------------------------
  // Tenant bill card (website-matching layout)
  // ---------------------------------------------------------------------------
  Widget _buildTenantBillCard(
    BillRecord bill,
    ThemeData theme,
    bool isOverdue,
    String billType,
  ) {
    final BillRecord displayBill = _billDetailsCache[bill.id] ?? bill;
    if (!_hasBillResidentName(displayBill)) {
      return FutureBuilder<BillRecord?>(
        future: _billDetailsFutureFor(bill),
        builder: (BuildContext context, AsyncSnapshot<BillRecord?> snapshot) {
          final BillRecord hydratedBill = snapshot.data ?? displayBill;
          return _buildTenantBillCardContent(
            hydratedBill,
            theme,
            hydratedBill.status == BillStatus.overdue,
            _billTypeLabel(hydratedBill.billTypeCode),
          );
        },
      );
    }

    return _buildTenantBillCardContent(displayBill, theme, isOverdue, billType);
  }

  Widget _buildTenantBillCardContent(
    BillRecord bill,
    ThemeData theme,
    bool isOverdue,
    String billType,
  ) {
    final String displayName =
        bill.residentName ?? _vendor?.fullName ?? bill.ownerName ?? '';
    final String propertyName = bill.propertyTitle ?? bill.societyName ?? '';
    final String phone =
        bill.residentPhone ?? _vendor?.phone ?? bill.ownerPhone ?? '';
    final String email =
        bill.residentEmail ?? _vendor?.email ?? bill.ownerEmail ?? '';

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: CustomCard(
        padding: CustomCardPadding.sm,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            // ── Owner Header ──
            Row(
              children: <Widget>[
                CircleAvatar(
                  radius: 28,
                  backgroundColor: const Color(0xFFDBEAFE),
                  child: Icon(
                    Icons.home_rounded,
                    color: AppTheme.primary,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        displayName,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      if (propertyName.isNotEmpty)
                        Text(
                          propertyName,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: AppTheme.primary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      if (phone.isNotEmpty) ...<Widget>[
                        const SizedBox(height: 2),
                        Row(
                          children: <Widget>[
                            Icon(
                              Icons.phone_outlined,
                              size: 14,
                              color: AppTheme.textSecondary,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              phone,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: AppTheme.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ],
                      if (email.isNotEmpty) ...<Widget>[
                        const SizedBox(height: 2),
                        Row(
                          children: <Widget>[
                            Icon(
                              Icons.email_outlined,
                              size: 14,
                              color: AppTheme.textSecondary,
                            ),
                            const SizedBox(width: 6),
                            Flexible(
                              child: Text(
                                email.toUpperCase(),
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: AppTheme.textSecondary,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            // ── Bill Type + Status ──
            Row(
              children: <Widget>[
                Expanded(
                  child: Text(
                    billType,
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                ToneBadge(label: bill.status.label, tone: bill.status.tone),
              ],
            ),
            const SizedBox(height: 8),
            // ── Amount ──
            Text(
              '\u20B9${(bill.finalAmount ?? bill.amount).toStringAsFixed(0)}',
              style: theme.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            const Divider(height: 24),
            // ── Metadata Rows ──
            Row(
              children: <Widget>[
                Expanded(
                  child: Text.rich(
                    TextSpan(
                      text: 'Flat/Unit: ',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: AppTheme.textMuted,
                      ),
                      children: <InlineSpan>[
                        TextSpan(
                          text: bill.unitLabel,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: AppTheme.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                if (bill.billDate != null)
                  Expanded(
                    child: Text.rich(
                      TextSpan(
                        text: 'Bill Date: ',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: AppTheme.textMuted,
                        ),
                        children: <InlineSpan>[
                          TextSpan(
                            text: formatCompactDate(bill.billDate!),
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: AppTheme.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              children: <Widget>[
                Expanded(
                  child: Text.rich(
                    TextSpan(
                      text: 'Due Date: ',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: AppTheme.textMuted,
                      ),
                      children: <InlineSpan>[
                        TextSpan(
                          text: formatCompactDate(bill.dueDate),
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: isOverdue
                                ? const Color(0xFFDC2626)
                                : AppTheme.textSecondary,
                            fontWeight: isOverdue ? FontWeight.w600 : null,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                if ((bill.ownerName ?? '').isNotEmpty)
                  Expanded(
                    child: Text.rich(
                      TextSpan(
                        text: 'Owner: ',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: AppTheme.textMuted,
                        ),
                        children: <InlineSpan>[
                          TextSpan(
                            text: bill.ownerName!,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: AppTheme.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
            // ── Society / Block / Building context ──
            if ((bill.societyName ?? '').isNotEmpty ||
                (bill.blockName ?? '').isNotEmpty ||
                (bill.buildingName ?? '').isNotEmpty) ...<Widget>[
              const SizedBox(height: 6),
              Wrap(
                spacing: 16,
                runSpacing: 4,
                children: <Widget>[
                  if ((bill.societyName ?? '').isNotEmpty)
                    Text.rich(
                      TextSpan(
                        text: 'Society: ',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: AppTheme.textMuted,
                        ),
                        children: <InlineSpan>[
                          TextSpan(
                            text: bill.societyName!,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: AppTheme.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  if ((bill.blockName ?? '').isNotEmpty)
                    Text.rich(
                      TextSpan(
                        text: 'Block: ',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: AppTheme.textMuted,
                        ),
                        children: <InlineSpan>[
                          TextSpan(
                            text: bill.blockName!,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: AppTheme.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  if ((bill.buildingName ?? '').isNotEmpty)
                    Text.rich(
                      TextSpan(
                        text: 'Building: ',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: AppTheme.textMuted,
                        ),
                        children: <InlineSpan>[
                          TextSpan(
                            text: bill.buildingName!,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: AppTheme.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ],
            const SizedBox(height: 14),
            // ── Buttons ──
            Row(
              children: <Widget>[
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _openBillDetails(bill),
                    icon: const Icon(Icons.visibility_outlined, size: 18),
                    label: const Text('View'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: bill.status == BillStatus.paid
                      ? FilledButton.icon(
                          onPressed: null,
                          icon: const Icon(
                            Icons.check_circle_outlined,
                            size: 18,
                          ),
                          label: const Text('Completed'),
                        )
                      : FilledButton.icon(
                          onPressed: () => _handleBillAction(bill),
                          icon: const Icon(Icons.payment_outlined, size: 18),
                          label: const Text('Pay Now'),
                        ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Actions
  // ---------------------------------------------------------------------------
  Future<void> _generateBills() async {
    try {
      if (widget.role.isSocietyScope &&
          (_vendor?.societyId?.isNotEmpty ?? false)) {
        await BillingService.generateSocietyBills(_vendor!.societyId!);
      } else if (widget.role == AppRole.propertyManager &&
          (_vendor?.propertyId?.isNotEmpty ?? false)) {
        await BillingService.generatePropertyBills(_vendor!.propertyId!);
      } else {
        _showMessage(
          'Linked society or property information is not available.',
        );
        return;
      }
      _showMessage('Bill generation request submitted.');
      if (_usesPmFlow) {
        _loadPmBills();
      } else if (_usesSocietyFlow) {
        _loadSocietyBills();
      } else {
        widget.onRefresh?.call();
      }
    } catch (error) {
      _showMessage(error.toString().replaceFirst('Exception: ', ''));
    }
  }

  Future<void> _handleBillAction(BillRecord bill) async {
    try {
      if (widget.role.isResidentScope || widget.role == AppRole.owner) {
        // Confirmation dialog before payment.
        final String billTypeLabel = _billTypeLabel(bill.billTypeCode);
        final bool? confirmed = await showDialog<bool>(
          context: context,
          builder: (BuildContext dialogCtx) => AlertDialog(
            title: const Text('Confirm Payment'),
            content: Text(
              'You are about to pay Rs ${bill.amount.toStringAsFixed(0)} for $billTypeLabel.',
            ),
            actions: <Widget>[
              OutlinedButton(
                onPressed: () => Navigator.pop(dialogCtx, false),
                child: const Text('Cancel'),
              ),
              FilledButton.icon(
                onPressed: () => Navigator.pop(dialogCtx, true),
                icon: const Icon(Icons.credit_card_outlined, size: 18),
                label: const Text('Pay Online'),
              ),
            ],
          ),
        );
        if (confirmed != true) return;

        final response = await BillingService.collectBillPayment(
          bill.id,
          paymentType: 2,
        );

        if (!response.success) {
          throw Exception(
            response.message ?? response.status ?? 'Unable to start payment.',
          );
        }

        final String orderId =
            response.extras['Razorpay_Order_ID'] as String? ?? '';
        if (orderId.isNotEmpty) {
          final RazorpayCheckoutResult checkoutResult =
              await RazorpayCheckoutService.openCheckout(
                keyId: response.extras['Razorpay_Key_ID'] as String? ?? '',
                amountInPaise:
                    (response.extras['Amount_In_Paise'] as num?)?.toInt() ??
                    (((response.extras['Amount'] as num?) ?? bill.amount) * 100)
                        .round(),
                name: 'Urban Easy Flats',
                description: bill.title,
                orderId: orderId,
                currency: response.extras['Currency'] as String? ?? 'INR',
                prefillName: _vendor?.fullName,
                prefillEmail: _vendor?.email,
                prefillContact: _vendor?.phone,
              );

          if (!checkoutResult.success) {
            throw Exception(
              checkoutResult.message ?? 'Payment was not completed.',
            );
          }

          _showMessage('Payment completed. Confirmation is being processed.');
        } else {
          _showMessage(
            response.message ?? response.status ?? 'Payment request submitted.',
          );
        }
      } else {
        await BillingService.sendBillWhatsAppReminder(bill.id);
        _showMessage('Reminder sent successfully.');
      }
      if (_usesPmFlow) {
        await _loadPmBills();
      } else if (_usesTenantWebsiteFlow) {
        await _loadTenantBills();
      } else if (_usesSocietyFlow) {
        await _loadSocietyBills();
      }
      widget.onRefresh?.call();
    } catch (error) {
      _showMessage(error.toString().replaceFirst('Exception: ', ''));
    }
  }

  bool _hasBillResidentName(BillRecord bill) {
    return (bill.residentName ?? '').trim().isNotEmpty;
  }

  Future<BillRecord?> _billDetailsFutureFor(BillRecord bill) {
    return _billDetailsFutures.putIfAbsent(bill.id, () async {
      final BillRecord? fullBill = await BillingService.fetchBillInfo(bill.id);
      final BillRecord mergedBill = _mergeBillRecords(bill, fullBill);
      _billDetailsCache[bill.id] = mergedBill;
      return mergedBill;
    });
  }

  BillRecord _mergeBillRecords(BillRecord bill, BillRecord? fullBill) {
    if (fullBill == null) {
      return bill;
    }

    return BillRecord(
      id: fullBill.id,
      title: fullBill.title,
      unitLabel: fullBill.unitLabel != 'N/A'
          ? fullBill.unitLabel
          : bill.unitLabel,
      amount: fullBill.amount,
      dueDate: fullBill.dueDate,
      status: fullBill.status,
      category: fullBill.category,
      note: fullBill.note ?? bill.note,
      billTypeCode: fullBill.billTypeCode ?? bill.billTypeCode,
      finalAmount: fullBill.finalAmount ?? bill.finalAmount,
      billDate: fullBill.billDate ?? bill.billDate,
      paidDate: fullBill.paidDate ?? bill.paidDate,
      paymentType: fullBill.paymentType ?? bill.paymentType,
      manualOnlinePaymentMode:
          fullBill.manualOnlinePaymentMode ?? bill.manualOnlinePaymentMode,
      paymentNote: fullBill.paymentNote ?? bill.paymentNote,
      billAmount: fullBill.billAmount ?? bill.billAmount,
      maintenanceAmount: fullBill.maintenanceAmount ?? bill.maintenanceAmount,
      tokenAmount: fullBill.tokenAmount ?? bill.tokenAmount,
      paymentImageUrl: fullBill.paymentImageUrl ?? bill.paymentImageUrl,
      walletCredited: fullBill.walletCredited ?? bill.walletCredited,
      walletCreditTime: fullBill.walletCreditTime ?? bill.walletCreditTime,
      walletCreditedTime:
          fullBill.walletCreditedTime ?? bill.walletCreditedTime,
      residentName: (fullBill.residentName ?? '').isNotEmpty
          ? fullBill.residentName
          : (bill.residentName ?? '').isNotEmpty
          ? bill.residentName
          : _vendor?.fullName,
      residentPhone: (fullBill.residentPhone ?? '').isNotEmpty
          ? fullBill.residentPhone
          : (bill.residentPhone ?? '').isNotEmpty
          ? bill.residentPhone
          : _vendor?.phone,
      residentEmail: (fullBill.residentEmail ?? '').isNotEmpty
          ? fullBill.residentEmail
          : (bill.residentEmail ?? '').isNotEmpty
          ? bill.residentEmail
          : _vendor?.email,
      residentTypeLabel: fullBill.residentTypeLabel ?? bill.residentTypeLabel,
      societyName: (fullBill.societyName ?? '').isNotEmpty
          ? fullBill.societyName
          : bill.societyName,
      blockName: (fullBill.blockName ?? '').isNotEmpty
          ? fullBill.blockName
          : bill.blockName,
      buildingName: (fullBill.buildingName ?? '').isNotEmpty
          ? fullBill.buildingName
          : bill.buildingName,
      propertyTitle: (fullBill.propertyTitle ?? '').isNotEmpty
          ? fullBill.propertyTitle
          : bill.propertyTitle,
      ownerName: (fullBill.ownerName ?? '').isNotEmpty
          ? fullBill.ownerName
          : bill.ownerName,
      ownerPhone: (fullBill.ownerPhone ?? '').isNotEmpty
          ? fullBill.ownerPhone
          : bill.ownerPhone,
      ownerEmail: (fullBill.ownerEmail ?? '').isNotEmpty
          ? fullBill.ownerEmail
          : bill.ownerEmail,
      contractStartDate: fullBill.contractStartDate ?? bill.contractStartDate,
      contractEndDate: fullBill.contractEndDate ?? bill.contractEndDate,
      rentAmount: fullBill.rentAmount ?? bill.rentAmount,
      depositAmount: fullBill.depositAmount ?? bill.depositAmount,
      vacateDate: fullBill.vacateDate ?? bill.vacateDate,
    );
  }

  Future<void> _openBillDetails(BillRecord bill) async {
    try {
      final BillRecord activeBill = await _billDetailsFutureFor(bill) ?? bill;
      if (!mounted) {
        return;
      }

      final bool canRecordPayment =
          !(widget.role.isResidentScope || widget.role == AppRole.owner) &&
          activeBill.status != BillStatus.paid;

      Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => _BillDetailPage(
            bill: activeBill,
            isTenantFlow: _usesTenantWebsiteFlow,
            isPmFlow: _usesPmFlow,
            canRecordPayment: canRecordPayment,
            onDownloadReceipt: () async {
              final bytes = await RentalBillPdfService.generateBillPdfBytes(
                activeBill,
              );
              if (!mounted) return;
              await PdfSaver.saveAndOffer(
                context,
                bytes: bytes,
                filename: 'bill-${activeBill.id}.pdf',
              );
            },
            onContactOwner: (activeBill.ownerPhone ?? '').isNotEmpty
                ? () => _contactOwner(activeBill.ownerPhone!)
                : null,
            onContactTenant: (activeBill.residentPhone ?? '').isNotEmpty
                ? () => _contactOwner(activeBill.residentPhone!)
                : null,
            onRecordPayment: canRecordPayment
                ? () {
                    Navigator.of(context).pop();
                    _openManualCollectionSheet(activeBill);
                  }
                : null,
          ),
        ),
      );
    } catch (error) {
      _showMessage(error.toString().replaceFirst('Exception: ', ''));
    }
  }

  /// Manual payment collection sheet — supports cash, manual online
  /// (with mode dropdown, description, and optional payment proof image).
  Future<void> _openManualCollectionSheet(BillRecord bill) async {
    // First ask: cash or manual online?
    final bool? isManualOnline = await showModalBottomSheet<bool>(
      context: context,
      builder: (BuildContext ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  'Record Payment',
                  style: Theme.of(
                    ctx,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 8),
                Text(
                  '${bill.title} | Rs ${bill.amount.toStringAsFixed(0)}',
                  style: Theme.of(ctx).textTheme.bodyMedium?.copyWith(
                    color: AppTheme.textSecondary,
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: CustomButton(
                    label: 'Paid by Cash',
                    icon: const Icon(Icons.payments_outlined),
                    variant: CustomButtonVariant.outline,
                    onPressed: () => Navigator.of(ctx).pop(false),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: CustomButton(
                    label: 'Paid by Manual Online',
                    icon: const Icon(Icons.phone_android_outlined),
                    onPressed: () => Navigator.of(ctx).pop(true),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );

    if (isManualOnline == null || !mounted) {
      return;
    }

    if (!isManualOnline) {
      // Cash payment
      try {
        await BillingService.collectBillManualOnline(bill.id, paymentType: 1);
        _showMessage('Cash payment recorded successfully.');
        if (_usesPmFlow) {
          _loadPmBills();
        } else if (_usesSocietyFlow) {
          _loadSocietyBills();
        } else {
          widget.onRefresh?.call();
        }
      } catch (error) {
        _showMessage(error.toString().replaceFirst('Exception: ', ''));
      }
      return;
    }

    // Manual online — show full form
    bool sheetClosed = false;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (BuildContext context) {
        int? selectedMode;
        final TextEditingController descController = TextEditingController();
        String? uploadedImageId;
        String? uploadedImagePath;
        bool isUploadingImage = false;
        bool isSubmitting = false;

        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            void safeSet(VoidCallback fn) {
              if (!mounted || sheetClosed) {
                return;
              }
              setModalState(fn);
            }

            Future<void> pickImage() async {
              final FilePickerResult? result = await FilePicker.platform
                  .pickFiles(type: FileType.image);
              if (result == null || result.files.single.path == null) {
                return;
              }
              safeSet(() {
                isUploadingImage = true;
              });
              try {
                final String? imgId = await UploadService.uploadImage(
                  File(result.files.single.path!),
                );
                safeSet(() {
                  uploadedImageId = imgId;
                  uploadedImagePath = result.files.single.path;
                  isUploadingImage = false;
                });
              } catch (_) {
                safeSet(() {
                  isUploadingImage = false;
                });
                _showMessage('Image upload failed. Please try again.');
              }
            }

            Future<void> submit() async {
              if (selectedMode == null) {
                _showMessage('Please select the payment mode.');
                return;
              }
              safeSet(() {
                isSubmitting = true;
              });
              try {
                await BillingService.collectBillManualOnline(
                  bill.id,
                  paymentType: 3,
                  manualOnlinePaymentMode: selectedMode,
                  paymentDescription: descController.text.trim().isEmpty
                      ? null
                      : descController.text.trim(),
                  whetherPaymentImageAvailable: uploadedImageId != null,
                  imageId: uploadedImageId,
                );
                if (!mounted || sheetClosed) {
                  return;
                }
                sheetClosed = true;
                Navigator.of(context).pop();
                _showMessage('Manual online payment recorded successfully.');
                if (_usesPmFlow) {
                  _loadPmBills();
                } else if (_usesSocietyFlow) {
                  _loadSocietyBills();
                } else {
                  widget.onRefresh?.call();
                }
              } catch (error) {
                _showMessage(error.toString().replaceFirst('Exception: ', ''));
                safeSet(() {
                  isSubmitting = false;
                });
              }
            }

            return SafeArea(
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  16,
                  12,
                  16,
                  MediaQuery.of(context).viewInsets.bottom + 24,
                ),
                child: ListView(
                  shrinkWrap: true,
                  children: <Widget>[
                    Text(
                      'Manual Online Payment',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${bill.title} | Rs ${bill.amount.toStringAsFixed(0)}',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppTheme.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 20),
                    DropdownButtonFormField<int?>(
                      value: selectedMode,
                      decoration: const InputDecoration(
                        labelText: 'Payment Mode *',
                      ),
                      items: _manualOnlinePaymentModes.entries
                          .map(
                            (MapEntry<int, String> e) => DropdownMenuItem<int?>(
                              value: e.key,
                              child: Text(e.value),
                            ),
                          )
                          .toList(),
                      onChanged: (int? v) => safeSet(() {
                        selectedMode = v;
                      }),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: descController,
                      decoration: const InputDecoration(
                        labelText: 'Description / Transaction ID (optional)',
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: <Widget>[
                        Expanded(
                          child: Text(
                            uploadedImagePath != null
                                ? 'Proof: ${uploadedImagePath!.split('/').last.split('\\').last}'
                                : 'No payment proof attached',
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(
                                  color: uploadedImagePath != null
                                      ? const Color(0xFF16A34A)
                                      : AppTheme.textSecondary,
                                ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 12),
                        isUploadingImage
                            ? const SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : CustomButton(
                                label: uploadedImagePath != null
                                    ? 'Change'
                                    : 'Upload Proof',
                                icon: const Icon(Icons.upload_outlined),
                                variant: CustomButtonVariant.outline,
                                onPressed: pickImage,
                              ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: CustomButton(
                        label: 'Confirm Payment',
                        isLoading: isSubmitting,
                        onPressed: isSubmitting ? null : submit,
                      ),
                    ),
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
  }

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------
  String _buildBillSubtitle(BillRecord bill) {
    if (_usesPmFlow) {
      if ((bill.residentName ?? '').isNotEmpty) {
        return '${bill.residentName!} | ${bill.unitLabel}';
      }
      if ((bill.propertyTitle ?? '').isNotEmpty) {
        return '${bill.propertyTitle!} | ${bill.unitLabel}';
      }
      return '${bill.category} for ${bill.unitLabel}';
    }
    if (_usesTenantWebsiteFlow) {
      if ((bill.propertyTitle ?? '').isNotEmpty) {
        if ((bill.ownerName ?? '').isNotEmpty) {
          return '${bill.propertyTitle} | ${bill.ownerName}';
        }
        return bill.propertyTitle!;
      }
      if ((bill.societyName ?? '').isNotEmpty) {
        return '${bill.category} | ${bill.societyName}';
      }
    }
    return '${bill.category} for ${bill.unitLabel}';
  }

  static String _billTypeLabel(int? code) {
    return switch (code) {
      1 => 'Maintenance',
      2 => 'Rental Amount',
      3 => 'Security Deposit',
      _ => 'Bill',
    };
  }

  static const Map<int, String> _manualOnlinePaymentModes = <int, String>{
    1: 'UPI',
    2: 'NetBanking',
    3: 'Card',
    4: 'Wallet',
    5: 'NEFT',
    6: 'IMPS',
    7: 'RTGS',
    8: 'Cash Deposit',
    9: 'Bank Transfer',
    10: 'Other',
  };

  /// Compact currency formatter: 1,50,000 → "Rs 1.5L", 5000 → "Rs 5K"
  String _compactRs(double value) {
    if (value >= 100000) {
      return 'Rs ${(value / 100000).toStringAsFixed(1)}L';
    }
    if (value >= 1000) {
      return 'Rs ${(value / 1000).toStringAsFixed(1)}K';
    }
    return 'Rs ${value.toStringAsFixed(0)}';
  }

  Future<void> _contactOwner(String phoneNumber, {String? email}) async {
    if (!mounted) return;
    showModalBottomSheet<void>(
      context: context,
      builder: (BuildContext sheetCtx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            ListTile(
              leading: const Icon(Icons.phone_outlined),
              title: Text('Call $phoneNumber'),
              onTap: () {
                Navigator.pop(sheetCtx);
                launchUrl(Uri.parse('tel:$phoneNumber'));
              },
            ),
            ListTile(
              leading: const Icon(Icons.chat_outlined),
              title: Text('WhatsApp $phoneNumber'),
              onTap: () {
                Navigator.pop(sheetCtx);
                final String cleaned = phoneNumber.replaceAll(
                  RegExp(r'[^0-9]'),
                  '',
                );
                final String whatsappNum = cleaned.length == 10
                    ? '91$cleaned'
                    : cleaned;
                launchUrl(
                  Uri.parse('https://wa.me/$whatsappNum'),
                  mode: LaunchMode.externalApplication,
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.sms_outlined),
              title: Text('SMS $phoneNumber'),
              onTap: () {
                Navigator.pop(sheetCtx);
                launchUrl(Uri.parse('sms:$phoneNumber'));
              },
            ),
            if (email != null && email.isNotEmpty)
              ListTile(
                leading: const Icon(Icons.email_outlined),
                title: Text('Email $email'),
                onTap: () {
                  Navigator.pop(sheetCtx);
                  launchUrl(Uri.parse('mailto:$email'));
                },
              ),
          ],
        ),
      ),
    );
  }

  void _showMessage(String message) {
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }
}

// ─── Full-Screen Bill Detail Page ──────────────────────────────────────────

class _BillDetailPage extends StatelessWidget {
  const _BillDetailPage({
    required this.bill,
    required this.isTenantFlow,
    required this.isPmFlow,
    required this.canRecordPayment,
    this.onDownloadReceipt,
    this.onContactOwner,
    this.onContactTenant,
    this.onRecordPayment,
  });

  final BillRecord bill;
  final bool isTenantFlow;
  final bool isPmFlow;
  final bool canRecordPayment;
  final VoidCallback? onDownloadReceipt;
  final VoidCallback? onContactOwner;
  final VoidCallback? onContactTenant;
  final VoidCallback? onRecordPayment;

  static String _billTypeLabel(int? code) {
    return switch (code) {
      1 => 'Maintenance',
      2 => 'Rental Amount',
      3 => 'Security Deposit',
      _ => 'Bill',
    };
  }

  static String _paymentTypeLabel(int value) {
    return switch (value) {
      1 => 'Cash',
      2 => 'Online',
      3 => 'Manual Online',
      _ => 'Other',
    };
  }

  static const Map<int, String> _manualOnlinePaymentModes = <int, String>{
    1: 'UPI',
    2: 'NetBanking',
    3: 'Card',
    4: 'Wallet',
    5: 'NEFT',
    6: 'IMPS',
    7: 'RTGS',
    8: 'Cash Deposit',
    9: 'Bank Transfer',
    10: 'Other',
  };

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final bool hasImage = (bill.paymentImageUrl ?? '').trim().isNotEmpty;
    final bool isOverdue = bill.status == BillStatus.overdue;

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 16,
        title: const Text('Bill Details'),
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1, thickness: 1, color: AppTheme.border),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: <Widget>[
          // ── 1. Owner / Resident Header ─────────────────────────
          if (isTenantFlow) ...<Widget>[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFF9FAFB),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: <Widget>[
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: const Color(0xFFDBEAFE),
                    child: Icon(
                      Icons.home_rounded,
                      color: AppTheme.primary,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          bill.residentName ?? '',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        if ((bill.propertyTitle ?? '').isNotEmpty ||
                            bill.unitLabel.isNotEmpty)
                          Text(
                            <String>[
                              if ((bill.propertyTitle ?? '').isNotEmpty)
                                bill.propertyTitle!,
                              if (bill.unitLabel.isNotEmpty)
                                'Unit ${bill.unitLabel}',
                            ].join(' - '),
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: AppTheme.primary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        if ((bill.residentPhone ?? '').isNotEmpty) ...<Widget>[
                          const SizedBox(height: 2),
                          Row(
                            children: <Widget>[
                              Icon(
                                Icons.phone_outlined,
                                size: 14,
                                color: AppTheme.textSecondary,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                bill.residentPhone!,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: AppTheme.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ],
                        if ((bill.residentEmail ?? '').isNotEmpty) ...<Widget>[
                          const SizedBox(height: 2),
                          Row(
                            children: <Widget>[
                              Icon(
                                Icons.email_outlined,
                                size: 14,
                                color: AppTheme.textSecondary,
                              ),
                              const SizedBox(width: 6),
                              Flexible(
                                child: Text(
                                  bill.residentEmail!.toUpperCase(),
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: AppTheme.textSecondary,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ] else if ((bill.residentName ?? '').isNotEmpty ||
              (bill.residentPhone ?? '').isNotEmpty ||
              (bill.residentEmail ?? '').isNotEmpty ||
              (bill.propertyTitle ?? '').isNotEmpty ||
              (bill.ownerName ?? '').isNotEmpty) ...<Widget>[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFF9FAFB),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: <Widget>[
                  CircleAvatar(
                    radius: 22,
                    backgroundColor: AppTheme.primary.withValues(alpha: 0.12),
                    child: Text(
                      (bill.residentName ?? 'B')[0].toUpperCase(),
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: AppTheme.primary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        if ((bill.residentName ?? '').isNotEmpty)
                          Text(
                            bill.residentName!,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        if ((bill.residentPhone ?? '').isNotEmpty)
                          Text(
                            bill.residentPhone!,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: AppTheme.textSecondary,
                            ),
                          ),
                        if ((bill.residentEmail ?? '').isNotEmpty)
                          Text(
                            bill.residentEmail!,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: AppTheme.textSecondary,
                            ),
                          ),
                        if ((bill.propertyTitle ?? '').isNotEmpty ||
                            (bill.unitLabel.isNotEmpty &&
                                bill.unitLabel != 'N/A'))
                          Text(
                            <String>[
                              if ((bill.propertyTitle ?? '').isNotEmpty)
                                bill.propertyTitle!,
                              if (bill.unitLabel.isNotEmpty &&
                                  bill.unitLabel != 'N/A')
                                'Unit ${bill.unitLabel}',
                            ].join(' - '),
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: AppTheme.textMuted,
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],

          // ── 2. Bill Type + Status + Amount ─────────────────────
          Text(
            _billTypeLabel(bill.billTypeCode),
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
              color: AppTheme.textSecondary,
            ),
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: <Widget>[
              ToneBadge(label: bill.status.label, tone: bill.status.tone),
              if (!isTenantFlow)
                ToneBadge(label: bill.category, tone: UiTone.neutral),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            'Rs ${(bill.finalAmount ?? bill.amount).toStringAsFixed(0)}',
            style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 20),

          // ── 3. Details / Date Info ─────────────────────────────
          if (isTenantFlow) ...<Widget>[
            const SizedBox(height: 4),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFF5F5F5),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  if (bill.billDate != null) ...<Widget>[
                    Text.rich(
                      TextSpan(
                        text: 'Bill Date: ',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                        children: <InlineSpan>[
                          TextSpan(
                            text: formatCompactDate(bill.billDate!),
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                  ],
                  Text.rich(
                    TextSpan(
                      text: 'Due Date: ',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                      children: <InlineSpan>[
                        TextSpan(
                          text: formatCompactDate(bill.dueDate),
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w400,
                            color: isOverdue ? const Color(0xFFDC2626) : null,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text.rich(
                    TextSpan(
                      text: 'Paid On: ',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                      children: <InlineSpan>[
                        TextSpan(
                          text: bill.paidDate != null
                              ? formatCompactDate(bill.paidDate!)
                              : 'Not Paid Yet',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w400,
                            color: bill.paidDate != null
                                ? const Color(0xFF16A34A)
                                : const Color(0xFFDC2626),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
          ] else ...<Widget>[
            _SectionHeading(title: 'Details'),
            const SizedBox(height: 10),
            _BillDetailGrid(
              items: <_BillGridItem>[
                if (bill.billDate != null)
                  _BillGridItem(
                    icon: Icons.calendar_today_outlined,
                    label: 'Bill Date',
                    value: formatCompactDate(bill.billDate!),
                  ),
                _BillGridItem(
                  icon: Icons.event_outlined,
                  label: 'Due Date',
                  value: formatCompactDate(bill.dueDate),
                  valueColor: isOverdue ? const Color(0xFFDC2626) : null,
                ),
                if (bill.paidDate != null)
                  _BillGridItem(
                    icon: Icons.check_circle_outline,
                    label: 'Paid On',
                    value: formatCompactDate(bill.paidDate!),
                    valueColor: bill.status == BillStatus.paid
                        ? const Color(0xFF16A34A)
                        : const Color(0xFFDC2626),
                  ),
                if (bill.paymentType != null)
                  _BillGridItem(
                    icon: Icons.payment_outlined,
                    label: 'Payment Mode',
                    value: _paymentTypeLabel(bill.paymentType!),
                  ),
                if (bill.manualOnlinePaymentMode != null)
                  _BillGridItem(
                    icon: Icons.phone_android_outlined,
                    label: 'Online Mode',
                    value:
                        _manualOnlinePaymentModes[bill
                            .manualOnlinePaymentMode!] ??
                        'Other',
                  ),
                if ((bill.paymentNote ?? '').isNotEmpty)
                  _BillGridItem(
                    icon: Icons.notes_outlined,
                    label: 'Payment Note',
                    value: bill.paymentNote!,
                  ),
              ],
            ),
            const SizedBox(height: 20),
          ],

          // ── 4. Context / Contract Details ─────────────────────
          if (isTenantFlow) ...<Widget>[
            _SectionHeading(title: 'Contract Details'),
            const SizedBox(height: 12),
            if ((bill.propertyTitle ?? '').isNotEmpty)
              _ContractDetailRow(label: 'Property', value: bill.propertyTitle!),
            _ContractDetailRow(label: 'Flat/Unit', value: bill.unitLabel),
            if ((bill.ownerName ?? '').isNotEmpty)
              _ContractDetailRow(label: 'Owner', value: bill.ownerName!),
            if ((bill.ownerPhone ?? '').isNotEmpty)
              _ContractDetailRow(label: 'Owner Phone', value: bill.ownerPhone!),
            if ((bill.ownerEmail ?? '').isNotEmpty)
              _ContractDetailRow(label: 'Owner Email', value: bill.ownerEmail!),
            if (bill.rentAmount != null && bill.billTypeCode != 3)
              _ContractDetailRow(
                label: 'Monthly Rent',
                value: '\u20B9${bill.rentAmount!.toStringAsFixed(0)}',
              ),
            if (bill.contractStartDate != null && bill.contractEndDate != null)
              _ContractDetailRow(
                label: 'Contract Period',
                value:
                    '${formatCompactDate(bill.contractStartDate!)} - ${formatCompactDate(bill.contractEndDate!)}',
              ),
            if (bill.contractStartDate != null || bill.contractEndDate != null)
              _ContractDetailRow(
                label: 'Contract Status',
                value:
                    (bill.contractEndDate != null &&
                        bill.contractEndDate!.isAfter(DateTime.now()))
                    ? 'Active'
                    : 'Expired',
              ),
            const SizedBox(height: 20),
          ] else if ((bill.societyName ?? '').isNotEmpty ||
              (bill.propertyTitle ?? '').isNotEmpty ||
              (bill.ownerName ?? '').isNotEmpty) ...<Widget>[
            _SectionHeading(title: 'Context'),
            const SizedBox(height: 10),
            _BillDetailGrid(
              items: <_BillGridItem>[
                if ((bill.societyName ?? '').isNotEmpty)
                  _BillGridItem(
                    icon: Icons.business_outlined,
                    label: 'Society',
                    value: bill.societyName!,
                  ),
                if ((bill.blockName ?? '').isNotEmpty)
                  _BillGridItem(
                    icon: Icons.domain_outlined,
                    label: 'Block',
                    value: bill.blockName!,
                  ),
                if ((bill.buildingName ?? '').isNotEmpty)
                  _BillGridItem(
                    icon: Icons.apartment_outlined,
                    label: 'Building',
                    value: bill.buildingName!,
                  ),
                _BillGridItem(
                  icon: Icons.home_outlined,
                  label: 'Flat/Unit',
                  value: bill.unitLabel,
                ),
                if ((bill.propertyTitle ?? '').isNotEmpty)
                  _BillGridItem(
                    icon: Icons.location_city_outlined,
                    label: 'Property',
                    value: bill.propertyTitle!,
                  ),
                if ((bill.ownerName ?? '').isNotEmpty)
                  _BillGridItem(
                    icon: Icons.person_outline,
                    label: 'Owner',
                    value: bill.ownerName!,
                  ),
                if ((bill.ownerPhone ?? '').isNotEmpty)
                  _BillGridItem(
                    icon: Icons.phone_outlined,
                    label: 'Owner Phone',
                    value: bill.ownerPhone!,
                  ),
                if ((bill.ownerEmail ?? '').isNotEmpty)
                  _BillGridItem(
                    icon: Icons.email_outlined,
                    label: 'Owner Email',
                    value: bill.ownerEmail!,
                  ),
              ],
            ),
            const SizedBox(height: 20),
          ],

          // ── 5. Amount Breakdown ────────────────────────────────
          _SectionHeading(title: 'Amount Breakdown'),
          const SizedBox(height: 10),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFF9FAFB),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              children: <Widget>[
                // Bill type 3 = Security Deposit, 2 = Rental Amount
                if (bill.billAmount != null)
                  _BreakdownRow(
                    label: bill.billTypeCode == 3
                        ? 'Security Deposit Amount'
                        : 'Bill Amount',
                    value: 'Rs ${bill.billAmount!.toStringAsFixed(0)}',
                  ),
                if ((bill.maintenanceAmount ?? 0) > 0 && bill.billTypeCode != 3)
                  _BreakdownRow(
                    label: 'Maintenance',
                    value: 'Rs ${bill.maintenanceAmount!.toStringAsFixed(0)}',
                  ),
                if ((bill.tokenAmount ?? 0) > 0)
                  _BreakdownRow(
                    label: 'Token',
                    value: 'Rs ${bill.tokenAmount!.toStringAsFixed(0)}',
                  ),
                // Show Rent only for rental bills, not security deposit
                if (bill.rentAmount != null && bill.billTypeCode != 3)
                  _BreakdownRow(
                    label: 'Rent',
                    value: 'Rs ${bill.rentAmount!.toStringAsFixed(0)}',
                  ),
                // Show Security Deposit from contract only for non-security-deposit bills
                if (bill.depositAmount != null && bill.billTypeCode != 3)
                  _BreakdownRow(
                    label: 'Security Deposit',
                    value: 'Rs ${bill.depositAmount!.toStringAsFixed(0)}',
                  ),
                const Divider(height: 20),
                _BreakdownRow(
                  label: 'Final Amount',
                  value:
                      'Rs ${(bill.finalAmount ?? bill.amount).toStringAsFixed(0)}',
                  isBold: true,
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // ── 6. Wallet Credit ───────────────────────────────────
          if (bill.walletCredited != null) ...<Widget>[
            _SectionHeading(title: 'Wallet Credit'),
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: bill.walletCredited!
                    ? const Color(0xFFF0FDF4)
                    : const Color(0xFFFFFBEB),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  ToneBadge(
                    label: bill.walletCredited! ? 'Credited' : 'Pending',
                    tone: bill.walletCredited!
                        ? UiTone.success
                        : UiTone.warning,
                  ),
                  if (bill.walletCreditTime != null) ...<Widget>[
                    const SizedBox(height: 8),
                    Text(
                      'Initiated: ${formatCompactDate(bill.walletCreditTime!)} ${formatClock(bill.walletCreditTime!)}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ],
                  if (bill.walletCreditedTime != null) ...<Widget>[
                    const SizedBox(height: 4),
                    Text(
                      'Credited: ${formatCompactDate(bill.walletCreditedTime!)} ${formatClock(bill.walletCreditedTime!)}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 20),
          ],

          // ── 7. Payment Proof Image ─────────────────────────────
          if (hasImage) ...<Widget>[
            _SectionHeading(title: 'Payment Proof'),
            const SizedBox(height: 10),
            GestureDetector(
              onTap: () => FullScreenImageViewer.show(
                context,
                imageUrl: bill.paymentImageUrl!,
              ),
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFF9FAFB),
                  border: Border.all(color: AppTheme.border),
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: const EdgeInsets.all(8),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxHeight: 250),
                    child: Image.network(
                      bill.paymentImageUrl!,
                      width: double.infinity,
                      fit: BoxFit.contain,
                      errorBuilder: (_, __, ___) => Container(
                        height: 180,
                        color: AppTheme.surfaceMuted,
                        alignment: Alignment.center,
                        child: const Text('Unable to load payment proof'),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],

          // ── 8. Actions ─────────────────────────────────────────
          if (isTenantFlow && onDownloadReceipt != null)
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: onDownloadReceipt,
                icon: const Icon(Icons.download_outlined, size: 18),
                label: const Text('Download Receipt'),
              ),
            ),
          if (isTenantFlow && onContactOwner != null) ...<Widget>[
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: onContactOwner,
                icon: const Icon(Icons.phone_outlined, size: 18),
                label: const Text('Contact Owner'),
              ),
            ),
          ],
          if (isPmFlow && onContactTenant != null) ...<Widget>[
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: onContactTenant,
                icon: const Icon(Icons.phone_outlined, size: 18),
                label: const Text('Contact Tenant'),
              ),
            ),
          ],
          if (canRecordPayment && onRecordPayment != null) ...<Widget>[
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: onRecordPayment,
                icon: const Icon(Icons.receipt_long_outlined, size: 18),
                label: const Text('Record Payment'),
              ),
            ),
          ],
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: FilledButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

// ─── Section heading ──────────────────────────────────────────────────────

class _SectionHeading extends StatelessWidget {
  const _SectionHeading({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: Theme.of(
        context,
      ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
    );
  }
}

// ─── Bill detail 2-column grid ────────────────────────────────────────────

class _BillGridItem {
  const _BillGridItem({
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;
}

class _BillDetailGrid extends StatelessWidget {
  const _BillDetailGrid({required this.items});

  final List<_BillGridItem> items;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const SizedBox.shrink();

    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: items.map((_BillGridItem item) {
        return SizedBox(
          width: (MediaQuery.of(context).size.width - 44) / 2,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Icon(item.icon, size: 18, color: AppTheme.textMuted),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      item.label,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppTheme.textMuted,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      item.value,
                      style: Theme.of(
                        context,
                      ).textTheme.bodyMedium?.copyWith(color: item.valueColor),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

// ─── Amount breakdown row ─────────────────────────────────────────────────

class _BreakdownRow extends StatelessWidget {
  const _BreakdownRow({
    required this.label,
    required this.value,
    this.isBold = false,
  });

  final String label;
  final String value;
  final bool isBold;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: <Widget>[
          Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: isBold ? null : AppTheme.textSecondary,
              fontWeight: isBold ? FontWeight.w700 : null,
            ),
          ),
          Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontWeight: isBold ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Contract detail row (simple label: value) ───────────────────────────

class _ContractDetailRow extends StatelessWidget {
  const _ContractDetailRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text.rich(
        TextSpan(
          text: '$label: ',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: AppTheme.textSecondary,
            fontWeight: FontWeight.w600,
          ),
          children: <InlineSpan>[
            TextSpan(
              text: value,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w400),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Private widgets
// ---------------------------------------------------------------------------
class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.label,
    required this.value,
    required this.tone,
  });

  final String label;
  final String value;
  final UiTone tone;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 146,
      child: CustomCard(
        padding: CustomCardPadding.sm,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            ToneBadge(label: label, tone: tone, size: ToneBadgeSize.small),
            const SizedBox(height: 14),
            Text(
              value,
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
            ),
          ],
        ),
      ),
    );
  }
}

class _MetaItem extends StatelessWidget {
  const _MetaItem({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          label,
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: AppTheme.textMuted),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: Theme.of(
            context,
          ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
        ),
      ],
    );
  }
}
