import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../services/media_service.dart';
import '../../models/custom_products_config.dart';

class CustomProductsConfigRepository {
  CustomProductsConfigRepository._();

  static final _db = FirebaseFirestore.instance;
  static final _media = MediaService();

  static Future<CustomProductsConfig> getConfig() async {
    try {
      final doc = await _db
          .collection('app_config')
          .doc('custom_products')
          .get();
      if (!doc.exists) return CustomProductsConfig.fromMap(null);
      return CustomProductsConfig.fromMap(doc.data());
    } catch (e) {
      debugPrint('CustomProductsConfigRepository.getConfig error: $e');
      return CustomProductsConfig.fromMap(null);
    }
  }

  static Future<void> saveConfig(
    CustomProductsConfig config, {
    Uint8List? heroImageBytes,
    String? previousHeroImageUrl,
  }) async {
    var nextConfig = config;

    if (heroImageBytes != null) {
      if (previousHeroImageUrl != null && previousHeroImageUrl.isNotEmpty) {
        await _media.deletePublicUrls([previousHeroImageUrl]);
      }

      final urls = await _media.uploadImages(
        docId: 'custom_products',
        pathPrefix: 'custom_products',
        files: [heroImageBytes],
      );

      if (urls.isNotEmpty) {
        nextConfig = CustomProductsConfig(
          heroImageUrl: urls.first,
          heroTitle: config.heroTitle,
          heroSubtitle: config.heroSubtitle,
          glazeOptions: config.glazeOptions,
          productTypes: config.productTypes,
          introText: config.introText,
          isEnabled: config.isEnabled,
        );
      }
    }

    await _db
        .collection('app_config')
        .doc('custom_products')
        .set(nextConfig.toMap(), SetOptions(merge: true));
  }
}
