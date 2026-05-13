import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:in_app_update/in_app_update.dart';

class AppUpdateService {
  AppUpdateService._();

  static bool _isChecking = false;

  static Future<void> checkForPlayStoreUpdate() async {
    if (!Platform.isAndroid || !kReleaseMode || _isChecking) {
      return;
    }

    _isChecking = true;
    try {
      final AppUpdateInfo updateInfo = await InAppUpdate.checkForUpdate();
      if (updateInfo.updateAvailability !=
          UpdateAvailability.updateAvailable) {
        return;
      }

      if (updateInfo.immediateUpdateAllowed) {
        await InAppUpdate.performImmediateUpdate();
        return;
      }

      if (updateInfo.flexibleUpdateAllowed) {
        final AppUpdateResult result = await InAppUpdate.startFlexibleUpdate();
        if (result == AppUpdateResult.success) {
          await InAppUpdate.completeFlexibleUpdate();
        }
      }
    } catch (_) {
      // In-app update checks fail on debug builds, sideloaded APKs, devices
      // without Play Store, and when no Play release is available. Ignore so
      // app startup is never blocked.
    } finally {
      _isChecking = false;
    }
  }
}
