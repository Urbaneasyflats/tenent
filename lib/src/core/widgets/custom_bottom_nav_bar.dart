import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class CustomBottomNavItem {
  const CustomBottomNavItem({
    required this.label,
    required this.icon,
    this.floating = false,
  });

  final String label;
  final IconData icon;
  // kept for API compatibility, no longer used
  final bool floating;
}

class CustomBottomNavBar extends StatelessWidget {
  const CustomBottomNavBar({
    super.key,
    required this.items,
    required this.selectedIndex,
    required this.onSelected,
  });

  final List<CustomBottomNavItem> items;
  final int selectedIndex;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: AppTheme.border)),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 58,
          child: Row(
            children: List<Widget>.generate(items.length, (int index) {
              return Expanded(
                child: _NavItem(
                  item: items[index],
                  selected: selectedIndex == index,
                  onTap: () => onSelected(index),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.item,
    required this.selected,
    required this.onTap,
  });

  final CustomBottomNavItem item;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final Color color =
        selected ? AppTheme.primary : AppTheme.textMuted;

    return InkWell(
      onTap: onTap,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          if (selected)
            Container(
              width: 28,
              height: 3,
              margin: const EdgeInsets.only(bottom: 6),
              decoration: BoxDecoration(
                color: AppTheme.primary,
                borderRadius: BorderRadius.circular(2),
              ),
            )
          else
            const SizedBox(height: 9),
          Icon(item.icon, size: 22, color: color),
          const SizedBox(height: 4),
          Text(
            item.label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 11,
              fontWeight:
                  selected ? FontWeight.w700 : FontWeight.w500,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
