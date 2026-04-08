import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../core/providers/wishlist_provider.dart';
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

  const ExclusiveCard({super.key, required this.product, required this.onTap});

  @override
  State<ExclusiveCard> createState() => _ExclusiveCardState();
}

class _ExclusiveCardState extends State<ExclusiveCard> {
  // Track hover state for zoom and border radius animation
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isCompact = screenWidth < 420;
    final hasDiscount = widget.product.mrp > widget.product.sellingPrice;
    final isSoldOut = widget.product.stockCount <= 0;
    final isWishlisted = context.watch<WishlistProvider>().isWishlisted(
      widget.product.id,
      isExclusive: true,
    );

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image with badges on top
            _buildImage(isSoldOut, isWishlisted),

            const SizedBox(height: 16),

            Text(
              widget.product.editionType.isNotEmpty
                  ? widget.product.editionType.toUpperCase()
                  : 'LIMITED EDITION',
              style: GoogleFonts.jost(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: AppTheme.terracotta,
                letterSpacing: 1.5,
              ),
            ),

            const SizedBox(height: 8),

            // Product title
            Text(
              widget.product.title.isNotEmpty
                  ? widget.product.title
                  : 'Artisanal Masterpiece',
              style: GoogleFonts.playfairDisplay(
                fontSize: isCompact ? 18 : 20,
                fontWeight: FontWeight.w600,
                color: AppTheme.textDark,
                height: 1.2,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),

            const SizedBox(height: 12),

            // Price Row
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  "₹${widget.product.sellingPrice.toInt()}",
                  style: GoogleFonts.jost(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textDark,
                  ),
                ),
                if (hasDiscount) ...[
                  const SizedBox(width: 12),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 2),
                    child: Text(
                      "₹${widget.product.mrp.toInt()}",
                      style: GoogleFonts.jost(
                        fontSize: 14,
                        color: AppTheme.textLight,
                        decoration: TextDecoration.lineThrough,
                      ),
                    ),
                  ),
                ],
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

  Widget _buildImage(bool isSoldOut, bool isWishlisted) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isCompact = screenWidth < 420;

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
              topLeft: const Radius.circular(32),
              bottomRight: Radius.circular(_isHovered ? 16 : 32),
              topRight: const Radius.circular(8),
              bottomLeft: const Radius.circular(8),
            ),
          ),
          child: AspectRatio(
            aspectRatio: isCompact ? 1 / 1.18 : 4 / 5,
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

        // SOLD OUT Overlay
        if (isSoldOut)
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.4),
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(32),
                  bottomRight: Radius.circular(_isHovered ? 16 : 32),
                  topRight: const Radius.circular(8),
                  bottomLeft: const Radius.circular(8),
                ),
              ),
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    "SOLD OUT",
                    style: GoogleFonts.jost(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textDark,
                      letterSpacing: 2,
                    ),
                  ),
                ),
              ),
            ),
          ),

        // LIMITED EDITION label — top left corner
        Positioned(
          top: isCompact ? 12 : 16,
          left: isCompact ? 12 : 16,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.9),
              borderRadius: BorderRadius.circular(4),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Text(
              'EXCLUSIVE',
              style: GoogleFonts.jost(
                fontSize: 9,
                fontWeight: FontWeight.w700,
                color: AppTheme.terracotta,
                letterSpacing: 1.5,
              ),
            ),
          ),
        ),

        // Certificate badge
        if (widget.product.hasCertificate)
          Positioned(
            bottom: isCompact ? 12 : 16,
            right: isCompact ? 12 : 16,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.verified_user_outlined,
                size: 16,
                color: AppTheme.terracotta,
              ),
            ),
          ),
        Positioned(
          top: isCompact ? 12 : 16,
          right: isCompact ? 12 : 16,
          child: Material(
            color: Colors.white.withOpacity(0.9),
            shape: const CircleBorder(),
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: () {
                context.read<WishlistProvider>().toggle(
                  widget.product.id,
                  isExclusive: true,
                );
              },
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Icon(
                  isWishlisted ? Icons.favorite : Icons.favorite_border,
                  size: 18,
                  color: isWishlisted ? AppTheme.terracotta : AppTheme.textDark,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
