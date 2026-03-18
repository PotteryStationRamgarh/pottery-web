import 'dart:math';
import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/services/branding_service.dart';

/// BrandingImageWidget — shows on left side of signin and signup screens.
///
/// Behavior:
/// - Fetches all branding image URLs from Firestore
/// - If multiple images exist → picks one randomly each time
/// - If no images exist → shows grey placeholder box with ? icon
/// - Image is always fixed size — layout never shifts
/// - Subtle gradient overlay on bottom for visual polish
class BrandingImageWidget extends StatefulWidget {
  const BrandingImageWidget({super.key});

  @override
  State<BrandingImageWidget> createState() => _BrandingImageWidgetState();
}

class _BrandingImageWidgetState extends State<BrandingImageWidget> {
  // Selected image URL — null means no image found
  String? _imageUrl;

  // True while fetching from Firestore
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadImage();
  }

  /// Fetches branding images and picks one randomly.
  Future<void> _loadImage() async {
    final urls = await BrandingService.getBrandingImageUrls();

    if (!mounted) return;

    if (urls.isEmpty) {
      setState(() {
        _imageUrl = null;
        _isLoading = false;
      });
      return;
    }

    // Pick a random image from available URLs
    final random = Random();
    final selectedUrl = urls[random.nextInt(urls.length)];

    setState(() {
      _imageUrl = selectedUrl;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: BoxDecoration(
        color: AppTheme.greyPlaceholder,
        borderRadius: BorderRadius.circular(24),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: _isLoading
            ? _buildLoadingState()
            : _imageUrl != null
                ? _buildImageState(_imageUrl!)
                : _buildPlaceholderState(),
      ),
    );
  }

  /// Shows loading indicator while fetching
  Widget _buildLoadingState() {
    return Container(
      color: AppTheme.greyPlaceholder,
      child: const Center(
        child: CircularProgressIndicator(
          color: AppTheme.lightBrown,
          strokeWidth: 2,
        ),
      ),
    );
  }

  /// Shows actual image with gradient overlay
  Widget _buildImageState(String url) {
    return Stack(
      fit: StackFit.expand,
      children: [
        // Main image — always fills box, crops if needed
        Image.network(
          url,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            // If URL fails to load — show placeholder
            return _buildPlaceholderState();
          },
        ),

        // Gradient overlay at bottom
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: Container(
            height: 120,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
                colors: [
                  AppTheme.primaryBrown.withOpacity(0.4),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),

        // Brand text at bottom of image
        Positioned(
          bottom: 24,
          left: 24,
          right: 24,
          child: Text(
            'Pottery Station Ramgarh',
            style: AppTheme.headingMedium.copyWith(
              color: AppTheme.white,
              shadows: [
                Shadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 8,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  /// Shows grey box with ? icon when no image available
  Widget _buildPlaceholderState() {
    return Container(
      color: AppTheme.greyPlaceholder,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: AppTheme.white.withOpacity(0.5),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.question_mark_rounded,
              size: 40,
              color: AppTheme.white,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'No image uploaded yet',
            style: AppTheme.bodyMedium.copyWith(
              color: AppTheme.white.withOpacity(0.8),
            ),
          ),
        ],
      ),
    );
  }
}