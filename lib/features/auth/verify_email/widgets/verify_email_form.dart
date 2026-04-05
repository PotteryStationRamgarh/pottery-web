import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_logo.dart';
import '../../../../core/providers/branding_provider.dart';
import 'package:provider/provider.dart';
import '../../../auth/widgets/hover_button.dart';

/// VerifyEmailForm — all the visible UI content for the verify email screen.
/// Zero logic here — everything is passed in via callbacks and state values
/// from VerifyEmailController through VerifyEmailScreen.
///
/// Shows:
/// - Logo + animated email icon
/// - Masked email address
/// - Spam hint
/// - Feedback message banner (success or error)
/// - "Resend" secondary button with live countdown
/// - "Sign out" text link
class VerifyEmailForm extends StatelessWidget {
  // State values from controller
  final String maskedEmail;
  final bool resendCooldown;
  final int cooldownSeconds;
  final String? message;
  final bool isSuccess;

  // Callbacks to controller methods
  final VoidCallback onResend;
  final VoidCallback onLogout;

  const VerifyEmailForm({
    super.key,
    required this.maskedEmail,
    required this.resendCooldown,
    required this.cooldownSeconds,
    required this.message,
    required this.isSuccess,
    required this.onResend,
    required this.onLogout,
  });

  @override
  Widget build(BuildContext context) {
    final branding = context.watch<BrandingProvider>().branding;

    return Column(
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

        // Animated email icon with spinning ring around it
        _buildEmailIcon(),

        const SizedBox(height: 20),

        // Heading
        Text(
          'Check Your Inbox',
          style: AppTheme.displayMedium,
          textAlign: TextAlign.center,
        ),

        const SizedBox(height: 8),

        Text(
          'We sent a verification link to',
          style: AppTheme.bodyMedium.copyWith(
            fontSize: 15,
            color: AppTheme.textDark,
          ),
          textAlign: TextAlign.center,
        ),

        const SizedBox(height: 4),

        // Masked email — shown for privacy
        Text(
          maskedEmail,
          style: AppTheme.bodyLarge.copyWith(
            color: AppTheme.primaryBrown,
            fontWeight: FontWeight.w600,
          ),
          textAlign: TextAlign.center,
        ),

        const SizedBox(height: 12),

        Text(
          'Click the link in the email to verify your account.',
          style: AppTheme.bodyMedium.copyWith(
            fontSize: 14,
            color: AppTheme.textDark,
          ),
          textAlign: TextAlign.center,
        ),

        const SizedBox(height: 8),

        // Spam folder hint
        _buildHintRow(
          icon: Icons.info_outline_rounded,
          text: "Can't find it? Check your spam or junk folder.",
        ),

        const SizedBox(height: 24),

        // Feedback banner — only shown after resend or failed check
        if (message != null) ...[
          _buildMessageBanner(),
          const SizedBox(height: 16),
        ],

        // Secondary button — resend with live countdown on label
        HoverButton(
          onTap: resendCooldown ? null : onResend,
          isLoading: false,
          isSecondary: true,
          label: resendCooldown
              ? 'Resend in ${cooldownSeconds}s'
              : 'Resend Verification Email',
        ),

        const SizedBox(height: 20),

        // Sign out text link — for wrong account
        _buildSignOutLink(),

        const SizedBox(height: 24),
      ],
    );
  }

  // ─────────────────────────────────────────
  // EMAIL ICON — spinning ring + icon in center
  // ─────────────────────────────────────────

  Widget _buildEmailIcon() {
    return const Center(child: _AnimatedEmailIcon());
  }

  // ─────────────────────────────────────────
  // HINT ROW — icon + text side by side
  // ─────────────────────────────────────────

  Widget _buildHintRow({required IconData icon, required String text}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, size: 13, color: AppTheme.primaryBrown),
        const SizedBox(width: 6),
        Flexible(
          child: Text(
            text,
            style: AppTheme.bodyMedium.copyWith(
              fontSize: 13,
              color: AppTheme.textDark,
            ),
          ),
        ),
      ],
    );
  }

  // ─────────────────────────────────────────
  // MESSAGE BANNER — success (green) or error (red)
  // ─────────────────────────────────────────

  Widget _buildMessageBanner() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isSuccess
            ? AppTheme.successGreen.withOpacity(0.08)
            : AppTheme.errorRed.withOpacity(0.08),
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
            isSuccess
                ? Icons.check_circle_outline_rounded
                : Icons.error_outline_rounded,
            color: isSuccess ? AppTheme.successGreen : AppTheme.errorRed,
            size: 18,
          ),

          const SizedBox(width: 10),

          Expanded(
            child: Text(
              message!,
              style: AppTheme.bodyMedium.copyWith(
                fontSize: 13,
                color: isSuccess ? AppTheme.successGreen : AppTheme.errorRed,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────
  // SIGN OUT LINK
  // ─────────────────────────────────────────

  Widget _buildSignOutLink() {
    return GestureDetector(
      onTap: onLogout,
      child: RichText(
        textAlign: TextAlign.center,
        text: TextSpan(
          style: AppTheme.bodyMedium.copyWith(
            fontSize: 14,
            color: AppTheme.textDark,
          ),
          children: [
            const TextSpan(text: 'Wrong account? '),
            TextSpan(
              text: 'Sign out',
              style: AppTheme.bodyMedium.copyWith(
                fontSize: 14,
                color: AppTheme.primaryBrown,
                fontWeight: FontWeight.w600,
                decoration: TextDecoration.underline,
                decorationColor: AppTheme.primaryBrown,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AnimatedEmailIcon extends StatefulWidget {
  const _AnimatedEmailIcon();
  @override
  State<_AnimatedEmailIcon> createState() => _AnimatedEmailIconState();
}

class _AnimatedEmailIconState extends State<_AnimatedEmailIcon>
    with SingleTickerProviderStateMixin {
  late AnimationController _rotationController;

  @override
  void initState() {
    super.initState();
    _rotationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
  }

  @override
  void dispose() {
    _rotationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 76,
      height: 76,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Smooth rotating ring background
          RotationTransition(
            turns: _rotationController,
            child: CustomPaint(
              size: const Size(76, 76),
              painter: _SpinnerPainter(color: AppTheme.primaryBrown),
            ),
          ),

          // Outer static circle border
          Container(
            width: 76,
            height: 76,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: AppTheme.primaryBrown.withOpacity(0.08),
                width: 2,
              ),
            ),
          ),

          // Central icon container
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              color: AppTheme.primaryBrown.withOpacity(0.08),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.mark_email_unread_outlined,
              size: 28,
              color: AppTheme.primaryBrown,
            ),
          ),
        ],
      ),
    );
  }
}

/// Custom painter for a smooth, tapered circular spinner.
class _SpinnerPainter extends CustomPainter {
  final Color color;

  _SpinnerPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - paint.strokeWidth) / 2;

    // Draw a partial arc — roughly 1/3 of a circle
    // This creates the "spinning ring" effect when the whole canvas rotates
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      0,
      1.5, // ~90 degrees
      false,
      paint,
    );

    // Draw a second, very subtle trailing arc
    paint.color = color.withOpacity(0.3);
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      2.0,
      0.8,
      false,
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
