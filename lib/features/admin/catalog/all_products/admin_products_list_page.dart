import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../models/product.dart';
import '../../../../models/product_category.dart';
import '../repositories/product_repository.dart';
import '../widgets/admin_form_field.dart';
import '../widgets/admin_toggle_switch.dart';
import '../widgets/image_upload_widget.dart';

class AdminProductsListPage extends StatefulWidget {
  const AdminProductsListPage({super.key});

  @override
  State<AdminProductsListPage> createState() => _AdminProductsListPageState();
}

class _AdminProductsListPageState extends State<AdminProductsListPage> {
  String _mode = 'list'; // 'list' or 'form'
  bool _isLoading = true;
  bool _isSaving = false;

  List<Product> _allProducts = [];
  List<Product> _filteredProducts = [];
  List<ProductCategory> _categories = [];
  String _searchQuery = '';

  // Form State
  Product? _editingProduct;
  late TextEditingController _titleCtrl;
  late TextEditingController _descCtrl;
  late TextEditingController _orderCtrl;
  late TextEditingController _searchCtrl;
  String? _selectedCategoryId;
  bool _isActive = true;
  List<Uint8List> _newImageBytes = [];
  List<String> _currentImageUrls = [];

  @override
  void initState() {
    super.initState();
    _titleCtrl = TextEditingController();
    _descCtrl = TextEditingController();
    _orderCtrl = TextEditingController();
    _searchCtrl = TextEditingController();
    _loadData();
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    _orderCtrl.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  // ── LOAD ──────────────────────────────────────────────────────────────────

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final results = await Future.wait([
        ProductRepository.getProducts(),
        ProductRepository.getCategories(),
      ]);
      _allProducts = results[0] as List<Product>;
      _categories = results[1] as List<ProductCategory>;
      _applyFilter();
    } catch (e) {
      _showSnackbar('Error loading data: $e', isError: true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _applyFilter() {
    setState(() {
      if (_searchQuery.isEmpty) {
        _filteredProducts = List.from(_allProducts);
      } else {
        final query = _searchQuery.toLowerCase();
        _filteredProducts = _allProducts.where((p) {
          final catName = _getCategoryName(p.categoryId).toLowerCase();
          return p.title.toLowerCase().contains(query) || catName.contains(query);
        }).toList();
      }
    });
  }

  String _getCategoryName(String id) {
    final cat = _categories.where((c) => c.id == id).firstOrNull;
    return cat?.name ?? 'Unknown Category';
  }

  // ── DELETE ────────────────────────────────────────────────────────────────

  Future<void> _deleteProduct(Product product) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Product?'),
        content: Text('Delete "${product.title}"? This cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await ProductRepository.deleteProduct(product.id);
        _showSnackbar('Product deleted');
        _loadData();
      } catch (e) {
        _showSnackbar('Delete failed: $e', isError: true);
      }
    }
  }

  // ── MODE SWITCH ───────────────────────────────────────────────────────────

  void _showForm([Product? product]) {
    _editingProduct = product;
    if (product != null) {
      _titleCtrl.text = product.title;
      _descCtrl.text = product.description;
      _orderCtrl.text = product.order.toString();
      _selectedCategoryId = _categories.any((c) => c.id == product.categoryId) ? product.categoryId : (_categories.isNotEmpty ? _categories.first.id : null);
      _isActive = product.isActive;
      _currentImageUrls = List.from(product.imageUrls);
    } else {
      _titleCtrl.clear();
      _descCtrl.clear();
      _orderCtrl.clear();
      _selectedCategoryId = _categories.isNotEmpty ? _categories.first.id : null;
      _isActive = true;
      _currentImageUrls = [];
    }
    _newImageBytes = [];
    setState(() => _mode = 'form');
  }

  void _showList() {
    setState(() => _mode = 'list');
    _loadData();
  }

  // ── SAVE ──────────────────────────────────────────────────────────────────

