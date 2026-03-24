import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../app/routes.dart';
import '../../../core/providers/config_provider.dart';
import '../../../core/services/firestore_service.dart';
import '../../../models/product.dart';
import 'widgets/nav_bar.dart';
import 'widgets/hero_section.dart';
import 'widgets/exclusive_section.dart';
import 'widgets/exhibition_section.dart';
import 'widgets/all_product_section.dart';
import 'widgets/store_banner.dart';
import 'home_footer.dart';

/// CustomerHomeScreen — main screen for logged-in customers.
///
/// Widget tree:
/// Scaffold
/// ├── endDrawer → NavDrawer (mobile hamburger menu)
/// └── body → Stack
///     ├── CustomScrollView
///     │   ├── 72px spacer      (sits under the fixed nav bar)
///     │   ├── HeroSection
///     │   ├── ExclusiveSection
///     │   ├── ExhibitionSection
///     │   ├── AllProductsSection
///     │   ├── StoreBanner
///     │   └── HomeFooter
///     └── NavBar (fixed at top via Positioned)
///
/// Data flow:
/// - AppConfig already loaded by SplashScreen via ConfigProvider
/// - Products and exclusive products fetched here on initState
/// - Both fetches run in parallel via Future.wait
class CustomerHomeScreen extends StatefulWidget {
  const CustomerHomeScreen({super.key});

  @override
  State<CustomerHomeScreen> createState() => _CustomerHomeScreenState();
}

class _CustomerHomeScreenState extends State<CustomerHomeScreen> {

  // ─────────────────────────────────────────
  // STATE
  // ─────────────────────────────────────────

  final ScrollController _scrollController = ScrollController();

  List<Product>          _products          = [];
  List<ExclusiveProduct> _exclusiveProducts = [];

  bool _loadingProducts   = true;
  bool _loadingExclusive  = true;

  // ─────────────────────────────────────────
  // LIFECYCLE
  // ─────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    // Fetch both lists in parallel — faster than sequential
    Future.wait([
      _fetchProducts(),
      _fetchExclusive(),
    ]);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  // ─────────────────────────────────────────
  // DATA FETCHING
  // ─────────────────────────────────────────

  Future<void> _fetchProducts() async {
    try {
      final data = await FirestoreService.getAllProducts();
      if (mounted) {
        setState(() {
          _products        = data;
          _loadingProducts = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loadingProducts = false);
    }
  }

  Future<void> _fetchExclusive() async {
    try {
      final data = await FirestoreService.getExclusiveProducts();
      if (mounted) {
        setState(() {
          _exclusiveProducts = data;
          _loadingExclusive  = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loadingExclusive = false);
    }
  }

  // ─────────────────────────────────────────
  // NAVIGATION
  // ─────────────────────────────────────────

  void _goToCategories() {
    Navigator.pushNamed(context, Routes.categories);
  }

  void _goToExclusiveDetail(ExclusiveProduct product) {
    Navigator.pushNamed(
      context,
      Routes.exclusiveDetail,
      arguments: product,
    );
  }

  // ─────────────────────────────────────────
  // BUILD
  // ─────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    // If config somehow not loaded yet — trigger load
    final config = context.watch<ConfigProvider>();
    if (!config.isLoaded && !config.isLoading) {
      config.load();
    }

    return Scaffold(
      backgroundColor: AppTheme.background,

      // NavDrawer opens from the right on mobile
      // Triggered by hamburger icon in NavBar
      endDrawer: const NavDrawer(),

      body: Stack(
        children: [

          // ── Scrollable content ──
          CustomScrollView(
            controller: _scrollController,
            physics: const BouncingScrollPhysics(),
            slivers: [

              // Empty space so first section clears the fixed nav bar
              const SliverToBoxAdapter(
                child: SizedBox(height: 72),
              ),

              // Hero — full viewport height on desktop
              const SliverToBoxAdapter(
                child: HeroSection(),
              ),

              // Exclusive products — editorial staggered grid
              SliverToBoxAdapter(
                child: ExclusiveSection(
                  products:      _exclusiveProducts,
                  onProductTap:  _goToExclusiveDetail,
                  isLoading:     _loadingExclusive,
                ),
              ),

              // Exhibition — only renders if isActive: true in Firestore
              const SliverToBoxAdapter(
                child: ExhibitionSection(),
              ),

              // All products grid
              SliverToBoxAdapter(
                child: AllProductsSection(
                  products:            _products,
                  onBrowseCategoryTap: _goToCategories,
                  isLoading:           _loadingProducts,
                ),
              ),

              // Store banner — dark section with coming soon CTA
              const SliverToBoxAdapter(
                child: StoreBanner(),
              ),

              // Footer — links, copyright
              const SliverToBoxAdapter(
                child: HomeFooter(),
              ),

            ],
          ),

          // ── Fixed nav bar — always on top ──
          // Positioned so it floats above the scroll content
          const Positioned(
            top:   0,
            left:  0,
            right: 0,
            child: NavBar(),
          ),

        ],
      ),
    );
  }
}