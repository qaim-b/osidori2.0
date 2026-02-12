import 'package:flutter/material.dart';

class ThemedBackdrop extends StatelessWidget {
  final Widget child;

  const ThemedBackdrop({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final bg = Theme.of(context).scaffoldBackgroundColor;

    return Stack(
      children: [
        Container(color: bg),
        Positioned(
          top: -120,
          right: -80,
          child: Container(
            width: 260,
            height: 260,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: scheme.primary.withValues(alpha: 0.12),
            ),
          ),
        ),
        Positioned(
          bottom: -100,
          left: -70,
          child: Container(
            width: 220,
            height: 220,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: scheme.secondary.withValues(alpha: 0.10),
            ),
          ),
        ),
        child,
      ],
    );
  }
}
