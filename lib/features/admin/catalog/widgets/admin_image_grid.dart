import 'dart:typed_data';
import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import 'package:google_fonts/google_fonts.dart';

/// AdminImageGrid — displays uploaded images in a grid with remove buttons.
/// Shows placeholder when empty.
class AdminImageGrid extends StatelessWidget {
  final List<Uint8List> images;
  final VoidCallback onAddImages;
  final Function(int index) onRemoveImage;
  final String title;
  final int crossAxisCount;

  const AdminImageGrid({
    super.key,
    required this.images,
    required this.onAddImages,
    required this.onRemoveImage,
    this.title = 'Images',
    this.crossAxisCount = 2,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: GoogleFonts.playfairDisplay(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppTheme.textDark,
              ),
            ),
            TextButton.icon(
              onPressed: onAddImages,
              icon: const Icon(
                Icons.add_photo_alternate_outlined,
                color: AppTheme.primaryBrown,
              ),
              label: const Text(
                'Add Images',
                style: TextStyle(color: AppTheme.primaryBrown),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (images.isEmpty)
          _buildEmptyState()
        else
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: crossAxisCount,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
            ),
            itemCount: images.length,
            itemBuilder: (context, index) => _buildImageCard(context, index),
          ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Container(
      height: 200,
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppTheme.background,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.divider, style: BorderStyle.solid),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.photo_library_outlined,
            size: 48,
            color: AppTheme.greyPlaceholder,
          ),
          const SizedBox(height: 12),
          Text(
            'No images selected',
            style: AppTheme.bodyMedium.copyWith(color: AppTheme.textLight),
          ),
        ],
      ),
    );
  }

  Widget _buildImageCard(BuildContext context, int index) {
    return Stack(
      children: [
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppTheme.divider),
            image: DecorationImage(
              image: MemoryImage(images[index]),
              fit: BoxFit.cover,
            ),
          ),
        ),
        Positioned(
          top: 4,
          right: 4,
          child: GestureDetector(
            onTap: () => onRemoveImage(index),
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: const BoxDecoration(
                color: Colors.black54,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.close, size: 16, color: Colors.white),
            ),
          ),
        ),
      ],
    );
  }
}
