import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class AuthFlowColors {
  const AuthFlowColors._();

  static const Color primary = Color(0xFF6C5CE7);
  static const Color dark = Color(0xFFA29BFE);
  static const Color accent = Color(0xFF00B894);
  static const Color background = Color(0xFFF8F9FB);
  static const Color text = Color(0xFF1F2937);
  static const Color muted = Color(0xFF6B7280);
  static const Color border = Color(0xFFE5E7EB);
  static const Color cream = Color(0xFFF1F0FF);
  static const Color ink = Color(0xFF1F2937);
}

class AuthTopBar extends StatelessWidget {
  const AuthTopBar({super.key, required this.title, required this.onBack});

  final String title;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 18, 0),
      child: Row(
        children: <Widget>[
          Material(
            color: Colors.white,
            shape: const CircleBorder(),
            elevation: 0,
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: onBack,
              child: const SizedBox(
                width: 42,
                height: 42,
                child: Icon(
                  Icons.arrow_back_ios_new_rounded,
                  color: AuthFlowColors.text,
                  size: 18,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            title,
            style: const TextStyle(
              color: AuthFlowColors.text,
              fontSize: 20,
              height: 1.2,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.4,
            ),
          ),
        ],
      ),
    );
  }
}

class GradientButton extends StatelessWidget {
  const GradientButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.isLoading = false,
    this.height = 58,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool isLoading;
  final double height;

