import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/providers/config_provider.dart';
import '../../../../core/widgets/pottery_placeholder.dart';

/// HeroSection — the very first thing the user sees on the home screen.
/// Takes up the full viewport height on desktop.
///
/// Desktop layout:
/// Left 50% → label + big headline + description + CTA buttons
/// Right 50% → hero image with editorial rounded corners + decorative orb
///
/// Mobile layout:
/// Image on top → text content below
///
/// All text content comes from Firestore app_config/branding:
/// heroText → main headline
/// heroDesc → supporting paragraph below headline
class HeroSection extends StatelessWidget {
  final VoidCallback? onExploreTap;

  const HeroSection({super.key, this.onExploreTap});

  @override
  Widget build(BuildContext context) {
    final config   = context.watch<ConfigProvider>();
    final size     = MediaQuery.of(context).size;
    final isMobile = size.width < 768;

    return Container(
      width: double.infinity,
      // Full screen height on desktop — immersive first impression
      constraints: BoxConstraints(minHeight: isMobile ? 0 : size.height),
      color: AppTheme.background,
      child: isMobile
          ? _buildMobile(context, config)
          : _buildDesktop(context, config, size),
    );
  }

  // ─────────────────────────────────────────
  // DESKTOP
  // ─────────────────────────────────────────

