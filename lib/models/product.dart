import 'package:cloud_firestore/cloud_firestore.dart';

// ─────────────────────────────────────────
// PRODUCT CATEGORY
// ─────────────────────────────────────────

class ProductCategory {
  final String id;
  final String name;
  final String description;
  final String imageUrl;
  final int order;
  final int productCount;
  final bool isActive;
  final DateTime? updatedAt;

  const ProductCategory({
    required this.id,
    required this.name,
    this.description = '',
    required this.imageUrl,
    required this.order,
    this.productCount = 0,
    required this.isActive,
    this.updatedAt,
  });

  factory ProductCategory.fromDoc(DocumentSnapshot doc) {
    final map = doc.data() as Map<String, dynamic>? ?? {};

    return ProductCategory(
      id: doc.id,
      name: map['name'] as String? ?? '',
      description: map['description'] as String? ?? '',
      imageUrl: map['imageUrl'] as String? ?? '',
      order: map['order'] as int? ?? 0,
      productCount: map['productCount'] as int? ?? 0,
      isActive: map['isActive'] as bool? ?? true,
      updatedAt: (map['updatedAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'description': description,
      'imageUrl': imageUrl,
      'order': order,
      'productCount': productCount,
      'isActive': isActive,
      'updatedAt': updatedAt ?? FieldValue.serverTimestamp(),
    };
  }
}

// ─────────────────────────────────────────
// PRODUCT
// ─────────────────────────────────────────

class Product {
  final String id;
  final String title;
  final String description;
  final List<String> imageUrls;
  final String categoryId;
  final int order;
  final bool isActive;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  // New ecommerce fields — all nullable with safe defaults
  final double mrp;           // original price (0 if not set)
  final double sellingPrice;  // sale price (0 if not set)
  final int stockCount;       // 99 if not set (assume in stock)
  final bool isInStock;       // true if not set
  final String sku;           // '' if not set
  final int weight;           // grams, 0 if not set
  final Map<String, dynamic> dimensions; // {height, width, depth}
  final String material;
  final List<String> careInstructions;
  final List<String> tags;
  final int soldCount;        // 0 if not set — used for popularity ranking

  const Product({
    required this.id,
    required this.title,
    required this.description,
    required this.imageUrls,
    required this.categoryId,
    required this.order,
    required this.isActive,
    this.createdAt,
    this.updatedAt,
    this.mrp = 0,
    this.sellingPrice = 0,
    this.stockCount = 99,
    this.isInStock = true,
    this.sku = '',
    this.weight = 0,
    this.dimensions = const {'height': 0, 'width': 0, 'depth': 0},
    this.material = '',
    this.careInstructions = const [],
    this.tags = const [],
    this.soldCount = 0,
  });

  factory Product.fromDoc(DocumentSnapshot doc) {
    final map = doc.data() as Map<String, dynamic>? ?? {};

    return Product(
      id: doc.id,
      title: map['title'] as String? ?? '',
      description: map['description'] as String? ?? '',
      imageUrls: (map['imageUrls'] as List?)?.map((e) => e.toString()).toList() ?? [],
      categoryId: map['categoryId'] as String? ?? '',
      order: map['order'] as int? ?? 0,
      isActive: map['isActive'] as bool? ?? true,
      createdAt: (map['createdAt'] as Timestamp?)?.toDate(),
      updatedAt: (map['updatedAt'] as Timestamp?)?.toDate(),
      mrp: (map['mrp'] as num?)?.toDouble() ?? 0,
      sellingPrice: (map['sellingPrice'] as num?)?.toDouble() ?? 0,
      stockCount: map['stockCount'] as int? ?? 99,
      isInStock: map['isInStock'] as bool? ?? true,
      sku: map['sku'] as String? ?? '',
      weight: map['weight'] as int? ?? 0,
      dimensions: map['dimensions'] as Map<String, dynamic>? ?? {'height': 0, 'width': 0, 'depth': 0},
      material: map['material'] as String? ?? '',
      careInstructions: (map['careInstructions'] as List?)?.map((e) => e.toString()).toList() ?? [],
      tags: (map['tags'] as List?)?.map((e) => e.toString()).toList() ?? [],
      soldCount: map['soldCount'] as int? ?? 0,
    );
  }

  /// Safe primary image (never crashes)
  String get primaryImage => imageUrls.isNotEmpty ? imageUrls.first : '';

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'description': description,
      'imageUrls': imageUrls,
      'categoryId': categoryId,
      'order': order,
      'isActive': isActive,
      'createdAt': createdAt ?? FieldValue.serverTimestamp(),
      'updatedAt': updatedAt ?? FieldValue.serverTimestamp(),
      'mrp': mrp,
      'sellingPrice': sellingPrice,
      'stockCount': stockCount,
      'isInStock': isInStock,
      'sku': sku,
      'weight': weight,
      'dimensions': dimensions,
      'material': material,
      'careInstructions': careInstructions,
      'tags': tags,
      'soldCount': soldCount,
    };
  }
}

