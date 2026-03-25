import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';
import '../../presentation/providers/appearance_provider.dart';

/// Editorial Luxe theme system.
class AppTheme {
  AppTheme._();

  static ThemeData light(ThemePresetData preset) {
    const radiusMd = Radius.circular(12);
    const radiusLg = Radius.circular(16);

    final colorScheme = ColorScheme.light(
      primary: preset.primary,
      secondary: preset.secondary,
      surface: preset.surface,
      error: AppColors.error,
      onPrimary: AppColors.accentForeground,
      onSecondary: AppColors.accentForeground,
      onSurface: AppColors.foreground,
    );

    final base = ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: preset.background,
      dividerColor: AppColors.border,
      splashFactory: InkSparkle.splashFactory,
    );
    final textTheme = _textTheme(base.textTheme, preset);

    return base.copyWith(
      textTheme: textTheme,
      appBarTheme: AppBarTheme(
        backgroundColor: preset.background,
        foregroundColor: preset.primary,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: GoogleFonts.inter(
          fontSize: 24,
          fontWeight: FontWeight.w700,
          color: preset.primary,
          letterSpacing: -0.2,
        ),
      ),
      cardTheme: CardThemeData(
        color: preset.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: const BorderRadius.all(radiusLg),
          side: BorderSide(color: AppColors.border.withValues(alpha: 0.7)),
        ),
        shadowColor: AppColors.shadow,
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ButtonStyle(
          minimumSize: const WidgetStatePropertyAll(Size(48, 48)),
          padding: const WidgetStatePropertyAll(
            EdgeInsets.symmetric(horizontal: 22, vertical: 14),
          ),
          elevation: const WidgetStatePropertyAll(0),
          shape: const WidgetStatePropertyAll(
            RoundedRectangleBorder(borderRadius: BorderRadius.all(radiusMd)),
          ),
          backgroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.disabled)) {
              return preset.primary.withValues(alpha: 0.45);
            }
            if (states.contains(WidgetState.pressed)) return preset.primary;
            if (states.contains(WidgetState.hovered)) {
              return preset.secondary;
            }
            return preset.primary;
          }),
          foregroundColor: const WidgetStatePropertyAll(
            AppColors.accentForeground,
          ),
          overlayColor: WidgetStatePropertyAll(
            AppColors.accentForeground.withValues(alpha: 0.08),
          ),
          textStyle: WidgetStatePropertyAll(
            GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.2,
            ),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: ButtonStyle(
          minimumSize: const WidgetStatePropertyAll(Size(48, 48)),
          padding: const WidgetStatePropertyAll(
            EdgeInsets.symmetric(horizontal: 22, vertical: 14),
          ),
          side: WidgetStateProperty.resolveWith((states) {
            final color = states.contains(WidgetState.hovered)
                ? preset.primary
                : AppColors.foreground;
            return BorderSide(color: color);
          }),
          shape: const WidgetStatePropertyAll(
            RoundedRectangleBorder(borderRadius: BorderRadius.all(radiusMd)),
          ),
          foregroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.hovered)) return preset.primary;
            return AppColors.foreground;
          }),
          textStyle: WidgetStatePropertyAll(
            GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.2,
            ),
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: preset.surfaceVariant.withValues(alpha: 0.6),
        border: OutlineInputBorder(
          borderRadius: const BorderRadius.all(radiusMd),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: const BorderRadius.all(radiusMd),
          borderSide: BorderSide(
            color: AppColors.border.withValues(alpha: 0.85),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: const BorderRadius.all(radiusMd),
          borderSide: BorderSide(color: preset.primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: const BorderRadius.all(radiusMd),
          borderSide: const BorderSide(color: AppColors.error, width: 1.5),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: const BorderRadius.all(radiusMd),
          borderSide: const BorderSide(color: AppColors.error, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        hintStyle: GoogleFonts.inter(
          color: AppColors.mutedForeground.withValues(alpha: 0.7),
          fontSize: 16,
          letterSpacing: 0.1,
        ),
        labelStyle: GoogleFonts.inter(
          color: AppColors.mutedForeground,
          fontSize: 12,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.3,
        ),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: AppColors.accent,
        foregroundColor: AppColors.accentForeground,
        elevation: 0,
        shape: CircleBorder(),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: preset.surface,
        selectedItemColor: preset.primary,
        unselectedItemColor: AppColors.mutedForeground,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.border,
        thickness: 1,
      ),
      chipTheme: ChipThemeData(
        backgroundColor: preset.surfaceVariant,
        selectedColor: preset.primary.withValues(alpha: 0.12),
        labelStyle: GoogleFonts.inter(
          fontSize: 13,
          color: AppColors.foreground,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: const BorderRadius.all(radiusMd),
          side: const BorderSide(color: AppColors.border),
        ),
        side: const BorderSide(color: AppColors.border),
      ),
    );
  }

  static TextTheme _textTheme(TextTheme base, ThemePresetData preset) {
    return base.copyWith(
      displayLarge: GoogleFonts.inter(
        fontSize: 44,
        height: 1.08,
        fontWeight: FontWeight.w800,
        letterSpacing: -0.6,
        color: preset.primary,
      ),
      displayMedium: GoogleFonts.inter(
        fontSize: 36,
        height: 1.12,
        fontWeight: FontWeight.w800,
        letterSpacing: -0.45,
        color: preset.primary,
      ),
      headlineLarge: GoogleFonts.inter(
        fontSize: 30,
        height: 1.18,
        fontWeight: FontWeight.w800,
        letterSpacing: -0.35,
        color: preset.primary,
      ),
      headlineMedium: GoogleFonts.inter(
        fontSize: 26,
        height: 1.2,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.2,
        color: preset.primary,
      ),
      titleLarge: GoogleFonts.inter(
        fontSize: 22,
        height: 1.28,
        fontWeight: FontWeight.w700,
        color: preset.primary,
      ),
      titleMedium: GoogleFonts.inter(
        fontSize: 16,
        height: 1.5,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.2,
        color: preset.primary,
      ),
      bodyLarge: GoogleFonts.inter(
        fontSize: 17,
        height: 1.7,
        fontWeight: FontWeight.w400,
        letterSpacing: 0.1,
        color: AppColors.foreground,
      ),
      bodyMedium: GoogleFonts.inter(
        fontSize: 16,
        height: 1.68,
        fontWeight: FontWeight.w400,
        letterSpacing: 0.08,
        color: AppColors.mutedForeground,
      ),
      labelLarge: GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.3,
        color: AppColors.accentForeground,
      ),
      labelMedium: GoogleFonts.inter(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.3,
        color: AppColors.accent,
      ),
    );
  }
}
