import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';

/// PotteryPlaceholder — unified placeholder for missing images.
/// Ensures consistent branding and aesthetics across the app.
class PotteryPlaceholder extends StatelessWidget {
  final double? width;
  final double? height;
  final double? aspectRatio;
  final IconData icon;

  const PotteryPlaceholder({
    super.key,
    this.width,
    this.height,
    this.aspectRatio,
    this.icon = Icons.spa_outlined,
  });

  @override
  Widget build(BuildContext context) {
    Widget content = Container(
      width: width,
      height: height,
      color: AppTheme.lightBrown.withOpacity(0.1),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 32,
              color: AppTheme.lightBrown.withOpacity(0.4),
            ),
            const SizedBox(height: 8),
            Text(
              'Image Not Available',
              style: GoogleFonts.jost(
                fontSize: 10,
                color: AppTheme.lightBrown.withOpacity(0.45),
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );

    if (aspectRatio != null) {
      return AspectRatio(
        aspectRatio: aspectRatio!,
        child: content,
      );
    }

    return content;
  }
}
