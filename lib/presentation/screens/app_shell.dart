import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/theme/app_colors.dart';

/// Main app shell with bottom navigation:
/// Home | Summary | + Input | Budget | Calendar
class AppShell extends StatelessWidget {
  final StatefulNavigationShell navigationShell;

  const AppShell({super.key, required this.navigationShell});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      extendBody: true,
      body: navigationShell,
      bottomNavigationBar: ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: scheme.surface,
            border: Border(
              top: BorderSide(color: AppColors.border.withValues(alpha: 0.9)),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.06),
                blurRadius: 10,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: SafeArea(
            top: false,
            minimum: const EdgeInsets.fromLTRB(10, 8, 10, 10),
            child: Row(
              children: [
                Expanded(
                  child: _NavItem(
                    label: 'Home',
                    icon: Icons.home_rounded,
                    selected: navigationShell.currentIndex == 0,
                    onTap: () => navigationShell.goBranch(0),
                  ),
                ),
                Expanded(
                  child: _NavItem(
                    label: 'Summary',
                    icon: Icons.analytics_rounded,
                    selected: navigationShell.currentIndex == 1,
                    onTap: () => navigationShell.goBranch(1),
                  ),
                ),
                _AddButton(onTap: () => context.push('/add')),
                Expanded(
                  child: _NavItem(
                    label: 'Budget',
                    icon: Icons.pie_chart_rounded,
                    selected: navigationShell.currentIndex == 2,
                    onTap: () => navigationShell.goBranch(2),
                  ),
                ),
                Expanded(
                  child: _NavItem(
                    label: 'Calendar',
                    icon: Icons.calendar_month_rounded,
                    selected: navigationShell.currentIndex == 3,
                    onTap: () => navigationShell.goBranch(3),
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

class _NavItem extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _NavItem({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return SizedBox(
      height: 52,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(10),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 20,
                color: selected
                    ? colorScheme.primary
                    : AppColors.mutedForeground,
              ),
              const SizedBox(height: 4),
              Container(
                height: 3,
                width: selected ? 16 : 6,
                decoration: BoxDecoration(
                  color: selected
                      ? colorScheme.primary
                      : AppColors.mutedForeground.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.manrope(
                  fontSize: 11,
                  fontWeight: selected ? FontWeight.w800 : FontWeight.w700,
                  letterSpacing: -0.08,
                  color: selected
                      ? colorScheme.primary
                      : AppColors.mutedForeground,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AddButton extends StatelessWidget {
  final VoidCallback onTap;

  const _AddButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return SizedBox(
      width: 56,
      height: 56,
      child: Material(
        color: colorScheme.primary,
        shape: const CircleBorder(),
        elevation: 2,
        shadowColor: colorScheme.primary.withValues(alpha: 0.4),
        child: InkWell(
          onTap: onTap,
          customBorder: const CircleBorder(),
          child: const Icon(Icons.add, color: AppColors.accentForeground),
        ),
      ),
    );
  }
}