  Future<void> _save() async {
    if (_titleCtrl.text.trim().isEmpty) {
      _showSnackbar('Title is required', isError: true);
      return;
    }
    if (_selectedCategoryId == null) {
      _showSnackbar('Category is required', isError: true);
      return;
    }

    setState(() => _isSaving = true);
    try {
      if (_editingProduct == null) {
        // Add
        if (_newImageBytes.isEmpty) throw 'At least one image is required';
        await ProductRepository.addProduct(
          title: _titleCtrl.text.trim(),
          description: _descCtrl.text.trim(),
          categoryId: _selectedCategoryId!,
          imageBytes: _newImageBytes,
          order: int.tryParse(_orderCtrl.text) ?? 0,
          isActive: _isActive,
        );
      } else {
        // Update
        if (_newImageBytes.isNotEmpty) {
          await ProductRepository.updateProductWithImages(
            id: _editingProduct!.id,
            title: _titleCtrl.text.trim(),
            description: _descCtrl.text.trim(),
            categoryId: _selectedCategoryId!,
            imageBytes: _newImageBytes,
            order: int.tryParse(_orderCtrl.text) ?? 0,
            isActive: _isActive,
          );
        } else {
          await ProductRepository.updateProduct(
            id: _editingProduct!.id,
            title: _titleCtrl.text.trim(),
            description: _descCtrl.text.trim(),
            categoryId: _selectedCategoryId!,
            order: int.tryParse(_orderCtrl.text) ?? 0,
            isActive: _isActive,
          );
        }
      }

      _showSnackbar('Product saved successfully!');
      _showList();
    } catch (e) {
      _showSnackbar('Failed to save product: $e', isError: true);
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _onImagesSelected(List<Uint8List> images) {
    setState(() => _newImageBytes = images);
  }

  // ── BUILD ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: _mode == 'list' ? _buildListView() : _buildFormView(),
    );
  }

  // ── LIST VIEW ─────────────────────────────────────────────────────────────

