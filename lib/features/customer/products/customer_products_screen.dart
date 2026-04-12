import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../core/providers/app_refresh_provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../features/admin/catalog/repositories/product_repository.dart';
import '../../../core/utils/storefront_filters.dart';
import '../../../models/product.dart';
import '../../../core/utils/responsive_utils.dart';
import '../home/home_footer.dart';
import '../widgets/product_card.dart';

/// CustomerProductsScreen — shows products filtered by category.
class CustomerProductsScreen extends StatefulWidget {
  final String categoryId;
  final String categoryName;

  const CustomerProductsScreen({
    super.key,
    required this.categoryId,
    required this.categoryName,
  });

  @override
  State<CustomerProductsScreen> createState() => _CustomerProductsScreenState();
}

class _CustomerProductsScreenState extends State<CustomerProductsScreen> {
  bool _isLoading = true;
  List<Product> _products = [];
  final TextEditingController _searchController = TextEditingController();
  int _refreshVersion = 0;
  String _searchQuery = '';
  String _sortBy = 'featured';

  List<Product> get _visibleProducts {
    final normalizedQuery = _searchQuery.trim().toLowerCase();
    final filtered = _products.where((product) {
      if (normalizedQuery.isEmpty) return true;
      return product.title.toLowerCase().contains(normalizedQuery) ||
          product.description.toLowerCase().contains(normalizedQuery) ||
          product.tags.any(
            (tag) => tag.toLowerCase().contains(normalizedQuery),
          );
    }).toList();

    switch (_sortBy) {
      case 'price_low_high':
        filtered.sort((a, b) => a.sellingPrice.compareTo(b.sellingPrice));
        break;
      case 'price_high_low':
        filtered.sort((a, b) => b.sellingPrice.compareTo(a.sellingPrice));
        break;
      case 'popular':
        filtered.sort((a, b) => b.soldCount.compareTo(a.soldCount));
        break;
      default:
        break;
    }

    return filtered;
  }

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final version = context.watch<AppRefreshProvider>().dataVersion;
    if (_refreshVersion == 0) {
      _refreshVersion = version;
      return;
    }
    if (version != _refreshVersion) {
      _refreshVersion = version;
      _loadProducts(forceRefresh: true);
    }
  }

  Future<void> _loadProducts({bool forceRefresh = false}) async {
    try {
      if (forceRefresh && mounted) {
        setState(() => _isLoading = true);
      }

      final prods = await ProductRepository.getProductsByCategory(
        widget.categoryId,
        forceRefresh: forceRefresh,
      );
      if (mounted) {
        setState(() {
          final activeProds = prods
              .where(StorefrontFilters.showProduct)
              .toList();
          activeProds.shuffle(); // Randomize for customer
          _products = activeProds;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error loading products: $e')));
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = ResponsiveBreakpoints.isMobile(context);
    final isTablet = ResponsiveBreakpoints.isTablet(context);

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.white,
        elevation: 1,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppTheme.textDark),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          widget.categoryName,
          style: GoogleFonts.playfairDisplay(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: AppTheme.textDark,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppTheme.primaryBrown),
            )
          : _products.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.inbox_outlined, size: 64, color: AppTheme.divider),
                  const SizedBox(height: 16),
                  Text(
                    'No products in this collection',
                    style: AppTheme.bodyMedium,
                  ),
                ],
              ),
            )
          : SingleChildScrollView(
              padding: EdgeInsets.symmetric(
                horizontal: isMobile ? 20 : 60,
                vertical: isMobile ? 32 : 48,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _searchController,
                          onChanged: (value) {
                            setState(() => _searchQuery = value);
                          },
                          decoration: AppTheme.inputDecoration(
                            label: 'Search within this collection',
                            hint: 'Search by title or tag',
                          ).copyWith(prefixIcon: const Icon(Icons.search)),
                        ),
                      ),
                      const SizedBox(width: 16),
                      SizedBox(
                        width: isMobile ? 150 : 220,
                        child: DropdownButtonFormField<String>(
                          initialValue: _sortBy,
                          decoration: AppTheme.inputDecoration(label: 'Sort'),
                          items: const [
                            DropdownMenuItem(
                              value: 'featured',
                              child: Text('Featured'),
                            ),
                            DropdownMenuItem(
                              value: 'popular',
                              child: Text('Popular'),
                            ),
                            DropdownMenuItem(
                              value: 'price_low_high',
                              child: Text('Price: Low to High'),
                            ),
                            DropdownMenuItem(
                              value: 'price_high_low',
                              child: Text('Price: High to Low'),
                            ),
                          ],
                          onChanged: (value) {
                            if (value != null) setState(() => _sortBy = value);
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Text(
                    '${_visibleProducts.length} Products',
                    style: GoogleFonts.jost(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: AppTheme.textLight,
                      letterSpacing: 2,
                    ),
                  ),
                  const SizedBox(height: 24),
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: isMobile ? 2 : (isTablet ? 3 : 4),
                      crossAxisSpacing: isMobile ? 14 : 24,
                      mainAxisSpacing: isMobile ? 28 : 40,
                      childAspectRatio: 0.72,
                    ),
                    itemCount: _visibleProducts.length,
                    itemBuilder: (context, index) {
                      final product = _visibleProducts[index];
                      return ProductCard(product: product);
                    },
                  ),
                  const SizedBox(height: 64),
                  const HomeFooter(),
                ],
              ),
            ),
    );
  }
}
