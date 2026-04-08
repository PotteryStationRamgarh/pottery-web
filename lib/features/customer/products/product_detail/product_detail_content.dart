import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../models/product.dart';
import '../../home/home_footer.dart';
import '../../home/widgets/nav_bar.dart';
import 'product_detail_models.dart';
import 'product_detail_sections.dart';

class ProductDetailContent extends StatelessWidget {
  final ProductDetailData data;
  final ProductCategory? category;
  final int selectedImageIndex;
  final int quantity;
  final ValueChanged<int> onImageSelected;
  final VoidCallback onDecreaseQuantity;
  final VoidCallback onIncreaseQuantity;
  final VoidCallback onAddToCart;
  final VoidCallback onBuyNow;

  const ProductDetailContent({
    super.key,
    required this.data,
    required this.category,
    required this.selectedImageIndex,
    required this.quantity,
    required this.onImageSelected,
    required this.onDecreaseQuantity,
    required this.onIncreaseQuantity,
    required this.onAddToCart,
    required this.onBuyNow,
  });

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width >= 960;

    return Scaffold(
      backgroundColor: AppTheme.background,
      endDrawer: const NavDrawer(),
      body: Stack(
        children: [
          SingleChildScrollView(
            child: Column(
              children: [
                const SizedBox(height: 72),
                Padding(
                  padding: EdgeInsets.fromLTRB(
                    isDesktop ? 40 : 18,
                    isDesktop ? 40 : 24,
                    isDesktop ? 40 : 18,
                    isDesktop ? 56 : 40,
                  ),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 1220),
                      child: isDesktop
                          ? Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  flex: 11,
                                  child: ProductGallerySection(
                                    images: data.images,
                                    selectedImageIndex: selectedImageIndex,
                                    onImageSelected: onImageSelected,
                                  ),
                                ),
                                const SizedBox(width: 48),
                                Expanded(
                                  flex: 9,
                                  child: ProductInfoSection(
                                    data: data,
                                    category: category,
                                    quantity: quantity,
                                    onDecreaseQuantity: onDecreaseQuantity,
                                    onIncreaseQuantity: onIncreaseQuantity,
                                    onAddToCart: onAddToCart,
                                    onBuyNow: onBuyNow,
                                  ),
                                ),
                              ],
                            )
                          : Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                ProductGallerySection(
                                  images: data.images,
                                  selectedImageIndex: selectedImageIndex,
                                  onImageSelected: onImageSelected,
                                ),
                                const SizedBox(height: 24),
                                ProductInfoSection(
                                  data: data,
                                  category: category,
                                  quantity: quantity,
                                  onDecreaseQuantity: onDecreaseQuantity,
                                  onIncreaseQuantity: onIncreaseQuantity,
                                  onAddToCart: onAddToCart,
                                  onBuyNow: onBuyNow,
                                ),
                              ],
                            ),
                    ),
                  ),
                ),
                CraftSection(material: data.material),
                DescriptionSection(data: data, category: category),
                if (data.lifestyleImages.isNotEmpty)
                  InPlaceSection(
                    images: data.lifestyleImages,
                    category: category,
                    productId: data.id,
                  ),
                if (data.hasSpecs) SpecsSection(data: data),
                if (data.reviews.isNotEmpty)
                  ReviewsSection(reviews: data.reviews),
                const HomeFooter(),
              ],
            ),
          ),
          const Positioned(top: 0, left: 0, right: 0, child: NavBar()),
        ],
      ),
    );
  }
}

class ProductDetailLoadingView extends StatelessWidget {
  const ProductDetailLoadingView({super.key});

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width >= 960;

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: Stack(
        children: [
          SingleChildScrollView(
            child: Column(
              children: [
                const SizedBox(height: 72),
                Padding(
                  padding: EdgeInsets.all(isDesktop ? 40 : 18),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 1220),
                      child: isDesktop
                          ? const Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(flex: 11, child: GallerySkeleton()),
                                SizedBox(width: 48),
                                Expanded(flex: 9, child: ProductInfoSkeleton()),
                              ],
                            )
                          : const Column(
                              children: [
                                GallerySkeleton(),
                                SizedBox(height: 24),
                                ProductInfoSkeleton(),
                              ],
                            ),
                    ),
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 18, vertical: 20),
                  child: SkeletonBlock(height: 180, radius: 24),
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 18, vertical: 20),
                  child: SkeletonBlock(height: 240, radius: 24),
                ),
              ],
            ),
          ),
          const Positioned(top: 0, left: 0, right: 0, child: NavBar()),
        ],
      ),
    );
  }
}

class ProductDetailErrorView extends StatelessWidget {
  final String productId;

  const ProductDetailErrorView({super.key, required this.productId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'This pottery piece is not available right now.',
                style: AppTheme.headingMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),
              Text(
                'We could not load product document `$productId` from Firestore.',
                style: AppTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
