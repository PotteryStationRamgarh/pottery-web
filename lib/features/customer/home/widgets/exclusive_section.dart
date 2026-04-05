import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/responsive_utils.dart';
import '../../../../models/product.dart';
import '../../../../app/routes.dart';
import '../../widgets/exclusive_card.dart';

/// ExclusiveSection — editorial showcase of limited edition products.
/// Shown directly below the hero section on the home screen.
///
/// Desktop layout:
/// 3 column grid — middle card is offset down for a staggered look
/// just like the HTML reference collections grid.
///
/// Mobile layout:
/// Horizontal scrollable row — one card visible at a time with peek.
///
/// Section is completely hidden if no exclusive products exist in Firestore
/// and isLoading is false — no empty state shown.
///
/// [products]     — list from Firestore exclusive_products/
/// [onProductTap] — navigates to exclusive detail page
/// [isLoading]    — shows shimmer cards while fetching from Firestore
class ExclusiveSection extends StatelessWidget {
  final List<ExclusiveProduct> products;
  final void Function(ExclusiveProduct product) onProductTap;
  final bool isLoading;

  const ExclusiveSection({
    super.key,
    required this.products,
    required this.onProductTap,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    final isMobile = ResponsiveBreakpoints.isMobile(context);

    // Hide if products are empty
    if (!isLoading && products.isEmpty) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      color: AppTheme.background,
      padding: EdgeInsets.fromLTRB(
        isMobile ? 24 : 80,
        isMobile ? 24 : 40,
        isMobile ? 24 : 80,
        isMobile ? 56 : 96,
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1400),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Section header
            _buildHeader(context, isMobile),

            SizedBox(height: isMobile ? 32 : 56),

            // Content — shimmer while loading, real cards when ready
            isLoading
                ? _buildShimmer(isMobile)
                : (products.isEmpty)
                ? _buildFallbackGrid(isMobile)
                : isMobile
                ? _buildMobileScroll()
                : _buildDesktopGrid(),
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
        final isNarrowHeader = ResponsiveBreakpoints.isMobileWidth(
          constraints.maxWidth,
        );

        return isNarrowHeader
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildTitleColumn(isMobile),
                  const SizedBox(height: 16),
                  _ViewAllLink(
                    onTap: () {
                      Navigator.pushNamed(context, Routes.exclusiveList);
                    },
                  ),
                ],
              )
            : Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(child: _buildTitleColumn(isMobile)),
                  const SizedBox(width: 16),
                  _ViewAllLink(
                    onTap: () {
                      Navigator.pushNamed(context, Routes.exclusiveList);
                    },
                  ),
                ],
              );
      },
    );
  }

  Widget _buildTitleColumn(bool isMobile) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'CURATED SERIES',
          style: GoogleFonts.jost(
            fontSize: 10,
            fontWeight: FontWeight.w500,
            color: AppTheme.primaryBrown.withOpacity(0.55),
            letterSpacing: 3.5,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          'Exclusive Collection',
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: GoogleFonts.playfairDisplay(
            fontSize: isMobile ? 28 : 40,
            fontWeight: FontWeight.w600,
            color: AppTheme.textDark,
            letterSpacing: 0.2,
          ),
        ),
      ],
    );
  }

  // ─────────────────────────────────────────
  // FALLBACK GRID — empty data state
  // ─────────────────────────────────────────

  Widget _buildFallbackGrid(bool isMobile) {
    // Generate 3 dummy products to satisfy the "Always render cards" requirement
    final fallbacks = List.generate(
      3,
      (i) => ExclusiveProduct(
        id: 'fallback_$i',
        title: 'Item not available',
        description: 'Description not available',
        imageUrls: [],
        totalPieces: 0,
        hasCertificate: false,
        material: 'Premium Clay',
        craftingTime: '6-8 Weeks',
        order: i,
        isActive: true,
      ),
    );

    if (isMobile) {
      return SizedBox(
        height:
            500, // Increased from 420 to prevent "LIMITED PRODUCT" badge overflow
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          itemCount: 3,
          itemBuilder: (context, index) {
            return SizedBox(
              width: 260,
              child: Padding(
                padding: EdgeInsets.only(right: index < 2 ? 16 : 0),
                child: ExclusiveCard(product: fallbacks[index], onTap: () {}),
              ),
            );
          },
        ),
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: List.generate(3, (index) {
        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(
              top: index == 1 ? 64.0 : 0.0, // Staggered look
              left: index == 0 ? 0.0 : 20.0,
              right: index == 2 ? 0.0 : 20.0,
            ),
            child: ExclusiveCard(product: fallbacks[index], onTap: () {}),
          ),
        );
      }),
    );
  }

  // ─────────────────────────────────────────
  // DESKTOP GRID — staggered 3 columns
  // ─────────────────────────────────────────

  Widget _buildDesktopGrid() {
    // Show max 3 products on home screen
    final items = products.take(3).toList();

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: List.generate(items.length, (index) {
        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(
              // Middle card pushed down for editorial stagger effect
              top: index == 1 ? 64.0 : 0.0,
              left: index == 0 ? 0.0 : 20.0,
              right: index == items.length - 1 ? 0.0 : 20.0,
            ),
            child: ExclusiveCard(
              product: items[index],
              onTap: () => onProductTap(items[index]),
            ),
          ),
        );
      }),
    );
  }

  // ─────────────────────────────────────────
  // MOBILE HORIZONTAL SCROLL
  // ─────────────────────────────────────────

  Widget _buildMobileScroll() {
    return SizedBox(
      height:
          500, // Increased from 420 to prevent "LIMITED PRODUCT" badge overflow
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: products.length,
        itemBuilder: (context, index) {
          return SizedBox(
            width: 260,
            child: Padding(
              padding: EdgeInsets.only(
                right: index < products.length - 1 ? 16 : 0,
              ),
              child: ExclusiveCard(
                product: products[index],
                onTap: () => onProductTap(products[index]),
              ),
            ),
          );
        },
      ),
    );
  }

  // ─────────────────────────────────────────
  // SHIMMER — shown while loading from Firestore
  // ─────────────────────────────────────────

  Widget _buildShimmer(bool isMobile) {
    if (isMobile) {
      return SizedBox(
        height: 420,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          itemCount: 3,
          itemBuilder: (_, index) => Padding(
            padding: EdgeInsets.only(right: index < 2 ? 16 : 0),
            child: SizedBox(width: 260, child: _ShimmerCard()),
          ),
        ),
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: List.generate(3, (index) {
        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(
              top: index == 1 ? 64.0 : 0.0,
              left: index == 0 ? 0.0 : 20.0,
              right: index == 2 ? 0.0 : 20.0,
            ),
            child: _ShimmerCard(),
          ),
        );
      }),
    );
  }
}

