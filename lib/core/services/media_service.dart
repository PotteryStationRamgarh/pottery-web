import 'package:flutter/foundation.dart';
import 'package:minio/minio.dart';
import '../utils/image_compressor.dart';
import 'remote_config_service.dart';

/// MediaService — Handles compression and R2 uploads using MinIO (S3 compatible client)
/// Strict rule: DocId MUST exist before calling this.
class MediaService {
  // ✅ FIX 2: Hardcoded Public Config (Public data is safe)
  static const String _bucket = 'pottery-station-ramgarh-assets';
  static const String _publicUrlBase =
      'https://pub-32b0eccfedfb4b29980313569dfccc15.r2.dev';

  Minio _createMinio() {
    final accountId = RemoteConfigService.r2AccountId;
    final accessKey = RemoteConfigService.r2AccessKeyId;
    final secretKey = RemoteConfigService.r2SecretAccessKey;

    if (accountId.isEmpty || accessKey.isEmpty || secretKey.isEmpty) {
      throw Exception(
        "Cloudflare R2 secrets not configured in Firebase Remote Config.",
      );
    }

    return Minio(
      endPoint: '$accountId.r2.cloudflarestorage.com',
      accessKey: accessKey,
      secretKey: secretKey,
      useSSL: true,
      region: 'auto',
    );
  }

  /// Compress → Upload → Return Public URLs
  /// pathPrefix examples: 'products', 'categories', 'exclusive', 'branding', 'exhibition'
  Future<List<String>> uploadImages({
    required String docId,
    required String pathPrefix,
    required List<Uint8List> files,
  }) async {
    // 🔴 FIX 3: Validation
    if (!_publicUrlBase.startsWith('http')) {
      throw Exception('Invalid R2 public URL configuration');
    }

    // Initialize Minio for Cloudflare R2
    final minio = _createMinio();

    List<String> urls = [];

    for (int i = 0; i < files.length; i++) {
      // 1. Compress
      final compressed = await ImageCompressor.compressImage(files[i]);

      // 2. Generate path based on prefix
      String path;
      if (pathPrefix == 'branding') {
        path = 'branding/$docId';
      } else {
        path = '$pathPrefix/$docId/image_${i + 1}.jpg';
      }

      // 🔴 FIX 4: Debug Logging
      debugPrint('Uploading to: $path');

      // 3. Upload Document to R2
      await _uploadToR2(minio, path, compressed);

      // 4. Construct Public URL
      final imageUrl = '$_publicUrlBase/$path';

      // 🔴 FIX 3: Validation
      if (!imageUrl.startsWith('http')) {
        throw Exception('Invalid generated image URL');
      }

      // 🔴 FIX 4: Debug Logging
      debugPrint('Generated URL: $imageUrl');

      urls.add(imageUrl);
    }

    return urls;
  }

  Future<void> deletePublicUrls(List<String> urls) async {
    final objectPaths = urls
        .map(_extractObjectPath)
        .whereType<String>()
        .toSet()
        .toList();

    if (objectPaths.isEmpty) return;

    final minio = _createMinio();

    for (final path in objectPaths) {
      try {
        await minio.removeObject(_bucket, path);
      } catch (e) {
        debugPrint('Failed to delete image from R2: $path, error: $e');
      }
    }
  }

  String? _extractObjectPath(String url) {
    final trimmed = url.trim();
    if (trimmed.isEmpty || !trimmed.startsWith(_publicUrlBase)) return null;

    final path = trimmed.substring(_publicUrlBase.length).replaceFirst('/', '');
    return path.isEmpty ? null : path;
  }

  Future<void> _uploadToR2(Minio minio, String path, Uint8List bytes) async {
    try {
      String contentType = 'image/jpeg';
      if (path.endsWith('.png')) contentType = 'image/png';

      final stream = Stream<Uint8List>.fromIterable([bytes]);

      await minio.putObject(
        _bucket,
        path,
        stream,
        size: bytes.length,
        metadata: {'Content-Type': contentType},
      );
    } catch (e) {
      throw Exception('Failed to upload image to $path: $e');
    }
  }
}
