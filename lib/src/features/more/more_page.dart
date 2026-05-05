import 'package:flutter/material.dart';

import '../../core/models/app_models.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/custom_card.dart';
import '../../core/widgets/tone_badge.dart';

class MorePage extends StatelessWidget {
  const MorePage({
    super.key,
    required this.role,
    required this.modules,
    required this.onModuleSelected,
    required this.onLogout,
  });

  final AppRole role;
  final List<ModuleStatusItem> modules;
  final ValueChanged<ModuleStatusItem> onModuleSelected;
  final VoidCallback onLogout;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    // Split modules into ready and coming-soon
    final List<ModuleStatusItem> readyModules =
        modules.where((ModuleStatusItem m) => m.readyNow).toList();
    final List<ModuleStatusItem> comingModules =
        modules.where((ModuleStatusItem m) => !m.readyNow).toList();

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 124),
      children: <Widget>[
        // Profile card
        _ProfileCard(role: role, onLogout: onLogout),
        const SizedBox(height: 24),

        // Ready modules grid
        if (readyModules.isNotEmpty) ...<Widget>[
          Text(
            'Modules',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          _ModuleGrid(
            modules: readyModules,
            onModuleSelected: onModuleSelected,
            tone: UiTone.brand,
          ),
          const SizedBox(height: 20),
        ],

        // Coming-soon modules (collapsed, lighter style)
        if (comingModules.isNotEmpty) ...<Widget>[
          Text(
            'Coming soon',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
              color: AppTheme.textSecondary,
            ),
          ),
          const SizedBox(height: 10),
          _ModuleGrid(
            modules: comingModules,
            onModuleSelected: onModuleSelected,
            tone: UiTone.neutral,
            dimmed: true,
          ),
        ],
      ],
    );
  }
}

class _ProfileCard extends StatelessWidget {
  const _ProfileCard({required this.role, required this.onLogout});

  final AppRole role;
  final VoidCallback onLogout;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return CustomCard(
      child: Column(
        children: <Widget>[
          Row(
            children: <Widget>[
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: AppTheme.primarySoft,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(role.icon, color: AppTheme.primary, size: 26),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      role.label,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const ToneBadge(label: 'Live session', tone: UiTone.success),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(height: 1, color: AppTheme.border),
          const SizedBox(height: 14),
          _SettingsRow(
            icon: Icons.logout_outlined,
            label: 'Sign out',
            color: const Color(0xFFDC2626),
            onTap: onLogout,
          ),
        ],
      ),
    );
  }
}

class _SettingsRow extends StatelessWidget {
  const _SettingsRow({
    required this.icon,
    required this.label,
    required this.onTap,
    this.color,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final Color effectiveColor = color ?? AppTheme.textSecondary;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          children: <Widget>[
            Icon(icon, size: 20, color: effectiveColor),
            const SizedBox(width: 12),
            Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: effectiveColor,
                    fontWeight: FontWeight.w500,
                  ),
            ),
            const Spacer(),
            Icon(Icons.chevron_right_rounded, size: 18, color: effectiveColor),
          ],
        ),
      ),
    );
  }
}

class _ModuleGrid extends StatelessWidget {
  const _ModuleGrid({
    required this.modules,
    required this.onModuleSelected,
    required this.tone,
    this.dimmed = false,
  });

  final List<ModuleStatusItem> modules;
  final ValueChanged<ModuleStatusItem> onModuleSelected;
  final UiTone tone;
  final bool dimmed;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final Color iconBg = dimmed ? AppTheme.surfaceMuted : AppTheme.toneSoft(tone);
    final Color iconColor =
        dimmed ? AppTheme.textMuted : AppTheme.toneColor(tone);

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: modules.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.0,
      ),
      itemBuilder: (BuildContext context, int index) {
        final ModuleStatusItem module = modules[index];
        return GestureDetector(
          onTap: () => onModuleSelected(module),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.border),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: iconBg,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(module.icon, color: iconColor, size: 22),
                ),
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  child: Text(
                    module.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.labelSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: dimmed ? AppTheme.textMuted : AppTheme.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class ModulePlaceholderPage extends StatelessWidget {
  const ModulePlaceholderPage({super.key, required this.module});

  final ModuleStatusItem module;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        titleSpacing: 16,
        title: Text(module.title),
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1, thickness: 1, color: AppTheme.border),
        ),
      ),
      body: ListView(
        padding: AppTheme.pagePadding,
        children: <Widget>[
          CustomCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: AppTheme.toneSoft(UiTone.warning),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    module.icon,
                    color: AppTheme.toneColor(UiTone.warning),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  module.title,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  module.subtitle,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppTheme.textSecondary,
                      ),
                ),
                const SizedBox(height: 14),
                ToneBadge(
                  label: 'Module status: ${module.phaseLabel}',
                  tone: UiTone.warning,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
