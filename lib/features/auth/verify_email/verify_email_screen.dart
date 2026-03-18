import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../../app/routes.dart';
import '../../../core/theme/app_theme.dart';
import '../auth_service.dart';
import '../widgets/hover_button.dart';
import '../widgets/logo_placeholder.dart';

class VerifyEmailScreen extends StatefulWidget {
  const VerifyEmailScreen({super.key});

  @override
  State<VerifyEmailScreen> createState() => _VerifyEmailScreenState();
}

class _VerifyEmailScreenState extends State<VerifyEmailScreen>
    with SingleTickerProviderStateMixin {

  final AuthService _authService = AuthService();

  Timer? _timer;
  bool _resendCooldown = false;
  String? _resendMessage;
  bool _isSuccess = false;

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    ));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.08),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    ));

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _animationController.forward();
    });

    _startVerificationCheck();
  }

  void _startVerificationCheck() {
    _timer = Timer.periodic(const Duration(seconds: 5), (_) async {
      await _authService.reloadUser();
      if (!mounted) return;
      if (_authService.isEmailVerified) {
        _timer?.cancel();
        Navigator.pushReplacementNamed(context, Routes.customerHome);
      }
    });
  }

  /// Masks email — shows only first 2 chars before @ then ****
  /// Example: he****@gmail.com
  String _maskEmail(String email) {
    final parts = email.split('@');
    if (parts.length != 2) return email;
    final name = parts[0];
    final domain = parts[1];
    if (name.length <= 2) return '${name}****@$domain';
    return '${name.substring(0, 2)}****@$domain';
  }

  Future<void> _handleResend() async {
    try {
      await _authService.resendVerificationEmail();
      if (!mounted) return;
      setState(() {
        _resendMessage = 'Verification email sent. Check your inbox.';
        _isSuccess = true;
        _resendCooldown = true;
      });
      await Future.delayed(const Duration(seconds: 30));
      if (!mounted) return;
      setState(() => _resendCooldown = false);
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _resendMessage = 'Failed to resend. Please try again.';
        _isSuccess = false;
      });
    }
  }

  Future<void> _handleLogout() async {
    await _authService.logout();
    if (!mounted) return;
    Navigator.pushReplacementNamed(context, Routes.signin);
  }

  @override
  void dispose() {
    _timer?.cancel();
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 768;

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: isMobile
          ? _buildMobileLayout()
          : _buildDesktopLayout(),
    );
  }

  Widget _buildDesktopLayout() {
    return Center(
      child: Container(
        width: MediaQuery.of(context).size.width * 0.40,
        height: MediaQuery.of(context).size.height * 0.75,
        decoration: BoxDecoration(
          color: AppTheme.white,
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: AppTheme.primaryBrown.withOpacity(0.08),
              blurRadius: 40,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(28),
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: SlideTransition(
              position: _slideAnimation,
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 48,
                    vertical: 32,
                  ),
                  child: _buildContent(),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMobileLayout() {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(
          horizontal: 24,
          vertical: 48,
        ),
        child: Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: AppTheme.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: AppTheme.primaryBrown.withOpacity(0.08),
                blurRadius: 32,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: 28,
            vertical: 36,
          ),
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: SlideTransition(
              position: _slideAnimation,
              child: _buildContent(),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildContent() {
    final rawEmail =
        FirebaseAuth.instance.currentUser?.email ?? 'your email';
    final maskedEmail = _maskEmail(rawEmail);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [

        const Center(child: LogoPlaceholder(size: 80)),

        const SizedBox(height: 28),

        Center(
          child: SizedBox(
            width: 72,
            height: 72,
            child: Stack(
              alignment: Alignment.center,
              children: [

                // Rotating loading ring as border
                SizedBox(
                  width: 72,
                  height: 72,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      AppTheme.primaryBrown.withOpacity(0.5),
                    ),
                  ),
                ),

                // Email icon in center
                Container(
                  width: 56,
                  height: 56,
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
          ),
        ),

        const SizedBox(height: 20),

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

        // Masked email
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
          'This page updates automatically once verified.',
          style: AppTheme.bodyMedium.copyWith(
            fontSize: 14,
            color: AppTheme.textDark,
          ),
          textAlign: TextAlign.center,
        ),

        const SizedBox(height: 6),

        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.info_outline_rounded,
              size: 14,
              color: AppTheme.primaryBrown,
            ),
            const SizedBox(width: 6),
            Text(
              "Can't find it? Check your spam or junk folder.",
              style: AppTheme.bodyMedium.copyWith(
                fontSize: 14,
                color: AppTheme.textDark,
              ),
            ),
          ],
        ),

        const SizedBox(height: 28),

        if (_resendMessage != null) ...[
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
            decoration: BoxDecoration(
              color: _isSuccess
                  ? AppTheme.successGreen.withOpacity(0.08)
                  : AppTheme.errorRed.withOpacity(0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border(
                left: BorderSide(
                  color: _isSuccess
                      ? AppTheme.successGreen
                      : AppTheme.errorRed,
                  width: 4,
                ),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  _isSuccess
                      ? Icons.check_circle_outline_rounded
                      : Icons.error_outline_rounded,
                  color: _isSuccess
                      ? AppTheme.successGreen
                      : AppTheme.errorRed,
                  size: 18,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    _resendMessage!,
                    style: AppTheme.bodyMedium.copyWith(
                      color: _isSuccess
                          ? AppTheme.successGreen
                          : AppTheme.errorRed,
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],

        HoverButton(
          onTap: _resendCooldown ? null : _handleResend,
          isLoading: false,
          label: _resendCooldown
              ? 'Wait 30s to resend'
              : 'Resend Verification Email',
        ),

        const SizedBox(height: 16),

        GestureDetector(
          onTap: _handleLogout,
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
        ),

        const SizedBox(height: 24),
      ],
    );
  }
}