import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../app/routes.dart';

/// SplashScreen is the first screen the user sees when the app launches.
/// It checks auth state and redirects accordingly — no manual navigation needed.
///
/// Logic flow:
/// 1. No user logged in → go to Login
/// 2. User logged in but email NOT verified → go to VerifyEmail
/// 3. User logged in and verified → go to CustomerHome (Admin logic added later)
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    // Start navigation logic as soon as screen loads
    _handleNavigation();
  }

  Future<void> _handleNavigation() async {
    // Small delay so splash screen is briefly visible
    await Future.delayed(const Duration(seconds: 2));

    // Safety check — if widget was removed from tree during delay, stop here
    if (!mounted) return;

    // Get currently logged in user from Firebase
    final user = FirebaseAuth.instance.currentUser;

    // CASE 1 — No user logged in at all
    if (user == null) {
      Navigator.pushReplacementNamed(context, Routes.login);
      return;
    }

    // Reload user data from Firebase servers to get fresh emailVerified status.
    // Without this, Firebase uses cached data and emailVerified may be stale.
    await user.reload();

    // Safety check again after async gap
    if (!mounted) return;

    // Get refreshed user object after reload
    final refreshedUser = FirebaseAuth.instance.currentUser;

    // CASE 2 — User exists but email is not verified
    if (refreshedUser == null || !refreshedUser.emailVerified) {
      Navigator.pushReplacementNamed(context, Routes.verifyEmail);
      return;
    }

    // CASE 3 — User is logged in and verified
    // Role-based redirect (admin vs customer) will be added in a later step
    // For now everyone goes to customerHome
    Navigator.pushReplacementNamed(context, Routes.customerHome);
  }

  @override
  Widget build(BuildContext context) {
    // Simple loading UI — we will design this properly in UI phase
    return const Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Pottery Station Ramgarh',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 24),
            CircularProgressIndicator(),
          ],
        ),
      ),
    );
  }
}