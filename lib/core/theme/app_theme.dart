import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';
import '../../presentation/providers/appearance_provider.dart';

/// Editorial Luxe theme system.
class AppTheme {
  AppTheme._();

  static TextStyle _font({
    double? fontSize,
    double? height,
    FontWeight? fontWeight,
    double? letterSpacing,
    Color? color,
  }) {
    return GoogleFonts.manrope(
      fontSize: fontSize,
      height: height,
      fontWeight: fontWeight,
      letterSpacing: letterSpacing,
      color: color,
    );
  }

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
      splashFactory: InkRipple.splashFactory,
    );
    final textTheme = _textTheme(base.textTheme, preset);

    return base.copyWith(
      textTheme: textTheme,
      appBarTheme: AppBarTheme(
        backgroundColor: preset.background,
        foregroundColor: preset.primary,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: _font(
          fontSize: 22,
          fontWeight: FontWeight.w800,
          color: preset.primary,
          letterSpacing: -0.35,
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
            _font(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.1,
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
            _font(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.1,
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
        hintStyle: _font(
          color: AppColors.mutedForeground.withValues(alpha: 0.7),
          fontSize: 15,
          letterSpacing: -0.05,
        ),
        labelStyle: _font(
          color: AppColors.mutedForeground,
          fontSize: 11,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.1,
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
        labelStyle: _font(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.05,
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
      displayLarge: _font(
        fontSize: 42,
        height: 1.02,
        fontWeight: FontWeight.w800,
        letterSpacing: -0.9,
        color: preset.primary,
      ),
      displayMedium: _font(
        fontSize: 34,
        height: 1.06,
        fontWeight: FontWeight.w800,
        letterSpacing: -0.75,
        color: preset.primary,
      ),
      headlineLarge: _font(
        fontSize: 28,
        height: 1.1,
        fontWeight: FontWeight.w800,
        letterSpacing: -0.6,
        color: preset.primary,
      ),
      headlineMedium: _font(
        fontSize: 24,
        height: 1.12,
        fontWeight: FontWeight.w800,
        letterSpacing: -0.45,
        color: preset.primary,
      ),
      titleLarge: _font(
        fontSize: 20,
        height: 1.18,
        fontWeight: FontWeight.w800,
        letterSpacing: -0.3,
        color: preset.primary,
      ),
      titleMedium: _font(
        fontSize: 15,
        height: 1.28,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.08,
        color: preset.primary,
      ),
      bodyLarge: _font(
        fontSize: 15,
        height: 1.4,
        fontWeight: FontWeight.w500,
        letterSpacing: -0.05,
        color: AppColors.foreground,
      ),
      bodyMedium: _font(
        fontSize: 14,
        height: 1.38,
        fontWeight: FontWeight.w500,
        letterSpacing: -0.03,
        color: AppColors.mutedForeground,
      ),
      labelLarge: _font(
        fontSize: 13,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.05,
        color: AppColors.accentForeground,
      ),
      labelMedium: _font(
        fontSize: 11,
        fontWeight: FontWeight.w600,
        letterSpacing: 0,
        color: AppColors.accent,
      ),
    );
  }
}
