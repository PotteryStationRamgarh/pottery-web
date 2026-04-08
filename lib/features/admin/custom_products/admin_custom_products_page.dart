import 'dart:typed_data';

import 'package:flutter/material.dart';

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
  const AdminCustomProductsPage({super.key});

  @override
  State<AdminCustomProductsPage> createState() =>
      _AdminCustomProductsPageState();
}

class _AdminCustomProductsPageState extends State<AdminCustomProductsPage> {
  bool _isLoading = true;
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
  String _status = 'pending';
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
    setState(() => _isLoading = true);
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

    if (mounted) setState(() => _isLoading = false);
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
      await CustomOrderRepository.updateCustomOrder(
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
          createdAt: order.createdAt,
          updatedAt: DateTime.now(),
        ),
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
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: AppTheme.background,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          CustomProductsSummaryCard(
            isEnabled: _isEnabled,
            pendingCount: _orders
                .where((order) => order.status == 'pending')
                .length,
            isSaving: _isSavingConfig,
            onSave: _saveConfig,
          ),
          const SizedBox(height: 24),
          LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth >= 1180;
              return isWide
                  ? Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(flex: 6, child: _buildConfigPanel()),
                        const SizedBox(width: 24),
                        Expanded(flex: 5, child: _buildOrdersPanel()),
                      ],
                    )
                  : Column(
                      children: [
                        _buildConfigPanel(),
                        const SizedBox(height: 24),
                        _buildOrdersPanel(),
                      ],
                    );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildConfigPanel() {
    return CustomProductsPanel(
      title: 'Custom Product Settings',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ImageUploadWidget(
            title: 'Hero Image',
            multiple: false,
            minHeight: 220,
            onImagesSelected: (images) {
              setState(
                () => _heroImageBytes = images.isEmpty ? null : images.first,
              );
            },
          ),
          if (_heroImageBytes == null && _config.heroImageUrl.isNotEmpty) ...[
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Image.network(
                _config.heroImageUrl,
                height: 160,
                width: double.infinity,
                fit: BoxFit.cover,
              ),
            ),
          ],
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
    return Column(
      children: [
        CustomProductsPanel(
          title: 'Custom Requests',
          child: _orders.isEmpty
              ? const Text('No custom requests yet.')
              : Column(
                  children: _orders
                      .map(
                        (order) => CustomOrderCard(
                          order: order,
                          isSelected: order.id == _selectedOrder?.id,
                          onTap: () => _selectOrder(order),
                        ),
                      )
                      .toList(),
                ),
        ),
        const SizedBox(height: 24),
        if (_selectedOrder != null)
          CustomProductsPanel(
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
          ),
      ],
    );
  }
}
