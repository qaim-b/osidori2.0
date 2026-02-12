import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

enum AppThemePreset {
  lightBlue,
  sage,
  lightPink,
  beige,
  chill,
}

class ThemePresetData {
  final String label;
  final Color primary;
  final Color secondary;
  final Color background;
  final Color surface;
  final Color surfaceVariant;

  const ThemePresetData({
    required this.label,
    required this.primary,
    required this.secondary,
    required this.background,
    required this.surface,
    required this.surfaceVariant,
  });
}

const themePresetMap = <AppThemePreset, ThemePresetData>{
  AppThemePreset.lightBlue: ThemePresetData(
    label: 'Light Blue',
    primary: Color(0xFF4A90E2),
    secondary: Color(0xFF7FB3FF),
    background: Color(0xFFF3F8FF),
    surface: Color(0xFFFFFFFF),
    surfaceVariant: Color(0xFFEAF2FF),
  ),
  AppThemePreset.sage: ThemePresetData(
    label: 'Sage',
    primary: Color(0xFF7AA37A),
    secondary: Color(0xFFA7C4A0),
    background: Color(0xFFF3F8F2),
    surface: Color(0xFFFFFFFF),
    surfaceVariant: Color(0xFFEAF3E8),
  ),
  AppThemePreset.lightPink: ThemePresetData(
    label: 'Light Pink',
    primary: Color(0xFFE78FB3),
    secondary: Color(0xFFF2B4CF),
    background: Color(0xFFFFF5FA),
    surface: Color(0xFFFFFFFF),
    surfaceVariant: Color(0xFFFFEAF3),
  ),
  AppThemePreset.beige: ThemePresetData(
    label: 'Beige',
    primary: Color(0xFFB08A6A),
    secondary: Color(0xFFD4BFA6),
    background: Color(0xFFFAF6F0),
    surface: Color(0xFFFFFFFF),
    surfaceVariant: Color(0xFFF3EBDD),
  ),
  AppThemePreset.chill: ThemePresetData(
    label: 'Chill',
    primary: Color(0xFF6D8FA3),
    secondary: Color(0xFF9DB7C5),
    background: Color(0xFFF1F6F9),
    surface: Color(0xFFFFFFFF),
    surfaceVariant: Color(0xFFE6EEF3),
  ),
};

final themePresetProvider = StateProvider<AppThemePreset>(
  (ref) => AppThemePreset.lightBlue,
);

final activeThemePresetDataProvider = Provider<ThemePresetData>((ref) {
  final preset = ref.watch(themePresetProvider);
  return themePresetMap[preset]!;
});
