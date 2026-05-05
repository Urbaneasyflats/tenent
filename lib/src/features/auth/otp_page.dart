import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/api/auth_service.dart';
import '../../core/models/app_models.dart';
import 'widgets/auth_flow_widgets.dart';

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

class _OtpPageState extends State<OtpPage> {
  final TextEditingController _otpController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  bool _isResending = false;
  String? _errorMessage;
  int _resendCountdown = 30;
  Timer? _resendTimer;

  @override
  void initState() {
    super.initState();
    _startResendTimer();
  }

  @override
  void dispose() {
    _otpController.dispose();
    _resendTimer?.cancel();
    super.dispose();
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
    TextInput.finishAutofillContext();
    _otpController.text = _normalizeOtp(_otpController.text);
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final response = await AuthService.validateOtp(
        widget.phoneNumber,
        _otpController.text.trim(),
        vendorType: widget.authSource.vendorType,
      );

      if (!mounted) {
        return;
      }

      if (response.success) {
        final Map<String, dynamic>? data =
            response.data as Map<String, dynamic>?;
        final bool hasBasicInformation =
            data?['Whether_Basic_Information_Available'] as bool? ?? true;

        setState(() {
          _isLoading = false;
        });
        widget.onVerified(!hasBasicInformation);
      } else {
        setState(() {
          _isLoading = false;
          _errorMessage =
              response.message ?? response.status ?? 'Invalid OTP';
        });
      }
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _isLoading = false;
        _errorMessage = 'Network error. Please check your connection.';
      });
    }
  }

  String _normalizeOtp(String value) {
    final String digits = value.replaceAll(RegExp(r'\D'), '');
    return digits.length > 4 ? digits.substring(0, 4) : digits;
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
        setState(() {
          _isResending = false;
          _errorMessage = 'OTP sent again successfully.';
        });
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
        _errorMessage = 'Network error. Please try again.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return Scaffold(
      backgroundColor: AuthFlowColors.background,
      body: SafeArea(
        child: Stack(
          children: <Widget>[
            const _OtpAtmosphere(),
            CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: <Widget>[
                SliverToBoxAdapter(
                  child: AuthTopBar(title: 'Verify OTP', onBack: widget.onBack),
                ),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate(
                      <Widget>[
                        const AnimatedSection(child: _OtpHeroCard()),
                        const SizedBox(height: 18),
                        Text(
                          'Enter your code',
                          style: theme.textTheme.headlineMedium?.copyWith(
                            color: AuthFlowColors.ink,
                            fontSize: 34,
                            height: 1,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -1.4,
                          ),
                        ),
                        const SizedBox(height: 10),
                        RichText(
                          text: TextSpan(
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: AuthFlowColors.muted,
                              fontSize: 15,
                              height: 1.45,
                              fontWeight: FontWeight.w600,
                            ),
                            children: <TextSpan>[
                              const TextSpan(text: 'We sent a 4-digit OTP to '),
                              TextSpan(
                                text: '+91 ${widget.phoneNumber}',
                                style: const TextStyle(
                                  color: AuthFlowColors.ink,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),
                        _OtpVerifyCard(
                          formKey: _formKey,
                          otpController: _otpController,
                          errorMessage: _errorMessage,
                        ),
                        const SizedBox(height: 18),
                        GradientButton(
                          label: 'Verify and continue',
                          icon: Icons.verified_rounded,
                          height: 60,
                          isLoading: _isLoading,
                          onPressed: _isLoading ? null : _verifyOtp,
                        ),
                        const SizedBox(height: 18),
                        _ResendOtpPanel(
                          countdown: _resendCountdown,
                          isResending: _isResending,
                          onResend: _resendOtp,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _OtpAtmosphere extends StatelessWidget {
  const _OtpAtmosphere();

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: <Widget>[
        Positioned(
          top: -90,
          left: -70,
          child: Container(
            width: 230,
            height: 230,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Color(0xFFEDEBFF),
            ),
          ),
        ),
        Positioned(
          bottom: 80,
          right: -110,
          child: Container(
            width: 260,
            height: 260,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Color(0xFFF8F9FB),
            ),
          ),
        ),
      ],
    );
  }
}

class _OtpHeroCard extends StatelessWidget {
  const _OtpHeroCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 198,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(34),
        boxShadow: const <BoxShadow>[
          BoxShadow(
            color: Color(0x1A1F2937),
            blurRadius: 34,
            offset: Offset(0, 18),
          ),
        ],
      ),
      child: Stack(
        children: <Widget>[
          Positioned.fill(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(34),
              child: const DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: <Color>[
                      Color(0xFFF1F0FF),
                      Color(0xFFF8F9FB),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
              ),
            ),
          ),
          const Positioned.fill(
            child: Align(
              alignment: Alignment.center,
              child: OtpHeroIllustration(),
            ),
          ),
          Positioned(
            left: 18,
            top: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.86),
                borderRadius: BorderRadius.circular(999),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Icon(
                    Icons.lock_outline_rounded,
                    size: 16,
                    color: AuthFlowColors.primary,
                  ),
                  SizedBox(width: 6),
                  Text(
                    'Secure login',
                    style: TextStyle(
                      color: AuthFlowColors.ink,
                      fontSize: 13,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _OtpVerifyCard extends StatelessWidget {
  const _OtpVerifyCard({
    required this.formKey,
    required this.otpController,
    required this.errorMessage,
  });

  final GlobalKey<FormState> formKey;
  final TextEditingController otpController;
  final String? errorMessage;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: AuthFlowColors.border),
        boxShadow: const <BoxShadow>[
          BoxShadow(
            color: Color(0x121F2937),
            blurRadius: 26,
            offset: Offset(0, 16),
          ),
        ],
      ),
      child: AutofillGroup(
        child: Form(
          key: formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
            Row(
              children: <Widget>[
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: AuthFlowColors.cream,
                    borderRadius: BorderRadius.circular(17),
                  ),
                  child: const Icon(
                    Icons.password_rounded,
                    color: AuthFlowColors.primary,
                    size: 25,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Verification code',
                    style: theme.textTheme.titleLarge?.copyWith(
                      color: AuthFlowColors.ink,
                      fontSize: 19,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.3,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            OtpRow(
              controller: otpController,
              validator: (String? value) {
                if (value == null || value.trim().isEmpty) {
                  return 'OTP is required';
                }
                if (value.trim().length != 4) {
                  return 'Enter a valid 4-digit OTP';
                }
                return null;
              },
            ),
            if (errorMessage != null) ...<Widget>[
              const SizedBox(height: 14),
              _OtpStatusMessage(text: errorMessage!),
            ],
            ],
          ),
        ),
      ),
    );
  }
}

class _OtpStatusMessage extends StatelessWidget {
  const _OtpStatusMessage({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        const Icon(Icons.error_rounded, color: AuthFlowColors.muted, size: 18),
        const SizedBox(width: 7),
        Flexible(
          child: Text(
            text,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AuthFlowColors.muted,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}

class _ResendOtpPanel extends StatelessWidget {
  const _ResendOtpPanel({
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

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.82),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AuthFlowColors.border),
      ),
      child: Row(
        children: <Widget>[
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: AuthFlowColors.cream,
              borderRadius: BorderRadius.circular(15),
            ),
            child: const Icon(
              Icons.refresh_rounded,
              color: AuthFlowColors.primary,
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                isResending
                    ? const Text(
                        'Sending OTP...',
                        style: TextStyle(
                          color: AuthFlowColors.primary,
                          fontSize: 15,
                          fontWeight: FontWeight.w900,
                        ),
                      )
                    : waiting
                    ? RichText(
                        text: TextSpan(
                          style: const TextStyle(
                            color: AuthFlowColors.ink,
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                          ),
                          children: <TextSpan>[
                            const TextSpan(text: 'Resend code in '),
                            TextSpan(
                              text: '${countdown}s',
                              style: const TextStyle(
                                color: AuthFlowColors.primary,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ],
                        ),
                      )
                    : GestureDetector(
                        onTap: onResend,
                        child: const Text(
                          'Resend OTP',
                          style: TextStyle(
                            color: AuthFlowColors.primary,
                            fontSize: 15,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                const SizedBox(height: 4),
                const Text(
                  'Did not receive it? You can request a new code.',
                  style: TextStyle(
                    color: AuthFlowColors.muted,
                    fontSize: 12.5,
                    height: 1.35,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
