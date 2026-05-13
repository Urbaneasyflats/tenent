import 'dart:async';

import 'package:flutter/material.dart';

import 'core/api/api_client.dart';
import 'core/api/auth_service.dart';
import 'core/api/auth_storage.dart';
import 'core/api/vendor_service.dart';
import 'core/models/app_models.dart';
import 'core/services/app_update_service.dart';
import 'core/services/connectivity_service.dart';
import 'core/services/push_notification_service.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/login_page.dart';
import 'features/auth/otp_page.dart';
import 'features/auth/profile_setup_page.dart';
import 'features/discovery/find_property_page.dart';
import 'features/notifications/notifications_page.dart';
import 'features/shell/app_shell.dart';

class ResidentApp extends StatefulWidget {
  const ResidentApp({super.key});

  /// Global navigator key — used by PushNotificationService to open
  /// NotificationsPage when the user taps a push notification.
  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();

  @override
  State<ResidentApp> createState() => _ResidentAppState();
}

class _ResidentAppState extends State<ResidentApp> {
  bool _isInitializing = true;
  bool _isAuthenticated = false;
  bool _needsProfileSetup = false;
  bool _showLogin = false;
  String? _phoneNumber;
  AppRole _currentRole = AppRole.tenant;

  @override
  void initState() {
    super.initState();
    _initApp();
  }

  Future<void> _initApp() async {
    ApiClient.instance.onSessionExpired = _logout;

    // Start connectivity monitoring.
    ConnectivityService.instance.initialize().catchError((_) {});

    await AuthService.initializeApp();

    if (!mounted) return;

    if (AuthStorage.isLoggedIn) {
      final AppRole role = await _resolveRole();

      if (!mounted) return;

      setState(() {
        _currentRole = role;
        _isAuthenticated = true;
        _isInitializing = false;
      });
    } else {
      setState(() {
        _isInitializing = false;
      });
    }

    // Initialize push notifications after auth state is resolved.
    PushNotificationService.initialize(
      onNotificationTap: _handleNotificationTap,
    ).catchError((_) {});

    unawaited(AppUpdateService.checkForPlayStoreUpdate());
  }

  void _handleNotificationTap() {
    if (!_isAuthenticated) return;
    ResidentApp.navigatorKey.currentState?.push(
      MaterialPageRoute<void>(builder: (_) => const NotificationsPage()),
    );
  }

  Future<AppRole> _resolveRole() async {
    int? vendorType = AuthStorage.vendorType;

    if (vendorType == null && AuthStorage.isLoggedIn) {
      final vendor = await VendorService.fetchVendorInfo();
      if (vendor != null && vendor.vendorType != 0) {
        vendorType = vendor.vendorType;
        await AuthStorage.setVendorType(vendor.vendorType);
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
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
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
      home: AnimatedSwitcher(
        duration: const Duration(milliseconds: 220),
        child: KeyedSubtree(
          key: ValueKey<String>(
            '${_isInitializing}_${_isAuthenticated}_${_needsProfileSetup}_${_phoneNumber != null}_$_showLogin',
          ),
          child: _buildHome(),
        ),
      ),
    );
  }
}
