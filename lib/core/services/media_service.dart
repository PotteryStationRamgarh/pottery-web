import 'dart:typed_data';
import 'package:firebase_storage/firebase_storage.dart';
import '../utils/image_compressor.dart';

/// MediaService — Handles compression and R2/Storage uploads.
/// Requires a docId to be generated first.
class MediaService {
  static final _storage = FirebaseStorage.instance;

  /// Compress → Upload → Return URLs
  /// pathPrefix examples: 'products', 'exclusive', 'categories', 'exhibition', 'branding'
  Future<List<String>> uploadImages({
    required String docId,
    required String pathPrefix,
    required List<Uint8List> files,
  }) async {
    List<String> urls = [];
    
    for (int i = 0; i < files.length; i++) {
      // 1. Compress
      final compressed = await ImageCompressor.compressImage(files[i]);
      
      // 2. Generate path based on prefix
      // E.g., branding/logo.png OR products/xyz123/image_1.jpg
      String path;
      if (pathPrefix == 'branding') {
        // Since we explicitly control the filename for branding
        // we map it based on docId we pass. Here we pass the specific filename as docId.
        // e.g., 'logo.png', 'login.png', 'signup.png'
        path = 'branding/$docId';
      } else {
        path = '$pathPrefix/$docId/image_${i + 1}.jpg';
      }

      // 3. Upload
      final url = await _uploadToR2(path, compressed);
      urls.add(url);
    }
    
    return urls;
  }

  /// Internal method to upload bytes to Firebase Storage (or R2 configured bucket)
  Future<String> _uploadToR2(String path, Uint8List bytes) async {
    try {
      final ref = _storage.ref().child(path);
      
      // Determine content type
      String contentType = 'image/jpeg';
      if (path.endsWith('.png')) contentType = 'image/png';
      
      final uploadTask = await ref.putData(
        bytes,
        SettableMetadata(contentType: contentType),
      );
      
      final downloadUrl = await uploadTask.ref.getDownloadURL();
      return downloadUrl;
    } catch (e) {
      throw Exception('Failed to upload image to $path: $e');
    }
  }
}
