import 'package:flutter/material.dart';

import '../../core/api/property_booking_service.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/contact_launcher.dart';

class PropertyBookingsPage extends StatefulWidget {
  const PropertyBookingsPage({super.key});

  @override
  State<PropertyBookingsPage> createState() => _PropertyBookingsPageState();
}

class _PropertyBookingsPageState extends State<PropertyBookingsPage> {
  List<PropertyBookingData> _bookings = <PropertyBookingData>[];
  bool _loading = true;
  String? _error;
  String _statusGroup = '';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final result = await PropertyBookingService.filterTenantBookings(
        limit: 100,
        statusGroup: _statusGroup,
      );
      if (!mounted) return;
      setState(() {
        _bookings = result.bookings;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error.toString().replaceFirst('Exception: ', '');
      });
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Bookings'),
        actions: <Widget>[
          IconButton(
            onPressed: _loading ? null : _load,
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: _buildBody(context),
      ),
    );
  }

  Widget _buildBody(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return ListView(
        padding: const EdgeInsets.all(20),
        children: <Widget>[
          _StatePanel(
            icon: Icons.error_outline_rounded,
            title: 'Unable to load bookings',
            message: _error!,
            action: FilledButton.icon(
              onPressed: _load,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Retry'),
            ),
          ),
        ],
      );
    }
    if (_bookings.isEmpty) {
      return ListView(
        padding: const EdgeInsets.all(20),
        children: <Widget>[
          _BookingFilterBar(
            selected: _statusGroup,
            onChanged: _setStatusGroup,
          ),
          const SizedBox(height: 16),
          _StatePanel(
            icon: Icons.event_available_outlined,
            title: 'No property bookings yet',
            message: 'Booked properties will appear here after payment.',
          ),
        ],
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: _bookings.length + 1,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (BuildContext context, int index) {
        if (index == 0) {
          return _BookingFilterBar(
            selected: _statusGroup,
            onChanged: _setStatusGroup,
          );
        }
        final PropertyBookingData booking = _bookings[index - 1];
        return _BookingCard(
          booking: booking,
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => PropertyBookingDetailsPage(booking: booking),
            ),
          ),
        );
      },
    );
  }

  void _setStatusGroup(String value) {
    if (_statusGroup == value) return;
    setState(() {
      _statusGroup = value;
    });
    _load();
  }
}

class _BookingFilterBar extends StatelessWidget {
  const _BookingFilterBar({required this.selected, required this.onChanged});

  final String selected;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    const Map<String, String> filters = <String, String>{
      '': 'All',
      'ACTIVE': 'Active requests',
      'CONFIRMED': 'Confirmed',
      'REJECTED': 'Rejected',
    };
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: filters.entries.map((MapEntry<String, String> item) {
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              selected: selected == item.key,
              label: Text(item.value),
              onSelected: (_) => onChanged(item.key),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class PropertyBookingDetailsPage extends StatelessWidget {
  const PropertyBookingDetailsPage({super.key, required this.booking});

  final PropertyBookingData booking;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Booking Details')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: <Widget>[
          _BookingCard(booking: booking, onTap: null),
          if (_rejectionReason(booking).isNotEmpty) ...<Widget>[
            const SizedBox(height: 16),
            _NoticePanel(
              title: 'Why this booking was rejected',
              message: _rejectionReason(booking),
              tone: _StatusTone.danger,
            ),
          ],
          if (booking.razorpayRefundId.isNotEmpty) ...<Widget>[
            const SizedBox(height: 16),
            const _NoticePanel(
              title: 'Refund initiated',
              message:
                  "Amount will be credited to customer's bank account within 5-7 working days after the refund has processed.",
              tone: _StatusTone.brand,
            ),
          ],
          const SizedBox(height: 16),
          _InfoSection(
            title: 'Payment',
            rows: <_InfoRow>[
              _InfoRow('Booking ID', booking.bookingNumber),
              _InfoRow('Amount', _money(booking.bookingAmount)),
              _InfoRow('Payment status', _statusLabel(booking.paymentStatus)),
              _InfoRow('Razorpay payment', booking.razorpayPaymentId),
              if (booking.refundStatus.isNotEmpty)
                _InfoRow('Refund status', _statusLabel(booking.refundStatus)),
              if (booking.razorpayRefundId.isNotEmpty)
                _InfoRow('Refund ID', booking.razorpayRefundId),
              if (booking.managerReason.isNotEmpty)
                _InfoRow('Manager rejection reason', booking.managerReason),
              if (booking.adminReason.isNotEmpty)
                _InfoRow('Admin rejection reason', booking.adminReason),
            ],
          ),
          const SizedBox(height: 16),
          _InfoSection(
            title: 'People',
            rows: <_InfoRow>[
              _InfoRow('Tenant', booking.tenantName),
              _InfoRow.phone('Phone', booking.tenantPhone),
              _InfoRow.email('Email', booking.tenantEmail),
              _InfoRow('Manager', booking.managerName),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'Timeline',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 10),
          if (booking.activityLogs.isEmpty)
            const Text('No activity yet.')
          else
            ...booking.activityLogs.map(
              (PropertyBookingActivity log) => _TimelineItem(log: log),
            ),
        ],
      ),
    );
  }
}

