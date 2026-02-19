import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_colors.dart';

/// Styled text field aligned with the Serif design system.
class AppTextField extends StatelessWidget {
  final TextEditingController? controller;
  final String? hintText;
  final String? labelText;
  final IconData? prefixIcon;
  final Widget? suffixIcon;
  final bool obscureText;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;
  final ValueChanged<String>? onChanged;
  final bool autofocus;
  final TextInputAction textInputAction;
  final bool autocorrect;
  final bool enableSuggestions;

  const AppTextField({
    super.key,
    this.controller,
    this.hintText,
    this.labelText,
    this.prefixIcon,
    this.suffixIcon,
    this.obscureText = false,
    this.keyboardType,
    this.validator,
    this.onChanged,
    this.autofocus = false,
    this.textInputAction = TextInputAction.next,
    this.autocorrect = false,
    this.enableSuggestions = true,
  });

  @override
  Widget build(BuildContext context) {
    final isSmallScreen = MediaQuery.sizeOf(context).width < 390;
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      keyboardAppearance: Theme.of(context).brightness,
      textInputAction: textInputAction,
      autocorrect: autocorrect,
      enableSuggestions: enableSuggestions,
      validator: validator,
      onChanged: onChanged,
      autofocus: autofocus,
      style: GoogleFonts.sourceSans3(
        fontSize: isSmallScreen ? 15 : 16,
        height: 1.6,
        letterSpacing: 0.12,
        color: AppColors.foreground,
      ),
      scrollPadding: const EdgeInsets.only(bottom: 96),
      decoration: InputDecoration(
        hintText: hintText,
        labelText: labelText?.toUpperCase(),
        isDense: true,
        constraints: const BoxConstraints(minHeight: 44),
        contentPadding: EdgeInsets.symmetric(
          horizontal: isSmallScreen ? 14 : 16,
          vertical: isSmallScreen ? 12 : 14,
        ),
        prefixIcon: prefixIcon != null
            ? Icon(prefixIcon, size: 18, color: AppColors.mutedForeground)
            : null,
        suffixIcon: suffixIcon,
      ),
    );
  }
}
