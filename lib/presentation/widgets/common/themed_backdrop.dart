import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../providers/auth_provider.dart';

class ThemedBackdrop extends ConsumerWidget {
  final Widget child;

  const ThemedBackdrop({super.key, required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bg = Theme.of(context).scaffoldBackgroundColor;
    final currency = ref.watch(currentCurrencyProvider).toUpperCase();
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
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: IgnorePointer(
            child: Opacity(
              opacity: 0.2,
              child: SizedBox(
                height: 120,
                child: SvgPicture.asset(
                  bannerAsset,
                  fit: BoxFit.cover,
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