class _BookingCard extends StatelessWidget {
  const _BookingCard({required this.booking, required this.onTap});

  final PropertyBookingData booking;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final String propertyImageUrl = _safeNetworkImageUrl(
      booking.propertyImageUrl,
    );
    final String imageUrl = propertyImageUrl.isEmpty
        ? _propertyFallbackPhotoUrl(booking.propertyType)
        : propertyImageUrl;
    final _PropertyVisual visual = _propertyVisual(booking);
    final _StatusTone bookingTone = _statusTone(booking.bookingStatus);
    final _StatusTone paymentTone = _statusTone(booking.paymentStatus);
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Ink(
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: AppTheme.border),
            borderRadius: BorderRadius.circular(14),
            boxShadow: const <BoxShadow>[
              BoxShadow(
                color: Color(0x0F111827),
                blurRadius: 18,
                offset: Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(14),
                ),
                child: Stack(
                  children: <Widget>[
                    AspectRatio(
                      aspectRatio: 16 / 9,
                      child: Image.network(
                        imageUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => _PropertyImageFallback(
                          booking: booking,
                          expand: true,
                        ),
                      ),
                    ),
                    Positioned.fill(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: <Color>[
                              Colors.black.withOpacity(0.05),
                              Colors.transparent,
                              Colors.black.withOpacity(0.34),
                            ],
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      left: 12,
                      top: 12,
                      child: _StatusChip(
                        label: _statusLabel(booking.bookingStatus),
                        tone: bookingTone,
                      ),
                    ),
                    Positioned(
                      right: 12,
                      top: 12,
                      child: _ImagePill(
                        icon: visual.icon,
                        label: visual.label,
                      ),
                    ),
                    Positioned(
                      left: 12,
                      right: 12,
                      bottom: 12,
                      child: Text(
                        booking.propertyTitle.isEmpty
                            ? 'Property booking'
                            : booking.propertyTitle,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleLarge?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                          shadows: const <Shadow>[
                            Shadow(
                              color: Color(0x66000000),
                              blurRadius: 10,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    if (booking.location.trim().isNotEmpty) ...<Widget>[
                      Row(
                        children: <Widget>[
                          const Icon(
                            Icons.place_outlined,
                            size: 16,
                            color: AppTheme.textSecondary,
                          ),
                          const SizedBox(width: 5),
                          Expanded(
                            child: Text(
                              booking.location,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: AppTheme.textSecondary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                    ],
                    Row(
                      children: <Widget>[
                        Expanded(
                          child: _MetricTile(
                            label: 'Platform fee',
                            value: _money(booking.bookingAmount),
                            icon: Icons.payments_outlined,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _MetricTile(
                            label: 'Payment',
                            value: _statusLabel(booking.paymentStatus),
                            icon: Icons.verified_outlined,
                            tone: paymentTone,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: <Widget>[
                        _StatusChip(
                          label: _humanBookingStage(booking),
                          tone: bookingTone,
                        ),
                        if (_rejectionReason(booking).isNotEmpty)
                          _StatusChip(
                            label: 'Reason available',
                            tone: _StatusTone.danger,
                          ),
                      ],
                    ),
                    if (onTap != null) ...<Widget>[
                      const SizedBox(height: 12),
                      Row(
                        children: <Widget>[
                          Text(
                            'View booking details',
                            style: theme.textTheme.labelLarge?.copyWith(
                              color: AppTheme.primary,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Icon(
                            Icons.arrow_forward_rounded,
                            size: 18,
                            color: AppTheme.primary,
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PropertyImageFallback extends StatelessWidget {
  const _PropertyImageFallback({required this.booking, this.expand = false});

  final PropertyBookingData booking;
  final bool expand;

  @override
  Widget build(BuildContext context) {
    final _PropertyVisual visual = _propertyVisual(booking);
    return Container(
      width: expand ? double.infinity : 74,
      height: expand ? double.infinity : 74,
      padding: EdgeInsets.all(expand ? 18 : 6),
      decoration: BoxDecoration(
        color: visual.background,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[visual.background, visual.accent.withOpacity(0.18)],
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Icon(visual.icon, size: expand ? 42 : 26, color: visual.accent),
          SizedBox(height: expand ? 8 : 5),
          Text(
            visual.label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: visual.accent,
                  fontWeight: FontWeight.w800,
                  fontSize: expand ? 13 : 10,
                ),
          ),
        ],
      ),
    );
  }
}

class _PropertyVisual {
  const _PropertyVisual({
    required this.label,
    required this.icon,
    required this.background,
    required this.accent,
  });

  final String label;
  final IconData icon;
  final Color background;
  final Color accent;
}

class _ImagePill extends StatelessWidget {
  const _ImagePill({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.92),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(icon, size: 15, color: AppTheme.textPrimary),
          const SizedBox(width: 5),
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  fontWeight: FontWeight.w900,
                  color: AppTheme.textPrimary,
                ),
          ),
        ],
      ),
    );
  }
}

class _MetricTile extends StatelessWidget {
  const _MetricTile({
    required this.label,
    required this.value,
    required this.icon,
    this.tone = _StatusTone.neutral,
  });

  final String label;
  final String value;
  final IconData icon;
  final _StatusTone tone;

  @override
  Widget build(BuildContext context) {
    final _StatusPalette palette = _statusPalette(tone);
    final ThemeData theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: palette.background,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: palette.border),
      ),
      child: Row(
        children: <Widget>[
          Icon(icon, size: 18, color: palette.foreground),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: AppTheme.textSecondary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: palette.foreground,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.label, required this.tone});

  final String label;
  final _StatusTone tone;

  @override
  Widget build(BuildContext context) {
    final _StatusPalette palette = _statusPalette(tone);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: palette.background,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: palette.border),
      ),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              fontWeight: FontWeight.w900,
              color: palette.foreground,
            ),
      ),
    );
  }
}

enum _StatusTone { success, warning, danger, brand, neutral }

class _StatusPalette {
  const _StatusPalette({
    required this.background,
    required this.foreground,
    required this.border,
  });

  final Color background;
  final Color foreground;
  final Color border;
}

_StatusPalette _statusPalette(_StatusTone tone) {
  return switch (tone) {
    _StatusTone.success => const _StatusPalette(
        background: Color(0xFFDCFCE7),
        foreground: Color(0xFF166534),
        border: Color(0xFFBBF7D0),
      ),
    _StatusTone.warning => const _StatusPalette(
        background: Color(0xFFFFF7ED),
        foreground: Color(0xFFC2410C),
        border: Color(0xFFFED7AA),
      ),
    _StatusTone.danger => const _StatusPalette(
        background: Color(0xFFFEF2F2),
        foreground: Color(0xFFB91C1C),
        border: Color(0xFFFECACA),
      ),
    _StatusTone.brand => const _StatusPalette(
        background: Color(0xFFEFF6FF),
        foreground: Color(0xFF1D4ED8),
        border: Color(0xFFBFDBFE),
      ),
    _StatusTone.neutral => const _StatusPalette(
        background: Color(0xFFF8FAFC),
        foreground: Color(0xFF334155),
        border: Color(0xFFE2E8F0),
      ),
  };
}

class _InfoSection extends StatelessWidget {
  const _InfoSection({required this.title, required this.rows});

  final String title;
  final List<_InfoRow> rows;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: AppTheme.border),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            title,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 10),
          ...rows.where((row) => row.value.trim().isNotEmpty).map(
                (row) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: <Widget>[
                      Expanded(
                        child: Text(
                          row.label,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: AppTheme.textSecondary,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Flexible(
                        child: row.action == _InfoRowAction.phone
                            ? ContactTextButton.phone(
                                value: row.value,
                                alignEnd: true,
                              )
                            : row.action == _InfoRowAction.email
                                ? ContactTextButton.email(
                                    value: row.value,
                                    alignEnd: true,
                                  )
                                : Text(
                                    row.value,
                                    textAlign: TextAlign.end,
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                      ),
                    ],
                  ),
                ),
              ),
        ],
      ),
    );
  }
}

class _NoticePanel extends StatelessWidget {
  const _NoticePanel({
    required this.title,
    required this.message,
    required this.tone,
  });

  final String title;
  final String message;
  final _StatusTone tone;

  @override
  Widget build(BuildContext context) {
    final _StatusPalette palette = _statusPalette(tone);
    final ThemeData theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: palette.background,
        border: Border.all(color: palette.border),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Icon(Icons.info_outline_rounded, color: palette.foreground),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  title,
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: palette.foreground,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  message,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: palette.foreground,
                    height: 1.45,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoRow {
  const _InfoRow(this.label, this.value) : action = _InfoRowAction.none;
  const _InfoRow.phone(this.label, this.value) : action = _InfoRowAction.phone;
  const _InfoRow.email(this.label, this.value) : action = _InfoRowAction.email;

  final String label;
  final String value;
  final _InfoRowAction action;
}

enum _InfoRowAction { none, phone, email }

class _TimelineItem extends StatelessWidget {
  const _TimelineItem({required this.log});

  final PropertyBookingActivity log;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const Padding(
            padding: EdgeInsets.only(top: 2),
            child: Icon(Icons.check_circle_rounded, color: Color(0xFF16A34A)),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  _statusLabel(log.newStatus.isEmpty ? log.action : log.newStatus),
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                if (log.notes.isNotEmpty)
                  Text(
                    log.notes,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: AppTheme.textSecondary,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatePanel extends StatelessWidget {
  const _StatePanel({
    required this.icon,
    required this.title,
    required this.message,
    this.action,
  });

  final IconData icon;
  final String title;
  final String message;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: AppTheme.border),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: <Widget>[
          Icon(icon, size: 42, color: AppTheme.textSecondary),
          const SizedBox(height: 10),
          Text(
            title,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          Text(message, textAlign: TextAlign.center),
          if (action != null) ...<Widget>[const SizedBox(height: 14), action!],
        ],
      ),
    );
  }
}

String _money(double value) => 'Rs ${value.toStringAsFixed(0)}';

String _safeNetworkImageUrl(String value) {
  final String url = value.trim();
  if (url.isEmpty) return '';
  final Uri? uri = Uri.tryParse(url);
  if (uri == null || !uri.hasScheme || uri.host.isEmpty) return '';
  if (uri.scheme != 'http' && uri.scheme != 'https') return '';
  return url;
}

_PropertyVisual _propertyVisual(PropertyBookingData booking) {
  final int type = booking.propertyType;
  final String label = booking.propertyTypeLabel.trim().isEmpty
      ? _typeLabel(type)
      : booking.propertyTypeLabel;
  return switch (type) {
    2 => _PropertyVisual(
        label: label,
        icon: Icons.villa_outlined,
        background: const Color(0xFFEFF6FF),
        accent: const Color(0xFF2563EB),
      ),
    3 => _PropertyVisual(
        label: label,
        icon: Icons.groups_2_outlined,
        background: const Color(0xFFF0FDF4),
        accent: const Color(0xFF15803D),
      ),
    4 => _PropertyVisual(
        label: label,
        icon: Icons.store_mall_directory_outlined,
        background: const Color(0xFFFFF7ED),
        accent: const Color(0xFFC2410C),
      ),
    _ => _PropertyVisual(
        label: label,
        icon: Icons.apartment_rounded,
        background: const Color(0xFFF5F3FF),
        accent: const Color(0xFF6D28D9),
      ),
  };
}

String _propertyFallbackPhotoUrl(int type) {
  return switch (type) {
    2 =>
      'https://images.unsplash.com/photo-1613490493576-7fde63acd811?auto=format&fit=crop&w=220&q=80',
    3 =>
      'https://images.unsplash.com/photo-1555854877-bab0e564b8d5?auto=format&fit=crop&w=220&q=80',
    4 =>
      'https://images.unsplash.com/photo-1497366754035-f200968a6e72?auto=format&fit=crop&w=220&q=80',
    _ =>
      'https://images.unsplash.com/photo-1560448204-e02f11c3d0e2?auto=format&fit=crop&w=220&q=80',
  };
}

_StatusTone _statusTone(String value) {
  final String normalized = value.replaceAll('_', ' ').toLowerCase();
  if (normalized.contains('reject') ||
      normalized.contains('failed') ||
      normalized.contains('cancel')) {
    return _StatusTone.danger;
  }
  if (normalized.contains('success') ||
      normalized.contains('confirm') ||
      normalized.contains('approved') ||
      normalized.contains('accepted') ||
      normalized.contains('captured')) {
    return _StatusTone.success;
  }
  if (normalized.contains('pending') ||
      normalized.contains('review') ||
      normalized.contains('waiting')) {
    return _StatusTone.warning;
  }
  return _StatusTone.brand;
}

String _humanBookingStage(PropertyBookingData booking) {
  final String bookingStatus = booking.bookingStatus.toLowerCase();
  final String paymentStatus = booking.paymentStatus.toLowerCase();
  if (bookingStatus.contains('reject')) return 'Not approved';
  if (bookingStatus.contains('confirm') || bookingStatus.contains('approved')) {
    return 'Stay confirmed';
  }
  if (bookingStatus.contains('accepted')) return 'Manager accepted';
  if (paymentStatus.contains('success') || paymentStatus.contains('captured')) {
    return 'Processing';
  }
  if (paymentStatus.contains('pending')) return 'Payment pending';
  return _statusLabel(booking.bookingStatus);
}

String _rejectionReason(PropertyBookingData booking) {
  if (booking.managerReason.trim().isNotEmpty) {
    return booking.managerReason.trim();
  }
  if (booking.adminReason.trim().isNotEmpty) {
    return booking.adminReason.trim();
  }
  return '';
}

String _typeLabel(int type) {
  return switch (type) {
    2 => 'Villa',
    3 => 'PG',
    4 => 'Commercial',
    _ => 'Apartment',
  };
}

String _statusLabel(String value) {
  final String normalized = value.replaceAll('_', ' ').trim().toLowerCase();
  if (normalized.isEmpty) return 'Pending';
  return normalized
      .split(' ')
      .where((String part) => part.isNotEmpty)
      .map((String part) => '${part[0].toUpperCase()}${part.substring(1)}')
      .join(' ');
}
