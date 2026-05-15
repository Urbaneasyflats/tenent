import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:in_app_update/in_app_update.dart';

class AppUpdateService {
  AppUpdateService._();

  static const Duration _updateCheckTimeout = Duration(seconds: 12);
  static bool _isChecking = false;

  static Future<void> checkForPlayStoreUpdate() async {
    if (!Platform.isAndroid || _isChecking) {
      _log(
        'skipped: platform=${Platform.operatingSystem}, checking=$_isChecking',
      );
      return;
    }

    _isChecking = true;
    try {
      final AppUpdateInfo updateInfo = await InAppUpdate.checkForUpdate()
          .timeout(
            _updateCheckTimeout,
            onTimeout: () {
              _log('check timed out after ${_updateCheckTimeout.inSeconds}s');
              throw TimeoutException('In-app update check timed out.');
            },
          );

      _log(
        'availability=${updateInfo.updateAvailability}, '
        'immediate=${updateInfo.immediateUpdateAllowed}, '
        'flexible=${updateInfo.flexibleUpdateAllowed}',
      );

      if (updateInfo.updateAvailability != UpdateAvailability.updateAvailable) {
        return;
      }

      if (updateInfo.immediateUpdateAllowed) {
        final AppUpdateResult result =
            await InAppUpdate.performImmediateUpdate();
        _log('immediate result: $result');
        return;
      }

      if (updateInfo.flexibleUpdateAllowed) {
        final AppUpdateResult result = await InAppUpdate.startFlexibleUpdate();
        _log('flexible start result: $result');
        if (result == AppUpdateResult.success) {
          await InAppUpdate.completeFlexibleUpdate();
          _log('flexible update completion requested');
        }
      }
    } on TimeoutException {
      // Startup must never hang because of an update check.
    } catch (error) {
      _log('failed: $error');
      // In-app update checks fail on debug builds, sideloaded APKs, devices
      // without Play Store, and when no Play release is available. Ignore so
      // app startup is never blocked.
    } finally {
      _isChecking = false;
    }
  }

  static void _log(String message) {
    if (kDebugMode) {
      debugPrint('[Update] $message');
    }
  }
}
