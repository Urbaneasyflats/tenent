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

class AuditLogsPage extends StatefulWidget {
  const AuditLogsPage({super.key});

  @override
  State<AuditLogsPage> createState() => _AuditLogsPageState();
}

class _AuditLogsPageState extends State<AuditLogsPage> {
  final TextEditingController _searchController = TextEditingController();

  int _tabIndex = 0;
  bool _isLoading = true;
  String? _errorMessage;
  List<NotificationRecord> _notifications = <NotificationRecord>[];

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadNotifications() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final bool? read = switch (_tabIndex) {
        1 => false,
        2 => true,
        _ => null,
      };
      final result = await NotificationService.filterNotifications(
        limit: 100,
        read: read,
        search:
            _searchController.text.trim().isEmpty ? null : _searchController.text.trim(),
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _notifications = result.notifications
            .map((NotificationData item) => item.toNotificationRecord())
            .toList();
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

  Future<void> _markAllRead() async {
    try {
      await NotificationService.markAllAsRead();
      _showMessage('All notifications marked as read.');
      await _loadNotifications();
    } catch (error) {
      _showMessage(error.toString().replaceFirst('Exception: ', ''));
    }
  }

  Future<void> _markRead(NotificationRecord notification) async {
    try {
      await NotificationService.markAsRead(notification.id);
      _showMessage('Notification marked as read.');
      await _loadNotifications();
    } catch (error) {
      _showMessage(error.toString().replaceFirst('Exception: ', ''));
    }
  }

  @override
  Widget build(BuildContext context) {
    final int unreadCount =
        _notifications.where((NotificationRecord item) => !item.isRead).length;

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 16,
        title: const Text('Audit Logs'),
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1, thickness: 1, color: AppTheme.border),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _loadNotifications,
        child: ListView(
          padding: AppTheme.pagePadding,
          children: <Widget>[
            const PageHeader(
              title: 'Activity Log',
              description:
                  'Backend-backed vendor notifications used as the current live audit and activity trail.',
            ),
            const SizedBox(height: 16),
            Row(
              children: <Widget>[
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      labelText: 'Search activity',
                      suffixIcon: IconButton(
                        onPressed: _loadNotifications,
                        icon: const Icon(Icons.search_rounded),
                      ),
                    ),
                    onSubmitted: (_) => _loadNotifications(),
                  ),
                ),
                const SizedBox(width: 12),
                CustomButton(
                  label: 'Mark All Read',
                  variant: CustomButtonVariant.outline,
                  onPressed: unreadCount == 0 ? null : _markAllRead,
                ),
              ],
            ),
            const SizedBox(height: 16),
            CustomTabBar(
              style: CustomTabBarStyle.pill,
              currentIndex: _tabIndex,
              onChanged: (int index) {
                setState(() {
                  _tabIndex = index;
                });
                _loadNotifications();
              },
              tabs: const <CustomTabItem>[
                CustomTabItem(label: 'All'),
                CustomTabItem(label: 'Unread'),
                CustomTabItem(label: 'Read'),
              ],
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
                      'Unable to load activity',
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
                    const SizedBox(height: 16),
                    CustomButton(
                      label: 'Retry',
                      icon: const Icon(Icons.refresh_rounded),
                      onPressed: _loadNotifications,
                    ),
                  ],
                ),
              )
            else if (_notifications.isEmpty)
              const CustomCard(
                child: Text('No activity records match the current filter.'),
              )
            else
              ..._notifications.map((NotificationRecord notification) {
                final UiTone tone =
                    notification.isRead ? UiTone.neutral : UiTone.brand;
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
                                notification.title,
                                style: Theme.of(context).textTheme.titleMedium
                                    ?.copyWith(fontWeight: FontWeight.w600),
                              ),
                            ),
                            ToneBadge(
                              label: notification.isRead ? 'Read' : 'Unread',
                              tone: tone,
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          notification.message,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: AppTheme.textSecondary,
                              ),
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: <Widget>[
                            ToneBadge(
                              label: notification.type,
                              tone: UiTone.neutral,
                            ),
                            ToneBadge(
                              label:
                                  '${formatCompactDate(notification.createdAt)} ${formatClock(notification.createdAt)}',
                              tone: UiTone.neutral,
                            ),
                          ],
                        ),
                        if (!notification.isRead) ...<Widget>[
                          const SizedBox(height: 14),
                          SizedBox(
                            width: double.infinity,
                            child: CustomButton(
                              label: 'Mark Read',
                              variant: CustomButtonVariant.outline,
                              onPressed: () => _markRead(notification),
                            ),
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
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }
}
