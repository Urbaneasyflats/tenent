import 'package:flutter/material.dart';

import '../../core/models/app_models.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/custom_button.dart';
import '../../core/widgets/custom_card.dart';
import '../../core/widgets/custom_tab_bar.dart';
import '../../core/widgets/page_header.dart';
import '../../core/widgets/tone_badge.dart';

class BlockIssuesPage extends StatefulWidget {
  const BlockIssuesPage({
    super.key,
    required this.issues,
  });

  final List<TicketRecord> issues;

  @override
  State<BlockIssuesPage> createState() => _BlockIssuesPageState();
}

class _BlockIssuesPageState extends State<BlockIssuesPage> {
  final TextEditingController _searchController = TextEditingController();
  late List<TicketRecord> _issues;
  late Map<String, _IssueMeta> _issueMeta;
  late Map<String, List<_IssueComment>> _issueComments;
  TicketStatus? _selectedStatus;
  String? _selectedCategory;
  TicketPriority? _selectedPriority;

  @override
  void initState() {
    super.initState();
    _initializeState(widget.issues);
  }

  @override
  void didUpdateWidget(covariant BlockIssuesPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.issues != widget.issues) {
      _initializeState(widget.issues);
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _initializeState(List<TicketRecord> source) {
    _issues = List<TicketRecord>.from(source);
    _issueMeta = <String, _IssueMeta>{
      for (final TicketRecord issue in _issues) issue.id: _defaultMeta(issue),
    };
    _issueComments = <String, List<_IssueComment>>{
      for (final TicketRecord issue in _issues) issue.id: _defaultComments(issue),
    };
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final String search = _searchController.text.trim().toLowerCase();
    final List<String> categories = _issues
        .map((TicketRecord item) => item.category)
        .toSet()
        .toList()
      ..sort();

    final List<TicketRecord> visibleIssues = _issues.where((TicketRecord item) {
      final _IssueMeta meta = _metaFor(item);
      final bool matchesStatus =
          _selectedStatus == null || item.status == _selectedStatus;
      final bool matchesCategory =
          _selectedCategory == null || item.category == _selectedCategory;
      final bool matchesPriority =
          _selectedPriority == null || item.priority == _selectedPriority;
      final bool matchesSearch = search.isEmpty ||
          item.title.toLowerCase().contains(search) ||
          item.description.toLowerCase().contains(search) ||
          item.category.toLowerCase().contains(search) ||
          meta.location.toLowerCase().contains(search) ||
          meta.reportedBy.toLowerCase().contains(search);
      return matchesStatus &&
          matchesCategory &&
          matchesPriority &&
          matchesSearch;
    }).toList();

    final int openCount = _issues
        .where((TicketRecord item) => item.status == TicketStatus.open)
        .length;
    final int progressCount = _issues
        .where((TicketRecord item) => item.status == TicketStatus.inProgress)
        .length;
    final int resolvedCount = _issues
        .where((TicketRecord item) => item.status == TicketStatus.resolved)
        .length;
    final int highPriorityCount = _issues
        .where(
          (TicketRecord item) =>
              item.priority == TicketPriority.high ||
              item.priority == TicketPriority.urgent,
        )
        .length;

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 16,
        title: const Text('Block Issues'),
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1, thickness: 1, color: AppTheme.border),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openCreateIssueSheet,
        icon: const Icon(Icons.add_comment_outlined),
        label: const Text('Report Issue'),
      ),
      body: ListView(
        padding: AppTheme.pagePadding,
        children: <Widget>[
          const PageHeader(
            title: 'Block Issues',
            description:
                'Track block-level issues with search, filters, local comments, and resolution flow that matches the website demo screen more closely.',
          ),
          const SizedBox(height: 16),
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.45,
            children: <Widget>[
              _IssueSummaryCard(
                label: 'Open',
                value: '$openCount',
                tone: UiTone.warning,
              ),
              _IssueSummaryCard(
                label: 'In Progress',
                value: '$progressCount',
                tone: UiTone.brand,
              ),
              _IssueSummaryCard(
                label: 'Resolved',
                value: '$resolvedCount',
                tone: UiTone.success,
              ),
              _IssueSummaryCard(
                label: 'High Priority',
                value: '$highPriorityCount',
                tone: UiTone.danger,
              ),
            ],
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              labelText: 'Search issues, locations, or reporters',
              suffixIcon: IconButton(
                onPressed: () => setState(() {}),
                icon: const Icon(Icons.search_rounded),
              ),
            ),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 12),
          Row(
            children: <Widget>[
              Expanded(
                child: DropdownButtonFormField<String?>(
                  value: _selectedCategory,
                  decoration: const InputDecoration(labelText: 'Category'),
                  items: <DropdownMenuItem<String?>>[
                    const DropdownMenuItem<String?>(
                      value: null,
                      child: Text('All Categories'),
                    ),
                    ...categories.map(
                      (String category) => DropdownMenuItem<String?>(
                        value: category,
                        child: Text(_labelize(category)),
                      ),
                    ),
                  ],
                  onChanged: (String? value) {
                    setState(() {
                      _selectedCategory = value;
                    });
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: DropdownButtonFormField<TicketPriority?>(
                  value: _selectedPriority,
                  decoration: const InputDecoration(labelText: 'Priority'),
                  items: <DropdownMenuItem<TicketPriority?>>[
                    const DropdownMenuItem<TicketPriority?>(
                      value: null,
                      child: Text('All Priorities'),
                    ),
                    ...TicketPriority.values.map(
                      (TicketPriority value) =>
                          DropdownMenuItem<TicketPriority?>(
                        value: value,
                        child: Text(value.label),
                      ),
                    ),
                  ],
                  onChanged: (TicketPriority? value) {
                    setState(() {
                      _selectedPriority = value;
                    });
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          CustomTabBar(
            style: CustomTabBarStyle.pill,
            currentIndex: _selectedStatus == null
                ? 0
                : TicketStatus.values.indexOf(_selectedStatus!) + 1,
            onChanged: (int index) {
              setState(() {
                _selectedStatus =
                    index == 0 ? null : TicketStatus.values[index - 1];
              });
            },
            tabs: <CustomTabItem>[
              const CustomTabItem(label: 'All'),
              ...TicketStatus.values.map(
                (TicketStatus status) => CustomTabItem(label: status.label),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (visibleIssues.isEmpty)
            const CustomCard(
              padding: CustomCardPadding.sm,
              child: Text('No block issues match the current filters.'),
            )
          else
            ...visibleIssues.map((TicketRecord issue) {
              final _IssueMeta meta = _metaFor(issue);
              final int commentCount = _issueComments[issue.id]?.length ?? 0;
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
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          ToneBadge(
                            label: issue.priority.label,
                            tone: issue.priority.tone,
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        issue.description,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: AppTheme.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: <Widget>[
                          ToneBadge(
                            label: issue.status.label,
                            tone: issue.status.tone,
                          ),
                          ToneBadge(
                            label: _labelize(issue.category),
                            tone: UiTone.neutral,
                          ),
                          ToneBadge(label: meta.location, tone: UiTone.brand),
                          if (commentCount > 0)
                            ToneBadge(
                              label: '$commentCount comments',
                              tone: UiTone.neutral,
                            ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Reported by ${meta.reportedBy}${meta.flatNumber?.isNotEmpty == true ? ' | ${meta.flatNumber}' : ''}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: AppTheme.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Updated ${formatCompactDate(issue.updatedAt)} at ${formatClock(issue.updatedAt)}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: AppTheme.textMuted,
                        ),
                      ),
                      const SizedBox(height: 14),
                      Row(
                        children: <Widget>[
                          Expanded(
                            child: CustomButton(
                              label: 'Details',
                              variant: CustomButtonVariant.outline,
                              onPressed: () => _showIssueDetails(issue),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: CustomButton(
                              label: _nextActionLabel(issue.status),
                              onPressed: () => _advanceIssue(issue),
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

  _IssueMeta _defaultMeta(TicketRecord issue) {
    final String location = switch (issue.category.toLowerCase()) {
      'maintenance' => 'Block corridor',
      'security' => 'Entry gate',
      'cleaning' => 'Common area',
      'utilities' => 'Utility room',
      'common_area' => 'Shared block area',
      _ => 'Block common area',
    };

    return _IssueMeta(
      location: location,
      reportedBy: issue.assignee ?? 'Block Secretary',
      flatNumber: null,
    );
  }

  List<_IssueComment> _defaultComments(TicketRecord issue) {
    if ((issue.assignee ?? '').isEmpty) {
      return <_IssueComment>[];
    }
    return <_IssueComment>[
      _IssueComment(
        id: 'comment-${issue.id}-1',
        author: issue.assignee!,
        message: 'Assigned for review and next update.',
        timestamp: issue.updatedAt,
      ),
    ];
  }

  _IssueMeta _metaFor(TicketRecord issue) {
    return _issueMeta[issue.id] ?? _defaultMeta(issue);
  }

  String _labelize(String value) {
    final String normalized = value.replaceAll('_', ' ');
    if (normalized.isEmpty) {
      return value;
    }
    return normalized[0].toUpperCase() + normalized.substring(1);
  }

  String _nextActionLabel(TicketStatus status) {
    return switch (status) {
      TicketStatus.open => 'Start Work',
      TicketStatus.inProgress => 'Resolve',
      TicketStatus.resolved => 'Close',
      TicketStatus.rejected => 'Reopen',
    };
  }

  TicketStatus _nextStatus(TicketStatus status) {
    return switch (status) {
      TicketStatus.open => TicketStatus.inProgress,
      TicketStatus.inProgress => TicketStatus.resolved,
      TicketStatus.resolved => TicketStatus.rejected,
      TicketStatus.rejected => TicketStatus.open,
    };
  }

  void _advanceIssue(TicketRecord issue) {
    final TicketStatus nextStatus = _nextStatus(issue.status);
    _replaceIssue(issue, issue.copyWith(status: nextStatus, updatedAt: DateTime.now()));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${issue.title} moved to ${nextStatus.label}.')),
    );
  }

  void _replaceIssue(TicketRecord source, TicketRecord updated) {
    final int index = _issues.indexWhere(
      (TicketRecord item) => item.id == source.id,
    );
    if (index < 0) {
      return;
    }
    setState(() {
      _issues[index] = updated;
    });
  }

  void _showIssueDetails(TicketRecord issue) {
    final TextEditingController commentController = TextEditingController();
    showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setDialogState) {
            TicketRecord currentIssue = _issues.firstWhere(
              (TicketRecord item) => item.id == issue.id,
              orElse: () => issue,
            );
            final _IssueMeta meta = _metaFor(currentIssue);
            final List<_IssueComment> comments =
                _issueComments[currentIssue.id] ?? <_IssueComment>[];

            void addComment() {
              final String text = commentController.text.trim();
              if (text.isEmpty) {
                return;
              }
              setState(() {
                _issueComments[currentIssue.id] = <_IssueComment>[
                  ...comments,
                  _IssueComment(
                    id: 'comment-${DateTime.now().millisecondsSinceEpoch}',
                    author: 'Block Secretary',
                    message: text,
                    timestamp: DateTime.now(),
                  ),
                ];
                _replaceIssueSilently(
                  currentIssue,
                  currentIssue.copyWith(updatedAt: DateTime.now()),
                );
              });
              commentController.clear();
              setDialogState(() {});
            }

            void markResolved() {
              setState(() {
                _replaceIssueSilently(
                  currentIssue,
                  currentIssue.copyWith(
                    status: currentIssue.status == TicketStatus.resolved
                        ? TicketStatus.open
                        : TicketStatus.resolved,
                    updatedAt: DateTime.now(),
                  ),
                );
              });
              setDialogState(() {});
            }

            return AlertDialog(
              title: Text(currentIssue.title),
              content: SizedBox(
                width: 520,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(currentIssue.description),
                      const SizedBox(height: 12),
                      _IssueDetailLine(
                        label: 'Category',
                        value: _labelize(currentIssue.category),
                      ),
                      _IssueDetailLine(
                        label: 'Priority',
                        value: currentIssue.priority.label,
                      ),
                      _IssueDetailLine(
                        label: 'Status',
                        value: currentIssue.status.label,
                      ),
                      _IssueDetailLine(label: 'Location', value: meta.location),
                      _IssueDetailLine(
                        label: 'Reported By',
                        value: meta.reportedBy,
                      ),
                      if ((meta.flatNumber ?? '').isNotEmpty)
                        _IssueDetailLine(
                          label: 'Flat',
                          value: meta.flatNumber!,
                        ),
                      _IssueDetailLine(
                        label: 'Updated',
                        value:
                            '${formatCompactDate(currentIssue.updatedAt)} ${formatClock(currentIssue.updatedAt)}',
                      ),
                      if ((currentIssue.assignee ?? '').isNotEmpty)
                        _IssueDetailLine(
                          label: 'Assigned',
                          value: currentIssue.assignee!,
                        ),
                      const SizedBox(height: 12),
                      Text(
                        'Comments & Updates',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                      const SizedBox(height: 10),
                      if (comments.isEmpty)
                        Text(
                          'No updates added yet.',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: AppTheme.textSecondary,
                              ),
                        )
                      else
                        ...comments.map(( _IssueComment comment) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: CustomCard(
                              padding: CustomCardPadding.sm,
                              color: AppTheme.surfaceMuted,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: <Widget>[
                                  Row(
                                    children: <Widget>[
                                      Expanded(
                                        child: Text(
                                          comment.author,
                                          style: Theme.of(context)
                                              .textTheme
                                              .titleSmall
                                              ?.copyWith(
                                                fontWeight: FontWeight.w600,
                                              ),
                                        ),
                                      ),
                                      Text(
                                        '${formatCompactDate(comment.timestamp)} ${formatClock(comment.timestamp)}',
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodySmall
                                            ?.copyWith(
                                              color: AppTheme.textMuted,
                                            ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  Text(comment.message),
                                ],
                              ),
                            ),
                          );
                        }),
                      const SizedBox(height: 12),
                      TextField(
                        controller: commentController,
                        minLines: 2,
                        maxLines: 4,
                        decoration: const InputDecoration(
                          labelText: 'Add update',
                          hintText: 'Add a comment or resolution note',
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: <Widget>[
                          Expanded(
                            child: CustomButton(
                              label: 'Add Comment',
                              variant: CustomButtonVariant.outline,
                              onPressed: addComment,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: CustomButton(
                              label: currentIssue.status == TicketStatus.resolved
                                  ? 'Reopen'
                                  : 'Mark Resolved',
                              onPressed: markResolved,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
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
      },
    ).whenComplete(commentController.dispose);
  }

  void _replaceIssueSilently(TicketRecord source, TicketRecord updated) {
    final int index = _issues.indexWhere(
      (TicketRecord item) => item.id == source.id,
    );
    if (index < 0) {
      return;
    }
    _issues[index] = updated;
  }

  Future<void> _openCreateIssueSheet() async {
    final TextEditingController titleController = TextEditingController();
    final TextEditingController descriptionController = TextEditingController();
    final TextEditingController locationController = TextEditingController();
    final TextEditingController flatController = TextEditingController();
    final TextEditingController reportedByController =
        TextEditingController(text: 'Block Secretary');
    TicketPriority priority = TicketPriority.medium;
    String category = 'maintenance';

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            void submit() {
              if (titleController.text.trim().isEmpty ||
                  descriptionController.text.trim().isEmpty ||
                  locationController.text.trim().isEmpty ||
                  reportedByController.text.trim().isEmpty) {
                return;
              }

              final TicketRecord record = TicketRecord(
                id: 'issue-${DateTime.now().millisecondsSinceEpoch}',
                title: titleController.text.trim(),
                description: descriptionController.text.trim(),
                status: TicketStatus.open,
                priority: priority,
                category: category,
                updatedAt: DateTime.now(),
                assignee: null,
              );

              setState(() {
                _issues.insert(0, record);
                _issueMeta[record.id] = _IssueMeta(
                  location: locationController.text.trim(),
                  reportedBy: reportedByController.text.trim(),
                  flatNumber: flatController.text.trim().isEmpty
                      ? null
                      : flatController.text.trim(),
                );
                _issueComments[record.id] = <_IssueComment>[
                  _IssueComment(
                    id: 'comment-${record.id}-created',
                    author: reportedByController.text.trim(),
                    message: 'Issue reported and waiting for acknowledgement.',
                    timestamp: DateTime.now(),
                  ),
                ];
              });

              Navigator.of(context).pop();
              ScaffoldMessenger.of(this.context).showSnackBar(
                const SnackBar(content: Text('Block issue added locally.')),
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
                      'Report Block Issue',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: titleController,
                      decoration: const InputDecoration(labelText: 'Issue title'),
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
                                value: 'maintenance',
                                child: Text('Maintenance'),
                              ),
                              DropdownMenuItem(
                                value: 'security',
                                child: Text('Security'),
                              ),
                              DropdownMenuItem(
                                value: 'cleaning',
                                child: Text('Cleaning'),
                              ),
                              DropdownMenuItem(
                                value: 'utilities',
                                child: Text('Utilities'),
                              ),
                              DropdownMenuItem(
                                value: 'common_area',
                                child: Text('Common Area'),
                              ),
                              DropdownMenuItem(
                                value: 'other',
                                child: Text('Other'),
                              ),
                            ],
                            onChanged: (String? value) {
                              setModalState(() {
                                category = value ?? 'maintenance';
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
                    const SizedBox(height: 12),
                    TextField(
                      controller: locationController,
                      decoration: const InputDecoration(labelText: 'Location'),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: <Widget>[
                        Expanded(
                          child: TextField(
                            controller: flatController,
                            decoration: const InputDecoration(
                              labelText: 'Flat number',
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextField(
                            controller: reportedByController,
                            decoration: const InputDecoration(
                              labelText: 'Reported by',
                            ),
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
    locationController.dispose();
    flatController.dispose();
    reportedByController.dispose();
  }
}

class _IssueSummaryCard extends StatelessWidget {
  const _IssueSummaryCard({
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

class _IssueDetailLine extends StatelessWidget {
  const _IssueDetailLine({
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

class _IssueMeta {
  const _IssueMeta({
    required this.location,
    required this.reportedBy,
    required this.flatNumber,
  });

  final String location;
  final String reportedBy;
  final String? flatNumber;
}

class _IssueComment {
  const _IssueComment({
    required this.id,
    required this.author,
    required this.message,
    required this.timestamp,
  });

  final String id;
  final String author;
  final String message;
  final DateTime timestamp;
}

extension on TicketRecord {
  TicketRecord copyWith({
    String? id,
    String? title,
    String? description,
    TicketStatus? status,
    TicketPriority? priority,
    String? category,
    DateTime? updatedAt,
    String? assignee,
  }) {
    return TicketRecord(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      status: status ?? this.status,
      priority: priority ?? this.priority,
      category: category ?? this.category,
      updatedAt: updatedAt ?? this.updatedAt,
      assignee: assignee ?? this.assignee,
    );
  }
}
