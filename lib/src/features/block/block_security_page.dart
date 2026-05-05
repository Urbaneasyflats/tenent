import 'package:flutter/material.dart';

import '../../core/models/app_models.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/custom_button.dart';
import '../../core/widgets/custom_card.dart';
import '../../core/widgets/custom_tab_bar.dart';
import '../../core/widgets/page_header.dart';
import '../../core/widgets/tone_badge.dart';

class BlockSecurityPage extends StatefulWidget {
  const BlockSecurityPage({
    super.key,
    required this.visitors,
    required this.issues,
  });

  final List<VisitorRecord> visitors;
  final List<TicketRecord> issues;

  @override
  State<BlockSecurityPage> createState() => _BlockSecurityPageState();
}

class _BlockSecurityPageState extends State<BlockSecurityPage> {
  final TextEditingController _searchController = TextEditingController();
  int _tabIndex = 0;
  late List<VisitorRecord> _visitors;
  late List<TicketRecord> _incidents;

  static const List<_CameraFeed> _cameraFeeds = <_CameraFeed>[
    _CameraFeed(
      title: 'Gate Entry Camera',
      subtitle: 'Tracks visitor check-in and delivery vehicles.',
      statusLabel: 'Online',
      tone: UiTone.success,
    ),
    _CameraFeed(
      title: 'Lobby Camera',
      subtitle: 'Covers elevator lobby and waiting area.',
      statusLabel: 'Maintenance',
      tone: UiTone.warning,
    ),
    _CameraFeed(
      title: 'Parking Camera',
      subtitle: 'Monitors basement access and reserved parking lanes.',
      statusLabel: 'Online',
      tone: UiTone.success,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _visitors = List<VisitorRecord>.from(widget.visitors);
    _incidents = List<TicketRecord>.from(widget.issues);
  }

  @override
  void didUpdateWidget(covariant BlockSecurityPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.visitors != widget.visitors) {
      _visitors = List<VisitorRecord>.from(widget.visitors);
    }
    if (oldWidget.issues != widget.issues) {
      _incidents = List<TicketRecord>.from(widget.issues);
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final String search = _searchController.text.trim().toLowerCase();
    final List<TicketRecord> visibleIssues = _incidents.where((TicketRecord item) {
      return search.isEmpty ||
          item.title.toLowerCase().contains(search) ||
          item.description.toLowerCase().contains(search) ||
          item.category.toLowerCase().contains(search);
    }).toList();
    final List<VisitorRecord> visibleVisitors =
        _visitors.where((VisitorRecord item) {
      return search.isEmpty ||
          item.name.toLowerCase().contains(search) ||
          item.host.toLowerCase().contains(search) ||
          item.unitLabel.toLowerCase().contains(search) ||
          item.purpose.toLowerCase().contains(search);
    }).toList();

    final int activeIssues = _incidents
        .where(
          (TicketRecord item) =>
              item.status == TicketStatus.open ||
              item.status == TicketStatus.inProgress,
        )
        .length;
    final int waitingVisitors = _visitors
        .where((VisitorRecord item) => item.status == VisitStatus.waiting)
        .length;
    final int activeVisitors = _visitors
        .where(
          (VisitorRecord item) =>
              item.status == VisitStatus.approved ||
              item.status == VisitStatus.checkedIn,
        )
        .length;

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 16,
        title: const Text('Block Security'),
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1, thickness: 1, color: AppTheme.border),
        ),
      ),
      floatingActionButton: _tabIndex == 0
          ? FloatingActionButton.extended(
              onPressed: _openIncidentSheet,
              icon: const Icon(Icons.add_alert_outlined),
              label: const Text('Report Issue'),
            )
          : null,
      body: ListView(
        padding: AppTheme.pagePadding,
        children: <Widget>[
          const PageHeader(
            title: 'Block Security',
            description:
                'Track block-level security with incident, visitor, and camera views aligned to the website demo workflow.',
          ),
          const SizedBox(height: 16),
          Row(
            children: <Widget>[
              Expanded(
                child: _SecuritySummaryCard(
                  label: 'Open Issues',
                  value: '$activeIssues',
                  tone: UiTone.warning,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _SecuritySummaryCard(
                  label: 'Visitors Waiting',
                  value: '$waitingVisitors',
                  tone: UiTone.brand,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _SecuritySummaryCard(
                  label: 'Active Visitors',
                  value: '$activeVisitors',
                  tone: UiTone.success,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              labelText: 'Search incidents, visitors, or locations',
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
            currentIndex: _tabIndex,
            onChanged: (int index) {
              setState(() {
                _tabIndex = index;
              });
            },
            tabs: const <CustomTabItem>[
              CustomTabItem(label: 'Issues'),
              CustomTabItem(label: 'Visitors'),
              CustomTabItem(label: 'Cameras'),
            ],
          ),
          const SizedBox(height: 16),
          switch (_tabIndex) {
            0 => _IssuesTab(
                issues: visibleIssues,
                onViewIssue: _showIncidentDetails,
                onUpdateIssue: _updateIssueStatus,
              ),
            1 => _VisitorsTab(
                visitors: visibleVisitors,
                onUpdateVisitor: _updateVisitor,
              ),
            _ => const _CamerasTab(feeds: _cameraFeeds),
          },
        ],
      ),
    );
  }

  void _updateVisitor(VisitorRecord source, VisitStatus nextStatus) {
    final int index = _visitors.indexWhere((VisitorRecord item) => item.id == source.id);
    if (index < 0) {
      return;
    }

    setState(() {
      _visitors[index] = VisitorRecord(
        id: source.id,
        name: source.name,
        host: source.host,
        unitLabel: source.unitLabel,
        purpose: source.purpose,
        time: source.time,
        status: nextStatus,
        preApproved: source.preApproved ||
            nextStatus == VisitStatus.approved ||
            nextStatus == VisitStatus.checkedIn ||
            nextStatus == VisitStatus.checkedOut,
      );
    });
  }

  void _updateIssueStatus(TicketRecord source, TicketStatus nextStatus) {
    final int index = _incidents.indexWhere(
      (TicketRecord item) => item.id == source.id,
    );
    if (index < 0) {
      return;
    }

    setState(() {
      _incidents[index] = TicketRecord(
        id: source.id,
        title: source.title,
        description: source.description,
        status: nextStatus,
        priority: source.priority,
        category: source.category,
        updatedAt: DateTime.now(),
        assignee: source.assignee,
      );
    });
  }

  void _showIncidentDetails(TicketRecord issue) {
    showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(issue.title),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(issue.description),
              const SizedBox(height: 12),
              _SecurityDetailLine(label: 'Category', value: issue.category),
              _SecurityDetailLine(label: 'Priority', value: issue.priority.label),
              _SecurityDetailLine(label: 'Status', value: issue.status.label),
              if ((issue.assignee ?? '').isNotEmpty)
                _SecurityDetailLine(label: 'Assigned', value: issue.assignee!),
              _SecurityDetailLine(
                label: 'Updated',
                value:
                    '${formatCompactDate(issue.updatedAt)} ${formatClock(issue.updatedAt)}',
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

  Future<void> _openIncidentSheet() async {
    final TextEditingController titleController = TextEditingController();
    final TextEditingController descriptionController = TextEditingController();
    String category = 'security';
    TicketPriority priority = TicketPriority.medium;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            void submit() {
              if (titleController.text.trim().isEmpty ||
                  descriptionController.text.trim().isEmpty) {
                return;
              }

              setState(() {
                _incidents.insert(
                  0,
                  TicketRecord(
                    id: 'incident-${DateTime.now().millisecondsSinceEpoch}',
                    title: titleController.text.trim(),
                    description: descriptionController.text.trim(),
                    status: TicketStatus.open,
                    priority: priority,
                    category: category,
                    updatedAt: DateTime.now(),
                    assignee: 'Security Desk',
                  ),
                );
              });

              Navigator.of(context).pop();
              ScaffoldMessenger.of(this.context).showSnackBar(
                const SnackBar(content: Text('Security issue added locally.')),
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
                      'Report Security Issue',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: titleController,
                      decoration: const InputDecoration(labelText: 'Title'),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: descriptionController,
                      minLines: 3,
                      maxLines: 5,
                      decoration: const InputDecoration(labelText: 'Description'),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: <Widget>[
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: category,
                            decoration:
                                const InputDecoration(labelText: 'Category'),
                            items: const <DropdownMenuItem<String>>[
                              DropdownMenuItem(
                                value: 'security',
                                child: Text('Security'),
                              ),
                              DropdownMenuItem(
                                value: 'visitor',
                                child: Text('Visitor'),
                              ),
                              DropdownMenuItem(
                                value: 'parking',
                                child: Text('Parking'),
                              ),
                              DropdownMenuItem(
                                value: 'maintenance',
                                child: Text('Maintenance'),
                              ),
                            ],
                            onChanged: (String? value) {
                              setModalState(() {
                                category = value ?? 'security';
                              });
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: DropdownButtonFormField<TicketPriority>(
                            value: priority,
                            decoration:
                                const InputDecoration(labelText: 'Priority'),
                            items: TicketPriority.values
                                .map(
                                  (TicketPriority value) =>
                                      DropdownMenuItem<TicketPriority>(
                                    value: value,
                                    child: Text(value.label),
                                  ),
                                )
                                .toList(),
                            onChanged: (TicketPriority? value) {
                              setModalState(() {
                                priority = value ?? TicketPriority.medium;
                              });
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    CustomButton(
                      label: 'Save Issue',
                      onPressed: submit,
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );

    titleController.dispose();
    descriptionController.dispose();
  }
}

class _IssuesTab extends StatelessWidget {
  const _IssuesTab({
    required this.issues,
    required this.onViewIssue,
    required this.onUpdateIssue,
  });

  final List<TicketRecord> issues;
  final ValueChanged<TicketRecord> onViewIssue;
  final void Function(TicketRecord issue, TicketStatus nextStatus) onUpdateIssue;

  @override
  Widget build(BuildContext context) {
    if (issues.isEmpty) {
      return const CustomCard(
        padding: CustomCardPadding.sm,
        child: Text('No security issues are tracked in this block yet.'),
      );
    }

    return Column(
      children: issues.map((TicketRecord issue) {
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
                      child: Text(
                        issue.title,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                    ),
                    ToneBadge(
                      label: issue.priority.label,
                      tone: issue.priority.tone,
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  issue.description,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppTheme.textSecondary,
                      ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: <Widget>[
                    ToneBadge(label: issue.status.label, tone: issue.status.tone),
                    ToneBadge(label: issue.category, tone: UiTone.neutral),
                  ],
                ),
                const SizedBox(height: 14),
                Row(
                  children: <Widget>[
                    Expanded(
                      child: CustomButton(
                        label: 'View',
                        variant: CustomButtonVariant.outline,
                        onPressed: () => onViewIssue(issue),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: CustomButton(
                        label: issue.status == TicketStatus.resolved
                            ? 'Reopen'
                            : 'Resolve',
                        onPressed: () => onUpdateIssue(
                          issue,
                          issue.status == TicketStatus.resolved
                              ? TicketStatus.open
                              : TicketStatus.resolved,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _VisitorsTab extends StatelessWidget {
  const _VisitorsTab({
    required this.visitors,
    required this.onUpdateVisitor,
  });

  final List<VisitorRecord> visitors;
  final void Function(VisitorRecord source, VisitStatus nextStatus)
      onUpdateVisitor;

  @override
  Widget build(BuildContext context) {
    if (visitors.isEmpty) {
      return const CustomCard(
        padding: CustomCardPadding.sm,
        child: Text('No visitors are currently tracked for this block.'),
      );
    }

    return Column(
      children: visitors.map((VisitorRecord visitor) {
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
                            visitor.name,
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${visitor.host} | ${visitor.unitLabel}',
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(color: AppTheme.textSecondary),
                          ),
                        ],
                      ),
                    ),
                    ToneBadge(
                      label: visitor.status.label,
                      tone: visitor.status.tone,
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: <Widget>[
                    ToneBadge(label: visitor.purpose, tone: UiTone.brand),
                    ToneBadge(
                      label: formatCompactDate(visitor.time),
                      tone: UiTone.neutral,
                    ),
                    ToneBadge(
                      label: formatClock(visitor.time),
                      tone: UiTone.neutral,
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Row(
                  children: <Widget>[
                    ..._visitorActions(visitor, onUpdateVisitor),
                  ],
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  List<Widget> _visitorActions(
    VisitorRecord visitor,
    void Function(VisitorRecord source, VisitStatus nextStatus) onUpdateVisitor,
  ) {
    return switch (visitor.status) {
      VisitStatus.waiting => <Widget>[
          Expanded(
            child: CustomButton(
              label: 'Approve',
              variant: CustomButtonVariant.outline,
              onPressed: () => onUpdateVisitor(visitor, VisitStatus.approved),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: CustomButton(
              label: 'Deny',
              variant: CustomButtonVariant.danger,
              onPressed: () => onUpdateVisitor(visitor, VisitStatus.denied),
            ),
          ),
        ],
      VisitStatus.approved => <Widget>[
          Expanded(
            child: CustomButton(
              label: 'Check In',
              onPressed: () => onUpdateVisitor(visitor, VisitStatus.checkedIn),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: CustomButton(
              label: 'Deny',
              variant: CustomButtonVariant.outline,
              onPressed: () => onUpdateVisitor(visitor, VisitStatus.denied),
            ),
          ),
        ],
      VisitStatus.checkedIn => <Widget>[
          Expanded(
            child: CustomButton(
              label: 'Check Out',
              onPressed: () => onUpdateVisitor(visitor, VisitStatus.checkedOut),
            ),
          ),
        ],
      _ => <Widget>[
          Expanded(
            child: CustomButton(
              label: 'Reopen',
              variant: CustomButtonVariant.outline,
              onPressed: () => onUpdateVisitor(visitor, VisitStatus.waiting),
            ),
          ),
        ],
    };
  }
}

class _CamerasTab extends StatelessWidget {
  const _CamerasTab({required this.feeds});

  final List<_CameraFeed> feeds;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: feeds.map(( _CameraFeed feed) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: CustomCard(
            padding: CustomCardPadding.sm,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    Expanded(
                      child: Text(
                        feed.title,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                    ),
                    ToneBadge(label: feed.statusLabel, tone: feed.tone),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  feed.subtitle,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppTheme.textSecondary,
                      ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _SecuritySummaryCard extends StatelessWidget {
  const _SecuritySummaryCard({
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

class _SecurityDetailLine extends StatelessWidget {
  const _SecurityDetailLine({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          SizedBox(
            width: 78,
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

class _CameraFeed {
  const _CameraFeed({
    required this.title,
    required this.subtitle,
    required this.statusLabel,
    required this.tone,
  });

  final String title;
  final String subtitle;
  final String statusLabel;
  final UiTone tone;
}
