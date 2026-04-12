import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../app/routes.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/responsive_utils.dart';
import '../../../../models/product.dart';
import '../../widgets/product_card.dart';

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
    final isMobile = ResponsiveBreakpoints.isMobile(context);
    final isTablet = ResponsiveBreakpoints.isTablet(context);

    // We NO LONGER hide if products are empty — per user request to always show cards.
    // if (!isLoading && products.isEmpty) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      color: AppTheme.background,
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 24 : 80,
        vertical: isMobile ? 56 : 96,
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1400),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(context, isMobile),

            SizedBox(height: isMobile ? 32 : 52),

            // Grid of products
            isLoading
                ? _buildShimmer(isMobile, isTablet)
                : (products.isEmpty)
                ? _buildFallbackGrid(context, isMobile, isTablet)
                : _buildGrid(context, isMobile, isTablet),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────
  // HEADER
  // ─────────────────────────────────────────

  Widget _buildHeader(BuildContext context, bool isMobile) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final stack = ResponsiveBreakpoints.isMobileWidth(constraints.maxWidth);
        final title = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'OUR WORK',
              style: GoogleFonts.jost(
                fontSize: 10,
                fontWeight: FontWeight.w500,
                color: AppTheme.primaryBrown.withValues(alpha: 0.55),
                letterSpacing: 3.5,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Collections',
              style: GoogleFonts.playfairDisplay(
                fontSize: isMobile ? 28 : 40,
                fontWeight: FontWeight.w600,
                color: AppTheme.textDark,
                letterSpacing: 0.2,
              ),
            ),
          ],
        );

        final link = _BrowseLink(
          onTap: () {
            Navigator.pushNamed(context, Routes.categories);
          },
        );

        if (stack) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [title, const SizedBox(height: 16), link],
          );
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(child: title),
            const SizedBox(width: 16),
            link,
          ],
        );
      },
    );
  }

  // ─────────────────────────────────────────
  // PRODUCT GRID
  // ─────────────────────────────────────────

  Widget _buildGrid(BuildContext context, bool isMobile, bool isTablet) {
    return GridView.builder(
      // Must use shrinkWrap inside a ScrollView
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: isMobile ? 2 : (isTablet ? 3 : 4),
        crossAxisSpacing: isMobile ? 14 : 24,
        mainAxisSpacing: isMobile ? 28 : 40,
        // 0.72 gives enough height for image + text below it
        childAspectRatio: 0.72,
      ),
      itemCount: products.take(4).length,
      itemBuilder: (context, index) {
        final product = products.take(4).toList()[index];
        return ProductCard(product: product);
      },
    );
  }

  // ─────────────────────────────────────────
  // SHIMMER GRID
  // ─────────────────────────────────────────

  Widget _buildShimmer(bool isMobile, bool isTablet) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: isMobile ? 2 : (isTablet ? 3 : 4),
        crossAxisSpacing: isMobile ? 14 : 24,
        mainAxisSpacing: isMobile ? 28 : 40,
        childAspectRatio: 0.72,
      ),
      itemCount: isMobile ? 4 : (isTablet ? 6 : 8),
      itemBuilder: (_, _) => _ShimmerCard(),
    );
  }

  // ─────────────────────────────────────────
  // FALLBACK GRID — shown when Firestore returns no products
  // ─────────────────────────────────────────

  Widget _buildFallbackGrid(
    BuildContext context,
    bool isMobile,
    bool isTablet,
  ) {
    // Show exactly 4 dummy cards as requested
    final fallbacks = List.generate(
      4,
      (i) => Product(
        id: 'fallback_$i',
        title: 'Item not available',
        description: 'Description not available',
        imageUrls: [],
        categoryId: '',
        order: i,
        isActive: true,
      ),
    );

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: isMobile ? 2 : (isTablet ? 3 : 4),
        crossAxisSpacing: isMobile ? 14 : 24,
        mainAxisSpacing: isMobile ? 28 : 40,
        childAspectRatio: 0.72,
      ),
      itemCount: fallbacks.length,
      itemBuilder: (context, index) {
        return ProductCard(product: fallbacks[index]);
      },
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
      onExit: (_) => setState(() => _isHovered = false),
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
              offset: _isHovered ? const Offset(0.2, 0) : Offset.zero,
              duration: const Duration(milliseconds: 200),
              child: Icon(
                Icons.north_east,
                size: 13,
                color: _isHovered ? AppTheme.primaryBrown : AppTheme.textLight,
              ),
            ),
          ],
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
    _anim = Tween<double>(
      begin: 0.3,
      end: 0.7,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
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
      builder: (_, _) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Square image placeholder
          AspectRatio(
            aspectRatio: 1.0,
            child: Container(
              decoration: BoxDecoration(
                color: AppTheme.divider.withValues(alpha: _anim.value),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(20),
                  bottomRight: Radius.circular(20),
                  topRight: Radius.circular(4),
                  bottomLeft: Radius.circular(4),
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
              color: AppTheme.divider.withValues(alpha: _anim.value),
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(height: 6),
          // Description line 1
          Container(
            height: 11,
            width: double.infinity,
            decoration: BoxDecoration(
              color: AppTheme.divider.withValues(alpha: _anim.value * 0.7),
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(height: 4),
          // Description line 2
          Container(
            height: 11,
            width: 70,
            decoration: BoxDecoration(
              color: AppTheme.divider.withValues(alpha: _anim.value * 0.5),
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        ],
      ),
    );
  }
}
