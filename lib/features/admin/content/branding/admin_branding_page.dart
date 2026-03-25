import 'package:flutter/material.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../../../../core/services/firestore_service.dart';
import '../../../../../core/services/media_service.dart';
import '../../../../../models/app_config.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:typed_data';

class AdminBrandingPage extends StatefulWidget {
  const AdminBrandingPage({super.key});

  @override
  State<AdminBrandingPage> createState() => _AdminBrandingPageState();
}

class _AdminBrandingPageState extends State<AdminBrandingPage> {
  bool _isLoading = true;
  bool _isSaving = false;

  String? _currentLogoUrl;
  String? _currentLoginUrl;
  String? _currentSignupUrl;

  Uint8List? _newLogoBytes;
  Uint8List? _newLoginBytes;
  Uint8List? _newSignupBytes;

  final ImagePicker _picker = ImagePicker();
  final MediaService _mediaService = MediaService();

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final branding = await FirestoreService.getBranding();
    if (mounted) {
      setState(() {
        _currentLogoUrl = branding.logoUrl;
        
        // Settings/branding was manually used for auth backgrounds in older code, we bring it here
        // The prompt says "update app_config/branding with new URLs", but we need to fetch all current auth images too.
        // Actually wait, let's just use the current Branding config for logo, 
        // but auth images are in 'branding/login.png' in R2.
        // We can just rely on getBrandingSettings() for legacy or just assume URLs are in app_config.
        // For now, load from getBrandingSettings.
        _isLoading = false;
      });
    }
    
    final settings = await FirestoreService.getBrandingSettings();
    if (mounted) {
      setState(() {
        _currentLoginUrl = settings['loginImage'];
        _currentSignupUrl = settings['signupImage'];
      });
    }
  }

  Future<void> _pickImage(String type) async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      final bytes = await image.readAsBytes();
      setState(() {
        if (type == 'logo') _newLogoBytes = bytes;
        if (type == 'login') _newLoginBytes = bytes;
        if (type == 'signup') _newSignupBytes = bytes;
      });
    }
  }

  Future<void> _save() async {
    setState(() => _isSaving = true);
    try {
      String? newLogoUrl;
      String? newLoginUrl;
      String? newSignupUrl;

      // Upload if changed
      if (_newLogoBytes != null) {
        final urls = await _mediaService.uploadImages(docId: 'logo.png', pathPrefix: 'branding', files: [_newLogoBytes!]);
        newLogoUrl = urls.first;
      }
      if (_newLoginBytes != null) {
        final urls = await _mediaService.uploadImages(docId: 'login.png', pathPrefix: 'branding', files: [_newLoginBytes!]);
        newLoginUrl = urls.first;
      }
      if (_newSignupBytes != null) {
        final urls = await _mediaService.uploadImages(docId: 'signup.png', pathPrefix: 'branding', files: [_newSignupBytes!]);
        newSignupUrl = urls.first;
      }

      // Update Firestore app_config/branding for logo
      if (newLogoUrl != null) {
        final current = await FirestoreService.getBranding();
        final updated = current.copyWith(logoUrl: newLogoUrl);
        await FirestoreService.updateConfig('branding', updated.toMap());
      }

      // Update legacy settings/branding for auth pages
      if (newLoginUrl != null) {
        await FirestoreService.setLoginImage(newLoginUrl);
      }
      if (newSignupUrl != null) {
        await FirestoreService.setSignupImage(newSignupUrl);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Branding updated successfully'), backgroundColor: AppTheme.successGreen),
        );
        // Clear local bytes so we show the network URL now
        setState(() {
          if (newLogoUrl != null) { _currentLogoUrl = newLogoUrl; _newLogoBytes = null; }
          if (newLoginUrl != null) { _currentLoginUrl = newLoginUrl; _newLoginBytes = null; }
          if (newSignupUrl != null) { _currentSignupUrl = newSignupUrl; _newSignupBytes = null; }
        });
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
                    Text('Branding', style: AppTheme.headingLarge),
                    const SizedBox(height: 4),
                    Text('Update your logo and authentication page images', style: AppTheme.bodyMedium),
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
            
            _buildCard('App Logo', _newLogoBytes, _currentLogoUrl, () => _pickImage('logo')),
            const SizedBox(height: 24),

            Row(
              children: [
                Expanded(child: _buildCard('Login Image', _newLoginBytes, _currentLoginUrl, () => _pickImage('login'))),
                const SizedBox(width: 24),
                Expanded(child: _buildCard('Signup Image', _newSignupBytes, _currentSignupUrl, () => _pickImage('signup'))),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCard(String title, Uint8List? localBytes, String? networkUrl, VoidCallback onPick) {
    bool hasImage = localBytes != null || (networkUrl != null && networkUrl.isNotEmpty);

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
          GestureDetector(
            onTap: onPick,
            child: Container(
              height: 200,
              width: double.infinity,
              decoration: BoxDecoration(
                color: AppTheme.background,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.divider, style: BorderStyle.solid),
                image: hasImage ? DecorationImage(
                  image: localBytes != null 
                      ? MemoryImage(localBytes) as ImageProvider
                      : NetworkImage(networkUrl!),
                  fit: BoxFit.cover,
                ) : null,
              ),
              child: hasImage ? null : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.add_photo_alternate_outlined, size: 48, color: AppTheme.greyPlaceholder),
                  const SizedBox(height: 12),
                  Text('Click to upload image', style: AppTheme.bodyMedium.copyWith(color: AppTheme.textLight)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
