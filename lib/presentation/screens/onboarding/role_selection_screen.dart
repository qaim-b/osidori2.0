import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/common/animated_mascot.dart';

/// After signup, user picks: are you Stitch (boy) or Angel (girl)?
/// This sets the entire app theme.
class RoleSelectionScreen extends ConsumerStatefulWidget {
  const RoleSelectionScreen({super.key});

  @override
  ConsumerState<RoleSelectionScreen> createState() =>
      _RoleSelectionScreenState();
}

class _RoleSelectionScreenState extends ConsumerState<RoleSelectionScreen> {
  String? _selectedRole;
  bool _saving = false;

  Future<void> _confirm() async {
    if (_selectedRole == null) return;
    setState(() => _saving = true);

    try {
      await ref.read(authStateProvider.notifier).setRole(_selectedRole!);
      if (mounted) context.go('/');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppColors.stitchBg,
              Colors.white,
              AppColors.angelBg,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              children: [
                const Spacer(flex: 2),

                // Title
                Text(
                  'Who are you?',
                  style: Theme.of(context).textTheme.headlineLarge,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'Choose your character — this sets your app theme!',
                  style: Theme.of(context).textTheme.bodyMedium,
                  textAlign: TextAlign.center,
                ),

                const Spacer(),

                // Two character cards side by side
                Row(
                  children: [
                    // Stitch (Boy)
                    Expanded(
                      child: _CharacterCard(
                        imagePath: 'assets/images/stitch.png',
                        name: 'Stitch',
                        subtitle: 'Boy',
                        color: AppColors.stitchBlue,
                        bgColor: AppColors.stitchBg,
                        gradient: AppColors.stitchGradient,
                        isSelected: _selectedRole == 'stitch',
                        onTap: () =>
                            setState(() => _selectedRole = 'stitch'),
                      ),
                    ),
                    const SizedBox(width: 16),
                    // Angel (Girl)
                    Expanded(
                      child: _CharacterCard(
                        imagePath: 'assets/images/angel.png',
                        name: 'Angel',
                        subtitle: 'Girl',
                        color: AppColors.angelPink,
                        bgColor: AppColors.angelBg,
                        gradient: AppColors.angelGradient,
                        isSelected: _selectedRole == 'angel',
                        onTap: () =>
                            setState(() => _selectedRole = 'angel'),
                      ),
                    ),
                  ],
                ),

                const Spacer(),

                // Animated preview of selected character
                if (_selectedRole != null)
                  AnimatedMascot(
                    imagePath: _selectedRole == 'stitch'
                        ? 'assets/images/stitch.png'
                        : 'assets/images/angel.png',
                    size: 80,
                    glowColor: _selectedRole == 'stitch'
                        ? AppColors.stitchBlue
                        : AppColors.angelPink,
                  ),
                if (_selectedRole == null)
                  const SizedBox(height: 80),

                const Spacer(),

                // Confirm button
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    decoration: BoxDecoration(
                      gradient: _selectedRole == null
                          ? null
                          : (_selectedRole == 'stitch'
                              ? AppColors.stitchGradient
                              : AppColors.angelGradient),
                      color: _selectedRole == null
                          ? AppColors.divider
                          : null,
                      borderRadius: BorderRadius.circular(28),
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: _selectedRole == null || _saving
                            ? null
                            : _confirm,
                        borderRadius: BorderRadius.circular(28),
                        child: Center(
                          child: _saving
                              ? const SizedBox(
                                  height: 24,
                                  width: 24,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2.5,
                                  ),
                                )
                              : Text(
                                  _selectedRole != null
                                      ? "I'm ${_selectedRole == 'stitch' ? 'Stitch' : 'Angel'}!"
                                      : 'Pick your character',
                                  style: TextStyle(
                                    color: _selectedRole != null
                                        ? Colors.white
                                        : AppColors.textHint,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                        ),
                      ),
                    ),
                  ),
                ),

                const Spacer(flex: 2),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CharacterCard extends StatelessWidget {
  final String imagePath;
  final String name;
  final String subtitle;
  final Color color;
  final Color bgColor;
  final LinearGradient gradient;
  final bool isSelected;
  final VoidCallback onTap;

  const _CharacterCard({
    required this.imagePath,
    required this.name,
    required this.subtitle,
    required this.color,
    required this.bgColor,
    required this.gradient,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 16),
        decoration: BoxDecoration(
          color: isSelected ? null : bgColor,
          gradient: isSelected ? gradient : null,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isSelected ? color : Colors.transparent,
            width: 3,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: color.withValues(alpha: 0.3),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ]
              : null,
        ),
        child: Column(
          children: [
            Image.asset(
              imagePath,
              height: isSelected ? 80 : 64,
              fit: BoxFit.contain,
            ),
            const SizedBox(height: 12),
            Text(
              name,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: isSelected ? Colors.white : color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 14,
                color: isSelected
                    ? Colors.white.withValues(alpha: 0.8)
                    : AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
