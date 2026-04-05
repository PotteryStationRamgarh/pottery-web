import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/providers/app_refresh_provider.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/responsive_utils.dart';
import '../../../../models/product.dart';
import '../repositories/exclusive_product_repository.dart';
import '../widgets/admin_form_field.dart';
import '../widgets/admin_toggle_switch.dart';
import '../widgets/image_upload_widget.dart';

class AdminExclusiveListPage extends StatefulWidget {
  const AdminExclusiveListPage({super.key});

  @override
  State<AdminExclusiveListPage> createState() => _AdminExclusiveListPageState();
}

class _AdminExclusiveListPageState extends State<AdminExclusiveListPage> {
  String _mode = 'list'; // 'list' or 'form'
  bool _isLoading = true;
  bool _isSaving = false;

  List<ExclusiveProduct> _allExclusives = [];
  List<ExclusiveProduct> _filteredExclusives = [];
  String _searchQuery = '';

  // Form State
  ExclusiveProduct? _editingExclusive;
  late TextEditingController _titleCtrl;
  late TextEditingController _descCtrl;
  late TextEditingController _piecesCtrl;
  late TextEditingController _orderCtrl;
  late TextEditingController _searchCtrl;
  late TextEditingController _materialCtrl;
  late TextEditingController _craftingTimeCtrl;
  bool _isActive = true;
  bool _hasCertificate = true;
  List<Uint8List> _newImageBytes = [];
  List<String> _currentImageUrls = [];

  @override
  void initState() {
    super.initState();
    _titleCtrl = TextEditingController();
    _descCtrl = TextEditingController();
    _piecesCtrl = TextEditingController();
    _orderCtrl = TextEditingController();
    _searchCtrl = TextEditingController();
    _materialCtrl = TextEditingController();
    _craftingTimeCtrl = TextEditingController();
    _loadExclusives();
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    _piecesCtrl.dispose();
    _orderCtrl.dispose();
    _searchCtrl.dispose();
    _materialCtrl.dispose();
    _craftingTimeCtrl.dispose();
    super.dispose();
  }

  // ── LOAD ──────────────────────────────────────────────────────────────────

  Future<void> _loadExclusives() async {
    setState(() => _isLoading = true);
    try {
      final list = await ExclusiveProductRepository.getExclusiveProducts(
        forceRefresh: true,
      );
      _allExclusives = list;
      _applyFilter();
    } catch (e) {
      _showSnackbar('Error loading exclusives: $e', isError: true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _applyFilter() {
    setState(() {
      if (_searchQuery.isEmpty) {
        _filteredExclusives = List.from(_allExclusives);
      } else {
        _filteredExclusives = _allExclusives.where((e) {
          return e.title.toLowerCase().contains(_searchQuery.toLowerCase());
        }).toList();
      }
    });
  }

  // ── DELETE ────────────────────────────────────────────────────────────────

  Future<void> _deleteExclusive(ExclusiveProduct product) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Exclusive Piece?'),
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
        await ExclusiveProductRepository.deleteExclusiveProduct(product.id);
        if (mounted) context.read<AppRefreshProvider>().invalidateAll();
        _showSnackbar('Exclusive piece deleted');
        _loadExclusives();
      } catch (e) {
        _showSnackbar('Delete failed: $e', isError: true);
      }
    }
  }

  // ── MODE SWITCH ───────────────────────────────────────────────────────────

  void _showForm([ExclusiveProduct? product]) {
    _editingExclusive = product;
    if (product != null) {
      _titleCtrl.text = product.title;
      _descCtrl.text = product.description;
      _piecesCtrl.text = product.totalPieces.toString();
      _orderCtrl.text = product.order.toString();
      _materialCtrl.text = product.material;
      _craftingTimeCtrl.text = product.craftingTime;
      _isActive = product.isActive;
      _hasCertificate = product.hasCertificate;
      _currentImageUrls = List.from(product.imageUrls);
    } else {
      _titleCtrl.clear();
      _descCtrl.clear();
      _piecesCtrl.clear();
      _orderCtrl.clear();
      _materialCtrl.clear();
      _craftingTimeCtrl.clear();
      _isActive = true;
      _hasCertificate = true;
      _currentImageUrls = [];
    }
    _newImageBytes = []; // Correctly re-initialize to empty list
    setState(() => _mode = 'form');
  }

  void _showList() {
    setState(() => _mode = 'list');
    _loadExclusives();
  }

  // ── SAVE ──────────────────────────────────────────────────────────────────

