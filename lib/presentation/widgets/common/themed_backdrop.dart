import 'package:flutter/material.dart';

class ThemedBackdrop extends StatelessWidget {
  final Widget child;

  const ThemedBackdrop({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final bg = Theme.of(context).scaffoldBackgroundColor;
    return DecoratedBox(
      decoration: BoxDecoration(color: bg),
      child: child,
    );
  }
}
