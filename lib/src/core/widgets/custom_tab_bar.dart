import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

enum CustomTabBarStyle { underline, pill }

class CustomTabItem {
  const CustomTabItem({required this.label, this.icon, this.trailing});

  final String label;
  final IconData? icon;
  final Widget? trailing;
}

class CustomTabBar extends StatelessWidget {
  const CustomTabBar({
    super.key,
    required this.tabs,
    required this.currentIndex,
    required this.onChanged,
    this.style = CustomTabBarStyle.underline,
  });

  final List<CustomTabItem> tabs;
  final int currentIndex;
  final ValueChanged<int> onChanged;
  final CustomTabBarStyle style;

  @override
  Widget build(BuildContext context) {
    final Widget row = SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: List<Widget>.generate(tabs.length, (int index) {
          final CustomTabItem tab = tabs[index];
          final bool selected = index == currentIndex;
          return Padding(
            padding: EdgeInsets.only(
              right: style == CustomTabBarStyle.pill ? 8 : 24,
            ),
            child: _CustomTabButton(
              item: tab,
              selected: selected,
              style: style,
              onTap: () => onChanged(index),
            ),
          );
        }),
      ),
    );

    if (style == CustomTabBarStyle.underline) {
      return Container(
        decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: AppTheme.border)),
        ),
        child: row,
      );
    }

    return row;
  }
}

class _CustomTabButton extends StatelessWidget {
  const _CustomTabButton({
    required this.item,
    required this.selected,
    required this.style,
    required this.onTap,
  });

  final CustomTabItem item;
  final bool selected;
  final CustomTabBarStyle style;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final bool isUnderline = style == CustomTabBarStyle.underline;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: isUnderline ? 4 : 14,
            vertical: isUnderline ? 12 : 10,
          ),
          decoration: BoxDecoration(
            color: isUnderline
                ? Colors.transparent
                : selected
                ? AppTheme.primarySoft
                : Colors.transparent,
            borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
            border: isUnderline
                ? Border(
                    bottom: BorderSide(
                      color: selected ? AppTheme.primary : Colors.transparent,
                      width: 2,
                    ),
                  )
                : null,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              if (item.icon != null) ...<Widget>[
                Icon(
                  item.icon,
                  size: 16,
                  color: selected ? AppTheme.primary : AppTheme.textMuted,
                ),
                const SizedBox(width: 8),
              ],
              Text(
                item.label,
                style: TextStyle(
                  color: selected
                      ? (isUnderline
                            ? AppTheme.primary
                            : const Color(0xFF1D4ED8))
                      : AppTheme.textMuted,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  height: 1.429,
                ),
              ),
              if (item.trailing != null) ...<Widget>[
                const SizedBox(width: 8),
                item.trailing!,
              ],
            ],
          ),
        ),
      ),
    );
  }
}
