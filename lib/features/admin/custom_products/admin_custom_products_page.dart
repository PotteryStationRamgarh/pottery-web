import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/repositories/custom_order_repository.dart';
import '../../../core/repositories/custom_products_config_repository.dart';
import '../../../core/theme/app_theme.dart';
import '../../../features/admin/catalog/widgets/admin_form_field.dart';
import '../../../features/admin/catalog/widgets/admin_toggle_switch.dart';
import '../../../features/admin/catalog/widgets/image_upload_widget.dart';
import '../../../models/custom_order_model.dart';
import '../../../models/custom_products_config.dart';
import 'widgets/custom_products_widgets.dart';

class AdminCustomProductsPage extends StatefulWidget {
  final int initialIndex;
  const AdminCustomProductsPage({super.key, this.initialIndex = 0});

  @override
  State<AdminCustomProductsPage> createState() =>
      _AdminCustomProductsPageState();
}

class _AdminCustomProductsPageState extends State<AdminCustomProductsPage> {
  // _isLoading removed as it was unused
  bool _isSavingConfig = false;
  bool _isSavingOrder = false;
  late CustomProductsConfig _config;
  List<CustomOrderModel> _orders = [];
  CustomOrderModel? _selectedOrder;

  late final TextEditingController _heroTitleCtrl;
  late final TextEditingController _heroSubtitleCtrl;
  late final TextEditingController _introTextCtrl;
  late final TextEditingController _typeInputCtrl;
  late final TextEditingController _glazeInputCtrl;
  late final TextEditingController _priceCtrl;
  late final TextEditingController _notesCtrl;

  Uint8List? _heroImageBytes;
  List<String> _productTypes = [];
  List<String> _glazeOptions = [];
  bool _isEnabled = true;
  String _status = 'submitted';
  DateTime? _proposedDate;

  @override
  void initState() {
    super.initState();
    _heroTitleCtrl = TextEditingController();
    _heroSubtitleCtrl = TextEditingController();
    _introTextCtrl = TextEditingController();
    _typeInputCtrl = TextEditingController();
    _glazeInputCtrl = TextEditingController();
    _priceCtrl = TextEditingController();
    _notesCtrl = TextEditingController();
    _load();
  }

  @override
  void dispose() {
    _heroTitleCtrl.dispose();
    _heroSubtitleCtrl.dispose();
    _introTextCtrl.dispose();
    _typeInputCtrl.dispose();
    _glazeInputCtrl.dispose();
    _priceCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    // _isLoading = true; (Removed)
    final results = await Future.wait([
      CustomOrderRepository.getCustomOrders(),
      CustomProductsConfigRepository.getConfig(),
    ]);

    _orders = results[0] as List<CustomOrderModel>;
    _config = results[1] as CustomProductsConfig;
    _syncConfigFields();

    if (_orders.isNotEmpty) {
      _selectOrder(
        _orders.firstWhere(
          (order) => order.id == _selectedOrder?.id,
          orElse: () => _orders.first,
        ),
      );
    } else {
      _selectedOrder = null;
    }

    // _isLoading = false; (Removed)
  }

  void _syncConfigFields() {
    _heroTitleCtrl.text = _config.heroTitle;
    _heroSubtitleCtrl.text = _config.heroSubtitle;
    _introTextCtrl.text = _config.introText;
    _productTypes = List<String>.from(_config.productTypes);
    _glazeOptions = List<String>.from(_config.glazeOptions);
    _isEnabled = _config.isEnabled;
    _heroImageBytes = null;
  }

  void _selectOrder(CustomOrderModel order) {
    _selectedOrder = order;
    _status = order.status;
    _priceCtrl.text = order.quotedPrice > 0
        ? order.quotedPrice.toStringAsFixed(0)
        : '';
    _notesCtrl.text = order.adminNotes;
    _proposedDate = order.proposedCreationDate;
    if (mounted) setState(() {});
  }

  Future<void> _saveConfig() async {
    if (_productTypes.isEmpty || _glazeOptions.isEmpty) {
      _showError('Add at least one product type and one glaze option.');
      return;
    }

    setState(() => _isSavingConfig = true);
    try {
      final nextConfig = CustomProductsConfig(
        heroImageUrl: _config.heroImageUrl,
        heroTitle: _heroTitleCtrl.text.trim(),
        heroSubtitle: _heroSubtitleCtrl.text.trim(),
        glazeOptions: _glazeOptions,
        productTypes: _productTypes,
        introText: _introTextCtrl.text.trim(),
        isEnabled: _isEnabled,
      );

      await CustomProductsConfigRepository.saveConfig(
        nextConfig,
        heroImageBytes: _heroImageBytes,
        previousHeroImageUrl: _config.heroImageUrl,
      );

      _showMessage('Custom product settings saved');
      await _load();
    } catch (e) {
      _showError('Failed to save custom product settings: $e');
    } finally {
      if (mounted) setState(() => _isSavingConfig = false);
    }
  }

