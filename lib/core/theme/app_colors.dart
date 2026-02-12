import 'package:flutter/material.dart';

/// Stitch & Angel themed color palette.
/// Stitch = blue (boy/Qaim), Angel = pink (girl/Mami).
class AppColors {
  AppColors._();

  // ── Stitch Blue (boy) ──
  static const Color stitchBlue = Color(0xFF2A52BE);
  static const Color stitchBlueLight = Color(0xFF6B8DD6);
  static const Color stitchBlueDark = Color(0xFF1A3A8A);
  static const Color stitchAccent = Color(0xFF4FC3F7);
  static const Color stitchBg = Color(0xFFEBF2FF);

  // ── Angel Pink (girl) ──
  static const Color angelPink = Color(0xFFE91E8C);
  static const Color angelPinkLight = Color(0xFFF48DC2);
  static const Color angelPinkDark = Color(0xFFC2185B);
  static const Color angelAccent = Color(0xFFFF80AB);
  static const Color angelBg = Color(0xFFFDE8F0);

  // Solo / chill vibe
  static const Color soloMint = Color(0xFF4F9B8E);
  static const Color soloMintLight = Color(0xFF7DBFB4);
  static const Color soloMintDark = Color(0xFF2F6F66);
  static const Color soloAccent = Color(0xFF9CCB8A);
  static const Color soloBg = Color(0xFFEFF8F5);

  // ── Default / shared (Stitch blue as default) ──
  static const Color primary = stitchBlue;
  static const Color primaryLight = stitchBlueLight;
  static const Color primaryDark = stitchBlueDark;
  static const Color secondary = angelPink;
  static const Color secondaryLight = angelPinkLight;
  static const Color secondaryDark = angelPinkDark;

  // Backgrounds
  static const Color background = Color(0xFFF5F7FA);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceVariant = Color(0xFFF0F2F8);

  // Starry accents
  static const Color starYellow = Color(0xFFFFE066);
  static const Color starGold = Color(0xFFFFD700);
  static const Color cloudWhite = Color(0xFFF8F8FF);

  // Text
  static const Color textPrimary = Color(0xFF1A1D2E);
  static const Color textSecondary = Color(0xFF6B7085);
  static const Color textHint = Color(0xFFA0A5BD);

  // Semantic
  static const Color income = Color(0xFF4CAF50);
  static const Color expense = Color(0xFFE53935);
  static const Color transfer = Color(0xFF2196F3);

  // Chart palette
  static const List<Color> chartPalette = [
    Color(0xFF2A52BE), // stitch blue
    Color(0xFFE91E8C), // angel pink
    Color(0xFFFFE066), // yellow
    Color(0xFF7C4DFF), // purple
    Color(0xFF4CAF50), // green
    Color(0xFFFF9800), // orange
    Color(0xFF4FC3F7), // light blue
    Color(0xFFF48DC2), // rose
    Color(0xFF26A69A), // teal
    Color(0xFFAB47BC), // violet
    Color(0xFF8BC34A), // lime
    Color(0xFFFF7043), // deep orange
    Color(0xFF29B6F6), // sky
    Color(0xFFEC407A), // magenta
    Color(0xFF66BB6A), // leaf
    Color(0xFFFFCA28), // amber
  ];

  // Misc
  static const Color divider = Color(0xFFE0E0E0);
  static const Color error = Color(0xFFE53935);
  static const Color success = Color(0xFF4CAF50);
  static const Color warning = Color(0xFFFF9800);
  static const Color shadow = Color(0x1A000000);

  // Gradients
  static const LinearGradient stitchGradient = LinearGradient(
    colors: [stitchBlue, stitchAccent],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient angelGradient = LinearGradient(
    colors: [angelPink, angelAccent],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient soloGradient = LinearGradient(
    colors: [soloMint, soloAccent],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Legacy alias used in some widgets
  static const LinearGradient dreamyGradient = stitchGradient;
}
