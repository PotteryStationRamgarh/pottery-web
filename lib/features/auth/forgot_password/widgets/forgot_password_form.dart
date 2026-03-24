import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../widgets/error_banner.dart';
import '../../widgets/hover_button.dart';
import '../../../../core/widgets/logo_placeholder.dart';

class ForgotPasswordForm extends StatelessWidget {
  final TextEditingController emailController;
  final bool isLoading;
  final String? errorMessage;
  final String? successMessage;
  final VoidCallback onSendReset;
  final VoidCallback onDismissMessage;
  final VoidCallback onBackToSignin;

  const ForgotPasswordForm({
    super.key,
    required this.emailController,
    required this.isLoading,
    required this.errorMessage,
    required this.successMessage,
    required this.onSendReset,
    required this.onDismissMessage,
    required this.onBackToSignin,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        const Center(child: LogoPlaceholder(size: 80)),
        const SizedBox(height: 28),
        Text(
          'Reset Password',
          style: AppTheme.displayMedium,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          'Enter your email to receive a reset link',
          style: AppTheme.bodyMedium,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 36),

        if (errorMessage != null) ...[
          ErrorBanner(
            message: errorMessage!,
            onDismiss: onDismissMessage,
          ),
          const SizedBox(height: 20),
        ],

        if (successMessage != null) ...[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.green.withOpacity(0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.green.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                const Icon(Icons.check_circle_outline, color: Colors.green, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    successMessage!,
                    style: AppTheme.bodyMedium.copyWith(color: Colors.green[800]),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, size: 18, color: Colors.green),
                  onPressed: onDismissMessage,
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
        ],

        TextField(
          controller: emailController,
          keyboardType: TextInputType.emailAddress,
          style: AppTheme.bodyLarge,
          decoration: AppTheme.inputDecoration(
            label: 'Email Address',
            hint: 'you@example.com',
          ),
        ),
        const SizedBox(height: 28),
        HoverButton(
          onTap: isLoading ? null : onSendReset,
          isLoading: isLoading,
          label: 'Send Reset Link',
        ),
        const SizedBox(height: 24),
        GestureDetector(
          onTap: onBackToSignin,
          child: Text(
            'Back to Sign In',
            textAlign: TextAlign.center,
            style: AppTheme.bodyMedium.copyWith(
              color: AppTheme.primaryBrown,
              fontWeight: FontWeight.w600,
              decoration: TextDecoration.underline,
              decorationColor: AppTheme.primaryBrown,
            ),
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }
}
