import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/providers/app_refresh_provider.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/responsive_utils.dart';
import '../../../../models/product_category.dart';
import '../repositories/category_repository.dart';
import '../widgets/admin_form_field.dart';
import '../widgets/admin_toggle_switch.dart';
import '../widgets/image_upload_widget.dart';

class AdminCategoriesListPage extends StatefulWidget {
  const AdminCategoriesListPage({super.key});

  @override
  State<AdminCategoriesListPage> createState() =>
      _AdminCategoriesListPageState();
}

class _AdminCategoriesListPageState extends State<AdminCategoriesListPage> {
  String _mode = 'list'; // 'list' or 'form'
  bool _isLoading = true;
  bool _isSaving = false;

  List<ProductCategory> _allCategories = [];
  List<ProductCategory> _filteredCategories = [];
  String _searchQuery = '';

  // Form State
  ProductCategory? _editingCategory;
  late TextEditingController _nameCtrl;
  late TextEditingController _descCtrl;
  late TextEditingController _inPlaceTextCtrl;
  late TextEditingController _orderCtrl;
  late TextEditingController _searchCtrl;
  bool _isActive = true;
  Uint8List? _newImageBytes;
  String? _currentImageUrl;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController();
    _descCtrl = TextEditingController();
    _inPlaceTextCtrl = TextEditingController();
    _orderCtrl = TextEditingController();
    _searchCtrl = TextEditingController();
    _loadCategories();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    _inPlaceTextCtrl.dispose();
    _orderCtrl.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  // ── LOAD ──────────────────────────────────────────────────────────────────

  Future<void> _loadCategories() async {
    setState(() => _isLoading = true);
    try {
      final list = await CategoryRepository.getCategories(forceRefresh: true);
      _allCategories = list;
      _applyFilter();
    } catch (e) {
      _showSnackbar('Error loading categories: $e', isError: true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _applyFilter() {
    setState(() {
      if (_searchQuery.isEmpty) {
        _filteredCategories = List.from(_allCategories);
      } else {
        _filteredCategories = _allCategories.where((c) {
          return c.name.toLowerCase().contains(_searchQuery.toLowerCase());
        }).toList();
      }
    });
  }

  // ── DELETE ────────────────────────────────────────────────────────────────

  Future<void> _deleteCategory(ProductCategory category) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Category?'),
        content: Text('Delete "${category.name}"? This cannot be undone.'),
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
        await CategoryRepository.deleteCategory(category.id);
        if (mounted) {
          context.read<AppRefreshProvider>().invalidateAll();
        }
        _showSnackbar('Category deleted');
        _loadCategories();
      } catch (e) {
        _showSnackbar('Delete failed: $e', isError: true);
      }
    }
  }

  // ── MODE SWITCH ───────────────────────────────────────────────────────────

  void _showForm([ProductCategory? category]) {
    _editingCategory = category;
    if (category != null) {
      _nameCtrl.text = category.name;
      _descCtrl.text = category.description;
      _inPlaceTextCtrl.text = category.inPlaceText;
      _orderCtrl.text = category.order.toString();
      _isActive = category.isActive;
      _currentImageUrl = category.imageUrl;
    } else {
      _nameCtrl.clear();
      _descCtrl.clear();
      _inPlaceTextCtrl.clear();
      _orderCtrl.clear();
      _isActive = true;
      _currentImageUrl = null;
    }
    _newImageBytes = null;
    setState(() => _mode = 'form');
  }

  void _showList() {
    setState(() => _mode = 'list');
    _loadCategories();
  }

  // ── SAVE ──────────────────────────────────────────────────────────────────

