import 'package:flutter/material.dart';

/// Styled text field matching the Kiki & Lala dreamy theme.
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
      style: Theme.of(
        context,
      ).textTheme.bodyLarge?.copyWith(fontSize: isSmallScreen ? 14 : 15),
      scrollPadding: const EdgeInsets.only(bottom: 96),
      decoration: InputDecoration(
        hintText: hintText,
        labelText: labelText,
        isDense: true,
        contentPadding: EdgeInsets.symmetric(
          horizontal: isSmallScreen ? 14 : 16,
          vertical: isSmallScreen ? 10 : 12,
        ),
        prefixIcon: prefixIcon != null ? Icon(prefixIcon, size: 20) : null,
        suffixIcon: suffixIcon,
      ),
    );
  }
}
