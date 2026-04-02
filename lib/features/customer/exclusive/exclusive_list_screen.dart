import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../app/routes.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/repositories/home_repository.dart';
import '../../../models/product.dart';
import '../widgets/exclusive_card.dart';
import '../home/widgets/nav_bar.dart';
import '../home/home_footer.dart';

class ExclusiveListScreen extends StatefulWidget {
  const ExclusiveListScreen({super.key});

  @override
  State<ExclusiveListScreen> createState() => _ExclusiveListScreenState();
}

class _ExclusiveListScreenState extends State<ExclusiveListScreen> {
  List<ExclusiveProduct> _products = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final products = await HomeRepository.getExclusiveProducts();
    if (mounted) {
      setState(() {
        _products = products;
        _isLoading = false;
      });
    }
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
              // Top spacing for NavBar
              const SliverToBoxAdapter(child: SizedBox(height: 100)),

              // Header with back button
              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: isMobile ? 24 : 80),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Back button
                      TextButton.icon(
                        onPressed: () {
                          if (Navigator.canPop(context)) {
                            Navigator.pop(context);
                          } else {
                            Navigator.pushReplacementNamed(context, Routes.customerHome);
                          }
                        },
                        icon: const Icon(Icons.arrow_back, size: 16),
                        label: Text('Back', style: GoogleFonts.jost(fontWeight: FontWeight.w500)),
                        style: TextButton.styleFrom(
                          foregroundColor: AppTheme.textDark,
                          padding: EdgeInsets.zero,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Exclusive Collection',
                        style: GoogleFonts.playfairDisplay(
                          fontSize: isMobile ? 32 : 48,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.textDark,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Discover our limited edition masterpieces, handcrafted with precision and passion.',
                        style: GoogleFonts.jost(fontSize: 15, color: AppTheme.textLight),
                      ),
                      const SizedBox(height: 48),
                    ],
                  ),
                ),
              ),

              // Content
              if (_isLoading)
                const SliverFillRemaining(
                  child: Center(child: CircularProgressIndicator(color: AppTheme.primaryBrown)),
                )
              else if (_products.isEmpty)
                SliverFillRemaining(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.star_outline, size: 64, color: AppTheme.divider),
                        const SizedBox(height: 16),
                        Text('No exclusive pieces found.', style: AppTheme.bodyLarge),
                      ],
                    ),
                  ),
                )
              else
                SliverPadding(
                  padding: EdgeInsets.symmetric(horizontal: isMobile ? 24 : 80),
                  sliver: SliverGrid(
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: isMobile ? 1 : 3,
                      // 1.0 width : ~1.75 height — enough for portrait image + text below
                      childAspectRatio: isMobile ? 0.75 : 0.58,
                      crossAxisSpacing: 32,
                      mainAxisSpacing: 48,
                    ),
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        return ExclusiveCard(
                          product: _products[index],
                          onTap: () => Navigator.pushNamed(
                            context,
                            Routes.exclusiveDetail,
                            arguments: _products[index],
                          ),
                        );
                      },
                      childCount: _products.length,
                    ),
                  ),
                ),

              const SliverToBoxAdapter(child: SizedBox(height: 80)),
              const SliverToBoxAdapter(child: HomeFooter()),
            ],
          ),
          const Positioned(top: 0, left: 0, right: 0, child: NavBar()),
        ],
      ),
    );
  }
}
