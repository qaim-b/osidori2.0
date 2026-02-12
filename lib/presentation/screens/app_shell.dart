import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../providers/appearance_provider.dart';

/// Main app shell with Osidori-style 5-tab bottom nav:
/// Home | Summary | + Input | Budget | Calendar
class AppShell extends ConsumerWidget {
  final StatefulNavigationShell navigationShell;

  const AppShell({super.key, required this.navigationShell});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final preset = ref.watch(activeThemePresetDataProvider);

    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: preset.surface,
          boxShadow: [
            BoxShadow(
              color: AppColors.shadow,
              blurRadius: 12,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _NavItem(
                  index: 0,
                  currentIndex: navigationShell.currentIndex,
                  icon: Icons.home_rounded,
                  label: 'Home',
                  activeColor: preset.primary,
                  onTap: () => navigationShell.goBranch(0),
                ),
                _NavItem(
                  index: 1,
                  currentIndex: navigationShell.currentIndex,
                  icon: Icons.analytics_rounded,
                  label: 'Summary',
                  activeColor: preset.primary,
                  onTap: () => navigationShell.goBranch(1),
                ),
                // Center add button
                _AddButton(
                  gradient: LinearGradient(
                    colors: [preset.primary, preset.secondary],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  glowColor: preset.primary,
                  onTap: () => context.push('/add'),
                ),
                _NavItem(
                  index: 2,
                  currentIndex: navigationShell.currentIndex,
                  icon: Icons.pie_chart_rounded,
                  label: 'Budget',
                  activeColor: preset.primary,
                  onTap: () => navigationShell.goBranch(2),
                ),
                _NavItem(
                  index: 3,
                  currentIndex: navigationShell.currentIndex,
                  icon: Icons.calendar_month_rounded,
                  label: 'Calendar',
                  activeColor: preset.primary,
                  onTap: () => navigationShell.goBranch(3),
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
  final int index;
  final int currentIndex;
  final IconData icon;
  final String label;
  final Color activeColor;
  final VoidCallback onTap;

  const _NavItem({
    required this.index,
    required this.currentIndex,
    required this.icon,
    required this.label,
    required this.activeColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isSelected = index == currentIndex;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? activeColor.withValues(alpha: 0.1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: isSelected ? 24 : 22,
              color: isSelected ? activeColor : AppColors.textHint,
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                color: isSelected ? activeColor : AppColors.textHint,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AddButton extends StatelessWidget {
  final LinearGradient gradient;
  final Color glowColor;
  final VoidCallback onTap;

  const _AddButton({
    required this.gradient,
    required this.glowColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          gradient: gradient,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: glowColor.withValues(alpha: 0.3),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: const Icon(Icons.add, color: Colors.white, size: 28),
      ),
    );
  }
}
