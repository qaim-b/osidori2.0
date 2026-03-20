import 'package:flutter/material.dart';

  /// Centralized design tokens for the Editorial Luxe system.
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

  // Editorial Luxe design system tokens.
  static const Color background = Color(0xFFF6F2EB); // warm paper
  static const Color foreground = Color(0xFF141416); // ink black
  static const Color muted = Color(0xFFEFE7DD);
  static const Color mutedForeground = Color(0xFF6B6357);
  static const Color accent = Color(0xFF0E6B68); // deep teal
  static const Color accentSecondary = Color(0xFF6BC4B3); // seafoam
  static const Color accentForeground = Color(0xFFFFFFFF);
  static const Color border = Color(0xFFE2D6C8);
  static const Color card = Color(0xFFFFFFFF);
  static const Color ring = accent;

  // Theme aliases used throughout the app.
  static const Color primary = accent;
  static const Color primaryLight = accentSecondary;
  static const Color primaryDark = Color(0xFF09504E);
  static const Color secondary = Color(0xFFB86A3E); // sunbaked clay
  static const Color secondaryLight = Color(0xFFE1A07C);
  static const Color secondaryDark = Color(0xFF8A4C28);
  static const Color surface = card;
  static const Color surfaceVariant = muted;

  // Decorative accents.
  static const Color starYellow = Color(0xFFFFE09A);
  static const Color starGold = Color(0xFFF7C56A);
  static const Color cloudWhite = Color(0xFFF9F7F3);

  // Text aliases.
  static const Color textPrimary = foreground;
  static const Color textSecondary = mutedForeground;
  static const Color textHint = Color(0xFF9E9386);

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
  static const Color shadow = Color(0x1A000000);

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
    colors: [Color(0xFF4F8F7A), Color(0xFF8AC7B2)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Legacy alias used in some widgets
  static const LinearGradient dreamyGradient = stitchGradient;
}
