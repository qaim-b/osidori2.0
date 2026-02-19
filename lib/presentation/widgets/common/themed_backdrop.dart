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
    return DecoratedBox(
      decoration: const BoxDecoration(
        color: AppColors.background,
      ),
      child: Stack(
        children: [
          Positioned(
            top: 92,
            left: 20,
            right: 20,
            child: IgnorePointer(
              child: Container(height: 1, color: AppColors.border),
            ),
          ),
          child,
        ],
      ),
    );
  }
}
