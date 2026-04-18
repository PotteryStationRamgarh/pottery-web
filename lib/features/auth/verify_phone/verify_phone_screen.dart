import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../app/routes.dart';
import '../../../core/services/auth_gate_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/responsive_utils.dart';
import '../widgets/branding_image_widget.dart';
import 'verify_phone_controller.dart';
import 'widgets/verify_phone_form.dart';

class VerifyPhoneScreen extends StatefulWidget {
  const VerifyPhoneScreen({super.key});

  @override
  State<VerifyPhoneScreen> createState() => _VerifyPhoneScreenState();
}

class _VerifyPhoneScreenState extends State<VerifyPhoneScreen>
    with SingleTickerProviderStateMixin {
  late final VerifyPhoneController _controller;
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _otpController = TextEditingController();

  bool _consentAccepted = false;
  late final AnimationController _animationController;
  late final Animation<double> _fadeAnimation;
  late final Animation<Offset> _slideAnimation;

  void _onControllerChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  void initState() {
    super.initState();
    _controller = VerifyPhoneController();
    _controller.addListener(_onControllerChanged);
    _phoneController.text = _controller.initialPhoneValue;

    if (FirebaseAuth.instance.currentUser == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          Navigator.pushReplacementNamed(context, Routes.signin);
        }
      });
    }

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );
    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.08), end: Offset.zero).animate(
          CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
        );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _animationController.forward();
    });
  }

  @override
  void dispose() {
    _controller.removeListener(_onControllerChanged);
    _controller.dispose();
    _phoneController.dispose();
    _otpController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _handleSendCode() async {
    final success = await _controller.sendCode(
      _phoneController.text,
      consentAccepted: _consentAccepted,
    );
    if (!mounted) return;
    if (success && _controller.alreadyVerified) {
      _navigateAfterSuccess();
    }
  }

  Future<void> _handleVerifyCode() async {
    final success = await _controller.verifyCode(_otpController.text);
    if (!mounted) return;
    if (success) {
      _navigateAfterSuccess();
    }
  }

  void _navigateAfterSuccess() {
    final pending = AuthGateService.consumePendingNavigation();
    if (pending != null) {
      Navigator.pushReplacementNamed(
        context,
        pending.routeName,
        arguments: pending.arguments,
      );
      return;
    }
    Navigator.pushReplacementNamed(context, Routes.myAccount);
  }

  void _handleBack() {
    final pending = AuthGateService.peekPendingNavigation();
    if (pending != null) {
      if (pending.routeName == Routes.savedAddresses) {
        Navigator.pushReplacementNamed(context, Routes.customerHome);
        return;
      }
      Navigator.pushReplacementNamed(
        context,
        pending.routeName,
        arguments: pending.arguments,
      );
      return;
    }
    Navigator.pushReplacementNamed(context, Routes.customerHome);
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = !ResponsiveBreakpoints.isDesktop(context);
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: isMobile ? _buildMobileLayout() : _buildDesktopLayout(),
    );
  }

  Widget _buildDesktopLayout() {
    return Container(
      width: double.infinity,
      height: double.infinity,
      alignment: Alignment.center,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppTheme.background, Color(0xFFF5F2F0)],
        ),
      ),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 980,
          maxHeight: MediaQuery.of(context).size.height * 0.88,
        ),
        child: Container(
          decoration: BoxDecoration(
            color: AppTheme.white,
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(
                color: AppTheme.primaryBrown.withValues(alpha: 0.12),
                blurRadius: 40,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(28),
            child: IntrinsicHeight(
              child: Row(
                children: [
                  const Expanded(flex: 55, child: BrandingImageWidget()),
                  Expanded(
                    flex: 45,
                    child: FadeTransition(
                      opacity: _fadeAnimation,
                      child: SlideTransition(
                        position: _slideAnimation,
                        child: Center(
                          child: SingleChildScrollView(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 40,
                              vertical: 32,
                            ),
                            child: _buildForm(),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
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
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 460),
          child: Container(
            decoration: BoxDecoration(
              color: AppTheme.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.primaryBrown.withValues(alpha: 0.08),
                  blurRadius: 32,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 36),
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: SlideTransition(
                position: _slideAnimation,
                child: _buildForm(),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildForm() {
    return VerifyPhoneForm(
      phoneController: _phoneController,
      otpController: _otpController,
      consentAccepted: _consentAccepted,
      onConsentChanged: (value) {
        setState(() => _consentAccepted = value ?? false);
      },
      codeSent: _controller.codeSent,
      isSendingCode: _controller.isSendingCode,
      isVerifyingCode: _controller.isVerifyingCode,
      resendSeconds: _controller.resendSeconds,
      message: _controller.message,
      isSuccess: _controller.isSuccess,
      onSendCode: _handleSendCode,
      onVerifyCode: _handleVerifyCode,
      onBack: _handleBack,
    );
  }
}
