import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/providers/branding_provider.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_logo.dart';
import '../../widgets/hover_button.dart';

class VerifyPhoneForm extends StatelessWidget {
  final TextEditingController phoneController;
  final TextEditingController otpController;
  final bool consentAccepted;
  final ValueChanged<bool?> onConsentChanged;
  final bool codeSent;
  final bool isSendingCode;
  final bool isVerifyingCode;
  final int resendSeconds;
  final String? message;
  final bool isSuccess;
  final VoidCallback onSendCode;
  final VoidCallback onVerifyCode;
  final VoidCallback onBack;

  const VerifyPhoneForm({
    super.key,
    required this.phoneController,
    required this.otpController,
    required this.consentAccepted,
    required this.onConsentChanged,
    required this.codeSent,
    required this.isSendingCode,
    required this.isVerifyingCode,
    required this.resendSeconds,
    required this.message,
    required this.isSuccess,
    required this.onSendCode,
    required this.onVerifyCode,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    final branding = context.watch<BrandingProvider>().branding;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Center(
          child: AppLogo(
            logoUrl: branding.logoUrl,
            appName: branding.appName,
            size: 80,
          ),
        ),
        const SizedBox(height: 28),
        Text(
          'Verify Your Phone',
          style: AppTheme.displayMedium,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 10),
        Text(
          'We use a verified phone for order confirmation, checkout, and delivery updates.',
          style: AppTheme.bodyMedium,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 28),
        if (message != null) ...[
          _StatusBanner(message: message!, isSuccess: isSuccess),
          const SizedBox(height: 18),
        ],
        TextFormField(
          controller: phoneController,
          keyboardType: TextInputType.phone,
          style: AppTheme.bodyLarge,
          decoration:
              AppTheme.inputDecoration(
                label: 'Indian Mobile Number',
                hint: '9876543210',
              ).copyWith(
                prefixIcon: Padding(
                  padding: const EdgeInsets.only(left: 18, right: 10),
                  child: Text(
                    '+91',
                    style: AppTheme.bodyLarge.copyWith(
                      color: AppTheme.primaryBrown,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                prefixIconConstraints: const BoxConstraints(
                  minWidth: 0,
                  minHeight: 0,
                ),
              ),
        ),
        const SizedBox(height: 16),
        if (codeSent) ...[
          TextFormField(
            controller: otpController,
            keyboardType: TextInputType.number,
            maxLength: 6,
            style: AppTheme.bodyLarge,
            decoration: AppTheme.inputDecoration(
              label: 'OTP',
              hint: 'Enter the 6-digit code',
            ).copyWith(counterText: ''),
          ),
          const SizedBox(height: 16),
        ],
        CheckboxListTile(
          value: consentAccepted,
          onChanged: onConsentChanged,
          contentPadding: EdgeInsets.zero,
          activeColor: AppTheme.terracotta,
          controlAffinity: ListTileControlAffinity.leading,
          title: Text(
            'I agree to receive a one-time SMS for phone verification and understand that Firebase may use this for abuse prevention.',
            style: AppTheme.bodySmall.copyWith(
              color: AppTheme.textDark,
              height: 1.5,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'We only use your verified phone for address, checkout, delivery coordination, and account security.',
          style: AppTheme.bodySmall,
        ),
        const SizedBox(height: 24),
        HoverButton(
          onTap: (codeSent ? isVerifyingCode : isSendingCode)
              ? null
              : (codeSent ? onVerifyCode : onSendCode),
          isLoading: codeSent ? isVerifyingCode : isSendingCode,
          label: codeSent ? 'Verify OTP' : 'Send OTP',
        ),
        const SizedBox(height: 16),
        if (codeSent)
          HoverButton(
            onTap: resendSeconds == 0 && !isSendingCode ? onSendCode : null,
            isSecondary: true,
            label: resendSeconds == 0
                ? 'Resend OTP'
                : 'Resend in ${resendSeconds}s',
          ),
        const SizedBox(height: 18),
        TextButton(onPressed: onBack, child: const Text('Back')),
      ],
    );
  }
}

class _StatusBanner extends StatelessWidget {
  final String message;
  final bool isSuccess;

  const _StatusBanner({required this.message, required this.isSuccess});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: (isSuccess ? AppTheme.successGreen : AppTheme.errorRed)
            .withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border(
          left: BorderSide(
            color: isSuccess ? AppTheme.successGreen : AppTheme.errorRed,
            width: 4,
          ),
        ),
      ),
      child: Row(
        children: [
          Icon(
            isSuccess ? Icons.verified_rounded : Icons.error_outline_rounded,
            color: isSuccess ? AppTheme.successGreen : AppTheme.errorRed,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: AppTheme.bodyMedium.copyWith(
                color: isSuccess ? AppTheme.successGreen : AppTheme.errorRed,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
