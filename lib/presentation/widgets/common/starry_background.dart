import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';

/// Clean editorial background for auth/onboarding surfaces.
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
    final bg = Theme.of(context).scaffoldBackgroundColor;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: bg,
      ),
      child: child,
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
