import 'package:flutter/material.dart';

import '../models/api_models.dart';
import '../models/app_models.dart';
import 'notification_payload_parser.dart';
import 'notification_type_enum.dart';
import '../../features/billing/billing_page.dart';
import '../../features/bookings/property_bookings_page.dart';
import '../../features/communication/communication_page.dart';
import '../../features/notifications/notifications_page.dart';
import '../../features/properties/property_enquiries_page.dart';
import '../../features/rental_contracts/rental_contracts_page.dart';
import '../../features/support/support_page.dart';
import '../../features/tenant/tenant_contracts_page.dart';

class NotificationTapRouter {
  NotificationTapRouter._();

  static final NotificationTapGuard _guard = NotificationTapGuard();

  static Widget buildPage({
    required AppRole role,
    required String? payload,
  }) {
    final NotificationPayload request = NotificationPayload.fromEncoded(payload);
    if (_guard.shouldIgnore(request)) {
      return const NotificationUnavailablePage();
    }
    if (request.type == NotificationType.unknown && request.screen.isEmpty) {
      return const NotificationUnavailablePage();
    }

    if (role == AppRole.tenant ||
        role == AppRole.pgResident ||
        role == AppRole.visitor) {
      return _buildTenantPage(request, role);
    }

    return _buildManagementPage(request, role);
  }

  static Widget _buildTenantPage(NotificationPayload request, AppRole role) {
    switch (request.type) {
      case NotificationType.enquiry:
        return const PropertyEnquiriesPage();
      case NotificationType.booking:
        return const PropertyBookingsPage();
      case NotificationType.announcement:
      case NotificationType.securityAlert:
        return const CommunicationPage(
          role: AppRole.tenant,
          announcements: <AnnouncementRecord>[],
        );
      case NotificationType.supportTicket:
      case NotificationType.supportUpdate:
        return const SupportPage(
          role: AppRole.tenant,
          tickets: <TicketRecord>[],
        );
      case NotificationType.payment:
      case NotificationType.rentReceived:
      case NotificationType.securityDeposit:
      case NotificationType.maintenanceAdded:
      case NotificationType.maintenanceReceived:
      case NotificationType.walletCredited:
        return const BillingPage(
          role: AppRole.tenant,
          bills: <BillRecord>[],
          isLoading: true,
        );
      case NotificationType.contract:
        return const TenantContractsPage();
      case NotificationType.system:
      case NotificationType.unknown:
        return const NotificationsPage();
    }
  }

  static Widget _buildManagementPage(
    NotificationPayload request,
    AppRole role,
  ) {
    switch (request.type) {
      case NotificationType.enquiry:
        return const PropertyEnquiriesPage();
      case NotificationType.booking:
        return const PropertyBookingsPage();
      case NotificationType.announcement:
      case NotificationType.securityAlert:
        return CommunicationPage(
          role: role,
          announcements: const <AnnouncementRecord>[],
        );
      case NotificationType.supportTicket:
      case NotificationType.supportUpdate:
        return SupportPage(
          role: role,
          tickets: const <TicketRecord>[],
        );
      case NotificationType.payment:
      case NotificationType.rentReceived:
      case NotificationType.securityDeposit:
      case NotificationType.maintenanceAdded:
      case NotificationType.maintenanceReceived:
      case NotificationType.walletCredited:
        return BillingPage(
          role: role,
          bills: const <BillRecord>[],
          isLoading: true,
        );
      case NotificationType.contract:
        return const RentalContractsPage();
      case NotificationType.system:
      case NotificationType.unknown:
        return const NotificationsPage();
    }
  }
}

class NotificationTapGuard {
  static String? _lastKey;
  static DateTime? _lastAt;

  bool shouldIgnore(NotificationPayload payload) {
    final String key = payload.dedupeKey;
    final DateTime now = DateTime.now();
    if (_lastKey == key &&
        _lastAt != null &&
        now.difference(_lastAt!) < const Duration(milliseconds: 1200)) {
      return true;
    }

    _lastKey = key;
    _lastAt = now;
    return false;
  }
}

class NotificationUnavailablePage extends StatelessWidget {
  const NotificationUnavailablePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F7),
      appBar: AppBar(title: const Text('Notification')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              const Icon(Icons.notifications_off_rounded, size: 56),
              const SizedBox(height: 14),
              Text(
                'Notification unavailable',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
              const SizedBox(height: 8),
              const Text(
                'This notification could not be opened safely.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 18),
              OutlinedButton.icon(
                onPressed: () => Navigator.of(context).maybePop(),
                icon: const Icon(Icons.arrow_back_rounded),
                label: const Text('Go back'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
