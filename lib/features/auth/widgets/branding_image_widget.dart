import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/providers/app_refresh_provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/providers/branding_provider.dart';
import '../../../core/utils/cache_busted_url.dart';

/// BrandingImageWidget — shows auth image on signin/signup screens.
///
/// Image is precached during SplashScreen so it renders instantly
/// with no loading delay. If no image is configured → placeholder.
class BrandingImageWidget extends StatelessWidget {
  const BrandingImageWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final branding = context.watch<BrandingProvider>().branding;
    final imageUrl = branding.authImageUrl.trim();
    final hasImage = imageUrl.isNotEmpty;
    final imageVersion = context.select<AppRefreshProvider, int>(
      (value) => value.imageVersion,
    );

    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: BoxDecoration(
        color: AppTheme.greyPlaceholder,
        borderRadius: BorderRadius.circular(24),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: hasImage
            ? _networkImage(imageUrl, imageVersion)
            : _placeholder(),
      ),
    );
  }

  Widget _networkImage(String url, int imageVersion) {
    return Image.network(
      CacheBustedUrl.withVersion(url, imageVersion),
      fit: BoxFit.cover,
      // Since splash precached this, wasSynchronouslyLoaded = true
      // → renders immediately with no fade or placeholder flash
      frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
        if (wasSynchronouslyLoaded || frame != null) return child;
        // Fallback: image wasn't precached (e.g. admin changed it mid-session)
        // Show placeholder until it loads
        return _placeholder();
      },
      errorBuilder: (context, error, stackTrace) {
        debugPrint('BrandingImageWidget: Failed to load image — $error');
        return _placeholder();
      },
    );
  }

  Widget _placeholder() {
    return Container(
      color: AppTheme.greyPlaceholder,
      child: const Center(
        child: Icon(Icons.image_outlined, size: 48, color: Colors.grey),
      ),
    );
  }
}
