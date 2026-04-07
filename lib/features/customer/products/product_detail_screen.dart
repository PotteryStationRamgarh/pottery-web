import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../app/routes.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/providers/cart_provider.dart';
import '../../../models/product.dart';
import '../../admin/catalog/repositories/product_repository.dart';
import '../home/widgets/nav_bar.dart';

class ProductDetailScreen extends StatefulWidget {
  final Product? product;
  final String? productId;

  const ProductDetailScreen({
    super.key,
    this.product,
    this.productId,
  });

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  int _currentImageIndex = 0;
  Product? _product;
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
      final p = await ProductRepository.getProduct(widget.productId!);
      setState(() => _product = p);
    } catch (e) {
      debugPrint('Error loading product: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  String _formatDimensions(Map<String, dynamic> dims) {
    if (dims.isEmpty) return "";
    final parts = <String>[];
    if (dims.containsKey('length')) parts.add("L: ${dims['length']}");
    if (dims.containsKey('width')) parts.add("W: ${dims['width']}");
    if (dims.containsKey('height')) parts.add("H: ${dims['height']}");
    if (dims.containsKey('diameter')) parts.add("D: ${dims['diameter']}");
    return parts.join(' • ');
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
        body: Center(child: Text("Product not found")),
      );
    }

    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth > 900;

    return Scaffold(
      backgroundColor: AppTheme.background,
      endDrawer: const NavDrawer(),
      body: Stack(
        children: [
          SingleChildScrollView(
            child: Column(
              children: [
                const SizedBox(height: 72), // Height of NavBar
                if (isDesktop)
                  _buildDesktopLayout()
                else
                  _buildMobileLayout(),
                _buildProcessSection(),
                if (_product!.careInstructions.isNotEmpty) _buildCareInstructions(),
                const SizedBox(height: 80),
              ],
            ),
          ),
          const Positioned(top: 0, left: 0, right: 0, child: NavBar()),
        ],
      ),
    );
  }

  Widget _buildMobileLayout() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildImageGallery(),
        _buildProductInfo(),
      ],
    );
  }

  Widget _buildDesktopLayout() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 48),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(flex: 3, child: _buildImageGallery()),
          const SizedBox(width: 48),
          Expanded(flex: 2, child: _buildProductInfo()),
        ],
      ),
    );
  }

  Widget _buildImageGallery() {
    final images = _product!.imageUrls;
    if (images.isEmpty) {
      return Container(
        height: 500,
        width: double.infinity,
        color: Colors.grey[200],
        child: const Icon(Icons.image_not_supported, size: 50, color: Colors.grey),
      );
    }

    return Column(
      children: [
        Container(
          height: 500,
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.grey.withOpacity(0.1),
          ),
          child: PageView.builder(
            onPageChanged: (index) => setState(() => _currentImageIndex = index),
            itemCount: images.length,
            itemBuilder: (context, index) {
              return Image.network(
                images[index],
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) =>
                    const Center(child: Icon(Icons.image, size: 50, color: Colors.grey)),
              );
            },
          ),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(
            images.length,
            (index) => Container(
              width: 6,
              height: 6,
              margin: const EdgeInsets.symmetric(horizontal: 4),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _currentImageIndex == index
                    ? AppTheme.terracotta
                    : AppTheme.divider,
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: images.asMap().entries.map((entry) {
                return GestureDetector(
                  onTap: () => setState(() => _currentImageIndex = entry.key),
                  child: Container(
                    width: 60,
                    height: 60,
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: _currentImageIndex == entry.key
                            ? AppTheme.terracotta
                            : Colors.transparent,
                        width: 2,
                      ),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(2),
                      child: Image.network(images[entry.key], fit: BoxFit.cover),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildProductInfo() {
    final hasDiscount = _product!.mrp > _product!.sellingPrice;
    final isSoldOut = _product!.stockCount <= 0;

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_product!.tags.isNotEmpty)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppTheme.divider.withOpacity(0.3),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                _product!.tags.join(' • ').toUpperCase(),
                style: GoogleFonts.jost(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 2,
                  color: AppTheme.textLight,
                ),
              ),
            ),
          const SizedBox(height: 16),
          Text(
            _product!.title,
            style: AppTheme.serifHeadingLarge,
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Text(
                "₹${_product!.sellingPrice.toInt()}",
                style: GoogleFonts.jost(
                  fontSize: 24,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.terracotta,
                ),
              ),
              if (hasDiscount) ...[
                const SizedBox(width: 12),
                Text(
                  "₹${_product!.mrp.toInt()}",
                  style: GoogleFonts.jost(
                    fontSize: 16,
                    color: AppTheme.textLight,
                    decoration: TextDecoration.lineThrough,
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 4),
          Text(
            "+ Delivery charges",
            style: GoogleFonts.jost(
              fontSize: 12,
              color: AppTheme.textLight,
              fontStyle: FontStyle.italic,
            ),
          ),
          const SizedBox(height: 16),
          _buildStockIndicator(),
          const SizedBox(height: 24),
          Text(
            _product!.description,
            style: AppTheme.bodyLarge.copyWith(height: 1.6),
          ),
          const SizedBox(height: 32),
          _buildSpecsRow(),
          const SizedBox(height: 40),
          Row(
            children: [
              Expanded(
                child: _buildButton(
                  "ADD TO CART",
                  isFilled: true,
                  onPressed: isSoldOut
                      ? null
                      : () {
                          context.read<CartProvider>().addItem(_product!);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: const Text("Added to cart"),
                              action: SnackBarAction(
                                label: "VIEW CART",
                                onPressed: () => Navigator.pushNamed(context, Routes.cart),
                                textColor: Colors.white,
                              ),
                              backgroundColor: AppTheme.terracotta,
                            ),
                          );
                        },
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildButton(
                  "BUY NOW",
                  isFilled: false,
                  onPressed: isSoldOut
                      ? null
                      : () {
                          context.read<CartProvider>().addItem(_product!);
                          Navigator.pushNamed(context, Routes.cart);
                        },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStockIndicator() {
    final stockCount = _product!.stockCount;
    if (stockCount <= 0) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.grey[200],
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(
          "SOLD OUT",
          style: GoogleFonts.jost(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Colors.grey[600],
          ),
        ),
      );
    }
    if (stockCount <= 5) {
      return Text(
        "Only $stockCount left in stock",
        style: GoogleFonts.jost(
          fontSize: 13,
          fontWeight: FontWeight.w500,
          color: Colors.orange[800],
        ),
      );
    }
    return const SizedBox.shrink();
  }

  Widget _buildSpecsRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _buildSpecItem(Icons.waves, "Material", _product!.material),
        _buildSpecItem(Icons.square_foot, "Dimensions", _formatDimensions(_product!.dimensions)),
        _buildSpecItem(Icons.line_weight, "Weight", "${_product!.weight}g"),
      ],
    );
  }

  Widget _buildSpecItem(IconData icon, String label, String value) {
    if (value.isEmpty || value == "0g" || value == "0") return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: AppTheme.textLight),
        const SizedBox(height: 8),
        Text(
          label,
          style: GoogleFonts.jost(
            fontSize: 11,
            color: AppTheme.textLight,
            fontWeight: FontWeight.w500,
          ),
        ),
        Text(
          value,
          style: GoogleFonts.jost(
            fontSize: 13,
            color: AppTheme.textDark,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildButton(String text, {required bool isFilled, VoidCallback? onPressed}) {
    final bool isDisabled = onPressed == null;
    return InkWell(
      onTap: onPressed,
      child: Container(
        height: 54,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isDisabled
              ? Colors.grey[300]
              : (isFilled ? AppTheme.terracotta : Colors.transparent),
          border: Border.all(
            color: isDisabled ? Colors.transparent : AppTheme.terracotta,
            width: 1.5,
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          isDisabled ? "SOLD OUT" : text,
          style: GoogleFonts.jost(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            letterSpacing: 1.5,
            color: isDisabled
                ? Colors.grey[600]
                : (isFilled ? Colors.white : AppTheme.terracotta),
          ),
        ),
      ),
    );
  }

  Widget _buildProcessSection() {
    return Container(
      width: double.infinity,
      color: AppTheme.exhibitionBackground,
      padding: const EdgeInsets.symmetric(vertical: 80, horizontal: 24),
      child: Column(
        children: [
          Text("The Artist's Process", style: AppTheme.serifHeadingMedium),
          const SizedBox(height: 48),
          LayoutBuilder(builder: (context, constraints) {
            return Wrap(
              spacing: 48,
              runSpacing: 40,
              alignment: WrapAlignment.center,
              children: [
                _buildProcessCard("Sourcing", "Selecting the finest local clay from the Ramgarh riverbeds.", Icons.landscape),
                _buildProcessCard("Wheel", "Slowly throwing and shaping on a manual kick-wheel.", Icons.change_circle_outlined),
                _buildProcessCard("Cure", "Sun-dried for days before double-firing in a traditional kiln.", Icons.wb_sunny_outlined),
              ],
            );
          }),
        ],
      ),
    );
  }

  Widget _buildProcessCard(String title, String desc, IconData icon) {
    return SizedBox(
      width: 280,
      child: Column(
        children: [
          Icon(icon, size: 40, color: AppTheme.terracotta),
          const SizedBox(height: 20),
          Text(title, style: AppTheme.headingMedium),
          const SizedBox(height: 12),
          Text(
            desc,
            textAlign: TextAlign.center,
            style: AppTheme.bodyMedium.copyWith(height: 1.6),
          ),
        ],
      ),
    );
  }

  Widget _buildCareInstructions() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 80, horizontal: 24),
      child: Column(
        children: [
          Text("Care Instructions", style: AppTheme.serifHeadingMedium),
          const SizedBox(height: 40),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: Column(
              children: _product!.careInstructions.map((text) {
                return _buildCareItem(Icons.info_outline, text);
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCareItem(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Icon(icon, size: 20, color: AppTheme.textLight),
          const SizedBox(width: 16),
          Expanded(
            child: Text(text, style: AppTheme.bodyMedium),
          ),
        ],
      ),
    );
  }
}
