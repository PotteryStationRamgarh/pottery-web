import 'dart:math';

import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../models/product.dart';
import '../../widgets/image_placeholder.dart';
import 'product_detail_models.dart';

class InPlaceSection extends StatelessWidget {
  final List<String> images;
  final ProductCategory? category;
  final String productId;

  const InPlaceSection({
    super.key,
    required this.images,
    required this.category,
    required this.productId,
  });

  @override
  Widget build(BuildContext context) {
    final copy = (category?.inPlaceText ?? '').trim();
    final randomImage =
        images[Random(productId.hashCode).nextInt(images.length)];

    return Container(
      width: double.infinity,
      color: AppTheme.exhibitionBackground,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 72),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1120),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('In Place', style: AppTheme.serifHeadingMedium),
              if (copy.isNotEmpty) ...[
                const SizedBox(height: 10),
                Text(copy, style: AppTheme.bodyMedium.copyWith(height: 1.7)),
              ],
              const SizedBox(height: 24),
              LifestyleImageCard(imageUrl: randomImage),
            ],
          ),
        ),
      ),
    );
  }
}

class LifestyleImageCard extends StatelessWidget {
  final String imageUrl;

  const LifestyleImageCard({super.key, required this.imageUrl});

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 1.2,
      child: Container(
        decoration: BoxDecoration(
          color: AppTheme.divider.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(26),
        ),
        child: imageUrl.isEmpty
            ? const ClipRRect(
                borderRadius: BorderRadius.all(Radius.circular(26)),
                child: ImagePlaceholder(
                  aspectRatio: 1.2,
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

class SpecsSection extends StatelessWidget {
  final ProductDetailData data;

  const SpecsSection({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    final specs = <MapEntry<String, String>>[
      MapEntry('Dimensions', data.dimensions),
      MapEntry('Material', data.material),
      MapEntry('Care', data.careInstructions),
    ].where((entry) => entry.value.isNotEmpty).toList();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 72),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 920),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Details', style: AppTheme.serifHeadingMedium),
              const SizedBox(height: 24),
              Container(
                decoration: BoxDecoration(
                  color: AppTheme.surfaceWhite,
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(color: AppTheme.divider),
                ),
                child: Column(
                  children: [
                    for (int index = 0; index < specs.length; index++) ...[
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 22,
                          vertical: 18,
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SizedBox(
                              width: 120,
                              child: Text(
                                specs[index].key,
                                style: AppTheme.bodyMedium,
                              ),
                            ),
                            const SizedBox(width: 18),
                            Expanded(
                              child: Text(
                                specs[index].value,
                                style: AppTheme.bodyLarge.copyWith(height: 1.7),
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (index != specs.length - 1)
                        const Divider(height: 1, color: AppTheme.divider),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ReviewsSection extends StatelessWidget {
  final List<ProductReviewData> reviews;

  const ReviewsSection({super.key, required this.reviews});

  @override
  Widget build(BuildContext context) {
    final visibleReviews = reviews.take(5).toList();

    return Container(
      width: double.infinity,
      color: AppTheme.exhibitionBackground,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 72),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1120),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Collected Notes', style: AppTheme.serifHeadingMedium),
              const SizedBox(height: 24),
              Wrap(
                spacing: 18,
                runSpacing: 18,
                children: visibleReviews
                    .map(
                      (review) => SizedBox(
                        width: 340,
                        child: ReviewCard(review: review),
                      ),
                    )
                    .toList(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ReviewCard extends StatelessWidget {
  final ProductReviewData review;

  const ReviewCard({super.key, required this.review});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: AppTheme.surfaceWhite,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (review.userImage.isNotEmpty)
                Container(
                  width: 38,
                  height: 38,
                  margin: const EdgeInsets.only(right: 12),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(19),
                    child: NetworkImageWithPlaceholder(
                      url: review.userImage,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              Wrap(
                spacing: 2,
                children: List.generate(
                  5,
                  (index) => Icon(
                    index < review.rating.round()
                        ? Icons.star_rounded
                        : Icons.star_border_rounded,
                    size: 18,
                    color: AppTheme.terracotta,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            review.comment,
            style: AppTheme.bodyLarge.copyWith(
              color: AppTheme.textLight,
              height: 1.75,
            ),
          ),
        ],
      ),
    );
  }
}
