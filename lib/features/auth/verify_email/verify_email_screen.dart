import 'package:flutter/material.dart';
import '../../../app/routes.dart';
import '../../../core/theme/app_theme.dart';
import 'verify_email_controller.dart';
import 'widgets/verify_email_form.dart';

/// VerifyEmailScreen — shown after signup until user verifies their email.
///
/// This file only handles:
/// - Desktop / mobile layout shell (floating card)
/// - Connecting VerifyEmailController to VerifyEmailForm
/// - Navigation after verification (based on role from controller)
///
/// All logic → VerifyEmailController
/// All UI    → VerifyEmailForm
class VerifyEmailScreen extends StatefulWidget {
  const VerifyEmailScreen({super.key});

  @override
  State<VerifyEmailScreen> createState() => _VerifyEmailScreenState();
}

class _VerifyEmailScreenState extends State<VerifyEmailScreen>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {

  late VerifyEmailController _controller;

  late AnimationController _animController;
  late Animation<double>   _fadeAnim;
  late Animation<Offset>   _slideAnim;

  @override
  void initState() {
    super.initState();

    // Create controller and start auto-check timer
    _controller = VerifyEmailController();
    _controller.addListener(_onControllerUpdate);
    _controller.init();

    // Watch app lifecycle — key fix for iPhone users
    // When user comes back from Safari after clicking the link
    // we immediately check instead of waiting for auto-check timer
    WidgetsBinding.instance.addObserver(this);

    // Fade + slide animation for the floating card
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeOut),
    );
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.08),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeOut),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _animController.forward();
    });
  }

  // ─────────────────────────────────────────
  // CONTROLLER LISTENER
  // Rebuilds UI whenever controller state changes
  // ─────────────────────────────────────────

  void _onControllerUpdate() {
    if (mounted) setState(() {});
  }

  // ─────────────────────────────────────────
  // APP LIFECYCLE — iPhone fix
  // Called when user returns from Safari after clicking verification link
  // ─────────────────────────────────────────

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _handleResumeCheck();
    }
  }

  Future<void> _handleResumeCheck() async {
    final role = await _controller.handleAppResume();
    if (!mounted) return;
    _navigateByRole(role);
  }

  // ─────────────────────────────────────────
  // NAVIGATION HANDLERS
  // ─────────────────────────────────────────

  Future<void> _handleManualCheck() async {
    final role = await _controller.handleManualCheck();
    if (!mounted) return;
    _navigateByRole(role);
  }

  Future<void> _handleLogout() async {
    await _controller.handleLogout();
    if (!mounted) return;
    Navigator.pushReplacementNamed(context, Routes.signin);
  }

  /// Routes to admin dashboard or customer home based on role.
  /// Does nothing if role is null — user not verified yet.
  void _navigateByRole(String? role) {
    if (role == null) return;
    if (role == 'admin') {
      Navigator.pushReplacementNamed(context, Routes.adminDashboard);
    } else {
      Navigator.pushReplacementNamed(context, Routes.customerHome);
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller.removeListener(_onControllerUpdate);
    _controller.dispose();
    _animController.dispose();
    super.dispose();
  }

  // ─────────────────────────────────────────
  // BUILD
  // ─────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 768;
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: isMobile ? _buildMobile() : _buildDesktop(),
    );
  }

  // ─────────────────────────────────────────
  // DESKTOP — centered floating card
  // ─────────────────────────────────────────

  Widget _buildDesktop() {
    return Center(
      child: Container(
        width:  MediaQuery.of(context).size.width  * 0.40,
        height: MediaQuery.of(context).size.height * 0.85,
        decoration: BoxDecoration(
          color: AppTheme.white,
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color:      AppTheme.primaryBrown.withOpacity(0.08),
              blurRadius: 40,
              offset:     const Offset(0, 8),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(28),
          child: FadeTransition(
            opacity: _fadeAnim,
            child: SlideTransition(
              position: _slideAnim,
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 48,
                    vertical:   32,
                  ),
                  child: _buildForm(),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ─────────────────────────────────────────
  // MOBILE — full width floating card
  // ─────────────────────────────────────────

  Widget _buildMobile() {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(
          horizontal: 24,
          vertical:   48,
        ),
        child: Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: AppTheme.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color:      AppTheme.primaryBrown.withOpacity(0.08),
                blurRadius: 32,
                offset:     const Offset(0, 6),
              ),
            ],
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: 28,
            vertical:   36,
          ),
          child: FadeTransition(
            opacity: _fadeAnim,
            child: SlideTransition(
              position: _slideAnim,
              child: _buildForm(),
            ),
          ),
        ),
      ),
    );
  }

  // ─────────────────────────────────────────
  // FORM — passes controller state + callbacks to VerifyEmailForm
  // ─────────────────────────────────────────

  Widget _buildForm() {
    return VerifyEmailForm(
      // State from controller
      maskedEmail:     _controller.maskedEmail,
      isChecking:      _controller.isChecking,
      resendCooldown:  _controller.resendCooldown,
      cooldownSeconds: _controller.cooldownSeconds,
      message:         _controller.message,
      isSuccess:       _controller.isSuccess,

      // Callbacks — screen handles navigation, controller handles logic
      onManualCheck: _handleManualCheck,
      onResend:      _controller.handleResend,
      onLogout:      _handleLogout,
    );
  }
}