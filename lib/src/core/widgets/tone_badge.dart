import 'package:flutter/material.dart';

import '../models/app_models.dart';
import '../theme/app_theme.dart';

class ToneBadge extends StatelessWidget {
  const ToneBadge({
    super.key,
    required this.label,
    required this.tone,
    this.size = ToneBadgeSize.medium,
  });

  final String label;
  final UiTone tone;
  final ToneBadgeSize size;

  @override
  Widget build(BuildContext context) {
    final EdgeInsetsGeometry padding = switch (size) {
      ToneBadgeSize.small => const EdgeInsets.symmetric(
        horizontal: 8,
        vertical: 4,
      ),
      ToneBadgeSize.medium => const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 6,
      ),
    };

    final double fontSize = switch (size) {
      ToneBadgeSize.small => 12,
      ToneBadgeSize.medium => 13,
    };

    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: AppTheme.toneContainer(tone),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: AppTheme.toneColor(tone),
          fontSize: fontSize,
          fontWeight: FontWeight.w500,
          height: 1.333,
        ),
      ),
    );
  }
}

enum ToneBadgeSize { small, medium }
