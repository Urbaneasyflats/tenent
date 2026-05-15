import 'dart:async';

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/api/notification_service.dart';
import '../../core/models/api_models.dart';
import '../../core/models/app_models.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/custom_button.dart';
import '../../core/widgets/custom_card.dart';
import '../../core/widgets/custom_tab_bar.dart';
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
      backgroundColor: const Color(0xFFF5F5F7),
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
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 18),
          children: <Widget>[
            _NotificationSummaryBar(
              totalCount: _totalCount,
              unreadCount: _unreadCount,
              onMarkAllRead: hasUnread ? _markAllAsRead : null,
            ),
            const SizedBox(height: 10),
            // Search
            SizedBox(
              height: 46,
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Search notifications',
                  prefixIcon: const Icon(Icons.search_rounded, size: 20),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.arrow_forward_rounded, size: 18),
                    onPressed: () => _loadNotifications(reset: true),
                  ),
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                ),
                onChanged: _onSearchChanged,
              ),
            ),
            const SizedBox(height: 8),
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
            const SizedBox(height: 10),
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
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _errorMessage!,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: AppTheme.textSecondary,
                      ),
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
              ..._buildNotificationSections(),
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
                        'Load More (${_totalCount - _skip} remaining)',
                      ),
                    ),
                  ),
                )
              else
                Padding(
                  padding: const EdgeInsets.only(top: 4, bottom: 8),
                  child: Center(
                    child: Text(
                      'All $_totalCount notifications loaded',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: AppTheme.textMuted,
                      ),
                    ),
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }

  List<Widget> _buildNotificationSections() {
    final Map<_NotificationCategory, List<NotificationData>> grouped =
        <_NotificationCategory, List<NotificationData>>{};

    for (final NotificationData notification in _notifications) {
      final _NotificationCategory category = _NotificationCategory.from(
        notification,
      );
      grouped
          .putIfAbsent(category, () => <NotificationData>[])
          .add(notification);
    }

    final List<Widget> widgets = <Widget>[];
    for (final _NotificationCategory category in _notificationCategoryOrder) {
      final List<NotificationData> categoryNotifications =
          grouped[category] ?? <NotificationData>[];
      if (categoryNotifications.isEmpty) continue;

      if (widgets.isNotEmpty) {
        widgets.add(const SizedBox(height: 4));
      }
      widgets.add(
        _NotificationSectionHeader(
          category: category,
          count: categoryNotifications.length,
        ),
      );
      widgets.add(const SizedBox(height: 6));

      widgets.addAll(
        categoryNotifications.map(
          (NotificationData notification) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: _NotificationCard(
              notification: notification,
              onMarkRead: notification.isRead
                  ? null
                  : () => _markAsRead(notification),
            ),
          ),
        ),
      );
    }

    return widgets;
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }
}

const List<_NotificationCategory> _notificationCategoryOrder =
    <_NotificationCategory>[
      _NotificationCategory.billing,
      _NotificationCategory.contracts,
      _NotificationCategory.communication,
      _NotificationCategory.support,
      _NotificationCategory.enquiries,
      _NotificationCategory.security,
      _NotificationCategory.system,
      _NotificationCategory.other,
    ];

enum _NotificationCategory {
  communication(
    'Communication',
    'Announcements, notices, and resident messages',
    'Source: Communication workflow',
    UiTone.brand,
  ),
  support(
    'Support Tickets',
    'New tickets and ticket status updates',
    'Source: Support ticket workflow',
    UiTone.brand,
  ),
  billing(
    'Billing',
    'Bills, payments, collections, and reminders',
    'Source: Billing workflow',
    UiTone.success,
  ),
  contracts(
    'Contracts',
    'Rental contract activity and contract-linked billing',
    'Source: Rental contract workflow',
    UiTone.brand,
  ),
  enquiries(
    'Enquiries',
    'Property leads and enquiry follow-ups',
    'Source: Property enquiry workflow',
    UiTone.warning,
  ),
  security(
    'Security',
    'Security incidents and urgent alerts',
    'Source: Security workflow',
    UiTone.danger,
  ),
  system(
    'System',
    'Account, app, and platform updates',
    'Source: System workflow',
    UiTone.neutral,
  ),
  other(
    'Other Notifications',
    'General notifications from the platform',
    'Source: General workflow',
    UiTone.neutral,
  );

  const _NotificationCategory(
    this.label,
    this.description,
    this.sourceLabel,
    this.tone,
  );

