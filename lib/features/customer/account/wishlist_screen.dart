import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/providers/wishlist_provider.dart';
import '../../../core/repositories/home_repository.dart';
import '../../../core/theme/app_theme.dart';
import '../../../models/product.dart';
import '../home/home_footer.dart';
import '../home/widgets/nav_bar.dart';
import '../widgets/exclusive_card.dart';
import '../widgets/product_card.dart';
import '../exclusive/exclusive_detail_screen.dart';

class WishlistScreen extends StatelessWidget {
  const WishlistScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth > 900;

    return Scaffold(
      backgroundColor: AppTheme.background,
      endDrawer: const NavDrawer(),
      body: Stack(
        children: [
          FutureBuilder<HomeData>(
            future: HomeRepository.fetchAll(forceRefresh: true),
            builder: (context, snapshot) {
              final ids = context.watch<WishlistProvider>().items;
              final data = snapshot.data;
              final products =
                  data?.products
                      .where((p) => ids.contains('product:${p.id}'))
                      .toList() ??
                  const <Product>[];
              final exclusives =
                  data?.exclusiveProducts
                      .where((p) => ids.contains('exclusive:${p.id}'))
                      .toList() ??
                  const <ExclusiveProduct>[];

              return SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 100),
                    Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: isDesktop ? 80 : 24,
                        vertical: 48,
                      ),
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 1280),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Wishlist', style: AppTheme.serifHeadingLarge),
                            const SizedBox(height: 12),
                            Text(
                              'Keep track of the pieces you want to return to.',
                              style: AppTheme.bodyMedium.copyWith(
                                color: AppTheme.textLight,
                              ),
                            ),
                            const SizedBox(height: 40),
                            if (!snapshot.hasData &&
                                snapshot.connectionState !=
                                    ConnectionState.done)
                              const Center(child: CircularProgressIndicator())
                            else if (products.isEmpty && exclusives.isEmpty)
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 80,
                                ),
                                child: Center(
                                  child: Text(
                                    'No products saved to wishlist yet.',
                                    style: AppTheme.bodyLarge,
                                  ),
                                ),
                              )
                            else ...[
                              if (products.isNotEmpty) ...[
                                Text(
                                  'Products',
                                  style: AppTheme.serifHeadingMedium,
                                ),
                                const SizedBox(height: 24),
                                GridView.builder(
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  gridDelegate:
                                      SliverGridDelegateWithFixedCrossAxisCount(
                                        crossAxisCount: isDesktop ? 4 : 2,
                                        crossAxisSpacing: 24,
                                        mainAxisSpacing: 32,
                                        childAspectRatio: 0.72,
                                      ),
                                  itemCount: products.length,
                                  itemBuilder: (context, index) =>
                                      ProductCard(product: products[index]),
                                ),
                                const SizedBox(height: 48),
                              ],
                              if (exclusives.isNotEmpty) ...[
                                Text(
                                  'Exclusive Pieces',
                                  style: AppTheme.serifHeadingMedium,
                                ),
                                const SizedBox(height: 24),
                                GridView.builder(
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  gridDelegate:
                                      SliverGridDelegateWithFixedCrossAxisCount(
                                        crossAxisCount: isDesktop ? 3 : 1,
                                        crossAxisSpacing: 24,
                                        mainAxisSpacing: 32,
                                        childAspectRatio: isDesktop
                                            ? 0.58
                                            : 0.8,
                                      ),
                                  itemCount: exclusives.length,
                                  itemBuilder: (context, index) =>
                                      ExclusiveCard(
                                        product: exclusives[index],
                                        onTap: () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (_) =>
                                                  ExclusiveDetailScreen(
                                                    product: exclusives[index],
                                                  ),
                                            ),
                                          );
                                        },
                                      ),
                                ),
                              ],
                            ],
                          ],
                        ),
                      ),
                    ),
                    const HomeFooter(),
                  ],
                ),
              );
            },
          ),
          const Positioned(top: 0, left: 0, right: 0, child: NavBar()),
        ],
      ),
    );
  }
}
