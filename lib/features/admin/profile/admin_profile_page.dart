import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/services/firebase_service.dart';
import '../../../core/utils/responsive_utils.dart';
import '../../../app/routes.dart';

class AdminProfilePage extends StatefulWidget {
  const AdminProfilePage({super.key});

  @override
  State<AdminProfilePage> createState() => _AdminProfilePageState();
}

class _AdminProfilePageState extends State<AdminProfilePage> {
  bool _isResetting = false;

  Future<void> _handleResetPassword() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || user.email == null) return;

    setState(() => _isResetting = true);
    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: user.email!);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Password reset email sent to ${user.email}'),
            backgroundColor: AppTheme.successGreen,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isResetting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final isMobile = ResponsiveBreakpoints.isMobile(context);

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.white,
        elevation: 1,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppTheme.textDark),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Account Settings',
          style: GoogleFonts.playfairDisplay(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: AppTheme.textDark,
          ),
        ),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(
            horizontal: isMobile ? 24 : 32,
            vertical: 48,
          ),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(40),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.04),
                        blurRadius: 24,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      CircleAvatar(
                        radius: 44,
                        backgroundColor: AppTheme.primaryBrown.withOpacity(
                          0.08,
                        ),
                        child: const Icon(
                          Icons.shield_outlined,
                          size: 40,
                          color: AppTheme.primaryBrown,
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        user?.email ?? 'Admin User',
                        style: AppTheme.headingLarge.copyWith(fontSize: 22),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Administrator',
                        style: AppTheme.bodyMedium.copyWith(
                          color: AppTheme.textLight,
                          letterSpacing: 1,
                        ),
                      ),
                      const SizedBox(height: 48),

                      // Reset Password Action
                      _buildActionButton(
                        onPressed: _isResetting ? null : _handleResetPassword,
                        icon: Icons.lock_reset,
                        label: _isResetting ? 'Sending...' : 'Reset Password',
                        color: AppTheme.primaryBrown,
                        isLoading: _isResetting,
                      ),
                      const SizedBox(height: 16),

                      // Logout Action
                      _buildActionButton(
                        onPressed: () async {
                          await FirebaseService.signOut();
                          if (context.mounted) {
                            Navigator.pushNamedAndRemoveUntil(
                              context,
                              Routes.signin,
                              (route) => false,
                            );
                          }
                        },
                        icon: Icons.logout,
                        label: 'Sign Out',
                        color: Colors.redAccent,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required VoidCallback? onPressed,
    required IconData icon,
    required String label,
    required Color color,
    bool isLoading = false,
  }) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: onPressed,
        icon: isLoading
            ? SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2, color: color),
              )
            : Icon(icon, size: 18),
        label: Text(label),
        style: OutlinedButton.styleFrom(
          foregroundColor: color,
          side: BorderSide(color: color.withOpacity(0.3)),
          padding: const EdgeInsets.symmetric(vertical: 18),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }
}
