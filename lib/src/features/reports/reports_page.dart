import 'package:flutter/material.dart';

import '../../core/api/notification_service.dart';
import '../../core/api/vendor_service.dart';
import '../../core/models/api_models.dart';
import '../../core/models/app_models.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/custom_card.dart';
import '../../core/widgets/page_header.dart';
import '../../core/widgets/tone_badge.dart';

class ReportsPage extends StatefulWidget {
  const ReportsPage({super.key});

  @override
  State<ReportsPage> createState() => _ReportsPageState();
}

class _ReportsPageState extends State<ReportsPage> {
  VendorData? _vendor;
  int _notificationCount = 0;
  bool _isLoading = true;
  String? _errorMessage;

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
      final VendorData? vendor = await VendorService.fetchVendorInfo();
      final notifications = await NotificationService.filterNotifications(
        limit: 100,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _vendor = vendor;
        _notificationCount = notifications.count;
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
    final BillCollectionSummaryData? billSummary =
        _vendor?.billCollectionSummary;
    final SupportTicketSummaryData? supportSummary =
        _vendor?.supportTicketSummary;
    final PropertySummaryData? propertySummary = _vendor?.propertySummary;
    final RentalContractSummaryData? contractSummary =
        _vendor?.rentalContractSummary;

    final List<_ReportMetric> metrics = switch (_vendor?.vendorType) {
      1 => <_ReportMetric>[
          _ReportMetric(
            title: 'Collected',
            value: _formatCurrency(billSummary?.currentMonthCollected ?? 0),
            subtitle: 'Current month collections',
            tone: UiTone.success,
          ),
          _ReportMetric(
            title: 'Pending',
            value: _formatCurrency(billSummary?.currentMonthPending ?? 0),
            subtitle: 'Current month pending bills',
            tone: UiTone.warning,
          ),
          _ReportMetric(
            title: 'Open Tickets',
            value: '${supportSummary?.openTicketsCount ?? 0}',
            subtitle: '${supportSummary?.criticalOpenTicketsCount ?? 0} critical',
            tone: UiTone.brand,
          ),
          _ReportMetric(
            title: 'Activity',
            value: '$_notificationCount',
            subtitle: 'Vendor notification records',
            tone: UiTone.neutral,
          ),
        ],
      2 => <_ReportMetric>[
          _ReportMetric(
            title: 'Properties',
            value: '${propertySummary?.totalPropertiesCount ?? 0}',
            subtitle: '${propertySummary?.approvedPropertiesCount ?? 0} approved',
            tone: UiTone.brand,
          ),
          _ReportMetric(
            title: 'Contracts',
            value: '${contractSummary?.activeContractsCount ?? 0}',
            subtitle: '${contractSummary?.pendingRenewalCount ?? 0} near renewal',
            tone: UiTone.success,
          ),
          _ReportMetric(
            title: 'Monthly Rent',
            value: _formatCurrency(contractSummary?.totalMonthlyRent ?? 0),
            subtitle: 'Active contract rent value',
            tone: UiTone.neutral,
          ),
          _ReportMetric(
            title: 'Outstanding',
            value: _formatCurrency(billSummary?.currentMonthPending ?? 0),
            subtitle: 'Pending bill amount',
            tone: UiTone.warning,
          ),
        ],
      _ => <_ReportMetric>[
          _ReportMetric(
            title: 'Activity',
            value: '$_notificationCount',
            subtitle: 'Vendor notification records',
            tone: UiTone.brand,
          ),
        ],
    };

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 16,
        title: const Text('Reports'),
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
            const PageHeader(
              title: 'Reports and Analytics',
              description:
                  'Website reports were mock-driven; this mobile screen uses live vendor summaries from the backend.',
            ),
            const SizedBox(height: 16),
            if (_isLoading)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 64),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_errorMessage != null)
              CustomCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      'Unable to load analytics',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _errorMessage!,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppTheme.textSecondary,
                          ),
                    ),
                  ],
                ),
              )
            else ...<Widget>[
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: metrics.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 1.15,
                ),
                itemBuilder: (BuildContext context, int index) {
                  final _ReportMetric metric = metrics[index];
                  return CustomCard(
                    padding: CustomCardPadding.sm,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        ToneBadge(
                          label: metric.title,
                          tone: metric.tone,
                          size: ToneBadgeSize.small,
                        ),
                        const Spacer(),
                        Text(
                          metric.value,
                          style: Theme.of(context).textTheme.headlineSmall
                              ?.copyWith(fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          metric.subtitle,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: AppTheme.textSecondary,
                              ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _formatCurrency(double value) {
    if (value >= 100000) {
      return 'Rs ${(value / 100000).toStringAsFixed(1)}L';
    }
    if (value >= 1000) {
      return 'Rs ${(value / 1000).toStringAsFixed(1)}K';
    }
    return 'Rs ${value.toStringAsFixed(0)}';
  }
}

class _ReportMetric {
  const _ReportMetric({
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
