import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../../app/routes.dart';
import '../auth_service.dart';

/// VerifyEmailScreen — shown after signup or when user is logged in
/// but has not verified their email yet.
///
/// Logic:
/// - Tells user to check their inbox
/// - Auto checks every 5 seconds if email has been verified
/// - If verified → goes to customerHome automatically
/// - Resend button available if user didn't get the email
class VerifyEmailScreen extends StatefulWidget {
  const VerifyEmailScreen({super.key});

  @override
  State<VerifyEmailScreen> createState() => _VerifyEmailScreenState();
}

class _VerifyEmailScreenState extends State<VerifyEmailScreen> {

  final AuthService _authService = AuthService();

  // Timer that periodically checks if email has been verified
  Timer? _timer;

  // Prevents resend button spam — true means cooldown is active
  bool _resendCooldown = false;

  // Shows feedback message after resend is tapped
  String? _resendMessage;

  @override
  void initState() {
    super.initState();
    // Start auto checking verification status every 5 seconds
    _startVerificationCheck();
  }

  /// Starts a periodic timer that checks Firebase every 5 seconds.
  /// Once verified it cancels itself and navigates to home.
  void _startVerificationCheck() {
    _timer = Timer.periodic(const Duration(seconds: 5), (_) async {
      // Reload user to get fresh data from Firebase servers
      await _authService.reloadUser();

      // Safety check after async gap
      if (!mounted) return;

      // If email is now verified — stop timer and go to home
      if (_authService.isEmailVerified) {
        _timer?.cancel();
        Navigator.pushReplacementNamed(context, Routes.customerHome);
      }
    });
  }

  /// Called when user taps Resend Email button.
  /// Adds a 30 second cooldown to prevent spam.
  Future<void> _handleResend() async {
    try {
      await _authService.resendVerificationEmail();

      if (!mounted) return;

      // Show success message and start cooldown
      setState(() {
        _resendMessage = 'Verification email sent. Please check your inbox.';
        _resendCooldown = true;
      });

      // Remove cooldown after 30 seconds
      await Future.delayed(const Duration(seconds: 30));

      if (!mounted) return;

      setState(() {
        _resendCooldown = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _resendMessage = 'Failed to resend email. Please try again.';
      });
    }
  }

  /// Called when user taps Wrong account? Logout.
  Future<void> _handleLogout() async {
    await _authService.logout();
    if (!mounted) return;
    Navigator.pushReplacementNamed(context, Routes.login);
  }

  @override
  void dispose() {
    // Always cancel timer when screen is removed to prevent memory leaks
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Get current user email to display to user
    final email = FirebaseAuth.instance.currentUser?.email ?? 'your email';

    return Scaffold(
      body: Center(
        child: SizedBox(
          width: 400,
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [

                // Icon
                const Icon(
                  Icons.mark_email_unread_outlined,
                  size: 64,
                  color: Colors.orange,
                ),

                const SizedBox(height: 24),

                // Title
                const Text(
                  'Verify your email',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 12),

                // Instruction text with user's email
                Text(
                  'A verification link has been sent to\n$email\n\nPlease check your inbox and click the link to continue.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 14, color: Colors.grey),
                ),

                const SizedBox(height: 8),

                // Auto check notice
                const Text(
                  'This page will update automatically once verified.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 12, color: Colors.blueGrey),
                ),

                const SizedBox(height: 24),

                // Feedback message after resend attempt
                if (_resendMessage != null)
                  Text(
                    _resendMessage!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 13, color: Colors.green),
                  ),

                const SizedBox(height: 8),

                // Resend button — disabled during cooldown
                ElevatedButton(
                  onPressed: _resendCooldown ? null : _handleResend,
                  child: Text(
                    _resendCooldown
                        ? 'Email Sent — Wait 30s to resend'
                        : 'Resend Verification Email',
                  ),
                ),

                const SizedBox(height: 12),

                // Logout option if wrong account
                TextButton(
                  onPressed: _handleLogout,
                  child: const Text('Wrong account? Logout'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}