  Future<void> _save() async {
    if (_nameCtrl.text.trim().isEmpty) {
      _showSnackbar('Name is required', isError: true);
      return;
    }

    setState(() => _isSaving = true);
    try {
      if (_editingCategory == null) {
        // Add
        if (_newImageBytes == null) {
          throw 'Image is required for new categories';
        }
        await CategoryRepository.addCategory(
          name: _nameCtrl.text.trim(),
          description: _descCtrl.text.trim(),
          inPlaceText: _inPlaceTextCtrl.text.trim(),
          imageBytes: _newImageBytes!,
          order: int.tryParse(_orderCtrl.text) ?? 0,
          isActive: _isActive,
        );
      } else {
        // Update
        if (_newImageBytes != null) {
          await CategoryRepository.updateCategoryWithImage(
            id: _editingCategory!.id,
            name: _nameCtrl.text.trim(),
            description: _descCtrl.text.trim(),
            inPlaceText: _inPlaceTextCtrl.text.trim(),
            imageBytes: _newImageBytes!,
            order: int.tryParse(_orderCtrl.text) ?? 0,
            isActive: _isActive,
          );
        } else {
          await CategoryRepository.updateCategory(
            id: _editingCategory!.id,
            name: _nameCtrl.text.trim(),
            description: _descCtrl.text.trim(),
            inPlaceText: _inPlaceTextCtrl.text.trim(),
            order: int.tryParse(_orderCtrl.text) ?? 0,
            isActive: _isActive,
          );
        }
      }

      _showSnackbar('Category saved successfully!');
      if (mounted) {
        context.read<AppRefreshProvider>().invalidateAll();
      }
      _showList();
    } catch (e) {
      _showSnackbar('Failed to save category: $e', isError: true);
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _onImageSelected(List<Uint8List> images) {
    setState(() {
      _newImageBytes = images.isNotEmpty ? images.first : null;
    });
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
              final isMobile = constraints.maxWidth < 600;
              final button = ElevatedButton.icon(
                onPressed: () => _showForm(),
                icon: const Icon(Icons.add),
                label: const Text('Add Category'),
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
              );
              if (isMobile) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Product Categories', style: AppTheme.headingLarge),
                    const SizedBox(height: 16),
                    SizedBox(width: double.infinity, child: button),
                  ],
                );
              }
              return Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Product Categories', style: AppTheme.headingLarge),
                  button,
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
                  label: 'Search categories...',
                  hint: 'Search by name',
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
              : _filteredCategories.isEmpty
              ? _buildEmptyState()
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(32, 0, 32, 32),
                  itemCount: _filteredCategories.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(height: 16),
                  itemBuilder: (context, index) =>
                      _buildCategoryCard(_filteredCategories[index]),
                ),
        ),
      ],
    );
  }

  Widget _buildCategoryCard(ProductCategory category) {
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
                    image: category.imageUrl.isNotEmpty
                        ? DecorationImage(
                            image: NetworkImage(category.imageUrl),
                            fit: BoxFit.cover,
                          )
                        : null,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        category.name,
                        style: AppTheme.headingMedium.copyWith(fontSize: 16),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        'Order: ${category.order}',
                        style: AppTheme.bodySmall,
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
                        (category.isActive
                                ? AppTheme.successGreen
                                : Colors.grey)
                            .withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    category.isActive ? 'Active' : 'Inactive',
                    style: TextStyle(
                      color: category.isActive
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
                    onPressed: () => _showForm(category),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline, color: Colors.red),
                    onPressed: () => _deleteCategory(category),
                  ),
                ] else ...[
                  PopupMenuButton<String>(
                    onSelected: (val) {
                      if (val == 'edit') {
                        _showForm(category);
                      } else if (val == 'delete') {
                        _deleteCategory(category);
                      }
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
            Icons.category_outlined,
            size: 64,
            color: AppTheme.textLight,
          ),
          const SizedBox(height: 16),
          Text(
            _searchQuery.isEmpty
                ? 'No categories yet.'
                : 'No matching categories.',
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
                      _editingCategory == null
                          ? 'Add Category'
                          : 'Edit: ${_editingCategory!.name}',
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
                      _editingCategory == null
                          ? 'Add Category'
                          : 'Edit: ${_editingCategory!.name}',
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

              final details = _buildSection('Category Details', [
                AdminFormField(
                  label: 'Name',
                  hint: 'Enter category name',
                  controller: _nameCtrl,
                ),
                const SizedBox(height: 16),
                AdminFormField(
                  label: 'Description',
                  hint: 'Brief summary of this category',
                  controller: _descCtrl,
                  maxLines: 3,
                ),
                const SizedBox(height: 16),
                AdminFormField(
                  label: 'In Place Text',
                  hint:
                      'Short lifestyle copy for product detail pages in this category',
                  controller: _inPlaceTextCtrl,
                  maxLines: 3,
                ),
                const SizedBox(height: 16),
                AdminFormField(
                  label: 'Display Order',
                  hint: 'Enter order',
                  controller: _orderCtrl,
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 24),
                AdminToggleSwitch(
                  label: 'Is Active',
                  value: _isActive,
                  onChanged: (val) => setState(() => _isActive = val),
                ),
              ]);

              final image = _buildSection('Category Image', [
                ImageUploadWidget(
                  title: 'Cover Image',
                  multiple: false,
                  onImagesSelected: _onImageSelected,
                  minHeight: 240,
                ),
                if (_editingCategory != null &&
                    _newImageBytes == null &&
                    _currentImageUrl != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Current Image:',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        Image.network(_currentImageUrl!, height: 100),
                      ],
                    ),
                  ),
              ]);

              if (isStacked) {
                return Column(
                  children: [details, const SizedBox(height: 24), image],
                );
              }

              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(flex: 3, child: details),
                  const SizedBox(width: 24),
                  Expanded(flex: 2, child: image),
                ],
              );
            },
          ),
        ],
      ),
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
          : const Text('Save Category'),
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
