import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/services/firestore_service.dart';
import '../../../../models/app_config.dart';

class AdminHeroSectionPage extends StatefulWidget {
  const AdminHeroSectionPage({super.key});

  @override
  State<AdminHeroSectionPage> createState() => _AdminHeroSectionPageState();
}

class _AdminHeroSectionPageState extends State<AdminHeroSectionPage> {
  bool _isLoading = true;
  bool _isSaving = false;

  late TextEditingController _heroTextCtrl;
  late TextEditingController _heroDescCtrl;
  late TextEditingController _bannerTitleCtrl;
  late TextEditingController _bannerDescCtrl;

  @override
  void initState() {
    super.initState();
    _heroTextCtrl = TextEditingController();
    _heroDescCtrl = TextEditingController();
    _bannerTitleCtrl = TextEditingController();
    _bannerDescCtrl = TextEditingController();
    _loadData();
  }

  Future<void> _loadData() async {
    final branding = await FirestoreService.getBranding();
    if (mounted) {
      setState(() {
        _heroTextCtrl.text = branding.heroText;
        _heroDescCtrl.text = branding.heroDesc;
        _bannerTitleCtrl.text = branding.storeBannerTitle;
        _bannerDescCtrl.text = branding.storeBannerDesc;
        _isLoading = false;
      });
    }
  }

  Future<void> _save() async {
    setState(() => _isSaving = true);
    try {
      final current = await FirestoreService.getBranding();
      final updated = current.copyWith(
        heroText: _heroTextCtrl.text.trim(),
        heroDesc: _heroDescCtrl.text.trim(),
        storeBannerTitle: _bannerTitleCtrl.text.trim(),
        storeBannerDesc: _bannerDescCtrl.text.trim(),
      );
      
      await FirestoreService.updateConfig('branding', updated.toMap());
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Hero Section updated successfully'),
            backgroundColor: AppTheme.successGreen,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update: $e'),
            backgroundColor: AppTheme.errorRed,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  void dispose() {
    _heroTextCtrl.dispose();
    _heroDescCtrl.dispose();
    _bannerTitleCtrl.dispose();
    _bannerDescCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: AppTheme.primaryBrown));
    }

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
                    Text('Hero Section', style: AppTheme.headingLarge),
                    const SizedBox(height: 4),
                    Text('Manage your homepage hero text and store banner', style: AppTheme.bodyMedium),
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
            
            // ── CARD 1: HERO CONTENT ─────────────────────────────────────────
            _buildCard(
              title: 'Hero Content',
              children: [
                _buildField('Hero Headline', _heroTextCtrl, maxLines: 1),
                const SizedBox(height: 16),
                _buildField('Hero Description', _heroDescCtrl, maxLines: 3),
              ],
            ),
            const SizedBox(height: 24),
            
            // ── CARD 2: STORE BANNER ─────────────────────────────────────────
            _buildCard(
              title: 'Store Banner',
              children: [
                _buildField('Banner Title', _bannerTitleCtrl, maxLines: 1),
                const SizedBox(height: 16),
                _buildField('Banner Description', _bannerDescCtrl, maxLines: 2),
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
      decoration: BoxDecoration(
        color: AppTheme.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.divider),
      ),
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
