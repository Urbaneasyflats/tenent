import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sms_autofill/sms_autofill.dart';

import '../../core/api/auth_service.dart';
import '../../core/models/app_models.dart';
import '../legal/legal_policy_page.dart';

class OtpPage extends StatefulWidget {
  const OtpPage({
    super.key,
    required this.phoneNumber,
    required this.authSource,
    required this.onBack,
    required this.onVerified,
  });

  final String phoneNumber;
  final AuthSource authSource;
  final VoidCallback onBack;
  final ValueChanged<bool> onVerified;

  @override
  State<OtpPage> createState() => _OtpPageState();
}

class _OtpPageState extends State<OtpPage> with CodeAutoFill {
  static const int _otpLength = 4;

  final TextEditingController _otpController = TextEditingController();
  final FocusNode _otpFocusNode = FocusNode();
  bool _isLoading = false;
  bool _isResending = false;
  String? _errorMessage;
  int _resendCountdown = 30;
  Timer? _resendTimer;
  Timer? _autoSubmitTimer;

  bool get _canVerify =>
      _normalizeOtp(_otpController.text).length == _otpLength &&
      !_isLoading &&
      !_isResending;

  @override
  void initState() {
    super.initState();
    _otpController.addListener(_handleOtpChanged);
    _otpFocusNode.addListener(_handleFocusChanged);
    _startResendTimer();
    listenForCode();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _otpFocusNode.requestFocus();
      }
    });
  }

  @override
  void dispose() {
    _otpController.removeListener(_handleOtpChanged);
    _otpFocusNode.removeListener(_handleFocusChanged);
    _otpController.dispose();
    _otpFocusNode.dispose();
    _resendTimer?.cancel();
    _autoSubmitTimer?.cancel();
    cancel();
    super.dispose();
  }

  @override
  void codeUpdated() {
    final String? incomingCode = code;
    if (incomingCode == null || incomingCode.isEmpty) {
      return;
    }
    _otpController.text = _normalizeOtp(incomingCode);
    _queueAutoSubmit();
  }

  void _handleOtpChanged() {
    final String otp = _normalizeOtp(_otpController.text);
    if (_otpController.text != otp) {
      _otpController.value = TextEditingValue(
        text: otp,
        selection: TextSelection.collapsed(offset: otp.length),
      );
      return;
    }
    if (mounted) {
      setState(() {
        if (_errorMessage != null && otp.length == _otpLength) {
          _errorMessage = null;
        }
      });
    }
    if (otp.length == _otpLength) {
      _queueAutoSubmit();
    } else {
      _autoSubmitTimer?.cancel();
    }
  }

  void _handleFocusChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  void _startResendTimer() {
    _resendTimer?.cancel();
    setState(() {
      _resendCountdown = 30;
    });
    _resendTimer = Timer.periodic(const Duration(seconds: 1), (Timer timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() {
        _resendCountdown--;
      });
      if (_resendCountdown <= 0) {
        timer.cancel();
      }
    });
  }

  Future<void> _verifyOtp() async {
    final String otp = _normalizeOtp(_otpController.text);
    if (otp.length != _otpLength) {
      setState(() {
        _errorMessage = 'Enter the 4-digit verification code.';
      });
      _otpFocusNode.requestFocus();
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final response = await AuthService.validateOtp(
        widget.phoneNumber,
        otp,
        vendorType: widget.authSource.vendorType,
      );

      if (!mounted) {
        return;
      }

      if (response.success) {
        final Map<String, dynamic>? data =
            response.data as Map<String, dynamic>?;
        final bool hasBasicInformation = _readBackendBool(
          data?['Whether_Basic_Information_Available'] ??
              data?['whether_basic_information_available'] ??
              data?['WhetherBasicInformationAvailable'],
          fallback: false,
        );

        setState(() {
          _isLoading = false;
        });
        widget.onVerified(!hasBasicInformation);
      } else {
        setState(() {
          _isLoading = false;
          _errorMessage = response.message ?? response.status ?? 'Invalid OTP';
        });
      }
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _isLoading = false;
        _errorMessage = AuthService.offlineMessage;
      });
    }
  }

  void _queueAutoSubmit() {
    if (_isLoading || _isResending) {
      return;
    }
    _autoSubmitTimer?.cancel();
    _autoSubmitTimer = Timer(const Duration(milliseconds: 350), () {
      if (!mounted || !_canVerify) {
        return;
      }
      _verifyOtp();
    });
  }

  Future<void> _resendOtp() async {
    if (_isResending || _resendCountdown > 0) {
      return;
    }

    setState(() {
      _isResending = true;
      _errorMessage = null;
    });

    try {
      final response = await AuthService.generateOtp(
        widget.phoneNumber,
        vendorType: widget.authSource.vendorType,
      );

      if (!mounted) {
        return;
      }

      if (response.success) {
        _otpController.clear();
        _autoSubmitTimer?.cancel();
        listenForCode();
        setState(() {
          _isResending = false;
          _errorMessage = 'OTP sent again successfully.';
        });
        _otpFocusNode.requestFocus();
        _startResendTimer();
      } else {
        setState(() {
          _isResending = false;
          _errorMessage =
              response.message ?? response.status ?? 'Failed to resend OTP';
        });
      }
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _isResending = false;
        _errorMessage = AuthService.offlineMessage;
      });
    }
  }

  String _normalizeOtp(String value) {
    final String digits = value.replaceAll(RegExp(r'\D'), '');
    return digits.length > _otpLength
        ? digits.substring(0, _otpLength)
        : digits;
  }

  String _maskedPhone() {
    final String digits = widget.phoneNumber.replaceAll(RegExp(r'\D'), '');
    if (digits.length < 4) {
      return '+91 ${widget.phoneNumber}';
    }
    final String start = digits.length >= 2 ? digits.substring(0, 2) : digits;
    final String end = digits.substring(digits.length - 2);
    return '+91 ${start}XXXXXX$end';
  }

  bool _readBackendBool(dynamic value, {required bool fallback}) {
    if (value is bool) {
      return value;
    }
    if (value is num) {
      return value != 0;
    }
    if (value is String) {
      final String normalized = value.trim().toLowerCase();
      if (normalized == 'true' || normalized == '1' || normalized == 'yes') {
        return true;
      }
      if (normalized == 'false' || normalized == '0' || normalized == 'no') {
        return false;
      }
    }
    return fallback;
  }

  void _openPolicy(BuildContext context, LegalPolicyType type) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => LegalPolicyPage(type: type)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final String otp = _normalizeOtp(_otpController.text);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      resizeToAvoidBottomInset: false,
      body: SafeArea(
        child: Stack(
          children: <Widget>[
            Positioned(
              left: 14,
              top: 8,
              child: _CircleBackButton(onPressed: widget.onBack),
            ),
            Center(
              child: SingleChildScrollView(
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                padding: const EdgeInsets.fromLTRB(22, 24, 22, 22),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 430),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: <Widget>[
                      const SizedBox(height: 18),
                      const _TenantLogo(),
                      const SizedBox(height: 28),
                      Text(
                        'Verify your number',
                        textAlign: TextAlign.center,
                        style: theme.textTheme.headlineMedium?.copyWith(
                          color: const Color(0xFF111827),
                          fontSize: 32,
                          height: 1.08,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Enter the 4-digit code sent to your phone number.',
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: const Color(0xFF64748B),
                          fontSize: 15.5,
                          height: 1.45,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 12),
                      _MaskedPhoneNumber(
                        text: _maskedPhone(),
                        onEdit: widget.onBack,
                      ),
                      const SizedBox(height: 32),
                      _OtpInput(
                        controller: _otpController,
                        focusNode: _otpFocusNode,
                        otp: otp,
                        length: _otpLength,
                      ),
                      if (_errorMessage != null) ...<Widget>[
                        const SizedBox(height: 14),
                        _ErrorMessage(text: _errorMessage!),
                      ],
                      const SizedBox(height: 24),
                      _ResendSection(
                        countdown: _resendCountdown,
                        isResending: _isResending,
                        onResend: _resendOtp,
                      ),
                      const SizedBox(height: 20),
                      _VerifyButton(
                        enabled: _canVerify,
                        isLoading: _isLoading,
                        onPressed: _verifyOtp,
                      ),
                      const SizedBox(height: 18),
                      const _SecurityNote(),
                      const SizedBox(height: 28),
                      const Divider(height: 1, color: Color(0xFFE2E8F0)),
                      const SizedBox(height: 16),
                      _TermsText(
                        onTermsTap: () =>
                            _openPolicy(context, LegalPolicyType.terms),
                        onPrivacyTap: () =>
                            _openPolicy(context, LegalPolicyType.privacy),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CircleBackButton extends StatelessWidget {
  const _CircleBackButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      shape: const CircleBorder(),
      elevation: 4,
      shadowColor: Colors.black.withValues(alpha: 0.08),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onPressed,
        child: const SizedBox(
          width: 42,
          height: 42,
          child: Icon(
            Icons.arrow_back_ios_new_rounded,
            color: Color(0xFF111827),
            size: 18,
          ),
        ),
      ),
    );
  }
}

class _TenantLogo extends StatelessWidget {
  const _TenantLogo();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 86,
        height: 86,
        padding: const EdgeInsets.all(9),
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          boxShadow: <BoxShadow>[
            BoxShadow(
              color: const Color(0xFF0284C7).withValues(alpha: 0.12),
              blurRadius: 28,
              offset: const Offset(0, 14),
            ),
          ],
        ),
        child: ClipOval(
          child: Image.asset(
            'assets/tenenet_logo.jpg',
            fit: BoxFit.cover,
          ),
        ),
      ),
    );
  }
}

