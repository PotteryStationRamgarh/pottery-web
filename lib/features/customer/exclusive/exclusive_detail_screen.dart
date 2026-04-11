import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../app/routes.dart';
import '../../../core/providers/wishlist_provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/responsive_utils.dart';
import '../../../core/utils/storefront_filters.dart';
import '../../../models/product.dart';
import '../../../core/providers/cart_provider.dart';
import '../../admin/catalog/repositories/exclusive_product_repository.dart';
import '../home/widgets/nav_bar.dart';
import '../home/home_footer.dart';

class ExclusiveDetailScreen extends StatefulWidget {
  final ExclusiveProduct? product;
  final String? productId;

  const ExclusiveDetailScreen({super.key, this.product, this.productId});

  @override
  State<ExclusiveDetailScreen> createState() => _ExclusiveDetailScreenState();
}

class _ExclusiveDetailScreenState extends State<ExclusiveDetailScreen> {
  int _activeImageIndex = 0;
  ExclusiveProduct? _product;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.product != null) {
      _product = widget.product;
    } else if (widget.productId != null) {
      _loadProduct();
    }
  }

  Future<void> _loadProduct() async {
    setState(() => _isLoading = true);
    try {
      final p = await ExclusiveProductRepository.getExclusiveProduct(
        widget.productId!,
      );
      if (mounted) {
        setState(() => _product = p);
      }
    } catch (e) {
      debugPrint('Error loading exclusive product: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: AppTheme.background,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_product == null) {
      return const Scaffold(
        backgroundColor: AppTheme.background,
        body: Center(child: Text("Piece not found")),
      );
    }

    final List<String> allImages = _product!.imageUrls;
    final isMobile = ResponsiveBreakpoints.isMobile(context);

    return Scaffold(
      backgroundColor: AppTheme.background,
      endDrawer: const NavDrawer(),
      body: Stack(
        children: [
          SingleChildScrollView(
            child: Column(
              children: [
                const SizedBox(height: 80), // Spacing for NavBar
                // Main Content
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: isMobile ? 24 : 48),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1320),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Breadcrumb-style navigation (Back button)
                        TextButton.icon(
                          onPressed: () {
                            if (Navigator.canPop(context)) {
                              Navigator.pop(context);
                            } else {
                              Navigator.pushReplacementNamed(
                                context,
                                Routes.customerHome,
                              );
                            }
                          },
                          icon: const Icon(Icons.arrow_back, size: 18),
                          label: Text(
                            'Back to Home',
                            style: GoogleFonts.jost(
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          style: TextButton.styleFrom(
                            foregroundColor: AppTheme.textDark,
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Layout: Images on left (desktop), Info on right
                        if (allImages.isNotEmpty)
                          isMobile
                              ? _buildMobileLayout(allImages)
                              : _buildDesktopLayout(allImages)
                        else
                          const Center(child: Text("No images available")),

                        const SizedBox(height: 64),
                        _buildExtendedDetails(),
                        const SizedBox(height: 64),
                      ],
                    ),
                  ),
                ),

                const HomeFooter(),
              ],
            ),
          ),
          const Positioned(top: 0, left: 0, right: 0, child: NavBar()),
        ],
      ),
    );
  }

  Widget _buildDesktopLayout(List<String> allImages) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (!ResponsiveBreakpoints.isDesktopWidth(constraints.maxWidth)) {
          return _buildMobileLayout(allImages);
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image Gallery (Left)
            Expanded(
              flex: 1,
              child: Column(
                children: [
                  // Main Image - AspectRatio 1:1 to shrink vertical height
                  AspectRatio(
                    aspectRatio: 1 / 1,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        image: DecorationImage(
                          image: NetworkImage(allImages[_activeImageIndex]),
                          fit: BoxFit.cover,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.05),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  // Thumbnails
                  if (allImages.length > 1)
                    SizedBox(
                      height: 80,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: allImages.length,
                        separatorBuilder: (context, index) =>
                            const SizedBox(width: 12),
                        itemBuilder: (context, index) => GestureDetector(
                          onTap: () =>
                              setState(() => _activeImageIndex = index),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            width: 80,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: _activeImageIndex == index
                                    ? AppTheme.terracotta
                                    : Colors.transparent,
                                width: 2,
                              ),
                              image: DecorationImage(
                                image: NetworkImage(allImages[index]),
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),

            const SizedBox(width: 48),

            // Product Details (Right)
            Expanded(
              flex: 1,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 500),
                child: _buildProductInfo(),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildMobileLayout(List<String> allImages) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Main Image Slider
        AspectRatio(
          aspectRatio: 1 / 1, // Shrink height on mobile too
          child: PageView.builder(
            onPageChanged: (idx) => setState(() => _activeImageIndex = idx),
            itemCount: allImages.length,
            itemBuilder: (context, index) => Container(
              margin: const EdgeInsets.symmetric(horizontal: 4),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                image: DecorationImage(
                  image: NetworkImage(allImages[index]),
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 24),
        _buildProductInfo(),
      ],
    );
  }

  Widget _buildProductInfo() {
    final hasDiscount = _product!.mrp > _product!.sellingPrice;
    final isSoldOut = _product!.stockCount <= 0;
    final discountPercent = hasDiscount
        ? (((_product!.mrp - _product!.sellingPrice) / _product!.mrp) * 100)
              .round()
        : 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Badge
        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: AppTheme.terracotta.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(30),
              ),
              child: Text(
                _product!.editionType.isNotEmpty
                    ? _product!.editionType.toUpperCase()
                    : 'EXCLUSIVE PIECE',
                style: GoogleFonts.jost(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.terracotta,
                  letterSpacing: 1.2,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Text(
                _product!.title,
                style: GoogleFonts.playfairDisplay(
                  fontSize: ResponsiveBreakpoints.isMobile(context) ? 32 : 40,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textDark,
                ),
              ),
            ),
            const SizedBox(width: 16),
            OutlinedButton.icon(
              onPressed: () {
                context.read<WishlistProvider>().toggle(
                  _product!.id,
                  isExclusive: true,
                );
              },
              icon: Icon(
                context.watch<WishlistProvider>().isWishlisted(
                      _product!.id,
                      isExclusive: true,
                    )
                    ? Icons.favorite
                    : Icons.favorite_border,
                size: 18,
              ),
              label: const Text('ADD TO WISHLIST'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppTheme.terracotta,
                side: const BorderSide(color: AppTheme.terracotta),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        Wrap(
          crossAxisAlignment: WrapCrossAlignment.end,
          spacing: 12,
          runSpacing: 8,
          children: [
            if (hasDiscount)
              Text(
                '-$discountPercent%',
                style: GoogleFonts.jost(
                  fontSize: 30,
                  fontWeight: FontWeight.w300,
                  color: AppTheme.terracotta,
                ),
              ),
            Text(
              "₹${_product!.sellingPrice.toInt()}",
              style: GoogleFonts.jost(
                fontSize: 34,
                fontWeight: FontWeight.w600,
                color: AppTheme.textDark,
              ),
            ),
          ],
        ),
        if (hasDiscount) ...[
          const SizedBox(height: 6),
          Text.rich(
            TextSpan(
              children: [
                TextSpan(
                  text: 'M.R.P. ',
                  style: GoogleFonts.jost(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textLight,
                  ),
                ),
                TextSpan(
                  text: '₹${_product!.mrp.toInt()}',
                  style: GoogleFonts.jost(
                    fontSize: 16,
                    color: AppTheme.textLight,
                    decoration: TextDecoration.lineThrough,
                  ),
                ),
              ],
            ),
          ),
        ],
        const SizedBox(height: 8),
        Text(
          "Free delivery",
          style: GoogleFonts.jost(
            fontSize: 13,
            color: AppTheme.textLight,
            fontStyle: FontStyle.italic,
          ),
        ),
        const SizedBox(height: 24),

        // Features Grid
        Wrap(
          spacing: 12,
          runSpacing: 8,
          children: [
            _buildFeatureTag(Icons.auto_awesome, 'Handmade'),
            if (_product!.hasCertificate)
              _buildFeatureTag(Icons.verified_user_outlined, 'Certified'),
          ],
        ),
        const SizedBox(height: 32),

        Text(
          'The Story',
          style: GoogleFonts.jost(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 12),
        Text(
          _product!.description,
          style: AppTheme.bodyLarge.copyWith(height: 1.8, fontSize: 15),
        ),
        const SizedBox(height: 32),

        // Add to Cart
        SizedBox(
          width: double.infinity,
          height: 60,
          child: ElevatedButton(
            onPressed: isSoldOut
                ? null
                : () {
                    context.read<CartProvider>().addItem(_product!);
                    ScaffoldMessenger.of(context)
                      ..clearSnackBars()
                      ..showSnackBar(
                        SnackBar(
                          behavior: SnackBarBehavior.floating,
                          duration: const Duration(seconds: 2),
                          backgroundColor: AppTheme.terracotta,
                          content: const Text("Added exclusive piece to cart"),
                          action: SnackBarAction(
                            label: "VIEW CART",
                            onPressed: () =>
                                Navigator.pushNamed(context, Routes.cart),
                            textColor: Colors.white,
                          ),
                        ),
                      );
                  },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.terracotta,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              isSoldOut ? "SOLD OUT" : "INQUIRE / PURCHASE",
              style: GoogleFonts.jost(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                letterSpacing: 2,
              ),
            ),
          ),
        ),
        const SizedBox(height: 32),
      ],
    );
  }

  Widget _buildExtendedDetails() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_product!.artistNote.isNotEmpty) ...[
          Text("Artist's Note", style: AppTheme.serifHeadingMedium),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppTheme.exhibitionBackground,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppTheme.divider),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.format_quote,
                  color: AppTheme.terracotta,
                  size: 32,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    _product!.artistNote,
                    style: GoogleFonts.jost(
                      fontSize: 16,
                      height: 1.6,
                      fontStyle: FontStyle.italic,
                      color: AppTheme.textDark,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 48),
        ],

        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (StorefrontFilters.careInstructionsForExclusive(
              _product!,
            ).isNotEmpty)
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Care & Handling",
                      style: GoogleFonts.jost(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    ...StorefrontFilters.careInstructionsForExclusive(
                      _product!,
                    ).map(
                      (item) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.check_circle_outline,
                              size: 16,
                              color: AppTheme.terracotta,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                item,
                                style: GoogleFonts.jost(fontSize: 14),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            if (_product!.tags.isNotEmpty) ...[
              const SizedBox(width: 48),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Tags",
                      style: GoogleFonts.jost(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _product!.tags
                          .map(
                            (tag) => Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                border: Border.all(color: AppTheme.divider),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                "#$tag",
                                style: GoogleFonts.jost(
                                  fontSize: 12,
                                  color: AppTheme.textLight,
                                ),
                              ),
                            ),
                          )
                          .toList(),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }

  Widget _buildFeatureTag(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        border: Border.all(color: AppTheme.divider.withValues(alpha: 0.5)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppTheme.terracotta),
          const SizedBox(width: 8),
          Text(
            label,
            style: GoogleFonts.jost(fontSize: 12, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }
}
