import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';

/// Lightweight connectivity monitor.
///
/// Call [ConnectivityService.initialize] once at app startup.
/// Widgets can listen to [isOnline] or use [addListener]/[removeListener].
class ConnectivityService extends ChangeNotifier {
  ConnectivityService._();

  static final ConnectivityService instance = ConnectivityService._();

  bool _isOnline = true;
  bool get isOnline => _isOnline;

  StreamSubscription<List<ConnectivityResult>>? _subscription;

  /// Start monitoring connectivity changes. Safe to call multiple times.
  Future<void> initialize() async {
    // Check current state.
    final List<ConnectivityResult> current =
        await Connectivity().checkConnectivity();
    _update(current);

    // Listen for future changes.
    _subscription?.cancel();
    _subscription =
        Connectivity().onConnectivityChanged.listen(_update);
  }

  void _update(List<ConnectivityResult> results) {
    final bool online = results.isNotEmpty &&
        !results.every(
            (ConnectivityResult r) => r == ConnectivityResult.none);

    if (online != _isOnline) {
      _isOnline = online;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
