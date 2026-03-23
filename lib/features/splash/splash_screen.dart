import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../app/routes.dart';
import '../../core/services/firebase_service.dart';
import '../../core/theme/app_theme.dart';
import '../../core/providers/config_provider.dart';

/// SplashScreen — very first screen the user sees.
/// It doesn't show any interactive UI — just the brand name
/// and a loading indicator while it figures out where to send the user.
///
/// Decision flow:
/// 1. Load all app config from Firestore (branding, exhibition, etc.)
/// 2. Check maintenanceMode → if true and user is not admin → /maintenance
/// 3. Check if user is logged in → if not → /signin
/// 4. Check if email is verified → if not → /verify-email
/// 5. Check user role → admin → /admin, customer → /home
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {

  // Used to fade in the brand name smoothly
  late AnimationController _animController;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();

    // Set up fade-in animation for the brand name
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnim = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeIn,
    );
    _animController.forward();

    // Start the navigation logic after the first frame is drawn
    WidgetsBinding.instance.addPostFrameCallback((_) => _handleNavigation());
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  // ─────────────────────────────────────────
  // NAVIGATION LOGIC
  // ─────────────────────────────────────────

  Future<void> _handleNavigation() async {
    // Keep splash visible for at least 2 seconds
    // so the brand name doesn't flash too quickly
    await Future.delayed(const Duration(seconds: 2));
    if (!mounted) return;

    // Load all Firestore config — branding, exhibition, features etc.
    // This runs in parallel so it's fast
    final config = context.read<ConfigProvider>();
    await config.load();
    if (!mounted) return;

    // STEP 1 — Is maintenance mode on?
    final isMaintenance = config.features.maintenanceMode;

    // Get whoever is currently logged in (null if nobody)
    final user = FirebaseAuth.instance.currentUser;

    if (isMaintenance) {
      // Admin can still access the app even in maintenance mode
      if (user != null) {
        final role = await FirebaseService.getUserRole(user.uid);
        if (!mounted) return;
        if (role == 'admin') {
          // Admin bypasses maintenance → go to dashboard
          Navigator.pushReplacementNamed(context, Routes.adminDashboard);
          return;
        }
      }
      // Everyone else sees the maintenance screen
      Navigator.pushReplacementNamed(context, Routes.maintenance);
      return;
    }

    // STEP 2 — Is anyone logged in?
    if (user == null) {
      Navigator.pushReplacementNamed(context, Routes.signin);
      return;
    }

    // STEP 3 — Reload user to get fresh emailVerified status
    // Without this, the cached status won't update after verification
    await user.reload();
    if (!mounted) return;

    final refreshedUser = FirebaseAuth.instance.currentUser;

    // Check if email is verified
    if (refreshedUser == null || !refreshedUser.emailVerified) {
      Navigator.pushReplacementNamed(context, Routes.verifyEmail);
      return;
    }

    // STEP 4 — Check role in Firestore users/{uid}
    final role = await FirebaseService.getUserRole(refreshedUser.uid);
    if (!mounted) return;

    // Send to the right screen based on role
    if (role == 'admin') {
      Navigator.pushReplacementNamed(context, Routes.adminDashboard);
    } else {
      Navigator.pushReplacementNamed(context, Routes.customerHome);
    }
  }

  // ─────────────────────────────────────────
  // UI
  // ─────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Dark warm background — matches the premium pottery feel
      backgroundColor: AppTheme.appBackground,
      body: Center(
        child: FadeTransition(
          opacity: _fadeAnim,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [

              // Brand name in serif font — elegant, premium
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

              // Sub-brand in light spaced Jost
              Text(
                'RAMGARH',
                style: GoogleFonts.jost(
                  fontSize: 12,
                  fontWeight: FontWeight.w300,
                  color: AppTheme.lightBrown.withOpacity(0.5),
                  letterSpacing: 6,
                ),
              ),

              const SizedBox(height: 52),

              // Thin loading spinner — subtle, not distracting
              SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 1.5,
                  color: AppTheme.lightBrown.withOpacity(0.4),
                ),
              ),

            ],
          ),
        ),
      ),
    );
  }
}