  Future<void> _saveOrderReview() async {
    final order = _selectedOrder;
    if (order == null) return;

    setState(() => _isSavingOrder = true);
    try {
      await CustomOrderRepository.reviewCustomOrder(
        CustomOrderModel(
          id: order.id,
          userId: order.userId,
          name: order.name,
          email: order.email,
          phone: order.phone,
          productType: order.productType,
          size: order.size,
          glazePreference: order.glazePreference,
          glazeFinish: order.glazeFinish,
          quantity: order.quantity,
          specialNotes: order.specialNotes,
          inspirationImageUrl: order.inspirationImageUrl,
          status: _status,
          quotedPrice:
              double.tryParse(_priceCtrl.text.trim()) ?? order.quotedPrice,
          adminNotes: _notesCtrl.text.trim(),
          proposedCreationDate: _proposedDate,
          razorpayOrderId: order.razorpayOrderId,
          razorpayPaymentId: order.razorpayPaymentId,
          paymentStatus: order.paymentStatus,
          cleanupAfter: _status == 'rejected'
              ? DateTime.now().add(const Duration(days: 30))
              : null,
          createdAt: order.createdAt,
          updatedAt: DateTime.now(),
          statusHistory: order.statusHistory,
        ),
        note: _notesCtrl.text.trim().isEmpty
            ? 'Status changed to ${CustomOrderModel.normalizeStatus(_status).replaceAll('_', ' ')}'
            : _notesCtrl.text.trim(),
      );

      _showMessage('Custom order review saved');
      await _load();
    } catch (e) {
      _showError('Failed to save order review: $e');
    } finally {
      if (mounted) setState(() => _isSavingOrder = false);
    }
  }

  Future<void> _pickCreationDate() async {
    final selected = await showDatePicker(
      context: context,
      initialDate:
          _proposedDate ?? DateTime.now().add(const Duration(days: 14)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (selected != null) {
      setState(() => _proposedDate = selected);
    }
  }

  void _addItem(TextEditingController controller, List<String> target) {
    final value = controller.text.trim();
    if (value.isEmpty || target.contains(value)) return;
    setState(() {
      target.add(value);
      controller.clear();
    });
  }

  void _removeItem(String value, List<String> target) {
    setState(() => target.remove(value));
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(behavior: SnackBarBehavior.floating, content: Text(message)),
    );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppTheme.errorRed,
        content: Text(message),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      initialIndex: widget.initialIndex,
      length: 2,
      child: Scaffold(
        backgroundColor: AppTheme.background,
        appBar: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: Container(
            color: Colors.white,
            child: TabBar(
              labelColor: AppTheme.terracotta,
              unselectedLabelColor: AppTheme.textLight,
              indicatorColor: AppTheme.terracotta,
              tabs: [
                Tab(
                  child: Text(
                    'ORDERS',
                    style: GoogleFonts.jost(
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1,
                    ),
                  ),
                ),
                Tab(
                  child: Text(
                    'CONFIG',
                    style: GoogleFonts.jost(
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        body: TabBarView(children: [_buildOrdersTab(), _buildConfigTab()]),
      ),
    );
  }

  Widget _buildOrdersTab() {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth >= 1000;
            return isWide
                ? Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(flex: 5, child: _buildOrdersPanel()),
                      const SizedBox(width: 24),
                      Expanded(flex: 7, child: _buildReviewPanel()),
                    ],
                  )
                : Column(
                    children: [
                      _buildOrdersPanel(),
                      const SizedBox(height: 24),
                      _buildReviewPanel(),
                    ],
                  );
          },
        ),
      ],
    );
  }

