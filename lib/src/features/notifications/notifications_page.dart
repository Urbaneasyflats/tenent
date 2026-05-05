import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/api/notification_service.dart';
import '../../core/models/api_models.dart';
import '../../core/models/app_models.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/custom_button.dart';
import '../../core/widgets/custom_card.dart';
import '../../core/widgets/custom_tab_bar.dart';
import '../../core/widgets/page_header.dart';
import '../../core/widgets/tone_badge.dart';

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  static const int _pageSize = 10;

  final TextEditingController _searchController = TextEditingController();
  Timer? _debounce;

  // 0 = All, 1 = Unread, 2 = Read
  int _filterTab = 0;

  List<NotificationData> _notifications = <NotificationData>[];
  int _totalCount = 0;
  int _unreadCount = 0;
  int _skip = 0;
  bool _isLoading = true;
  String? _errorMessage;

  bool? get _readFilter => switch (_filterTab) {
        1 => false, // unread
        2 => true, // read
        _ => null, // all
      };

  @override
  void initState() {
    super.initState();
    _loadNotifications(reset: true);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  Future<void> _loadNotifications({bool reset = false}) async {
    final int skip = reset ? 0 : _skip;
    if (reset) {
      setState(() {
        _skip = 0;
        _isLoading = true;
        _errorMessage = null;
      });
    } else {
      setState(() => _isLoading = true);
    }

    try {
      final String? search = _searchController.text.trim().isEmpty
          ? null
          : _searchController.text.trim();

      final result = await NotificationService.filterNotifications(
        skip: skip,
        limit: _pageSize,
        read: _readFilter,
        search: search,
      );

      if (!mounted) return;

      setState(() {
        if (reset) {
          _notifications = result.notifications;
        } else {
          _notifications = <NotificationData>[
            ..._notifications,
            ...result.notifications,
          ];
        }
        _totalCount = result.count;
        _unreadCount = result.unreadCount;
        _skip = skip + result.notifications.length;
        _isLoading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _errorMessage = error.toString().replaceFirst('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  void _onSearchChanged(String _) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () {
      _loadNotifications(reset: true);
    });
  }

  Future<void> _markAsRead(NotificationData notification) async {
    try {
      await NotificationService.markAsRead(notification.notificationId);
      await _loadNotifications(reset: true);
    } catch (error) {
      _showMessage(error.toString().replaceFirst('Exception: ', ''));
    }
  }

  Future<void> _markAllAsRead() async {
    try {
      await NotificationService.markAllAsRead();
      await _loadNotifications(reset: true);
      _showMessage('All notifications marked as read.');
    } catch (error) {
      _showMessage(error.toString().replaceFirst('Exception: ', ''));
    }
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final bool hasMore = _skip < _totalCount;
    final bool hasUnread = _unreadCount > 0;

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 16,
        title: const Text('Notifications'),
        actions: <Widget>[
          if (hasUnread)
            TextButton(
              onPressed: _markAllAsRead,
              child: const Text('Mark all read'),
            ),
          const SizedBox(width: 4),
        ],
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1, thickness: 1, color: AppTheme.border),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: () => _loadNotifications(reset: true),
        child: ListView(
          padding: AppTheme.pagePadding,
          children: <Widget>[
            const PageHeader(
              title: 'Notifications',
              description:
                  'Activity alerts, payment updates, and system messages.',
            ),
            const SizedBox(height: 16),
            // Search
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                labelText: 'Search notifications',
                suffixIcon: IconButton(
                  icon: const Icon(Icons.search_rounded),
                  onPressed: () => _loadNotifications(reset: true),
                ),
              ),
              onChanged: _onSearchChanged,
            ),
            const SizedBox(height: 12),
            // Filter tabs
            CustomTabBar(
              style: CustomTabBarStyle.pill,
              currentIndex: _filterTab,
              onChanged: (int index) {
                setState(() => _filterTab = index);
                _loadNotifications(reset: true);
              },
              tabs: <CustomTabItem>[
                const CustomTabItem(label: 'All'),
                CustomTabItem(
                  label: _unreadCount > 0 ? 'Unread ($_unreadCount)' : 'Unread',
                ),
                const CustomTabItem(label: 'Read'),
              ],
            ),
            const SizedBox(height: 16),
            // List
            if (_isLoading && _notifications.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 64),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_errorMessage != null && _notifications.isEmpty)
              CustomCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      'Unable to load notifications',
                      style: theme.textTheme.titleMedium
                          ?.copyWith(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _errorMessage!,
                      style: theme.textTheme.bodyMedium
                          ?.copyWith(color: AppTheme.textSecondary),
                    ),
                    const SizedBox(height: 16),
                    CustomButton(
                      label: 'Retry',
                      icon: const Icon(Icons.refresh_rounded),
                      onPressed: () => _loadNotifications(reset: true),
                    ),
                  ],
                ),
              )
            else if (_notifications.isEmpty)
              const CustomCard(
                padding: CustomCardPadding.sm,
                child: Text('No notifications found.'),
              )
            else ...<Widget>[
              ..._notifications.map(
                (NotificationData n) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _NotificationCard(
                    notification: n,
                    onMarkRead: n.isRead ? null : () => _markAsRead(n),
                  ),
                ),
              ),
              if (_isLoading)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (hasMore)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: () => _loadNotifications(),
                      child: Text(
                          'Load More (${_totalCount - _skip} remaining)'),
                    ),
                  ),
                )
              else
                Padding(
                  padding: const EdgeInsets.only(top: 4, bottom: 8),
                  child: Center(
                    child: Text(
                      'All $_totalCount notifications loaded',
                      style: theme.textTheme.bodySmall
                          ?.copyWith(color: AppTheme.textMuted),
                    ),
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }
}

