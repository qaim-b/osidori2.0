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
    final bannerAsset = currency == 'MYR'
        ? 'assets/images/banner_malaysia.svg'
        : 'assets/images/banner_japan.svg';
    final bannerTint = theme.colorScheme.primary.withValues(alpha: 0.22);

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
                    alpha: 0.55,
                  ),
                  theme.scaffoldBackgroundColor,
                ],
              ),
            ),
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
                    colorFilter: ColorFilter.mode(bannerTint, BlendMode.srcIn),
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
