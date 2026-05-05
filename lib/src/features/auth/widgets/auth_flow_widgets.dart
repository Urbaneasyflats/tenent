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

class AnimatedSection extends StatefulWidget {
  const AnimatedSection({
    super.key,
    required this.child,
    this.delay = Duration.zero,
    this.offset = const Offset(0, 18),
  });

  final Widget child;
  final Duration delay;
  final Offset offset;

  @override
  State<AnimatedSection> createState() => _AnimatedSectionState();
}

class _AnimatedSectionState extends State<AnimatedSection>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fade;
  late final Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 520),
    );
    _fade = CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic);
    _slide = Tween<Offset>(
      begin: widget.offset,
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));
    Future<void>.delayed(widget.delay, () {
      if (mounted) {
        _controller.forward();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fade,
      child: SlideTransition(position: _slide, child: widget.child),
    );
  }
}

class AuthTopBar extends StatelessWidget {
  const AuthTopBar({
    super.key,
    required this.title,
    required this.onBack,
  });

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

class GradientButton extends StatefulWidget {
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
  State<GradientButton> createState() => _GradientButtonState();
}

class _GradientButtonState extends State<GradientButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final bool disabled = widget.onPressed == null;

    return GestureDetector(
      onTapDown: disabled ? null : (_) => setState(() => _pressed = true),
      onTapCancel: disabled ? null : () => setState(() => _pressed = false),
      onTapUp: disabled
          ? null
          : (_) {
              setState(() => _pressed = false);
              widget.onPressed?.call();
            },
      child: AnimatedScale(
        scale: _pressed ? 0.97 : 1,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOut,
        child: Container(
          width: double.infinity,
          height: widget.height,
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
            boxShadow: disabled
                ? const <BoxShadow>[]
                : const <BoxShadow>[
                    BoxShadow(
                      color: Color(0x336C5CE7),
                      blurRadius: 24,
                      offset: Offset(0, 14),
                    ),
                  ],
          ),
          child: Center(
            child: widget.isLoading
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
                      if (widget.icon != null) ...<Widget>[
                        Icon(widget.icon, color: Colors.white, size: 24),
                        const SizedBox(width: 12),
                      ],
                      Text(
                        widget.label,
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
      autofillHints: const <String>[
        AutofillHints.telephoneNumberDevice,
        AutofillHints.telephoneNumber,
        AutofillHints.telephoneNumberNational,
      ],
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
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 19),
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
          borderSide: const BorderSide(color: AuthFlowColors.primary, width: 1.5),
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
  const OtpRow({
    super.key,
    required this.controller,
    required this.validator,
  });

  final TextEditingController controller;
  final FormFieldValidator<String> validator;

  @override
  State<OtpRow> createState() => _OtpRowState();
}

class _OtpRowState extends State<OtpRow> {
  late final List<TextEditingController> _controllers;
  late final FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _controllers = List<TextEditingController>.generate(
      4,
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
    for (int index = 0; index < 4; index++) {
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
    return digits.length > 4 ? digits.substring(0, 4) : digits;
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
                      autofocus: true,
                      autofillHints: const <String>[AutofillHints.oneTimeCode],
                      keyboardType: TextInputType.number,
                      textInputAction: TextInputAction.done,
                      inputFormatters: <TextInputFormatter>[
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(4),
                      ],
                      onChanged: (String value) {
                        final String digits = _digitsOnly(value);
                        if (value != digits) {
                          widget.controller.value = TextEditingValue(
                            text: digits,
                            selection:
                                TextSelection.collapsed(offset: digits.length),
                          );
                        }
                        _updateParent(field);
                      },
                    ),
                  ),
                ),
                Row(
                  children: List<Widget>.generate(4, (int index) {
                    return Expanded(
                      child: AnimatedSection(
                        delay: Duration(milliseconds: 80 * index),
                        offset: const Offset(0, 10),
                        child: GestureDetector(
                          onTap: () => _focusNode.requestFocus(),
                          child: Container(
                            height: 58,
                            margin:
                                EdgeInsets.only(right: index == 3 ? 0 : 10),
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFFCFA),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: _focusNode.hasFocus ||
                                        _controllers[index].text.isNotEmpty
                                    ? AuthFlowColors.primary
                                    : const Color(0xFFD4DAE5),
                                width: _focusNode.hasFocus ||
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
    return SizedBox(
      height: 210,
      width: double.infinity,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: Image.asset(
          'assets/login_hero.png',
          fit: BoxFit.contain,
          alignment: Alignment.center,
          errorBuilder: (
            BuildContext context,
            Object error,
            StackTrace? stackTrace,
          ) {
            return const _LoginFallbackIllustration(progress: 0.58);
          },
        ),
      ),
    );
  }
}

class OtpHeroIllustration extends StatelessWidget {
  const OtpHeroIllustration({super.key});

  @override
  Widget build(BuildContext context) {
    return const _OtpFallbackIllustration();
  }
}

class _LoginFallbackIllustration extends StatelessWidget {
  const _LoginFallbackIllustration({required this.progress});

  final double progress;

  @override
  Widget build(BuildContext context) {
    final double rise = (progress - 0.5) * 10;
    final double pulse = 0.94 + (progress * 0.08);

    return SizedBox(
      height: 210,
      child: Stack(
        alignment: Alignment.center,
        children: <Widget>[
          Positioned(
            top: 22,
            left: 38,
            child: Container(
              width: 236,
              height: 132,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(70),
                gradient: const LinearGradient(
                  colors: <Color>[Color(0x33FFFFFF), Color(0x11FFFFFF)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
            ),
          ),
          Positioned(
            right: 62,
            top: 28 + rise,
            child: Transform.scale(
              scale: pulse,
              child: const _SoftCloud(width: 38),
            ),
          ),
          Positioned(
            left: 52,
            top: 48 - rise,
            child: Transform.scale(
              scale: 1.02 - (progress * 0.05),
              child: const _SoftCloud(width: 46),
            ),
          ),
          Positioned(
            right: 52,
            bottom: 18,
            child: Transform.translate(
              offset: Offset(0, rise * 0.45),
              child: const _BuildingTower(),
            ),
          ),
          Positioned(
            right: 108,
            top: 56 + rise,
            child: Transform.scale(
              scale: pulse,
              child: const _LocationPinMark(),
            ),
          ),
          Positioned(
            left: 56,
            bottom: 16,
            child: Transform.translate(
              offset: Offset(0, -rise * 0.5),
              child: const _SeatedPerson(),
            ),
          ),
          Positioned(
            left: 116,
            top: 24,
            child: Transform.translate(
              offset: Offset(0, rise),
              child: const _FloatingKeyBadge(),
            ),
          ),
          Positioned(
            left: 88,
            bottom: 12,
            child: Container(
              width: 122,
              height: 12,
              decoration: BoxDecoration(
                color: const Color(0x291F2937),
                borderRadius: BorderRadius.circular(999),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FloatingKeyBadge extends StatelessWidget {
  const _FloatingKeyBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(18),
        boxShadow: const <BoxShadow>[
          BoxShadow(
            color: Color(0x26000000),
            blurRadius: 18,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: const Icon(
        Icons.key_rounded,
        color: AuthFlowColors.primary,
        size: 25,
      ),
    );
  }
}

class _SoftCloud extends StatelessWidget {
  const _SoftCloud({required this.width});

  final double width;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: width * 0.42,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.82),
        borderRadius: BorderRadius.circular(999),
        boxShadow: const <BoxShadow>[
          BoxShadow(
            color: Color(0x0F1F2937),
            blurRadius: 12,
            offset: Offset(0, 6),
          ),
        ],
      ),
    );
  }
}

class _LocationPinMark extends StatelessWidget {
  const _LocationPinMark();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 38,
      height: 38,
      decoration: BoxDecoration(
        color: AuthFlowColors.primary,
        borderRadius: BorderRadius.circular(19),
        boxShadow: const <BoxShadow>[
          BoxShadow(
            color: Color(0x336C5CE7),
            blurRadius: 18,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: const Icon(
        Icons.location_on_rounded,
        color: Colors.white,
        size: 22,
      ),
    );
  }
}

class _OtpFallbackIllustration extends StatelessWidget {
  const _OtpFallbackIllustration();

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      height: 170,
      child: Stack(
        alignment: Alignment.center,
        children: <Widget>[
          Positioned(left: 72, bottom: 0, child: _StandingPerson()),
          Positioned(right: 74, bottom: 14, child: _ShieldMark()),
        ],
      ),
    );
  }
}

class _BuildingTower extends StatelessWidget {
  const _BuildingTower();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 96,
      height: 128,
      decoration: BoxDecoration(
        color: const Color(0xFFD9EBFF),
        borderRadius: BorderRadius.circular(18),
        boxShadow: const <BoxShadow>[
          BoxShadow(
            color: Color(0x1A1B4D7A),
            blurRadius: 20,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: <Widget>[
          Container(
            height: 24,
            decoration: const BoxDecoration(
              color: Color(0xFFBFDFFF),
              borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
            ),
          ),
          Expanded(
            child: GridView.count(
              crossAxisCount: 3,
              padding: const EdgeInsets.fromLTRB(13, 12, 13, 13),
              mainAxisSpacing: 9,
              crossAxisSpacing: 9,
              physics: const NeverScrollableScrollPhysics(),
              children: List<Widget>.generate(
                12,
                (int index) => Container(
                  decoration: BoxDecoration(
                    color: index.isEven ? Colors.white : const Color(0xFFFFF5ED),
                    borderRadius: BorderRadius.circular(5),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SeatedPerson extends StatelessWidget {
  const _SeatedPerson();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 112,
      height: 138,
      child: Stack(
        alignment: Alignment.bottomCenter,
        children: <Widget>[
          Positioned(
            bottom: 0,
            child: Container(
              width: 86,
              height: 82,
              decoration: const BoxDecoration(
                color: AuthFlowColors.primary,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(34),
                  topRight: Radius.circular(34),
                  bottomLeft: Radius.circular(18),
                  bottomRight: Radius.circular(18),
                ),
              ),
            ),
          ),
          Positioned(
            top: 6,
            child: Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: const Color(0xFFC9815C),
                borderRadius: BorderRadius.circular(26),
              ),
              child: Align(
                alignment: Alignment.topCenter,
                child: Container(
                  width: 38,
                  height: 15,
                  margin: const EdgeInsets.only(top: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF211A18),
                    borderRadius: BorderRadius.circular(18),
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            right: 4,
            bottom: 34,
            child: Transform.rotate(
              angle: -0.12,
              child: Container(
                width: 34,
                height: 48,
                decoration: BoxDecoration(
                  color: const Color(0xFF171717),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.white, width: 2),
                ),
                child: const Center(
                  child: Icon(
                    Icons.home_rounded,
                    color: Colors.white,
                    size: 16,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StandingPerson extends StatelessWidget {
  const _StandingPerson();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        Container(
          width: 54,
          height: 54,
          decoration: BoxDecoration(
            color: const Color(0xFFBC744F),
            borderRadius: BorderRadius.circular(30),
          ),
        ),
        Container(
          width: 92,
          height: 110,
          decoration: const BoxDecoration(
            color: AuthFlowColors.primary,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(34),
              topRight: Radius.circular(34),
              bottomLeft: Radius.circular(12),
              bottomRight: Radius.circular(12),
            ),
          ),
        ),
      ],
    );
  }
}

class _ShieldMark extends StatelessWidget {
  const _ShieldMark();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 122,
      height: 138,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: <Color>[AuthFlowColors.primary, AuthFlowColors.dark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(52),
          topRight: Radius.circular(52),
          bottomLeft: Radius.circular(42),
          bottomRight: Radius.circular(42),
        ),
      ),
      child: const Icon(Icons.check_rounded, color: Colors.white, size: 70),
    );
  }
}
