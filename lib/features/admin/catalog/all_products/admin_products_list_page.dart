import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../../core/providers/app_refresh_provider.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/responsive_utils.dart';
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

  // New Fields
  late TextEditingController _mrpCtrl;
  late TextEditingController _sellingPriceCtrl;
  late TextEditingController _stockCountCtrl;
  late TextEditingController _skuCtrl;
  late TextEditingController _weightCtrl;
  late TextEditingController _materialCtrl;
  late TextEditingController _hCtrl;
  late TextEditingController _wCtrl;
  late TextEditingController _dCtrl;
  late TextEditingController _careInputCtrl;
  late TextEditingController _tagInputCtrl;

  List<String> _careInstructions = [];
  List<String> _tags = [];
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

    _mrpCtrl = TextEditingController();
    _sellingPriceCtrl = TextEditingController();
    _stockCountCtrl = TextEditingController();
    _skuCtrl = TextEditingController();
    _weightCtrl = TextEditingController();
    _materialCtrl = TextEditingController();
    _hCtrl = TextEditingController();
    _wCtrl = TextEditingController();
    _dCtrl = TextEditingController();
    _careInputCtrl = TextEditingController();
    _tagInputCtrl = TextEditingController();

    _loadData();
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    _orderCtrl.dispose();
    _searchCtrl.dispose();

    _mrpCtrl.dispose();
    _sellingPriceCtrl.dispose();
    _stockCountCtrl.dispose();
    _skuCtrl.dispose();
    _weightCtrl.dispose();
    _materialCtrl.dispose();
    _hCtrl.dispose();
    _wCtrl.dispose();
    _dCtrl.dispose();
    _careInputCtrl.dispose();
    _tagInputCtrl.dispose();
    super.dispose();
  }

  // ── LOAD ──────────────────────────────────────────────────────────────────

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final results = await Future.wait([
        ProductRepository.getProducts(forceRefresh: true),
        ProductRepository.getCategories(forceRefresh: true),
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
          return p.title.toLowerCase().contains(query) ||
              catName.contains(query);
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
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
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
        if (mounted) context.read<AppRefreshProvider>().invalidateAll();
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
      _selectedCategoryId = _categories.any((c) => c.id == product.categoryId)
          ? product.categoryId
          : (_categories.isNotEmpty ? _categories.first.id : null);
      _isActive = product.isActive;
      _currentImageUrls = List.from(product.imageUrls);

      _mrpCtrl.text = product.mrp.toString();
      _sellingPriceCtrl.text = product.sellingPrice.toString();
      _stockCountCtrl.text = product.stockCount.toString();
      _skuCtrl.text = product.sku;
      _weightCtrl.text = product.weight.toString();
      _materialCtrl.text = product.material;
      _hCtrl.text = product.dimensions['height']?.toString() ?? '0';
      _wCtrl.text = product.dimensions['width']?.toString() ?? '0';
      _dCtrl.text = product.dimensions['depth']?.toString() ?? '0';
      _careInstructions = List.from(product.careInstructions);
      _tags = List.from(product.tags);
    } else {
      _titleCtrl.clear();
      _descCtrl.clear();
      _orderCtrl.clear();
      _selectedCategoryId = _categories.isNotEmpty
          ? _categories.first.id
          : null;
      _isActive = true;
      _currentImageUrls = [];

      _mrpCtrl.clear();
      _sellingPriceCtrl.clear();
      _stockCountCtrl.text = '99';
      _skuCtrl.text = 'AUTO-GENERATED';
      _weightCtrl.clear();
      _materialCtrl.clear();
      _hCtrl.clear();
      _wCtrl.clear();
      _dCtrl.clear();
      _careInstructions = [];
      _tags = [];
    }
    _newImageBytes = [];
    _careInputCtrl.clear();
    _tagInputCtrl.clear();
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
      final mrp = double.tryParse(_mrpCtrl.text) ?? 0.0;
      final sellingPrice = double.tryParse(_sellingPriceCtrl.text) ?? 0.0;
      final stockCount = int.tryParse(_stockCountCtrl.text) ?? 99;
      final weight = int.tryParse(_weightCtrl.text) ?? 0;
      final dimensions = {
        'height': double.tryParse(_hCtrl.text) ?? 0.0,
        'width': double.tryParse(_wCtrl.text) ?? 0.0,
        'depth': double.tryParse(_dCtrl.text) ?? 0.0,
      };

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
          mrp: mrp,
          sellingPrice: sellingPrice,
          stockCount: stockCount,
          weight: weight,
          material: _materialCtrl.text.trim(),
          dimensions: dimensions,
          careInstructions: _careInstructions,
          tags: _tags,
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
            mrp: mrp,
            sellingPrice: sellingPrice,
            stockCount: stockCount,
            weight: weight,
            material: _materialCtrl.text.trim(),
            dimensions: dimensions,
            careInstructions: _careInstructions,
            tags: _tags,
            sku: _skuCtrl.text,
          );
        } else {
          await ProductRepository.updateProduct(
            id: _editingProduct!.id,
            title: _titleCtrl.text.trim(),
            description: _descCtrl.text.trim(),
            categoryId: _selectedCategoryId!,
            order: int.tryParse(_orderCtrl.text) ?? 0,
            isActive: _isActive,
            mrp: mrp,
            sellingPrice: sellingPrice,
            stockCount: stockCount,
            weight: weight,
            material: _materialCtrl.text.trim(),
            dimensions: dimensions,
            careInstructions: _careInstructions,
            tags: _tags,
            sku: _skuCtrl.text,
          );
        }
      }

      _showSnackbar('Product saved successfully!');
      if (mounted) context.read<AppRefreshProvider>().invalidateAll();
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
              final isNarrow = ResponsiveBreakpoints.isMobileWidth(
                constraints.maxWidth,
              );
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
                              padding: const EdgeInsets.symmetric(
                                horizontal: 24,
                                vertical: 16,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
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
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 16,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
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
            decoration:
                AppTheme.inputDecoration(
                  label: 'Search products...',
                  hint: 'Search by title or category',
                ).copyWith(
                  prefixIcon: const Icon(
                    Icons.search,
                    color: AppTheme.textLight,
                  ),
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
                  separatorBuilder: (context, index) =>
                      const SizedBox(height: 16),
                  itemBuilder: (context, index) =>
                      _buildProductCard(_filteredProducts[index]),
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
          final isNarrow = ResponsiveBreakpoints.isMobileWidth(
            constraints.maxWidth,
          );

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
                        ? DecorationImage(
                            image: NetworkImage(product.imageUrls.first),
                            fit: BoxFit.cover,
                          )
                        : null,
                  ),
                  child: product.imageUrls.isEmpty
                      ? const Icon(Icons.image, color: AppTheme.greyPlaceholder)
                      : null,
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
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color:
                        (product.isActive ? AppTheme.successGreen : Colors.grey)
                            .withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    product.isActive ? 'Active' : 'Inactive',
                    style: TextStyle(
                      color: product.isActive
                          ? AppTheme.successGreen
                          : Colors.grey,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 4),

                if (!isNarrow) ...[
                  IconButton(
                    icon: const Icon(
                      Icons.edit_outlined,
                      color: AppTheme.primaryBrown,
                    ),
                    onPressed: () => _showForm(product),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline, color: Colors.red),
                    onPressed: () => _deleteProduct(product),
                  ),
                ] else ...[
                  PopupMenuButton<String>(
                    onSelected: (val) {
                      if (val == 'edit')
                        _showForm(product);
                      else if (val == 'delete')
                        _deleteProduct(product);
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(value: 'edit', child: Text('Edit')),
                      const PopupMenuItem(
                        value: 'delete',
                        child: Text(
                          'Delete',
                          style: TextStyle(color: Colors.red),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.inventory_2_outlined,
            size: 64,
            color: AppTheme.textLight,
          ),
          const SizedBox(height: 16),
          Text(
            _searchQuery.isEmpty ? 'No products yet.' : 'No matching products.',
            style: AppTheme.bodyLarge,
          ),
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
          LayoutBuilder(
            builder: (context, constraints) {
              final isMobile = ResponsiveBreakpoints.isMobileWidth(
                constraints.maxWidth,
              );

              if (isMobile) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextButton.icon(
                      onPressed: _showList,
                      icon: const Icon(Icons.arrow_back),
                      label: const Text('Back to List'),
                      style: TextButton.styleFrom(
                        foregroundColor: AppTheme.primaryBrown,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _editingProduct == null
                          ? 'Add Product'
                          : 'Edit: ${_editingProduct!.title}',
                      style: AppTheme.headingLarge,
                    ),
                    const SizedBox(height: 16),
                    SizedBox(width: double.infinity, child: _buildSaveButton()),
                  ],
                );
              }

              return Row(
                children: [
                  TextButton.icon(
                    onPressed: _showList,
                    icon: const Icon(Icons.arrow_back),
                    label: const Text('Back to List'),
                    style: TextButton.styleFrom(
                      foregroundColor: AppTheme.primaryBrown,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      _editingProduct == null
                          ? 'Add Product'
                          : 'Edit: ${_editingProduct!.title}',
                      style: AppTheme.headingLarge,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 16),
                  _buildSaveButton(),
                ],
              );
            },
          ),

          const SizedBox(height: 32),

          LayoutBuilder(
            builder: (context, constraints) {
              final isStacked = !ResponsiveBreakpoints.isDesktopWidth(
                constraints.maxWidth,
              );

              final leftSide = Column(
                children: [
                  _buildSection('Product Details', [
                    AdminFormField(
                      label: 'Title',
                      hint: 'Enter product title',
                      controller: _titleCtrl,
                    ),
                    const SizedBox(height: 16),
                    AdminFormField(
                      label: 'Description',
                      hint: 'Enter product description',
                      controller: _descCtrl,
                      maxLines: 4,
                    ),
                    const SizedBox(height: 16),
                    _buildCategoryDropdown(),
                    const SizedBox(height: 16),
                    LayoutBuilder(
                      builder: (context, inner) {
                        final isMobile = ResponsiveBreakpoints.isMobileWidth(
                          inner.maxWidth,
                        );
                        if (isMobile) {
                          return Column(
                            children: [
                              AdminFormField(
                                label: 'Display Order',
                                hint: 'Enter order',
                                controller: _orderCtrl,
                                keyboardType: TextInputType.number,
                              ),
                              const SizedBox(height: 16),
                              AdminToggleSwitch(
                                label: 'Is Active',
                                value: _isActive,
                                onChanged: (val) => setState(() => _isActive = val),
                              ),
                            ],
                          );
                        }
                        return Row(
                          children: [
                            Expanded(
                              child: AdminFormField(
                                label: 'Display Order',
                                hint: 'Enter order',
                                controller: _orderCtrl,
                                keyboardType: TextInputType.number,
                              ),
                            ),
                            const SizedBox(width: 24),
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.only(top: 8),
                                child: AdminToggleSwitch(
                                  label: 'Is Active',
                                  value: _isActive,
                                  onChanged: (val) =>
                                      setState(() => _isActive = val),
                                ),
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ]),
                  const SizedBox(height: 24),
                  _buildSection('Pricing & Inventory', [
                    Row(
                      children: [
                        Expanded(
                          child: AdminFormField(
                            label: 'MRP (₹)',
                            hint: 'Original price',
                            controller: _mrpCtrl,
                            keyboardType: TextInputType.number,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: AdminFormField(
                            label: 'Selling Price (₹)',
                            hint: 'Customer pays',
                            controller: _sellingPriceCtrl,
                            keyboardType: TextInputType.number,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: AdminFormField(
                            label: 'Stock Count',
                            hint: '99 for unlimited',
                            controller: _stockCountCtrl,
                            keyboardType: TextInputType.number,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: AdminFormField(
                            label: 'Weight (grams)',
                            hint: 'For shipping',
                            controller: _weightCtrl,
                            keyboardType: TextInputType.number,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: AdminFormField(
                            label: 'SKU',
                            hint: 'Auto-generated',
                            controller: _skuCtrl,
                            readOnly: true,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Status',
                                style: GoogleFonts.jost(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 12,
                                ),
                                decoration: BoxDecoration(
                                  color: AppTheme.background,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: AppTheme.divider),
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 8,
                                      height: 8,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: (int.tryParse(_stockCountCtrl.text) ?? 0) > 0
                                            ? AppTheme.successGreen
                                            : Colors.red,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      (int.tryParse(_stockCountCtrl.text) ?? 0) > 0
                                          ? 'IN STOCK'
                                          : 'OUT OF STOCK',
                                      style: GoogleFonts.jost(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: (int.tryParse(_stockCountCtrl.text) ?? 0) > 0
                                            ? AppTheme.successGreen
                                            : Colors.red,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ]),
                ],
              );

              final rightSide = Column(
                children: [
                  _buildSection('Product Images', [
                    ImageUploadWidget(
                      title: 'Upload Images',
                      multiple: true,
                      onImagesSelected: _onImagesSelected,
                    ),
                    if (_editingProduct != null &&
                        _newImageBytes.isEmpty &&
                        _currentImageUrls.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Current Images:',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 8),
                            SizedBox(
                              height: 100,
                              child: ListView.separated(
                                scrollDirection: Axis.horizontal,
                                itemCount: _currentImageUrls.length,
                                separatorBuilder: (context, index) =>
                                    const SizedBox(width: 8),
                                itemBuilder: (context, index) => Image.network(
                                  _currentImageUrls[index],
                                  width: 100,
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                  ]),
                  const SizedBox(height: 24),
                  _buildSection('Product Specs', [
                    AdminFormField(
                      label: 'Material / Clay Type',
                      hint: 'e.g. Ramgarh Red Clay',
                      controller: _materialCtrl,
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: AdminFormField(
                            label: 'Height (cm)',
                            hint: '0',
                            controller: _hCtrl,
                            keyboardType: TextInputType.number,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: AdminFormField(
                            label: 'Width (cm)',
                            hint: '0',
                            controller: _wCtrl,
                            keyboardType: TextInputType.number,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: AdminFormField(
                            label: 'Depth (cm)',
                            hint: '0',
                            controller: _dCtrl,
                            keyboardType: TextInputType.number,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    _buildDynamicList(
                      title: 'Care Instructions',
                      hint: 'Add instruction...',
                      controller: _careInputCtrl,
                      items: _careInstructions,
                      maxItems: 6,
                      onAdd: (val) {
                        setState(() => _careInstructions.add(val));
                        _careInputCtrl.clear();
                      },
                      onRemove: (idx) => setState(() => _careInstructions.removeAt(idx)),
                    ),
                    const SizedBox(height: 24),
                    _buildDynamicList(
                      title: 'Tags',
                      hint: 'Add tag...',
                      controller: _tagInputCtrl,
                      items: _tags,
                      maxItems: 10,
                      onAdd: (val) {
                        setState(() => _tags.add(val));
                        _tagInputCtrl.clear();
                      },
                      onRemove: (idx) => setState(() => _tags.removeAt(idx)),
                    ),
                  ]),
                ],
              );

              if (isStacked) {
                return Column(
                  children: [leftSide, const SizedBox(height: 24), rightSide],
                );
              }

              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(flex: 3, child: leftSide),
                  const SizedBox(width: 24),
                  Expanded(flex: 2, child: rightSide),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildDynamicList({
    required String title,
    required String hint,
    required TextEditingController controller,
    required List<String> items,
    required int maxItems,
    required Function(String) onAdd,
    required Function(int) onRemove,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: GoogleFonts.jost(
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: items.asMap().entries.map((entry) {
            return Chip(
              label: Text(entry.value, style: const TextStyle(fontSize: 12)),
              onDeleted: () => onRemove(entry.key),
              deleteIcon: const Icon(Icons.close, size: 14),
              backgroundColor: AppTheme.background,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
                side: const BorderSide(color: AppTheme.divider),
              ),
            );
          }).toList(),
        ),
        if (items.length < maxItems) ...[
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: controller,
                  onSubmitted: (val) {
                    if (val.trim().isNotEmpty) onAdd(val.trim());
                  },
                  decoration: AppTheme.inputDecoration(
                    label: '',
                    hint: hint,
                  ).copyWith(contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8)),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                onPressed: () {
                  if (controller.text.trim().isNotEmpty) onAdd(controller.text.trim());
                },
                icon: const Icon(Icons.add_circle, color: AppTheme.primaryBrown),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildSaveButton() {
    return ElevatedButton(
      onPressed: _isSaving ? null : _save,
      style: ElevatedButton.styleFrom(
        backgroundColor: AppTheme.primaryBrown,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      child: _isSaving
          ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                color: Colors.white,
                strokeWidth: 2,
              ),
            )
          : const Text('Save Product'),
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
          decoration: AppTheme.inputDecoration(
            label: 'Category',
            hint: 'Select category',
          ),
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
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : AppTheme.successGreen,
      ),
    );
  }
}
