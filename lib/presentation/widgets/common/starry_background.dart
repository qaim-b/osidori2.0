import 'package:flutter/material.dart';

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
      decoration: BoxDecoration(color: bg),
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
        _cloud(context, 60),
        const SizedBox(width: 8),
        _cloud(context, 40),
        const SizedBox(width: 12),
        _cloud(context, 50),
      ],
    );
  }

  Widget _cloud(BuildContext context, double width) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      width: width,
      height: width * 0.5,
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(width),
      ),
    );
  }
}
