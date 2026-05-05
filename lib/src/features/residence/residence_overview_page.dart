import 'package:flutter/material.dart';

import '../../core/api/billing_service.dart';
import '../../core/api/rental_contract_service.dart';
import '../../core/models/app_models.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/custom_button.dart';
import '../../core/widgets/custom_card.dart';
import '../../core/widgets/page_header.dart';
import '../../core/widgets/tone_badge.dart';

enum ResidenceOverviewKind { myProperty, pgDetails }

class ResidenceOverviewPage extends StatefulWidget {
  const ResidenceOverviewPage({
    super.key,
    required this.kind,
  });

  final ResidenceOverviewKind kind;

  @override
  State<ResidenceOverviewPage> createState() => _ResidenceOverviewPageState();
}

class _ResidenceOverviewPageState extends State<ResidenceOverviewPage> {
  bool _isLoading = true;
  String? _errorMessage;
  List<RentalContractRecord> _contracts = <RentalContractRecord>[];
  List<BillRecord> _bills = <BillRecord>[];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final results = await Future.wait<dynamic>(<Future<dynamic>>[
        RentalContractService.filterTenantRentalContracts(limit: 100),
        BillingService.filterTenantBills(limit: 100),
      ]);

      if (!mounted) {
        return;
      }

      final contractsResult =
          results[0] as ({List<RentalContractRecord> contracts, int count});
      final billsResult = results[1] as ({List<BillRecord> bills, int count});

