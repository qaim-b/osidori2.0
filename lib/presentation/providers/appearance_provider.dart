import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

enum AppThemePreset {
  defaultNeutral,
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
  AppThemePreset.defaultNeutral: ThemePresetData(
    label: 'Default',
    primary: Color(0xFF1E5B62),
    secondary: Color(0xFF5FA6A5),
    background: Color(0xFFF6F2EB),
    surface: Color(0xFFFFFFFF),
    surfaceVariant: Color(0xFFECE3D8),
  ),
  AppThemePreset.lightBlue: ThemePresetData(
    label: 'Light Blue',
    primary: Color(0xFF2F6FA2),
    secondary: Color(0xFF6FA8D6),
    background: Color(0xFFF2F6FA),
    surface: Color(0xFFFFFFFF),
    surfaceVariant: Color(0xFFE5EDF4),
  ),
  AppThemePreset.sage: ThemePresetData(
    label: 'Sage',
    primary: Color(0xFF3F7E6B),
    secondary: Color(0xFF8BB5A6),
    background: Color(0xFFF1F6F1),
    surface: Color(0xFFFFFFFF),
    surfaceVariant: Color(0xFFE3EFE7),
  ),
  AppThemePreset.lightPink: ThemePresetData(
    label: 'Light Pink',
    primary: Color(0xFFC2577D),
    secondary: Color(0xFFE3A3BD),
    background: Color(0xFFFFF3F7),
    surface: Color(0xFFFFFFFF),
    surfaceVariant: Color(0xFFF8E2EC),
  ),
  AppThemePreset.beige: ThemePresetData(
    label: 'Beige',
    primary: Color(0xFF9C6A4D),
    secondary: Color(0xFFCFAE91),
    background: Color(0xFFFBF5EE),
    surface: Color(0xFFFFFFFF),
    surfaceVariant: Color(0xFFF1E4D7),
  ),
  AppThemePreset.chill: ThemePresetData(
    label: 'Chill',
    primary: Color(0xFF3E6A73),
    secondary: Color(0xFF86A7AD),
    background: Color(0xFFF0F5F6),
    surface: Color(0xFFFFFFFF),
    surfaceVariant: Color(0xFFE3ECEE),
  ),
};

final themePresetProvider = StateProvider<AppThemePreset>(
  (ref) => AppThemePreset.defaultNeutral,
);

final activeThemePresetDataProvider = Provider<ThemePresetData>((ref) {
  final preset = ref.watch(themePresetProvider);
  return themePresetMap[preset]!;
});
