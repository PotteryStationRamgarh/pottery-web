import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_theme.dart';
import '../../../models/product.dart';
import 'image_placeholder.dart';

/// ProductCard — standard product card for the all products grid.
/// Used in AllProductsSection on the home screen.
///
/// No price shown — this is a showcase not a shop.
/// Tapping the image opens the full screen image gallery.
///
/// [product]      — Product fetched from Firestore products/
/// [onImageTap]   — opens full screen swipeable gallery overlay
class ProductCard extends StatefulWidget {
  final Product product;
  final VoidCallback onImageTap;

  const ProductCard({
    super.key,
    required this.product,
    required this.onImageTap,
  });

  @override
  State<ProductCard> createState() => _ProductCardState();
}

class _ProductCardState extends State<ProductCard> {
  // Track hover for image zoom and border radius animation
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit:  (_) => setState(() => _isHovered = false),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          // Tappable image — opens gallery on tap
          _buildImage(),

          const SizedBox(height: 12),

          // Product name
          Text(
            widget.product.title,
            style: GoogleFonts.jost(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppTheme.textDark,
              letterSpacing: 0.1,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),

          const SizedBox(height: 4),

          // Short description — 2 lines max
          Text(
            widget.product.description,
            style: GoogleFonts.jost(
              fontSize: 12,
              fontWeight: FontWeight.w400,
              color: AppTheme.textLight,
              height: 1.5,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),

          // Show photo count hint only if product has multiple images
          // Lets user know they can see more by tapping
          if (widget.product.imageUrls.length > 1) ...[
            const SizedBox(height: 6),
            Row(
              children: [
                Icon(
                  Icons.photo_library_outlined,
                  size: 11,
                  color: AppTheme.greyPlaceholder,
                ),
                const SizedBox(width: 4),
                Text(
                  '${widget.product.imageUrls.length} photos',
                  style: GoogleFonts.jost(
                    fontSize: 11,
                    color: AppTheme.greyPlaceholder,
                    letterSpacing: 0.2,
                  ),
                ),
              ],
            ),
          ],

        ],
      ),
    );
  }

  // ─────────────────────────────────────────
  // IMAGE
  // ─────────────────────────────────────────

  Widget _buildImage() {
    return GestureDetector(
      onTap: widget.onImageTap,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: AppTheme.divider.withOpacity(0.3),
            // Corners animate smoothly on hover
            borderRadius: BorderRadius.only(
              topLeft:     const Radius.circular(20),
              bottomRight: const Radius.circular(20),
              topRight:    Radius.circular(_isHovered ? 20 : 4),
              bottomLeft:  Radius.circular(_isHovered ? 20 : 4),
            ),
          ),
          child: AspectRatio(
            // Square cards look clean in a grid layout
            aspectRatio: 1.0,
            child: widget.product.primaryImage.isNotEmpty
                ? AnimatedScale(
                    // Subtle zoom on hover
                    scale: _isHovered ? 1.04 : 1.0,
                    duration: const Duration(milliseconds: 400),
                    curve: Curves.easeOut,
                    child: NetworkImageWithPlaceholder(
                      url: widget.product.primaryImage,
                      fit: BoxFit.cover,
                    ),
                  )
                : const ImagePlaceholder(
                    aspectRatio: 1.0,
                  ),
          ),
        ),
      ),
    );
  }
}