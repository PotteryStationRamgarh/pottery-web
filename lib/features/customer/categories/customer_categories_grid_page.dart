import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/services/firestore_service.dart';
import '../../../models/product.dart';
import '../home/widgets/nav_bar.dart';
import '../../../app/routes.dart';

class CustomerCategoriesGridPage extends StatefulWidget {
  const CustomerCategoriesGridPage({super.key});

  @override
  State<CustomerCategoriesGridPage> createState() => _CustomerCategoriesGridPageState();
}

class _CustomerCategoriesGridPageState extends State<CustomerCategoriesGridPage> {
  final TextEditingController _searchCtrl = TextEditingController();
  List<ProductCategory> _allCategories = [];
  List<ProductCategory> _filteredCategories = [];
  bool _isLoading = true;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    try {
      final categories = await FirestoreService.getCategories();
      // Shuffle categories randomly per user request
      categories.shuffle();
      setState(() {
        _allCategories = categories;
        _filteredCategories = categories;
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _filterCategories(String query) {
    setState(() {
      _searchQuery = query;
      _filteredCategories = _allCategories
          .where((c) => c.name.toLowerCase().contains(query.toLowerCase()))
          .toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 768;

    return Scaffold(
      backgroundColor: AppTheme.background,
      endDrawer: const NavDrawer(),
      body: Stack(
        children: [
          CustomScrollView(
            slivers: [
              const SliverToBoxAdapter(child: SizedBox(height: 120)),
              
              // Header & Search
              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: isMobile ? 24 : 80),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Back button — only shown when there is history to go back to
                      if (Navigator.canPop(context))
                        TextButton.icon(
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(Icons.arrow_back, size: 16),
                          label: Text('Back', style: GoogleFonts.jost(fontWeight: FontWeight.w500)),
                          style: TextButton.styleFrom(
                            foregroundColor: AppTheme.textDark,
                            padding: EdgeInsets.zero,
                          ),
                        ),
                      if (Navigator.canPop(context)) const SizedBox(height: 12),
                      Text(
                        'Browse Categories',
                        style: GoogleFonts.playfairDisplay(
                          fontSize: isMobile ? 32 : 48,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textDark,
                        ),
                      ),
                      const SizedBox(height: 32),
                      TextField(
                        controller: _searchCtrl,
                        onChanged: _filterCategories,
                        decoration: AppTheme.inputDecoration(
                          label: 'Search categories',
                          hint: 'Search by name...',
                        ).copyWith(
                          prefixIcon: const Icon(Icons.search, color: AppTheme.textLight),
                        ),
                      ),
                      const SizedBox(height: 48),
                    ],
                  ),
                ),
              ),

              // Categories Grid
              if (_isLoading)
                const SliverFillRemaining(
                  child: Center(child: CircularProgressIndicator(color: AppTheme.primaryBrown)),
                )
              else if (_filteredCategories.isEmpty)
                SliverFillRemaining(
                  child: Center(
                    child: Text(
                      'No categories found matching "$_searchQuery"',
                      style: AppTheme.bodyLarge,
                    ),
                  ),
                )
              else
                SliverPadding(
                  padding: EdgeInsets.symmetric(horizontal: isMobile ? 24 : 80),
                  sliver: SliverGrid(
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: isMobile ? 2 : 4,
                      crossAxisSpacing: 24,
                      mainAxisSpacing: 24,
                      childAspectRatio: 0.85,
                    ),
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final category = _filteredCategories[index];
                        return _CategoryGridCard(category: category);
                      },
                      childCount: _filteredCategories.length,
                    ),
                  ),
                ),
              
              const SliverToBoxAdapter(child: SizedBox(height: 100)),
            ],
          ),
          const Positioned(top: 0, left: 0, right: 0, child: NavBar()),
        ],
      ),
    );
  }
}

class _CategoryGridCard extends StatelessWidget {
  final ProductCategory category;
  const _CategoryGridCard({required this.category});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.pushNamed(
          context,
          Routes.products,
          arguments: {'categoryId': category.id, 'categoryName': category.name},
        );
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                image: DecorationImage(
                  image: NetworkImage(category.imageUrl),
                  fit: BoxFit.cover,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            category.name.toUpperCase(),
            style: GoogleFonts.jost(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              letterSpacing: 1.5,
              color: AppTheme.textDark,
            ),
          ),
        ],
      ),
    );
  }
}