  @override
  Widget build(BuildContext context) {
    final bool disabled = onPressed == null;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: disabled ? null : onPressed,
        borderRadius: BorderRadius.circular(16),
        child: Ink(
          width: double.infinity,
          height: height,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: disabled
                ? const LinearGradient(
                    colors: <Color>[AuthFlowColors.dark, AuthFlowColors.dark],
                  )
                : const LinearGradient(
                    colors: <Color>[
                      AuthFlowColors.primary,
                      AuthFlowColors.dark,
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
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
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      if (icon != null) ...<Widget>[
                        Icon(icon, color: Colors.white, size: 24),
                        const SizedBox(width: 12),
                      ],
                      Text(
                        label,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}

class PhoneInputField extends StatelessWidget {
  const PhoneInputField({
    super.key,
    required this.controller,
    required this.validator,
  });

  final TextEditingController controller;
  final FormFieldValidator<String> validator;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: TextInputType.phone,
      textInputAction: TextInputAction.done,
      inputFormatters: <TextInputFormatter>[
        FilteringTextInputFormatter.digitsOnly,
        _IndianPhoneInputFormatter(),
      ],
      style: const TextStyle(
        color: AuthFlowColors.text,
        fontSize: 16,
        fontWeight: FontWeight.w700,
      ),
      decoration: InputDecoration(
        counterText: '',
        hintText: 'Mobile number',
        hintStyle: const TextStyle(
          color: AuthFlowColors.muted,
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
        filled: true,
        fillColor: const Color(0xFFFFFCFA),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 19,
        ),
        prefixIcon: const Padding(
          padding: EdgeInsets.only(left: 16, right: 14),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Text(
                '+91',
                style: TextStyle(
                  color: AuthFlowColors.text,
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                ),
              ),
              SizedBox(width: 8),
              Icon(
                Icons.keyboard_arrow_down_rounded,
                color: AuthFlowColors.muted,
                size: 22,
              ),
              SizedBox(width: 14),
              SizedBox(
                height: 28,
                child: VerticalDivider(
                  width: 1,
                  thickness: 1,
                  color: AuthFlowColors.border,
                ),
              ),
              SizedBox(width: 14),
              Icon(Icons.phone_outlined, color: AuthFlowColors.muted, size: 22),
            ],
          ),
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: AuthFlowColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: AuthFlowColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(
            color: AuthFlowColors.primary,
            width: 1.5,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: Color(0xFFFCA5A5)),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: AuthFlowColors.muted, width: 1.5),
        ),
      ),
      validator: validator,
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

class OtpRow extends StatefulWidget {
  const OtpRow({super.key, required this.controller, required this.validator});

  final TextEditingController controller;
  final FormFieldValidator<String> validator;

  @override
  State<OtpRow> createState() => _OtpRowState();
}

class _OtpRowState extends State<OtpRow> {
  static const int _otpMaxLength = 4;

  late final List<TextEditingController> _controllers;
  late final FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _controllers = List<TextEditingController>.generate(
      _otpMaxLength,
      (_) => TextEditingController(),
    );
    _focusNode = FocusNode();
    _focusNode.addListener(_handleFocusChange);
    widget.controller.addListener(_syncFromParent);
    _syncFromParent();
  }

  @override
  void dispose() {
    widget.controller.removeListener(_syncFromParent);
    _focusNode.removeListener(_handleFocusChange);
    for (final TextEditingController controller in _controllers) {
      controller.dispose();
    }
    _focusNode.dispose();
    super.dispose();
  }

  void _syncFromParent() {
    final String value = _digitsOnly(widget.controller.text);
    for (int index = 0; index < _otpMaxLength; index++) {
      _controllers[index].text = index < value.length ? value[index] : '';
    }
    if (mounted) setState(() {});
  }

  void _handleFocusChange() {
    if (mounted) setState(() {});
  }

  void _updateParent(FormFieldState<String> field) {
    final String value = _digitsOnly(widget.controller.text);
    field.didChange(value);
    _syncFromParent();
  }

  String _digitsOnly(String value) {
    final String digits = value.replaceAll(RegExp(r'\D'), '');
    return digits.length > _otpMaxLength
        ? digits.substring(0, _otpMaxLength)
        : digits;
  }

  @override
  Widget build(BuildContext context) {
    return FormField<String>(
      initialValue: widget.controller.text,
      validator: widget.validator,
      builder: (FormFieldState<String> field) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            Stack(
              children: <Widget>[
                Positioned.fill(
                  child: Opacity(
                    opacity: 0.01,
                    child: TextField(
                      controller: widget.controller,
                      focusNode: _focusNode,
                      autofocus: false,
                      keyboardType: TextInputType.number,
                      textInputAction: TextInputAction.done,
                      inputFormatters: <TextInputFormatter>[
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(_otpMaxLength),
                      ],
                      onChanged: (String value) {
                        final String digits = _digitsOnly(value);
                        if (value != digits) {
                          widget.controller.value = TextEditingValue(
                            text: digits,
                            selection: TextSelection.collapsed(
                              offset: digits.length,
                            ),
                          );
                        }
                        _updateParent(field);
                      },
                    ),
                  ),
                ),
                Row(
                  children: List<Widget>.generate(_otpMaxLength, (int index) {
                    return Expanded(
                      child: GestureDetector(
                        onTap: () => _focusNode.requestFocus(),
                        child: Container(
                          height: 58,
                          margin: EdgeInsets.only(
                            right: index == _otpMaxLength - 1 ? 0 : 10,
                          ),
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFFCFA),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color:
                                  _focusNode.hasFocus ||
                                      _controllers[index].text.isNotEmpty
                                  ? AuthFlowColors.primary
                                  : const Color(0xFFD4DAE5),
                              width:
                                  _focusNode.hasFocus ||
                                      _controllers[index].text.isNotEmpty
                                  ? 1.8
                                  : 1.3,
                            ),
                          ),
                          child: Text(
                            _controllers[index].text.isEmpty
                                ? '-'
                                : _controllers[index].text,
                            style: TextStyle(
                              color: _controllers[index].text.isEmpty
                                  ? const Color(0xFFC9D0DC)
                                  : AuthFlowColors.text,
                              fontSize: 24,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                      ),
                    );
                  }),
                ),
              ],
            ),
            if (field.hasError) ...<Widget>[
              const SizedBox(height: 10),
              Text(
                field.errorText!,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: AuthFlowColors.muted,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ],
        );
      },
    );
  }
}

class AuthStatusMessage extends StatelessWidget {
  const AuthStatusMessage({
    super.key,
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
        const SizedBox(width: 7),
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

class LoginHeroIllustration extends StatelessWidget {
  const LoginHeroIllustration({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AuthFlowColors.border),
      ),
      child: Row(
        children: <Widget>[
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: <Color>[AuthFlowColors.primary, AuthFlowColors.dark],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Icon(
              Icons.home_work_rounded,
              color: Colors.white,
              size: 27,
            ),
          ),
          const SizedBox(width: 14),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  'Urban EasyFlats',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: AuthFlowColors.ink,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    height: 1.05,
                  ),
                ),
                SizedBox(height: 5),
                Text(
                  'Verified homes, PGs and rentals in one place.',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: AuthFlowColors.muted,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    height: 1.25,
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

class OtpHeroIllustration extends StatelessWidget {
  const OtpHeroIllustration({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AuthFlowColors.border),
      ),
      child: Row(
        children: <Widget>[
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: AuthFlowColors.cream,
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Icon(
              Icons.lock_outline_rounded,
              color: AuthFlowColors.primary,
              size: 26,
            ),
          ),
          const SizedBox(width: 14),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  'Secure OTP',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: AuthFlowColors.ink,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    height: 1.05,
                  ),
                ),
                SizedBox(height: 5),
                Text(
                  'Enter the code sent to your mobile number.',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: AuthFlowColors.muted,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    height: 1.25,
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

class _AuthFeaturePill extends StatelessWidget {
  const _AuthFeaturePill({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AuthFlowColors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(icon, color: AuthFlowColors.primary, size: 15),
          const SizedBox(width: 5),
          Text(
            label,
            style: const TextStyle(
              color: AuthFlowColors.ink,
              fontSize: 11.5,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class AuthFeatureRow extends StatelessWidget {
  const AuthFeatureRow({super.key});

  @override
  Widget build(BuildContext context) {
    return const Wrap(
      spacing: 8,
      runSpacing: 8,
      children: <Widget>[
        _AuthFeaturePill(icon: Icons.verified_rounded, label: 'Verified'),
        _AuthFeaturePill(icon: Icons.bolt_rounded, label: 'Fast login'),
        _AuthFeaturePill(icon: Icons.shield_outlined, label: 'Secure'),
      ],
    );
  }
}
