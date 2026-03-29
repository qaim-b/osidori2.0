import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
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
    final showLightBackdrop = kIsWeb;

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
            color: theme.colorScheme.primary.withValues(
              alpha: showLightBackdrop ? 0.11 : 0.18,
            ),
            size: showLightBackdrop ? 220 : 260,
          ),
        ),
        Positioned(
          top: 120,
          right: -120,
          child: _GlowBlob(
            color: theme.colorScheme.secondary.withValues(
              alpha: showLightBackdrop ? 0.11 : 0.18,
            ),
            size: showLightBackdrop ? 240 : 300,
          ),
        ),
        Positioned(
          bottom: -120,
          left: 40,
          child: _GlowBlob(
            color: theme.colorScheme.primary.withValues(
              alpha: showLightBackdrop ? 0.08 : 0.12,
            ),
            size: showLightBackdrop ? 190 : 240,
          ),
        ),
        if (showCountryBanner)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: IgnorePointer(
              child: Opacity(
                opacity: isMalaysia
                    ? (showLightBackdrop ? 0.42 : 0.56)
                    : (showLightBackdrop ? 0.2 : 0.32),
                child: SizedBox(
                  height: showLightBackdrop ? 180 : 220,
                  child: SvgPicture.asset(
                    bannerAsset,
                    fit: BoxFit.fitWidth,
                    alignment: Alignment.topCenter,
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

  const _GlowBlob({required this.color, required this.size});

  @override
  Widget build(BuildContext context) {
    final colors = [color, color.withValues(alpha: 0.02)];
    return IgnorePointer(
      child: SizedBox(
        height: size,
        width: size,
        child: DecoratedBox(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(colors: colors),
          ),
        ),
      ),
    );
  }
}
