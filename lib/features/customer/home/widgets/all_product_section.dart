import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../models/product.dart';
import '../../widgets/product_card.dart';
import '../../widgets/image_gallery.dart';

/// AllProductsSection — grid of all active products from Firestore.
/// Shown below the exhibition section on the home screen.
///
/// Desktop: 4 column grid
/// Mobile:  2 column grid
///
/// Tapping a product image opens the full screen ImageGallery overlay.
/// "Browse by Category" button at bottom navigates to /categories.
///
/// [products]             — from Firestore products/ (all active)
/// [onBrowseCategoryTap]  — navigates to categories screen
/// [isLoading]            — shows shimmer grid while fetching
class AllProductsSection extends StatelessWidget {
  final List<Product> products;
  final VoidCallback onBrowseCategoryTap;
  final bool isLoading;

  const AllProductsSection({
    super.key,
    required this.products,
    required this.onBrowseCategoryTap,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 768;

    // Hide if nothing to show and not loading
    if (!isLoading && products.isEmpty) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      color: AppTheme.background,
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 24 : 80,
        vertical:   isMobile ? 56 : 96,
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1400),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            _buildHeader(isMobile),

            SizedBox(height: isMobile ? 32 : 52),

            isLoading
                ? _buildShimmer(isMobile)
                : _buildGrid(context, isMobile),

            // Browse by category CTA
            if (!isLoading && products.isNotEmpty) ...[
              SizedBox(height: isMobile ? 40 : 64),
              _buildCTA(context),
            ],

          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────
  // HEADER
  // ─────────────────────────────────────────

  Widget _buildHeader(bool isMobile) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [

        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'OUR WORK',
                style: GoogleFonts.jost(
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                  color: AppTheme.primaryBrown.withOpacity(0.55),
                  letterSpacing: 3.5,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'All Products',
                style: GoogleFonts.playfairDisplay(
                  fontSize: isMobile ? 28 : 40,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textDark,
                  letterSpacing: 0.2,
                ),
              ),
            ],
          ),
        ),

        // Browse by category link — desktop only
        if (!isMobile) _BrowseLink(onTap: onBrowseCategoryTap),

      ],
    );
  }

  // ─────────────────────────────────────────
  // PRODUCT GRID
  // ─────────────────────────────────────────

  Widget _buildGrid(BuildContext context, bool isMobile) {
    return GridView.builder(
      // Must use shrinkWrap inside a ScrollView
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount:   isMobile ? 2 : 4,
        crossAxisSpacing: isMobile ? 14 : 24,
        mainAxisSpacing:  isMobile ? 28 : 40,
        // 0.72 gives enough height for image + text below it
        childAspectRatio: 0.72,
      ),
      itemCount: products.length,
      itemBuilder: (context, index) {
        final product = products[index];
        return ProductCard(
          product: product,
          onImageTap: () {
            // Open full screen swipeable gallery
            ImageGallery.show(
              context,
              images: product.imageUrls,
              title:  product.title,
            );
          },
        );
      },
    );
  }

  // ─────────────────────────────────────────
  // BROWSE BY CATEGORY CTA
  // Circular arrow button + label below
  // ─────────────────────────────────────────

  Widget _buildCTA(BuildContext context) {
    return Center(
      child: Column(
        children: [
          _CircleArrowButton(onTap: onBrowseCategoryTap),
          const SizedBox(height: 14),
          Text(
            'BROWSE ALL CATEGORIES',
            style: GoogleFonts.jost(
              fontSize: 10,
              fontWeight: FontWeight.w400,
              color: AppTheme.textLight.withOpacity(0.55),
              letterSpacing: 3,
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────
  // SHIMMER GRID
  // ─────────────────────────────────────────

  Widget _buildShimmer(bool isMobile) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount:   isMobile ? 2 : 4,
        crossAxisSpacing: isMobile ? 14 : 24,
        mainAxisSpacing:  isMobile ? 28 : 40,
        childAspectRatio: 0.72,
      ),
      itemCount: isMobile ? 4 : 8,
      itemBuilder: (_, __) => _ShimmerCard(),
    );
  }
}

// ─────────────────────────────────────────
// BROWSE LINK
// ─────────────────────────────────────────

class _BrowseLink extends StatefulWidget {
  final VoidCallback onTap;
  const _BrowseLink({required this.onTap});

  @override
  State<_BrowseLink> createState() => _BrowseLinkState();
}

class _BrowseLinkState extends State<_BrowseLink> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit:  (_) => setState(() => _isHovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: Row(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.only(bottom: 2),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: _isHovered
                        ? AppTheme.primaryBrown
                        : AppTheme.divider,
                    width: 1,
                  ),
                ),
              ),
              child: Text(
                'BROWSE BY CATEGORY',
                style: GoogleFonts.jost(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 2,
                  color: _isHovered
                      ? AppTheme.primaryBrown
                      : AppTheme.textLight,
                ),
              ),
            ),
            const SizedBox(width: 6),
            AnimatedSlide(
              offset: _isHovered
                  ? const Offset(0.2, 0)
                  : Offset.zero,
              duration: const Duration(milliseconds: 200),
              child: Icon(
                Icons.north_east,
                size: 13,
                color: _isHovered
                    ? AppTheme.primaryBrown
                    : AppTheme.textLight,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────
// CIRCLE ARROW BUTTON
// Rotates 45deg on hover — from HTML reference
// ─────────────────────────────────────────

class _CircleArrowButton extends StatefulWidget {
  final VoidCallback onTap;
  const _CircleArrowButton({required this.onTap});

  @override
  State<_CircleArrowButton> createState() => _CircleArrowButtonState();
}

class _CircleArrowButtonState extends State<_CircleArrowButton> {
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
          width:  64,
          height: 64,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: _isHovered
                ? AppTheme.primaryBrown
                : AppTheme.primaryBrown.withOpacity(0.08),
            border: Border.all(
              color: AppTheme.primaryBrown.withOpacity(0.25),
              width: 1,
            ),
          ),
          child: AnimatedRotation(
            // 45deg rotation on hover — same as HTML reference
            turns:    _isHovered ? 0.125 : 0.0,
            duration: const Duration(milliseconds: 250),
            child: Icon(
              Icons.arrow_forward,
              size:  20,
              color: _isHovered ? Colors.white : AppTheme.primaryBrown,
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────
// SHIMMER CARD
// ─────────────────────────────────────────

class _ShimmerCard extends StatefulWidget {
  @override
  State<_ShimmerCard> createState() => _ShimmerCardState();
}

class _ShimmerCardState extends State<_ShimmerCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _anim = Tween<double>(begin: 0.3, end: 0.7).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (_, __) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Square image placeholder
          AspectRatio(
            aspectRatio: 1.0,
            child: Container(
              decoration: BoxDecoration(
                color: AppTheme.divider.withOpacity(_anim.value),
                borderRadius: const BorderRadius.only(
                  topLeft:     Radius.circular(20),
                  bottomRight: Radius.circular(20),
                  topRight:    Radius.circular(4),
                  bottomLeft:  Radius.circular(4),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          // Title
          Container(
            height: 13,
            width: 100,
            decoration: BoxDecoration(
              color: AppTheme.divider.withOpacity(_anim.value),
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(height: 6),
          // Description line 1
          Container(
            height: 11,
            width: double.infinity,
            decoration: BoxDecoration(
              color: AppTheme.divider.withOpacity(_anim.value * 0.7),
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(height: 4),
          // Description line 2
          Container(
            height: 11,
            width: 70,
            decoration: BoxDecoration(
              color: AppTheme.divider.withOpacity(_anim.value * 0.5),
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        ],
      ),
    );
  }
}