import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'auth_provider.dart';
import '../../core/theme/app_colors.dart';

/// Dynamic theme based on user's role (Stitch=blue, Angel=pink).
final userRoleProvider = Provider<String>((ref) {
  final user = ref.watch(authStateProvider).valueOrNull;
  return user?.role ?? 'stitch';
});

final primaryColorProvider = Provider<Color>((ref) {
  final role = ref.watch(userRoleProvider);
  return role == 'angel' ? AppColors.angelPink : AppColors.stitchBlue;
});

final roleColorsProvider = Provider<RoleColors>((ref) {
  final role = ref.watch(userRoleProvider);
  return role == 'angel' ? RoleColors.angel() : RoleColors.stitch();
});

class RoleColors {
  final Color primary;
  final Color primaryLight;
  final Color primaryDark;
  final Color accent;
  final Color background;
  final LinearGradient gradient;
  final String mascotEmoji;
  final String mascotName;
  final String mascotImage;

  const RoleColors({
    required this.primary,
    required this.primaryLight,
    required this.primaryDark,
    required this.accent,
    required this.background,
    required this.gradient,
    required this.mascotEmoji,
    required this.mascotName,
    required this.mascotImage,
  });

  factory RoleColors.stitch() => const RoleColors(
        primary: AppColors.stitchBlue,
        primaryLight: AppColors.stitchBlueLight,
        primaryDark: AppColors.stitchBlueDark,
        accent: AppColors.stitchAccent,
        background: AppColors.stitchBg,
        gradient: AppColors.stitchGradient,
        mascotEmoji: '👾',
        mascotName: 'Stitch',
        mascotImage: 'assets/images/stitch.png',
      );

  factory RoleColors.angel() => const RoleColors(
        primary: AppColors.angelPink,
        primaryLight: AppColors.angelPinkLight,
        primaryDark: AppColors.angelPinkDark,
        accent: AppColors.angelAccent,
        background: AppColors.angelBg,
        gradient: AppColors.angelGradient,
        mascotEmoji: '🩷',
        mascotName: 'Angel',
        mascotImage: 'assets/images/angel.png',
      );
}