  Widget _buildListView() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(32),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final isNarrow = constraints.maxWidth < 600;
              return isNarrow
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Products', style: AppTheme.headingLarge),
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: () => _showForm(),
                            icon: const Icon(Icons.add),
                            label: const Text('Add Product'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.primaryBrown,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                          ),
                        ),
                      ],
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Products', style: AppTheme.headingLarge),
                        ElevatedButton.icon(
                          onPressed: () => _showForm(),
                          icon: const Icon(Icons.add),
                          label: const Text('Add Product'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primaryBrown,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ],
                    );
            },
          ),
        ),

        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: TextField(
            controller: _searchCtrl,
            onChanged: (val) {
              _searchQuery = val;
              _applyFilter();
            },
            decoration: AppTheme.inputDecoration(
              label: 'Search products...',
              hint: 'Search by title or category',
            ).copyWith(
              prefixIcon: const Icon(Icons.search, color: AppTheme.textLight),
            ),
          ),
        ),

        const SizedBox(height: 24),

        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _filteredProducts.isEmpty
                  ? _buildEmptyState()
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(32, 0, 32, 32),
                      itemCount: _filteredProducts.length,
                      separatorBuilder: (context, index) => const SizedBox(height: 16),
                      itemBuilder: (context, index) => _buildProductCard(_filteredProducts[index]),
                    ),
        ),
      ],
    );
  }

  Widget _buildProductCard(Product product) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.divider),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isNarrow = constraints.maxWidth < 500;
          
          return Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: AppTheme.background,
                    borderRadius: BorderRadius.circular(8),
                    image: product.imageUrls.isNotEmpty
                        ? DecorationImage(image: NetworkImage(product.imageUrls.first), fit: BoxFit.cover)
                        : null,
                  ),
                  child: product.imageUrls.isEmpty ? const Icon(Icons.image, color: AppTheme.greyPlaceholder) : null,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        product.title, 
                        style: AppTheme.headingMedium.copyWith(fontSize: 16),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        '${_getCategoryName(product.categoryId)} • Order: ${product.order}', 
                        style: AppTheme.bodySmall,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: (product.isActive ? AppTheme.successGreen : Colors.grey).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    product.isActive ? 'Active' : 'Inactive',
                    style: TextStyle(
                      color: product.isActive ? AppTheme.successGreen : Colors.grey,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                
                if (!isNarrow) ...[
                  IconButton(
                    icon: const Icon(Icons.edit_outlined, color: AppTheme.primaryBrown),
                    onPressed: () => _showForm(product),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline, color: Colors.red),
                    onPressed: () => _deleteProduct(product),
                  ),
                ] else ...[
                  PopupMenuButton<String>(
                    onSelected: (val) {
                      if (val == 'edit') _showForm(product);
                      else if (val == 'delete') _deleteProduct(product);
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(value: 'edit', child: Text('Edit')),
                      const PopupMenuItem(value: 'delete', child: Text('Delete', style: TextStyle(color: Colors.red))),
                    ],
                  ),
                ],
              ],
            ),
          );
        }
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.inventory_2_outlined, size: 64, color: AppTheme.textLight),
          const SizedBox(height: 16),
          Text(_searchQuery.isEmpty ? 'No products yet.' : 'No matching products.', style: AppTheme.bodyLarge),
        ],
      ),
    );
  }

  // ── FORM VIEW ─────────────────────────────────────────────────────────────

  Widget _buildFormView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              TextButton.icon(
                onPressed: _showList,
                icon: const Icon(Icons.arrow_back),
                label: const Text('Back to List'),
                style: TextButton.styleFrom(foregroundColor: AppTheme.primaryBrown),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  _editingProduct == null ? 'Add Product' : 'Edit: ${_editingProduct!.title}',
                  style: AppTheme.headingLarge,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 16),
              ElevatedButton(
                onPressed: _isSaving ? null : _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryBrown,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: _isSaving
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Text('Save Product'),
              ),
            ],
          ),

          const SizedBox(height: 32),

          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 3,
                child: _buildSection('Product Details', [
                  AdminFormField(label: 'Title', hint: 'Enter product title', controller: _titleCtrl),
                  const SizedBox(height: 16),
                  AdminFormField(label: 'Description', hint: 'Enter product description', controller: _descCtrl, maxLines: 4),
                  const SizedBox(height: 16),
                  _buildCategoryDropdown(),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(child: AdminFormField(label: 'Display Order', hint: 'Enter order', controller: _orderCtrl, keyboardType: TextInputType.number)),
                      const SizedBox(width: 24),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: AdminToggleSwitch(
                            label: 'Is Active',
                            value: _isActive,
                            onChanged: (val) => setState(() => _isActive = val),
                          ),
                        ),
                      ),
                    ],
                  ),
                ]),
              ),
              const SizedBox(width: 24),
              Expanded(
                flex: 2,
                child: _buildSection('Product Images', [
                  ImageUploadWidget(
                    title: 'Upload Images',
                    multiple: true,
                    onImagesSelected: _onImagesSelected,
                  ),
                  if (_editingProduct != null && _newImageBytes.isEmpty && _currentImageUrls.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Current Images:', style: TextStyle(fontWeight: FontWeight.bold)),
                          const SizedBox(height: 8),
                          SizedBox(
                            height: 100,
                            child: ListView.separated(
                              scrollDirection: Axis.horizontal,
                              itemCount: _currentImageUrls.length,
                              separatorBuilder: (context, index) => const SizedBox(width: 8),
                              itemBuilder: (context, index) => Image.network(_currentImageUrls[index], width: 100, fit: BoxFit.cover),
                            ),
                          ),
                        ],
                      ),
                    ),
                ]),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Category',
          style: GoogleFonts.jost(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: AppTheme.textDark,
          ),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: _selectedCategoryId,
          decoration: AppTheme.inputDecoration(label: 'Category', hint: 'Select category'),
          items: _categories
              .map((c) => DropdownMenuItem(value: c.id, child: Text(c.name)))
              .toList(),
          onChanged: (val) => setState(() => _selectedCategoryId = val),
        ),
      ],
    );
  }

  Widget _buildSection(String title, List<Widget> children) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: AppTheme.headingMedium),
          const SizedBox(height: 20),
          ...children,
        ],
      ),
    );
  }

  void _showSnackbar(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: isError ? Colors.red : AppTheme.successGreen),
    );
  }
}
