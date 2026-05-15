import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/api/announcement_service.dart';
import '../../core/api/api_client.dart';
import '../../core/api/auth_storage.dart';
import '../../core/api/billing_service.dart';
import '../../core/api/block_building_service.dart';
import '../../core/api/notification_service.dart';
import '../../core/api/society_service.dart';
import '../../core/api/support_service.dart';
import '../../core/api/vendor_service.dart';
import '../../core/data/mock_repository.dart';
import '../../core/models/api_models.dart';
import '../../core/models/app_models.dart';
import '../../core/services/connectivity_service.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/custom_bottom_nav_bar.dart';
import '../billing/billing_page.dart';
import '../block/block_issues_page.dart';
import '../block/block_security_page.dart';
import '../bookings/property_bookings_page.dart';
import '../communication/communication_page.dart';
import '../dashboard/dashboard_page.dart';
import '../discovery/find_property_page.dart';
import '../more/more_page.dart';
import '../audit/audit_logs_page.dart';
import '../properties/properties_page.dart';
import '../properties/property_enquiries_page.dart';
import '../rental_contracts/rental_contracts_page.dart';
import '../residence/residence_overview_page.dart';
import '../residents/residents_page.dart';
import '../reports/reports_page.dart';
import '../security/security_page.dart';
import '../settings/settings_page.dart';
import '../society/society_management_page.dart';
import '../support/support_page.dart';
import '../tenant/tenant_contracts_page.dart';
import '../tenant/tenant_security_page.dart';
import '../visitors/my_visits_page.dart';
import '../visitors/visitors_page.dart';
import '../notifications/notifications_page.dart';
import '../wallet/bank_wallet_page.dart';

class AppShell extends StatefulWidget {
  const AppShell({
    super.key,
    required this.role,
    required this.onLogout,
  });

  final AppRole role;
  final VoidCallback onLogout;

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  final MockUrbanRepository _repository = const MockUrbanRepository();
  int _selectedIndex = 0;
  VendorData? _vendor;
  SocietyData? _societyInfo;
  int _blockCount = 0;
  int _buildingCount = 0;

  // API data
  List<BillRecord> _bills = <BillRecord>[];
  List<TicketRecord> _tickets = <TicketRecord>[];
  List<AnnouncementRecord> _announcements = <AnnouncementRecord>[];
  List<NotificationRecord> _notifications = <NotificationRecord>[];
  bool _isLoading = true;
  String? _loadError;

  // Exit confirmation — double-back to exit within 2 seconds.
  DateTime? _lastBackPress;

  @override
  void initState() {
    super.initState();
    _loadData();
    ConnectivityService.instance.addListener(_onConnectivityChanged);
  }