class _NotificationCard extends StatelessWidget {
  const _NotificationCard({
    required this.notification,
    required this.onMarkRead,
  });

  final NotificationData notification;
  final VoidCallback? onMarkRead;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final UiTone tone = _typeTone(notification.type);
    final String typeLabel = _typeLabel(notification.type);

    return CustomCard(
      padding: CustomCardPadding.sm,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              // Unread dot
              if (!notification.isRead) ...<Widget>[
                Container(
                  width: 8,
                  height: 8,
                  margin: const EdgeInsets.only(top: 6, right: 10),
                  decoration: const BoxDecoration(
                    color: AppTheme.primary,
                    shape: BoxShape.circle,
                  ),
                ),
              ] else
                const SizedBox(width: 18),
              Expanded(
                child: Text(
                  notification.title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: notification.isRead
                        ? FontWeight.w500
                        : FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              ToneBadge(label: typeLabel, tone: tone, size: ToneBadgeSize.small),
            ],
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.only(left: 18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  notification.message,
                  style: theme.textTheme.bodyMedium
                      ?.copyWith(color: AppTheme.textSecondary),
                ),
                const SizedBox(height: 8),
                Text(
                  '${formatCompactDate(notification.createdAt)} at ${formatClock(notification.createdAt)}',
                  style: theme.textTheme.bodySmall
                      ?.copyWith(color: AppTheme.textMuted),
                ),
                if (onMarkRead != null) ...<Widget>[
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: onMarkRead,
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: const Text('Mark as Read'),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  static String _typeLabel(String type) {
    return switch (type.toLowerCase()) {
      'payment' || 'billing' || '1' => 'Payment',
      'support' || 'ticket' || '2' => 'Support',
      'contract' || '3' => 'Contract',
      'enquiry' || 'lead' || '4' => 'Enquiry',
      'security' || '5' => 'Security',
      'announcement' || 'notice' || '6' => 'Notice',
      'system' || '7' => 'System',
      _ => 'Alert',
    };
  }

  static UiTone _typeTone(String type) {
    return switch (type.toLowerCase()) {
      'payment' || 'billing' || '1' => UiTone.success,
      'support' || 'ticket' || '2' => UiTone.brand,
      'contract' || '3' => UiTone.brand,
      'enquiry' || 'lead' || '4' => UiTone.warning,
      'security' || '5' => UiTone.danger,
      'announcement' || 'notice' || '6' => UiTone.brand,
      'system' || '7' => UiTone.neutral,
      _ => UiTone.neutral,
    };
  }
}
