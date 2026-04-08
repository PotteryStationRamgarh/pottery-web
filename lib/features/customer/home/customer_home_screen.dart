import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/providers/app_refresh_provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../app/routes.dart';
import '../../../core/providers/config_provider.dart';
import '../../../core/providers/exhibition_provider.dart';
import '../../../core/repositories/home_repository.dart';
import '../../../models/product.dart';
import 'widgets/nav_bar.dart';
import 'widgets/hero_section.dart';
import 'widgets/exclusive_section.dart';
import 'widgets/exhibition_section.dart';
import 'widgets/all_product_section.dart';
import 'widgets/categories_section.dart';
import 'home_footer.dart';

/// CustomerHomeScreen — main screen for logged-in customers.
/// All data (products, exclusives, exhibition) is fetched via HomeRepository
/// in a single parallel call. No widget fetches Firestore independently.
class CustomerHomeScreen extends StatefulWidget {
  const CustomerHomeScreen({super.key});

  @override
  State<CustomerHomeScreen> createState() => _CustomerHomeScreenState();
}

class _CustomerHomeScreenState extends State<CustomerHomeScreen> {
  final ScrollController _scrollController = ScrollController();
  final GlobalKey _exclusiveSectionKey = GlobalKey();

  List<Product> _products = [];
  List<ExclusiveProduct> _exclusiveProducts = [];

  bool _isLoading = true;
  int _refreshVersion = 0;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _scrollController.dispose();
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
      _loadData(forceRefresh: true);
    }
  }

  Future<void> _loadData({bool forceRefresh = false}) async {
    try {
      if (forceRefresh && mounted) {
        setState(() => _isLoading = true);
      }

      final data = await HomeRepository.fetchAll(forceRefresh: forceRefresh);
      if (!mounted) return;

      // If exhibition wasn't pre-loaded by CustomerLoadingScreen, update provider now.
      final exhibitionProvider = context.read<ExhibitionProvider>();
      if (forceRefresh || !exhibitionProvider.isLoaded) {
        // HomeRepository already fetched it — push it into the provider indirectly
        // by triggering a load (will skip if already loaded by loading screen).
        await exhibitionProvider.load(forceRefresh: forceRefresh);
      }

      setState(() {
        _products = data.products;
        _exclusiveProducts = data.exclusiveProducts;
        _isLoading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _goToCategories() => Navigator.pushNamed(context, Routes.categories);

  void _goToExclusiveDetail(ExclusiveProduct product) =>
      Navigator.pushNamed(context, Routes.exclusiveDetail, arguments: product);

  @override
  Widget build(BuildContext context) {
    final config = context.watch<ConfigProvider>();
    if (!config.isLoaded && !config.isLoading) config.load();

    return Scaffold(
      backgroundColor: AppTheme.background,
      endDrawer: const NavDrawer(),
      body: Stack(
        children: [
          CustomScrollView(
            controller: _scrollController,
            physics: const BouncingScrollPhysics(),
            slivers: [
              const SliverToBoxAdapter(child: SizedBox(height: 72)),
              SliverToBoxAdapter(
                child: HeroSection(
                  onExploreTap: () {
                    final context = _exclusiveSectionKey.currentContext;
                    if (context != null) {
                      Scrollable.ensureVisible(
                        context,
                        duration: const Duration(milliseconds: 800),
                        curve: Curves.easeInOutQuart,
                      );
                    }
                  },
                ),
              ),
              SliverToBoxAdapter(
                child: KeyedSubtree(
                  key: _exclusiveSectionKey,
                  child: ExclusiveSection(
                    products: _exclusiveProducts,
                    onProductTap: _goToExclusiveDetail,
                    isLoading: _isLoading,
                  ),
                ),
              ),
              const SliverToBoxAdapter(child: ExhibitionSection()),
              SliverToBoxAdapter(
                child: AllProductsSection(
                  products: _products,
                  onBrowseCategoryTap: _goToCategories,
                  isLoading: _isLoading,
                ),
              ),
              const SliverToBoxAdapter(child: CategoriesSection()),
              const SliverToBoxAdapter(child: HomeFooter()),
            ],
          ),
          const Positioned(top: 0, left: 0, right: 0, child: NavBar()),
        ],
      ),
    );
  }
}
