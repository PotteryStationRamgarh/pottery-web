import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../app/routes.dart';
import '../../core/services/firebase_service.dart';

/// SplashScreen — first screen shown on app launch.
/// Checks auth state and redirects based on signin + verification + role.
///
/// Full logic flow:
/// 1. No user logged in → signin
/// 2. Logged in but email NOT verified → VerifyEmail
/// 3. Verified + role is 'admin' → AdminDashboard
/// 4. Verified + role is 'customer' → CustomerHome
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _handleNavigation();
  }

  Future<void> _handleNavigation() async {
    // Brief delay so splash is visible
    await Future.delayed(const Duration(seconds: 2));

    if (!mounted) return;

    // Get currently logged in user
    final user = FirebaseAuth.instance.currentUser;

    // CASE 1 — No user logged in
    if (user == null) {
      Navigator.pushReplacementNamed(context, Routes.signin);
      return;
    }

    // Reload to get fresh emailVerified status from Firebase servers
    await user.reload();

    if (!mounted) return;

    // Get refreshed user object after reload
    final refreshedUser = FirebaseAuth.instance.currentUser;

    // CASE 2 — Logged in but email not verified
    if (refreshedUser == null || !refreshedUser.emailVerified) {
      Navigator.pushReplacementNamed(context, Routes.verifyEmail);
      return;
    }

    // CASE 3 — Verified — fetch role from Firestore
    final role = await FirebaseService.getUserRole(refreshedUser.uid);

    if (!mounted) return;

    // Redirect based on role
    if (role == 'admin') {
      Navigator.pushReplacementNamed(context, Routes.adminDashboard);
    } else {
      Navigator.pushReplacementNamed(context, Routes.customerHome);
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Pottery Station Ramgarh',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 24),
            CircularProgressIndicator(),
          ],
        ),
      ),
    );
  }
}