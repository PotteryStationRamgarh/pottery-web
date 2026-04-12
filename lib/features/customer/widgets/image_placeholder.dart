import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/providers/app_refresh_provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/cache_busted_url.dart';

/// ImagePlaceholder — shown when an image is loading or fails to load.
/// Used across product cards, exclusive cards, exhibition section etc.
///
/// [aspectRatio] — width/height ratio, default 1.0 (square)
/// [icon]        — icon shown in center, defaults to image icon
/// [borderRadius]— optional rounded corners
class ImagePlaceholder extends StatelessWidget {
  final double aspectRatio;
  final IconData icon;
  final BorderRadius? borderRadius;

  const ImagePlaceholder({
    super.key,
    this.aspectRatio = 1.0,
    this.icon = Icons.image_outlined,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: aspectRatio,
      child: Container(
        decoration: BoxDecoration(
          color: AppTheme.divider.withValues(alpha: 0.4),
          borderRadius: borderRadius,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 26,
              color: AppTheme.greyPlaceholder.withValues(alpha: 0.4),
            ),
            const SizedBox(height: 8),
            Text(
              'Image Not Available',
              style: GoogleFonts.jost(
                fontSize: 10,
                color: AppTheme.greyPlaceholder.withValues(alpha: 0.6),
                fontWeight: FontWeight.w400,
                letterSpacing: 0.2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// NetworkImageWithPlaceholder — drop-in replacement for Image.network.
/// Handles loading state and error fallback automatically.
/// Use this everywhere instead of raw Image.network.
///
/// [url]          — any HTTPS image URL
/// [fit]          — how image fills its box, default BoxFit.cover
/// [aspectRatio]  — if provided wraps in AspectRatio
/// [borderRadius] — if provided clips with rounded corners
class NetworkImageWithPlaceholder extends StatelessWidget {
  final String url;
  final BoxFit fit;
  final double? aspectRatio;
  final BorderRadius? borderRadius;

  const NetworkImageWithPlaceholder({
    super.key,
    required this.url,
    this.fit = BoxFit.cover,
    this.aspectRatio,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    final imageVersion = context.select<AppRefreshProvider, int>(
      (value) => value.imageVersion,
    );
    Widget image = Image.network(
      CacheBustedUrl.withVersion(url, imageVersion),
      fit: fit,
      width: double.infinity,
      height: double.infinity,

      // Soft spinner while image bytes are downloading
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return Container(
          color: AppTheme.divider.withValues(alpha: 0.25),
          child: Center(
            child: SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(
                strokeWidth: 1.5,
                color: AppTheme.lightBrown.withValues(alpha: 0.4),
                value: loadingProgress.expectedTotalBytes != null
                    ? loadingProgress.cumulativeBytesLoaded /
                          loadingProgress.expectedTotalBytes!
                    : null,
              ),
            ),
          ),
        );
      },

      // Broken image icon if URL fails or image deleted
      errorBuilder: (context, error, stackTrace) {
        return Container(
          color: AppTheme.divider.withValues(alpha: 0.25),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.broken_image_outlined,
                size: 24,
                color: AppTheme.greyPlaceholder.withValues(alpha: 0.35),
              ),
              const SizedBox(height: 6),
              Text(
                'Image Not Available',
                style: GoogleFonts.jost(
                  fontSize: 9,
                  color: AppTheme.greyPlaceholder.withValues(alpha: 0.55),
                ),
              ),
            ],
          ),
        );
      },
    );

    // Clip with rounded corners if provided
    if (borderRadius != null) {
      image = ClipRRect(borderRadius: borderRadius!, child: image);
    }

    // Wrap in AspectRatio if provided
    if (aspectRatio != null) {
      return AspectRatio(aspectRatio: aspectRatio!, child: image);
    }

    return image;
  }
}
