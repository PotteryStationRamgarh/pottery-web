import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../repositories/custom_order_repository.dart';
import 'local_session_service.dart';
import 'media_service.dart';

class StorefrontCleanupService {
  StorefrontCleanupService._();

  static final _db = FirebaseFirestore.instance;
  static final _media = MediaService();

  static const _collectionsToScan = <String>[
    'products',
    'categories',
    'exclusive_products',
    'exhibition',
    'custom_orders',
    'support_messages',
    'notifications',
    'system_email_outbox',
  ];

  static Future<void> runMaintenanceIfDue({
    Duration interval = const Duration(hours: 12),
  }) async {
    final lastRun = await LocalSessionService.readLastMaintenanceRun();
    final now = DateTime.now();
    if (lastRun != null && now.difference(lastRun) < interval) return;

    try {
      await CustomOrderRepository.cleanupRejectedOrders();
      await cleanupOrphanedCloudflareImages();
      await LocalSessionService.writeLastMaintenanceRun(now);
    } catch (e) {
      debugPrint('StorefrontCleanupService.runMaintenanceIfDue error: $e');
    }
  }

  static Future<void> cleanupOrphanedCloudflareImages() async {
    try {
      final referencedPaths = <String>{};

      for (final collection in _collectionsToScan) {
        final snap = await _db.collection(collection).get();
        for (final doc in snap.docs) {
          _collectUrls(doc.data(), referencedPaths);
        }
      }

      final appConfig = await _db.collection('app_config').get();
      for (final doc in appConfig.docs) {
        _collectUrls(doc.data(), referencedPaths);
      }

      final allObjects = await _media.listAllObjectPaths();
      final orphaned = allObjects
          .where((path) => !referencedPaths.contains(path))
          .where((path) => path.trim().isNotEmpty)
          .toList();

      if (orphaned.isEmpty) return;

      final urls = orphaned.map(_media.publicUrlForPath).toList();
      await _media.deletePublicUrls(urls);
    } catch (e) {
      debugPrint(
        'StorefrontCleanupService.cleanupOrphanedCloudflareImages error: $e',
      );
    }
  }

  static void _collectUrls(dynamic value, Set<String> target) {
    if (value is Map) {
      for (final entry in value.values) {
        _collectUrls(entry, target);
      }
      return;
    }
    if (value is Iterable) {
      for (final entry in value) {
        _collectUrls(entry, target);
      }
      return;
    }
    if (value is String) {
      final path = _media.extractObjectPath(value);
      if (path != null) {
        target.add(path);
      }
    }
  }
}
