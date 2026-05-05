import 'package:flutter/material.dart';

import '../../core/models/app_models.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/custom_button.dart';
import '../../core/widgets/custom_card.dart';
import '../../core/widgets/custom_tab_bar.dart';
import '../../core/widgets/page_header.dart';
import '../../core/widgets/tone_badge.dart';

class VisitorsPage extends StatefulWidget {
  const VisitorsPage({super.key, required this.role, required this.visitors});

  final AppRole role;
  final List<VisitorRecord> visitors;

  @override
  State<VisitorsPage> createState() => _VisitorsPageState();
}

class _VisitorsPageState extends State<VisitorsPage> {
  final TextEditingController _searchController = TextEditingController();
  VisitStatus? _selectedFilter;
  List<VisitorRecord> _visitors = <VisitorRecord>[];

  bool get _canCreateVisitor => widget.role != AppRole.visitor;

  @override
  void initState() {
    super.initState();
    _visitors = List<VisitorRecord>.from(widget.visitors);
  }

  @override
  void didUpdateWidget(covariant VisitorsPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.visitors != widget.visitors) {
      _visitors = List<VisitorRecord>.from(widget.visitors);
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
    final List<VisitorRecord> visibleVisitors = _visitors.where((
      VisitorRecord visitor,
    ) {
      final bool matchesFilter =
          _selectedFilter == null || visitor.status == _selectedFilter;
      final bool matchesSearch = search.isEmpty ||
          visitor.name.toLowerCase().contains(search) ||
          visitor.host.toLowerCase().contains(search) ||
          visitor.unitLabel.toLowerCase().contains(search) ||
          visitor.purpose.toLowerCase().contains(search);
      return matchesFilter && matchesSearch;
    }).toList();

    final int waitingCount = _visitors
        .where((VisitorRecord item) => item.status == VisitStatus.waiting)
        .length;
    final int activeCount = _visitors
        .where(
          (VisitorRecord item) =>
              item.status == VisitStatus.approved ||
              item.status == VisitStatus.checkedIn,
        )
        .length;
    final int completedCount = _visitors
        .where((VisitorRecord item) => item.status == VisitStatus.checkedOut)
        .length;

    return ListView(
      padding: AppTheme.pagePadding,
      children: <Widget>[
        PageHeader(
          title: widget.role.visitorSectionTitle,
          description: widget.role == AppRole.visitor
              ? 'Track scheduled, active, and completed visits with pass details and QR access.'
              : 'Manage guests, deliveries, and gate approvals with search, status filters, and quick actions.',
          trailing: _canCreateVisitor
              ? CustomButton(
                  label: 'Add Visitor',
                  size: CustomButtonSize.sm,
                  icon: const Icon(Icons.person_add_alt_1_outlined),
                  onPressed: _openAddVisitorSheet,
                )
              : null,
        ),
        const SizedBox(height: 16),
        Row(
          children: <Widget>[
            Expanded(
              child: _VisitorSummaryCard(
                label: 'Waiting',
                value: '$waitingCount',
                tone: UiTone.warning,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _VisitorSummaryCard(
                label: 'Active',
                value: '$activeCount',
                tone: UiTone.brand,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _VisitorSummaryCard(
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
            labelText: widget.role == AppRole.visitor
                ? 'Search visits'
                : 'Search by visitor, host, unit, or purpose',
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
              _selectedFilter = index == 0
                  ? null
                  : VisitStatus.values[index - 1];
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
        if (visibleVisitors.isEmpty)
          const CustomCard(
            padding: CustomCardPadding.sm,
            child: Text('No visitor records match the current filters.'),
          ),
        ...visibleVisitors.map((VisitorRecord visitor) {
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
                          color: AppTheme.toneSoft(visitor.status.tone),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          widget.role == AppRole.visitor
                              ? Icons.qr_code_scanner_outlined
                              : Icons.person_outline,
                          color: AppTheme.toneColor(visitor.status.tone),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text(
                              visitor.name,
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              widget.role == AppRole.visitor
                                  ? 'Host: ${visitor.host}'
                                  : 'Host: ${visitor.host}',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: AppTheme.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      ToneBadge(
                        label: visitor.status.label,
                        tone: visitor.status.tone,
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: <Widget>[
                      _InfoBadge(
                        icon: Icons.location_on_outlined,
                        text: visitor.unitLabel,
                      ),
                      _InfoBadge(
                        icon: Icons.assignment_outlined,
                        text: visitor.purpose,
                      ),
                      _InfoBadge(
                        icon: Icons.event_outlined,
                        text: formatCompactDate(visitor.time),
                      ),
                      _InfoBadge(
                        icon: Icons.access_time_outlined,
                        text: formatClock(visitor.time),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: visitor.preApproved
                          ? AppTheme.toneSoft(UiTone.success)
                          : AppTheme.toneSoft(UiTone.warning),
                      borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                    ),
                    child: Row(
                      children: <Widget>[
                        Icon(
                          visitor.preApproved
                              ? Icons.verified_outlined
                              : Icons.pending_outlined,
                          size: 18,
                          color: AppTheme.toneColor(
                            visitor.preApproved
                                ? UiTone.success
                                : UiTone.warning,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            visitor.preApproved
                                ? 'Pre-approved before arrival'
                                : 'Approval still required at the gate',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: AppTheme.textSecondary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: <Widget>[
                      Expanded(
                        child: CustomButton(
                          label: 'Details',
                          variant: CustomButtonVariant.outline,
                          onPressed: () => _showDetails(context, visitor),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: CustomButton(
                          label: widget.role == AppRole.visitor
                              ? 'Show QR'
                              : _primaryActionLabel(visitor),
                          onPressed: () => _openVisitorAction(context, visitor),
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
    );
  }

  String _primaryActionLabel(VisitorRecord visitor) {
    return switch (visitor.status) {
      VisitStatus.waiting => 'Approve',
      VisitStatus.approved => 'Check In',
      VisitStatus.checkedIn => 'Check Out',
      VisitStatus.scheduled => 'Update',
      VisitStatus.checkedOut => 'Reopen',
      VisitStatus.denied => 'Reopen',
      VisitStatus.cancelled => 'Reopen',
    };
  }

  void _showDetails(BuildContext context, VisitorRecord visitor) {
    showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(visitor.name),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              _VisitorDetailLine(label: 'Host', value: visitor.host),
              _VisitorDetailLine(label: 'Unit', value: visitor.unitLabel),
              _VisitorDetailLine(label: 'Purpose', value: visitor.purpose),
              _VisitorDetailLine(
                label: 'Date',
                value: formatCompactDate(visitor.time),
              ),
              _VisitorDetailLine(
                label: 'Time',
                value: formatClock(visitor.time),
              ),
              _VisitorDetailLine(label: 'Status', value: visitor.status.label),
              _VisitorDetailLine(
                label: 'Approval',
                value: visitor.preApproved
                    ? 'Pre-approved before arrival'
                    : 'Approval required at gate',
              ),
              _VisitorDetailLine(
                label: 'Pass ID',
                value: _accessCodeFor(visitor),
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

  Future<void> _openVisitorAction(
    BuildContext context,
    VisitorRecord visitor,
  ) async {
    if (widget.role == AppRole.visitor) {
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
                    'Visitor QR Access',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Use this visit pass at the gate for the selected visit record.',
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
                      _accessCodeFor(visitor),
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.2,
                          ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Center(
                    child: Text(
                      '${visitor.host} | ${visitor.unitLabel}',
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
      return;
    }

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
                  'Update Visitor',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Move this visitor through the current gate-access flow.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppTheme.textSecondary,
                      ),
                ),
                const SizedBox(height: 16),
                ..._availableStatuses(visitor).map((VisitStatus status) {
                  final bool selected = visitor.status == status;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: CustomCard(
                      padding: CustomCardPadding.sm,
                      onTap: () {
                        setState(() {
                          _replaceVisitor(
                            visitor,
                            VisitorRecord(
                              id: visitor.id,
                              name: visitor.name,
                              host: visitor.host,
                              unitLabel: visitor.unitLabel,
                              purpose: visitor.purpose,
                              time: visitor.time,
                              status: status,
                              preApproved: visitor.preApproved ||
                                  status == VisitStatus.approved ||
                                  status == VisitStatus.checkedIn ||
                                  status == VisitStatus.checkedOut,
                            ),
                          );
                        });
                        Navigator.of(context).pop();
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              '${visitor.name} updated to ${status.label}.',
                            ),
                          ),
                        );
                      },
                      child: Row(
                        children: <Widget>[
                          Expanded(
                            child: Text(
                              status.label,
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(fontWeight: FontWeight.w600),
                            ),
                          ),
                          ToneBadge(label: status.label, tone: status.tone),
                          if (selected) ...<Widget>[
                            const SizedBox(width: 10),
                            const Icon(
                              Icons.check_circle_rounded,
                              color: AppTheme.primary,
                            ),
                          ],
                        ],
                      ),
                    ),
                  );
                }),
              ],
            ),
          ),
        );
      },
    );
  }

  List<VisitStatus> _availableStatuses(VisitorRecord visitor) {
    return switch (visitor.status) {
      VisitStatus.waiting => <VisitStatus>[
          VisitStatus.approved,
          VisitStatus.denied,
          VisitStatus.cancelled,
        ],
      VisitStatus.approved => <VisitStatus>[
          VisitStatus.checkedIn,
          VisitStatus.denied,
          VisitStatus.cancelled,
        ],
      VisitStatus.checkedIn => <VisitStatus>[
          VisitStatus.checkedOut,
          VisitStatus.cancelled,
        ],
      VisitStatus.scheduled => <VisitStatus>[
          VisitStatus.waiting,
          VisitStatus.approved,
          VisitStatus.cancelled,
        ],
      VisitStatus.checkedOut || VisitStatus.denied || VisitStatus.cancelled =>
        <VisitStatus>[
          VisitStatus.waiting,
          VisitStatus.scheduled,
        ],
    };
  }

  Future<void> _openAddVisitorSheet() async {
    final TextEditingController nameController = TextEditingController();
    final TextEditingController hostController = TextEditingController();
    final TextEditingController unitController = TextEditingController();
    final TextEditingController purposeController = TextEditingController();
    DateTime scheduledAt = DateTime.now().add(const Duration(hours: 1));
    bool preApproved = true;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            Future<void> pickDateTime() async {
              final DateTime now = DateTime.now();
              final DateTime? pickedDate = await showDatePicker(
                context: context,
                initialDate: scheduledAt,
                firstDate: now.subtract(const Duration(days: 30)),
                lastDate: now.add(const Duration(days: 365)),
              );
              if (pickedDate == null || !mounted) {
                return;
              }
              final TimeOfDay? pickedTime = await showTimePicker(
                context: context,
                initialTime: TimeOfDay.fromDateTime(scheduledAt),
              );
              if (pickedTime == null || !mounted) {
                return;
              }
              setModalState(() {
                scheduledAt = DateTime(
                  pickedDate.year,
                  pickedDate.month,
                  pickedDate.day,
                  pickedTime.hour,
                  pickedTime.minute,
                );
              });
            }

            void submit() {
              if (nameController.text.trim().isEmpty ||
                  hostController.text.trim().isEmpty ||
                  unitController.text.trim().isEmpty ||
                  purposeController.text.trim().isEmpty) {
                return;
              }

              setState(() {
                _visitors.insert(
                  0,
                  VisitorRecord(
                    id: 'visitor-${DateTime.now().millisecondsSinceEpoch}',
                    name: nameController.text.trim(),
                    host: hostController.text.trim(),
                    unitLabel: unitController.text.trim(),
                    purpose: purposeController.text.trim(),
                    time: scheduledAt,
                    status: preApproved
                        ? VisitStatus.approved
                        : VisitStatus.waiting,
                    preApproved: preApproved,
                  ),
                );
              });

              Navigator.of(context).pop();
              ScaffoldMessenger.of(this.context).showSnackBar(
                const SnackBar(content: Text('Visitor added locally.')),
              );
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
                      'Add Visitor',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: nameController,
                      decoration:
                          const InputDecoration(labelText: 'Visitor name'),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: hostController,
                      decoration: const InputDecoration(labelText: 'Host name'),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: unitController,
                      decoration: const InputDecoration(labelText: 'Unit label'),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: purposeController,
                      decoration: const InputDecoration(labelText: 'Purpose'),
                    ),
                    const SizedBox(height: 12),
                    CustomCard(
                      padding: CustomCardPadding.sm,
                      onTap: pickDateTime,
                      child: Row(
                        children: <Widget>[
                          const Icon(Icons.event_outlined),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              '${formatCompactDate(scheduledAt)} at ${formatClock(scheduledAt)}',
                            ),
                          ),
                          const Icon(Icons.edit_calendar_outlined),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    SwitchListTile(
                      value: preApproved,
                      onChanged: (bool value) {
                        setModalState(() {
                          preApproved = value;
                        });
                      },
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Pre-approved'),
                      subtitle: const Text(
                        'Turn off to keep the visitor in waiting state.',
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: <Widget>[
                        Expanded(
                          child: CustomButton(
                            label: 'Cancel',
                            variant: CustomButtonVariant.outline,
                            onPressed: () => Navigator.of(context).pop(),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: CustomButton(
                            label: 'Save Visitor',
                            onPressed: submit,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );

    nameController.dispose();
    hostController.dispose();
    unitController.dispose();
    purposeController.dispose();
  }

  void _replaceVisitor(VisitorRecord source, VisitorRecord updated) {
    final int index = _visitors.indexWhere(
      (VisitorRecord item) => item.id == source.id,
    );
    if (index < 0) {
      return;
    }
    _visitors[index] = updated;
  }

  String _accessCodeFor(VisitorRecord visitor) {
    final String suffix = visitor.id.length > 8
        ? visitor.id.substring(visitor.id.length - 8).toUpperCase()
        : visitor.id.toUpperCase();
    return 'UEF-$suffix';
  }
}

class _VisitorSummaryCard extends StatelessWidget {
  const _VisitorSummaryCard({
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

class _InfoBadge extends StatelessWidget {
  const _InfoBadge({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: AppTheme.surfaceMuted,
        borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(icon, size: 16, color: AppTheme.textMuted),
          const SizedBox(width: 6),
          Text(
            text,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: AppTheme.textSecondary),
          ),
        ],
      ),
    );
  }
}

class _VisitorDetailLine extends StatelessWidget {
  const _VisitorDetailLine({
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
