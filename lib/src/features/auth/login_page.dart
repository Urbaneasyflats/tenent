import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/api/auth_service.dart';
import '../../core/models/app_models.dart';
import '../../core/services/phone_number_prefill_service.dart';
import '../legal/legal_policy_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({
    super.key,
    required this.authSource,
    required this.onOtpRequested,
    required this.onBack,
  });

  final AuthSource authSource;
  final ValueChanged<String> onOtpRequested;
  final VoidCallback onBack;

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> with WidgetsBindingObserver {
  final TextEditingController _phoneController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  bool _isPrefillInProgress = false;
  String? _errorMessage;

  static final RegExp _indianMobilePattern = RegExp(r'^[6-9]\d{9}$');

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _prefillPhoneNumber();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _phoneController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed &&
        _phoneController.text.trim().isEmpty) {
      _prefillPhoneNumber();
    }
  }

  Future<void> _prefillPhoneNumber() async {
    if (_isPrefillInProgress) {
      return;
    }
    _isPrefillInProgress = true;

    final String? phone =
        await PhoneNumberPrefillService.detectIndianMobileNumber();
    if (!mounted) {
      _isPrefillInProgress = false;
      return;
    }
    if (phone != null && _phoneController.text.trim().isEmpty) {
      _phoneController.text = phone;
    }
    _isPrefillInProgress = false;
  }

  Future<void> _requestOtp() async {
    _phoneController.text = _normalizePhone(_phoneController.text);
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final response = await AuthService.generateOtp(
        _phoneController.text.trim(),
        vendorType: widget.authSource.vendorType,
      );

      if (!mounted) return;

      if (response.success) {
        setState(() {
          _isLoading = false;
        });
        widget.onOtpRequested(_phoneController.text.trim());
      } else {
        setState(() {
          _isLoading = false;
          _errorMessage =
              response.message ?? response.status ?? 'Failed to send OTP';
        });
      }
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = AuthService.offlineMessage;
      });
    }
  }

  String _normalizePhone(String value) {
    final String digits = value.replaceAll(RegExp(r'\D'), '');
    if (digits.length <= 10) return digits;
    return digits.substring(digits.length - 10);
  }

  void _openPolicy(BuildContext context, LegalPolicyType type) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => LegalPolicyPage(type: type)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      resizeToAvoidBottomInset: false,
      body: SafeArea(
        child: Stack(
          children: <Widget>[
            Positioned(
              left: 14,
              top: 8,
              child: _BackButton(onPressed: widget.onBack),
            ),
            Center(
              child: AutofillGroup(
                child: SingleChildScrollView(
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,
                  padding: const EdgeInsets.fromLTRB(22, 24, 22, 22),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 430),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: <Widget>[
                          const SizedBox(height: 22),
                          const _TenantLogo(),
                          const SizedBox(height: 30),
                          Text(
                            'Welcome home.',
                            textAlign: TextAlign.center,
                            style: theme.textTheme.headlineMedium?.copyWith(
                              color: const Color(0xFF111827),
                              fontSize: 34,
                              height: 1.05,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            'Log in to your tenant account to manage your home with ease.',
                            textAlign: TextAlign.center,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: const Color(0xFF64748B),
                              fontSize: 15.5,
                              height: 1.45,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 34),
                          _PhoneInputField(
                            controller: _phoneController,
                            validator: (String? value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Phone number is required';
                              }
                              if (!_indianMobilePattern.hasMatch(
                                value.trim(),
                              )) {
                                return 'Enter a valid 10-digit Indian mobile number';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 18),
                          _LoginButton(
                            isLoading: _isLoading,
                            onPressed: _isLoading ? null : _requestOtp,
                          ),
                          const SizedBox(height: 12),
                          const _VerificationText(),
                          if (_errorMessage != null) ...<Widget>[
                            const SizedBox(height: 14),
                            _ErrorMessage(text: _errorMessage!),
                          ],
                          const SizedBox(height: 34),
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
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BackButton extends StatelessWidget {
  const _BackButton({required this.onPressed});

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
        width: 92,
        height: 92,
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(28),
          boxShadow: <BoxShadow>[
            BoxShadow(
              color: const Color(0xFF0284C7).withValues(alpha: 0.12),
              blurRadius: 28,
              offset: const Offset(0, 14),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(22),
          child: Image.asset(
            'assets/tenenet_logo.jpg',
            fit: BoxFit.cover,
          ),
        ),
      ),
    );
  }
}

class _PhoneInputField extends StatelessWidget {
  const _PhoneInputField({
    required this.controller,
    required this.validator,
  });

  final TextEditingController controller;
  final FormFieldValidator<String> validator;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      autofillHints: const <String>[
        AutofillHints.telephoneNumber,
        AutofillHints.telephoneNumberNational,
      ],
      keyboardType: TextInputType.phone,
      textInputAction: TextInputAction.done,
      maxLength: 10,
      inputFormatters: <TextInputFormatter>[
        FilteringTextInputFormatter.digitsOnly,
        _IndianPhoneInputFormatter(),
      ],
      style: const TextStyle(
        color: Color(0xFF111827),
        fontSize: 16,
        fontWeight: FontWeight.w800,
      ),
      decoration: InputDecoration(
        counterText: '',
        hintText: 'Phone number',
        hintStyle: const TextStyle(
          color: Color(0xFF94A3B8),
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 18,
          vertical: 19,
        ),
        prefixIcon: const Padding(
          padding: EdgeInsets.only(left: 16, right: 12),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Icon(Icons.phone_iphone_rounded, color: Color(0xFF0284C7)),
              SizedBox(width: 12),
              Text(
                '+91',
                style: TextStyle(
                  color: Color(0xFF111827),
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                ),
              ),
              SizedBox(width: 4),
              Icon(
                Icons.keyboard_arrow_down_rounded,
                color: Color(0xFF64748B),
                size: 22,
              ),
              SizedBox(width: 12),
              SizedBox(
                height: 26,
                child: VerticalDivider(
                  width: 1,
                  thickness: 1,
                  color: Color(0xFFE2E8F0),
                ),
              ),
              SizedBox(width: 12),
            ],
          ),
        ),
        border: _inputBorder(const Color(0xFFE2E8F0), 1),
        enabledBorder: _inputBorder(const Color(0xFFE2E8F0), 1),
        focusedBorder: _inputBorder(const Color(0xFF38BDF8), 1.5),
        errorBorder: _inputBorder(const Color(0xFFFCA5A5), 1),
        focusedErrorBorder: _inputBorder(const Color(0xFF38BDF8), 1.5),
      ),
      validator: validator,
    );
  }

  static OutlineInputBorder _inputBorder(Color color, double width) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(20),
      borderSide: BorderSide(color: color, width: width),
    );
  }
}

