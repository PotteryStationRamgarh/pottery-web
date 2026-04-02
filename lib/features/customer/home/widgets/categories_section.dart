import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../app/routes.dart';
import '../../../../models/product_category.dart';
import '../../../../features/admin/catalog/repositories/category_repository.dart';

class CategoriesSection extends StatefulWidget {
  const CategoriesSection({super.key});

  @override
  State<CategoriesSection> createState() => _CategoriesSectionState();
}

class _CategoriesSectionState extends State<CategoriesSection> {
  bool _isLoading = true;
  List<ProductCategory> _categories = [];

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    try {
      final cats = await CategoryRepository.getCategories();
      if (mounted) {
        setState(() {
          _categories = cats.where((c) => c.isActive).take(4).toList();
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_isLoading && _categories.isEmpty) return const SizedBox.shrink();

    final isMobile = MediaQuery.of(context).size.width < 768;

    return Container(
      width: double.infinity,
      color: AppTheme.white,
      padding: EdgeInsets.symmetric(
        vertical: isMobile ? 48 : 80,
        horizontal: isMobile ? 20 : 60,
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                   Text(
                    'DISCOVER COLLECTIONS',
                    style: GoogleFonts.jost(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: AppTheme.textLight,
                      letterSpacing: 2,
                    ),
                  ),
                  const SizedBox(height: 12),
                    Text(
                      'Browse Categories',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.playfairDisplay(
                        fontSize: isMobile ? 28 : 40,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textDark,
                      ),
                    ),
                  ],
                ),
              ),
              TextButton(
                onPressed: () => Navigator.pushNamed(context, Routes.categories),
                child: Row(
                  children: [
                    Text(
                      'View All',
                      style: GoogleFonts.jost(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.primaryBrown,
                      ),
                    ),
                    const Icon(Icons.arrow_forward, size: 16),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 48),
          _isLoading
              ? const Center(child: CircularProgressIndicator(color: AppTheme.primaryBrown))
              : LayoutBuilder(
                  builder: (context, constraints) {
                    final cardWidth = (constraints.maxWidth - (isMobile ? 16 : 48)) / (isMobile ? 2 : 4);
                    return Wrap(
                      spacing: isMobile ? 16 : 16,
                      runSpacing: 16,
                      children: _categories.map((cat) => _buildCategoryCard(cat, cardWidth, isMobile)).toList(),
                    );
                  },
                ),
        ],
      ),
    );
  }

  Widget _buildCategoryCard(ProductCategory category, double width, bool isMobile) {
    return GestureDetector(
      onTap: () {
        Navigator.pushNamed(
          context,
          Routes.products,
          arguments: {'categoryId': category.id, 'categoryName': category.name},
        );
      },
      child: SizedBox(
        width: width,
        child: Column(
          children: [
            AspectRatio(
              aspectRatio: 1,
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(width / 2),
                  border: Border.all(color: AppTheme.divider),
                  image: category.imageUrl != null && category.imageUrl!.isNotEmpty
                      ? DecorationImage(
                          image: NetworkImage(category.imageUrl!),
                          fit: BoxFit.cover,
                        )
                      : null,
                ),
                child: category.imageUrl == null || category.imageUrl!.isEmpty
                    ? const Icon(Icons.category_outlined, color: AppTheme.greyPlaceholder, size: 32)
                    : null,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              category.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.jost(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppTheme.textDark,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
