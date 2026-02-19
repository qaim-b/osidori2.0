import 'dart:ui';

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
    final bottomInset = MediaQuery.of(context).viewPadding.bottom;

    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: Padding(
        padding: EdgeInsets.only(bottom: bottomInset > 0 ? bottomInset : 8),
        child: ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: AppColors.card.withValues(alpha: 0.95),
                border: const Border(
                  top: BorderSide(color: AppColors.border),
                ),
              ),
              child: SafeArea(
                top: false,
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
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
    return SizedBox(
      height: 48,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(6),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 20,
                color: selected ? AppColors.accent : AppColors.mutedForeground,
              ),
              const SizedBox(height: 3),
              Text(
                label.toUpperCase(),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.ibmPlexMono(
                  fontSize: 10,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                  letterSpacing: 1.1,
                  color:
                      selected ? AppColors.accent : AppColors.mutedForeground,
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
    return SizedBox(
      width: 52,
      height: 52,
      child: Material(
        color: AppColors.accent,
        shape: const CircleBorder(),
        child: InkWell(
          onTap: onTap,
          customBorder: const CircleBorder(),
          child: const Icon(Icons.add, color: AppColors.accentForeground),
        ),
      ),
    );
  }
}