  Widget _buildConfigTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          CustomProductsSummaryCard(
            isEnabled: _isEnabled,
            pendingCount: _orders
                .where((order) => order.status == 'submitted')
                .length,
            isSaving: _isSavingConfig,
            onSave: _saveConfig,
          ),
          const SizedBox(height: 24),
          _buildConfigPanel(),
        ],
      ),
    );
  }

  Widget _buildReviewPanel() {
    if (_selectedOrder == null) {
      return CustomProductsPanel(
        title: 'Review Request',
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 60),
            child: Text(
              'Select an order to review',
              style: AppTheme.bodyLarge.copyWith(color: AppTheme.textLight),
            ),
          ),
        ),
      );
    }
    return CustomProductsPanel(
      title: 'Review Request',
      child: CustomOrderReviewForm(
        order: _selectedOrder!,
        status: _status,
        notesController: _notesCtrl,
        priceController: _priceCtrl,
        proposedDate: _proposedDate,
        isSaving: _isSavingOrder,
        onStatusChanged: (value) => setState(() => _status = value),
        onPickDate: _pickCreationDate,
        onSave: _saveOrderReview,
      ),
    );
  }

  Widget _buildConfigPanel() {
    return CustomProductsPanel(
      title: 'Custom Product Settings',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Hero Image',
            style: AppTheme.bodyLarge.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),
          if (_heroImageBytes == null && _config.heroImageUrl.isEmpty)
            ImageUploadWidget(
              title: 'Hero Image',
              multiple: false,
              minHeight: 220,
              onImagesSelected: (images) {
                setState(
                  () => _heroImageBytes = images.isEmpty ? null : images.first,
                );
              },
            )
          else
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: _heroImageBytes != null
                      ? Image.memory(
                          _heroImageBytes!,
                          height: 240,
                          width: double.infinity,
                          fit: BoxFit.cover,
                        )
                      : Image.network(
                          _config.heroImageUrl,
                          height: 240,
                          width: double.infinity,
                          fit: BoxFit.cover,
                        ),
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: () {
                    setState(() {
                      _heroImageBytes = null;
                      _config = _config.copyWith(heroImageUrl: '');
                    });
                  },
                  icon: const Icon(Icons.refresh),
                  label: const Text('Replace Image'),
                ),
              ],
            ),
          const SizedBox(height: 24),
          AdminFormField(
            label: 'Hero Title',
            hint: 'Enter hero title',
            controller: _heroTitleCtrl,
          ),
          const SizedBox(height: 16),
          AdminFormField(
            label: 'Hero Subtitle',
            hint: 'Enter hero subtitle',
            controller: _heroSubtitleCtrl,
          ),
          const SizedBox(height: 16),
          AdminFormField(
            label: 'Intro Text',
            hint: 'Write a short introduction for the custom order page',
            controller: _introTextCtrl,
            maxLines: 3,
          ),
          const SizedBox(height: 24),
          CustomStringListEditor(
            title: 'Product Types',
            hint: 'Add new type',
            controller: _typeInputCtrl,
            items: _productTypes,
            onAdd: () => _addItem(_typeInputCtrl, _productTypes),
            onRemove: (value) => _removeItem(value, _productTypes),
          ),
          const SizedBox(height: 24),
          CustomStringListEditor(
            title: 'Glaze Options',
            hint: 'Add glaze option',
            controller: _glazeInputCtrl,
            items: _glazeOptions,
            onAdd: () => _addItem(_glazeInputCtrl, _glazeOptions),
            onRemove: (value) => _removeItem(value, _glazeOptions),
          ),
          const SizedBox(height: 24),
          AdminToggleSwitch(
            label: 'Enable custom products page',
            value: _isEnabled,
            onChanged: (value) => setState(() => _isEnabled = value),
          ),
        ],
      ),
    );
  }

  Widget _buildOrdersPanel() {
    return DefaultTabController(
      length: 3,
      child: CustomProductsPanel(
        title: 'Order Tracking',
        child: Column(
          children: [
            TabBar(
              labelColor: AppTheme.terracotta,
              unselectedLabelColor: AppTheme.textLight,
              indicatorSize: TabBarIndicatorSize.label,
              labelStyle: GoogleFonts.jost(
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
              tabs: const [
                Tab(text: 'REQUESTS'),
                Tab(text: 'PRODUCTION'),
                Tab(text: 'HISTORY'),
              ],
            ),
            const SizedBox(height: 20),
            SizedBox(
              height: 500,
              child: TabBarView(
                children: [
                  _buildOrdersFilterList(['submitted', 'in_review', 'quoted']),
                  _buildOrdersFilterList([
                    'confirmed',
                    'in_production',
                    'ready_to_dispatch',
                  ]),
                  _buildOrdersFilterList([
                    'in_transit',
                    'delivered',
                    'rejected',
                  ]),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrdersFilterList(List<String> statuses) {
    final filtered = _orders.where((o) => statuses.contains(o.status)).toList();

    if (filtered.isEmpty) {
      return Center(
        child: Text(
          'No orders in this stage',
          style: AppTheme.bodyMedium.copyWith(color: AppTheme.textLight),
        ),
      );
    }

    return ListView(
      children: filtered
          .map(
            (order) => CustomOrderCard(
              order: order,
              isSelected: order.id == _selectedOrder?.id,
              onTap: () => _selectOrder(order),
            ),
          )
          .toList(),
    );
  }
}