  final String label;
  final String description;
  final String sourceLabel;
  final UiTone tone;

  IconData get icon {
    return switch (this) {
      _NotificationCategory.communication => Icons.campaign_rounded,
      _NotificationCategory.support => Icons.confirmation_number_rounded,
      _NotificationCategory.billing => Icons.account_balance_wallet_rounded,
      _NotificationCategory.contracts => Icons.description_rounded,
      _NotificationCategory.enquiries => Icons.person_search_rounded,
      _NotificationCategory.security => Icons.security_rounded,
      _NotificationCategory.system => Icons.settings_suggest_rounded,
      _NotificationCategory.other => Icons.notifications_rounded,
    };
  }

  static _NotificationCategory from(NotificationData notification) {
    final String type = notification.type.toLowerCase().trim();
    final String reference = notification.referenceType.toLowerCase().trim();
    final String content =
        '$type $reference ${notification.title} ${notification.message}'
        .toLowerCase();

    if (type == 'billing' ||
        type == 'payment' ||
        type == '1' ||
        type == '5' ||
        content.contains('bill') ||
        content.contains('wallet') ||
        content.contains('billing') ||
        content.contains('payment') ||
        content.contains('paid') ||
        content.contains('collection') ||
        content.contains('razorpay')) {
      return _NotificationCategory.billing;
    }
    if (type == 'contract' ||
        type == '2' ||
        content.contains('contract') ||
        content.contains('lease')) {
      return _NotificationCategory.contracts;
    }
    if (type == 'announcement' ||
        type == 'notice' ||
        type == '3' ||
        content.contains('communication') ||
        content.contains('announcement') ||
        content.contains('notice')) {
      return _NotificationCategory.communication;
    }
    if (type == 'support' ||
        type == 'ticket' ||
        type == '4' ||
        content.contains('support') ||
        content.contains('ticket')) {
      return _NotificationCategory.support;
    }
    if (type == 'enquiry' ||
        type == 'lead' ||
        type == '6' ||
        content.contains('enquiry') ||
        content.contains('inquiry') ||
        content.contains('lead')) {
      return _NotificationCategory.enquiries;
    }
    if (type == 'security' ||
        content.contains('security') ||
        content.contains('incident')) {
      return _NotificationCategory.security;
    }
    if (type == 'system' || type == '7' || content.contains('system')) {
      return _NotificationCategory.system;
    }
    return _NotificationCategory.other;
  }
}

class _NotificationSectionHeader extends StatelessWidget {
  const _NotificationSectionHeader({
    required this.category,
    required this.count,
  });

  final _NotificationCategory category;
  final int count;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Row(
      children: <Widget>[
        Icon(category.icon, size: 16, color: AppTheme.toneColor(category.tone)),
        const SizedBox(width: 7),
        Expanded(
          child: Text(
            category.label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w900,
              color: AppTheme.textPrimary,
            ),
          ),
        ),
        const SizedBox(width: 8),
        ToneBadge(
          label: '$count',
          tone: category.tone,
          size: ToneBadgeSize.small,
        ),
      ],
    );
  }
}

class _NotificationSummaryBar extends StatelessWidget {
  const _NotificationSummaryBar({
    required this.totalCount,
    required this.unreadCount,
    required this.onMarkAllRead,
  });

