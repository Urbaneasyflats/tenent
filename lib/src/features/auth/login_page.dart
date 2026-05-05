import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/api/auth_service.dart';
import '../../core/models/app_models.dart';
import '../legal/legal_policy_page.dart';
import 'widgets/auth_flow_widgets.dart';

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

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _phoneController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  bool _otpSent = false;
  String? _errorMessage;

  static final RegExp _indianMobilePattern = RegExp(r'^[6-9]\d{9}$');

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _requestOtp() async {
    TextInput.finishAutofillContext(shouldSave: true);
    _phoneController.text = _normalizePhone(_phoneController.text);
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _otpSent = false;
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
          _otpSent = true;
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
        _errorMessage = 'Network error. Please check your connection.';
      });
    }
  }

  String _normalizePhone(String value) {
    final String digits = value.replaceAll(RegExp(r'\D'), '');
    if (digits.length <= 10) return digits;
    return digits.substring(digits.length - 10);
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return Scaffold(
      backgroundColor: AuthFlowColors.background,
      body: SafeArea(
        child: Stack(
          children: <Widget>[
            const _AuthAtmosphere(),
            CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: <Widget>[
                SliverToBoxAdapter(
                  child: AuthTopBar(title: 'Sign in', onBack: widget.onBack),
                ),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 14, 20, 22),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate(
                      <Widget>[
                        const AnimatedSection(child: _LoginHeroCard()),
                        const SizedBox(height: 18),
                        Text(
                          'Find your next stay',
                          style: theme.textTheme.headlineMedium?.copyWith(
                            color: AuthFlowColors.ink,
                            fontSize: 34,
                            height: 1,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -1.4,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'Login with OTP to explore homes, PGs and rentals made for easy living.',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: AuthFlowColors.muted,
                            fontSize: 15,
                            height: 1.45,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 20),
                        _OtpLoginCard(
                          formKey: _formKey,
                          phoneController: _phoneController,
                          isLoading: _isLoading,
                          otpSent: _otpSent,
                          errorMessage: _errorMessage,
                          onRequestOtp: _requestOtp,
                          validator: (String? value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Phone number is required';
                            }
                            if (!_indianMobilePattern.hasMatch(value.trim())) {
                              return 'Enter a valid 10-digit Indian mobile number';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 18),
                        const _SecureFooter(),
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

class _AuthAtmosphere extends StatelessWidget {
  const _AuthAtmosphere();

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: <Widget>[
        Positioned(
          top: -110,
          right: -90,
          child: Container(
            width: 260,
            height: 260,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Color(0xFFEDEBFF),
            ),
          ),
        ),
        Positioned(
          top: 170,
          left: -110,
          child: Container(
            width: 240,
            height: 240,
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

class _LoginHeroCard extends StatelessWidget {
  const _LoginHeroCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 232,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(34),
        border: Border.all(color: const Color(0xFFF1F5F9)),
        boxShadow: const <BoxShadow>[
          BoxShadow(
            color: Color(0x14111827),
            blurRadius: 30,
            offset: Offset(0, 16),
          ),
        ],
      ),
      child: const Padding(
        padding: EdgeInsets.all(8),
        child: LoginHeroIllustration(),
      ),
    );
  }
}

class _OtpLoginCard extends StatelessWidget {
  const _OtpLoginCard({
    required this.formKey,
    required this.phoneController,
    required this.isLoading,
    required this.otpSent,
    required this.errorMessage,
    required this.onRequestOtp,
    required this.validator,
  });

  final GlobalKey<FormState> formKey;
  final TextEditingController phoneController;
  final bool isLoading;
  final bool otpSent;
  final String? errorMessage;
  final VoidCallback onRequestOtp;
  final FormFieldValidator<String> validator;

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
                    Icons.phone_iphone_rounded,
                    color: AuthFlowColors.primary,
                    size: 25,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        'Continue with phone',
                        style: theme.textTheme.titleLarge?.copyWith(
                          color: AuthFlowColors.ink,
                          fontSize: 19,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -0.3,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        'We will send a one time password.',
                        style: theme.textTheme.bodySmall?.copyWith(
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
            const SizedBox(height: 18),
            PhoneInputField(
              controller: phoneController,
              validator: validator,
            ),
            const SizedBox(height: 16),
            GradientButton(
              label: 'Continue',
              icon: Icons.arrow_forward_rounded,
              isLoading: isLoading,
              onPressed: isLoading ? null : onRequestOtp,
            ),
            if (otpSent) ...<Widget>[
              const SizedBox(height: 14),
              const _StatusMessage(
                text: 'OTP sent successfully!',
                color: AuthFlowColors.accent,
                icon: Icons.check_circle_rounded,
              ),
            ],
            if (errorMessage != null) ...<Widget>[
              const SizedBox(height: 14),
              _StatusMessage(
                text: errorMessage!,
                color: AuthFlowColors.muted,
                icon: Icons.error_rounded,
              ),
            ],
            ],
          ),
        ),
      ),
    );
  }
}

class _StatusMessage extends StatelessWidget {
  const _StatusMessage({
    required this.text,
    required this.color,
    required this.icon,
  });

  final String text;
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        Icon(icon, color: color, size: 18),
        const SizedBox(width: 6),
        Flexible(
          child: Text(
            text,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: color,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}

class _SecureFooter extends StatelessWidget {
  const _SecureFooter();

  void _openPolicy(BuildContext context, LegalPolicyType type) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => LegalPolicyPage(type: type),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.74),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Wrap(
        alignment: WrapAlignment.center,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: <Widget>[
          const Text(
            'By continuing, you agree to our ',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AuthFlowColors.muted,
              fontSize: 12,
              height: 1.45,
              fontWeight: FontWeight.w600,
            ),
          ),
          _FooterPolicyLink(
            text: 'Terms',
            onTap: () => _openPolicy(context, LegalPolicyType.terms),
          ),
          const Text(
            ' and ',
            style: TextStyle(
              color: AuthFlowColors.muted,
              fontSize: 12,
              height: 1.45,
              fontWeight: FontWeight.w600,
            ),
          ),
          _FooterPolicyLink(
            text: 'Privacy Policy',
            onTap: () => _openPolicy(context, LegalPolicyType.privacy),
          ),
        ],
      ),
    );
  }
}

class _FooterPolicyLink extends StatelessWidget {
  const _FooterPolicyLink({required this.text, required this.onTap});

  final String text;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 2),
        child: Text(
          text,
          style: const TextStyle(
            color: AuthFlowColors.primary,
            fontSize: 12,
            height: 1.45,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    );
  }
}