  Future<void> _save() async {
    if (_titleCtrl.text.trim().isEmpty) {
      _showSnackbar('Title is required', isError: true);
      return;
    }

    setState(() => _isSaving = true);
    try {
      if (_editingExclusive == null) {
        // Add
        if (_newImageBytes.isEmpty) throw 'At least one image is required';
        await ExclusiveProductRepository.addExclusiveProduct(
          title: _titleCtrl.text.trim(),
          description: _descCtrl.text.trim(),
          imageBytes: _newImageBytes,
          totalPieces: int.tryParse(_piecesCtrl.text) ?? 1,
          hasCertificate: _hasCertificate,
          material: _materialCtrl.text.trim(),
          craftingTime: _craftingTimeCtrl.text.trim(),
          order: int.tryParse(_orderCtrl.text) ?? 0,
          isActive: _isActive,
        );
      } else {
        // Update
        if (_newImageBytes.isNotEmpty) {
          await ExclusiveProductRepository.updateExclusiveProductWithImages(
            id: _editingExclusive!.id,
            title: _titleCtrl.text.trim(),
            description: _descCtrl.text.trim(),
            imageBytes: _newImageBytes,
            totalPieces: int.tryParse(_piecesCtrl.text) ?? 1,
            hasCertificate: _hasCertificate,
            material: _materialCtrl.text.trim(),
            craftingTime: _craftingTimeCtrl.text.trim(),
            order: int.tryParse(_orderCtrl.text) ?? 0,
            isActive: _isActive,
          );
        } else {
          await ExclusiveProductRepository.updateExclusiveProduct(
            id: _editingExclusive!.id,
            title: _titleCtrl.text.trim(),
            description: _descCtrl.text.trim(),
            totalPieces: int.tryParse(_piecesCtrl.text) ?? 1,
            hasCertificate: _hasCertificate,
            material: _materialCtrl.text.trim(),
            craftingTime: _craftingTimeCtrl.text.trim(),
            order: int.tryParse(_orderCtrl.text) ?? 0,
            isActive: _isActive,
          );
        }
      }

      _showSnackbar('Exclusive piece saved successfully!');
      if (mounted) context.read<AppRefreshProvider>().invalidateAll();
      _showList();
    } catch (e) {
      _showSnackbar('Failed to save exclusive piece: $e', isError: true);
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

  Widget _buildAddButton() {
    return ElevatedButton.icon(
      onPressed: () => _showForm(),
      icon: const Icon(Icons.add),
      label: const Text('Add Exclusive'),
      style: ElevatedButton.styleFrom(
        backgroundColor: AppTheme.primaryBrown,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
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
            builder: (context, headerConstraints) {
              final isNarrowHeader = ResponsiveBreakpoints.isMobileWidth(
                headerConstraints.maxWidth,
              );
              return isNarrowHeader
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Exclusive Collection',
                          style: AppTheme.headingLarge,
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          child: _buildAddButton(),
                        ),
                      ],
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            'Exclusive Collection',
                            style: AppTheme.headingLarge,
                          ),
                        ),
                        _buildAddButton(),
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
                  label: 'Search exclusives...',
                  hint: 'Search by title',
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
              : _filteredExclusives.isEmpty
              ? _buildEmptyState()
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(32, 0, 32, 32),
                  itemCount: _filteredExclusives.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(height: 16),
                  itemBuilder: (context, index) =>
                      _buildExclusiveCard(_filteredExclusives[index]),
                ),
        ),
      ],
    );
  }

  Widget _buildExclusiveCard(ExclusiveProduct product) {
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
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              '${product.totalPieces} pieces • Order: ${product.order}',
                              style: AppTheme.bodySmall,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (product.hasCertificate && !isNarrow)
                            Padding(
                              padding: const EdgeInsets.only(left: 8.0),
                              child: Icon(
                                Icons.verified_outlined,
                                size: 14,
                                color: AppTheme.primaryBrown.withOpacity(0.7),
                              ),
                            ),
                        ],
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
                    onPressed: () => _deleteExclusive(product),
                  ),
                ] else ...[
                  PopupMenuButton<String>(
                    onSelected: (val) {
                      if (val == 'edit')
                        _showForm(product);
                      else if (val == 'delete')
                        _deleteExclusive(product);
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
            Icons.star_border_outlined,
            size: 64,
            color: AppTheme.textLight,
          ),
          const SizedBox(height: 16),
          Text(
            _searchQuery.isEmpty
                ? 'No exclusive pieces yet.'
                : 'No matching exclusive pieces.',
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
              final isNarrow = ResponsiveBreakpoints.isMobileWidth(
                constraints.maxWidth,
              );
              if (isNarrow) {
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
                      _editingExclusive == null
                          ? 'Add Exclusive Piece'
                          : 'Edit: ${_editingExclusive!.title}',
                      style: AppTheme.headingLarge,
                    ),
                    const SizedBox(height: 16),
                    SizedBox(width: double.infinity, child: _buildSaveButton()),
                  ],
                );
              }
              return Wrap(
                spacing: 16,
                runSpacing: 16,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  TextButton.icon(
                    onPressed: _showList,
                    icon: const Icon(Icons.arrow_back),
                    label: const Text('Back to List'),
                    style: TextButton.styleFrom(
                      foregroundColor: AppTheme.primaryBrown,
                    ),
                  ),
                  Text(
                    _editingExclusive == null
                        ? 'Add Exclusive Piece'
                        : 'Edit: ${_editingExclusive!.title}',
                    style: AppTheme.headingLarge,
                    overflow: TextOverflow.ellipsis,
                  ),
                  ElevatedButton(
                    onPressed: _isSaving ? null : _save,
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
                    child: _isSaving
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Text('Save Exclusive'),
                  ),
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

              final details = _buildSection('Basic Details', [
                AdminFormField(
                  label: 'Title',
                  hint: 'Enter piece title',
                  controller: _titleCtrl,
                ),
                const SizedBox(height: 16),
                AdminFormField(
                  label: 'Description & Story',
                  hint: 'Enter description',
                  controller: _descCtrl,
                  maxLines: 4,
                ),
                const SizedBox(height: 16),
                LayoutBuilder(
                  builder: (context, c) {
                    final isNarrow = ResponsiveBreakpoints.isMobileWidth(
                      c.maxWidth,
                    );
                    return isNarrow
                        ? Column(
                            children: [
                              AdminFormField(
                                label: 'Total Pieces Made',
                                hint: 'Enter number',
                                controller: _piecesCtrl,
                                keyboardType: TextInputType.number,
                              ),
                              const SizedBox(height: 16),
                              AdminFormField(
                                label: 'Display Order',
                                hint: 'Enter order',
                                controller: _orderCtrl,
                                keyboardType: TextInputType.number,
                              ),
                            ],
                          )
                        : Row(
                            children: [
                              Expanded(
                                child: AdminFormField(
                                  label: 'Total Pieces Made',
                                  hint: 'Enter number',
                                  controller: _piecesCtrl,
                                  keyboardType: TextInputType.number,
                                ),
                              ),
                              const SizedBox(width: 24),
                              Expanded(
                                child: AdminFormField(
                                  label: 'Display Order',
                                  hint: 'Enter order',
                                  controller: _orderCtrl,
                                  keyboardType: TextInputType.number,
                                ),
                              ),
                            ],
                          );
                  },
                ),
                const SizedBox(height: 16),
                LayoutBuilder(
                  builder: (context, c) {
                    final isNarrow = ResponsiveBreakpoints.isMobileWidth(
                      c.maxWidth,
                    );
                    return isNarrow
                        ? Column(
                            children: [
                              AdminFormField(
                                label: 'Material',
                                hint: 'e.g. Stoneware',
                                controller: _materialCtrl,
                              ),
                              const SizedBox(height: 16),
                              AdminFormField(
                                label: 'Crafting Time',
                                hint: 'e.g. 4-6 Weeks',
                                controller: _craftingTimeCtrl,
                              ),
                            ],
                          )
                        : Row(
                            children: [
                              Expanded(
                                child: AdminFormField(
                                  label: 'Material',
                                  hint: 'e.g. Stoneware',
                                  controller: _materialCtrl,
                                ),
                              ),
                              const SizedBox(width: 24),
                              Expanded(
                                child: AdminFormField(
                                  label: 'Crafting Time',
                                  hint: 'e.g. 4-6 Weeks',
                                  controller: _craftingTimeCtrl,
                                ),
                              ),
                            ],
                          );
                  },
                ),
                const SizedBox(height: 24),
                LayoutBuilder(
                  builder: (context, c) {
                    final isNarrow = ResponsiveBreakpoints.isMobileWidth(
                      c.maxWidth,
                    );
                    return isNarrow
                        ? Column(
                            children: [
                              AdminToggleSwitch(
                                label: 'Authenticity Cert',
                                value: _hasCertificate,
                                onChanged: (val) =>
                                    setState(() => _hasCertificate = val),
                              ),
                              const SizedBox(height: 16),
                              AdminToggleSwitch(
                                label: 'Is Active',
                                value: _isActive,
                                onChanged: (val) =>
                                    setState(() => _isActive = val),
                              ),
                            ],
                          )
                        : Row(
                            children: [
                              Expanded(
                                child: AdminToggleSwitch(
                                  label: 'Authenticity Cert',
                                  value: _hasCertificate,
                                  onChanged: (val) =>
                                      setState(() => _hasCertificate = val),
                                ),
                              ),
                              const SizedBox(width: 24),
                              Expanded(
                                child: AdminToggleSwitch(
                                  label: 'Is Active',
                                  value: _isActive,
                                  onChanged: (val) =>
                                      setState(() => _isActive = val),
                                ),
                              ),
                            ],
                          );
                  },
                ),
              ]);
              final images = _buildSection('Masterpiece Images', [
                ImageUploadWidget(
                  title: 'Upload Images',
                  multiple: true,
                  onImagesSelected: _onImagesSelected,
                ),
                if (_editingExclusive != null &&
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
              ]);

              if (isStacked) {
                return Column(
                  children: [details, const SizedBox(height: 24), images],
                );
              }

              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(flex: 3, child: details),
                  const SizedBox(width: 24),
                  Expanded(flex: 2, child: images),
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
          : const Text('Save Exclusive'),
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
