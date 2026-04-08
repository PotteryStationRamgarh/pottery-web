import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../app/routes.dart';
import '../../../core/providers/wishlist_provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../models/product.dart';
import 'image_placeholder.dart';

/// ProductCard — updated for ecommerce.
/// Shows price and navigates to ProductDetailScreen.
class ProductCard extends StatefulWidget {
  final Product product;

  const ProductCard({super.key, required this.product});

  @override
  State<ProductCard> createState() => _ProductCardState();
}

class _ProductCardState extends State<ProductCard> {
  bool _isHovered = false;

  void _navigateToDetail() {
    Navigator.pushNamed(
      context,
      Routes.productDetail,
      arguments: widget.product.id,
    );
  }

  @override
  Widget build(BuildContext context) {
    final hasDiscount = widget.product.mrp > widget.product.sellingPrice;
    final isSoldOut = widget.product.stockCount <= 0;
    final isWishlisted = context.watch<WishlistProvider>().isWishlisted(
      widget.product.id,
    );

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: _navigateToDetail,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image Section
            _buildImage(isSoldOut, isWishlisted),

            const SizedBox(height: 12),

            // Category/Tag hint
            if (widget.product.tags.isNotEmpty)
              Text(
                widget.product.tags.first.toUpperCase(),
                style: GoogleFonts.jost(
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                  color: AppTheme.terracotta,
                  letterSpacing: 1.2,
                ),
              ),

            const SizedBox(height: 4),

            // Product name
            Text(
              widget.product.title.isNotEmpty
                  ? widget.product.title
                  : 'Artisanal Piece',
              style: GoogleFonts.jost(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppTheme.textDark,
                letterSpacing: 0.1,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),

            const SizedBox(height: 6),

            // Price Row
            Row(
              children: [
                Text(
                  "₹${widget.product.sellingPrice.toInt()}",
                  style: GoogleFonts.jost(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textDark,
                  ),
                ),
                if (hasDiscount) ...[
                  const SizedBox(width: 8),
                  Text(
                    "₹${widget.product.mrp.toInt()}",
                    style: GoogleFonts.jost(
                      fontSize: 12,
                      color: AppTheme.textLight,
                      decoration: TextDecoration.lineThrough,
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

  Widget _buildImage(bool isSoldOut, bool isWishlisted) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: AppTheme.divider.withValues(alpha: 0.3),
        borderRadius: BorderRadius.only(
          topLeft: const Radius.circular(20),
          bottomRight: const Radius.circular(20),
          topRight: Radius.circular(_isHovered ? 20 : 4),
          bottomLeft: Radius.circular(_isHovered ? 20 : 4),
        ),
      ),
      child: Stack(
        children: [
          AspectRatio(
            aspectRatio: 1.0,
            child: widget.product.primaryImage.isNotEmpty
                ? AnimatedScale(
                    scale: _isHovered ? 1.05 : 1.0,
                    duration: const Duration(milliseconds: 400),
                    curve: Curves.easeOut,
                    child: NetworkImageWithPlaceholder(
                      url: widget.product.primaryImage,
                      fit: BoxFit.cover,
                    ),
                  )
                : const ImagePlaceholder(aspectRatio: 1.0),
          ),
          if (isSoldOut)
            Positioned.fill(
              child: Container(
                color: Colors.black.withValues(alpha: 0.4),
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      "SOLD OUT",
                      style: GoogleFonts.jost(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textDark,
                        letterSpacing: 1,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          Positioned(
            top: 12,
            right: 12,
            child: Material(
              color: Colors.white.withValues(alpha: 0.9),
              shape: const CircleBorder(),
              child: InkWell(
                customBorder: const CircleBorder(),
                onTap: () {
                  context.read<WishlistProvider>().toggle(widget.product.id);
                },
                child: Padding(
                  padding: const EdgeInsets.all(10),
                  child: Icon(
                    isWishlisted ? Icons.favorite : Icons.favorite_border,
                    size: 18,
                    color: isWishlisted
                        ? AppTheme.terracotta
                        : AppTheme.textDark,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
