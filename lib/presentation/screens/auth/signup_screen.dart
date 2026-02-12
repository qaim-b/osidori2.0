import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/common/starry_background.dart';
import '../../widgets/common/app_button.dart';
import '../../widgets/common/app_text_field.dart';

class SignupScreen extends ConsumerStatefulWidget {
  const SignupScreen({super.key});

  @override
  ConsumerState<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends ConsumerState<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirm = true;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _onSignUp() {
    if (!_formKey.currentState!.validate()) return;

    ref
        .read(authStateProvider.notifier)
        .signUp(
          email: _emailController.text.trim(),
          password: _passwordController.text,
          name: _nameController.text.trim(),
        );
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authStateProvider);
    final isLoading = authState.isLoading;

    ref.listen(authStateProvider, (prev, next) {
      if (next.valueOrNull != null) {
        // After signup, go to role selection
        context.go('/onboarding');
      }
    });

    return Scaffold(
      body: StarryBackground(
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(height: 32),

                    // Stitch & Angel mascots
                    SvgPicture.asset(
                      'assets/images/stitchangel.svg',
                      height: 120,
                      fit: BoxFit.contain,
                    ),

                    const SizedBox(height: 12),
                    const CloudDecoration(),
                    const SizedBox(height: 16),

                    ShaderMask(
                      shaderCallback: (bounds) =>
                          AppColors.stitchGradient.createShader(bounds),
                      child: Text(
                        'Join ${AppConstants.appName}',
                        style: Theme.of(context).textTheme.headlineMedium
                            ?.copyWith(color: Colors.white),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Start tracking together',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),

                    const SizedBox(height: 32),

                    AppTextField(
                      controller: _nameController,
                      hintText: 'Your name',
                      prefixIcon: Icons.person_outline,
                      validator: (v) {
                        if (v == null || v.isEmpty) return 'Enter your name';
                        return null;
                      },
                    ),
                    const SizedBox(height: 14),

                    AppTextField(
                      controller: _emailController,
                      hintText: 'Email',
                      prefixIcon: Icons.email_outlined,
                      keyboardType: TextInputType.emailAddress,
                      validator: (v) {
                        if (v == null || v.isEmpty) return 'Enter your email';
                        if (!v.contains('@')) return 'Invalid email';
                        return null;
                      },
                    ),
                    const SizedBox(height: 14),

                    AppTextField(
                      controller: _passwordController,
                      hintText: 'Password',
                      prefixIcon: Icons.lock_outline,
                      obscureText: _obscurePassword,
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined,
                          size: 20,
                        ),
                        onPressed: () => setState(
                          () => _obscurePassword = !_obscurePassword,
                        ),
                      ),
                      validator: (v) {
                        if (v == null || v.isEmpty) return 'Enter a password';
                        if (v.length < 6) return 'At least 6 characters';
                        return null;
                      },
                    ),
                    const SizedBox(height: 14),

                    AppTextField(
                      controller: _confirmPasswordController,
                      hintText: 'Confirm password',
                      prefixIcon: Icons.lock_outline,
                      obscureText: _obscureConfirm,
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscureConfirm
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined,
                          size: 20,
                        ),
                        onPressed: () =>
                            setState(() => _obscureConfirm = !_obscureConfirm),
                      ),
                      validator: (v) {
                        if (v != _passwordController.text) {
                          return 'Passwords do not match';
                        }
                        return null;
                      },
                    ),

                    if (authState.hasError) ...[
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.error.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.error_outline,
                              color: AppColors.error,
                              size: 18,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                authState.error.toString(),
                                style: const TextStyle(
                                  color: AppColors.error,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

                    const SizedBox(height: 28),

                    AppButton(
                      label: 'Create Account',
                      onPressed: _onSignUp,
                      isLoading: isLoading,
                      useGradient: true,
                    ),

                    const SizedBox(height: 16),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Already have an account? ',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        GestureDetector(
                          onTap: () => context.go('/login'),
                          child: Text(
                            'Sign In',
                            style: TextStyle(
                              color: AppColors.stitchBlue,
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
