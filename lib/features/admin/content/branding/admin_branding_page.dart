import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/providers/app_refresh_provider.dart';
import '../../../../core/providers/config_provider.dart';
import '../../../../core/providers/exhibition_provider.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/providers/branding_provider.dart';
import '../../../../core/utils/responsive_utils.dart';
import 'admin_branding_controller.dart';
import 'widgets/branding_images_section.dart';
import 'widgets/branding_text_section.dart';
import 'widgets/contact_social_section.dart';
import 'widgets/content_section.dart';

class AdminBrandingPage extends StatefulWidget {
  const AdminBrandingPage({super.key});

  @override
  State<AdminBrandingPage> createState() => _AdminBrandingPageState();
}

class _AdminBrandingPageState extends State<AdminBrandingPage> {
  late final AdminBrandingController _ctrl;
  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _ctrl = AdminBrandingController();
    _loadAllData();
  }

  Future<void> _loadAllData() async {
    try {
      await _ctrl.loadAll();
      if (mounted) setState(() => _isLoading = false);
    } catch (e) {
      if (mounted) {
        _showSnackbar('Failed to load configs: $e', isError: true);
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _saveAll() async {
    setState(() => _isSaving = true);
    try {
      await _ctrl.saveAll();
      if (mounted) {
        await Future.wait([
          context.read<ConfigProvider>().reload(),
          context.read<BrandingProvider>().reloadBranding(),
          context.read<ExhibitionProvider>().reload(),
        ]);
        context.read<AppRefreshProvider>().invalidateAll();
        _showSnackbar('All branding & content updated successfully!');
        setState(() {});
      }
    } catch (e) {
      if (mounted) _showSnackbar('Failed to update: $e', isError: true);
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _showSnackbar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: AppTheme.bodyMedium.copyWith(color: AppTheme.white),
        ),
        backgroundColor: isError ? AppTheme.errorRed : AppTheme.successGreen,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppTheme.primaryBrown),
      );
    }

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 28, 24, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            const SizedBox(height: 32),
            BrandingImagesSection(
              controller: _ctrl,
              onChanged: () => setState(() {}),
            ),
            const SizedBox(height: 24),
            BrandingTextSection(controller: _ctrl),
            const SizedBox(height: 24),
            ContactSocialSection(controller: _ctrl),
            const SizedBox(height: 24),
            ContentSection(controller: _ctrl),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = ResponsiveBreakpoints.isMobileWidth(
          constraints.maxWidth,
        );

        if (isMobile) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Branding & Content', style: AppTheme.headingLarge),
              const SizedBox(height: 4),
              Text(
                'Manage visuals, copy, and contact info in one place',
                style: AppTheme.bodyMedium,
              ),
              const SizedBox(height: 16),
              SizedBox(width: double.infinity, child: _buildSaveButton()),
            ],
          );
        }

        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Flexible(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Branding & Content', style: AppTheme.headingLarge),
                  const SizedBox(height: 4),
                  Text(
                    'Manage visuals, copy, and contact info in one place',
                    style: AppTheme.bodyMedium,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            _buildSaveButton(),
          ],
        );
      },
    );
  }

  Widget _buildSaveButton() {
    return ElevatedButton(
      onPressed: _isSaving ? null : _saveAll,
      style: ElevatedButton.styleFrom(
        backgroundColor: AppTheme.primaryBrown,
        foregroundColor: AppTheme.white,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 0,
      ),
      child: _isSaving
          ? const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(
                color: Colors.white,
                strokeWidth: 2,
              ),
            )
          : Text('Save Changes', style: AppTheme.labelLarge),
    );
  }
}
