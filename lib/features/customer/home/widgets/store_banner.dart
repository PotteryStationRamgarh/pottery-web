import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/providers/config_provider.dart';

/// StoreBanner — full width dark CTA section at the bottom of home screen.
/// Sits between AllProductsSection and the footer.
///
/// Content from Firestore app_config/branding:
/// storeBannerTitle → main heading (serif italic)
/// storeBannerDesc  → supporting text below heading
///
/// The circular arrow button shows a "Coming Soon" snackbar.
/// Actual store is planned for V2.
class StoreBanner extends StatelessWidget {
  const StoreBanner({super.key});

  @override
  Widget build(BuildContext context) {
    final config   = context.watch<ConfigProvider>();
    final isMobile = MediaQuery.of(context).size.width < 768;

    // Fall back to defaults if Firestore values are empty
    final title = config.branding.storeBannerTitle.isNotEmpty
        ? config.branding.storeBannerTitle
        : 'Bring the studio home.';

    final desc = config.branding.storeBannerDesc.isNotEmpty
        ? config.branding.storeBannerDesc
        : 'Browse our current collection of unique, hand-thrown pieces.';

    return Container(
      width: double.infinity,
      // Dark warm background — strong contrast from the light sections above
      color: AppTheme.appBackground,
      child: Stack(
        children: [

          // Decorative blob shape painted in background
          // Purely visual — no asset files needed
          Positioned.fill(
            child: CustomPaint(painter: _BlobPainter()),
          ),

          // Main content
          Padding(
            padding: EdgeInsets.symmetric(
              horizontal: isMobile ? 32 : 80,
              vertical:   isMobile ? 72 : 112,
            ),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 600),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [

                    // Small label above title
                    Text(
                      'POTTERY STATION',
                      style: GoogleFonts.jost(
                        fontSize: 10,
                        fontWeight: FontWeight.w300,
                        color: AppTheme.lightBrown.withOpacity(0.35),
                        letterSpacing: 4,
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Main title — large serif italic
                    Text(
                      title,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.playfairDisplay(
                        fontSize: isMobile ? 36 : 56,
                        fontWeight: FontWeight.w600,
                        fontStyle: FontStyle.italic,
                        color: AppTheme.white,
                        height: 1.2,
                        letterSpacing: 0.3,
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Supporting description
                    Text(
                      desc,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.jost(
                        fontSize: 16,
                        fontWeight: FontWeight.w300,
                        color: AppTheme.white.withOpacity(0.8),
                        height: 1.75,
                        letterSpacing: 0.3,
                      ),
                    ),

                    const SizedBox(height: 48),

                    // Circular arrow CTA
                    _CircleButton(
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'Online store coming soon!',
                              style: GoogleFonts.jost(
                                fontSize: 13,
                                color: Colors.white,
                              ),
                            ),
                            backgroundColor: AppTheme.primaryBrown,
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            duration: const Duration(seconds: 2),
                          ),
                        );
                      },
                    ),

                    const SizedBox(height: 16),

                    // Label below button
                    Text(
                      'COMING SOON',
                      style: GoogleFonts.jost(
                        fontSize: 10,
                        fontWeight: FontWeight.w300,
                        color: AppTheme.lightBrown.withOpacity(0.28),
                        letterSpacing: 3.5,
                      ),
                    ),

                  ],
                ),
              ),
            ),
          ),

        ],
      ),
    );
  }
}

// ─────────────────────────────────────────
// CIRCLE BUTTON
// ─────────────────────────────────────────

class _CircleButton extends StatefulWidget {
  final VoidCallback onTap;
  const _CircleButton({required this.onTap});

  @override
  State<_CircleButton> createState() => _CircleButtonState();
}

class _CircleButtonState extends State<_CircleButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit:  (_) => setState(() => _isHovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          width:  72,
          height: 72,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: _isHovered
                ? AppTheme.lightBrown
                : AppTheme.lightBrown.withOpacity(0.1),
            border: Border.all(
              color: AppTheme.lightBrown.withOpacity(0.22),
              width: 1,
            ),
          ),
          child: AnimatedRotation(
            turns:    _isHovered ? 0.125 : 0.0,
            duration: const Duration(milliseconds: 250),
            child: Icon(
              Icons.arrow_forward,
              size:  22,
              color: _isHovered
                  ? AppTheme.appBackground
                  : AppTheme.lightBrown,
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────
// BLOB PAINTER
// Draws a soft organic shape — no SVG assets needed
// ─────────────────────────────────────────

class _BlobPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppTheme.lightBrown.withOpacity(0.03)
      ..style = PaintingStyle.fill;

    final cx = size.width  / 2;
    final cy = size.height / 2;
    final r  = size.width  * 0.38;

    final path = Path();
    path.moveTo(cx + r * 0.44, cy - r * 0.76);
    path.cubicTo(cx + r * 0.58, cy - r * 0.69, cx + r * 0.70, cy - r * 0.58, cx + r * 0.78, cy - r * 0.45);
    path.cubicTo(cx + r * 0.86, cy - r * 0.32, cx + r * 0.91, cy - r * 0.17, cx + r * 0.90, cy - r * 0.02);
    path.cubicTo(cx + r * 0.89, cy + r * 0.12, cx + r * 0.84, cy + r * 0.26, cx + r * 0.76, cy + r * 0.41);
    path.cubicTo(cx + r * 0.69, cy + r * 0.55, cx + r * 0.59, cy + r * 0.70, cx + r * 0.46, cy + r * 0.78);
    path.cubicTo(cx + r * 0.34, cy + r * 0.86, cx + r * 0.17, cy + r * 0.88, cx + r * 0.01, cy + r * 0.86);
    path.cubicTo(cx - r * 0.14, cy + r * 0.83, cx - r * 0.30, cy + r * 0.77, cx - r * 0.44, cy + r * 0.69);
    path.cubicTo(cx - r * 0.58, cy + r * 0.61, cx - r * 0.72, cy + r * 0.51, cx - r * 0.79, cy + r * 0.38);
    path.cubicTo(cx - r * 0.87, cy + r * 0.25, cx - r * 0.90, cy + r * 0.10, cx - r * 0.87, cy - r * 0.04);
    path.cubicTo(cx - r * 0.84, cy - r * 0.19, cx - r * 0.76, cy - r * 0.34, cx - r * 0.65, cy - r * 0.45);
    path.cubicTo(cx - r * 0.55, cy - r * 0.56, cx - r * 0.41, cy - r * 0.64, cx - r * 0.28, cy - r * 0.71);
    path.cubicTo(cx - r * 0.15, cy - r * 0.79, cx - r * 0.01, cy - r * 0.85, cx + r * 0.11, cy - r * 0.85);
    path.cubicTo(cx + r * 0.25, cy - r * 0.84, cx + r * 0.31, cy - r * 0.83, cx + r * 0.44, cy - r * 0.76);
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}