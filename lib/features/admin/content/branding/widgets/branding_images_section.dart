import 'package:flutter/material.dart';
import '../admin_branding_controller.dart';
import 'image_upload_card.dart';

class BrandingImagesSection extends StatelessWidget {
  final AdminBrandingController controller;
  final VoidCallback onChanged;

  const BrandingImagesSection({
    super.key,
    required this.controller,
    required this.onChanged,
  });

  Future<void> _pick(BuildContext context, String type) async {
    final bytes = await controller.pickImage(type);
    if (bytes != null) onChanged();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: ImageUploadCard(
            title: 'App Logo',
            subtitle: 'Shown in auth screens and header',
            localBytes: controller.newLogoBytes,
            networkUrl: controller.currentLogoUrl,
            isCircular: true,
            onPick: () => _pick(context, 'logo'),
          ),
        ),
        const SizedBox(width: 24),
        Expanded(
          child: ImageUploadCard(
            title: 'Auth Page Image',
            subtitle: 'Shown on the left panel of sign in / sign up',
            localBytes: controller.newAuthBytes,
            networkUrl: controller.currentAuthUrl,
            isCircular: false,
            onPick: () => _pick(context, 'auth'),
          ),
        ),
      ],
    );
  }
}