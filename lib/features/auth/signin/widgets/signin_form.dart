import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../widgets/error_banner.dart';
import '../../widgets/hover_button.dart';
import '../../../../core/widgets/app_logo.dart';
import '../../../../core/providers/branding_provider.dart';
import 'package:provider/provider.dart';
import '../../../../core/utils/validation_utils.dart';

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
  final VoidCallback onForgotPasswordTap;

  const SigninForm({
    super.key,
    required this.emailController,
    required this.passwordController,
    required this.isLoading,
    required this.errorMessage,
    required this.onSignin,
    required this.onDismissError,
    required this.onSignupTap,
    required this.onForgotPasswordTap,
  });

  @override
  State<SigninForm> createState() => _SigninFormState();
}

class _SigninFormState extends State<SigninForm> {
  final _formKey = GlobalKey<FormState>();
  bool _obscurePassword = true;

  void _submitForm() {
    if (_formKey.currentState!.validate()) {
      widget.onSignin();
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

          // Password field with show/hide toggle
          TextFormField(
            controller: widget.passwordController,
            obscureText: _obscurePassword,
            textInputAction: TextInputAction.done,
            onFieldSubmitted: (_) => _submitForm(),
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
              if (value == null || value.trim().isEmpty) {
                return 'Password is required.';
              }
              return null;
            },
          ),

          const SizedBox(height: 12),

          // Forgot Password link
          Align(
            alignment: Alignment.centerRight,
            child: GestureDetector(
              onTap: widget.onForgotPasswordTap,
              child: Text(
                'Forgot Password?',
                style: AppTheme.bodySmall.copyWith(
                  color: AppTheme.primaryBrown,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),

          const SizedBox(height: 28),

          // Signin button
          HoverButton(
            onTap: widget.isLoading ? null : _submitForm,
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
      ),
    );
  }
}
