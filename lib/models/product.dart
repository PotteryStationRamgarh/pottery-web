import 'package:cloud_firestore/cloud_firestore.dart';

// ─────────────────────────────────────────
// PRODUCT CATEGORY
// ─────────────────────────────────────────

class ProductCategory {
  final String id;
  final String name;
  final String imageUrl;
  final int order;
  final bool isActive;

  const ProductCategory({
    required this.id,
    required this.name,
    required this.imageUrl,
    required this.order,
    required this.isActive,
  });

  factory ProductCategory.fromDoc(DocumentSnapshot doc) {
    final map = doc.data() as Map<String, dynamic>;
    return ProductCategory(
      id:       doc.id,
      name:     map['name']     as String? ?? '',
      imageUrl: map['imageUrl'] as String? ?? '',
      order:    map['order']    as int?    ?? 0,
      isActive: map['isActive'] as bool?   ?? true,
    );
  }
  Map<String, dynamic> toMap() {
    return {
      'name':     name,
      'imageUrl': imageUrl,
      'order':    order,
      'isActive': isActive,
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

  const Product({
    required this.id,
    required this.title,
    required this.description,
    required this.imageUrls,
    required this.categoryId,
    required this.order,
    required this.isActive,
    this.createdAt,
  });

  factory Product.fromDoc(DocumentSnapshot doc) {
    final map = doc.data() as Map<String, dynamic>;
    return Product(
      id:          doc.id,
      title:       map['title']       as String? ?? '',
      description: map['description'] as String? ?? '',
      imageUrls:   List<String>.from(map['imageUrls'] as List? ?? []),
      categoryId:  map['categoryId']  as String? ?? '',
      order:       map['order']       as int?    ?? 0,
      isActive:    map['isActive']    as bool?   ?? true,
      createdAt:   (map['createdAt']  as Timestamp?)?.toDate(),
    );
  }

  String get primaryImage => imageUrls.isNotEmpty ? imageUrls.first : '';

  Map<String, dynamic> toMap() {
    return {
      'title':       title,
      'description': description,
      'imageUrls':   imageUrls,
      'categoryId':  categoryId,
      'order':       order,
      'isActive':    isActive,
      'createdAt':   createdAt ?? FieldValue.serverTimestamp(),
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
  final int order;
  final bool isActive;
  final DateTime? createdAt;

  const ExclusiveProduct({
    required this.id,
    required this.title,
    required this.description,
    required this.imageUrls,
    required this.totalPieces,
    required this.hasCertificate,
    required this.order,
    required this.isActive,
    this.createdAt,
  });

  factory ExclusiveProduct.fromDoc(DocumentSnapshot doc) {
    final map = doc.data() as Map<String, dynamic>;
    return ExclusiveProduct(
      id:             doc.id,
      title:          map['title']          as String? ?? '',
      description:    map['description']    as String? ?? '',
      imageUrls:      List<String>.from(map['imageUrls'] as List? ?? []),
      totalPieces:    map['totalPieces']    as int?    ?? 1,
      hasCertificate: map['hasCertificate'] as bool?   ?? false,
      order:          map['order']          as int?    ?? 0,
      isActive:       map['isActive']       as bool?   ?? true,
      createdAt:      (map['createdAt']     as Timestamp?)?.toDate(),
    );
  }

  String get primaryImage => imageUrls.isNotEmpty ? imageUrls.first : '';

  Map<String, dynamic> toMap() {
    return {
      'title':          title,
      'description':    description,
      'imageUrls':      imageUrls,
      'totalPieces':    totalPieces,
      'hasCertificate': hasCertificate,
      'order':          order,
      'isActive':       isActive,
      'createdAt':      createdAt ?? FieldValue.serverTimestamp(),
    };
  }
}