      setState(() {
        _contracts = contractsResult.contracts;
        _bills = billsResult.bills;
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

  RentalContractRecord? get _primaryContract {
    if (_contracts.isEmpty) {
      return null;
    }

    final List<RentalContractRecord> sorted = List<RentalContractRecord>.from(
      _contracts,
    )..sort((RentalContractRecord a, RentalContractRecord b) {
        int rank(RentalContractRecord item) {
          return switch (item.status) {
            ContractStatus.active => 0,
            ContractStatus.readyToVacate => 1,
            ContractStatus.expired => 2,
            ContractStatus.closed => 3,
          };
        }

        final int rankCompare = rank(a).compareTo(rank(b));
        if (rankCompare != 0) {
          return rankCompare;
        }
        return b.endDate.compareTo(a.endDate);
      });

    return sorted.first;
  }

  double get _pendingAmount {
    return _bills
        .where((BillRecord bill) =>
            bill.status == BillStatus.pending ||
            bill.status == BillStatus.overdue)
        .fold<double>(0, (double sum, BillRecord bill) => sum + bill.amount);
  }

  BillRecord? get _nextDueBill {
    final List<BillRecord> dueBills = _bills
        .where((BillRecord bill) =>
            bill.status == BillStatus.pending ||
            bill.status == BillStatus.overdue)
        .toList()
      ..sort((BillRecord a, BillRecord b) => a.dueDate.compareTo(b.dueDate));
    return dueBills.isEmpty ? null : dueBills.first;
  }

  @override
  Widget build(BuildContext context) {
    final RentalContractRecord? contract = _primaryContract;
    final bool isPg = widget.kind == ResidenceOverviewKind.pgDetails;
    final String title = isPg ? 'PG Details' : 'My Property';
    final String description = isPg
        ? 'Room, stay, contract, and billing details pulled from your live tenant data.'
        : 'Current residence, contract, and billing summary pulled from your live tenant data.';

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 16,
        title: Text(title),
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1, thickness: 1, color: AppTheme.border),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _loadData,
        child: ListView(
          padding: AppTheme.pagePadding,
          children: <Widget>[
            PageHeader(
              title: title,
              description: description,
              trailing: CustomButton(
                label: 'Refresh',
                variant: CustomButtonVariant.outline,
                icon: const Icon(Icons.refresh_rounded),
                onPressed: _isLoading ? null : _loadData,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: <Widget>[
                Expanded(
                  child: _OverviewMetricCard(
                    label: isPg ? 'Stay Status' : 'Residence Status',
                    value: contract?.status.label ?? 'No contract',
                    tone: contract?.status.tone ?? UiTone.warning,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _OverviewMetricCard(
                    label: 'Pending Bills',
                    value: 'Rs ${_pendingAmount.toStringAsFixed(0)}',
                    tone: _pendingAmount > 0 ? UiTone.warning : UiTone.success,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: <Widget>[
                Expanded(
                  child: _OverviewMetricCard(
                    label: isPg ? 'Room Records' : 'Contracts',
                    value: '${_contracts.length}',
                    tone: UiTone.brand,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _OverviewMetricCard(
                    label: 'Bills',
                    value: '${_bills.length}',
                    tone: UiTone.neutral,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (_isLoading)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 64),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_errorMessage != null)
              _OverviewMessageCard(
                title: 'Unable to load details',
                message: _errorMessage!,
                tone: UiTone.danger,
              )
            else ...<Widget>[
              CustomCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      isPg ? 'Current Stay' : 'Current Residence',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    const SizedBox(height: 12),
                    if (contract == null)
                      Text(
                        isPg
                            ? 'No PG stay contract is available yet for this account.'
                            : 'No active property contract is available yet for this account.',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: AppTheme.textSecondary,
                            ),
                      )
                    else ...<Widget>[
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                Text(
                                  contract.propertyTitle,
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleLarge
                                      ?.copyWith(fontWeight: FontWeight.w700),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  isPg
                                      ? 'Room ${contract.flatNo ?? 'N/A'}'
                                      : 'Unit ${contract.flatNo ?? 'N/A'}',
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodyMedium
                                      ?.copyWith(
                                        color: AppTheme.textSecondary,
                                      ),
                                ),
                              ],
                            ),
                          ),
                          ToneBadge(
                            label: contract.status.label,
                            tone: contract.status.tone,
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: <Widget>[
                          ToneBadge(
                            label: 'Rent Rs ${contract.rent.toStringAsFixed(0)}',
                            tone: UiTone.brand,
                          ),
                          ToneBadge(
                            label:
                                'Deposit Rs ${contract.deposit.toStringAsFixed(0)}',
                            tone: UiTone.neutral,
                          ),
                          ToneBadge(
                            label:
                                '${formatCompactDate(contract.startDate)} to ${formatCompactDate(contract.endDate)}',
                            tone: UiTone.success,
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      _OverviewLine(
                        label: isPg ? 'Resident' : 'Tenant',
                        value: contract.tenantName,
                      ),
                      _OverviewLine(
                        label: 'Owner',
                        value: contract.ownerName,
                      ),
                      if ((contract.tenantPhone ?? '').isNotEmpty)
                        _OverviewLine(
                          label: isPg ? 'Resident Phone' : 'Tenant Phone',
                          value: contract.tenantPhone!,
                        ),
                      if ((contract.ownerPhone ?? '').isNotEmpty)
                        _OverviewLine(
                          label: 'Owner Phone',
                          value: contract.ownerPhone!,
                        ),
                      if ((contract.ownerAddress ?? '').isNotEmpty)
                        _OverviewLine(
                          label: 'Owner Address',
                          value: contract.ownerAddress!,
                        ),
                      if ((contract.specialTerms ?? '').isNotEmpty)
                        _OverviewLine(
                          label: isPg ? 'Stay Notes' : 'Special Terms',
                          value: contract.specialTerms!,
                        ),
                      if (contract.vacateDate != null)
                        _OverviewLine(
                          label: 'Vacate Date',
                          value: formatCompactDate(contract.vacateDate!),
                        ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 12),
              CustomCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      'Billing Snapshot',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    const SizedBox(height: 12),
                    if (_bills.isEmpty)
                      Text(
                        'No bills are linked to this account yet.',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: AppTheme.textSecondary,
                            ),
                      )
                    else ...<Widget>[
                      _OverviewLine(
                        label: 'Total bills',
                        value: '${_bills.length}',
                      ),
                      _OverviewLine(
                        label: 'Pending amount',
                        value: 'Rs ${_pendingAmount.toStringAsFixed(0)}',
                      ),
                      _OverviewLine(
                        label: 'Paid bills',
                        value:
                            '${_bills.where((BillRecord bill) => bill.status == BillStatus.paid).length}',
                      ),
                      if (_nextDueBill != null)
                        _OverviewLine(
                          label: 'Next due',
                          value:
                              '${_nextDueBill!.title} on ${formatCompactDate(_nextDueBill!.dueDate)}',
                        ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 12),
              CustomCard(
                color: AppTheme.primarySoft,
                borderColor: AppTheme.primaryTone,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      isPg ? 'PG Access Notes' : 'Residence Notes',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      isPg
                          ? 'Use Rental Contracts for vacate requests and KYC documents, and use Bills for payment actions.'
                          : 'Use Rental Contracts for lease changes and vacate requests, and use Bills for payment actions.',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppTheme.textSecondary,
                          ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _OverviewMetricCard extends StatelessWidget {
  const _OverviewMetricCard({
    required this.label,
    required this.value,
    required this.tone,
  });

  final String label;
  final String value;
  final UiTone tone;

  @override
  Widget build(BuildContext context) {
    return CustomCard(
      padding: CustomCardPadding.sm,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          ToneBadge(label: label, tone: tone, size: ToneBadgeSize.small),
          const SizedBox(height: 12),
          Text(
            value,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
        ],
      ),
    );
  }
}

class _OverviewLine extends StatelessWidget {
  const _OverviewLine({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          SizedBox(
            width: 108,
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppTheme.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}

class _OverviewMessageCard extends StatelessWidget {
  const _OverviewMessageCard({
    required this.title,
    required this.message,
    required this.tone,
  });

  final String title;
  final String message;
  final UiTone tone;

  @override
  Widget build(BuildContext context) {
    return CustomCard(
      color: AppTheme.toneSoft(tone),
      borderColor: AppTheme.toneColor(tone).withValues(alpha: 0.2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          ToneBadge(label: title, tone: tone),
          const SizedBox(height: 10),
          Text(
            message,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppTheme.textSecondary,
                ),
          ),
        ],
      ),
    );
  }
}
