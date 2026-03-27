import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/services/firestore_service.dart';
import '../../../../core/services/media_service.dart';
import '../../../../models/product_category.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:typed_data';

class AdminAddCategoryPage extends StatefulWidget {
  const AdminAddCategoryPage({super.key});

  @override
  State<AdminAddCategoryPage> createState() => _AdminAddCategoryPageState();
}

class _AdminAddCategoryPageState extends State<AdminAddCategoryPage> {
  bool _isSaving = false;

  late TextEditingController _nameCtrl;
  late TextEditingController _orderCtrl;
  bool _isActive = true;

  Uint8List? _imageBytes;
  final ImagePicker _picker = ImagePicker();
  final MediaService _mediaService = MediaService();

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController();
    _orderCtrl = TextEditingController();
  }

  Future<void> _pickImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      final bytes = await image.readAsBytes();
      setState(() => _imageBytes = bytes);
    }
  }

  Future<void> _save() async {
    if (_nameCtrl.text.isEmpty || _imageBytes == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Name and Cover Image are required')));
      return;
    }

    setState(() => _isSaving = true);
    try {
      // 1. Create document first (empty image URL)
      final category = ProductCategory(
        id: '', // Firestore auto-generates
        name: _nameCtrl.text.trim(),
        imageUrl: '', // Will update
        isActive: _isActive,
        order: int.tryParse(_orderCtrl.text) ?? 0,
      );
      
      final docRef = await FirestoreService.addCategory(category);
      final docId = docRef.id;

      // 2. Upload Image using new docId
      final urls = await _mediaService.uploadImages(
        docId: docId,
        pathPrefix: 'categories',
        files: [_imageBytes!],
      );

      // 3. Update document with actual URL
      if (urls.isNotEmpty) {
        await FirestoreService.updateCategory(docId, {'imageUrl': urls.first});
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Category added successfully!'), backgroundColor: AppTheme.successGreen),
        );
        Navigator.of(context).pop(); // Go back to categories list
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to add category: $e'), backgroundColor: AppTheme.errorRed),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _orderCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 28, 24, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: () => Navigator.of(context).pop(),
                ),
                const SizedBox(width: 8),
                Text('Add New Category', style: AppTheme.headingLarge),
                const Spacer(),
                ElevatedButton(
                  onPressed: _isSaving ? null : _save,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryBrown,
                    foregroundColor: AppTheme.white,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: _isSaving
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : Text('Save & Publish', style: AppTheme.labelLarge),
                ),
              ],
            ),
            const SizedBox(height: 32),

            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 3,
                  child: Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(color: AppTheme.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppTheme.divider)),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Category Details', style: AppTheme.headingMedium),
                        const SizedBox(height: 24),
                        _buildField('Name', _nameCtrl),
                        const SizedBox(height: 16),
                        _buildField('Display Order', _orderCtrl, keyboardType: TextInputType.number),
                        const SizedBox(height: 24),
                        Row(
                          children: [
                            Text('Is Active', style: AppTheme.bodyLarge.copyWith(fontWeight: FontWeight.w600)),
                            const SizedBox(width: 16),
                            Switch(
                              value: _isActive,
                              activeColor: AppTheme.primaryBrown,
                              onChanged: (val) => setState(() => _isActive = val),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 24),
                Expanded(
                  flex: 2,
                  child: Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(color: AppTheme.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppTheme.divider)),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Cover Image', style: AppTheme.headingMedium),
                        const SizedBox(height: 24),
                        GestureDetector(
                          onTap: _pickImage,
                          child: Container(
                            height: 240,
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color: AppTheme.background,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: AppTheme.divider),
                              image: _imageBytes != null ? DecorationImage(
                                image: MemoryImage(_imageBytes!),
                                fit: BoxFit.cover,
                              ) : null,
                            ),
                            child: _imageBytes == null ? Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.add_photo_alternate_outlined, size: 48, color: AppTheme.greyPlaceholder),
                                const SizedBox(height: 12),
                                Text('Upload Image', style: AppTheme.bodyMedium.copyWith(color: AppTheme.textLight)),
                              ],
                            ) : null,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }

  Widget _buildField(String label, TextEditingController controller, {TextInputType? keyboardType}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTheme.bodySmall.copyWith(fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          style: AppTheme.bodyLarge,
          decoration: AppTheme.inputDecoration(label: label, hint: 'Enter $label'),
        ),
      ],
    );
  }
}
