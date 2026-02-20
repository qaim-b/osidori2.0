import 'package:flutter/animation.dart';

/// Shared motion tokens for consistent animations across the app.
class AppMotion {
  AppMotion._();

  static const Duration fast = Duration(milliseconds: 180);
  static const Duration normal = Duration(milliseconds: 260);
  static const Duration reveal = Duration(milliseconds: 320);
  static const Duration entrance = Duration(milliseconds: 700);

  static const Curve smooth = Curves.easeOutCubic;
  static const Curve pop = Curves.easeOutBack;
  static const Curve dismiss = Curves.easeInCubic;
}
