import 'dart:async';

import 'package:flutter/material.dart';

import 'core/api/api_client.dart';
import 'core/api/auth_service.dart';
import 'core/api/auth_storage.dart';
import 'core/api/vendor_service.dart';
import 'core/models/app_models.dart';
import 'core/services/app_update_service.dart';
import 'core/services/connectivity_service.dart';
import 'core/services/notification_tap_router.dart';
import 'core/services/push_notification_service.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/login_page.dart';
import 'features/auth/blocked_account_page.dart';
import 'features/auth/otp_page.dart';
import 'features/auth/profile_setup_page.dart';
import 'features/discovery/find_property_page.dart';
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
  bool _isAccountBlocked = false;
  String? _accountBlockReason;
  bool _needsProfileSetup = false;
  bool _showLogin = false;
  String? _phoneNumber;
  AppRole _currentRole = AppRole.tenant;
  StartupStep _startupStep = StartupStep.initializing;
  String? _pendingNotificationPayload;
  bool _isOpeningPendingNotification = false;

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
        _isAccountBlocked = AuthStorage.whetherAccountBlockedByAdmin;
        _accountBlockReason = AuthStorage.accountBlockReason;
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
          _isAccountBlocked = AuthStorage.whetherAccountBlockedByAdmin;
          _accountBlockReason = AuthStorage.accountBlockReason;
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
      _flushPendingNotificationTap();
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
    if (payload == null || payload.trim().isEmpty) {
      return;
    }

    if (!_isAuthenticated || ResidentApp.navigatorKey.currentState == null) {
      _pendingNotificationPayload = payload;
      _flushPendingNotificationTap();
      return;
    }

    ResidentApp.navigatorKey.currentState?.push(
      MaterialPageRoute<void>(
        builder: (_) => NotificationTapRouter.buildPage(
          role: _currentRole,
          payload: payload,
        ),
      ),
    );
  }

  void _flushPendingNotificationTap() {
    if (_isOpeningPendingNotification) {
      return;
    }
    if (!_isAuthenticated || _pendingNotificationPayload == null) {
      return;
    }
    if (ResidentApp.navigatorKey.currentState == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _flushPendingNotificationTap();
        }
      });
      return;
    }

    _isOpeningPendingNotification = true;
    final String payload = _pendingNotificationPayload!;
    _pendingNotificationPayload = null;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        _isOpeningPendingNotification = false;
        return;
      }

      ResidentApp.navigatorKey.currentState?.push(
        MaterialPageRoute<void>(
          builder: (_) => NotificationTapRouter.buildPage(
            role: _currentRole,
            payload: payload,
          ),
        ),
      );
      _isOpeningPendingNotification = false;
    });
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
    if (AuthStorage.whetherAccountBlockedByAdmin) {
      await _completeAuthentication();
      return;
    }

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
      _isAccountBlocked = AuthStorage.whetherAccountBlockedByAdmin;
      _accountBlockReason = AuthStorage.accountBlockReason;
      _isInitializing = false;
      _needsProfileSetup = false;
      _phoneNumber = null;
      _showLogin = false;
    });
    unawaited(PushNotificationService.syncToken());
    _flushPendingNotificationTap();
  }

  void _logout() {
    AuthService.logout();
    if (!mounted) return;
    setState(() {
      _isAuthenticated = false;
      _isAccountBlocked = false;
      _accountBlockReason = null;
      _phoneNumber = null;
      _needsProfileSetup = false;
      _showLogin = false;
      _currentRole = AppRole.tenant;
    });
    _pendingNotificationPayload = null;
  }

  Widget _buildHome() {
    if (_isInitializing) {
      return StartupSplashPage(step: _startupStep, onRetry: _initApp);
    }

    if (_isAccountBlocked) {
      return BlockedAccountPage(
        reason: _accountBlockReason,
        onLogout: _logout,
      );
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
