import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';
import '../../presentation/providers/appearance_provider.dart';

/// Editorial serif theme system.
class AppTheme {
  AppTheme._();

  static ThemeData light(ThemePresetData preset) {
    const radiusMd = Radius.circular(6);
    const radiusLg = Radius.circular(8);

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
      splashFactory: InkRipple.splashFactory,
    );

    return base.copyWith(
      textTheme: _textTheme(base.textTheme),
      appBarTheme: AppBarTheme(
        backgroundColor: preset.background,
        foregroundColor: AppColors.foreground,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: GoogleFonts.playfairDisplay(
          fontSize: 24,
          fontWeight: FontWeight.w500,
          color: AppColors.foreground,
          letterSpacing: -0.2,
        ),
      ),
      cardTheme: CardThemeData(
        color: preset.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: const BorderRadius.all(radiusLg),
          side: const BorderSide(color: AppColors.border),
        ),
        shadowColor: AppColors.shadow,
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ButtonStyle(
          minimumSize: const WidgetStatePropertyAll(Size(44, 44)),
          padding: const WidgetStatePropertyAll(
            EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          ),
          elevation: const WidgetStatePropertyAll(0),
          shape: const WidgetStatePropertyAll(
            RoundedRectangleBorder(
              borderRadius: BorderRadius.all(radiusMd),
            ),
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
          foregroundColor: const WidgetStatePropertyAll(AppColors.accentForeground),
          overlayColor: WidgetStatePropertyAll(
            AppColors.accentForeground.withValues(alpha: 0.08),
          ),
          textStyle: WidgetStatePropertyAll(
            GoogleFonts.sourceSans3(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.4,
            ),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: ButtonStyle(
          minimumSize: const WidgetStatePropertyAll(Size(44, 44)),
          padding: const WidgetStatePropertyAll(
            EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          ),
          side: WidgetStateProperty.resolveWith((states) {
            final color = states.contains(WidgetState.hovered)
                ? preset.primary
                : AppColors.foreground;
            return BorderSide(color: color);
          }),
          shape: const WidgetStatePropertyAll(
            RoundedRectangleBorder(
              borderRadius: BorderRadius.all(radiusMd),
            ),
          ),
          foregroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.hovered)) return preset.primary;
            return AppColors.foreground;
          }),
          textStyle: WidgetStatePropertyAll(
            GoogleFonts.sourceSans3(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.35,
            ),
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.transparent,
        border: OutlineInputBorder(
          borderRadius: const BorderRadius.all(radiusMd),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: const BorderRadius.all(radiusMd),
          borderSide: const BorderSide(color: AppColors.border),
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
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        hintStyle: GoogleFonts.sourceSans3(
          color: AppColors.mutedForeground.withValues(alpha: 0.7),
          fontSize: 16,
          letterSpacing: 0.1,
        ),
        labelStyle: GoogleFonts.ibmPlexMono(
          color: AppColors.mutedForeground,
          fontSize: 12,
          fontWeight: FontWeight.w500,
          letterSpacing: 1.4,
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
        labelStyle: GoogleFonts.sourceSans3(
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

  static TextTheme _textTheme(TextTheme base) {
    return base.copyWith(
      displayLarge: GoogleFonts.playfairDisplay(
        fontSize: 46,
        height: 1.1,
        fontWeight: FontWeight.w500,
        letterSpacing: -0.9,
        color: AppColors.foreground,
      ),
      displayMedium: GoogleFonts.playfairDisplay(
        fontSize: 38,
        height: 1.15,
        fontWeight: FontWeight.w500,
        letterSpacing: -0.5,
        color: AppColors.foreground,
      ),
      headlineLarge: GoogleFonts.playfairDisplay(
        fontSize: 32,
        height: 1.2,
        fontWeight: FontWeight.w500,
        letterSpacing: -0.35,
        color: AppColors.foreground,
      ),
      headlineMedium: GoogleFonts.playfairDisplay(
        fontSize: 28,
        height: 1.2,
        fontWeight: FontWeight.w500,
        letterSpacing: -0.25,
        color: AppColors.foreground,
      ),
      titleLarge: GoogleFonts.playfairDisplay(
        fontSize: 22,
        height: 1.3,
        fontWeight: FontWeight.w600,
        color: AppColors.foreground,
      ),
      titleMedium: GoogleFonts.sourceSans3(
        fontSize: 16,
        height: 1.5,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.35,
        color: AppColors.foreground,
      ),
      bodyLarge: GoogleFonts.sourceSans3(
        fontSize: 17,
        height: 1.75,
        fontWeight: FontWeight.w400,
        letterSpacing: 0.16,
        color: AppColors.foreground,
      ),
      bodyMedium: GoogleFonts.sourceSans3(
        fontSize: 16,
        height: 1.72,
        fontWeight: FontWeight.w400,
        letterSpacing: 0.14,
        color: AppColors.mutedForeground,
      ),
      labelLarge: GoogleFonts.sourceSans3(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.6,
        color: AppColors.accentForeground,
      ),
      labelMedium: GoogleFonts.ibmPlexMono(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        letterSpacing: 1.6,
        color: AppColors.accent,
      ),
    );
  }
}
