import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../app/routes.dart';

class AdminProfilePage extends StatefulWidget {
  const AdminProfilePage({super.key});

  @override
  State<AdminProfilePage> createState() => _AdminProfilePageState();
}

class _AdminProfilePageState extends State<AdminProfilePage>
    with SingleTickerProviderStateMixin {
  final _auth = FirebaseAuth.instance;

  late TextEditingController _currentPasswordCtrl;
  late TextEditingController _newPasswordCtrl;
  late TextEditingController _confirmPasswordCtrl;

  bool _isChangingPassword = false;
  bool _isSendingReset = false;
  bool _isPasswordExpanded = false; // ← collapsed by default

  late final AnimationController _animCtrl;
  late final Animation<double> _expandAnimation;

  @override
  void initState() {
    super.initState();
    _currentPasswordCtrl = TextEditingController();
    _newPasswordCtrl = TextEditingController();
    _confirmPasswordCtrl = TextEditingController();

    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 280),
    );
    _expandAnimation = CurvedAnimation(
      parent: _animCtrl,
      curve: Curves.easeInOut,
    );
  }

  void _togglePasswordForm() {
    setState(() => _isPasswordExpanded = !_isPasswordExpanded);
    if (_isPasswordExpanded) {
      _animCtrl.forward();
    } else {
      _animCtrl.reverse();
      // Clear fields when collapsing
      _currentPasswordCtrl.clear();
      _newPasswordCtrl.clear();
      _confirmPasswordCtrl.clear();
    }
  }

  Future<void> _changePassword() async {
    final current = _currentPasswordCtrl.text;
    final newPass = _newPasswordCtrl.text;
    final confirm = _confirmPasswordCtrl.text;

    if (current.isEmpty || newPass.isEmpty || confirm.isEmpty) {
      _showSnack('Please fill all password fields', AppTheme.errorRed);
      return;
    }
    if (newPass != confirm) {
      _showSnack('New passwords do not match', AppTheme.errorRed);
      return;
    }
    if (newPass.length < 6) {
      _showSnack('Password must be at least 6 characters', AppTheme.errorRed);
      return;
    }

    setState(() => _isChangingPassword = true);
    try {
      final user = _auth.currentUser;
      if (user != null && user.email != null) {
        final credential = EmailAuthProvider.credential(
          email: user.email!,
          password: current,
        );
        await user.reauthenticateWithCredential(credential);
        await user.updatePassword(newPass);

        _currentPasswordCtrl.clear();
        _newPasswordCtrl.clear();
        _confirmPasswordCtrl.clear();
        _showSnack('Password successfully updated', AppTheme.successGreen);

        // Collapse form after success
        setState(() => _isPasswordExpanded = false);
        _animCtrl.reverse();
      }
    } on FirebaseAuthException catch (e) {
      _showSnack(e.message ?? 'Authentication failed', AppTheme.errorRed);
    } catch (e) {
      _showSnack('An error occurred', AppTheme.errorRed);
    } finally {
      if (mounted) setState(() => _isChangingPassword = false);
    }
  }

  Future<void> _sendResetEmail() async {
    setState(() => _isSendingReset = true);
    try {
      final user = _auth.currentUser;
      if (user != null && user.email != null) {
        await _auth.sendPasswordResetEmail(email: user.email!);
        _showSnack('Password reset email sent to ${user.email}', AppTheme.successGreen);
      }
    } catch (e) {
      _showSnack('Failed to send reset email', AppTheme.errorRed);
    } finally {
      if (mounted) setState(() => _isSendingReset = false);
    }
  }

  Future<void> _logout() async {
    await _auth.signOut();
    if (mounted) {
      Navigator.of(context).pushNamedAndRemoveUntil(Routes.signin, (route) => false);
    }
  }

  void _showSnack(String msg, Color color) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg), backgroundColor: color),
      );
    }
  }

  @override
  void dispose() {
    _currentPasswordCtrl.dispose();
    _newPasswordCtrl.dispose();
    _confirmPasswordCtrl.dispose();
    _animCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = _auth.currentUser;
    final email = user?.email ?? 'Unknown Admin';
    final name = user?.displayName ?? 'Administrator';

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: Text('Admin Profile', style: AppTheme.headingMedium),
        backgroundColor: AppTheme.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppTheme.textDark),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 28, 24, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Section 1: User Info ──
            _buildSection(
              'User Information',
              Row(
                children: [
                  const CircleAvatar(
                    backgroundColor: AppTheme.primaryBrown,
                    radius: 28,
                    child: Icon(Icons.person, color: Colors.white, size: 28),
                  ),
                  const SizedBox(width: 20),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(name, style: AppTheme.headingMedium),
                      const SizedBox(height: 2),
                      Text(email, style: AppTheme.bodyMedium.copyWith(color: AppTheme.textLight)),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // ── Section 2: Security ──
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Change Password — collapsible
                Expanded(
                  flex: 3,
                  child: _buildCollapsiblePasswordSection(),
                ),
                const SizedBox(width: 24),
                // Quick Reset
                Expanded(
                  flex: 2,
                  child: _buildSection(
                    'Quick Reset',
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Send a password recovery link to your registered email.',
                          style: AppTheme.bodyMedium,
                        ),
                        const SizedBox(height: 24),
                        OutlinedButton.icon(
                          onPressed: _isSendingReset ? null : _sendResetEmail,
                          icon: _isSendingReset
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: AppTheme.primaryBrown,
                                  ),
                                )
                              : const Icon(Icons.email_outlined, size: 18),
                          label: Text(_isSendingReset ? 'Sending…' : 'Send Reset Link'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppTheme.primaryBrown,
                            side: const BorderSide(color: AppTheme.primaryBrown),
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // ── Section 3: Session ──
            _buildSection(
              'Session Management',
              Row(
                children: [
                  const Icon(Icons.logout, size: 28, color: AppTheme.errorRed),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Logout', style: AppTheme.headingMedium.copyWith(color: AppTheme.errorRed)),
                        Text('Securely end your current administrative session.', style: AppTheme.bodyMedium),
                      ],
                    ),
                  ),
                  ElevatedButton(
                    onPressed: _logout,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.errorRed,
                      foregroundColor: AppTheme.white,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: const Text('Logout Session'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Password section with a toggle button — collapsed by default
  Widget _buildCollapsiblePasswordSection() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppTheme.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header row with toggle button ──
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 20, 20, 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'CHANGE PASSWORD',
                      style: AppTheme.headingMedium.copyWith(
                        fontSize: 14,
                        color: AppTheme.textLight,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Update your account password',
                      style: AppTheme.bodySmall.copyWith(color: AppTheme.textLight),
                    ),
                  ],
                ),
                ElevatedButton.icon(
                  onPressed: _togglePasswordForm,
                  icon: AnimatedRotation(
                    turns: _isPasswordExpanded ? 0.5 : 0,
                    duration: const Duration(milliseconds: 280),
                    child: const Icon(Icons.keyboard_arrow_down, size: 18),
                  ),
                  label: Text(_isPasswordExpanded ? 'Cancel' : 'Change Password'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _isPasswordExpanded
                        ? AppTheme.background
                        : AppTheme.primaryBrown,
                    foregroundColor: _isPasswordExpanded
                        ? AppTheme.textDark
                        : AppTheme.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                      side: BorderSide(
                        color: _isPasswordExpanded ? AppTheme.divider : Colors.transparent,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ── Animated expandable form ──
          SizeTransition(
            sizeFactor: _expandAnimation,
            child: Column(
              children: [
                const Divider(height: 1, color: AppTheme.divider),
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildPasswordField('Current Password', _currentPasswordCtrl),
                      const SizedBox(height: 16),
                      _buildPasswordField('New Password', _newPasswordCtrl),
                      const SizedBox(height: 16),
                      _buildPasswordField('Confirm New Password', _confirmPasswordCtrl),
                      const SizedBox(height: 24),
                      ElevatedButton(
                        onPressed: _isChangingPassword ? null : _changePassword,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryBrown,
                          foregroundColor: AppTheme.white,
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        child: _isChangingPassword
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                              )
                            : Text('Update Password', style: AppTheme.labelLarge),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection(String title, Widget content) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppTheme.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: AppTheme.headingMedium.copyWith(
              fontSize: 14,
              color: AppTheme.textLight,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 20),
          content,
        ],
      ),
    );
  }

  Widget _buildPasswordField(String label, TextEditingController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTheme.bodySmall.copyWith(fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          obscureText: true,
          style: AppTheme.bodyLarge,
          decoration: AppTheme.inputDecoration(label: label, hint: '••••••••'),
        ),
      ],
    );
  }
}