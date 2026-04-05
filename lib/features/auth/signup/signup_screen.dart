import 'package:flutter/material.dart';
import '../../../app/routes.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/responsive_utils.dart';
import '../../../features/auth/widgets/branding_image_widget.dart';
import '../signup/signup_controller.dart';
import '../signup/widgets/signup_form.dart';

/// SignupScreen — same floating island layout as SigninScreen.
/// Desktop → image on left, form on right
/// Mobile → no image, only logo and form
class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen>
    with SingleTickerProviderStateMixin {
  final SignupController _controller = SignupController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

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

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
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

  Future<void> _handleSignup() async {
    FocusScope.of(context).unfocus();

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final result = await _controller.signUp(
      email: _emailController.text,
      password: _passwordController.text,
      confirmPassword: _confirmPasswordController.text,
    );

    if (!mounted) return;

    setState(() => _isLoading = false);

    if (result == null) {
      Navigator.pushReplacementNamed(context, Routes.verifyEmail);
    } else {
      setState(() => _errorMessage = result);
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = !ResponsiveBreakpoints.isDesktop(context);

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: isMobile ? _buildMobileLayout() : _buildDesktopLayout(),
    );
  }

  // ─────────────────────────────────────────
  // DESKTOP — floating island, image + form
  // ─────────────────────────────────────────

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
          maxWidth: 950,
          maxHeight: MediaQuery.of(context).size.height * 0.85,
        ),
        child: Container(
          decoration: BoxDecoration(
            color: AppTheme.white,
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(
                color: AppTheme.primaryBrown.withOpacity(0.12),
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
                  // Left — branding image
                  const Expanded(flex: 55, child: BrandingImageWidget()),

                  // Right — signup form
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
                            child: SignupForm(
                              emailController: _emailController,
                              passwordController: _passwordController,
                              confirmPasswordController:
                                  _confirmPasswordController,
                              isLoading: _isLoading,
                              errorMessage: _errorMessage,
                              onSignup: _handleSignup,
                              onDismissError: () {
                                setState(() => _errorMessage = null);
                              },
                              onSigninTap: () {
                                Navigator.pushReplacementNamed(
                                  context,
                                  Routes.signin,
                                );
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
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 450),
          child: Container(
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
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 36),
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: SlideTransition(
                position: _slideAnimation,
                child: SignupForm(
                  emailController: _emailController,
                  passwordController: _passwordController,
                  confirmPasswordController: _confirmPasswordController,
                  isLoading: _isLoading,
                  errorMessage: _errorMessage,
                  onSignup: _handleSignup,
                  onDismissError: () {
                    setState(() => _errorMessage = null);
                  },
                  onSigninTap: () {
                    Navigator.pushReplacementNamed(context, Routes.signin);
                  },
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
