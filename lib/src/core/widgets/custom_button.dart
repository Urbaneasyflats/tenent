import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

enum CustomButtonVariant { primary, secondary, outline, ghost, danger }

enum CustomButtonSize { sm, md, lg }

class CustomButton extends StatefulWidget {
  const CustomButton({
    super.key,
    required this.label,
    this.onPressed,
    this.icon,
    this.variant = CustomButtonVariant.primary,
    this.size = CustomButtonSize.md,
    this.isLoading = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final Widget? icon;
  final CustomButtonVariant variant;
  final CustomButtonSize size;
  final bool isLoading;

  @override
  State<CustomButton> createState() => _CustomButtonState();
}

class _CustomButtonState extends State<CustomButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final _ButtonStyleTokens tokens = _tokensFor(widget.variant);
    final bool isDisabled = widget.onPressed == null || widget.isLoading;

    return AnimatedScale(
      scale: _pressed && !isDisabled ? 0.98 : 1,
      duration: const Duration(milliseconds: 120),
      child: AnimatedOpacity(
        opacity: isDisabled ? 0.5 : 1,
        duration: const Duration(milliseconds: 120),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: tokens.backgroundColor,
            borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
            border: Border.all(
              color: tokens.borderColor,
              width: tokens.borderWidth,
            ),
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: isDisabled ? null : widget.onPressed,
              onHighlightChanged: (bool value) {
                if (!mounted) {
                  return;
                }
                setState(() {
                  _pressed = value;
                });
              },
              borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
              splashColor: tokens.foregroundColor.withAlpha(20),
              highlightColor: tokens.foregroundColor.withAlpha(10),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: _heightFor(widget.size)),
                child: Padding(
                  padding: _paddingFor(widget.size),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      if (widget.isLoading)
                        SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              tokens.foregroundColor,
                            ),
                          ),
                        ),
                      if (widget.isLoading) const SizedBox(width: 8),
                      if (!widget.isLoading && widget.icon != null) ...<Widget>[
                        IconTheme(
                          data: IconThemeData(
                            size: _iconSizeFor(widget.size),
                            color: tokens.foregroundColor,
                          ),
                          child: widget.icon!,
                        ),
                        const SizedBox(width: 8),
                      ],
                      Flexible(
                        child: Text(
                          widget.label,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: tokens.foregroundColor,
                            fontSize: _fontSizeFor(widget.size),
                            fontWeight: FontWeight.w500,
                            height: 1.429,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  _ButtonStyleTokens _tokensFor(CustomButtonVariant value) {
    return switch (value) {
      CustomButtonVariant.primary => const _ButtonStyleTokens(
        backgroundColor: AppTheme.primary,
        foregroundColor: Colors.white,
        borderColor: AppTheme.primary,
      ),
      CustomButtonVariant.secondary => const _ButtonStyleTokens(
        backgroundColor: AppTheme.secondary,
        foregroundColor: Colors.white,
        borderColor: AppTheme.secondary,
      ),
      CustomButtonVariant.outline => const _ButtonStyleTokens(
        backgroundColor: AppTheme.surface,
        foregroundColor: AppTheme.textSecondary,
        borderColor: AppTheme.borderStrong,
        borderWidth: 1.5,
      ),
      CustomButtonVariant.ghost => const _ButtonStyleTokens(
        backgroundColor: Colors.transparent,
        foregroundColor: AppTheme.textSecondary,
        borderColor: Colors.transparent,
        borderWidth: 0,
      ),
      CustomButtonVariant.danger => const _ButtonStyleTokens(
        backgroundColor: Color(0xFFDC2626),
        foregroundColor: Colors.white,
        borderColor: Color(0xFFDC2626),
      ),
    };
  }

  EdgeInsets _paddingFor(CustomButtonSize value) {
    return switch (value) {
      CustomButtonSize.sm => const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 8,
      ),
      CustomButtonSize.md => const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 10,
      ),
      CustomButtonSize.lg => const EdgeInsets.symmetric(
        horizontal: 20,
        vertical: 12,
      ),
    };
  }

  double _heightFor(CustomButtonSize value) {
    return switch (value) {
      CustomButtonSize.sm => 36,
      CustomButtonSize.md => 40,
      CustomButtonSize.lg => 48,
    };
  }

  double _fontSizeFor(CustomButtonSize value) {
    return switch (value) {
      CustomButtonSize.sm => 13,
      CustomButtonSize.md => 14,
      CustomButtonSize.lg => 16,
    };
  }

  double _iconSizeFor(CustomButtonSize value) {
    return switch (value) {
      CustomButtonSize.sm => 16,
      CustomButtonSize.md => 18,
      CustomButtonSize.lg => 20,
    };
  }
}

class _ButtonStyleTokens {
  const _ButtonStyleTokens({
    required this.backgroundColor,
    required this.foregroundColor,
    required this.borderColor,
    this.borderWidth = 1,
  });

  final Color backgroundColor;
  final Color foregroundColor;
  final Color borderColor;
  final double borderWidth;
}
