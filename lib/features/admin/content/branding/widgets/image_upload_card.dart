import 'dart:typed_data';
import 'package:flutter/material.dart';
import '../../../../../core/theme/app_theme.dart';

/// Reusable image upload card used for both logo and auth image.
/// Pass [isCircular] true for logo, false for auth image (rounded square).
/// Both cards are identical in size and layout — only shape differs.
class ImageUploadCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final Uint8List? localBytes;
  final String? networkUrl;
  final bool isCircular;
  final VoidCallback onPick;

  const ImageUploadCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.localBytes,
    required this.networkUrl,
    required this.isCircular,
    required this.onPick,
  });

  bool get _hasImage =>
      localBytes != null || (networkUrl != null && networkUrl!.isNotEmpty);

  ImageProvider get _imageProvider => localBytes != null
      ? MemoryImage(localBytes!) as ImageProvider
      : NetworkImage(networkUrl!);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppTheme.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Card header ──
          Text(
            title,
            style: AppTheme.headingMedium.copyWith(color: AppTheme.textDark),
          ),
          const SizedBox(height: 4),
          Text(subtitle, style: AppTheme.bodySmall),
          const SizedBox(height: 20),

          // ── Image preview + tap to change ──
          Center(
            child: GestureDetector(
              onTap: onPick,
              child: _hasImage ? _previewImage() : _emptyState(),
            ),
          ),

          const SizedBox(height: 16),

          // ── Change/Upload button ──
          Center(
            child: TextButton.icon(
              onPressed: onPick,
              icon: Icon(
                _hasImage ? Icons.swap_horiz_rounded : Icons.upload_rounded,
                size: 16,
                color: AppTheme.primaryBrown,
              ),
              label: Text(
                _hasImage ? 'Change Image' : 'Upload Image',
                style: AppTheme.bodyMedium.copyWith(
                  color: AppTheme.primaryBrown,
                  fontWeight: FontWeight.w600,
                ),
              ),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                backgroundColor: AppTheme.primaryBrown.withOpacity(0.08),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Preview when image exists
  Widget _previewImage() {
    const double size = 160;
    if (isCircular) {
      return Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: AppTheme.divider, width: 2),
          image: DecorationImage(image: _imageProvider, fit: BoxFit.cover),
        ),
      );
    }
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.divider, width: 2),
        image: DecorationImage(image: _imageProvider, fit: BoxFit.cover),
      ),
    );
  }

  /// Empty state when no image uploaded yet
  Widget _emptyState() {
    const double size = 160;
    final Widget inner = Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          Icons.add_photo_alternate_outlined,
          size: 32,
          color: AppTheme.greyPlaceholder,
        ),
        const SizedBox(height: 8),
        Text(
          'Tap to upload',
          style: AppTheme.bodySmall.copyWith(color: AppTheme.greyPlaceholder),
        ),
      ],
    );

    if (isCircular) {
      return Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: AppTheme.background,
          border: Border.all(
            color: AppTheme.divider,
            width: 2,
            style: BorderStyle.solid,
          ),
        ),
        child: inner,
      );
    }

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: AppTheme.background,
        border: Border.all(color: AppTheme.divider, width: 2),
      ),
      child: inner,
    );
  }
}
