import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../models/product.dart';
import '../../widgets/image_placeholder.dart';
import 'product_detail_models.dart';

class ProductGallerySection extends StatelessWidget {
  final List<String> images;
  final int selectedImageIndex;
  final ValueChanged<int> onImageSelected;

  const ProductGallerySection({
    super.key,
    required this.images,
    required this.selectedImageIndex,
    required this.onImageSelected,
  });

  @override
  Widget build(BuildContext context) {
    final safeImages = images.isEmpty ? const [''] : images;
    final imageUrl =
        safeImages[selectedImageIndex.clamp(0, safeImages.length - 1)];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AspectRatio(
          aspectRatio: 1,
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 260),
            child: Container(
              key: ValueKey(imageUrl),
              decoration: BoxDecoration(
                color: AppTheme.divider.withValues(alpha: 0.22),
                borderRadius: BorderRadius.circular(28),
              ),
              child: imageUrl.isEmpty
                  ? const ClipRRect(
                      borderRadius: BorderRadius.all(Radius.circular(28)),
                      child: ImagePlaceholder(
                        aspectRatio: 1,
                        borderRadius: BorderRadius.all(Radius.circular(28)),
                      ),
                    )
                  : NetworkImageWithPlaceholder(
                      url: imageUrl,
                      borderRadius: BorderRadius.circular(28),
                      fit: BoxFit.cover,
                    ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 84,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: safeImages.length,
            separatorBuilder: (context, index) => const SizedBox(width: 10),
            itemBuilder: (context, index) {
              final thumbnail = safeImages[index];
              final isSelected = index == selectedImageIndex;

              return GestureDetector(
                onTap: () => onImageSelected(index),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 220),
                  width: 84,
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceWhite,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: isSelected
                          ? AppTheme.terracotta
                          : AppTheme.borderColor,
                    ),
                  ),
                  child: thumbnail.isEmpty
                      ? const ClipRRect(
                          borderRadius: BorderRadius.all(Radius.circular(14)),
                          child: ImagePlaceholder(
                            aspectRatio: 1,
                            borderRadius: BorderRadius.all(Radius.circular(14)),
                          ),
                        )
                      : NetworkImageWithPlaceholder(
                          url: thumbnail,
                          borderRadius: BorderRadius.circular(14),
                          fit: BoxFit.cover,
                        ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class ProductInfoSection extends StatelessWidget {
  final ProductDetailData data;
  final ProductCategory? category;
  final int quantity;
  final VoidCallback onDecreaseQuantity;
  final VoidCallback onIncreaseQuantity;
  final VoidCallback onAddToCart;
  final VoidCallback onBuyNow;

  const ProductInfoSection({
    super.key,
    required this.data,
    required this.category,
    required this.quantity,
    required this.onDecreaseQuantity,
    required this.onIncreaseQuantity,
    required this.onAddToCart,
    required this.onBuyNow,
  });

  @override
  Widget build(BuildContext context) {
    final label =
        category?.name ?? (data.tags.isNotEmpty ? data.tags.first : '');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label.isNotEmpty)
          Text(
            label.toUpperCase(),
            style: AppTheme.bodySmall.copyWith(
              letterSpacing: 2,
              fontWeight: FontWeight.w600,
              color: AppTheme.terracotta,
            ),
          ),
        const SizedBox(height: 10),
        Text(
          data.title,
          style: AppTheme.serifHeadingLarge.copyWith(fontSize: 34, height: 1.2),
        ),
        const SizedBox(height: 12),
        Wrap(
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 12,
          runSpacing: 10,
          children: [
            Text(
              data.priceText,
              style: AppTheme.headingLarge.copyWith(fontSize: 28),
            ),
            if (data.hasDiscount)
              Text(
                data.mrpText,
                style: AppTheme.bodyLarge.copyWith(
                  color: AppTheme.textLight,
                  decoration: TextDecoration.lineThrough,
                ),
              ),
            if (data.hasDiscount)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: AppTheme.exhibitionBackground,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  '${data.discountPercent}% off',
                  style: AppTheme.bodySmall.copyWith(
                    color: AppTheme.terracotta,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
          ],
        ),
        if (data.stockCount <= 10) ...[
          const SizedBox(height: 16),
          _buildStockWarning(data.stockCount),
        ],
        const SizedBox(height: 18),
        Text(
          data.shortDescription,
          maxLines: 3,
          overflow: TextOverflow.ellipsis,
          style: AppTheme.bodyLarge.copyWith(
            color: AppTheme.textLight,
            height: 1.75,
          ),
        ),
        const SizedBox(height: 20),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppTheme.exhibitionBackground,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: AppTheme.divider),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Each piece is shaped by hand — no two are ever identical.',
                style: AppTheme.headingMedium.copyWith(fontSize: 18),
              ),
              const SizedBox(height: 8),
              Text(
                'Crafted slowly, meant to last.',
                style: AppTheme.bodyMedium.copyWith(height: 1.6),
              ),
            ],
          ),
        ),
        const SizedBox(height: 28),
        if (data.stockCount > 0) ...[
          QuantitySelector(
            quantity: quantity,
            onDecrease: onDecreaseQuantity,
            onIncrease: data.stockCount > quantity ? onIncreaseQuantity : () {},
          ),
          const SizedBox(height: 20),
        ],
        SizedBox(
          width: double.infinity,
          child: FilledButton(
            onPressed: data.stockCount > 0 ? onAddToCart : null,
            style: FilledButton.styleFrom(
              backgroundColor: data.stockCount > 0 ? AppTheme.terracotta : AppTheme.divider,
              foregroundColor: data.stockCount > 0 ? AppTheme.white : AppTheme.textLight,
              padding: const EdgeInsets.symmetric(vertical: 18),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            child: Text(data.stockCount > 0 ? 'ADD TO CART' : 'OUT OF STOCK', style: AppTheme.labelLarge),
          ),
        ),
        const SizedBox(height: 12),
        if (data.stockCount > 0)
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: onBuyNow,
              style: OutlinedButton.styleFrom(
                foregroundColor: AppTheme.textDark,
                side: const BorderSide(color: AppTheme.borderColor),
                padding: const EdgeInsets.symmetric(vertical: 18),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: Text(
                'BUY NOW',
                style: AppTheme.bodyLarge.copyWith(
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1.2,
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildStockWarning(int stock) {
    if (stock <= 0) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.red.shade50,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.block, color: Colors.red.shade700, size: 16),
            const SizedBox(width: 8),
            Text(
              'Out of Stock',
              style: AppTheme.bodySmall.copyWith(
                color: Colors.red.shade700,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      );
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.orange.shade50,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.warning_amber_rounded, color: Colors.orange.shade800, size: 16),
          const SizedBox(width: 8),
          Text(
            'Only $stock left in stock',
            style: AppTheme.bodySmall.copyWith(
              color: Colors.orange.shade800,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class QuantitySelector extends StatelessWidget {
  final int quantity;
  final VoidCallback onDecrease;
  final VoidCallback onIncrease;

  const QuantitySelector({
    super.key,
    required this.quantity,
    required this.onDecrease,
    required this.onIncrease,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          'Quantity',
          style: AppTheme.bodyLarge.copyWith(fontWeight: FontWeight.w500),
        ),
        const SizedBox(width: 18),
        Container(
          decoration: BoxDecoration(
            color: AppTheme.surfaceWhite,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppTheme.divider),
          ),
          child: Row(
            children: [
              QuantityButton(icon: Icons.remove, onTap: onDecrease),
              SizedBox(
                width: 54,
                child: Center(
                  child: Text(
                    '$quantity',
                    style: AppTheme.bodyLarge.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              QuantityButton(icon: Icons.add, onTap: onIncrease),
            ],
          ),
        ),
      ],
    );
  }
}

class QuantityButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const QuantityButton({super.key, required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Icon(icon, size: 18, color: AppTheme.textDark),
      ),
    );
  }
}

class CraftSection extends StatelessWidget {
  final String material;

  const CraftSection({super.key, required this.material});

  @override
  Widget build(BuildContext context) {
    final text = material.isNotEmpty
        ? 'Formed on the wheel, finished by hand, and fired with care in $material.'
        : 'Formed on the wheel, finished by hand, and fired with care.';

    return Container(
      width: double.infinity,
      color: AppTheme.exhibitionBackground,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 72),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 760),
          child: Column(
            children: [
              Text('Craft', style: AppTheme.serifHeadingMedium),
              const SizedBox(height: 18),
              Text(
                '$text Made to feel grounded, warm, and quietly distinct.',
                textAlign: TextAlign.center,
                style: AppTheme.bodyLarge.copyWith(
                  color: AppTheme.textLight,
                  height: 1.8,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class DescriptionSection extends StatelessWidget {
  final ProductDetailData data;
  final ProductCategory? category;

  const DescriptionSection({
    super.key,
    required this.data,
    required this.category,
  });

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width >= 960;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 72),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1120),
          child: isDesktop
              ? Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      flex: 5,
                      child: CategoryImageCard(
                        imageUrl: category?.imageUrl ?? '',
                      ),
                    ),
                    const SizedBox(width: 32),
                    Expanded(flex: 7, child: DescriptionCopy(data: data)),
                  ],
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CategoryImageCard(imageUrl: category?.imageUrl ?? ''),
                    const SizedBox(height: 24),
                    DescriptionCopy(data: data),
                  ],
                ),
        ),
      ),
    );
  }
}

class DescriptionCopy extends StatelessWidget {
  final ProductDetailData data;

  const DescriptionCopy({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Description', style: AppTheme.serifHeadingMedium),
        const SizedBox(height: 20),
        Text(
          data.fullDescription,
          style: AppTheme.bodyLarge.copyWith(
            color: AppTheme.textLight,
            height: 1.9,
          ),
        ),
      ],
    );
  }
}

class CategoryImageCard extends StatelessWidget {
  final String imageUrl;

  const CategoryImageCard({super.key, required this.imageUrl});

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 0.9,
      child: Container(
        decoration: BoxDecoration(
          color: AppTheme.divider.withValues(alpha: 0.18),
          borderRadius: BorderRadius.circular(26),
        ),
        child: imageUrl.isEmpty
            ? const ClipRRect(
                borderRadius: BorderRadius.all(Radius.circular(26)),
                child: ImagePlaceholder(
                  aspectRatio: 0.9,
                  borderRadius: BorderRadius.all(Radius.circular(26)),
                ),
              )
            : NetworkImageWithPlaceholder(
                url: imageUrl,
                borderRadius: BorderRadius.circular(26),
                fit: BoxFit.cover,
              ),
      ),
    );
  }
}
