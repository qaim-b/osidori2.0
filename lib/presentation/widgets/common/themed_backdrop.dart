import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../providers/auth_provider.dart';

class ThemedBackdrop extends ConsumerWidget {
  final Widget child;
  final bool showCountryBanner;

  const ThemedBackdrop({
    super.key,
    required this.child,
    this.showCountryBanner = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final currency = ref.watch(currentCurrencyProvider).toUpperCase();
    final isMalaysia = currency == 'MYR';
    final bannerAsset = currency == 'MYR'
        ? 'assets/images/banner_malaysia.svg'
        : 'assets/images/banner_japan.svg';
    final bannerTint = theme.colorScheme.primary.withValues(alpha: 0.75);

    return Stack(
      children: [
        Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  theme.colorScheme.surfaceContainerHighest.withValues(
                    alpha: 0.65,
                  ),
                  theme.scaffoldBackgroundColor,
                ],
              ),
            ),
          ),
        ),
        Positioned(
          top: -140,
          left: -80,
          child: _GlowBlob(
            color: theme.colorScheme.primary.withValues(alpha: 0.18),
            size: 260,
          ),
        ),
        Positioned(
          top: 120,
          right: -120,
          child: _GlowBlob(
            color: theme.colorScheme.secondary.withValues(alpha: 0.18),
            size: 300,
          ),
        ),
        Positioned(
          bottom: -120,
          left: 40,
          child: _GlowBlob(
            color: theme.colorScheme.primary.withValues(alpha: 0.12),
            size: 240,
          ),
        ),
        if (showCountryBanner)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: IgnorePointer(
              child: Opacity(
                opacity: 0.32,
                child: SizedBox(
                  height: 220,
                  child: SvgPicture.asset(
                    bannerAsset,
                    fit: BoxFit.fitWidth,
                    alignment: Alignment.topCenter,
                    colorFilter: isMalaysia
                        ? ColorFilter.mode(bannerTint, BlendMode.modulate)
                        : null,
                  ),
                ),
              ),
            ),
          ),
        child,
      ],
    );
  }
}

class _GlowBlob extends StatelessWidget {
  final Color color;
  final double size;

  const _GlowBlob({
    required this.color,
    required this.size,
  });

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        height: size,
        width: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [
              color,
              color.withValues(alpha: 0.02),
            ],
          ),
        ),
      ),
    );
  }
}
