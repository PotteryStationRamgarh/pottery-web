import 'package:flutter/material.dart';
import '../app/routes.dart';
import '../core/theme/app_theme.dart';
import '../features/splash/splash_screen.dart';
import '../features/auth/signin/signin_screen.dart';
import '../features/auth/signup/signup_screen.dart';
import '../features/auth/verify_email/verify_email_screen.dart';
import '../features/maintenance/maintenance_screen.dart';
import '../features/customer/home/customer_home_screen.dart';
//import '../features/admin/dashboard/admin_dashboard_screen.dart';

/// Root of the entire app.
/// All screens are registered here as named routes.
/// Think of this as the "map" of the app —
/// every screen has an address (route) defined here.
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Pottery Station Ramgarh',

      // All colors, fonts, button styles come from AppTheme
      // No screen needs to define its own theme
      theme: AppTheme.themeData,

      // App always starts at splash —
      // splash decides where to go next based on auth + maintenance
      initialRoute: Routes.splash,

      routes: {
        // First screen — checks maintenance, auth, role
        Routes.splash: (context) => const SplashScreen(),

        // Auth flow — sign in, sign up, verify email
        Routes.signin:      (context) => const SigninScreen(),
        Routes.signup:      (context) => const SignupScreen(),
        Routes.verifyEmail: (context) => const VerifyEmailScreen(),

        // Shown when admin sets maintenanceMode: true in Firestore
        // Admin bypasses this and goes straight to dashboard
        Routes.maintenance: (context) => const MaintenanceScreen(),

        // Main screen for logged-in customers
        Routes.customerHome: (context) => const CustomerHomeScreen(),

        // Only accessible to users with role: 'admin' in Firestore
        //Routes.adminDashboard: (context) => const AdminDashboardScreen(),
      },
    );
  }
}