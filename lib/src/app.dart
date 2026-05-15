import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';

import 'core/api/api_client.dart';
import 'core/api/auth_service.dart';
import 'core/api/auth_storage.dart';
import 'core/api/vendor_service.dart';
import 'core/models/app_models.dart';
import 'core/services/app_update_service.dart';
import 'core/services/connectivity_service.dart';
import 'core/services/notification_analytics.dart';
import 'core/services/push_notification_service.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/login_page.dart';
import 'features/auth/otp_page.dart';
import 'features/auth/profile_setup_page.dart';
import 'features/bookings/property_bookings_page.dart';
import 'features/discovery/find_property_page.dart';
import 'features/notifications/notifications_page.dart';
import 'features/properties/property_enquiries_page.dart';
import 'features/shell/app_shell.dart';
import 'features/splash/startup_splash_page.dart';

class ResidentApp extends StatefulWidget {
  const ResidentApp({super.key});

  /// Global navigator key — used by PushNotificationService to open
  /// NotificationsPage when the user taps a push notification.
  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();

  @override
  State<ResidentApp> createState() => _ResidentAppState();
}

class _ResidentAppState extends State<ResidentApp> with WidgetsBindingObserver {
  bool _isInitializing = true;
  bool _isAuthenticated = false;
  bool _needsProfileSetup = false;
  bool _showLogin = false;
  String? _phoneNumber;
  AppRole _currentRole = AppRole.tenant;
  StartupStep _startupStep = StartupStep.initializing;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initApp();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && _isAuthenticated) {
      unawaited(PushNotificationService.syncToken());
    }
  }

  Future<void> _initApp() async {
    setState(() {
      _isInitializing = true;
      _startupStep = StartupStep.initializing;
    });

    ApiClient.instance.onSessionExpired = _logout;

    try {
      _setStartupStep(StartupStep.checkingInternet);
      await AuthService.ensureStorageInitialized();
      await ConnectivityService.instance.initialize().timeout(
            const Duration(seconds: 5),
            onTimeout: () => null,
          );

      final bool loggedIn = AuthStorage.isLoggedIn;
      final bool online = ConnectivityService.instance.isOnline;

      if (!online) {
        if (loggedIn) {
          final AppRole role = await _resolveRole();
          if (!mounted) return;
          setState(() {
            _currentRole = role;
            _isAuthenticated = true;
            _isInitializing = false;
            _startupStep = StartupStep.ready;
          });
          _startBackgroundServices();
          return;
        }
        if (!mounted) return;
        setState(() {
          _startupStep = StartupStep.noInternet;
        });
        return;
      }

      if (AuthStorage.deviceId == null || AuthStorage.deviceId!.isEmpty) {
        _setStartupStep(StartupStep.requestingDeviceId);
        final String? deviceId = await AuthService.generateDeviceId();
        if (deviceId == null || deviceId.isEmpty) {
          throw StateError('Device setup failed.');
        }
      }

      if (AuthStorage.apiKey == null || AuthStorage.apiKey!.isEmpty) {
        _setStartupStep(StartupStep.fetchingVendorConfig);
        final String? apiKey =
            await AuthService.getApiKey(AuthStorage.deviceId ?? '');
        if (apiKey == null || apiKey.isEmpty) {
          throw StateError('App setup failed.');
        }
      }

      _setStartupStep(StartupStep.authenticatingUser);

      if (AuthStorage.isLoggedIn) {
        final AppRole role = await _resolveRole();

        if (!mounted) return;

        setState(() {
          _currentRole = role;
          _isAuthenticated = true;
          _isInitializing = false;
          _startupStep = StartupStep.ready;
        });
      } else {
        setState(() {
          _isInitializing = false;
          _startupStep = StartupStep.ready;
        });
      }

      _startBackgroundServices();
    } on TimeoutException {
      if (!mounted) return;
      setState(() {
        _startupStep = StartupStep.timeout;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _startupStep = StartupStep.failed;
      });
    }
  }

  void _setStartupStep(StartupStep step) {
    if (!mounted) return;
    setState(() {
      _startupStep = step;
    });
  }

  void _startBackgroundServices() {
    final Future<void> updateCheck = AppUpdateService.checkForPlayStoreUpdate();
    PushNotificationService.initialize(
      onNotificationTap: _handleNotificationTap,
    ).catchError((_) {});
    unawaited(updateCheck);
  }

  void _handleNotificationTap(String? payload) {
    if (!_isAuthenticated) return;
    ResidentApp.navigatorKey.currentState?.push(
      MaterialPageRoute<void>(
        builder: (_) => _pageForNotificationPayload(payload),
      ),
    );
  }

  Widget _pageForNotificationPayload(String? payload) {
    if (payload == null || payload.trim().isEmpty) {
      return const NotificationsPage();
    }
    try {
      final Object? decoded = jsonDecode(payload);
      if (decoded is! Map<String, dynamic>) {
        unawaited(
          NotificationAnalytics.track('notification_deep_link_failed'),
        );
        return const NotificationsPage();
      }
      final String screen = '${decoded['screen'] ?? ''}'.trim();
      return switch (screen) {
        'property_enquiry_detail' => const PropertyEnquiriesPage(),
        'booking_detail' ||
        'tenant_booking_detail' =>
          const PropertyBookingsPage(),
        'announcement_detail' => const NotificationsPage(),
        'support_ticket_detail' => const NotificationsPage(),
        'bill_detail' || 'payment_history' => const NotificationsPage(),
        'agreement_detail' => const NotificationsPage(),
        'wallet_detail' || 'settings' => const NotificationsPage(),
        _ => const NotificationsPage(),
      };
    } catch (_) {
      unawaited(
        NotificationAnalytics.track('notification_deep_link_failed'),
      );
      return const NotificationsPage();
    }
  }

  Future<AppRole> _resolveRole() async {
    int? vendorType = AuthStorage.vendorType;

    if (vendorType == null && AuthStorage.isLoggedIn) {
      try {
        final vendor = await VendorService.fetchVendorInfo();
        if (vendor != null && vendor.vendorType != 0) {
          vendorType = vendor.vendorType;
          await AuthStorage.setVendorType(vendor.vendorType);
        }
      } on TimeoutException {
        vendorType = AuthStorage.vendorType;
      } catch (_) {
        vendorType = AuthStorage.vendorType;
      }
    }

    return roleFromVendorType(vendorType);
  }

  void _onOtpRequested(String phone) {
    setState(() {
      _phoneNumber = phone;
    });
  }

  Future<void> _onOtpVerified(bool needsProfile) async {
    if (needsProfile) {
      setState(() {
        _needsProfileSetup = true;
      });
      return;
    }
    await _completeAuthentication();
  }

  Future<void> _onProfileCompleted() async {
    await _completeAuthentication();
  }

  void _cancelProfileSetup() {
    AuthService.logout();
    setState(() {
      _needsProfileSetup = false;
      _phoneNumber = null;
      _showLogin = false;
    });
  }

  Future<void> _completeAuthentication() async {
    setState(() {
      _isInitializing = true;
    });

    final AppRole role = await _resolveRole();

    if (!mounted) return;

    setState(() {
      _currentRole = role;
      _isAuthenticated = true;
      _isInitializing = false;
      _needsProfileSetup = false;
      _phoneNumber = null;
      _showLogin = false;
    });
    unawaited(PushNotificationService.syncToken());
  }

  void _logout() {
    AuthService.logout();
    if (!mounted) return;
    setState(() {
      _isAuthenticated = false;
      _phoneNumber = null;
      _needsProfileSetup = false;
      _showLogin = false;
      _currentRole = AppRole.tenant;
    });
  }

  Widget _buildHome() {
    if (_isInitializing) {
      return StartupSplashPage(step: _startupStep, onRetry: _initApp);
    }

    if (_isAuthenticated) {
      return AppShell(role: _currentRole, onLogout: _logout);
    }

    if (_needsProfileSetup) {
      return ProfileSetupPage(
        onCompleted: _onProfileCompleted,
        onBack: _cancelProfileSetup,
      );
    }

    if (_phoneNumber == null) {
      if (!_showLogin) {
        return FindPropertyPage(
          onLoginPressed: () {
            setState(() {
              _showLogin = true;
            });
          },
        );
      }

      return LoginPage(
        authSource: AuthSource.tenant,
        onOtpRequested: _onOtpRequested,
        onBack: () {
          setState(() {
            _showLogin = false;
          });
        },
      );
    }

    return OtpPage(
      phoneNumber: _phoneNumber!,
      authSource: AuthSource.tenant,
      onBack: () {
        setState(() {
          _phoneNumber = null;
        });
      },
      onVerified: _onOtpVerified,
    );
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'resident app',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      navigatorKey: ResidentApp.navigatorKey,
      home: _buildHome(),
    );
  }
}
