import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/services/firestore_service.dart';

class AdminContentPage extends StatefulWidget {
  const AdminContentPage({super.key});

  @override
  State<AdminContentPage> createState() => _AdminContentPageState();
}

class _AdminContentPageState extends State<AdminContentPage> {
  bool _isLoading = true;
  bool _isSaving = false;

  late TextEditingController _aboutCtrl;
  late TextEditingController _helpCtrl;
  late TextEditingController _privacyCtrl;
  late TextEditingController _termsCtrl;

  @override
  void initState() {
    super.initState();
    _aboutCtrl = TextEditingController();
    _helpCtrl = TextEditingController();
    _privacyCtrl = TextEditingController();
    _termsCtrl = TextEditingController();
    _loadData();
  }

  Future<void> _loadData() async {
    final content = await FirestoreService.getContent();
    if (mounted) {
      setState(() {
        _aboutCtrl.text = content.aboutUs;
        _helpCtrl.text = content.helpText;
        _privacyCtrl.text = content.privacyPolicy;
        _termsCtrl.text = content.termsConditions;
        _isLoading = false;
      });
    }
  }

  Future<void> _save() async {
    setState(() => _isSaving = true);
    try {
      final current = await FirestoreService.getContent();
      final updated = current.copyWith(
        aboutUs: _aboutCtrl.text.trim(),
        helpText: _helpCtrl.text.trim(),
        privacyPolicy: _privacyCtrl.text.trim(),
        termsConditions: _termsCtrl.text.trim(),
      );
      await FirestoreService.updateConfig('content', updated.toMap());

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Content updated successfully'), backgroundColor: AppTheme.successGreen),
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
    _aboutCtrl.dispose();
    _helpCtrl.dispose();
    _privacyCtrl.dispose();
    _termsCtrl.dispose();
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
                    Text('Content', style: AppTheme.headingLarge),
                    const SizedBox(height: 4),
                    Text('Manage your About Us, legal, and help text', style: AppTheme.bodyMedium),
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

            _buildCard(
              title: 'About Us',
              children: [_buildField('Company Description', _aboutCtrl, maxLines: 8)],
            ),
            const SizedBox(height: 24),

            _buildCard(
              title: 'Help & Legal',
              children: [
                _buildField('Help Text', _helpCtrl, maxLines: 3),
                const SizedBox(height: 20),
                _buildField('Privacy Policy', _privacyCtrl, maxLines: 4),
                const SizedBox(height: 20),
                _buildField('Terms & Conditions', _termsCtrl, maxLines: 3),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCard({required String title, required List<Widget> children}) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(color: AppTheme.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppTheme.divider)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: AppTheme.headingMedium.copyWith(color: AppTheme.textDark)),
          const SizedBox(height: 20),
          ...children,
        ],
      ),
    );
  }

  Widget _buildField(String label, TextEditingController controller, {int maxLines = 1}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTheme.bodySmall.copyWith(color: AppTheme.textDark, fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          maxLines: maxLines,
          style: AppTheme.bodyLarge,
          decoration: AppTheme.inputDecoration(label: label, hint: 'Enter $label'),
        ),
      ],
    );
  }
}