class _MaskedPhoneNumber extends StatelessWidget {
  const _MaskedPhoneNumber({
    required this.text,
    required this.onEdit,
  });

  final String text;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: InkWell(
        onTap: onEdit,
        borderRadius: BorderRadius.circular(999),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Text(
                text,
                style: const TextStyle(
                  color: Color(0xFF111827),
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(width: 8),
              const Icon(
                Icons.edit_rounded,
                color: Color(0xFF0284C7),
                size: 16,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OtpInput extends StatelessWidget {
  const _OtpInput({
    required this.controller,
    required this.focusNode,
    required this.otp,
    required this.length,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final String otp;
  final int length;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: <Widget>[
        Positioned.fill(
          child: Opacity(
            opacity: 0.01,
            child: TextField(
              controller: controller,
              focusNode: focusNode,
              autofocus: true,
              keyboardType: TextInputType.number,
              textInputAction: TextInputAction.done,
              inputFormatters: <TextInputFormatter>[
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(length),
              ],
              autofillHints: const <String>[AutofillHints.oneTimeCode],
            ),
          ),
        ),
        Row(
          children: List<Widget>.generate(length, (int index) {
            final bool hasValue = index < otp.length;
            final bool active = focusNode.hasFocus &&
                (index == otp.length || index == length - 1);
            return Expanded(
              child: GestureDetector(
                onTap: focusNode.requestFocus,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 160),
                  curve: Curves.easeOut,
                  height: 54,
                  margin: EdgeInsets.only(right: index == length - 1 ? 0 : 7),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: active || hasValue
                          ? const Color(0xFF38BDF8)
                          : const Color(0xFFE2E8F0),
                      width: active || hasValue ? 1.7 : 1,
                    ),
                    boxShadow: active
                        ? <BoxShadow>[
                            BoxShadow(
                              color: const Color(0xFF38BDF8)
                                  .withValues(alpha: 0.18),
                              blurRadius: 18,
                              offset: const Offset(0, 8),
                            ),
                          ]
                        : const <BoxShadow>[],
                  ),
                  child: Text(
                    hasValue ? otp[index] : '',
                    style: const TextStyle(
                      color: Color(0xFF111827),
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ),
            );
          }),
        ),
      ],
    );
  }
}

class _ResendSection extends StatelessWidget {
  const _ResendSection({
    required this.countdown,
    required this.isResending,
    required this.onResend,
  });

  final int countdown;
  final bool isResending;
  final VoidCallback onResend;

  @override
  Widget build(BuildContext context) {
    final bool waiting = countdown > 0;
    final String countdownText =
        '00:${countdown.clamp(0, 59).toString().padLeft(2, '0')}';

    return Column(
      children: <Widget>[
        Text(
          waiting ? 'Resend code in $countdownText' : 'Code can be resent now',
          style: const TextStyle(
            color: Color(0xFF64748B),
            fontSize: 13,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          alignment: WrapAlignment.center,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: <Widget>[
            const Text(
              "Didn't receive the code? ",
              style: TextStyle(
                color: Color(0xFF64748B),
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
            InkWell(
              onTap: waiting || isResending ? null : onResend,
              borderRadius: BorderRadius.circular(4),
              child: Text(
                isResending ? 'Sending...' : 'Resend',
                style: TextStyle(
                  color: waiting
                      ? const Color(0xFF94A3B8)
                      : const Color(0xFF0284C7),
                  fontSize: 13,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _VerifyButton extends StatelessWidget {
  const _VerifyButton({
    required this.enabled,
    required this.isLoading,
    required this.onPressed,
  });

  final bool enabled;
  final bool isLoading;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return AnimatedScale(
      scale: enabled ? 1 : 0.99,
      duration: const Duration(milliseconds: 130),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(22),
        child: InkWell(
          onTap: enabled ? onPressed : null,
          borderRadius: BorderRadius.circular(22),
          child: Ink(
            height: 60,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(22),
              gradient: LinearGradient(
                colors: enabled
                    ? const <Color>[Color(0xFF38BDF8), Color(0xFF0284C7)]
                    : const <Color>[Color(0xFFBAE6FD), Color(0xFF7DD3FC)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: enabled
                  ? <BoxShadow>[
                      BoxShadow(
                        color: const Color(0xFF0284C7).withValues(alpha: 0.24),
                        blurRadius: 24,
                        offset: const Offset(0, 12),
                      ),
                    ]
                  : const <BoxShadow>[],
            ),
            child: Center(
              child: isLoading
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2.4,
                      ),
                    )
                  : const Text(
                      'Verify OTP',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SecurityNote extends StatelessWidget {
  const _SecurityNote();

  @override
  Widget build(BuildContext context) {
    return const Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        Icon(Icons.verified_user_outlined, color: Color(0xFF0284C7), size: 18),
        SizedBox(width: 7),
        Flexible(
          child: Text(
            'Your phone number is securely verified.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Color(0xFF64748B),
              fontSize: 12.5,
              height: 1.35,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}

class _ErrorMessage extends StatelessWidget {
  const _ErrorMessage({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF1F2),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFFFCDD2)),
      ),
      child: Row(
        children: <Widget>[
          const Icon(Icons.error_outline_rounded, color: Color(0xFFE11D48)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                color: Color(0xFF9F1239),
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TermsText extends StatelessWidget {
  const _TermsText({
    required this.onTermsTap,
    required this.onPrivacyTap,
  });

  final VoidCallback onTermsTap;
  final VoidCallback onPrivacyTap;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      alignment: WrapAlignment.center,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: <Widget>[
        const Text(
          'By continuing, you agree to our ',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Color(0xFF64748B),
            fontSize: 12.5,
            height: 1.5,
            fontWeight: FontWeight.w600,
          ),
        ),
        _PolicyLink(text: 'Terms of Service', onTap: onTermsTap),
        const Text(
          ' and ',
          style: TextStyle(
            color: Color(0xFF64748B),
            fontSize: 12.5,
            height: 1.5,
            fontWeight: FontWeight.w600,
          ),
        ),
        _PolicyLink(text: 'Privacy Policy', onTap: onPrivacyTap),
        const Text(
          '.',
          style: TextStyle(
            color: Color(0xFF64748B),
            fontSize: 12.5,
            height: 1.5,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _PolicyLink extends StatelessWidget {
  const _PolicyLink({required this.text, required this.onTap});

  final String text;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(4),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 1, vertical: 2),
        child: Text(
          text,
          style: const TextStyle(
            color: Color(0xFF0284C7),
            decoration: TextDecoration.underline,
            decorationColor: Color(0xFF0284C7),
            fontSize: 12.5,
            height: 1.5,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}
