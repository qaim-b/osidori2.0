import 'package:flutter/material.dart';

/// Centralized design tokens for the Serif style system.
class AppColors {
  AppColors._();

  // Legacy role colors kept for category/owner semantics.
  static const Color stitchBlue = Color(0xFF2A52BE);
  static const Color stitchBlueLight = Color(0xFF6B8DD6);
  static const Color stitchBlueDark = Color(0xFF1A3A8A);
  static const Color stitchAccent = Color(0xFF4FC3F7);
  static const Color stitchBg = Color(0xFFEBF2FF);

  static const Color angelPink = Color(0xFFE91E8C);
  static const Color angelPinkLight = Color(0xFFF48DC2);
  static const Color angelPinkDark = Color(0xFFC2185B);
  static const Color angelAccent = Color(0xFFFF80AB);
  static const Color angelBg = Color(0xFFFDE8F0);

  static const Color soloMint = Color(0xFF4F9B8E);
  static const Color soloMintLight = Color(0xFF7DBFB4);
  static const Color soloMintDark = Color(0xFF2F6F66);
  static const Color soloAccent = Color(0xFF9CCB8A);
  static const Color soloBg = Color(0xFFEFF8F5);

  // Serif design system tokens.
  static const Color background = Color(0xFFFAFAF8); // ivory
  static const Color foreground = Color(0xFF1A1A1A); // rich black
  static const Color muted = Color(0xFFF5F3F0);
  static const Color mutedForeground = Color(0xFF6B6B6B);
  static const Color accent = Color(0xFFB8860B); // burnished gold
  static const Color accentSecondary = Color(0xFFD4A84B);
  static const Color accentForeground = Color(0xFFFFFFFF);
  static const Color border = Color(0xFFE8E4DF);
  static const Color card = Color(0xFFFFFFFF);
  static const Color ring = accent;

  // Theme aliases used throughout the app.
  static const Color primary = accent;
  static const Color primaryLight = accentSecondary;
  static const Color primaryDark = Color(0xFF8E6700);
  static const Color secondary = Color(0xFF8A7A65);
  static const Color secondaryLight = Color(0xFFA69884);
  static const Color secondaryDark = Color(0xFF6F6251);
  static const Color surface = card;
  static const Color surfaceVariant = muted;

  // Decorative accents.
  static const Color starYellow = Color(0xFFFFE066);
  static const Color starGold = Color(0xFFFFD700);
  static const Color cloudWhite = Color(0xFFF8F8FF);

  // Text aliases.
  static const Color textPrimary = foreground;
  static const Color textSecondary = mutedForeground;
  static const Color textHint = Color(0xFF9A938A);

  // Semantic
  static const Color income = Color(0xFF4CAF50);
  static const Color expense = Color(0xFFE53935);
  static const Color transfer = Color(0xFF2196F3);

  // Chart palette
  static const List<Color> chartPalette = [
    Color(0xFF5E60CE),
    Color(0xFF4361EE),
    Color(0xFF3A86FF),
    Color(0xFF00B4D8),
    Color(0xFF2A9D8F),
    Color(0xFF52B788),
    Color(0xFF80ED99),
    Color(0xFFF4A261),
    Color(0xFFE76F51),
    Color(0xFFEF476F),
    Color(0xFFFF006E),
    Color(0xFFB5179E),
  ];

  // Misc
  static const Color divider = border;
  static const Color error = Color(0xFFE53935);
  static const Color success = Color(0xFF4CAF50);
  static const Color warning = Color(0xFFFF9800);
  static const Color shadow = Color(0x14000000);

  // Gradients
  static const LinearGradient stitchGradient = LinearGradient(
    colors: [accent, accentSecondary],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient angelGradient = LinearGradient(
    colors: [accentSecondary, accent],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient soloGradient = LinearGradient(
    colors: [Color(0xFF7AA37A), Color(0xFFA7C4A0)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Legacy alias used in some widgets
  static const LinearGradient dreamyGradient = stitchGradient;
}
