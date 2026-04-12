import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_refresh_provider.dart';
import '../theme/app_theme.dart';
import '../utils/cache_busted_url.dart';

/// AppLogo — used everywhere across the app.
/// Auth screens, nav bar, splash, admin dashboard etc.
///
/// If logoUrl is set in Firestore app_config/branding → shows the image.
/// If logoUrl is empty → falls back to a simple icon placeholder.
///
/// [logoUrl]   — from BrandingProvider.branding.logoUrl
/// [size]      — controls height of image / icon size of fallback
/// [lightMode] — true = light colors (use on dark backgrounds like splash)
class AppLogo extends StatelessWidget {
  final String logoUrl;
  final String
  appName; // Kept for compatibility, but no longer used for fallback text
  final double size;
  final bool lightMode;

  const AppLogo({
    super.key,
    required this.logoUrl,
    required this.appName,
    this.size = 32,
    this.lightMode = false,
  });

  @override
  Widget build(BuildContext context) {
    // If we have a logo image URL — show it
    if (logoUrl.isNotEmpty) {
      final imageVersion = context.select<AppRefreshProvider, int>(
        (value) => value.imageVersion,
      );
      return Image.network(
        CacheBustedUrl.withVersion(logoUrl, imageVersion),
        height: size,
        fit: BoxFit.contain,
        // If image fails to load — fall back to icon placeholder
        errorBuilder: (_, _, _) => _iconPlaceholder(),
      );
    }

    // No URL set — show the icon placeholder
    return _iconPlaceholder();
  }

  /// Simple icon-based placeholder instead of large text.
  /// This prevents the "Pottery Station Ramgarh" text flicker while loading
  /// or if no logo is configured.
  Widget _iconPlaceholder() {
    return Container(
      width: size,
      height: size,
      padding: EdgeInsets.all(size * 0.1),
      decoration: BoxDecoration(
        color: lightMode
            ? Colors.white.withValues(alpha: 0.1)
            : Colors.black.withValues(alpha: 0.05),
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Icon(
          Icons.blur_on_rounded, // An elegant, abstract icon that fits pottery
          size: size * 0.7,
          color: lightMode ? AppTheme.lightBrown : AppTheme.primaryBrown,
        ),
      ),
    );
  }
}
