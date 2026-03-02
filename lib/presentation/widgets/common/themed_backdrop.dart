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
    final currency = ref.watch(currentCurrencyProvider).toUpperCase();
    final bg = currency == 'MYR'
        ? const Color(0xFFEAF6FF)
        : const Color(0xFFFFF0F7);
    final bannerAsset = currency == 'MYR'
        ? 'assets/images/banner_malaysia.svg'
        : 'assets/images/banner_japan.svg';

    return Stack(
      children: [
        Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(color: bg),
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
