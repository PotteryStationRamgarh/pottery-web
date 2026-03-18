import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';

/// ErrorBanner — styled error message shown inside auth forms.
/// Has left red border accent, icon, message and dismiss button.
/// Used across signin, signup, and any other auth screen.
class ErrorBanner extends StatelessWidget {
  final String message;
  final VoidCallback onDismiss;

  const ErrorBanner({
    super.key,
    required this.message,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      opacity: 1.0,
      duration: const Duration(milliseconds: 300),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        decoration: BoxDecoration(
          color: AppTheme.errorRed.withOpacity(0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border(
            left: BorderSide(
              color: AppTheme.errorRed,
              width: 4,
            ),
          ),
        ),
        child: Row(
          children: [
            // Error icon
            Icon(
              Icons.error_outline_rounded,
              color: AppTheme.errorRed,
              size: 20,
            ),

            const SizedBox(width: 12),

            // Error message text
            Expanded(
              child: Text(
                message,
                style: AppTheme.errorText,
              ),
            ),

            // Dismiss button
            GestureDetector(
              onTap: onDismiss,
              child: Icon(
                Icons.close_rounded,
                color: AppTheme.errorRed.withOpacity(0.6),
                size: 18,
              ),
            ),
          ],
        ),
      ),
    );
  }
}