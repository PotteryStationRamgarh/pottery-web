import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/theme/app_theme.dart';
import 'package:google_fonts/google_fonts.dart';

/// ImageUploadWidget — handles single or multiple image upload with preview.
/// Returns uploaded image bytes to parent widget.
class ImageUploadWidget extends StatefulWidget {
  final bool multiple;
  final void Function(List<Uint8List> images) onImagesSelected;
  final String title;
  final double minHeight;

  const ImageUploadWidget({
    super.key,
    required this.onImagesSelected,
    this.multiple = false,
    this.title = 'Upload Image',
    this.minHeight = 240,
  });

  @override
  State<ImageUploadWidget> createState() => _ImageUploadWidgetState();
}

class _ImageUploadWidgetState extends State<ImageUploadWidget> {
  final ImagePicker _picker = ImagePicker();
  final List<Uint8List> _imageBytes = [];

  Future<void> _pickImages() async {
    try {
      if (widget.multiple) {
        final List<XFile> images = await _picker.pickMultiImage();
        if (images.isNotEmpty) {
          final bytes = <Uint8List>[];
          for (var img in images) {
            bytes.add(await img.readAsBytes());
          }
          setState(() => _imageBytes.addAll(bytes));
          widget.onImagesSelected(_imageBytes);
        }
      } else {
        final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
        if (image != null) {
          final bytes = await image.readAsBytes();
          setState(() {
            _imageBytes.clear();
            _imageBytes.add(bytes);
          });
          widget.onImagesSelected(_imageBytes);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error picking image: $e')),
        );
      }
    }
  }

  void _removeImage(int index) {
    setState(() {
      _imageBytes.removeAt(index);
      widget.onImagesSelected(_imageBytes);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              widget.title,
              style: GoogleFonts.playfairDisplay(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppTheme.textDark,
              ),
            ),
            TextButton.icon(
              onPressed: _pickImages,
              icon: const Icon(Icons.add_photo_alternate_outlined, color: AppTheme.primaryBrown),
              label: const Text('Add', style: TextStyle(color: AppTheme.primaryBrown)),
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (_imageBytes.isEmpty)
          _buildEmptyState()
        else
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: widget.multiple ? 2 : 1,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: widget.multiple ? 1 : 2,
            ),
            itemCount: _imageBytes.length,
            itemBuilder: (context, index) => _buildImageCard(context, index),
          ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return GestureDetector(
      onTap: _pickImages,
      child: Container(
        height: widget.minHeight,
        width: double.infinity,
        decoration: BoxDecoration(
          color: AppTheme.background,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppTheme.divider),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.add_photo_alternate_outlined, size: 48, color: AppTheme.greyPlaceholder),
            const SizedBox(height: 12),
            Text(
              'Click to ${widget.multiple ? 'select images' : 'upload image'}',
              style: AppTheme.bodyMedium.copyWith(color: AppTheme.textLight),
            ),
          ],
        ),
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
              image: MemoryImage(_imageBytes[index]),
              fit: BoxFit.cover,
            ),
          ),
        ),
        Positioned(
          top: 4,
          right: 4,
          child: GestureDetector(
            onTap: () => _removeImage(index),
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
