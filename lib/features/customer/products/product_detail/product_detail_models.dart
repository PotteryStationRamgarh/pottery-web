import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../../models/product.dart';

class ProductReviewData {
  final double rating;
  final String comment;
  final String userImage;

  const ProductReviewData({
    required this.rating,
    required this.comment,
    required this.userImage,
  });

  factory ProductReviewData.fromMap(Map<String, dynamic> map) {
    return ProductReviewData(
      rating: (map['rating'] as num?)?.toDouble() ?? 0,
      comment: (map['comment'] as String? ?? '').trim(),
      userImage:
          (map['user_image'] as String? ?? map['userImage'] as String? ?? '')
              .trim(),
    );
  }
}

class ProductDetailData {
  final String id;
  final String categoryId;
  final String title;
  final String description;
  final List<String> images;
  final double mrp;
  final double sellingPrice;
  final String dimensions;
  final String material;
  final String careInstructions;
  final List<ProductReviewData> reviews;
  final List<String> tags;
  final int stockCount;

  const ProductDetailData({
    required this.id,
    required this.categoryId,
    required this.title,
    required this.description,
    required this.images,
    required this.mrp,
    required this.sellingPrice,
    required this.dimensions,
    required this.material,
    required this.careInstructions,
    required this.reviews,
    required this.tags,
    required this.stockCount,
  });

  static ProductDetailData? fromSnapshot(
    DocumentSnapshot<Map<String, dynamic>>? snapshot, {
    Product? fallback,
  }) {
    final map = snapshot?.data();
    if (map != null) {
      return ProductDetailData.fromMap(snapshot!.id, map);
    }

    if (fallback == null) return null;

    return ProductDetailData(
      id: fallback.id,
      categoryId: fallback.categoryId,
      title: fallback.title.isEmpty ? 'Untitled Piece' : fallback.title,
      description: fallback.description,
      images: fallback.imageUrls,
      mrp: fallback.mrp,
      sellingPrice: fallback.sellingPrice,
      dimensions: _readDimensions(fallback.dimensions),
      material: fallback.material,
      careInstructions: fallback.careInstructions.join(' • '),
      reviews: const [],
      tags: fallback.tags,
      stockCount: fallback.stockCount,
    );
  }

  factory ProductDetailData.fromMap(String id, Map<String, dynamic> map) {
    final rawImages =
        (map['images'] as List?) ?? (map['imageUrls'] as List?) ?? const [];
    final rawReviews = (map['reviews'] as List?) ?? const [];

    return ProductDetailData(
      id: id,
      categoryId: (map['categoryId'] as String? ?? '').trim(),
      title: (map['title'] as String? ?? '').trim().isEmpty
          ? 'Untitled Piece'
          : (map['title'] as String).trim(),
      description: (map['description'] as String? ?? '').trim(),
      images: rawImages
          .map((item) => item.toString().trim())
          .where((item) => item.isNotEmpty)
          .toList(),
      mrp:
          (map['mrp'] as num?)?.toDouble() ??
          (map['price'] as num?)?.toDouble() ??
          0,
      sellingPrice:
          (map['sellingPrice'] as num?)?.toDouble() ??
          (map['price'] as num?)?.toDouble() ??
          (map['mrp'] as num?)?.toDouble() ??
          0,
      dimensions: _readDimensions(map['dimensions']),
      material: (map['material'] as String? ?? '').trim(),
      careInstructions: _readCareInstructions(
        map['care_instructions'] ?? map['careInstructions'],
      ),
      reviews: rawReviews
          .whereType<Map>()
          .map(
            (review) =>
                ProductReviewData.fromMap(Map<String, dynamic>.from(review)),
          )
          .where((review) => review.comment.isNotEmpty)
          .toList(),
      tags:
          (map['tags'] as List?)
              ?.map((item) => item.toString().trim())
              .where((item) => item.isNotEmpty)
              .toList() ??
          const [],
      stockCount: map['stockCount'] as int? ?? 99,
    );
  }

  double get finalPrice => sellingPrice > 0 ? sellingPrice : mrp;

  bool get hasDiscount => mrp > finalPrice && finalPrice > 0;

  int get discountPercent {
    if (!hasDiscount) return 0;
    return (((mrp - finalPrice) / mrp) * 100).round();
  }

  String get priceText => '₹${_formatPrice(finalPrice)}';

  String get mrpText => '₹${_formatPrice(mrp)}';

  String get shortDescription => description.isNotEmpty
      ? description
      : 'A handmade pottery piece with a tactile finish and a quiet presence for everyday use.';

  String get fullDescription => description.isNotEmpty
      ? description
      : 'Formed by hand and finished with care, this piece carries natural variation in surface, tone, and form, making each one feel singular in use and display.';

  List<String> get lifestyleImages {
    if (images.length <= 1) return const [];
    return images.skip(1).take(2).toList();
  }

  bool get hasSpecs =>
      dimensions.isNotEmpty ||
      material.isNotEmpty ||
      careInstructions.isNotEmpty;

  Product toCartProduct() {
    return Product(
      id: id,
      title: title,
      description: description,
      imageUrls: images,
      categoryId: categoryId,
      order: 0,
      isActive: true,
      mrp: mrp,
      sellingPrice: finalPrice,
      material: material,
      careInstructions: careInstructions.isEmpty
          ? const []
          : careInstructions.split(' • '),
      stockCount: stockCount,
    );
  }

  static String _readCareInstructions(dynamic value) {
    if (value is String) return value.trim();
    if (value is List) {
      return value
          .map((item) => item.toString().trim())
          .where((item) => item.isNotEmpty)
          .join(' • ');
    }
    return '';
  }

  static String _readDimensions(dynamic value) {
    if (value is String) return value.trim();
    if (value is! Map) return '';

    final map = Map<String, dynamic>.from(value);
    final parts = <String>[];

    void add(String label, List<String> keys) {
      for (final key in keys) {
        final raw = map[key];
        final text = raw?.toString().trim() ?? '';
        if (text.isNotEmpty && text != '0') {
          parts.add('$label $text');
          return;
        }
      }
    }

    add('L', ['length']);
    add('W', ['width']);
    add('H', ['height']);
    add('D', ['depth', 'diameter']);
    return parts.join(' • ');
  }

  static String _formatPrice(double value) {
    return value.truncateToDouble() == value
        ? value.toStringAsFixed(0)
        : value.toStringAsFixed(2);
  }
}
