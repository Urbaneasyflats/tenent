import 'package:flutter/material.dart';

import '../../core/models/api_models.dart';
import '../../core/models/app_models.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/custom_button.dart';
import '../../core/widgets/custom_card.dart';
import '../../core/widgets/page_header.dart';
import '../../core/widgets/tone_badge.dart';

class DashboardPage extends StatelessWidget {
  const DashboardPage({
    super.key,
    required this.role,
    required this.metrics,
    required this.shortcuts,
    required this.announcements,
    required this.tickets,
    required this.onShortcutSelected,
    this.bills = const <BillRecord>[],
    this.vendor,
    this.societyInfo,
    this.blockCount = 0,
    this.buildingCount = 0,
    this.isLoading = false,
    this.onRefresh,
  });

  final AppRole role;
  final List<DashboardMetric> metrics;
  final List<AppShortcut> shortcuts;
  final List<AnnouncementRecord> announcements;
  final List<TicketRecord> tickets;
  final List<BillRecord> bills;
  final ValueChanged<String> onShortcutSelected;
  final VendorData? vendor;
  final SocietyData? societyInfo;
  final int blockCount;
  final int buildingCount;
  final bool isLoading;
  final VoidCallback? onRefresh;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final List<TicketRecord> ticketPreview = tickets.take(2).toList();
    final List<AnnouncementRecord> announcementPreview = announcements
        .take(2)
        .toList();
    final List<Widget> roleSections = _buildRoleSections(context);

    if (role == AppRole.tenant ||
        role == AppRole.owner ||
        role == AppRole.pgResident) {
      Widget residentContent = _buildResidentDashboard(
        context,
        ticketPreview: ticketPreview,
        announcementPreview: announcementPreview,
      );
      if (onRefresh != null) {
        residentContent = RefreshIndicator(
          onRefresh: () async => onRefresh!(),
          child: residentContent,
        );
      }
      return residentContent;
    }

