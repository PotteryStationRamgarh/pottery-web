import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../widgets/error_banner.dart';
import '../../widgets/hover_button.dart';
import '../../../../core/widgets/app_logo.dart';
import '../../../../core/providers/branding_provider.dart';
import 'package:provider/provider.dart';
import '../../../../core/utils/validation_utils.dart';

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
  final _formKey = GlobalKey<FormState>();
  final _passwordFieldKey = GlobalKey<FormFieldState<String>>();
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  void _submitForm() {
    if (_formKey.currentState!.validate()) {
      widget.onSignup();
    }
  }

  @override
  Widget build(BuildContext context) {
    final branding = context.watch<BrandingProvider>().branding;

    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Auth Logo — uses Firestore branding
          Center(
            child: AppLogo(
              logoUrl: branding.logoUrl,
              appName: branding.appName,
              size: 80,
            ),
          ),

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
          TextFormField(
            controller: widget.emailController,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
            style: AppTheme.bodyLarge,
            decoration: AppTheme.inputDecoration(
              label: 'Email Address',
              hint: 'you@example.com',
            ),
            validator: (value) {
              return ValidationUtils.validateEmail(value);
            },
          ),

          const SizedBox(height: 16),

          // Password field
          TextFormField(
            key: _passwordFieldKey,
            controller: widget.passwordController,
            obscureText: _obscurePassword,
            textInputAction: TextInputAction.next,
            onTapOutside: (_) => _passwordFieldKey.currentState?.validate(),
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
            validator: (value) {
              return ValidationUtils.validatePassword(value);
            },
          ),

          const SizedBox(height: 16),

          // Confirm password field
          TextFormField(
            controller: widget.confirmPasswordController,
            obscureText: _obscureConfirmPassword,
            textInputAction: TextInputAction.done,
            onFieldSubmitted: (_) => _submitForm(),
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
                    () => _obscureConfirmPassword = !_obscureConfirmPassword,
                  );
                },
              ),
            ),
            validator: (value) {
              if (value == null || value.isEmpty)
                return 'Please confirm your password';
              if (value != widget.passwordController.text)
                return 'Passwords do not match';
              return null;
            },
          ),

          const SizedBox(height: 28),

          // Signup button
          HoverButton(
            onTap: widget.isLoading ? null : _submitForm,
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
      ),
    );
  }
}
