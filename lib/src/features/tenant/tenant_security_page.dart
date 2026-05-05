import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/api/incident_service.dart';
import '../../core/models/app_models.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/custom_button.dart';
import '../../core/widgets/custom_card.dart';
import '../../core/widgets/custom_tab_bar.dart';
import '../../core/widgets/fullscreen_image_viewer.dart';
import '../../core/widgets/page_header.dart';
import '../../core/widgets/tone_badge.dart';

class TenantSecurityPage extends StatefulWidget {
  const TenantSecurityPage({
    super.key,
    this.embedded = false,
  });

  final bool embedded;

  @override
  State<TenantSecurityPage> createState() => _TenantSecurityPageState();
}

class _TenantSecurityPageState extends State<TenantSecurityPage> {
  static const int _pageSize = 10;

  final TextEditingController _searchController = TextEditingController();
  Timer? _searchDebounce;

  bool _isLoading = true;
  String? _errorMessage;
  IncidentStatus? _statusFilter;
  List<IncidentRecord> _incidents = <IncidentRecord>[];
  int _count = 0;
  int _page = 0;

  @override
  void initState() {
    super.initState();
    _loadIncidents();
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadIncidents() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final String search = _searchController.text.trim();
      final result = await IncidentService.filterTenantIncidentRecords(
        skip: _page * _pageSize,
        limit: _pageSize,
        search: search.isEmpty ? null : search,
        status: _statusFilter,
      );
      if (!mounted) {
        return;
      }

      setState(() {
        _incidents = result.incidents;
        _count = result.count;
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

  void _handleSearchChanged(String value) {
    setState(() {
      _page = 0;
    });
    _searchDebounce?.cancel();
    _searchDebounce = Timer(
      const Duration(milliseconds: 350),
      _loadIncidents,
    );
  }

  void _showIncidentDetails(IncidentRecord incident) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => _AlertDetailPage(incident: incident),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final Widget body = RefreshIndicator(
      onRefresh: _loadIncidents,
      child: ListView(
        padding: AppTheme.pagePadding,
        children: <Widget>[
          const PageHeader(
            title: 'Security Alerts',
            description:
                'View security incidents reported in your society.',
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              labelText: 'Search alerts',
              hintText: 'Search by title or location',
              prefixIcon: const Icon(Icons.search_rounded),
              suffixIcon: _searchController.text.isEmpty
                  ? null
                  : IconButton(
                      onPressed: () {
                        _searchController.clear();
                        _page = 0;
                        _loadIncidents();
                      },
                      icon: const Icon(Icons.close_rounded),
                    ),
            ),
            onChanged: _handleSearchChanged,
            onSubmitted: (_) => _loadIncidents(),
          ),
          const SizedBox(height: 16),
          CustomTabBar(
            style: CustomTabBarStyle.pill,
            currentIndex: _statusFilter == null
                ? 0
                : IncidentStatus.values.indexOf(_statusFilter!) + 1,
            onChanged: (int index) {
              setState(() {
                _page = 0;
                _statusFilter =
                    index == 0 ? null : IncidentStatus.values[index - 1];
              });
              _loadIncidents();
            },
            tabs: <CustomTabItem>[
              const CustomTabItem(label: 'All'),
              ...IncidentStatus.values.map(
                (IncidentStatus status) => CustomTabItem(label: status.label),
              ),
            ],
          ),
          const SizedBox(height: 16),
          CustomCard(
            padding: CustomCardPadding.sm,
            child: Wrap(
              spacing: 10,
              runSpacing: 10,
              children: <Widget>[
                ToneBadge(label: '$_count alerts', tone: UiTone.brand),
                ToneBadge(
                  label:
                      '${_incidents.where((IncidentRecord item) => item.status == IncidentStatus.open).length} open',
                  tone: UiTone.warning,
                ),
                ToneBadge(
                  label:
                      '${_incidents.where((IncidentRecord item) => item.status == IncidentStatus.resolved).length} resolved',
                  tone: UiTone.success,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 64),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (_errorMessage != null)
            _TenantSecurityErrorCard(
              message: _errorMessage!,
              onRetry: _loadIncidents,
            )
          else if (_incidents.isEmpty)
            const CustomCard(
              child: Text('No security alerts found for the current filters.'),
            )
          else
            ..._incidents.map((IncidentRecord incident) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _IncidentCard(
                  incident: incident,
                  onView: () => _showIncidentDetails(incident),
                ),
              );
            }),
          if (!_isLoading && _errorMessage == null && _count > _pageSize) ...<Widget>[
            const SizedBox(height: 4),
            CustomCard(
              padding: CustomCardPadding.sm,
              child: Row(
                children: <Widget>[
                  Expanded(
                    child: Text(
                      'Page ${_page + 1} of ${(_count / _pageSize).ceil()}',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppTheme.textSecondary,
                          ),
                    ),
                  ),
                  CustomButton(
                    label: 'Previous',
                    variant: CustomButtonVariant.outline,
                    onPressed: _page == 0
                        ? null
                        : () {
                            setState(() {
                              _page -= 1;
                            });
                            _loadIncidents();
                          },
                  ),
                  const SizedBox(width: 10),
                  CustomButton(
                    label: 'Next',
                    variant: CustomButtonVariant.outline,
                    onPressed: (_page + 1) * _pageSize >= _count
                        ? null
                        : () {
                            setState(() {
                              _page += 1;
                            });
                            _loadIncidents();
                          },
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );

    if (widget.embedded) {
      return body;
    }

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 16,
        title: const Text('Security Alerts'),
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1, thickness: 1, color: AppTheme.border),
        ),
      ),
      body: body,
    );
  }
}

// ─── Incident Card (matches website card layout) ─────────────────────

class _IncidentCard extends StatelessWidget {
  const _IncidentCard({
    required this.incident,
    required this.onView,
  });

  final IncidentRecord incident;
  final VoidCallback onView;

  @override
  Widget build(BuildContext context) {
    final bool hasImage = (incident.imageUrl ?? '').trim().isNotEmpty;

    return CustomCard(
      padding: CustomCardPadding.sm,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          // Title + priority badge
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Expanded(
                child: Text(
                  incident.title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ),
              const SizedBox(width: 8),
              ToneBadge(
                label: incident.priority.label,
                tone: incident.priority.tone,
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Description (line-clamp-2 matching website)
          Text(
            incident.description,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppTheme.textSecondary,
                ),
          ),

          // Image preview — contained with border like website
          if (hasImage) ...<Widget>[
            const SizedBox(height: 12),
            GestureDetector(
              onTap: () => FullScreenImageViewer.show(
                context,
                imageUrl: incident.imageUrl!,
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
                    constraints: const BoxConstraints(maxHeight: 180),
                    child: Image.network(
                      incident.imageUrl!,
                      width: double.infinity,
                      fit: BoxFit.contain,
                      errorBuilder: (_, __, ___) => Container(
                        height: 120,
                        color: AppTheme.surfaceMuted,
                        alignment: Alignment.center,
                        child: const Icon(Icons.broken_image_outlined,
                            color: AppTheme.textMuted, size: 32),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
          const SizedBox(height: 12),

          // Status badge + metadata row
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: <Widget>[
              ToneBadge(
                label: incident.status.label,
                tone: incident.status.tone,
              ),
              if ((incident.location ?? '').isNotEmpty)
                _MetaChip(
                  icon: Icons.location_on_outlined,
                  label: incident.location!,
                ),
              _MetaChip(
                icon: Icons.schedule_outlined,
                label:
                    '${formatCompactDate(incident.createdAt)}, ${formatClock(incident.createdAt)}',
              ),
            ],
          ),
          const SizedBox(height: 14),

          // View button with Eye icon (matching website)
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: onView,
              icon: const Icon(Icons.visibility_outlined, size: 18),
              label: const Text('View'),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Small metadata chip for location / timestamp ────────────────────

class _MetaChip extends StatelessWidget {
  const _MetaChip({
    required this.icon,
    required this.label,
  });

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Icon(icon, size: 14, color: AppTheme.textMuted),
        const SizedBox(width: 4),
        Flexible(
          child: Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppTheme.textMuted,
                ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

// ─── Full-screen Alert Detail Page (matches website modal) ───────────

class _AlertDetailPage extends StatelessWidget {
  const _AlertDetailPage({required this.incident});

  final IncidentRecord incident;

  @override
  Widget build(BuildContext context) {
    final bool hasImage = (incident.imageUrl ?? '').trim().isNotEmpty;

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 16,
        title: const Text('Alert Details'),
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1, thickness: 1, color: AppTheme.border),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: <Widget>[
          // Title
          Text(
            incident.title,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 12),

          // Badges — status + priority + inactive
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: <Widget>[
              ToneBadge(
                label: incident.status.label,
                tone: incident.status.tone,
              ),
              ToneBadge(
                label: incident.priority.label,
                tone: incident.priority.tone,
              ),
              if (!incident.isActive)
                const ToneBadge(
                  label: 'Inactive',
                  tone: UiTone.warning,
                ),
            ],
          ),
          const SizedBox(height: 20),

          // Image — centered, contained, with border (website style)
          if (hasImage) ...<Widget>[
            Text(
              'Incident Image',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: () => FullScreenImageViewer.show(
                context,
                imageUrl: incident.imageUrl!,
              ),
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: const Color(0xFFF9FAFB),
                  border: Border.all(color: AppTheme.border),
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: const EdgeInsets.all(8),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxHeight: 320),
                    child: Image.network(
                      incident.imageUrl!,
                      fit: BoxFit.contain,
                      loadingBuilder: (_, Widget child,
                          ImageChunkEvent? loadingProgress) {
                        if (loadingProgress == null) return child;
                        return SizedBox(
                          height: 200,
                          child: Center(
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              value: loadingProgress.expectedTotalBytes != null
                                  ? loadingProgress.cumulativeBytesLoaded /
                                      loadingProgress.expectedTotalBytes!
                                  : null,
                            ),
                          ),
                        );
                      },
                      errorBuilder: (_, __, ___) => Container(
                        height: 200,
                        alignment: Alignment.center,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: <Widget>[
                            Icon(Icons.broken_image_outlined,
                                color: Colors.grey[400], size: 48),
                            const SizedBox(height: 8),
                            Text(
                              'Unable to load image',
                              style: TextStyle(color: Colors.grey[500]),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],

          // Description — gray background container (website style)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFF9FAFB),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  'Full Description',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  incident.description,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppTheme.textSecondary,
                        height: 1.5,
                      ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Metadata grid (website uses 2-column grid)
          _DetailGridRow(
            items: <_DetailGridItem>[
              if ((incident.location ?? '').isNotEmpty)
                _DetailGridItem(
                  icon: Icons.location_on_outlined,
                  label: 'Location',
                  value: incident.location!,
                ),
              if ((incident.blockName ?? '').isNotEmpty)
                _DetailGridItem(
                  icon: Icons.domain_outlined,
                  label: 'Block',
                  value: incident.blockName!,
                ),
              if ((incident.buildingName ?? '').isNotEmpty)
                _DetailGridItem(
                  icon: Icons.apartment_outlined,
                  label: 'Building',
                  value: incident.buildingName!,
                ),
              _DetailGridItem(
                icon: Icons.schedule_outlined,
                label: 'Reported',
                value:
                    '${formatCompactDate(incident.createdAt)}, ${formatClock(incident.createdAt)}',
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Close button — full-width (website style)
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

// ─── Detail grid for metadata (2-column layout) ─────────────────────

class _DetailGridItem {
  const _DetailGridItem({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;
}

class _DetailGridRow extends StatelessWidget {
  const _DetailGridRow({required this.items});

  final List<_DetailGridItem> items;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const SizedBox.shrink();

    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: items.map((_DetailGridItem item) {
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
                      style: Theme.of(context).textTheme.bodyMedium,
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

// ─── Error card ──────────────────────────────────────────────────────

class _TenantSecurityErrorCard extends StatelessWidget {
  const _TenantSecurityErrorCard({
    required this.message,
    required this.onRetry,
  });

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return CustomCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            'Unable to load security alerts',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            message,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppTheme.textSecondary,
                ),
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Retry'),
          ),
        ],
      ),
    );
  }
}
