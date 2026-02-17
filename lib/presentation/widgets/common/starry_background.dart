import 'dart:math';
import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';

/// Dreamy starry background widget — Little Twin Stars style.
/// Renders floating stars and soft gradient background.
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
            Color(0xFFE8D5F5), // soft lavender top
            Color(0xFFF5F0FA), // light lavender
            Color(0xFFD4E8F8), // soft blue bottom
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: showStars
          ? Stack(
              children: [
                const IgnorePointer(
                  // Decorative layer only; never intercept taps.
                  child: _FloatingStars(),
                ),
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
    final random = Random(42); // Fixed seed for consistent star positions
    final size = MediaQuery.of(context).size;

    return Stack(
      children: List.generate(15, (i) {
        final x = random.nextDouble() * size.width;
        final y = random.nextDouble() * size.height * 0.6;
        final starSize = 8.0 + random.nextDouble() * 14;
        final opacity = 0.2 + random.nextDouble() * 0.4;

        return Positioned(
          left: x,
          top: y,
          child: Opacity(
            opacity: opacity,
            child: Text(
              i % 3 == 0 ? '⭐' : (i % 3 == 1 ? '✦' : '☆'),
              style: TextStyle(fontSize: starSize),
            ),
          ),
        );
      }),
    );
  }
}

/// Cloud decoration — used on auth screens
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
        color: AppColors.cloudWhite.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(width),
      ),
    );
  }
}
