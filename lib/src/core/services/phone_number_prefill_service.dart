import 'dart:io';

import 'package:mobile_number/mobile_number.dart';

class PhoneNumberPrefillService {
  PhoneNumberPrefillService._();

  static Future<String?> detectIndianMobileNumber() async {
    if (!Platform.isAndroid) {
      return null;
    }

    try {
      bool hasPermission = await MobileNumber.hasPhonePermission;
      if (!hasPermission) {
        await MobileNumber.requestPhonePermission;
        await Future<void>.delayed(const Duration(milliseconds: 450));
        hasPermission = await MobileNumber.hasPhonePermission;
      }

      if (!hasPermission) {
        return null;
      }

      final Future<String>? primaryNumberFuture = MobileNumber.mobileNumber;
      final String? primaryNumber =
          primaryNumberFuture == null ? null : await primaryNumberFuture;
      final String? normalizedPrimary = _normalizeIndianPhone(primaryNumber);
      if (normalizedPrimary != null) {
        return normalizedPrimary;
      }

      final Future<List<SimCard>>? simCardsFuture = MobileNumber.getSimCards;
      final List<SimCard>? simCards =
          simCardsFuture == null ? null : await simCardsFuture;
      if (simCards == null || simCards.isEmpty) {
        return null;
      }

      for (final SimCard simCard in simCards) {
        final String? normalized = _normalizeIndianPhone(simCard.number);
        if (normalized != null) {
          return normalized;
        }
      }
    } catch (_) {
      return null;
    }

    return null;
  }

  static String? _normalizeIndianPhone(String? value) {
    if (value == null || value.trim().isEmpty) {
      return null;
    }

    final String digits = value.replaceAll(RegExp(r'\D'), '');
    if (digits.length < 10) {
      return null;
    }

    final String normalized = digits.substring(digits.length - 10);
    if (RegExp(r'^[6-9]\d{9}$').hasMatch(normalized)) {
      return normalized;
    }
    return null;
  }
}
