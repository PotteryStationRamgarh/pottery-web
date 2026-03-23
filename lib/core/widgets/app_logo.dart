import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';

/// AppLogo — used everywhere across the app.
/// Auth screens, nav bar, splash, admin dashboard etc.
///
/// If logoUrl is set in Firestore app_config/branding → shows the image.
/// If logoUrl is empty → falls back to a styled text logo.
///
/// [logoUrl]   — from ConfigProvider.branding.logoUrl
/// [appName]   — from ConfigProvider.branding.appName
/// [size]      — controls height of image / font size of text fallback
/// [lightMode] — true = light colors (use on dark backgrounds like splash)
class AppLogo extends StatelessWidget {
  final String logoUrl;
  final String appName;
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
      return Image.network(
        logoUrl,
        height: size,
        fit: BoxFit.contain,
        // If image fails to load — fall back to text logo silently
        errorBuilder: (_, __, ___) => _textLogo(),
      );
    }

    // No URL set — show the text logo
    return _textLogo();
  }

  /// Styled text logo — Playfair Display italic
  /// Looks elegant and on-brand even without a real logo image
  Widget _textLogo() {
    return Text(
      appName.isNotEmpty ? appName : 'Pottery Station',
      style: GoogleFonts.playfairDisplay(
        fontSize: size * 0.75,
        fontWeight: FontWeight.w600,
        fontStyle: FontStyle.italic,
        // Light mode = creamy brown (for dark backgrounds)
        // Dark mode = primary brown (for light backgrounds)
        color: lightMode
            ? AppTheme.lightBrown
            : AppTheme.primaryBrown,
        letterSpacing: 0.5,
      ),
    );
  }
}