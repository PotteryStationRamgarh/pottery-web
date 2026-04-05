import 'package:flutter/material.dart';
import '../../../../../core/utils/responsive_utils.dart';
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
    return LayoutBuilder(
      builder: (context, constraints) {
        if (!ResponsiveBreakpoints.isDesktopWidth(constraints.maxWidth)) {
          return Column(
            children: [
              _logoCard(context),
              const SizedBox(height: 16),
              _authCard(context),
              const SizedBox(height: 16),
              _heroCard(context),
            ],
          );
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: _logoCard(context)),
            const SizedBox(width: 20),
            Expanded(child: _authCard(context)),
            const SizedBox(width: 20),
            Expanded(child: _heroCard(context)),
          ],
        );
      },
    );
  }

  Widget _logoCard(BuildContext context) => ImageUploadCard(
    title: 'App Logo',
    subtitle: 'Shown in auth screens and sidebar header',
    localBytes: controller.newLogoBytes,
    networkUrl: controller.currentLogoUrl,
    isCircular: true,
    onPick: () => _pick(context, 'logo'),
  );

  Widget _authCard(BuildContext context) => ImageUploadCard(
    title: 'Auth Page Image',
    subtitle: 'Left panel of sign in / sign up screens',
    localBytes: controller.newAuthBytes,
    networkUrl: controller.currentAuthUrl,
    isCircular: false,
    onPick: () => _pick(context, 'auth'),
  );

  Widget _heroCard(BuildContext context) => ImageUploadCard(
    title: 'Hero Section Image',
    subtitle: 'Right side of the home page hero section',
    localBytes: controller.newHeroBytes,
    networkUrl: controller.currentHeroUrl,
    isCircular: false,
    onPick: () => _pick(context, 'hero'),
  );
}