  Widget _buildDesktop(
    BuildContext context,
    ConfigProvider config,
    Size size,
  ) {
    return Center(
      child: ConstrainedBox(
        // Max width keeps content centered on very wide screens
        constraints: const BoxConstraints(maxWidth: 1400),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 80),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [

              // Left — text content
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(right: 56),
                  child: _buildText(context, config, isMobile: false),
                ),
              ),

              // Right — hero image
              Expanded(
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    // Cap image height on tablets/desktops so it doesn't get too tall
                    maxHeight: size.height * 0.70,
                  ),
                  child: _buildImage(config, size.height * 0.70),
                ),
              ),

            ],
          ),
        ),
      ),
    );
  }

  // ─────────────────────────────────────────
  // MOBILE
  // ─────────────────────────────────────────

  Widget _buildMobile(BuildContext context, ConfigProvider config) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [

        // Image on top for mobile — now with padding so it doesn't touch edges
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: _buildImage(config, 300),
        ),

        const SizedBox(height: 36),

        // Text content below image
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: _buildText(context, config, isMobile: true),
        ),

        const SizedBox(height: 56),

      ],
    );
  }

  // ─────────────────────────────────────────
  // TEXT CONTENT
  // ─────────────────────────────────────────

  Widget _buildText(
    BuildContext context,
    ConfigProvider config, {
    required bool isMobile,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [

        // Small label above headline — like a category tag
        Text(
          'POTTERY STATION RAMGARH',
          style: GoogleFonts.jost(
            fontSize: 10,
            fontWeight: FontWeight.w400,
            color: AppTheme.primaryBrown.withOpacity(0.55),
            letterSpacing: 3.5,
          ),
        ),

        const SizedBox(height: 20),

        // Main headline — big serif font, from Firestore heroText
        Text(
          config.branding.heroText.isNotEmpty
              ? config.branding.heroText
              : 'The art of\nintentional form.',
          style: GoogleFonts.playfairDisplay(
            fontSize: isMobile ? 38 : 60,
            fontWeight: FontWeight.w600,
            color: AppTheme.textDark,
            height: 1.15,
            letterSpacing: -0.5,
          ),
        ),

        const SizedBox(height: 24),

        // Supporting paragraph — from Firestore heroDesc
        // Only shown if text is set in Firestore
        if (config.branding.heroDesc.isNotEmpty)
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 440),
            child: Text(
              config.branding.heroDesc,
              style: GoogleFonts.jost(
                fontSize: 15,
                fontWeight: FontWeight.w300,
                color: AppTheme.textLight,
                height: 1.75,
                letterSpacing: 0.2,
              ),
            ),
          ),

        const SizedBox(height: 40),

        // CTA buttons row
        Wrap(
          spacing: 16,
          runSpacing: 12,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [

            // Primary button — solid brown
            _PrimaryButton(
              label: 'Explore Collections',
              onTap: () => onExploreTap?.call(),
            ),

            // Secondary — text link with underline
            _TextButton(
              label: 'Our Story',
              onTap: () => _showAboutDialog(
                context,
                config.content.aboutUs,
              ),
            ),

          ],
        ),

      ],
    );
  }

  // ─────────────────────────────────────────
  // HERO IMAGE
  // ─────────────────────────────────────────

  Widget _buildImage(ConfigProvider config, double height) {
    // Use dedicated heroImageUrl; show placeholder if empty
    final imageUrl = config.branding.heroImageUrl;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          height: height,
          decoration: BoxDecoration(
            color: AppTheme.divider.withOpacity(0.35),
            borderRadius: const BorderRadius.only(
              topLeft:     Radius.circular(80),
              bottomRight: Radius.circular(100),
              topRight:    Radius.circular(16),
              bottomLeft:  Radius.circular(16),
            ),
          ),
          clipBehavior: Clip.antiAlias,
          child: imageUrl.isNotEmpty
              ? Image.network(
                  imageUrl,
                  width: double.infinity,
                  height: height,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => const PotteryPlaceholder(),
                )
              : const PotteryPlaceholder(),
        ),

        // Decorative orb — bottom left
        Positioned(
          bottom: -20,
          left: -20,
          child: Container(
            width: 140,
            height: 140,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppTheme.lightBrown.withOpacity(0.15),
            ),
          ),
        ),
      ],
    );
  }


  // ─────────────────────────────────────────
  // ABOUT DIALOG
  // Opened from "Our Story" text button
  // ─────────────────────────────────────────

  void _showAboutDialog(BuildContext context, String content) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: AppTheme.background,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 500),
          child: Padding(
            padding: const EdgeInsets.all(36),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [

                Text(
                  'Our Story',
                  style: GoogleFonts.playfairDisplay(
                    fontSize: 26,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textDark,
                  ),
                ),

                const SizedBox(height: 14),
                Divider(color: AppTheme.divider),
                const SizedBox(height: 14),

                // Scrollable in case aboutUs text is very long
                ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 320),
                  child: SingleChildScrollView(
                    child: Text(
                      content.isNotEmpty
                          ? content
                          : 'Pottery Station Ramgarh is dedicated to the art of hand-thrown ceramics.',
                      style: GoogleFonts.jost(
                        fontSize: 14,
                        color: AppTheme.textLight,
                        height: 1.8,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text(
                      'Close',
                      style: GoogleFonts.jost(
                        fontSize: 13,
                        color: AppTheme.primaryBrown,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),

              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────
// PRIMARY BUTTON — solid brown fill
// ─────────────────────────────────────────

class _PrimaryButton extends StatefulWidget {
  final String label;
  final VoidCallback onTap;
  const _PrimaryButton({required this.label, required this.onTap});

  @override
  State<_PrimaryButton> createState() => _PrimaryButtonState();
}

class _PrimaryButtonState extends State<_PrimaryButton> {
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
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(
            horizontal: 32,
            vertical: 16,
          ),
          decoration: BoxDecoration(
            color: _isHovered
                ? AppTheme.primaryBrown.withOpacity(0.82)
                : AppTheme.primaryBrown,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            widget.label.toUpperCase(),
            style: GoogleFonts.jost(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: Colors.white,
              letterSpacing: 2,
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────
// TEXT BUTTON — underline link style
// ─────────────────────────────────────────

class _TextButton extends StatefulWidget {
  final String label;
  final VoidCallback onTap;
  const _TextButton({required this.label, required this.onTap});

  @override
  State<_TextButton> createState() => _TextButtonState();
}

class _TextButtonState extends State<_TextButton> {
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
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.only(bottom: 2),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: _isHovered
                    ? AppTheme.primaryBrown
                    : AppTheme.primaryBrown.withOpacity(0.35),
                width: 1.5,
              ),
            ),
          ),
          child: Text(
            widget.label.toUpperCase(),
            style: GoogleFonts.jost(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: _isHovered
                  ? AppTheme.primaryBrown
                  : AppTheme.textLight,
              letterSpacing: 2,
            ),
          ),
        ),
      ),
    );
  }
}