  @override
  void didUpdateWidget(covariant AppShell oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.role != widget.role) {
      _selectedIndex = 0;
      _loadData();
    }
  }

  @override
  void dispose() {
    ConnectivityService.instance.removeListener(_onConnectivityChanged);
    super.dispose();
  }

  void _onConnectivityChanged() {
    if (!mounted) return;
    final bool online = ConnectivityService.instance.isOnline;

    if (online) {
      if (_loadError != null || _bills.isEmpty) {
        _loadData();
      }
      ScaffoldMessenger.of(context)
        ..clearSnackBars()
        ..showSnackBar(
          const SnackBar(
            content: Text('You are back online'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
    } else {
      ScaffoldMessenger.of(context)
        ..clearSnackBars()
        ..showSnackBar(
          const SnackBar(
            content: Text(ApiClient.offlineMessage),
            backgroundColor: Colors.red,
            duration: Duration(days: 1),
          ),
        );
    }
    setState(() {});
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _loadError = null;
      _vendor = null;
      _societyInfo = null;
      _blockCount = 0;
      _buildingCount = 0;
      _bills = <BillRecord>[];
      _tickets = <TicketRecord>[];
      _announcements = <AnnouncementRecord>[];
      _notifications = <NotificationRecord>[];
    });

    try {
      _vendor = await VendorService.fetchVendorInfo();

      await Future.wait(<Future<void>>[
        _loadBills(),
        _loadTickets(),
        _loadAnnouncements(),
        _loadNotifications(),
        _loadSocietyContext(),
      ].map((Future<void> f) => f.catchError((_) {})));
    } catch (error) {
      _loadError = error.toString().replaceFirst('Exception: ', '');
    }

    if (mounted) {
      setState(() {
        _isLoading = false;
      });

      if (_loadError != null && _vendor == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_loadError!),
            action: SnackBarAction(label: 'Retry', onPressed: _loadData),
            duration: const Duration(seconds: 6),
          ),
        );
      }
    }
  }

  Future<void> _loadBills() async {
    final int? vendorType = _vendor?.vendorType ?? AuthStorage.vendorType;

    if (widget.role.isSocietyScope && (_vendor?.societyId?.isNotEmpty ?? false)) {
      final result = await BillingService.filterSocietyResidentBills(
        societyId: _vendor!.societyId!,
      );
      if (mounted) {
        _bills = result.bills;
      }
    } else if (vendorType == 3 ||
        widget.role == AppRole.tenant ||
        widget.role == AppRole.pgResident ||
        widget.role == AppRole.owner) {
      final result = await BillingService.filterTenantBills();
      if (mounted) {
        _bills = result.bills;
      }
    } else {
      _bills = <BillRecord>[];
    }
  }

  Future<void> _loadTickets() async {
    final result = widget.role.isSocietyScope &&
            (_vendor?.societyId?.isNotEmpty ?? false)
        ? await SupportService.filterSocietyTickets(
            societyId: _vendor!.societyId!,
            limit: 100,
          )
        : widget.role == AppRole.propertyManager
            ? await SupportService.filterPropertyTickets(limit: 100)
            : await SupportService.filterTenantTickets();
    if (mounted) {
      _tickets = result.tickets;
    }
  }

  Future<void> _loadAnnouncements() async {
    final result = widget.role.isSocietyScope &&
            (_vendor?.societyId?.isNotEmpty ?? false)
        ? await AnnouncementService.filterSocietyAnnouncements(
            societyId: _vendor!.societyId!,
            limit: 100,
          )
        : await AnnouncementService.filterTenantAnnouncements();
    if (mounted) {
      _announcements = result.announcements;
    }
  }

  Future<void> _loadNotifications() async {
    final result = await NotificationService.filterNotifications(limit: 50);
    if (mounted) {
      _notifications = result.notifications
          .map((NotificationData item) => item.toNotificationRecord())
          .toList();
    }
  }

  Future<void> _loadSocietyContext() async {
    if (!widget.role.isSocietyScope || !(_vendor?.societyId?.isNotEmpty ?? false)) {
      _societyInfo = null;
      _blockCount = 0;
      _buildingCount = 0;
      return;
    }

    final String societyId = _vendor!.societyId!;
    final results = await Future.wait<dynamic>(<Future<dynamic>>[
      SocietyService.fetchSocietyInfo(),
      BlockBuildingService.filterBlocks(societyId, limit: 200),
      BlockBuildingService.filterBuildings(societyId, limit: 500),
    ]);

    if (!mounted) {
      return;
    }

    final SocietyData? societyInfo = results[0] as SocietyData?;
    final ({List<BlockData> blocks, int count}) blockResult =
        results[1] as ({List<BlockData> blocks, int count});
    final ({List<BuildingData> buildings, int count}) buildingResult =
        results[2] as ({List<BuildingData> buildings, int count});

    _societyInfo = societyInfo;
    _blockCount = blockResult.blocks.length;
    _buildingCount = buildingResult.buildings.length;
  }

  /// Handles device back button — double-tap within 2 seconds to exit.
  void _handleBackPress(bool didPop) {
    if (didPop) return;

    final DateTime now = DateTime.now();
    if (_lastBackPress != null &&
        now.difference(_lastBackPress!).inMilliseconds < 2000) {
      SystemNavigator.pop();
      return;
    }

    _lastBackPress = now;
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(
        const SnackBar(
          content: Text('Press back again to exit'),
          duration: Duration(seconds: 2),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    final List<_TabDefinition> tabs = _buildTabs();
    final _TabDefinition activeTab = tabs[_selectedIndex];
    final bool offline = !ConnectivityService.instance.isOnline;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (bool didPop, _) => _handleBackPress(didPop),
      child: Scaffold(
        appBar: AppBar(
          titleSpacing: 16,
          title: Text(activeTab.title),
          actions: <Widget>[
            if (widget.role != AppRole.propertyManager) ...<Widget>[
              IconButton(
                tooltip: 'Communication',
                onPressed: () => _openCommunication(context),
                icon: const Icon(Icons.campaign_outlined),
              ),
              const SizedBox(width: 4),
            ],
            _NotificationBell(
              unreadCount: _unreadNotificationCount(),
              onTap: () => _openModule(
                context,
                const ModuleStatusItem(
                  title: 'Notifications',
                  subtitle: 'Activity alerts and system messages.',
                  icon: Icons.notifications_outlined,
                  phaseLabel: 'Ready now',
                  actionKey: 'notifications',
                  readyNow: true,
                ),
              ),
            ),
            const SizedBox(width: 4),
          ],
          bottom: PreferredSize(
            preferredSize: Size.fromHeight(offline ? 29 : 1),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                if (offline)
                  Container(
                    width: double.infinity,
                    color: Colors.red.shade700,
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: const Text(
                      ApiClient.offlineMessage,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                const Divider(height: 1, thickness: 1, color: AppTheme.border),
              ],
            ),
          ),
        ),
        body: activeTab.child,
        bottomNavigationBar: CustomBottomNavBar(
          selectedIndex: _selectedIndex,
          onSelected: (int index) {
            setState(() {
              _selectedIndex = index;
            });
          },
          items: tabs
              .map(
                (_TabDefinition tab) => CustomBottomNavItem(
                  label: tab.label,
                  icon: tab.icon,
                  floating: false,
                ),
              )
              .toList(),
        ),
      ),
    );
  }

  List<_TabDefinition> _buildTabs() {
    if (widget.role == AppRole.propertyManager) {
      return _buildPropertyManagerTabs();
    }

    final List<_TabDefinition> tabs = <_TabDefinition>[
      _TabDefinition(
        key: 'dashboard',
        title: 'Home',
        label: 'Home',
        icon: Icons.home_outlined,
        child: DashboardPage(
          role: widget.role,
          metrics: _dashboardMetrics(),
          shortcuts: _shortcutsForRole(widget.role),
          announcements: _announcements,
          tickets: _tickets,
          bills: _bills,
          vendor: _vendor,
          societyInfo: _societyInfo,
          blockCount: _blockCount,
          buildingCount: _buildingCount,
          onShortcutSelected: (String actionKey) => _handleShortcut(actionKey),
          isLoading: _isLoading,
          onRefresh: _loadData,
        ),
      ),
    ];

    if (widget.role.supportsBilling) {
      tabs.add(
        _TabDefinition(
          key: 'billing',
          title: widget.role.billingSectionTitle,
          label: 'Bills',
          icon: Icons.receipt_long_outlined,
          child: BillingPage(
            role: widget.role,
            bills: _bills,
            isLoading: _isLoading,
            onRefresh: _loadData,
          ),
        ),
      );
    }

    tabs.add(
      _TabDefinition(
        key: 'support',
        title: widget.role == AppRole.tenant ? 'Support Center' : 'Support',
        label: widget.role == AppRole.tenant ? 'Help' : 'Support',
        icon: Icons.headset_mic_outlined,
        child: SupportPage(
          role: widget.role,
          tickets: _tickets,
          isLoading: _isLoading,
          onRefresh: _loadData,
        ),
      ),
    );

    if (widget.role == AppRole.tenant) {
      tabs.add(
        _TabDefinition(
          key: 'find_property',
          title: 'Find Property',
          label: 'Find',
          icon: Icons.travel_explore_rounded,
          child: FindPropertyPage(
            showLoginButton: false,
            enableWishlist: true,
            onLoginPressed: () {},
          ),
        ),
      );
      tabs.add(
        const _TabDefinition(
          key: 'security_alerts',
          title: 'Security Alerts',
          label: 'Alerts',
          icon: Icons.shield_outlined,
          child: TenantSecurityPage(embedded: true),
        ),
      );
    } else {
      tabs.add(
        _TabDefinition(
          key: 'visitors',
          title: widget.role.visitorSectionTitle,
          label: widget.role == AppRole.visitor ? 'Visits' : 'Visitors',
          icon: widget.role == AppRole.visitor
              ? Icons.qr_code_scanner_outlined
              : Icons.badge_outlined,
          child: VisitorsPage(
            role: widget.role,
            visitors: _repository.visitorsForRole(widget.role),
          ),
        ),
      );
    }

    tabs.add(
      _TabDefinition(
        key: 'more',
        title: 'Account',
        label: 'Account',
        icon: Icons.person_outline_rounded,
        child: MorePage(
          role: widget.role,
          vendor: _vendor,
          modules: _modulesForRole(widget.role),
          onModuleSelected: (ModuleStatusItem module) =>
              _openModule(context, module),
          onLogout: widget.onLogout,
        ),
      ),
    );

    return tabs;
  }

  List<_TabDefinition> _buildPropertyManagerTabs() {
    return <_TabDefinition>[
      _TabDefinition(
        key: 'dashboard',
        title: 'Home',
        label: 'Home',
        icon: Icons.home_outlined,
        child: DashboardPage(
          role: widget.role,
          metrics: _dashboardMetrics(),
          shortcuts: _shortcutsForRole(widget.role),
          announcements: _announcements,
          tickets: _tickets,
          bills: _bills,
          vendor: _vendor,
          societyInfo: null,
          blockCount: 0,
          buildingCount: 0,
          onShortcutSelected: (String actionKey) => _handleShortcut(actionKey),
          isLoading: _isLoading,
          onRefresh: _loadData,
        ),
      ),
      const _TabDefinition(
        key: 'properties',
        title: 'Properties',
        label: 'Properties',
        icon: Icons.home_work_outlined,
        child: PropertiesPage(),
      ),
      const _TabDefinition(
        key: 'rental_contracts',
        title: 'Contracts',
        label: 'Contracts',
        icon: Icons.description_outlined,
        child: RentalContractsPage(),
      ),
      _TabDefinition(
        key: 'billing',
        title: 'Rental Bills',
        label: 'Bills',
        icon: Icons.receipt_long_outlined,
        child: BillingPage(
          role: widget.role,
          bills: _bills,
          isLoading: _isLoading,
          onRefresh: _loadData,
        ),
      ),
      _TabDefinition(
        key: 'more',
        title: 'Account',
        label: 'Account',
        icon: Icons.person_outline_rounded,
        child: MorePage(
          role: widget.role,
          vendor: _vendor,
          modules: _modulesForRole(widget.role),
          onModuleSelected: (ModuleStatusItem module) =>
              _openModule(context, module),
          onLogout: widget.onLogout,
        ),
      ),
    ];
  }

  void _handleShortcut(String actionKey) {
    if (!mounted) {
      return;
    }

    final List<_TabDefinition> tabs = _buildTabs();
    final int? index = switch (actionKey) {
      'billing' => tabs.indexWhere((tab) => tab.key == 'billing'),
      'visitors' => tabs.indexWhere((tab) => tab.key == 'visitors'),
      'security_alerts' => tabs.indexWhere((tab) => tab.key == 'security_alerts'),
      'support' => tabs.indexWhere((tab) => tab.key == 'support'),
      'properties' => tabs.indexWhere((tab) => tab.key == 'properties'),
      'rental_contracts' => tabs.indexWhere((tab) => tab.key == 'rental_contracts'),
      _ => null,
    };

    if (index != null && index >= 0) {
      setState(() {
        _selectedIndex = index;
      });
      return;
    }

    if (actionKey == 'communication') {
      _openCommunication(context);
      return;
    }

    final ModuleStatusItem module = ModuleStatusItem(
      title: _prettyTitle(actionKey),
      subtitle: 'Open the website-backed module in the mobile shell.',
      icon: Icons.layers_outlined,
      phaseLabel: 'Ready now',
      actionKey: actionKey,
      readyNow: true,
    );
    _openModule(context, module);
  }

  void _openCommunication(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => CommunicationPage(
          role: widget.role,
          announcements: _announcements,
          isLoading: _isLoading,
          onRefresh: _loadData,
        ),
      ),
    );
  }

  void _openModule(BuildContext context, ModuleStatusItem module) {
    final Widget? page = switch (module.actionKey) {
      'communication' => CommunicationPage(
          role: widget.role,
          announcements: _announcements,
          isLoading: _isLoading,
          onRefresh: _loadData,
        ),
      'settings' => const SettingsPage(),
      'society_management' => const SocietyManagementPage(),
      'bank_details' => const BankWalletPage(),
      'notifications' => const NotificationsPage(),
      'residents' || 'module_residents' => const ResidentsPage(),
      'security' => const SecurityPage(),
      'reports' => const ReportsPage(),
      'audit' => const AuditLogsPage(),
      'properties' || 'module_properties' => const PropertiesPage(),
      'enquiries' => const PropertyEnquiriesPage(),
      'rental_contracts' => const RentalContractsPage(),
      'tenant_contracts' => const TenantContractsPage(),
      'security_alerts' => const TenantSecurityPage(),
      'block_residents' => const ResidentsPage(),
      'block_security' => BlockSecurityPage(
          visitors: _repository.visitorsForRole(widget.role),
          issues: _repository.ticketsForRole(widget.role),
        ),
      'block_issues' => BlockIssuesPage(
          issues: _repository.ticketsForRole(widget.role),
        ),
      'my_property' => const ResidenceOverviewPage(
          kind: ResidenceOverviewKind.myProperty,
        ),
      'pg_details' => const ResidenceOverviewPage(
          kind: ResidenceOverviewKind.pgDetails,
        ),
      'bookings' => const PropertyBookingsPage(),
      'my_visits' => MyVisitsPage(
          visits: _repository.visitorsForRole(widget.role),
        ),
      'rental_bills' => Scaffold(
          appBar: AppBar(
            titleSpacing: 16,
            title: Text(widget.role.billingSectionTitle),
            bottom: const PreferredSize(
              preferredSize: Size.fromHeight(1),
              child: Divider(
                height: 1,
                thickness: 1,
                color: AppTheme.border,
              ),
            ),
          ),
          body: BillingPage(
            role: widget.role,
            bills: _bills,
            isLoading: _isLoading,
            onRefresh: _loadData,
          ),
        ),
      _ => null,
    };

    final List<_TabDefinition> tabs = _buildTabs();
    final int capturedIndex = _selectedIndex;

    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => Scaffold(
          body: page ?? ModulePlaceholderPage(module: module),
          bottomNavigationBar: CustomBottomNavBar(
            selectedIndex: capturedIndex,
            onSelected: (int index) {
              Navigator.of(context).pop();
              if (mounted) setState(() => _selectedIndex = index);
            },
            items: tabs
                .map((_TabDefinition tab) => CustomBottomNavItem(
                      label: tab.label,
                      icon: tab.icon,
                    ))
                .toList(),
          ),
        ),
      ),
    ).then((_) {
      if (mounted && module.actionKey == 'settings') {
        _loadData();
      }
    });
  }

  String _prettyTitle(String actionKey) {
    final String withSpaces = actionKey.replaceAll('_', ' ');
    return withSpaces.isEmpty
        ? 'Module'
        : '${withSpaces[0].toUpperCase()}${withSpaces.substring(1)}';
  }

  List<DashboardMetric> _dashboardMetrics() {
    if (_isLoading) {
      return _loadingMetricsForRole(widget.role);
    }

    return switch (widget.role) {
      AppRole.societyManager ||
      AppRole.treasurer ||
      AppRole.president ||
      AppRole.blockSecretary =>
        _societyDashboardMetrics(),
      AppRole.propertyManager => _propertyDashboardMetrics(),
      AppRole.tenant || AppRole.owner || AppRole.pgResident =>
        _tenantDashboardMetrics(),
      AppRole.visitor => _visitorDashboardMetrics(),
    };
  }

  List<DashboardMetric> _societyDashboardMetrics() {
    final SupportTicketSummaryData? supportSummary = _vendor?.supportTicketSummary;
    final BillCollectionSummaryData? billSummary =
        _vendor?.billCollectionSummary;
    final WalletSummaryData? walletInfo = _vendor?.walletInfo;
    final int unreadAnnouncements =
        _announcements.where((AnnouncementRecord item) => item.unread).length;

    return <DashboardMetric>[
      DashboardMetric(
        title: 'Open Tickets',
        value: '${supportSummary?.openTicketsCount ?? _countTickets(TicketStatus.open)}',
        subtitle: 'Society support queue',
        tone: UiTone.warning,
      ),
      DashboardMetric(
        title: 'In Progress',
        value:
            '${supportSummary?.inProgressTicketsCount ?? _countTickets(TicketStatus.inProgress)}',
        subtitle: 'Active backend cases',
        tone: UiTone.brand,
      ),
      DashboardMetric(
        title: 'Unread Notices',
        value: '$unreadAnnouncements',
        subtitle:
            '${_announcements.length} announcements, ${_unreadNotificationCount()} alerts',
        tone: UiTone.neutral,
      ),
      DashboardMetric(
        title: 'This Month',
        value: _formatCurrencyCompact(
          billSummary?.currentMonthCollected ?? _paidBillAmount(),
        ),
        subtitle: 'Collected maintenance amount',
        tone: UiTone.success,
      ),
      DashboardMetric(
        title: 'Total Pending',
        value: _formatCurrencyCompact(billSummary?.totalPendingAmount ?? 0),
        subtitle: 'Pending maintenance dues',
        tone: UiTone.warning,
      ),
      DashboardMetric(
        title: "Today's Collection",
        value: _formatCurrencyCompact(billSummary?.todaysCollection ?? 0),
        subtitle: 'Collected today',
        tone: UiTone.brand,
      ),
      DashboardMetric(
        title: 'Wallet Balance',
        value: _formatCurrencyCompact(walletInfo?.availableAmount ?? 0),
        subtitle: 'Available wallet amount',
        tone: UiTone.success,
      ),
    ];
  }

  List<DashboardMetric> _propertyDashboardMetrics() {
    final PropertySummaryData? propertySummary = _vendor?.propertySummary;
    final RentalContractSummaryData? contractSummary =
        _vendor?.rentalContractSummary;
    final BillCollectionSummaryData? billSummary =
        _vendor?.billCollectionSummary;

    return <DashboardMetric>[
      DashboardMetric(
        title: 'Properties',
        value: '${propertySummary?.totalPropertiesCount ?? 0}',
        subtitle: '${propertySummary?.approvedPropertiesCount ?? 0} approved',
        tone: UiTone.brand,
      ),
      DashboardMetric(
        title: 'Live Contracts',
        value: '${contractSummary?.activeContractsCount ?? 0}',
        subtitle: '${contractSummary?.pendingRenewalCount ?? 0} near renewal',
        tone: UiTone.success,
      ),
      DashboardMetric(
        title: 'Pending Approval',
        value: '${propertySummary?.pendingPropertiesCount ?? 0}',
        subtitle: '${propertySummary?.rejectedPropertiesCount ?? 0} rejected',
        tone: UiTone.warning,
      ),
      DashboardMetric(
        title: 'Outstanding',
        value: _formatCurrencyCompact(
          billSummary?.currentMonthPending ?? _pendingBillAmount(),
        ),
        subtitle: 'Current month pending bills',
        tone: UiTone.neutral,
      ),
    ];
  }

  List<DashboardMetric> _tenantDashboardMetrics() {
    final double dueAmount = _bills
        .where((BillRecord bill) =>
            bill.status == BillStatus.pending || bill.status == BillStatus.overdue)
        .fold<double>(0, (double sum, BillRecord bill) => sum + bill.amount);
    final int openTickets = _tickets
        .where((TicketRecord ticket) =>
            ticket.status == TicketStatus.open ||
            ticket.status == TicketStatus.inProgress)
        .length;
    final int unreadAnnouncements =
        _announcements.where((AnnouncementRecord item) => item.unread).length;
    final BillRecord? lastPaidBill = _latestPaidBill();

    return <DashboardMetric>[
      DashboardMetric(
        title: 'Due Amount',
        value: _formatCurrencyCompact(dueAmount),
        subtitle: '${_bills.where((BillRecord bill) => bill.status != BillStatus.paid).length} unsettled bills',
        tone: dueAmount > 0 ? UiTone.warning : UiTone.success,
      ),
      DashboardMetric(
        title: 'Open Tickets',
        value: '$openTickets',
        subtitle: 'Support cases in progress',
        tone: UiTone.brand,
      ),
      DashboardMetric(
        title: 'Unread Notices',
        value: '$unreadAnnouncements',
        subtitle:
            '${_announcements.length} updates, ${_unreadNotificationCount()} alerts',
        tone: UiTone.neutral,
      ),
      DashboardMetric(
        title: 'Last Payment',
        value: lastPaidBill == null
            ? 'No payment'
            : _formatCurrencyCompact(lastPaidBill.amount),
        subtitle: lastPaidBill == null
            ? 'No paid bill recorded yet'
            : formatCompactDate(lastPaidBill.dueDate),
        tone: UiTone.success,
      ),
    ];
  }

  List<DashboardMetric> _visitorDashboardMetrics() {
    final int openTickets = _countTickets(TicketStatus.open) +
        _countTickets(TicketStatus.inProgress);
    final int unreadAnnouncements =
        _announcements.where((AnnouncementRecord item) => item.unread).length;

    return <DashboardMetric>[
      DashboardMetric(
        title: 'Open Tickets',
        value: '$openTickets',
        subtitle: 'Active support cases',
        tone: UiTone.brand,
      ),
      DashboardMetric(
        title: 'Unread Notices',
        value: '$unreadAnnouncements',
        subtitle:
            '${_announcements.length} announcement${_announcements.length == 1 ? '' : 's'}',
        tone: UiTone.neutral,
      ),
      DashboardMetric(
        title: 'Alerts',
        value: '${_unreadNotificationCount()}',
        subtitle: 'Unread notifications',
        tone: _unreadNotificationCount() > 0 ? UiTone.warning : UiTone.success,
      ),
    ];
  }

  int _countTickets(TicketStatus status) {
    return _tickets.where((TicketRecord item) => item.status == status).length;
  }

  double _paidBillAmount() {
    return _bills
        .where((BillRecord bill) => bill.status == BillStatus.paid)
        .fold<double>(0, (double sum, BillRecord bill) => sum + bill.amount);
  }

  double _pendingBillAmount() {
    return _bills
        .where((BillRecord bill) =>
            bill.status == BillStatus.pending || bill.status == BillStatus.overdue)
        .fold<double>(0, (double sum, BillRecord bill) => sum + bill.amount);
  }

  BillRecord? _latestPaidBill() {
    final List<BillRecord> paidBills = _bills
        .where((BillRecord bill) => bill.status == BillStatus.paid)
        .toList()
      ..sort((BillRecord a, BillRecord b) => b.dueDate.compareTo(a.dueDate));
    return paidBills.isEmpty ? null : paidBills.first;
  }

  int _unreadNotificationCount() {
    return _notifications
        .where((NotificationRecord item) => !item.isRead)
        .length;
  }

  static List<DashboardMetric> _loadingMetricsForRole(AppRole role) {
    const String dash = '\u2014';
    const String loading = 'Loading\u2026';
    return switch (role) {
      AppRole.societyManager ||
      AppRole.treasurer ||
      AppRole.president ||
      AppRole.blockSecretary =>
        const <DashboardMetric>[
          DashboardMetric(
            title: 'Open Tickets',
            value: dash,
            subtitle: loading,
            tone: UiTone.warning,
          ),
          DashboardMetric(
            title: 'In Progress',
            value: dash,
            subtitle: loading,
            tone: UiTone.brand,
          ),
          DashboardMetric(
            title: 'Unread Notices',
            value: dash,
            subtitle: loading,
            tone: UiTone.neutral,
          ),
          DashboardMetric(
            title: 'This Month',
            value: dash,
            subtitle: loading,
            tone: UiTone.success,
          ),
        ],
      AppRole.propertyManager => const <DashboardMetric>[
        DashboardMetric(
          title: 'Properties',
          value: dash,
          subtitle: loading,
          tone: UiTone.brand,
        ),
        DashboardMetric(
          title: 'Live Contracts',
          value: dash,
          subtitle: loading,
          tone: UiTone.success,
        ),
        DashboardMetric(
          title: 'Pending Approval',
          value: dash,
          subtitle: loading,
          tone: UiTone.warning,
        ),
        DashboardMetric(
          title: 'Outstanding',
          value: dash,
          subtitle: loading,
          tone: UiTone.neutral,
        ),
      ],
      AppRole.tenant || AppRole.owner || AppRole.pgResident =>
        const <DashboardMetric>[
          DashboardMetric(
            title: 'Due Amount',
            value: dash,
            subtitle: loading,
            tone: UiTone.warning,
          ),
          DashboardMetric(
            title: 'Open Tickets',
            value: dash,
            subtitle: loading,
            tone: UiTone.brand,
          ),
          DashboardMetric(
            title: 'Unread Notices',
            value: dash,
            subtitle: loading,
            tone: UiTone.neutral,
          ),
          DashboardMetric(
            title: 'Last Payment',
            value: dash,
            subtitle: loading,
            tone: UiTone.success,
          ),
        ],
      AppRole.visitor => const <DashboardMetric>[
        DashboardMetric(
          title: 'Open Tickets',
          value: dash,
          subtitle: loading,
          tone: UiTone.brand,
        ),
        DashboardMetric(
          title: 'Unread Notices',
          value: dash,
          subtitle: loading,
          tone: UiTone.neutral,
        ),
        DashboardMetric(
          title: 'Alerts',
          value: dash,
          subtitle: loading,
          tone: UiTone.warning,
        ),
      ],
    };
  }

  static List<AppShortcut> _shortcutsForRole(AppRole role) {
    return switch (role) {
      AppRole.societyManager => const <AppShortcut>[
        AppShortcut(
          title: 'Society',
          subtitle: 'Profile, billing rules, blocks, and buildings',
          icon: Icons.apartment_outlined,
          actionKey: 'society_management',
        ),
        AppShortcut(
          title: 'Residents',
          subtitle: 'Manage resident records and status',
          icon: Icons.groups_outlined,
          actionKey: 'residents',
        ),
        AppShortcut(
          title: 'Security',
          subtitle: 'Track incidents and update status',
          icon: Icons.shield_outlined,
          actionKey: 'security',
        ),
        AppShortcut(
          title: 'Wallet',
          subtitle: 'Bank accounts, payouts, and ledger',
          icon: Icons.account_balance_wallet_outlined,
          actionKey: 'bank_details',
        ),
      ],
      AppRole.propertyManager => const <AppShortcut>[
        AppShortcut(
          title: 'Properties',
          subtitle: 'Inventory, status, and detail review',
          icon: Icons.apartment_outlined,
          actionKey: 'properties',
        ),
        AppShortcut(
          title: 'Enquiries',
          subtitle: 'Follow up on property leads',
          icon: Icons.manage_search_outlined,
          actionKey: 'enquiries',
        ),
        AppShortcut(
          title: 'Contracts',
          subtitle: 'Rental agreements and vacate flow',
          icon: Icons.description_outlined,
          actionKey: 'rental_contracts',
        ),
      ],
      AppRole.treasurer => const <AppShortcut>[
        AppShortcut(
          title: 'Review Bills',
          subtitle: 'Jump to due and overdue records',
          icon: Icons.receipt_long_outlined,
          actionKey: 'billing',
        ),
        AppShortcut(
          title: 'Support Queue',
          subtitle: 'Finance and maintenance tickets',
          icon: Icons.support_agent_outlined,
          actionKey: 'support',
        ),
        AppShortcut(
          title: 'Announcements',
          subtitle: 'Broadcast reminders and notices',
          icon: Icons.campaign_outlined,
          actionKey: 'communication',
        ),
      ],
      AppRole.president => const <AppShortcut>[
        AppShortcut(
          title: 'Resident Updates',
          subtitle: 'Track daily operations from one view',
          icon: Icons.groups_outlined,
          actionKey: 'module_residents',
        ),
        AppShortcut(
          title: 'Property Review',
          subtitle: 'Inspect vacant and occupied units',
          icon: Icons.apartment_outlined,
          actionKey: 'module_properties',
        ),
        AppShortcut(
          title: 'Announcements',
          subtitle: 'Share society-wide updates',
          icon: Icons.campaign_outlined,
          actionKey: 'communication',
        ),
      ],
      AppRole.owner => const <AppShortcut>[
        AppShortcut(
          title: 'My Bills',
          subtitle: 'Track current due amounts',
          icon: Icons.payments_outlined,
          actionKey: 'billing',
        ),
        AppShortcut(
          title: 'Visitors',
          subtitle: 'Approve guests and deliveries',
          icon: Icons.badge_outlined,
          actionKey: 'visitors',
        ),
        AppShortcut(
          title: 'Support',
          subtitle: 'Raise issues fast from mobile',
          icon: Icons.report_problem_outlined,
          actionKey: 'support',
        ),
      ],
      AppRole.tenant => const <AppShortcut>[
        AppShortcut(
          title: 'My Bills',
          subtitle: 'Review pending, paid, and overdue charges',
          icon: Icons.payments_outlined,
          actionKey: 'billing',
        ),
        AppShortcut(
          title: 'Security Alerts',
          subtitle: 'Track incident updates tied to your residence',
          icon: Icons.shield_outlined,
          actionKey: 'security_alerts',
        ),
        AppShortcut(
          title: 'Rental Contracts',
          subtitle: 'Lease details, KYC, and vacate workflow',
          icon: Icons.description_outlined,
          actionKey: 'tenant_contracts',
        ),
      ],
      AppRole.pgResident => const <AppShortcut>[
        AppShortcut(
          title: 'My Bills',
          subtitle: 'Review stay and rent charges',
          icon: Icons.payments_outlined,
          actionKey: 'billing',
        ),
        AppShortcut(
          title: 'Visitors',
          subtitle: 'Check guest approvals',
          icon: Icons.people_outline,
          actionKey: 'visitors',
        ),
        AppShortcut(
          title: 'Communication',
          subtitle: 'Read management updates',
          icon: Icons.forum_outlined,
          actionKey: 'communication',
        ),
      ],
      AppRole.visitor => const <AppShortcut>[
        AppShortcut(
          title: 'My Visits',
          subtitle: 'See active and scheduled entries',
          icon: Icons.qr_code_outlined,
          actionKey: 'visitors',
        ),
        AppShortcut(
          title: 'Communication',
          subtitle: 'Read access and maintenance notices',
          icon: Icons.notifications_active_outlined,
          actionKey: 'communication',
        ),
        AppShortcut(
          title: 'Support',
          subtitle: 'Contact the help desk if blocked',
          icon: Icons.support_agent_outlined,
          actionKey: 'support',
        ),
      ],
      AppRole.blockSecretary => const <AppShortcut>[
        AppShortcut(
          title: 'Block Visitors',
          subtitle: 'Move to current visitor queue',
          icon: Icons.shield_outlined,
          actionKey: 'visitors',
        ),
        AppShortcut(
          title: 'Issue Desk',
          subtitle: 'Update the support board',
          icon: Icons.assignment_turned_in_outlined,
          actionKey: 'support',
        ),
        AppShortcut(
          title: 'Block Notice',
          subtitle: 'Share urgent updates quickly',
          icon: Icons.campaign_outlined,
          actionKey: 'communication',
        ),
      ],
    };
  }

  static List<ModuleStatusItem> _modulesForRole(AppRole role) {
    return switch (role) {
      AppRole.societyManager => const <ModuleStatusItem>[
        ModuleStatusItem(
          title: 'Society Management',
          subtitle: 'Society profile, billing defaults, blocks, and buildings',
          icon: Icons.apartment_outlined,
          phaseLabel: 'Ready now',
          actionKey: 'society_management',
          readyNow: true,
        ),
        ModuleStatusItem(
          title: 'Communication',
          subtitle: 'Society announcements and notices',
          icon: Icons.campaign_outlined,
          phaseLabel: 'Ready now',
          actionKey: 'communication',
          readyNow: true,
        ),
        ModuleStatusItem(
          title: 'Residents',
          subtitle: 'Resident directory, filters, and status actions',
          icon: Icons.groups_outlined,
          phaseLabel: 'Ready now',
          actionKey: 'residents',
          readyNow: true,
        ),
        ModuleStatusItem(
          title: 'Security',
          subtitle: 'Incident queue and update actions',
          icon: Icons.shield_outlined,
          phaseLabel: 'Ready now',
          actionKey: 'security',
          readyNow: true,
        ),
        ModuleStatusItem(
          title: 'Bank Details',
          subtitle: 'Wallet, bank accounts, and withdrawals',
          icon: Icons.account_balance_wallet_outlined,
          phaseLabel: 'Ready now',
          actionKey: 'bank_details',
          readyNow: true,
        ),
        ModuleStatusItem(
          title: 'Settings',
          subtitle: 'Profile and account preferences',
          icon: Icons.settings_outlined,
          phaseLabel: 'Ready now',
          actionKey: 'settings',
          readyNow: true,
        ),
      ],
      AppRole.propertyManager => const <ModuleStatusItem>[
        ModuleStatusItem(
          title: 'Properties',
          subtitle: 'Listing, detail, and status management',
          icon: Icons.apartment_outlined,
          phaseLabel: 'Ready now',
          actionKey: 'properties',
          readyNow: true,
        ),
        ModuleStatusItem(
          title: 'Enquiries',
          subtitle: 'Lead queue and follow-up status',
          icon: Icons.manage_search_outlined,
          phaseLabel: 'Ready now',
          actionKey: 'enquiries',
          readyNow: true,
        ),
        ModuleStatusItem(
          title: 'Rental Contracts',
          subtitle: 'Contract list and lifecycle actions',
          icon: Icons.description_outlined,
          phaseLabel: 'Ready now',
          actionKey: 'rental_contracts',
          readyNow: true,
        ),
        ModuleStatusItem(
          title: 'Bank Details',
          subtitle: 'Payout accounts, wallet, and withdrawals',
          icon: Icons.account_balance_wallet_outlined,
          phaseLabel: 'Ready now',
          actionKey: 'bank_details',
          readyNow: true,
        ),
        ModuleStatusItem(
          title: 'Settings',
          subtitle: 'Profile and account preferences',
          icon: Icons.settings_outlined,
          phaseLabel: 'Ready now',
          actionKey: 'settings',
          readyNow: true,
        ),
      ],
      AppRole.treasurer => const <ModuleStatusItem>[
        ModuleStatusItem(
          title: 'Communication',
          subtitle: 'Announcements and notification center',
          icon: Icons.campaign_outlined,
          phaseLabel: 'Ready now',
          actionKey: 'communication',
          readyNow: true,
        ),
        ModuleStatusItem(
          title: 'Reports',
          subtitle: 'Live vendor-summary analytics from the backend',
          icon: Icons.bar_chart_outlined,
          phaseLabel: 'Ready now',
          actionKey: 'reports',
          readyNow: true,
        ),
        ModuleStatusItem(
          title: 'Audit Logs',
          subtitle: 'Notification-backed activity and audit trail',
          icon: Icons.fact_check_outlined,
          phaseLabel: 'Ready now',
          actionKey: 'audit',
          readyNow: true,
        ),
        ModuleStatusItem(
          title: 'Settings',
          subtitle: 'Billing preferences and commission settings',
          icon: Icons.settings_outlined,
          phaseLabel: 'Ready now',
          actionKey: 'settings',
          readyNow: true,
        ),
      ],
      AppRole.president => const <ModuleStatusItem>[
        ModuleStatusItem(
          title: 'Society Management',
          subtitle: 'Society profile, rates, billing rules, and structure',
          icon: Icons.apartment_outlined,
          phaseLabel: 'Ready now',
          actionKey: 'society_management',
          readyNow: true,
        ),
        ModuleStatusItem(
          title: 'Communication',
          subtitle: 'Send and review society announcements',
          icon: Icons.campaign_outlined,
          phaseLabel: 'Ready now',
          actionKey: 'communication',
          readyNow: true,
        ),
        ModuleStatusItem(
          title: 'Residents',
          subtitle: 'Resident directory and validity rules',
          icon: Icons.groups_outlined,
          phaseLabel: 'Ready now',
          actionKey: 'residents',
          readyNow: true,
        ),
        ModuleStatusItem(
          title: 'Properties',
          subtitle: 'Inventory, vacancy, and onboarding flow',
          icon: Icons.apartment_outlined,
          phaseLabel: 'Ready now',
          actionKey: 'properties',
          readyNow: true,
        ),
        ModuleStatusItem(
          title: 'Security',
          subtitle: 'Incidents, guards, and CCTV overview',
          icon: Icons.shield_outlined,
          phaseLabel: 'Ready now',
          actionKey: 'security',
          readyNow: true,
        ),
        ModuleStatusItem(
          title: 'Rental Contracts',
          subtitle: 'Contract inspection and renewal pipeline',
          icon: Icons.description_outlined,
          phaseLabel: 'Ready now',
          actionKey: 'rental_contracts',
          readyNow: true,
        ),
        ModuleStatusItem(
          title: 'Rental Bills',
          subtitle: 'Rent collection and overdue follow-up',
          icon: Icons.request_quote_outlined,
          phaseLabel: 'Ready now',
          actionKey: 'rental_bills',
          readyNow: true,
        ),
      ],
      AppRole.owner => const <ModuleStatusItem>[
        ModuleStatusItem(
          title: 'Communication',
          subtitle: 'Announcements and community notices',
          icon: Icons.forum_outlined,
          phaseLabel: 'Ready now',
          actionKey: 'communication',
          readyNow: true,
        ),
        ModuleStatusItem(
          title: 'Settings',
          subtitle: 'Profile, billing preference, and privacy',
          icon: Icons.settings_outlined,
          phaseLabel: 'Ready now',
          actionKey: 'settings',
          readyNow: true,
        ),
        ModuleStatusItem(
          title: 'Rental Contracts',
          subtitle: 'Lease details and ready-to-vacate workflow',
          icon: Icons.description_outlined,
          phaseLabel: 'Ready now',
          actionKey: 'tenant_contracts',
          readyNow: true,
        ),
        ModuleStatusItem(
          title: 'Security Alerts',
          subtitle: 'Incident updates tied to your residence',
          icon: Icons.shield_outlined,
          phaseLabel: 'Ready now',
          actionKey: 'security_alerts',
          readyNow: true,
        ),
        ModuleStatusItem(
          title: 'My Property',
          subtitle: 'Current contract and billing summary for this residence',
          icon: Icons.home_work_outlined,
          phaseLabel: 'Ready now',
          actionKey: 'my_property',
          readyNow: true,
        ),
        ModuleStatusItem(
          title: 'My Bookings',
          subtitle: 'Property booking payments, approvals, and refunds',
          icon: Icons.event_available_outlined,
          phaseLabel: 'Ready now',
          actionKey: 'bookings',
          readyNow: true,
        ),
      ],
      AppRole.tenant => const <ModuleStatusItem>[
        ModuleStatusItem(
          title: 'Communication',
          subtitle: 'Announcements and community notices',
          icon: Icons.forum_outlined,
          phaseLabel: 'Ready now',
          actionKey: 'communication',
          readyNow: true,
        ),
        ModuleStatusItem(
          title: 'Rental Contracts',
          subtitle: 'Lease details and ready-to-vacate workflow',
          icon: Icons.description_outlined,
          phaseLabel: 'Ready now',
          actionKey: 'tenant_contracts',
          readyNow: true,
        ),
        ModuleStatusItem(
          title: 'Settings',
          subtitle: 'Profile, billing preference, and privacy',
          icon: Icons.settings_outlined,
          phaseLabel: 'Ready now',
          actionKey: 'settings',
          readyNow: true,
        ),
        ModuleStatusItem(
          title: 'My Property',
          subtitle: 'Current contract and billing summary for this residence',
          icon: Icons.home_work_outlined,
          phaseLabel: 'Ready now',
          actionKey: 'my_property',
          readyNow: true,
        ),
        ModuleStatusItem(
          title: 'My Bookings',
          subtitle: 'Property booking payments, approvals, and refunds',
          icon: Icons.event_available_outlined,
          phaseLabel: 'Ready now',
          actionKey: 'bookings',
          readyNow: true,
        ),
      ],
      AppRole.pgResident => const <ModuleStatusItem>[
        ModuleStatusItem(
          title: 'Communication',
          subtitle: 'Read management updates and notices',
          icon: Icons.forum_outlined,
          phaseLabel: 'Ready now',
          actionKey: 'communication',
          readyNow: true,
        ),
        ModuleStatusItem(
          title: 'PG Details',
          subtitle: 'Current stay, contract, and billing summary',
          icon: Icons.meeting_room_outlined,
          phaseLabel: 'Ready now',
          actionKey: 'pg_details',
          readyNow: true,
        ),
        ModuleStatusItem(
          title: 'Settings',
          subtitle: 'Notification and profile preferences',
          icon: Icons.settings_outlined,
          phaseLabel: 'Ready now',
          actionKey: 'settings',
          readyNow: true,
        ),
      ],
      AppRole.visitor => const <ModuleStatusItem>[
        ModuleStatusItem(
          title: 'Communication',
          subtitle: 'Read visit-impacting announcements',
          icon: Icons.notifications_active_outlined,
          phaseLabel: 'Ready now',
          actionKey: 'communication',
          readyNow: true,
        ),
        ModuleStatusItem(
          title: 'Visitor QR Access',
          subtitle: 'Dedicated QR pass flow for gate entry',
          icon: Icons.qr_code_outlined,
          phaseLabel: 'Ready now',
          actionKey: 'my_visits',
          readyNow: true,
        ),
      ],
      AppRole.blockSecretary => const <ModuleStatusItem>[
        ModuleStatusItem(
          title: 'Communication',
          subtitle: 'Block-wide announcements and urgent notices',
          icon: Icons.campaign_outlined,
          phaseLabel: 'Ready now',
          actionKey: 'communication',
          readyNow: true,
        ),
        ModuleStatusItem(
          title: 'Block Residents',
          subtitle: 'Resident directory for the current block',
          icon: Icons.groups_outlined,
          phaseLabel: 'Ready now',
          actionKey: 'block_residents',
          readyNow: true,
        ),
        ModuleStatusItem(
          title: 'Block Security',
          subtitle: 'Incidents, visitors, and camera status',
          icon: Icons.shield_outlined,
          phaseLabel: 'Ready now',
          actionKey: 'block_security',
          readyNow: true,
        ),
        ModuleStatusItem(
          title: 'Block Issues',
          subtitle: 'Track issue lifecycle and escalations',
          icon: Icons.assignment_late_outlined,
          phaseLabel: 'Ready now',
          actionKey: 'block_issues',
          readyNow: true,
        ),
      ],
    };
  }

  String _formatCurrencyCompact(double value) {
    if (value >= 100000) {
      return 'Rs ${(value / 100000).toStringAsFixed(1)}L';
    }
    if (value >= 1000) {
      return 'Rs ${(value / 1000).toStringAsFixed(1)}K';
    }
    return 'Rs ${value.toStringAsFixed(0)}';
  }
}

class _TabDefinition {
  const _TabDefinition({
    required this.key,
    required this.title,
    required this.label,
    required this.icon,
    required this.child,
  });

  final String key;
  final String title;
  final String label;
  final IconData icon;
  final Widget child;
}

class _NotificationBell extends StatelessWidget {
  const _NotificationBell({
    required this.unreadCount,
    required this.onTap,
  });

  final int unreadCount;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: 'Notifications',
      onPressed: onTap,
      icon: Stack(
        clipBehavior: Clip.none,
        children: <Widget>[
          const Icon(Icons.notifications_outlined),
          if (unreadCount > 0)
            Positioned(
              top: -4,
              right: -4,
              child: Container(
                padding: const EdgeInsets.all(2),
                constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                decoration: const BoxDecoration(
                  color: Color(0xFFDC2626),
                  shape: BoxShape.circle,
                ),
                child: Text(
                  unreadCount > 99 ? '99+' : '$unreadCount',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    height: 1,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
