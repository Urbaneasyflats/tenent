import 'package:flutter/material.dart';

import '../models/app_models.dart';

class MockUrbanRepository {
  const MockUrbanRepository();

  List<DashboardMetric> metricsForRole(AppRole role) {
    return switch (role) {
      AppRole.societyManager => const <DashboardMetric>[
        DashboardMetric(
          title: 'Residents',
          value: '156',
          subtitle: 'Across active society units',
          tone: UiTone.brand,
        ),
        DashboardMetric(
          title: 'Open Tickets',
          value: '5',
          subtitle: 'Support and security combined',
          tone: UiTone.warning,
        ),
        DashboardMetric(
          title: 'Announcements',
          value: '12',
          subtitle: 'Recent society broadcasts',
          tone: UiTone.neutral,
        ),
        DashboardMetric(
          title: 'Collections',
          value: 'Rs 1.84L',
          subtitle: 'Current month billed value',
          tone: UiTone.success,
        ),
      ],
      AppRole.propertyManager => const <DashboardMetric>[
        DashboardMetric(
          title: 'Properties',
          value: '18',
          subtitle: 'Managed inventory',
          tone: UiTone.brand,
        ),
        DashboardMetric(
          title: 'Live Contracts',
          value: '11',
          subtitle: 'Current active agreements',
          tone: UiTone.success,
        ),
        DashboardMetric(
          title: 'Open Enquiries',
          value: '9',
          subtitle: 'Leads awaiting follow-up',
          tone: UiTone.warning,
        ),
        DashboardMetric(
          title: 'Rental Bills',
          value: '27',
          subtitle: 'Current billing cycle',
          tone: UiTone.neutral,
        ),
      ],
      AppRole.treasurer => const <DashboardMetric>[
        DashboardMetric(
          title: 'Total Collection',
          value: 'Rs 1.84L',
          subtitle: '12 percent above last cycle',
          tone: UiTone.success,
        ),
        DashboardMetric(
          title: 'Outstanding',
          value: 'Rs 18.2K',
          subtitle: '3 overdue units need follow-up',
          tone: UiTone.warning,
        ),
        DashboardMetric(
          title: 'Generated Bills',
          value: '47',
          subtitle: 'Maintenance plus rent billing',
          tone: UiTone.brand,
        ),
        DashboardMetric(
          title: 'Collection Rate',
          value: '91%',
          subtitle: 'Healthy payment conversion',
          tone: UiTone.neutral,
        ),
      ],
      AppRole.president => const <DashboardMetric>[
        DashboardMetric(
          title: 'Residents',
          value: '156',
          subtitle: 'Across 85 total units',
          tone: UiTone.brand,
        ),
        DashboardMetric(
          title: 'Open Issues',
          value: '5',
          subtitle: '2 high priority cases',
          tone: UiTone.warning,
        ),
        DashboardMetric(
          title: 'Vacant Units',
          value: '7',
          subtitle: 'Property follow-up required',
          tone: UiTone.neutral,
        ),
        DashboardMetric(
          title: 'Visitors Today',
          value: '11',
          subtitle: '3 still checked in',
          tone: UiTone.success,
        ),
      ],
      AppRole.owner => const <DashboardMetric>[
        DashboardMetric(
          title: 'Due Amount',
          value: 'Rs 5,900',
          subtitle: 'Due in 7 days',
          tone: UiTone.warning,
        ),
        DashboardMetric(
          title: 'Visitors',
          value: '4',
          subtitle: '1 active visit right now',
          tone: UiTone.brand,
        ),
        DashboardMetric(
          title: 'Open Tickets',
          value: '1',
          subtitle: 'Lift issue is in progress',
          tone: UiTone.neutral,
        ),
        DashboardMetric(
          title: 'Last Payment',
          value: 'Rs 5,310',
          subtitle: 'Recorded successfully',
          tone: UiTone.success,
        ),
      ],
      AppRole.tenant => const <DashboardMetric>[
        DashboardMetric(
          title: 'Due Amount',
          value: 'Rs 5,900',
          subtitle: 'Due in 7 days',
          tone: UiTone.warning,
        ),
        DashboardMetric(
          title: 'Security Alerts',
          value: '2',
          subtitle: '1 needs attention',
          tone: UiTone.brand,
        ),
        DashboardMetric(
          title: 'Open Tickets',
          value: '1',
          subtitle: 'Lift issue is in progress',
          tone: UiTone.neutral,
        ),
        DashboardMetric(
          title: 'Last Payment',
          value: 'Rs 5,310',
          subtitle: 'Recorded successfully',
          tone: UiTone.success,
        ),
      ],
      AppRole.pgResident => const <DashboardMetric>[
        DashboardMetric(
          title: 'Monthly Rent',
          value: 'Rs 8,500',
          subtitle: 'Shared room plan',
          tone: UiTone.brand,
        ),
        DashboardMetric(
          title: 'Amenities',
          value: '4',
          subtitle: 'Meals, Wi-Fi, AC, laundry',
          tone: UiTone.success,
        ),
        DashboardMetric(
          title: 'Visitors',
          value: '2',
          subtitle: 'This month',
          tone: UiTone.neutral,
        ),
        DashboardMetric(
          title: 'Outstanding',
          value: 'Rs 0',
          subtitle: 'No pending rent right now',
          tone: UiTone.success,
        ),
      ],
      AppRole.visitor => const <DashboardMetric>[
        DashboardMetric(
          title: 'Upcoming Visit',
          value: '1',
          subtitle: 'Scheduled for tomorrow',
          tone: UiTone.warning,
        ),
        DashboardMetric(
          title: 'Checked In',
          value: '1',
          subtitle: 'One active gate pass',
          tone: UiTone.brand,
        ),
        DashboardMetric(
          title: 'Past Visits',
          value: '4',
          subtitle: 'Recent visit history',
          tone: UiTone.neutral,
        ),
        DashboardMetric(
          title: 'Support',
          value: 'Ready',
          subtitle: 'Help desk one tap away',
          tone: UiTone.success,
        ),
      ],
      AppRole.blockSecretary => const <DashboardMetric>[
        DashboardMetric(
          title: 'Block Residents',
          value: '20',
          subtitle: 'Residents under Block A',
          tone: UiTone.brand,
        ),
        DashboardMetric(
          title: 'Block Issues',
          value: '6',
          subtitle: '2 need escalation',
          tone: UiTone.warning,
        ),
        DashboardMetric(
          title: 'Visitors Today',
          value: '5',
          subtitle: '1 visitor still inside',
          tone: UiTone.success,
        ),
        DashboardMetric(
          title: 'Cameras Online',
          value: '4/6',
          subtitle: '2 require maintenance',
          tone: UiTone.neutral,
        ),
      ],
    };
  }

