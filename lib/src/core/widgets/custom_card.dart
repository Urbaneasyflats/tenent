import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

enum CustomCardPadding { none, sm, md, lg }

class CustomCard extends StatelessWidget {
  const CustomCard({
    super.key,
    required this.child,
    this.padding = CustomCardPadding.md,
    this.onTap,
    this.color,
    this.borderColor,
  });

  final Widget child;
  final CustomCardPadding padding;
  final VoidCallback? onTap;
  final Color? color;
  final Color? borderColor;

  @override
  Widget build(BuildContext context) {
    final Widget content = Padding(padding: _paddingFor(padding), child: child);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: color ?? AppTheme.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        border: Border.all(color: borderColor ?? AppTheme.borderSoft),
        boxShadow: const <BoxShadow>[
          BoxShadow(
            color: Color(0x0F111827),
            blurRadius: 24,
            offset: Offset(0, 10),
          ),
          BoxShadow(
            color: Color(0x0A111827),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: onTap != null
          ? Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: onTap,
                borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                child: content,
              ),
            )
          : content,
    );
  }

  EdgeInsets _paddingFor(CustomCardPadding value) {
    return switch (value) {
      CustomCardPadding.none => EdgeInsets.zero,
      CustomCardPadding.sm => const EdgeInsets.all(16),
      CustomCardPadding.md => const EdgeInsets.all(24),
      CustomCardPadding.lg => const EdgeInsets.all(32),
    };
  }
}
