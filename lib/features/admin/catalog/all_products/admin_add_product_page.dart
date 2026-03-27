import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/services/firestore_service.dart';
import '../../../../core/services/media_service.dart';
import '../../../../models/product.dart';
import '../../../../models/product_category.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:typed_data';

class AdminAddProductPage extends StatefulWidget {
  const AdminAddProductPage({super.key});

  @override
  State<AdminAddProductPage> createState() => _AdminAddProductPageState();
}

class _AdminAddProductPageState extends State<AdminAddProductPage> {
  bool _isLoading = true;
  bool _isSaving = false;

  late TextEditingController _titleCtrl;
  late TextEditingController _descCtrl;
  late TextEditingController _orderCtrl;
  
  String? _selectedCategoryId;
  bool _isActive = true;
  List<ProductCategory> _categories = [];

  final List<Uint8List> _imageBytes = [];
  final ImagePicker _picker = ImagePicker();
  final MediaService _mediaService = MediaService();

  @override
  void initState() {
    super.initState();
    _titleCtrl = TextEditingController();
    _descCtrl = TextEditingController();
    _orderCtrl = TextEditingController();
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    try {
      final cats = await FirestoreService.getCategories();
      if (mounted) {
        setState(() {
          _categories = cats;
          if (cats.isNotEmpty) {
            _selectedCategoryId = cats.first.id;
          }
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to load categories: $e')));
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _pickImages() async {
    final List<XFile> images = await _picker.pickMultiImage();
    if (images.isNotEmpty) {
      for (var img in images) {
        final bytes = await img.readAsBytes();
        setState(() => _imageBytes.add(bytes));
      }
    }
  }

  void _removeImage(int index) {
    setState(() => _imageBytes.removeAt(index));
  }

  Future<void> _save() async {
    if (_titleCtrl.text.isEmpty || _selectedCategoryId == null || _selectedCategoryId!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Title and Category are required')));
      return;
    }

    if (_imageBytes.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('At least one image is required')));
      return;
    }

    setState(() => _isSaving = true);
    try {
      // 1. Create document first to get ID
      final product = Product(
        id: '',
        title: _titleCtrl.text.trim(),
        description: _descCtrl.text.trim(),
        categoryId: _selectedCategoryId!,
        imageUrls: [],
        isActive: _isActive,
        order: int.tryParse(_orderCtrl.text) ?? 0,
        createdAt: Timestamp.now(),
      );
      
      final docRef = await FirestoreService.addProduct(product);
      final docId = docRef.id;

      // 2. Upload Images
      final urls = await _mediaService.uploadImages(
        docId: docId,
        pathPrefix: 'products',
        files: _imageBytes,
      );

      // 3. Update document with URLs
      await FirestoreService.updateProduct(docId, {'imageUrls': urls});

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Product added successfully!'), backgroundColor: AppTheme.successGreen),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to add product: $e'), backgroundColor: AppTheme.errorRed),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    _orderCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Scaffold(backgroundColor: AppTheme.background, body: Center(child: CircularProgressIndicator(color: AppTheme.primaryBrown)));

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
                Text('Add New Product', style: AppTheme.headingLarge),
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
                        Text('Basic Details', style: AppTheme.headingMedium),
                        const SizedBox(height: 24),
                        _buildField('Product Title', _titleCtrl),
                        const SizedBox(height: 16),
                        _buildField('Description', _descCtrl, maxLines: 4),
                        const SizedBox(height: 16),
                        
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Category', style: AppTheme.bodySmall.copyWith(fontWeight: FontWeight.w600)),
                            const SizedBox(height: 8),
                            DropdownButtonFormField<String>(
                              value: _selectedCategoryId,
                              decoration: AppTheme.inputDecoration(label: 'Category', hint: 'Select Category'),
                              items: _categories.map((c) => DropdownMenuItem(value: c.id, child: Text(c.name))).toList(),
                              onChanged: (val) => setState(() => _selectedCategoryId = val),
                            ),
                          ],
                        ),
                        
                        const SizedBox(height: 24),
                        Row(
                          children: [
                            Expanded(child: _buildField('Display Order', _orderCtrl, keyboardType: TextInputType.number)),
                            const SizedBox(width: 24),
                            Expanded(
                              child: Row(
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
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 24),
                // Images Section
                Expanded(
                  flex: 2,
                  child: Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(color: AppTheme.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppTheme.divider)),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Product Images', style: AppTheme.headingMedium),
                            TextButton.icon(
                              onPressed: _pickImages,
                              icon: const Icon(Icons.add_photo_alternate_outlined, color: AppTheme.primaryBrown),
                              label: const Text('Add Images', style: TextStyle(color: AppTheme.primaryBrown)),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        if (_imageBytes.isEmpty)
                          Container(
                            height: 200,
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color: AppTheme.background,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: AppTheme.divider, style: BorderStyle.dash),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.photo_library_outlined, size: 48, color: AppTheme.greyPlaceholder),
                                const SizedBox(height: 12),
                                Text('No images selected', style: AppTheme.bodyMedium.copyWith(color: AppTheme.textLight)),
                              ],
                            ),
                          )
                        else
                          GridView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              crossAxisSpacing: 12,
                              mainAxisSpacing: 12,
                            ),
                            itemCount: _imageBytes.length,
                            itemBuilder: (context, index) {
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
                            },
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

  Widget _buildField(String label, TextEditingController controller, {int maxLines = 1, TextInputType? keyboardType}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTheme.bodySmall.copyWith(fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          maxLines: maxLines,
          keyboardType: keyboardType,
          style: AppTheme.bodyLarge,
          decoration: AppTheme.inputDecoration(label: label, hint: 'Enter $label'),
        ),
      ],
    );
  }
}
