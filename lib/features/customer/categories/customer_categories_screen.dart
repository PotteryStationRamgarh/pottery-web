import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../core/providers/app_refresh_provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../features/admin/catalog/repositories/category_repository.dart';
import '../../../models/product_category.dart';
import '../../../app/routes.dart';
import '../../../core/utils/responsive_utils.dart';

/// CustomerCategoriesScreen — browse products by category.
/// Shows grid of category cards with images.
class CustomerCategoriesScreen extends StatefulWidget {
  const CustomerCategoriesScreen({super.key});

  @override
  State<CustomerCategoriesScreen> createState() =>
      _CustomerCategoriesScreenState();
}

class _CustomerCategoriesScreenState extends State<CustomerCategoriesScreen> {
  bool _isLoading = true;
  List<ProductCategory> _categories = [];
  int _refreshVersion = 0;

  @override
  void initState() {
    super.initState();
    _loadCategories();
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
      _loadCategories(forceRefresh: true);
    }
  }

  Future<void> _loadCategories({bool forceRefresh = false}) async {
    try {
      if (forceRefresh && mounted) {
        setState(() => _isLoading = true);
      }
      final cats = await CategoryRepository.getCategories(
        forceRefresh: forceRefresh,
      );
      if (mounted) {
        setState(() {
          final activeCats = cats.where((c) => c.isActive).toList();
          activeCats.shuffle(); // Randomize for customer
          _categories = activeCats;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error loading categories: $e')));
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
          'Browse Collections',
          style: GoogleFonts.playfairDisplay(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: AppTheme.textDark,
          ),
        ),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppTheme.primaryBrown),
            )
          : _categories.isEmpty
          ? Center(
              child: Text(
                'No categories available',
                style: AppTheme.bodyMedium,
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
                  Text(
                    'Select a Collection',
                    style: GoogleFonts.playfairDisplay(
                      fontSize: isMobile ? 28 : 40,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textDark,
                    ),
                  ),
                  const SizedBox(height: 40),
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: isMobile ? 2 : (isTablet ? 3 : 4),
                      crossAxisSpacing: isMobile ? 16 : 32,
                      mainAxisSpacing: isMobile ? 16 : 32,
                    ),
                    itemCount: _categories.length,
                    itemBuilder: (context, index) {
                      final category = _categories[index];
                      return _buildCategoryCard(context, category);
                    },
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildCategoryCard(BuildContext context, ProductCategory category) {
    return GestureDetector(
      onTap: () {
        Navigator.pushNamed(
          context,
          Routes.products,
          arguments: {'categoryId': category.id, 'categoryName': category.name},
        );
      },
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.divider),
          color: AppTheme.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(16),
                  ),
                  color: AppTheme.background,
                  image: category.imageUrl.isNotEmpty
                      ? DecorationImage(
                          image: NetworkImage(category.imageUrl),
                          fit: BoxFit.cover,
                        )
                      : null,
                ),
                child: category.imageUrl.isEmpty
                    ? const Center(
                        child: Icon(
                          Icons.category_outlined,
                          size: 48,
                          color: AppTheme.greyPlaceholder,
                        ),
                      )
                    : null,
              ),
            ),
            // Title
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    category.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.jost(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textDark,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Tap to explore',
                    style: GoogleFonts.jost(
                      fontSize: 12,
                      color: AppTheme.textLight,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