    Widget content = ListView(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 124),
      children: <Widget>[
        PageHeader(title: 'Dashboard', description: role.homeHeadline),
        const SizedBox(height: 16),
        CustomCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              ToneBadge(label: role.label, tone: UiTone.brand),
              const SizedBox(height: 14),
              Text(
                'Welcome back',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Your mobile dashboard is connected to the same backend summaries and module flows used by the website.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: AppTheme.textSecondary,
                ),
              ),
            ],
          ),
        ),
        if (isLoading) ...<Widget>[
          const SizedBox(height: 24),
          const Center(child: CircularProgressIndicator()),
          const SizedBox(height: 24),
        ],
        const SizedBox(height: 16),
        _metricGrid(metrics),
        if (roleSections.isNotEmpty) ...<Widget>[
          const SizedBox(height: 24),
          ...roleSections,
        ],
        const SizedBox(height: 24),
        Text(
          'Quick actions',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        ...shortcuts.map((AppShortcut shortcut) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: CustomCard(
              onTap: () => onShortcutSelected(shortcut.actionKey),
              padding: CustomCardPadding.sm,
              child: Row(
                children: <Widget>[
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: AppTheme.primarySoft,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(shortcut.icon, color: AppTheme.primary),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          shortcut.title,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          shortcut.subtitle,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: AppTheme.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 16,
                    color: AppTheme.textMuted,
                  ),
                ],
              ),
            ),
          );
        }),
        const SizedBox(height: 12),
        Text(
          'Recent signals',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        ...ticketPreview.map((TicketRecord ticket) {
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
                          ticket.title,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      ToneBadge(
                        label: ticket.status.label,
                        tone: ticket.status.tone,
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    ticket.description,
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
                        label: ticket.priority.label,
                        tone: ticket.priority.tone,
                      ),
                      ToneBadge(label: ticket.category, tone: UiTone.neutral),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Updated ${formatCompactDate(ticket.updatedAt)} at ${formatClock(ticket.updatedAt)}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: AppTheme.textMuted,
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
        const SizedBox(height: 12),
        Text(
          'Announcements',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        ...announcementPreview.map((AnnouncementRecord announcement) {
          final UiTone tone = announcement.unread
              ? UiTone.brand
              : UiTone.neutral;
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: CustomCard(
              padding: CustomCardPadding.sm,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: AppTheme.toneSoft(tone),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      announcement.category.icon,
                      color: AppTheme.toneColor(tone),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Row(
                          children: <Widget>[
                            Expanded(
                              child: Text(
                                announcement.title,
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            if (announcement.unread)
                              Container(
                                width: 10,
                                height: 10,
                                decoration: const BoxDecoration(
                                  color: AppTheme.primary,
                                  shape: BoxShape.circle,
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          announcement.message,
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
                              label: announcement.category.label,
                              tone: UiTone.brand,
                              size: ToneBadgeSize.small,
                            ),
                            ToneBadge(
                              label: announcement.priorityLabel,
                              tone: UiTone.warning,
                              size: ToneBadgeSize.small,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
      ],
    );

    if (onRefresh != null) {
      content = RefreshIndicator(
        onRefresh: () async => onRefresh!(),
        child: content,
      );
    }

    return content;
  }

  Widget _buildResidentDashboard(
    BuildContext context, {
    required List<TicketRecord> ticketPreview,
    required List<AnnouncementRecord> announcementPreview,
  }) {
    final ThemeData theme = Theme.of(context);
    final DateTime now = DateTime.now();
    final String greeting = _timeGreeting(now.hour);
    final String dateLabel =
        '${_weekday(now.weekday)}, ${now.day} ${_monthShort(now.month)}';

    // Personalized name from vendor
    final String rawName = (vendor?.fullName ?? '').trim();
    final String firstName = rawName.isNotEmpty ? rawName.split(' ').first : '';
    final String greetingText =
        firstName.isNotEmpty ? '$greeting, $firstName' : greeting;

    // Bill urgency analysis
    final List<BillRecord> overdueBills = bills
        .where((BillRecord b) => b.status == BillStatus.overdue)
        .toList()
      ..sort((BillRecord a, BillRecord b) => a.dueDate.compareTo(b.dueDate));

    final List<BillRecord> pendingBills = bills
        .where((BillRecord b) => b.status == BillStatus.pending)
        .toList()
      ..sort((BillRecord a, BillRecord b) => a.dueDate.compareTo(b.dueDate));

    final List<BillRecord> dueSoon = pendingBills
        .where(
          (BillRecord b) => b.dueDate.difference(now).inDays <= 7,
        )
        .toList();

    final double totalDue =
        <BillRecord>[...overdueBills, ...pendingBills].fold<double>(
      0,
      (double sum, BillRecord b) => sum + b.amount,
    );

    final bool allClear = !isLoading &&
        bills.isNotEmpty &&
        overdueBills.isEmpty &&
        pendingBills.isEmpty;

    // Active tickets only, sorted urgent → high → medium → low
    final List<TicketRecord> activeTickets = tickets
        .where(
          (TicketRecord t) =>
              t.status == TicketStatus.open ||
              t.status == TicketStatus.inProgress,
        )
        .toList()
      ..sort(
        (TicketRecord a, TicketRecord b) =>
            b.priority.index.compareTo(a.priority.index),
      );

    // Announcements: unread first, then by date
    final List<AnnouncementRecord> sortedAnnouncements =
        <AnnouncementRecord>[...announcements]..sort(
            (AnnouncementRecord a, AnnouncementRecord b) {
              if (a.unread && !b.unread) return -1;
              if (!a.unread && b.unread) return 1;
              return b.createdAt.compareTo(a.createdAt);
            },
          );
    final List<AnnouncementRecord> noticeSlice =
        sortedAnnouncements.take(2).toList();
    final int unreadCount =
        announcements.where((AnnouncementRecord a) => a.unread).length;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 124),
      children: <Widget>[
        // ── Greeting row ────────────────────────────────────────
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    greetingText,
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    role.label,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: AppTheme.surfaceMuted,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                dateLabel,
                style: theme.textTheme.labelMedium?.copyWith(
                  color: AppTheme.textMuted,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 18),

        // ── Bill status banner ───────────────────────────────────
        if (isLoading)
          _buildLoadingBanner(theme)
        else if (overdueBills.isNotEmpty)
          _buildBillBanner(
            context,
            theme: theme,
            icon: Icons.error_outline_rounded,
            bgColor: const Color(0xFFFEF2F2),
            accentColor: const Color(0xFFDC2626),
            title: overdueBills.length == 1
                ? 'Payment Overdue'
                : '${overdueBills.length} Bills Overdue',
            subtitle: overdueBills.length == 1
                ? overdueBills.first.title
                : 'Total outstanding amount',
            amount: _fmt(totalDue),
            detail: overdueBills.length == 1
                ? 'Since ${formatCompactDate(overdueBills.first.dueDate)}'
                : '${overdueBills.length} unpaid bills need attention',
            actionLabel: 'Settle Now',
          )
        else if (dueSoon.isNotEmpty)
          _buildBillBanner(
            context,
            theme: theme,
            icon: Icons.schedule_rounded,
            bgColor: const Color(0xFFFEFCE8),
            accentColor: const Color(0xFFD97706),
            title: dueSoon.first.dueDate.difference(now).inDays == 0
                ? 'Due Today'
                : 'Due in ${dueSoon.first.dueDate.difference(now).inDays} Days',
            subtitle: dueSoon.first.title,
            amount: _fmt(dueSoon.first.amount),
            detail: 'On ${formatCompactDate(dueSoon.first.dueDate)}',
            actionLabel: 'Pay Now',
          )
        else if (pendingBills.isNotEmpty)
          _buildBillBanner(
            context,
            theme: theme,
            icon: Icons.receipt_long_outlined,
            bgColor: AppTheme.primarySoft,
            accentColor: AppTheme.primary,
            title: '${pendingBills.length} Bill${pendingBills.length > 1 ? 's' : ''} Pending',
            subtitle: pendingBills.first.title,
            amount: _fmt(totalDue),
            detail: 'Due ${formatCompactDate(pendingBills.first.dueDate)}',
            actionLabel: 'View Bills',
          )
        else if (allClear)
          _buildAllClearRow(theme)
        else
          const SizedBox.shrink(),

        const SizedBox(height: 18),

        // ── Metrics row ──────────────────────────────────────────
        if (metrics.isNotEmpty) ...<Widget>[
          SizedBox(
            height: 88,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: metrics.length,
              separatorBuilder: (_, __) => const SizedBox(width: 10),
              itemBuilder: (BuildContext ctx, int index) {
                final DashboardMetric metric = metrics[index];
                final Color accent = AppTheme.toneColor(metric.tone);
                return Container(
                  width: 148,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border(
                      left: BorderSide(color: accent, width: 3),
                    ),
                    boxShadow: const <BoxShadow>[
                      BoxShadow(
                        color: Color(0x0A000000),
                        blurRadius: 6,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      Text(
                        metric.value,
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        metric.title,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: AppTheme.textSecondary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 20),
        ],

        // ── Quick actions ────────────────────────────────────────
        Text(
          'Quick actions',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 84,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: shortcuts.length,
            separatorBuilder: (_, __) => const SizedBox(width: 14),
            itemBuilder: (BuildContext ctx, int index) {
              final AppShortcut shortcut = shortcuts[index];
              return GestureDetector(
                onTap: () => onShortcutSelected(shortcut.actionKey),
                child: SizedBox(
                  width: 72,
                  child: Column(
                    children: <Widget>[
                      Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          color: AppTheme.primarySoft,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Icon(
                          shortcut.icon,
                          color: AppTheme.primary,
                          size: 24,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        shortcut.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                        style: theme.textTheme.labelSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 22),

        // ── Active issues ────────────────────────────────────────
        _ResidentSectionHeader(
          title: 'Active Issues',
          count: activeTickets.length,
          onViewAll: activeTickets.length > 2
              ? () => onShortcutSelected('support')
              : null,
        ),
        const SizedBox(height: 10),
        if (activeTickets.isEmpty)
          const _ResidentEmptyRow(
            icon: Icons.check_circle_outline_rounded,
            message: 'No open issues right now',
            color: Color(0xFF16A34A),
          )
        else
          ...activeTickets.take(2).map((TicketRecord ticket) {
            final Color priorityColor =
                AppTheme.toneColor(ticket.priority.tone);
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border(
                    left: BorderSide(color: priorityColor, width: 3),
                  ),
                  boxShadow: const <BoxShadow>[
                    BoxShadow(
                      color: Color(0x08000000),
                      blurRadius: 6,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Expanded(
                          child: Text(
                            ticket.title,
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        ToneBadge(
                          label: ticket.status.label,
                          tone: ticket.status.tone,
                          size: ToneBadgeSize.small,
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      ticket.description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: AppTheme.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: <Widget>[
                        ToneBadge(
                          label: ticket.priority.label,
                          tone: ticket.priority.tone,
                          size: ToneBadgeSize.small,
                        ),
                        const SizedBox(width: 6),
                        ToneBadge(
                          label: ticket.category,
                          tone: UiTone.neutral,
                          size: ToneBadgeSize.small,
                        ),
                        const Spacer(),
                        Text(
                          formatCompactDate(ticket.updatedAt),
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: AppTheme.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          }),
        const SizedBox(height: 16),

        // ── Notices ──────────────────────────────────────────────
        _ResidentSectionHeader(
          title: 'Notices',
          badgeLabel: unreadCount > 0 ? '$unreadCount unread' : null,
          onViewAll: sortedAnnouncements.length > 2
              ? () => onShortcutSelected('communication')
              : null,
        ),
        const SizedBox(height: 10),
        if (noticeSlice.isEmpty)
          const _ResidentEmptyRow(
            icon: Icons.notifications_none_rounded,
            message: 'No new announcements',
            color: AppTheme.textMuted,
          )
        else
          ...noticeSlice.map((AnnouncementRecord announcement) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: announcement.unread
                        ? AppTheme.primaryTone
                        : AppTheme.border,
                  ),
                  boxShadow: const <BoxShadow>[
                    BoxShadow(
                      color: Color(0x08000000),
                      blurRadius: 6,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: announcement.unread
                            ? AppTheme.primarySoft
                            : AppTheme.surfaceMuted,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        announcement.category.icon,
                        size: 18,
                        color: announcement.unread
                            ? AppTheme.primary
                            : AppTheme.textMuted,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Row(
                            children: <Widget>[
                              Expanded(
                                child: Text(
                                  announcement.title,
                                  style: theme.textTheme.titleSmall?.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              if (announcement.unread)
                                Container(
                                  width: 8,
                                  height: 8,
                                  margin: const EdgeInsets.only(left: 6),
                                  decoration: const BoxDecoration(
                                    color: AppTheme.primary,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            announcement.message,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: AppTheme.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: <Widget>[
                              ToneBadge(
                                label: announcement.priorityLabel,
                                tone: announcement.unread
                                    ? UiTone.brand
                                    : UiTone.neutral,
                                size: ToneBadgeSize.small,
                              ),
                              const Spacer(),
                              Text(
                                formatCompactDate(announcement.createdAt),
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: AppTheme.textMuted,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
      ],
    );
  }

  Widget _buildBillBanner(
    BuildContext context, {
    required ThemeData theme,
    required IconData icon,
    required Color bgColor,
    required Color accentColor,
    required String title,
    required String subtitle,
    required String amount,
    required String detail,
    required String actionLabel,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(14),
        border: Border(left: BorderSide(color: accentColor, width: 4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Icon(icon, color: accentColor, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      title,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: accentColor,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text(
                amount,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: accentColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: <Widget>[
              Text(
                detail,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: AppTheme.textMuted,
                ),
              ),
              const Spacer(),
              GestureDetector(
                onTap: () => onShortcutSelected('billing'),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: accentColor,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    actionLabel,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAllClearRow(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF0FDF4),
        borderRadius: BorderRadius.circular(12),
        border: const Border(
          left: BorderSide(color: Color(0xFF16A34A), width: 4),
        ),
      ),
      child: Row(
        children: <Widget>[
          const Icon(
            Icons.check_circle_rounded,
            color: Color(0xFF16A34A),
            size: 20,
          ),
          const SizedBox(width: 10),
          Text(
            'All bills settled',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
              color: const Color(0xFF15803D),
            ),
          ),
          const Spacer(),
          Text(
            'Great job!',
            style: theme.textTheme.bodySmall?.copyWith(
              color: const Color(0xFF16A34A),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingBanner(ThemeData theme) {
    return Container(
      height: 76,
      decoration: BoxDecoration(
        color: AppTheme.surfaceMuted,
        borderRadius: BorderRadius.circular(14),
        border: const Border(
          left: BorderSide(color: AppTheme.border, width: 4),
        ),
      ),
      child: const Center(
        child: SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      ),
    );
  }

  static String _timeGreeting(int hour) {
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }

  static String _weekday(int day) {
    const List<String> days = <String>[
      'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun',
    ];
    return days[day - 1];
  }

  static String _monthShort(int month) {
    const List<String> months = <String>[
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return months[month - 1];
  }

  String _fmt(double value) {
    if (value >= 100000) {
      return 'Rs ${(value / 100000).toStringAsFixed(1)}L';
    }
    if (value >= 1000) {
      return 'Rs ${(value / 1000).toStringAsFixed(1)}K';
    }
    return 'Rs ${value.toStringAsFixed(0)}';
  }

  List<Widget> _buildRoleSections(BuildContext context) {
    if (role.isSocietyScope) {
      return _buildSocietySections(context);
    }
    if (role == AppRole.propertyManager) {
      return _buildPropertySections(context);
    }
    return <Widget>[];
  }

  List<Widget> _buildSocietySections(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final SocietyData? society = societyInfo;
    final bool hasSociety = (society?.societyId ?? vendor?.societyId ?? '')
        .isNotEmpty;

    if (!hasSociety) {
      return <Widget>[
        _SectionHeader(
          title: 'Society Setup',
          actionLabel: 'Create Society',
          onAction: () => onShortcutSelected('society_management'),
        ),
        CustomCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                'No society profile found',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'The website opens the create-society flow from the dashboard when setup is missing. Use the same mobile action here to start with profile, billing rules, blocks, and buildings.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: AppTheme.textSecondary,
                ),
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: <Widget>[
                  CustomButton(
                    label: 'Create Society',
                    icon: const Icon(Icons.add_business_outlined),
                    onPressed: () => onShortcutSelected('society_management'),
                  ),
                  CustomButton(
                    label: 'Residents',
                    variant: CustomButtonVariant.outline,
                    icon: const Icon(Icons.groups_outlined),
                    onPressed: () => onShortcutSelected('residents'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ];
    }

    final WalletSummaryData? walletInfo = society?.walletInfo ?? vendor?.walletInfo;
    final BillCollectionSummaryData? billSummary = vendor?.billCollectionSummary;
    final SupportTicketSummaryData? supportSummary = vendor?.supportTicketSummary;
    final SocietyMaintenanceRates rates =
        society?.maintenanceRates ?? const SocietyMaintenanceRates();
    final SocietyBillingConfig billingConfig =
        society?.billingConfig ?? const SocietyBillingConfig();

    final List<DashboardMetric> setupMetrics = <DashboardMetric>[
      DashboardMetric(
        title: 'Blocks',
        value: '$blockCount',
        subtitle: 'Society structure configured',
        tone: UiTone.brand,
      ),
      DashboardMetric(
        title: 'Buildings',
        value: '$buildingCount',
        subtitle: 'Mapped under current blocks',
        tone: UiTone.neutral,
      ),
      DashboardMetric(
        title: 'Residents',
        value: '${society?.totalResidents ?? 0}',
        subtitle: '${society?.activeResidents ?? 0} active profiles',
        tone: UiTone.success,
      ),
      DashboardMetric(
        title: 'Available Slots',
        value: '${society?.availableResidentsCreationCount ?? 0}',
        subtitle: '${society?.usedResidentsCreationCount ?? 0} slots used',
        tone: UiTone.warning,
      ),
    ];

    final List<DashboardMetric> financeMetrics = <DashboardMetric>[
      DashboardMetric(
        title: 'Month Collected',
        value: _formatCurrencyCompact(
          billSummary?.currentMonthCollected ?? 0.0,
        ),
        subtitle: 'Current maintenance collection',
        tone: UiTone.success,
      ),
      DashboardMetric(
        title: 'Month Pending',
        value: _formatCurrencyCompact(
          billSummary?.currentMonthPending ?? 0.0,
        ),
        subtitle: 'Current month outstanding',
        tone: UiTone.warning,
      ),
      DashboardMetric(
        title: 'Open Tickets',
        value: '${supportSummary?.openTicketsCount ?? 0}',
        subtitle: '${supportSummary?.criticalOpenTicketsCount ?? 0} critical open',
        tone: UiTone.brand,
      ),
      DashboardMetric(
        title: 'Wallet Balance',
        value: _formatCurrencyCompact(walletInfo?.availableAmount ?? 0.0),
        subtitle: 'Available for withdrawal',
        tone: UiTone.neutral,
      ),
    ];

    final List<String> maintenanceBadges = <String>[
      '1 BHK ${_formatCurrencyCompact(rates.oneBhk)}',
      '2 BHK ${_formatCurrencyCompact(rates.twoBhk)}',
      '3 BHK ${_formatCurrencyCompact(rates.threeBhk)}',
      '4 BHK ${_formatCurrencyCompact(rates.fourBhk)}',
      'Villa ${_formatCurrencyCompact(rates.villa)}',
    ];

    return <Widget>[
      _SectionHeader(
        title: 'Society Overview',
        actionLabel: 'Open Society',
        onAction: () => onShortcutSelected('society_management'),
      ),
      CustomCard(
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
                        society?.name ?? 'Society',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        society?.locationAddress?.isNotEmpty == true
                            ? society!.locationAddress!
                            : society?.address ?? '',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                ToneBadge(
                  label: society?.isActive == false ? 'Inactive' : 'Active',
                  tone: society?.isActive == false
                      ? UiTone.warning
                      : UiTone.success,
                ),
              ],
            ),
            const SizedBox(height: 14),
            if ((society?.phone ?? '').isNotEmpty)
              _DetailLine(label: 'Phone', value: society!.phone!),
            if ((society?.email ?? '').isNotEmpty)
              _DetailLine(label: 'Email', value: society!.email!),
            if ((society?.estYear ?? '').isNotEmpty)
              _DetailLine(label: 'Established', value: society!.estYear!),
            _DetailLine(
              label: 'Billing rule',
              value:
                  'Generate on day ${billingConfig.billGenerationDate} | Due in ${billingConfig.paymentDueDays} days',
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: <Widget>[
                CustomButton(
                  label: 'Manage Society',
                  icon: const Icon(Icons.apartment_outlined),
                  onPressed: () => onShortcutSelected('society_management'),
                ),
                CustomButton(
                  label: 'Residents',
                  variant: CustomButtonVariant.outline,
                  icon: const Icon(Icons.groups_outlined),
                  onPressed: () => onShortcutSelected('residents'),
                ),
                CustomButton(
                  label: 'Security',
                  variant: CustomButtonVariant.outline,
                  icon: const Icon(Icons.shield_outlined),
                  onPressed: () => onShortcutSelected('security'),
                ),
              ],
            ),
          ],
        ),
      ),
      const SizedBox(height: 12),
      _metricGrid(setupMetrics),
      const SizedBox(height: 12),
      CustomCard(
        color: AppTheme.primarySoft,
        borderColor: AppTheme.primaryTone,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              'Resident Slot Setup',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Use Residents to purchase or renew slots and continue onboarding after society, block, and building setup.',
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
                  label: 'Free ${society?.freeResidentsCount ?? 0}',
                  tone: UiTone.success,
                ),
                ToneBadge(
                  label: 'Purchased ${society?.purchasedResidentsCount ?? 0}',
                  tone: UiTone.brand,
                ),
                ToneBadge(
                  label: 'Available ${society?.availableResidentsCreationCount ?? 0}',
                  tone: UiTone.success,
                ),
                ToneBadge(
                  label: 'Used ${society?.usedResidentsCreationCount ?? 0}',
                  tone: UiTone.warning,
                ),
                if ((society?.purchasedResidentsExpiryDate ?? '').isNotEmpty)
                  ToneBadge(
                    label: 'Expiry ${society!.purchasedResidentsExpiryDate!}',
                    tone: UiTone.neutral,
                  ),
              ],
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: <Widget>[
                CustomButton(
                  label: 'Manage Residents',
                  icon: const Icon(Icons.manage_accounts_outlined),
                  onPressed: () => onShortcutSelected('residents'),
                ),
                CustomButton(
                  label: 'Wallet',
                  variant: CustomButtonVariant.outline,
                  icon: const Icon(Icons.account_balance_wallet_outlined),
                  onPressed: () => onShortcutSelected('bank_details'),
                ),
              ],
            ),
          ],
        ),
      ),
      const SizedBox(height: 12),
      _SectionHeader(
        title: 'Finance and Rules',
        actionLabel: 'Wallet',
        onAction: () => onShortcutSelected('bank_details'),
      ),
      _metricGrid(financeMetrics),
      const SizedBox(height: 12),
      CustomCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              'Maintenance and Billing Rules',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 12),
            _DetailLine(
              label: 'Bill generation',
              value: 'Day ${billingConfig.billGenerationDate} of every month',
            ),
            _DetailLine(
              label: 'Payment due',
              value: '${billingConfig.paymentDueDays} days after generation',
            ),
            if (walletInfo != null) ...<Widget>[
              _DetailLine(
                label: 'Wallet credited',
                value: _formatCurrencyCompact(walletInfo.creditedAmount),
              ),
              _DetailLine(
                label: 'Wallet debited',
                value: _formatCurrencyCompact(walletInfo.debitedAmount),
              ),
            ],
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: maintenanceBadges
                  .map(
                    (String label) =>
                        ToneBadge(label: label, tone: UiTone.neutral),
                  )
                  .toList(),
            ),
          ],
        ),
      ),
    ];
  }

  List<Widget> _buildPropertySections(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final PropertySummaryData? propertySummary = vendor?.propertySummary;
    final RentalContractSummaryData? contractSummary =
        vendor?.rentalContractSummary;
    final BillCollectionSummaryData? billSummary = vendor?.billCollectionSummary;
    final SupportTicketSummaryData? supportSummary = vendor?.supportTicketSummary;
    final WalletSummaryData? walletInfo = vendor?.walletInfo;

    final List<DashboardMetric> propertyMetrics = <DashboardMetric>[
      DashboardMetric(
        title: 'Total Properties',
        value: '${propertySummary?.totalPropertiesCount ?? 0}',
        subtitle: 'Managed inventory',
        tone: UiTone.brand,
      ),
      DashboardMetric(
        title: 'Approved',
        value: '${propertySummary?.approvedPropertiesCount ?? 0}',
        subtitle: 'Live listings ready',
        tone: UiTone.success,
      ),
      DashboardMetric(
        title: 'Pending',
        value: '${propertySummary?.pendingPropertiesCount ?? 0}',
        subtitle: 'Awaiting approval',
        tone: UiTone.warning,
      ),
      DashboardMetric(
        title: 'Rejected',
        value: '${propertySummary?.rejectedPropertiesCount ?? 0}',
        subtitle: 'Needs correction',
        tone: UiTone.danger,
      ),
    ];

    final List<DashboardMetric> contractMetrics = <DashboardMetric>[
      DashboardMetric(
        title: 'Active Contracts',
        value: '${contractSummary?.activeContractsCount ?? 0}',
        subtitle: 'Current agreements',
        tone: UiTone.success,
      ),
      DashboardMetric(
        title: 'Pending Renewal',
        value: '${contractSummary?.pendingRenewalCount ?? 0}',
        subtitle: 'Needs follow-up soon',
        tone: UiTone.warning,
      ),
      DashboardMetric(
        title: 'Expired',
        value: '${contractSummary?.expiredContractsCount ?? 0}',
        subtitle: 'Closed or lapsed',
        tone: UiTone.neutral,
      ),
      DashboardMetric(
        title: 'Monthly Rent',
        value: _formatCurrencyCompact(contractSummary?.totalMonthlyRent ?? 0.0),
        subtitle: 'Active rent value',
        tone: UiTone.brand,
      ),
    ];

    final List<DashboardMetric> operationsMetrics = <DashboardMetric>[
      DashboardMetric(
        title: 'Total Pending',
        value: _formatCurrencyCompact(billSummary?.totalPendingAmount ?? 0.0),
        subtitle: 'All pending rental bills',
        tone: UiTone.warning,
      ),
      DashboardMetric(
        title: 'Month Collection',
        value: _formatCurrencyCompact(
          billSummary?.currentMonthCollected ?? 0.0,
        ),
        subtitle: 'Current month collected',
        tone: UiTone.success,
      ),
      DashboardMetric(
        title: 'Open Tickets',
        value: '${supportSummary?.openTicketsCount ?? 0}',
        subtitle: '${supportSummary?.criticalOpenTicketsCount ?? 0} critical',
        tone: UiTone.brand,
      ),
      DashboardMetric(
        title: 'Wallet Balance',
        value: _formatCurrencyCompact(walletInfo?.availableAmount ?? 0.0),
        subtitle: 'Available for withdrawal',
        tone: UiTone.neutral,
      ),
    ];

    return <Widget>[
      _SectionHeader(
        title: 'Property Overview',
        actionLabel: 'Properties',
        onAction: () => onShortcutSelected('properties'),
      ),
      CustomCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              (vendor?.fullName ?? '').isNotEmpty
                  ? vendor!.fullName
                  : 'Property Manager',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'The website property dashboard groups inventory, contracts, billing, support, and wallet into one overview. Mobile now uses the same backend summaries before you open each module.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: AppTheme.textSecondary,
              ),
            ),
            const SizedBox(height: 12),
            if ((vendor?.email ?? '').isNotEmpty)
              _DetailLine(label: 'Email', value: vendor!.email),
            if ((vendor?.phone ?? '').isNotEmpty)
              _DetailLine(label: 'Phone', value: vendor!.phone),
            if ((vendor?.propertyId ?? '').isNotEmpty)
              _DetailLine(label: 'Property scope', value: vendor!.propertyId!),
            const SizedBox(height: 16),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: <Widget>[
                CustomButton(
                  label: 'Properties',
                  icon: const Icon(Icons.apartment_outlined),
                  onPressed: () => onShortcutSelected('properties'),
                ),
                CustomButton(
                  label: 'Enquiries',
                  variant: CustomButtonVariant.outline,
                  icon: const Icon(Icons.manage_search_outlined),
                  onPressed: () => onShortcutSelected('enquiries'),
                ),
                CustomButton(
                  label: 'Contracts',
                  variant: CustomButtonVariant.outline,
                  icon: const Icon(Icons.description_outlined),
                  onPressed: () => onShortcutSelected('rental_contracts'),
                ),
              ],
            ),
          ],
        ),
      ),
      const SizedBox(height: 12),
      _metricGrid(propertyMetrics),
      const SizedBox(height: 12),
      _SectionHeader(
        title: 'Contracts and Revenue',
        actionLabel: 'Rental Bills',
        onAction: () => onShortcutSelected('rental_bills'),
      ),
      _metricGrid(contractMetrics),
      const SizedBox(height: 12),
      _metricGrid(operationsMetrics),
      const SizedBox(height: 12),
      CustomCard(
        color: AppTheme.primarySoft,
        borderColor: AppTheme.primaryTone,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              'Operations Actions',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Use billing, support, and bank details directly from the summary numbers, matching the website flow.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: AppTheme.textSecondary,
              ),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: <Widget>[
                CustomButton(
                  label: 'Rental Bills',
                  icon: const Icon(Icons.receipt_long_outlined),
                  onPressed: () => onShortcutSelected('rental_bills'),
                ),
                CustomButton(
                  label: 'Wallet',
                  variant: CustomButtonVariant.outline,
                  icon: const Icon(Icons.account_balance_wallet_outlined),
                  onPressed: () => onShortcutSelected('bank_details'),
                ),
                CustomButton(
                  label: 'Support',
                  variant: CustomButtonVariant.outline,
                  icon: const Icon(Icons.support_agent_outlined),
                  onPressed: () => onShortcutSelected('support'),
                ),
              ],
            ),
          ],
        ),
      ),
    ];
  }

  Widget _metricGrid(List<DashboardMetric> items) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: items.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.18,
      ),
      itemBuilder: (BuildContext context, int index) {
        final DashboardMetric metric = items[index];
        return _MetricCard(metric: metric);
      },
    );
  }

  String _formatCurrencyCompact(double value) {
    if (value >= 10000000) {
      return 'Rs ${(value / 10000000).toStringAsFixed(2)} Cr';
    }
    if (value >= 100000) {
      return 'Rs ${(value / 100000).toStringAsFixed(2)} L';
    }
    if (value >= 1000) {
      return 'Rs ${(value / 1000).toStringAsFixed(1)} K';
    }
    return 'Rs ${value.toStringAsFixed(0)}';
  }
}

class _ResidentSectionHeader extends StatelessWidget {
  const _ResidentSectionHeader({
    required this.title,
    this.count,
    this.badgeLabel,
    this.onViewAll,
  });

  final String title;
  final int? count;
  final String? badgeLabel;
  final VoidCallback? onViewAll;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Row(
      children: <Widget>[
        Text(
          title,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        if (count != null && count! > 0) ...<Widget>[
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
            decoration: BoxDecoration(
              color: AppTheme.primarySoft,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '$count',
              style: theme.textTheme.labelSmall?.copyWith(
                color: AppTheme.primary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
        if (badgeLabel != null) ...<Widget>[
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
            decoration: BoxDecoration(
              color: AppTheme.primarySoft,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              badgeLabel!,
              style: theme.textTheme.labelSmall?.copyWith(
                color: AppTheme.primary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
        const Spacer(),
        if (onViewAll != null)
          GestureDetector(
            onTap: onViewAll,
            child: Text(
              'View all',
              style: theme.textTheme.labelMedium?.copyWith(
                color: AppTheme.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
      ],
    );
  }
}

class _ResidentEmptyRow extends StatelessWidget {
  const _ResidentEmptyRow({
    required this.icon,
    required this.message,
    required this.color,
  });

  final IconData icon;
  final String message;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppTheme.surfaceMuted,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: <Widget>[
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 10),
          Text(
            message,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppTheme.textSecondary,
                ),
          ),
        ],
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({required this.metric});

  final DashboardMetric metric;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

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
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            metric.subtitle,
            style: theme.textTheme.bodySmall?.copyWith(
              color: AppTheme.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.title,
    this.actionLabel,
    this.onAction,
  });

  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: <Widget>[
          Expanded(
            child: Text(
              title,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ),
          if ((actionLabel ?? '').isNotEmpty && onAction != null)
            TextButton(
              onPressed: onAction,
              child: Text(actionLabel!),
            ),
        ],
      ),
    );
  }
}

class _DetailLine extends StatelessWidget {
  const _DetailLine({
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