  List<AppShortcut> shortcutsForRole(AppRole role) {
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

  List<BillRecord> billsForRole(AppRole role) {
    final List<BillRecord> managementBills = <BillRecord>[
      BillRecord(
        id: 'm1',
        title: 'Maintenance - A-101',
        unitLabel: 'A-101',
        amount: 5900,
        dueDate: DateTime(2026, 4, 8),
        status: BillStatus.pending,
        category: 'Maintenance',
        note: 'GST included',
      ),
      BillRecord(
        id: 'm2',
        title: 'Rental - A-101',
        unitLabel: 'A-101',
        amount: 25000,
        dueDate: DateTime(2026, 4, 5),
        status: BillStatus.paid,
        category: 'Rent',
        note: 'Paid via UPI',
      ),
      BillRecord(
        id: 'm3',
        title: 'Maintenance - C-301',
        unitLabel: 'C-301',
        amount: 7080,
        dueDate: DateTime(2026, 3, 29),
        status: BillStatus.overdue,
        category: 'Maintenance',
        note: 'Two reminder notices sent',
      ),
      BillRecord(
        id: 'm4',
        title: 'Rental - E-501',
        unitLabel: 'E-501',
        amount: 15000,
        dueDate: DateTime(2026, 4, 5),
        status: BillStatus.partial,
        category: 'Rent',
        note: 'Partial payment received',
      ),
    ];

    final List<BillRecord> residentBills = <BillRecord>[
      managementBills.first,
      managementBills[1],
    ];

    final List<BillRecord> pgBills = <BillRecord>[
      BillRecord(
        id: 'pg1',
        title: 'PG Rent - PG-101',
        unitLabel: 'PG-101',
        amount: 8500,
        dueDate: DateTime(2026, 4, 7),
        status: BillStatus.pending,
        category: 'PG Rent',
        note: 'Meals included',
      ),
      BillRecord(
        id: 'pg2',
        title: 'PG Deposit Balance',
        unitLabel: 'PG-101',
        amount: 0,
        dueDate: DateTime(2026, 4, 1),
        status: BillStatus.paid,
        category: 'Deposit',
        note: 'No pending deposit',
      ),
    ];

    return switch (role) {
      AppRole.societyManager ||
      AppRole.treasurer ||
      AppRole.president => managementBills,
      AppRole.propertyManager ||
      AppRole.owner ||
      AppRole.tenant ||
      AppRole.blockSecretary => residentBills,
      AppRole.pgResident => pgBills,
      AppRole.visitor => const <BillRecord>[],
    };
  }

  List<VisitorRecord> visitorsForRole(AppRole role) {
    if (role == AppRole.visitor) {
      return <VisitorRecord>[
        VisitorRecord(
          id: 'v1',
          name: 'Visit to John Smith',
          host: 'John Smith',
          unitLabel: 'A-101',
          purpose: 'Personal visit',
          time: DateTime(2026, 4, 1, 18, 0),
          status: VisitStatus.checkedIn,
          preApproved: true,
        ),
        VisitorRecord(
          id: 'v2',
          name: 'Visit to Sarah Johnson',
          host: 'Sarah Johnson',
          unitLabel: 'B-205',
          purpose: 'Business meeting',
          time: DateTime(2026, 4, 2, 11, 30),
          status: VisitStatus.scheduled,
          preApproved: true,
        ),
        VisitorRecord(
          id: 'v3',
          name: 'Visit to Raj Patel',
          host: 'Raj Patel',
          unitLabel: 'C-301',
          purpose: 'Delivery pickup',
          time: DateTime(2026, 3, 29, 16, 10),
          status: VisitStatus.checkedOut,
          preApproved: false,
        ),
      ];
    }

    if (role == AppRole.blockSecretary) {
      return <VisitorRecord>[
        VisitorRecord(
          id: 'b1',
          name: 'Rohit Sharma',
          host: 'A-101 Resident',
          unitLabel: 'A-101',
          purpose: 'Personal visit',
          time: DateTime(2026, 4, 1, 17, 45),
          status: VisitStatus.checkedIn,
          preApproved: true,
        ),
        VisitorRecord(
          id: 'b2',
          name: 'Delivery Person',
          host: 'A-205 Resident',
          unitLabel: 'A-205',
          purpose: 'Package delivery',
          time: DateTime(2026, 4, 1, 18, 5),
          status: VisitStatus.waiting,
          preApproved: false,
        ),
        VisitorRecord(
          id: 'b3',
          name: 'Maintenance Worker',
          host: 'A-301 Resident',
          unitLabel: 'A-301',
          purpose: 'AC repair',
          time: DateTime(2026, 4, 1, 14, 0),
          status: VisitStatus.checkedOut,
          preApproved: true,
        ),
      ];
    }

    return <VisitorRecord>[
      VisitorRecord(
        id: 'r1',
        name: 'Rohit Sharma',
        host: 'Approved by Sarah Johnson',
        unitLabel: 'A-101',
        purpose: 'Personal visit',
        time: DateTime(2026, 4, 1, 18, 0),
        status: VisitStatus.checkedIn,
        preApproved: true,
      ),
      VisitorRecord(
        id: 'r2',
        name: 'Delivery Person',
        host: 'Gate approval pending',
        unitLabel: 'B-205',
        purpose: 'Package delivery',
        time: DateTime(2026, 4, 1, 17, 20),
        status: VisitStatus.waiting,
        preApproved: false,
      ),
      VisitorRecord(
        id: 'r3',
        name: 'Guest User',
        host: 'Approved by Raj Patel',
        unitLabel: 'PG-101',
        purpose: 'Family visit',
        time: DateTime(2026, 3, 31, 20, 15),
        status: VisitStatus.checkedOut,
        preApproved: true,
      ),
    ];
  }

  List<TicketRecord> ticketsForRole(AppRole role) {
    final List<TicketRecord> allTickets = <TicketRecord>[
      TicketRecord(
        id: 't1',
        title: 'Lift not working in Block A',
        description: 'The lift has been out of order since yesterday morning.',
        status: TicketStatus.inProgress,
        priority: TicketPriority.high,
        category: 'maintenance',
        updatedAt: DateTime(2026, 4, 1, 16, 10),
        assignee: 'Maintenance Team',
      ),
      TicketRecord(
        id: 't2',
        title: 'Water leakage in parking area',
        description:
            'Continuous leakage near parking slot 15 is creating a slip risk.',
        status: TicketStatus.open,
        priority: TicketPriority.medium,
        category: 'maintenance',
        updatedAt: DateTime(2026, 4, 1, 12, 30),
      ),
      TicketRecord(
        id: 't3',
        title: 'Unauthorized parking complaint',
        description: 'Reserved slot A-15 was used by an unknown vehicle.',
        status: TicketStatus.resolved,
        priority: TicketPriority.low,
        category: 'security',
        updatedAt: DateTime(2026, 3, 31, 19, 0),
        assignee: 'Security Team',
      ),
    ];

    return switch (role) {
      AppRole.owner ||
      AppRole.tenant ||
      AppRole.pgResident ||
      AppRole.visitor => <TicketRecord>[allTickets.first],
      _ => allTickets,
    };
  }

  List<AnnouncementRecord> announcements() {
    return <AnnouncementRecord>[
      AnnouncementRecord(
        id: 'a1',
        title: 'Water supply maintenance',
        message:
            'Water supply will be interrupted tomorrow from 2 PM to 6 PM for pipeline work.',
        category: AnnouncementCategory.maintenance,
        createdAt: DateTime(2026, 4, 1, 15, 30),
        unread: true,
        priorityLabel: 'High',
      ),
      AnnouncementRecord(
        id: 'a2',
        title: 'Monthly society meeting',
        message:
            'The monthly society meeting is scheduled for Saturday at 6 PM in the community hall.',
        category: AnnouncementCategory.meeting,
        createdAt: DateTime(2026, 3, 31, 18, 0),
        unread: true,
        priorityLabel: 'Medium',
      ),
      AnnouncementRecord(
        id: 'a3',
        title: 'Festival celebration',
        message:
            'Join the Friday evening celebration in the courtyard. Potluck dinner begins at 7 PM.',
        category: AnnouncementCategory.social,
        createdAt: DateTime(2026, 3, 29, 10, 0),
        unread: false,
        priorityLabel: 'Low',
      ),
      AnnouncementRecord(
        id: 'a4',
        title: 'Payment reminder',
        message:
            'Residents with pending maintenance dues should complete payment before the 5th.',
        category: AnnouncementCategory.financial,
        createdAt: DateTime(2026, 4, 1, 9, 0),
        unread: true,
        priorityLabel: 'High',
      ),
    ];
  }

  List<ModuleStatusItem> moreModulesForRole(AppRole role) {
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
          title: 'Bookings',
          subtitle: 'Amenity booking entry point and current manual process',
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
          title: 'Bookings',
          subtitle: 'Amenity booking entry point and current manual process',
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
}
