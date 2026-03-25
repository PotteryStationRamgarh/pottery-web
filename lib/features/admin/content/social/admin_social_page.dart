import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/services/firestore_service.dart';

class AdminSocialPage extends StatefulWidget {
  const AdminSocialPage({super.key});

  @override
  State<AdminSocialPage> createState() => _AdminSocialPageState();
}

class _AdminSocialPageState extends State<AdminSocialPage> {
  bool _isLoading = true;
  bool _isSaving = false;

  late TextEditingController _igCtrl;
  late TextEditingController _fbCtrl;
  late TextEditingController _webCtrl;

  @override
  void initState() {
    super.initState();
    _igCtrl = TextEditingController();
    _fbCtrl = TextEditingController();
    _webCtrl = TextEditingController();
    _loadData();
  }

  Future<void> _loadData() async {
    final social = await FirestoreService.getSocial();
    if (mounted) {
      setState(() {
        _igCtrl.text = social.instagramUrl;
        _fbCtrl.text = social.facebookUrl;
        _webCtrl.text = social.websiteUrl;
        _isLoading = false;
      });
    }
  }

  Future<void> _save() async {
    setState(() => _isSaving = true);
    try {
      final current = await FirestoreService.getSocial();
      final updated = current.copyWith(
        instagramUrl: _igCtrl.text.trim(),
        facebookUrl: _fbCtrl.text.trim(),
        websiteUrl: _webCtrl.text.trim(),
      );
      await FirestoreService.updateConfig('social', updated.toMap());

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Social links updated successfully'), backgroundColor: AppTheme.successGreen),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update: $e'), backgroundColor: AppTheme.errorRed),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  void dispose() {
    _igCtrl.dispose();
    _fbCtrl.dispose();
    _webCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Center(child: CircularProgressIndicator(color: AppTheme.primaryBrown));

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 28, 24, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Social Links', style: AppTheme.headingLarge),
                    const SizedBox(height: 4),
                    Text('Manage your social media and website links', style: AppTheme.bodyMedium),
                  ],
                ),
                ElevatedButton(
                  onPressed: _isSaving ? null : _save,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryBrown,
                    foregroundColor: AppTheme.white,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: _isSaving
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : Text('Save Changes', style: AppTheme.labelLarge),
                ),
              ],
            ),
            const SizedBox(height: 32),

            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(color: AppTheme.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppTheme.divider)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildField('Instagram URL', _igCtrl, Icons.camera_alt_outlined),
                  const SizedBox(height: 20),
                  _buildField('Facebook URL', _fbCtrl, Icons.facebook_outlined),
                  const SizedBox(height: 20),
                  _buildField('Website URL', _webCtrl, Icons.link_outlined),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildField(String label, TextEditingController controller, IconData prefixIcon) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTheme.bodySmall.copyWith(color: AppTheme.textDark, fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          style: AppTheme.bodyLarge,
          decoration: AppTheme.inputDecoration(label: label, hint: 'Enter $label').copyWith(
            prefixIcon: Icon(prefixIcon, color: AppTheme.greyPlaceholder, size: 20),
          ),
        ),
      ],
    );
  }
}
