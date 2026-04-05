import 'dart:typed_data';

/// ImageCompressor — Single responsibility: compress image bytes.
/// No upload. No Firestore.
class ImageCompressor {
  /// Compresses image bytes.
  /// Currently acts as a pass-through since flutter_image_compress
  /// is not strictly configured for web without specific setup,
  /// but can be easily swapped out here later.
  static Future<Uint8List> compressImage(Uint8List bytes) async {
    // Basic mock of image compression
    // In a production environment with flutter_image_compress,
    // this would run: FlutterImageCompress.compressWithList(bytes, quality: 75)
    return bytes;
  }
}
