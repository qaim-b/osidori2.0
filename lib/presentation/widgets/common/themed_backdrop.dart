import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';

class ThemedBackdrop extends StatelessWidget {
  final Widget child;

  const ThemedBackdrop({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppColors.background,
                Color(0xFFF8F6F2),
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
        ),
        Positioned(
          top: -140,
          right: -100,
          child: IgnorePointer(
            child: Container(
              width: 320,
              height: 320,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.accent.withValues(alpha: 0.03),
              ),
            ),
          ),
        ),
        Positioned(
          top: 92,
          left: 24,
          right: 24,
          child: IgnorePointer(
            child: Container(height: 1, color: AppColors.border),
          ),
        ),
        child,
      ],
    );
  }
}
