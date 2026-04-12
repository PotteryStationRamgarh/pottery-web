import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../app/routes.dart';
import '../../core/providers/branding_provider.dart';
import '../../core/providers/config_provider.dart';
import '../../core/services/auth_gate_service.dart';
import '../../core/services/firebase_service.dart';
import '../../core/services/storefront_cleanup_service.dart';
import '../../core/theme/app_theme.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeIn);
    _animController.forward();
    WidgetsBinding.instance.addPostFrameCallback((_) => _handleNavigation());
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  Future<void> _handleNavigation() async {
    await Future.delayed(const Duration(milliseconds: 350));
    if (!mounted) return;

    final config = context.read<ConfigProvider>();
    final branding = context.read<BrandingProvider>();

    // Load config + branding in parallel
    await Future.wait([config.load(), branding.loadBranding()]);

    if (!mounted) return;

    // Precache both images so auth screens show them instantly with zero delay
    final logoUrl = branding.branding.logoUrl.trim();
    final authImageUrl = branding.branding.authImageUrl.trim();

    await Future.wait([
      if (logoUrl.isNotEmpty)
        precacheImage(NetworkImage(logoUrl), context).catchError((_) {}),
      if (authImageUrl.isNotEmpty)
        precacheImage(NetworkImage(authImageUrl), context).catchError((_) {}),
    ]);

    if (!mounted) return;

    // ── Navigation logic ──
    final isMaintenance = config.features.maintenanceMode;
    final user = FirebaseAuth.instance.currentUser;

    if (isMaintenance) {
      if (user != null) {
        final role = await FirebaseService.getUserRole(user.uid);
        if (!mounted) return;
        if (role == 'admin') {
          StorefrontCleanupService.runMaintenanceIfDue();
          Navigator.pushReplacementNamed(context, Routes.adminDashboard);
          return;
        }
      }
      Navigator.pushReplacementNamed(context, Routes.maintenance);
      return;
    }

    if (user == null) {
      Navigator.pushReplacementNamed(context, Routes.customerHome);
      return;
    }

    User? refreshedUser = user;
    if (!user.emailVerified) {
      await user.reload();
      if (!mounted) return;
      refreshedUser = FirebaseAuth.instance.currentUser;
    }

    if (refreshedUser == null || !refreshedUser.emailVerified) {
      Navigator.pushReplacementNamed(context, Routes.verifyEmail);
      return;
    }

    final role = await FirebaseService.getUserRole(refreshedUser.uid);
    if (!mounted) return;

    if (role == 'admin') {
      StorefrontCleanupService.runMaintenanceIfDue();
      Navigator.pushReplacementNamed(context, Routes.adminDashboard);
    } else {
      final pending = AuthGateService.consumePendingNavigation();
      if (pending != null) {
        Navigator.pushReplacementNamed(
          context,
          pending.routeName,
          arguments: pending.arguments,
        );
      } else {
        Navigator.pushReplacementNamed(context, Routes.customerHome);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.appBackground,
      body: Center(
        child: FadeTransition(
          opacity: _fadeAnim,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Pottery Station',
                style: GoogleFonts.playfairDisplay(
                  fontSize: 36,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.lightBrown,
                  letterSpacing: 1.5,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'RAMGARH',
                style: GoogleFonts.jost(
                  fontSize: 12,
                  fontWeight: FontWeight.w300,
                  color: AppTheme.lightBrown.withValues(alpha: 0.5),
                  letterSpacing: 6,
                ),
              ),
              const SizedBox(height: 52),
              SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 1.5,
                  color: AppTheme.lightBrown.withValues(alpha: 0.4),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