  final int totalCount;
  final int unreadCount;
  final VoidCallback? onMarkAllRead;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 10, 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFECEEF3)),
      ),
      child: Row(
        children: <Widget>[
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: AppTheme.primary.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.notifications_rounded,
              color: AppTheme.primary,
              size: 20,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  '$totalCount notifications',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w900,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  unreadCount > 0 ? '$unreadCount unread' : 'All caught up',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AppTheme.textMuted,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          if (onMarkAllRead != null)
            TextButton(
              onPressed: onMarkAllRead,
              style: TextButton.styleFrom(
                visualDensity: VisualDensity.compact,
                padding: const EdgeInsets.symmetric(horizontal: 8),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: const Text('Mark read'),
            ),
        ],
      ),
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
    final _NotificationCategory category = _NotificationCategory.from(
      notification,
    );
    final String propertyImageUrl = _propertyImageUrl(notification, category);
    final NotificationDisplayModel display =
        NotificationDisplayModel.fromNotification(
      notification,
      category: category,
    );

    return Container(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: const Color(0xFFECEEF3)),
        boxShadow: const <BoxShadow>[
          BoxShadow(
            color: Color(0x17111827),
            blurRadius: 24,
            offset: Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          _NotificationTopSection(
            display: display,
            logo: _NotificationLogo(
              category: category,
              isRead: notification.isRead,
            ),
            tone: category.tone,
          ),
          if (display.typeChips.isNotEmpty) ...<Widget>[
            const SizedBox(height: 10),
            _NotificationTypeChips(chips: display.typeChips, tone: category.tone),
          ],
          if (propertyImageUrl.isNotEmpty) ...<Widget>[
            const SizedBox(height: 12),
            _NotificationImagePreview(
              imageUrl: propertyImageUrl,
              tone: category.tone,
            ),
          ],
          const SizedBox(height: 12),
          _NotificationMessageSection(display: display),
          if (display.phone.isNotEmpty) ...<Widget>[
            const SizedBox(height: 10),
            _ContactChip(
              phone: display.phone,
              onTap: () => _launchPhone(display.phone),
            ),
          ],
          if (display.contextDetails.isNotEmpty) ...<Widget>[
            const SizedBox(height: 8),
            _NotificationContextSection(
              details: display.contextDetails,
              onPhoneTap: _launchPhone,
            ),
          ],
          const SizedBox(height: 8),
          _NotificationActions(
            onMarkRead: onMarkRead,
            onViewDetails: () => _showDetailsSheet(context, display),
          ),
        ],
      ),
    );
  }

  static Future<void> _launchPhone(String phone) async {
    await launchUrl(Uri.parse('tel:${_digitsForDial(phone)}'));
  }

  static void _showDetailsSheet(
    BuildContext context,
    NotificationDisplayModel display,
  ) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (BuildContext context) => _NotificationDetailsSheet(
        display: display,
      ),
    );
  }

  static String _digitsForDial(String phone) {
    return phone.replaceAll(RegExp(r'[^0-9+]'), '');
  }

  static String _dataText(NotificationData notification, String key) {
    final Object? value = notification.data[key];
    final String text = value == null ? '' : '$value'.trim();
    return text == 'null' ? '' : text;
  }

  static String _propertyImageUrl(
    NotificationData notification,
    _NotificationCategory category,
  ) {
    if (category.label != 'Enquiry') return '';
    return _firstDataText(notification, <String>[
      'Property_Image_URL',
      'Property_Image_Original_URL',
      'Image_Original_URL',
      'Image_URL',
    ]);
  }

  static String _firstDataText(NotificationData notification, List<String> keys) {
    for (final String key in keys) {
      final String value = _dataText(notification, key);
      if (value.isNotEmpty) return value;
    }
    return '';
  }

}

class _NotificationLogo extends StatelessWidget {
  const _NotificationLogo({
    required this.category,
    required this.isRead,
  });

  final _NotificationCategory category;
  final bool isRead;

  @override
  Widget build(BuildContext context) {
    final Color toneColor = AppTheme.toneColor(category.tone);
    return Stack(
      clipBehavior: Clip.none,
      children: <Widget>[
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: const Color(0xFFE5E7EB)),
          ),
          clipBehavior: Clip.antiAlias,
          child: Image.asset(
            'assets/tenenet_logo.jpg',
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) =>
                Icon(Icons.home_work_rounded, color: toneColor),
          ),
        ),
        Positioned(
          right: -5,
          bottom: -5,
          child: Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: AppTheme.surface,
              shape: BoxShape.circle,
              border: Border.all(color: AppTheme.border),
            ),
            child: Icon(category.icon, size: 14, color: toneColor),
          ),
        ),
        if (!isRead)
          Positioned(
            top: -3,
            right: -3,
            child: Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                color: AppTheme.primary,
                shape: BoxShape.circle,
                border: Border.all(color: AppTheme.surface, width: 2),
              ),
            ),
          ),
      ],
    );
  }
}

class _NotificationTopSection extends StatelessWidget {
  const _NotificationTopSection({
    required this.display,
    required this.logo,
    required this.tone,
  });

