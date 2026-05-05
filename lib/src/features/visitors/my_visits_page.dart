import 'package:flutter/material.dart';

import '../../core/models/app_models.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/custom_button.dart';
import '../../core/widgets/custom_card.dart';
import '../../core/widgets/custom_tab_bar.dart';
import '../../core/widgets/page_header.dart';
import '../../core/widgets/tone_badge.dart';

class MyVisitsPage extends StatefulWidget {
  const MyVisitsPage({
    super.key,
    required this.visits,
  });

  final List<VisitorRecord> visits;

  @override
  State<MyVisitsPage> createState() => _MyVisitsPageState();
}

class _MyVisitsPageState extends State<MyVisitsPage> {
  final TextEditingController _searchController = TextEditingController();
  VisitStatus? _selectedFilter;
  late List<VisitorRecord> _visits;

  @override
  void initState() {
    super.initState();
    _visits = List<VisitorRecord>.from(widget.visits);
  }

  @override
  void didUpdateWidget(covariant MyVisitsPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.visits != widget.visits) {
      _visits = List<VisitorRecord>.from(widget.visits);
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final String search = _searchController.text.trim().toLowerCase();
    final List<VisitorRecord> visibleVisits = _visits.where((VisitorRecord item) {
      final bool matchesStatus =
          _selectedFilter == null || item.status == _selectedFilter;
      final bool matchesSearch = search.isEmpty ||
          item.name.toLowerCase().contains(search) ||
          item.host.toLowerCase().contains(search) ||
          item.unitLabel.toLowerCase().contains(search) ||
          item.purpose.toLowerCase().contains(search);
      return matchesStatus && matchesSearch;
    }).toList();

    final int scheduledCount = _visits
        .where((VisitorRecord item) => item.status == VisitStatus.scheduled)
        .length;
    final int activeCount = _visits
        .where(
          (VisitorRecord item) =>
              item.status == VisitStatus.waiting ||
              item.status == VisitStatus.approved ||
              item.status == VisitStatus.checkedIn,
        )
        .length;
    final int completedCount = _visits
        .where((VisitorRecord item) => item.status == VisitStatus.checkedOut)
        .length;

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 16,
        title: const Text('My Visits'),
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1, thickness: 1, color: AppTheme.border),
        ),
      ),
      body: ListView(
        padding: AppTheme.pagePadding,
        children: <Widget>[
          const PageHeader(
            title: 'My Visits',
            description:
                'Website-style visitor history with summary cards, search, status filters, and QR/pass details.',
          ),
          const SizedBox(height: 16),
          Row(
            children: <Widget>[
              Expanded(
                child: _VisitSummaryCard(
                  label: 'Scheduled',
                  value: '$scheduledCount',
                  tone: UiTone.brand,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _VisitSummaryCard(
                  label: 'Active',
                  value: '$activeCount',
                  tone: UiTone.warning,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _VisitSummaryCard(
                  label: 'Completed',
                  value: '$completedCount',
                  tone: UiTone.success,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              labelText: 'Search visits',
              suffixIcon: IconButton(
                onPressed: () => setState(() {}),
                icon: const Icon(Icons.search_rounded),
              ),
            ),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 16),
          CustomTabBar(
            style: CustomTabBarStyle.pill,
            currentIndex: _selectedFilter == null
                ? 0
                : VisitStatus.values.indexOf(_selectedFilter!) + 1,
            onChanged: (int index) {
              setState(() {
                _selectedFilter =
                    index == 0 ? null : VisitStatus.values[index - 1];
              });
            },
            tabs: <CustomTabItem>[
              const CustomTabItem(label: 'All'),
              ...VisitStatus.values.map(
                (VisitStatus status) => CustomTabItem(label: status.label),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (visibleVisits.isEmpty)
            const CustomCard(
              padding: CustomCardPadding.sm,
              child: Text('No visits match the current filters.'),
            )
          else
            ...visibleVisits.map((VisitorRecord visit) {
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
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: AppTheme.toneSoft(visit.status.tone),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              Icons.qr_code_scanner_outlined,
                              color: AppTheme.toneColor(visit.status.tone),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                Text(
                                  visit.name,
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Host: ${visit.host}',
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: AppTheme.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          ToneBadge(
                            label: visit.status.label,
                            tone: visit.status.tone,
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: <Widget>[
                          ToneBadge(label: visit.unitLabel, tone: UiTone.neutral),
                          ToneBadge(label: visit.purpose, tone: UiTone.brand),
                          ToneBadge(
                            label: formatCompactDate(visit.time),
                            tone: UiTone.neutral,
                          ),
                          ToneBadge(
                            label: formatClock(visit.time),
                            tone: UiTone.neutral,
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Row(
                        children: <Widget>[
                          Expanded(
                            child: CustomButton(
                              label: 'Details',
                              variant: CustomButtonVariant.outline,
                              onPressed: () => _showDetails(visit),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: CustomButton(
                              label: 'Show QR',
                              onPressed: () => _showQrSheet(visit),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            }),
        ],
      ),
    );
  }

  void _showDetails(VisitorRecord visit) {
    showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(visit.name),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              _VisitDetailLine(label: 'Host', value: visit.host),
              _VisitDetailLine(label: 'Unit', value: visit.unitLabel),
              _VisitDetailLine(label: 'Purpose', value: visit.purpose),
              _VisitDetailLine(
                label: 'Date',
                value: formatCompactDate(visit.time),
              ),
              _VisitDetailLine(
                label: 'Time',
                value: formatClock(visit.time),
              ),
              _VisitDetailLine(label: 'Status', value: visit.status.label),
              _VisitDetailLine(
                label: 'Pass ID',
                value: _accessCodeFor(visit),
              ),
            ],
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _showQrSheet(VisitorRecord visit) async {
    await showModalBottomSheet<void>(
      context: context,
      builder: (BuildContext context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  'Visit Pass',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Use this pass at the gate. The code below is generated from the current visit record linked to your account.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppTheme.textSecondary,
                      ),
                ),
                const SizedBox(height: 16),
                Center(
                  child: Container(
                    width: 180,
                    height: 180,
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceMuted,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppTheme.borderStrong),
                    ),
                    alignment: Alignment.center,
                    child: const Icon(
                      Icons.qr_code_2_rounded,
                      size: 120,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Center(
                  child: SelectableText(
                    _accessCodeFor(visit),
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.2,
                        ),
                  ),
                ),
                const SizedBox(height: 8),
                Center(
                  child: Text(
                    '${visit.host} | ${visit.unitLabel}',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppTheme.textSecondary,
                        ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  String _accessCodeFor(VisitorRecord visit) {
    final String suffix = visit.id.length > 8
        ? visit.id.substring(visit.id.length - 8).toUpperCase()
        : visit.id.toUpperCase();
    return 'UEF-$suffix';
  }
}

class _VisitSummaryCard extends StatelessWidget {
  const _VisitSummaryCard({
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
          const SizedBox(height: 14),
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

class _VisitDetailLine extends StatelessWidget {
  const _VisitDetailLine({
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
            width: 88,
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