// ─────────────────────────────────────────
// VIEW ALL LINK
// ─────────────────────────────────────────

class _ViewAllLink extends StatefulWidget {
  final VoidCallback onTap;
  const _ViewAllLink({required this.onTap});

  @override
  State<_ViewAllLink> createState() => _ViewAllLinkState();
}

class _ViewAllLinkState extends State<_ViewAllLink> {
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
                'VIEW ALL',
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
// Animated placeholder shown while products load
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
      builder: (_, __) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image placeholder — same 4:5 ratio as real card
          AspectRatio(
            aspectRatio: 4 / 5,
            child: Container(
              decoration: BoxDecoration(
                color: AppTheme.divider.withOpacity(_anim.value),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(32),
                  bottomRight: Radius.circular(32),
                  topRight: Radius.circular(8),
                  bottomLeft: Radius.circular(8),
                ),
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Title placeholder
          Container(
            height: 18,
            width: 160,
            decoration: BoxDecoration(
              color: AppTheme.divider.withOpacity(_anim.value),
              borderRadius: BorderRadius.circular(4),
            ),
          ),

          const SizedBox(height: 8),

          // Description placeholder
          Container(
            height: 13,
            width: double.infinity,
            decoration: BoxDecoration(
              color: AppTheme.divider.withOpacity(_anim.value * 0.7),
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        ],
      ),
    );
  }
}
