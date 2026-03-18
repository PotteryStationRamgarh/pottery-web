import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../widgets/error_banner.dart';
import '../../widgets/hover_button.dart';
import '../../widgets/logo_placeholder.dart';

/// SignupForm — contains all form fields, error banner and button.
/// Mirrors LoginForm structure for consistency.
class SignupForm extends StatefulWidget {
  final TextEditingController emailController;
  final TextEditingController passwordController;
  final TextEditingController confirmPasswordController;
  final bool isLoading;
  final String? errorMessage;
  final VoidCallback onSignup;
  final VoidCallback onDismissError;
  final VoidCallback onSigninTap;

  const SignupForm({
    super.key,
    required this.emailController,
    required this.passwordController,
    required this.confirmPasswordController,
    required this.isLoading,
    required this.errorMessage,
    required this.onSignup,
    required this.onDismissError,
    required this.onSigninTap,
  });

  @override
  State<SignupForm> createState() => _SignupFormState();
}

class _SignupFormState extends State<SignupForm> {
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [

        // Logo placeholder
        const Center(child: LogoPlaceholder(size: 80)),

        const SizedBox(height: 28),

        // Heading
        Text(
          'Create Account',
          style: AppTheme.displayMedium,
          textAlign: TextAlign.center,
        ),

        const SizedBox(height: 8),

        // Subtitle
        Text(
          'Your story with clay starts here',
          style: AppTheme.bodyMedium,
          textAlign: TextAlign.center,
        ),

        const SizedBox(height: 36),

        // Error banner
        if (widget.errorMessage != null) ...[
          ErrorBanner(
            message: widget.errorMessage!,
            onDismiss: widget.onDismissError,
          ),
          const SizedBox(height: 20),
        ],

        // Email field
        TextField(
          controller: widget.emailController,
          keyboardType: TextInputType.emailAddress,
          style: AppTheme.bodyLarge,
          decoration: AppTheme.inputDecoration(
            label: 'Email Address',
            hint: 'you@example.com',
          ),
        ),

        const SizedBox(height: 16),

        // Password field
        TextField(
          controller: widget.passwordController,
          obscureText: _obscurePassword,
          style: AppTheme.bodyLarge,
          decoration: AppTheme.inputDecoration(
            label: 'Password',
            hint: '••••••••',
            suffixIcon: IconButton(
              icon: Icon(
                _obscurePassword
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined,
                color: AppTheme.textLight,
                size: 20,
              ),
              onPressed: () {
                setState(() => _obscurePassword = !_obscurePassword);
              },
            ),
          ),
        ),

        const SizedBox(height: 16),

        // Confirm password field
        TextField(
          controller: widget.confirmPasswordController,
          obscureText: _obscureConfirmPassword,
          style: AppTheme.bodyLarge,
          decoration: AppTheme.inputDecoration(
            label: 'Confirm Password',
            hint: '••••••••',
            suffixIcon: IconButton(
              icon: Icon(
                _obscureConfirmPassword
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined,
                color: AppTheme.textLight,
                size: 20,
              ),
              onPressed: () {
                setState(
                    () => _obscureConfirmPassword = !_obscureConfirmPassword);
              },
            ),
          ),
        ),

        const SizedBox(height: 28),

        // Signup button
        HoverButton(
          onTap: widget.isLoading ? null : widget.onSignup,
          isLoading: widget.isLoading,
          label: 'Create Account',
        ),

        const SizedBox(height: 20),

        // Divider
        Row(
          children: [
            const Expanded(child: Divider(color: AppTheme.borderColor)),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Text('or', style: AppTheme.bodyMedium),
            ),
            const Expanded(child: Divider(color: AppTheme.borderColor)),
          ],
        ),

        const SizedBox(height: 20),

        // Signin link
        GestureDetector(
          onTap: widget.onSigninTap,
          child: RichText(
            textAlign: TextAlign.center,
            text: TextSpan(
              style: AppTheme.bodyMedium,
              children: [
                const TextSpan(text: 'Already have an account? '),
                TextSpan(
                  text: 'Sign in',
                  style: AppTheme.bodyMedium.copyWith(
                    color: AppTheme.primaryBrown,
                    fontWeight: FontWeight.w600,
                    decoration: TextDecoration.underline,
                    decorationColor: AppTheme.primaryBrown,
                  ),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 24),
      ],
    );
  }
}