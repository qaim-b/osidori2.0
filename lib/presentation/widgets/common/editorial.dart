import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_colors.dart';

class SectionLabel extends StatelessWidget {
  final String text;
  final EdgeInsetsGeometry padding;

  const SectionLabel({
    super.key,
    required this.text,
    this.padding = const EdgeInsets.fromLTRB(20, 8, 20, 10),
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding,
      child: Row(
        children: [
          const Expanded(child: Divider(color: AppColors.border, thickness: 1)),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Text(
              text.toUpperCase(),
              style: GoogleFonts.ibmPlexMono(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                letterSpacing: 1.6,
                color: AppColors.accent,
              ),
            ),
          ),
          const Expanded(child: Divider(color: AppColors.border, thickness: 1)),
        ],
      ),
    );
  }
}

class EditorialCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final bool accentTop;

  const EditorialCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.accentTop = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin ?? const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border),
        boxShadow: const [
          BoxShadow(
            color: AppColors.shadow,
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (accentTop)
            Container(
              height: 2,
              decoration: const BoxDecoration(
                color: AppColors.accent,
                borderRadius: BorderRadius.vertical(top: Radius.circular(8)),
              ),
            ),
          Padding(
            padding: padding ?? const EdgeInsets.all(16),
            child: child,
          ),
        ],
      ),
    );
  }
}

class DisplayNumber extends StatelessWidget {
  final String value;
  final Color? color;
  final double size;

  const DisplayNumber({
    super.key,
    required this.value,
    this.color,
    this.size = 34,
  });

  @override
  Widget build(BuildContext context) {
    return Text(
      value,
      style: GoogleFonts.playfairDisplay(
        fontSize: size,
        height: 1.12,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.5,
        color: color ?? AppColors.foreground,
      ),
    );
  }
}
