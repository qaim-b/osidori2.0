import 'dart:math';
import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';

/// Soft editorial background for auth/onboarding surfaces.
class StarryBackground extends StatelessWidget {
  final Widget child;
  final bool showStars;

  const StarryBackground({
    super.key,
    required this.child,
    this.showStars = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.background,
            Color(0xFFF7F4EE),
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: showStars
          ? Stack(
              children: [
                const IgnorePointer(child: _FloatingStars()),
                child,
              ],
            )
          : child,
    );
  }
}

class _FloatingStars extends StatelessWidget {
  const _FloatingStars();

  @override
  Widget build(BuildContext context) {
    final random = Random(42);
    final size = MediaQuery.of(context).size;

    return Stack(
      children: List.generate(16, (i) {
        final x = random.nextDouble() * size.width;
        final y = random.nextDouble() * size.height * 0.55;
        final dotSize = 4.0 + random.nextDouble() * 8;
        final opacity = 0.08 + random.nextDouble() * 0.15;

        return Positioned(
          left: x,
          top: y,
          child: Opacity(
            opacity: opacity,
            child: Container(
              width: dotSize,
              height: dotSize,
              decoration: BoxDecoration(
                color: i.isEven ? AppColors.accent : AppColors.mutedForeground,
                shape: BoxShape.circle,
              ),
            ),
          ),
        );
      }),
    );
  }
}

class CloudDecoration extends StatelessWidget {
  const CloudDecoration({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _cloud(60),
        const SizedBox(width: 8),
        _cloud(40),
        const SizedBox(width: 12),
        _cloud(50),
      ],
    );
  }

  Widget _cloud(double width) {
    return Container(
      width: width,
      height: width * 0.5,
      decoration: BoxDecoration(
        color: AppColors.card.withValues(alpha: 0.75),
        borderRadius: BorderRadius.circular(width),
        border: Border.all(color: AppColors.border),
      ),
    );
  }
}
