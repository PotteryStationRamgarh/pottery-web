import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter/foundation.dart';

/// CloudinaryService handles all image uploads to Cloudinary.
/// We use Cloudinary REST API directly — no SDK needed for Flutter Web.
///
/// Images are organized into folders using presets:
/// - pottery_branding  → login/signup page images
/// - pottery_portfolio → portfolio/showcase images
/// - pottery_products  → product images (V3)
class CloudinaryService {

  // Private constructor — this class should never be instantiated
  CloudinaryService._();

  // Your Cloudinary cloud name — visible on Cloudinary dashboard
  static const String _cloudName = 'dpmlahejh';

  // Base upload URL for Cloudinary REST API
  static const String _baseUrl = 'https://api.cloudinary.com/v1_1/$_cloudName/image/upload';

  // Upload preset names — must match exactly what you created in Cloudinary
  static const String _brandingPreset = 'pottery_branding';
  static const String _portfolioPreset = 'pottery_portfolio';
  static const String _productsPreset = 'pottery_products'; // V3

  /// Uploads an image to Cloudinary and returns the secure URL.
  ///
  /// [fileBytes] — raw bytes of the image file
  /// [fileName] — original name of the file
  /// [preset] — which Cloudinary preset to use (determines folder)
  ///
  /// Returns secure URL string on success.
  /// Throws exception on failure.
  static Future<String> _uploadImage({
    required Uint8List fileBytes,
    required String fileName,
    required String preset,
  }) async {
    try {
      // Create multipart request to Cloudinary upload endpoint
      final request = http.MultipartRequest('POST', Uri.parse(_baseUrl));

      // Add the upload preset — this tells Cloudinary which folder to use
      request.fields['upload_preset'] = preset;

      // Add the image file as bytes
      request.files.add(
        http.MultipartFile.fromBytes(
          'file',
          fileBytes,
          filename: fileName,
        ),
      );

      // Send the request
      final response = await request.send();

      // Parse the response
      final responseData = await response.stream.bytesToString();
      final jsonData = json.decode(responseData);

      if (response.statusCode == 200) {
        // Return the secure HTTPS URL of the uploaded image
        final String secureUrl = jsonData['secure_url'];
        debugPrint('Image uploaded successfully: $secureUrl');
        return secureUrl;
      } else {
        // Upload failed — throw with Cloudinary error message
        throw Exception('Cloudinary upload failed: ${jsonData['error']['message']}');
      }
    } catch (e) {
      debugPrint('Error uploading image: $e');
      rethrow;
    }
  }

  /// Upload a branding image (login/signup page background).
  /// Stored in pottery_images/branding/ folder in Cloudinary.
  static Future<String> uploadBrandingImage({
    required Uint8List fileBytes,
    required String fileName,
  }) async {
    return await _uploadImage(
      fileBytes: fileBytes,
      fileName: fileName,
      preset: _brandingPreset,
    );
  }

  /// Upload a portfolio image (showcase section).
  /// Stored in pottery_images/portfolio/ folder in Cloudinary.
  static Future<String> uploadPortfolioImage({
    required Uint8List fileBytes,
    required String fileName,
  }) async {
    return await _uploadImage(
      fileBytes: fileBytes,
      fileName: fileName,
      preset: _portfolioPreset,
    );
  }

  /// Upload a product image (V3).
  /// Stored in pottery_images/products/ folder in Cloudinary.
  static Future<String> uploadProductImage({
    required Uint8List fileBytes,
    required String fileName,
  }) async {
    return await _uploadImage(
      fileBytes: fileBytes,
      fileName: fileName,
      preset: _productsPreset,
    );
  }
}