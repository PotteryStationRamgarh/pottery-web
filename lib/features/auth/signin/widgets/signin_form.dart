import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../widgets/error_banner.dart';
import '../../widgets/hover_button.dart';
import '../../widgets/logo_placeholder.dart';

/// signinForm — contains all form fields, error banner and button.
/// Kept separate from SigninScreen so screen file stays clean.
class SigninForm extends StatefulWidget {
  final TextEditingController emailController;
  final TextEditingController passwordController;
  final bool isLoading;
  final String? errorMessage;
  final VoidCallback onSignin;
  final VoidCallback onDismissError;
  final VoidCallback onSignupTap;

  const SigninForm({
    super.key,
    required this.emailController,
    required this.passwordController,
    required this.isLoading,
    required this.errorMessage,
    required this.onSignin,
    required this.onDismissError,
    required this.onSignupTap,
  });

  @override
  State<SigninForm> createState() => _SigninFormState();
}

class _SigninFormState extends State<SigninForm> {
  bool _obscurePassword = true;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [

        // Logo placeholder — circle with ? icon
        const Center(child: LogoPlaceholder(size: 80)),

        const SizedBox(height: 28),

        // Welcome heading
        Text(
          'Welcome Back',
          style: AppTheme.displayMedium,
          textAlign: TextAlign.center,
        ),

        const SizedBox(height: 8),

        // Subtitle
        Text(
          'Welcome back to the wheel',
          style: AppTheme.bodyMedium,
          textAlign: TextAlign.center,
        ),

        const SizedBox(height: 36),

        // Error banner — only visible when error exists
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

        // Password field with show/hide toggle
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

        const SizedBox(height: 28),

        // Signin button
        HoverButton(
          onTap: widget.isLoading ? null : widget.onSignin,
          isLoading: widget.isLoading,
          label: 'Sign In',
        ),

        const SizedBox(height: 20),

        // Divider with or
        Row(
          children: [
            const Expanded(child: Divider(color: AppTheme.divider)),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Text('or', style: AppTheme.bodyMedium),
            ),
            const Expanded(child: Divider(color: AppTheme.divider)),
          ],
        ),

        const SizedBox(height: 20),

        // Signup link
        GestureDetector(
          onTap: widget.onSignupTap,
          child: RichText(
            textAlign: TextAlign.center,
            text: TextSpan(
              style: AppTheme.bodyMedium,
              children: [
                const TextSpan(text: "Don't have an account? "),
                TextSpan(
                  text: 'Sign up',
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