import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_theme.dart';
import '../../../models/product.dart';
import 'image_placeholder.dart';

/// ExclusiveCard — editorial style card for exclusive/limited edition products.
/// Used in ExclusiveSection on the home screen.
///
/// Features:
/// - Portrait image (4:5 ratio) with hover zoom effect
/// - "LIMITED EDITION" label on top left
/// - Certificate badge on bottom right (only if hasCertificate is true)
/// - Title, description, total pieces count below image
///
/// [product]  — ExclusiveProduct fetched from Firestore exclusive_products/
/// [onTap]    — called when card is tapped, navigates to exclusive detail page
class ExclusiveCard extends StatefulWidget {
  final ExclusiveProduct product;
  final VoidCallback onTap;

  const ExclusiveCard({
    super.key,
    required this.product,
    required this.onTap,
  });

  @override
  State<ExclusiveCard> createState() => _ExclusiveCardState();
}

class _ExclusiveCardState extends State<ExclusiveCard> {
  // Track hover state for zoom and border radius animation
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit:  (_) => setState(() => _isHovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            // Image with badges on top
            _buildImage(),

            const SizedBox(height: 12),

            // Product title — serif font for premium feel
            Text(
              widget.product.title.isNotEmpty 
                  ? widget.product.title 
                  : 'Item not available',
              style: GoogleFonts.playfairDisplay(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppTheme.textDark,
                letterSpacing: 0.1,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),

            const SizedBox(height: 4),

            // Short description
            Text(
              widget.product.description.isNotEmpty 
                  ? widget.product.description 
                  : 'Description not available',
              style: GoogleFonts.jost(
                fontSize: 12,
                fontWeight: FontWeight.w400,
                color: AppTheme.textLight,
                height: 1.4,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),

            const SizedBox(height: 8),

            // LIMITED PRODUCT label — from user requirements
            Row(
              children: [
                Icon(
                  Icons.auto_awesome,
                  size: 11,
                  color: AppTheme.terracotta,
                ),
                const SizedBox(width: 6),
                Text(
                  'LIMITED PRODUCT',
                  style: GoogleFonts.jost(
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.terracotta,
                    letterSpacing: 1.2,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 6),

            // Total pieces — shown as a subtle info row
            Row(
              children: [
                Icon(
                  Icons.inventory_2_outlined,
                  size: 13,
                  color: AppTheme.primaryBrown.withOpacity(0.55),
                ),
                const SizedBox(width: 5),
                Text(
                  '${widget.product.totalPieces} '
                  '${widget.product.totalPieces == 1 ? 'piece' : 'pieces'} only',
                  style: GoogleFonts.jost(
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                    color: AppTheme.primaryBrown.withOpacity(0.65),
                    letterSpacing: 0.3,
                  ),
                ),
              ],
            ),

          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────
  // IMAGE SECTION
  // ─────────────────────────────────────────

  Widget _buildImage() {
    return Stack(
      children: [

        // Main image container — 4:5 portrait ratio
        AnimatedContainer(
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeOut,
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: AppTheme.divider.withOpacity(0.35),
            // Corner shape animates slightly on hover
            borderRadius: BorderRadius.only(
              topLeft:     const Radius.circular(32),
              bottomRight: Radius.circular(_isHovered ? 16 : 32),
              topRight:    const Radius.circular(8),
              bottomLeft:  const Radius.circular(8),
            ),
          ),
          child: AspectRatio(
            aspectRatio: 4 / 5,
            child: widget.product.primaryImage.isNotEmpty
                ? AnimatedScale(
                    // Subtle zoom on hover
                    scale: _isHovered ? 1.05 : 1.0,
                    duration: const Duration(milliseconds: 500),
                    curve: Curves.easeOut,
                    child: NetworkImageWithPlaceholder(
                      url: widget.product.primaryImage,
                      fit: BoxFit.cover,
                    ),
                  )
                : const ImagePlaceholder(
                    aspectRatio: 4 / 5,
                    icon: Icons.auto_awesome_outlined,
                  ),
          ),
        ),

        // LIMITED EDITION label — top left corner
        Positioned(
          top: 10,
          left: 10,
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 8,
              vertical: 4,
            ),
            decoration: BoxDecoration(
              color: AppTheme.appBackground,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              'LIMITED EDITION',
              style: GoogleFonts.jost(
                fontSize: 8,
                fontWeight: FontWeight.w600,
                color: AppTheme.lightBrown,
                letterSpacing: 1.5,
              ),
            ),
          ),
        ),

        // Certificate badge — bottom right, only if hasCertificate is true
        if (widget.product.hasCertificate)
          Positioned(
            bottom: 10,
            right: 10,
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 8,
                vertical: 4,
              ),
              decoration: BoxDecoration(
                color: AppTheme.primaryBrown,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.workspace_premium_outlined,
                    size: 12,
                    color: AppTheme.white,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Certificate',
                    style: GoogleFonts.jost(
                      fontSize: 9,
                      fontWeight: FontWeight.w500,
                      color: AppTheme.white,
                      letterSpacing: 0.2,
                    ),
                  ),
                ],
              ),
            ),
          ),

      ],
    );
  }
}