// ─────────────────────────────────────────
// EXCLUSIVE PRODUCT
// ─────────────────────────────────────────

class ExclusiveProduct {
  final String id;
  final String title;
  final String description;
  final List<String> imageUrls;
  final int totalPieces;
  final bool hasCertificate;
  final String material;
  final String craftingTime;
  final int order;
  final bool isActive;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  // New ecommerce fields
  final double mrp;
  final double sellingPrice;
  final int stockCount;
  final bool isInStock;
  final String sku;
  final int weight;
  final Map<String, dynamic> dimensions;
  final List<String> careInstructions;
  final List<String> tags;
  final int soldCount;
  final String seriesName;
  final String editionType;
  final String artistNote;

  const ExclusiveProduct({
    required this.id,
    required this.title,
    required this.description,
    required this.imageUrls,
    required this.totalPieces,
    required this.hasCertificate,
    required this.material,
    required this.craftingTime,
    required this.order,
    required this.isActive,
    this.createdAt,
    this.updatedAt,
    this.mrp = 0,
    this.sellingPrice = 0,
    this.stockCount = 99,
    this.isInStock = true,
    this.sku = '',
    this.weight = 0,
    this.dimensions = const {'height': 0, 'width': 0, 'depth': 0},
    this.careInstructions = const [],
    this.tags = const [],
    this.soldCount = 0,
    this.seriesName = '',
    this.editionType = 'Limited Edition',
    this.artistNote = '',
  });

  factory ExclusiveProduct.fromDoc(DocumentSnapshot doc) {
    final map = doc.data() as Map<String, dynamic>? ?? {};

    return ExclusiveProduct(
      id: doc.id,
      title: map['title'] as String? ?? '',
      description: map['description'] as String? ?? '',
      imageUrls: (map['imageUrls'] as List?)?.map((e) => e.toString()).toList() ?? [],
      totalPieces: map['totalPieces'] as int? ?? 1,
      hasCertificate: map['hasCertificate'] as bool? ?? false,
      material: map['material'] as String? ?? '',
      craftingTime: map['craftingTime'] as String? ?? '',
      order: map['order'] as int? ?? 0,
      isActive: map['isActive'] as bool? ?? true,
      createdAt: (map['createdAt'] as Timestamp?)?.toDate(),
      updatedAt: (map['updatedAt'] as Timestamp?)?.toDate(),
      mrp: (map['mrp'] as num?)?.toDouble() ?? 0,
      sellingPrice: (map['sellingPrice'] as num?)?.toDouble() ?? 0,
      stockCount: map['stockCount'] as int? ?? 99,
      isInStock: map['isInStock'] as bool? ?? true,
      sku: map['sku'] as String? ?? '',
      weight: map['weight'] as int? ?? 0,
      dimensions: map['dimensions'] as Map<String, dynamic>? ?? {'height': 0, 'width': 0, 'depth': 0},
      careInstructions: (map['careInstructions'] as List?)?.map((e) => e.toString()).toList() ?? [],
      tags: (map['tags'] as List?)?.map((e) => e.toString()).toList() ?? [],
      soldCount: map['soldCount'] as int? ?? 0,
      seriesName: map['seriesName'] as String? ?? '',
      editionType: map['editionType'] as String? ?? 'Limited Edition',
      artistNote: map['artistNote'] as String? ?? '',
    );
  }

  /// Safe primary image
  String get primaryImage => imageUrls.isNotEmpty ? imageUrls.first : '';

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'description': description,
      'imageUrls': imageUrls,
      'totalPieces': totalPieces,
      'hasCertificate': hasCertificate,
      'material': material,
      'craftingTime': craftingTime,
      'order': order,
      'isActive': isActive,
      'createdAt': createdAt ?? FieldValue.serverTimestamp(),
      'updatedAt': updatedAt ?? FieldValue.serverTimestamp(),
      'mrp': mrp,
      'sellingPrice': sellingPrice,
      'stockCount': stockCount,
      'isInStock': isInStock,
      'sku': sku,
      'weight': weight,
      'dimensions': dimensions,
      'careInstructions': careInstructions,
      'tags': tags,
      'soldCount': soldCount,
      'seriesName': seriesName,
      'editionType': editionType,
      'artistNote': artistNote,
    };
  }
}
