import 'dart:async';

import 'package:razorpay_flutter/razorpay_flutter.dart';

class RazorpayCheckoutResult {
  const RazorpayCheckoutResult({
    required this.success,
    this.message,
    this.paymentId,
    this.orderId,
    this.signature,
    this.externalWallet,
  });

  const RazorpayCheckoutResult.success({
    this.paymentId,
    this.orderId,
    this.signature,
  })  : success = true,
        message = null,
        externalWallet = null;

  const RazorpayCheckoutResult.failure(String message)
      : success = false,
        message = message,
        paymentId = null,
        orderId = null,
        signature = null,
        externalWallet = null;

  const RazorpayCheckoutResult.externalWallet(String walletName)
      : success = true,
        message = 'External wallet selected: $walletName',
        paymentId = null,
        orderId = null,
        signature = null,
        externalWallet = walletName;

  final bool success;
  final String? message;
  final String? paymentId;
  final String? orderId;
  final String? signature;
  final String? externalWallet;
}

class RazorpayCheckoutService {
  RazorpayCheckoutService._();

  static Future<RazorpayCheckoutResult> openCheckout({
    required String keyId,
    required int amountInPaise,
    required String name,
    required String description,
    required String orderId,
    String currency = 'INR',
    String? prefillName,
    String? prefillEmail,
    String? prefillContact,
  }) async {
    if (keyId.isEmpty || orderId.isEmpty || amountInPaise <= 0) {
      throw Exception('Razorpay checkout data is incomplete.');
    }

    final Razorpay razorpay = Razorpay();
    final Completer<RazorpayCheckoutResult> completer =
        Completer<RazorpayCheckoutResult>();

    void complete(RazorpayCheckoutResult result) {
      if (!completer.isCompleted) {
        completer.complete(result);
      }
      razorpay.clear();
    }

    razorpay.on(
      Razorpay.EVENT_PAYMENT_SUCCESS,
      (PaymentSuccessResponse response) {
        complete(
          RazorpayCheckoutResult.success(
            paymentId: response.paymentId,
            orderId: response.orderId,
            signature: response.signature,
          ),
        );
      },
    );

    razorpay.on(
      Razorpay.EVENT_PAYMENT_ERROR,
      (PaymentFailureResponse response) {
        final String message = (response.message ?? '').trim().isEmpty
            ? 'Payment failed or was cancelled.'
            : response.message!.trim();
        complete(RazorpayCheckoutResult.failure(message));
      },
    );

    razorpay.on(
      Razorpay.EVENT_EXTERNAL_WALLET,
      (ExternalWalletResponse response) {},
    );

    final Map<String, dynamic> options = <String, dynamic>{
      'key': keyId,
      'amount': amountInPaise,
      'currency': currency,
      'name': name,
      'description': description,
      'order_id': orderId,
      'prefill': <String, dynamic>{
        'name': prefillName ?? '',
        'email': prefillEmail ?? '',
        'contact': prefillContact ?? '',
      },
      'theme': <String, dynamic>{
        'color': '#1DAEFF',
      },
    };

    try {
      razorpay.open(options);
    } catch (error) {
      razorpay.clear();
      throw Exception(
        error.toString().replaceFirst('Exception: ', ''),
      );
    }

    return completer.future.timeout(
      const Duration(minutes: 10),
      onTimeout: () {
        razorpay.clear();
        return const RazorpayCheckoutResult.failure(
          'Payment timed out. Please try again.',
        );
      },
    );
  }
}