  final NotificationDisplayModel display;
  final Widget logo;
  final UiTone tone;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Semantics(label: '${display.category} notification', child: logo),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Expanded(
                    child: Wrap(
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 5,
                      children: <Widget>[
                        const Text(
                          'Urban EasyFlats',
                          style: TextStyle(
                            color: Color(0xFF111827),
                            fontSize: 14,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        Text(
                          '• ${display.category} • ${display.time}',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: AppTheme.textMuted,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 6),
                  if (!display.isRead)
                    Container(
                      width: 9,
                      height: 9,
                      decoration: const BoxDecoration(
                        color: AppTheme.primary,
                        shape: BoxShape.circle,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 9),
              Text(
                display.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.titleLarge?.copyWith(
                  color: const Color(0xFF111827),
                  fontSize: 20,
                  height: 1.18,
                  fontWeight: display.isRead ? FontWeight.w800 : FontWeight.w900,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _NotificationTypeChips extends StatelessWidget {
  const _NotificationTypeChips({required this.chips, required this.tone});

  final List<String> chips;
  final UiTone tone;

  @override
  Widget build(BuildContext context) {
    final Color toneColor = AppTheme.toneColor(tone);
    return Wrap(
      spacing: 7,
      runSpacing: 7,
      children: chips
          .map(
            (String chip) => Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: AppTheme.toneSoft(tone),
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: AppTheme.toneContainer(tone)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Icon(_typeIcon(chip), size: 14, color: toneColor),
                  const SizedBox(width: 6),
                  Text(
                    chip,
                    style: TextStyle(
                      color: toneColor,
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
            ),
          )
          .toList(),
    );
  }

  IconData _typeIcon(String chip) {
    final String value = chip.toLowerCase();
    if (value.contains('pg')) return Icons.groups_2_rounded;
    if (value.contains('resident')) return Icons.person_rounded;
    if (value.contains('villa')) return Icons.villa_rounded;
    if (value.contains('village')) return Icons.holiday_village_rounded;
    if (value.contains('apartment')) return Icons.apartment_rounded;
    if (value.contains('commercial')) return Icons.store_mall_directory_rounded;
    return Icons.home_work_rounded;
  }
}

class _NotificationMeta extends StatelessWidget {
  const _NotificationMeta({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Icon(icon, size: 14, color: theme.colorScheme.onSurfaceVariant),
        const SizedBox(width: 4),
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

class _NotificationMessageSection extends StatelessWidget {
  const _NotificationMessageSection({required this.display});

  final NotificationDisplayModel display;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Text(
      display.message,
      maxLines: 3,
      overflow: TextOverflow.ellipsis,
      style: theme.textTheme.bodyMedium?.copyWith(
        color: const Color(0xFF404040),
        height: 1.34,
        fontSize: 15,
        fontWeight: FontWeight.w700,
      ),
    );
  }
}

class _ContactChip extends StatelessWidget {
  const _ContactChip({required this.phone, required this.onTap});

  final String phone;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
        decoration: BoxDecoration(
          color: const Color(0xFFE0F2FE),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: const Color(0xFFBAE6FD)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            const Icon(Icons.call_rounded, size: 14, color: Color(0xFF0284C7)),
            const SizedBox(width: 5),
            Text(
              phone,
              style: const TextStyle(
                color: AppTheme.primary,
                fontSize: 12,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NotificationContextSection extends StatelessWidget {
  const _NotificationContextSection({
    required this.details,
    required this.onPhoneTap,
  });

  final List<_NotificationDetail> details;
  final ValueChanged<String> onPhoneTap;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        ...details.map(
          (_NotificationDetail detail) => _NotificationInfoRow(
            detail: detail,
            onTap: detail.isPhone ? () => onPhoneTap(detail.value) : null,
          ),
        ),
      ],
    );
  }
}

class _NotificationInfoRow extends StatelessWidget {
  const _NotificationInfoRow({required this.detail, this.onTap});

  final _NotificationDetail detail;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final Widget content = Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Icon(detail.icon, size: 17, color: theme.colorScheme.onSurfaceVariant),
          const SizedBox(width: 8),
          SizedBox(
            width: 78,
            child: Text(
              detail.label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w800,
                fontSize: 11,
              ),
            ),
          ),
          Expanded(
            child: Text(
              detail.value,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface,
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
    if (onTap == null) return content;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
      child: content,
    );
  }
}

class _NotificationActions extends StatelessWidget {
  const _NotificationActions({
    required this.onMarkRead,
    required this.onViewDetails,
  });

  final VoidCallback? onMarkRead;
  final VoidCallback? onViewDetails;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 7,
      runSpacing: 6,
      children: <Widget>[
        OutlinedButton.icon(
          onPressed: onViewDetails,
          style: OutlinedButton.styleFrom(
            visualDensity: VisualDensity.compact,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          ),
          icon: const Icon(Icons.open_in_new_rounded, size: 16),
          label: const Text('Details'),
        ),
        if (onMarkRead != null)
          OutlinedButton.icon(
            onPressed: onMarkRead,
            style: OutlinedButton.styleFrom(
              visualDensity: VisualDensity.compact,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            ),
            icon: const Icon(Icons.done_all_rounded, size: 16),
            label: const Text('Read'),
          ),
      ],
    );
  }
}

class _NotificationDetailsSheet extends StatelessWidget {
  const _NotificationDetailsSheet({required this.display});

  final NotificationDisplayModel display;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          bottom: 20 + MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              display.title,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 6),
            _NotificationMeta(
              icon: Icons.schedule_rounded,
              label: display.time,
            ),
            const SizedBox(height: 14),
            Text(
              display.message,
              style: theme.textTheme.bodyMedium?.copyWith(height: 1.4),
            ),
            if (display.contextDetails.isNotEmpty) ...<Widget>[
              const SizedBox(height: 14),
              _NotificationContextSection(
                details: display.contextDetails,
                onPhoneTap: (_) {},
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _NotificationImagePreview extends StatelessWidget {
  const _NotificationImagePreview({required this.imageUrl, required this.tone});

  final String imageUrl;
  final UiTone tone;

  @override
  Widget build(BuildContext context) {
    final Color toneColor = AppTheme.toneColor(tone);
    return ClipRRect(
      borderRadius: BorderRadius.circular(22),
      child: AspectRatio(
        aspectRatio: 16 / 9,
        child: Image.network(
          imageUrl,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => Container(
            color: AppTheme.toneSoft(tone),
            alignment: Alignment.center,
            child: Icon(Icons.apartment_rounded, color: toneColor),
          ),
        ),
      ),
    );
  }
}

class _NotificationDetail {
  const _NotificationDetail({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  bool get isPhone => label.toLowerCase().contains('phone');
}

class NotificationDisplayModel {
  const NotificationDisplayModel({
    required this.title,
    required this.message,
    required this.category,
    required this.time,
    required this.isRead,
    required this.contextDetails,
    required this.phone,
    required this.typeChips,
  });

  final String title;
  final String message;
  final String category;
  final String time;
  final bool isRead;
  final List<_NotificationDetail> contextDetails;
  final String phone;
  final List<String> typeChips;

  factory NotificationDisplayModel.fromNotification(
    NotificationData notification, {
    required _NotificationCategory category,
  }) {
    final bool isEnquiry = category.label == 'Enquiry';
    final bool isAnnouncement = category == _NotificationCategory.communication;
    final String title = notification.title.trim().isEmpty
        ? category.label
        : notification.title.trim();
    final String phone = _firstDataText(notification, <String>[
      'PhoneNumber',
      'Phone',
      'Tenant_PhoneNumber',
      'Resident_PhoneNumber',
    ]);
    final String propertyName = _firstDataText(notification, <String>[
      'Property_Title',
      'Property_Name',
      'Society_Name',
    ]);
    final String apartmentType = _firstDataText(notification, <String>[
      'Apartment_Type_Label',
      'Sub_Type_Label',
      'Property_Sub_Type_Label',
      'Flat_Or_Unit_No',
      'Property_Type_Label',
    ]);
    final String propertyType = _readPropertyType(notification);
    final String residentType = _readResidentType(notification);
    final String priority = _firstDataText(notification, <String>[
      'Priority_Label',
      'Priority',
    ]);
    final String target = _firstDataText(notification, <String>[
      'Announcement_Target_Label',
    ]);
    final String blockNames = _firstDataText(notification, <String>[
      'Block_Names',
      'Block_Name',
    ]);
    final String buildingNames = _firstDataText(notification, <String>[
      'Building_Names',
      'Building_Name',
    ]);
    final String summary = isEnquiry
        ? _buildEnquirySummary(
            apartmentType: apartmentType,
            propertyName: propertyName,
          )
        : (notification.message.trim().isEmpty
            ? 'No message details were provided.'
            : notification.message.trim());

    final List<_NotificationDetail> details = <_NotificationDetail>[
      if (propertyName.isNotEmpty)
        _NotificationDetail(
          icon: Icons.apartment_rounded,
          label: isAnnouncement ? 'Society' : 'Property',
          value: propertyName,
        ),
      if (isAnnouncement && priority.isNotEmpty)
        _NotificationDetail(
          icon: Icons.flag_rounded,
          label: 'Priority',
          value: _priorityLabel(priority),
        ),
      if (isAnnouncement && target.isNotEmpty)
        _NotificationDetail(
          icon: Icons.groups_rounded,
          label: 'Target',
          value: target,
        ),
      if (isAnnouncement && blockNames.isNotEmpty)
        _NotificationDetail(
          icon: Icons.domain_rounded,
          label: 'Block',
          value: blockNames,
        ),
      if (isAnnouncement && buildingNames.isNotEmpty)
        _NotificationDetail(
          icon: Icons.location_city_rounded,
          label: 'Building',
          value: buildingNames,
        ),
      if (propertyType.isNotEmpty)
        _NotificationDetail(
          icon: Icons.home_work_rounded,
          label: 'Type',
          value: propertyType,
        ),
      if (residentType.isNotEmpty)
        _NotificationDetail(
          icon: Icons.person_rounded,
          label: 'Resident',
          value: residentType,
        ),
    ];

    final List<String> typeChips = <String>[
      if (residentType.isNotEmpty) residentType,
      if (propertyType.isNotEmpty) propertyType,
      if (apartmentType.isNotEmpty && apartmentType != propertyType)
        apartmentType,
    ];

    return NotificationDisplayModel(
      title: title,
      message: summary,
      category: category.label,
      time:
          '${formatCompactDate(notification.createdAt)} at ${formatClock(notification.createdAt)}',
      isRead: notification.isRead,
      contextDetails: details,
      phone: phone,
      typeChips: typeChips,
    );
  }

  static String _readPropertyType(NotificationData notification) {
    final String label = _firstDataText(notification, <String>[
      'Property_Type_Label',
      'PropertyTypeLabel',
      'Property_Type_Name',
      'Apartment_Type',
      'Apartment_Type_Label',
    ]);
    if (label.isNotEmpty) {
      return _normalizeTypeLabel(label);
    }

    final String raw = _firstDataText(notification, <String>[
      'Property_Type',
      'PropertyType',
    ]);
    return switch (raw.trim()) {
      '1' => 'Apartment',
      '2' => 'Villa',
      '3' => 'PG',
      '4' => 'Commercial',
      _ => _normalizeTypeLabel(raw),
    };
  }

  static String _readResidentType(NotificationData notification) {
    final String label = _firstDataText(notification, <String>[
      'Resident_Type_Label',
      'ResidentTypeLabel',
      'Tenant_Type_Label',
    ]);
    if (label.isNotEmpty) {
      return _normalizeTypeLabel(label);
    }

    final String raw = _firstDataText(notification, <String>[
      'Resident_Type',
      'ResidentType',
      'Tenant_Type',
    ]);
    return switch (raw.trim()) {
      '1' => 'Resident',
      '2' => 'Owner',
      '3' => 'PG Resident',
      '4' => 'Visitor',
      _ => _normalizeTypeLabel(raw),
    };
  }

  static String _normalizeTypeLabel(String value) {
    final String normalized = value.trim();
    if (normalized.isEmpty || normalized == 'null') return '';
    final String lower = normalized.toLowerCase();
    if (lower == 'pg') return 'PG';
    if (lower.contains('village')) return 'Village';
    if (lower.contains('villa')) return 'Villa';
    if (lower.contains('apartment') || lower.contains('flat')) {
      return 'Apartment';
    }
    if (lower.contains('resident')) return 'Resident';
    return normalized;
  }

  static String _buildEnquirySummary({
    required String apartmentType,
    required String propertyName,
  }) {
    final String home = apartmentType.isEmpty ? 'property' : apartmentType;
    if (propertyName.isEmpty) {
      return 'A customer is interested in your $home.';
    }
    return 'A customer is interested in your $home at $propertyName.';
  }

  static String _firstDataText(
    NotificationData notification,
    List<String> keys,
  ) {
    for (final String key in keys) {
      final Object? value = notification.data[key];
      final String text = _displayText(value);
      if (text.isNotEmpty && text != 'null') return text;
    }
    return '';
  }

  static String _displayText(Object? value) {
    if (value == null) return '';
    if (value is List) {
      return value
          .map((Object? item) => '$item'.trim())
          .where((String item) => item.isNotEmpty && item != 'null')
          .join(', ');
    }
    return '$value'.trim();
  }

  static String _priorityLabel(String value) {
    return switch (value.trim()) {
      '1' => 'Low',
      '2' => 'Medium',
      '3' => 'High',
      '4' => 'Critical',
      _ => value,
    };
  }
}
