import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../app/routes.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/services/firebase_service.dart';
import '../widgets/branding_image_widget.dart';
import 'signin_controller.dart';
import 'widgets/signin_form.dart';

/// SigninScreen — floating island layout.
/// Desktop → image on left, form on right, floating card center
/// Mobile → no image, only logo and form, clean minimal
class SigninScreen extends StatefulWidget {
  const SigninScreen({super.key});
  @override
  State<SigninScreen> createState() => _SigninScreenState();
}

class _SigninScreenState extends State<SigninScreen>
    with SingleTickerProviderStateMixin {

  final SigninController _controller = SigninController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _isLoading = false;
  String? _errorMessage;

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
  }

  Future<void> _handleSignin() async {
    FocusScope.of(context).unfocus();

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final result = await _controller.signin(
      email: _emailController.text,
      password: _passwordController.text,
    );

    if (!mounted) return;

    setState(() => _isLoading = false);

    if (result == null) {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final role = await FirebaseService.getUserRole(user.uid);
        if (!mounted) return;
        if (role == 'admin') {
          Navigator.pushReplacementNamed(context, Routes.adminDashboard);
          return;
        }
      }
      Navigator.pushReplacementNamed(context, Routes.customerHome);
    } else if (result == 'email_not_verified') {
      Navigator.pushReplacementNamed(context, Routes.verifyEmail);
    } else {
      setState(() => _errorMessage = result);
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
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

  // ─────────────────────────────────────────
  // DESKTOP — floating island, image + form
  // ─────────────────────────────────────────

  Widget _buildDesktopLayout() {
    return Center(
      child: Container(
        // 50% width — 25% empty on each side
        // 60% height — 20% empty on top and bottom
        width: MediaQuery.of(context).size.width * 0.50,
        height: MediaQuery.of(context).size.height * 0.60,
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
          child: Row(
            children: [

              // Left — branding image 55%
              Expanded(
                flex: 55,
                child: const BrandingImageWidget(),
              ),

              // Right — signin form 45%
              Expanded(
                flex: 45,
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: SlideTransition(
                    position: _slideAnimation,
                    child: Center(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 36,
                          vertical: 24,
                        ),
                        child: SigninForm(
                          emailController: _emailController,
                          passwordController: _passwordController,
                          isLoading: _isLoading,
                          errorMessage: _errorMessage,
                          onSignin: _handleSignin,
                          onDismissError: () {
                            setState(() => _errorMessage = null);
                          },
                          onSignupTap: () {
                            Navigator.pushReplacementNamed(
                                context, Routes.signup);
                          },
                          onForgotPasswordTap: () {
                            Navigator.pushNamed(context, Routes.forgotPassword);
                          },
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─────────────────────────────────────────
  // MOBILE — no image, floating card, logo + form
  // ─────────────────────────────────────────

  Widget _buildMobileLayout() {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(
          horizontal: 24,
          vertical: 48,
        ),
        child: Container(
          // Floating card on mobile
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
              child: SigninForm(
                emailController: _emailController,
                passwordController: _passwordController,
                isLoading: _isLoading,
                errorMessage: _errorMessage,
                onSignin: _handleSignin,
                onDismissError: () {
                  setState(() => _errorMessage = null);
                },
                onSignupTap: () {
                  Navigator.pushReplacementNamed(context, Routes.signup);
                },
                onForgotPasswordTap: () {
                  Navigator.pushNamed(context, Routes.forgotPassword);
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}