class _LoginButton extends StatelessWidget {
  const _LoginButton({
    required this.isLoading,
    required this.onPressed,
  });

  final bool isLoading;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(22),
        child: Ink(
          height: 60,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            gradient: const LinearGradient(
              colors: <Color>[Color(0xFF38BDF8), Color(0xFF0284C7)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: <BoxShadow>[
              BoxShadow(
                color: const Color(0xFF0284C7).withValues(alpha: 0.24),
                blurRadius: 24,
                offset: const Offset(0, 12),
              ),
            ],
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
                    'Log in',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}

class _VerificationText extends StatelessWidget {
  const _VerificationText();

  @override
  Widget build(BuildContext context) {
    return const Text(
      "We'll send you a verification code to your phone number.",
      textAlign: TextAlign.center,
      style: TextStyle(
        color: Color(0xFF64748B),
        fontSize: 12.5,
        height: 1.35,
        fontWeight: FontWeight.w600,
      ),
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

class _IndianPhoneInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final String oldDigits = oldValue.text.replaceAll(RegExp(r'\D'), '');
    final String digits = newValue.text.replaceAll(RegExp(r'\D'), '');
    if (digits.length <= 10) {
      return newValue.copyWith(
        text: digits,
        selection: TextSelection.collapsed(offset: digits.length),
      );
    }

    if (oldDigits.length >= 10) {
      return oldValue;
    }

    final String normalized = digits.substring(digits.length - 10);
    return TextEditingValue(
      text: normalized,
      selection: TextSelection.collapsed(offset: normalized.length),
    );
  }
}
