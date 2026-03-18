import 'package:flutter/material.dart';
import '../app/routes.dart';
import '../core/theme/app_theme.dart'; // NEW
import '../features/splash/splash_screen.dart';
import '../features/auth/signin/signin_screen.dart';
import '../features/auth/signup/signup_screen.dart';
import '../features/auth/verify_email/verify_email_screen.dart';
import '../features/home/customer_home_screen.dart';
import '../features/home/admin_dashboard_screen.dart';

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Pottery Station Ramgarh',

      // Apply global theme — all screens inherit this automatically
      theme: AppTheme.themeData,

      initialRoute: Routes.splash,
      routes: {
        Routes.splash: (context) => const SplashScreen(),
        Routes.signin: (context) => const SigninScreen(),
        Routes.signup: (context) => const SignupScreen(),
        Routes.verifyEmail: (context) => const VerifyEmailScreen(),
        Routes.customerHome: (context) => const CustomerHomeScreen(),
        Routes.adminDashboard: (context) => const AdminDashboardScreen(),
      },
    );
  }
}