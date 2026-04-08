import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';

class GallerySkeleton extends StatelessWidget {
  const GallerySkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: const [
        SkeletonBlock(height: 620, radius: 28),
        SizedBox(height: 16),
        Row(
          children: [
            Expanded(child: SkeletonBlock(height: 84, radius: 18)),
            SizedBox(width: 10),
            Expanded(child: SkeletonBlock(height: 84, radius: 18)),
            SizedBox(width: 10),
            Expanded(child: SkeletonBlock(height: 84, radius: 18)),
          ],
        ),
      ],
    );
  }
}

class ProductInfoSkeleton extends StatelessWidget {
  const ProductInfoSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SkeletonLine(widthFactor: 0.24),
        SizedBox(height: 14),
        SkeletonLine(widthFactor: 0.8, height: 36),
        SizedBox(height: 12),
        SkeletonLine(widthFactor: 0.48, height: 28),
        SizedBox(height: 20),
        SkeletonLine(widthFactor: 1),
        SizedBox(height: 10),
        SkeletonLine(widthFactor: 0.92),
        SizedBox(height: 10),
        SkeletonLine(widthFactor: 0.72),
        SizedBox(height: 24),
        SkeletonBlock(height: 126, radius: 22),
        SizedBox(height: 24),
        SkeletonBlock(height: 56, radius: 14),
        SizedBox(height: 16),
        SkeletonBlock(height: 56, radius: 14),
        SizedBox(height: 12),
        SkeletonBlock(height: 56, radius: 14),
      ],
    );
  }
}

class SkeletonBlock extends StatelessWidget {
  final double height;
  final double radius;

  const SkeletonBlock({super.key, required this.height, this.radius = 16});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppTheme.divider.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }
}

class SkeletonLine extends StatelessWidget {
  final double widthFactor;
  final double height;

  const SkeletonLine({super.key, required this.widthFactor, this.height = 18});

  @override
  Widget build(BuildContext context) {
    return FractionallySizedBox(
      widthFactor: widthFactor,
      child: SkeletonBlock(height: height, radius: 10),
    );
  }
}
