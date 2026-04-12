import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/repositories/order_repository.dart';
import '../../../core/theme/app_theme.dart';
import '../../../models/order_model.dart';

class AdminOrdersPage extends StatefulWidget {
  const AdminOrdersPage({super.key});

  @override
  State<AdminOrdersPage> createState() => _AdminOrdersPageState();
}

class _AdminOrdersPageState extends State<AdminOrdersPage> {
  final _trackingController = TextEditingController();
  final _courierController = TextEditingController();
  final _notesController = TextEditingController();

  bool _isLoading = true;
  bool _isSaving = false;
  List<OrderModel> _orders = [];
  OrderModel? _selectedOrder;
  String _selectedStatus = 'pending';
  DateTime? _estimatedDelivery;
  String _filter = 'all';

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _trackingController.dispose();
    _courierController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final orders = await OrderRepository.getAllOrders();
    if (!mounted) return;
    setState(() {
      _orders = orders;
      _isLoading = false;
      if (_selectedOrder != null) {
        _selectedOrder = orders.firstWhere(
          (item) => item.id == _selectedOrder!.id,
          orElse: () => orders.isNotEmpty ? orders.first : _selectedOrder!,
        );
      } else if (orders.isNotEmpty) {
        _setSelectedOrder(orders.first);
      }
    });
  }

  void _setSelectedOrder(OrderModel order) {
    _selectedOrder = order;
    _selectedStatus = order.orderStatus;
    _trackingController.text = order.trackingNumber;
    _courierController.text = order.courierName;
    _notesController.text = order.adminNotes;
    _estimatedDelivery = order.estimatedDelivery;
  }

  Future<void> _save() async {
    final order = _selectedOrder;
    if (order == null) return;

    setState(() => _isSaving = true);
    try {
      await OrderRepository.updateOrderStatus(
        order.id,
        status: _selectedStatus,
        trackingNumber: _trackingController.text.trim(),
        courierName: _courierController.text.trim(),
        estimatedDelivery: _estimatedDelivery,
        adminNotes: _notesController.text.trim(),
        description: _notesController.text.trim(),
      );
      await _load();
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Order updated')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to update order: $e')));
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppTheme.terracotta),
            )
          : Padding(
              padding: const EdgeInsets.all(24),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final isWide = constraints.maxWidth >= 1100;
                  return isWide
                      ? Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(flex: 5, child: _buildListPanel()),
                            const SizedBox(width: 24),
                            Expanded(flex: 7, child: _buildDetailPanel()),
                          ],
                        )
                      : ListView(
                          children: [
                            _buildListPanel(),
                            const SizedBox(height: 24),
                            _buildDetailPanel(),
                          ],
                        );
                },
              ),
            ),
    );
  }

  Widget _buildListPanel() {
    final filtered = _filter == 'all'
        ? _orders
        : _orders.where((order) => order.orderStatus == _filter).toList();

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Storefront Orders', style: AppTheme.headingLarge),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final value in const [
                'all',
                'pending',
                'confirmed',
                'in_production',
                'ready_to_dispatch',
                'in_transit',
                'delivered',
                'cancelled',
                'return_requested',
                'refund_requested',
              ])
                ChoiceChip(
                  label: Text(value.replaceAll('_', ' ')),
                  selected: _filter == value,
                  onSelected: (_) => setState(() => _filter = value),
                ),
            ],
          ),
          const SizedBox(height: 20),
          if (filtered.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 40),
              child: Center(
                child: Text('No orders found', style: AppTheme.bodyLarge),
              ),
            )
          else
            ...filtered.map(
              (order) => InkWell(
                onTap: () => setState(() => _setSelectedOrder(order)),
                borderRadius: BorderRadius.circular(18),
                child: Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: _selectedOrder?.id == order.id
                        ? AppTheme.exhibitionBackground
                        : AppTheme.background,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: _selectedOrder?.id == order.id
                          ? AppTheme.terracotta
                          : AppTheme.divider,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Order ${order.id.substring(0, 8).toUpperCase()}',
                        style: AppTheme.headingMedium,
                      ),
                      const SizedBox(height: 6),
                      Text(order.customerEmail, style: AppTheme.bodySmall),
                      const SizedBox(height: 6),
                      Text(
                        order.displayStatus,
                        style: AppTheme.bodySmall.copyWith(
                          color: AppTheme.terracotta,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildDetailPanel() {
    final order = _selectedOrder;
    if (order == null) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Center(
          child: Text('Select an order to review', style: AppTheme.bodyLarge),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Order ${order.id.substring(0, 8).toUpperCase()}',
              style: AppTheme.headingLarge,
            ),
            const SizedBox(height: 8),
            Text(
              'Placed ${DateFormat('dd MMM yyyy • hh:mm a').format(order.createdAt)}',
              style: AppTheme.bodySmall,
            ),
            const SizedBox(height: 20),
            DropdownButtonFormField<String>(
              initialValue: _selectedStatus,
              decoration: AppTheme.inputDecoration(label: 'Order Status'),
              items:
                  const [
                        'pending',
                        'confirmed',
                        'in_production',
                        'ready_to_dispatch',
                        'in_transit',
                        'delivered',
                        'cancelled',
                        'return_requested',
                        'refund_requested',
                        'refunded',
                      ]
                      .map(
                        (status) => DropdownMenuItem(
                          value: status,
                          child: Text(
                            status.replaceAll('_', ' ').toUpperCase(),
                          ),
                        ),
                      )
                      .toList(),
              onChanged: (value) {
                if (value != null) setState(() => _selectedStatus = value);
              },
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _courierController,
              decoration: AppTheme.inputDecoration(label: 'Courier Name'),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _trackingController,
              decoration: AppTheme.inputDecoration(label: 'Tracking Number'),
            ),
            const SizedBox(height: 16),
            OutlinedButton(
              onPressed: () async {
                final selected = await showDatePicker(
                  context: context,
                  initialDate: _estimatedDelivery ?? DateTime.now(),
                  firstDate: DateTime.now(),
                  lastDate: DateTime.now().add(const Duration(days: 365)),
                );
                if (selected != null) {
                  setState(() => _estimatedDelivery = selected);
                }
              },
              child: Text(
                _estimatedDelivery == null
                    ? 'Set estimated delivery'
                    : 'Estimated delivery: ${DateFormat('dd MMM yyyy').format(_estimatedDelivery!)}',
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _notesController,
              maxLines: 4,
              decoration: AppTheme.inputDecoration(
                label: 'Admin Notes / Customer Update',
              ),
            ),
            const SizedBox(height: 20),
            Text('Items', style: AppTheme.headingMedium),
            const SizedBox(height: 8),
            ...order.items.map(
              (item) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Text(
                  '${item.title} • Qty ${item.qty} • ₹${item.sellingPrice.toStringAsFixed(0)}',
                  style: AppTheme.bodyMedium,
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text('Timeline', style: AppTheme.headingMedium),
            const SizedBox(height: 8),
            ...order.statusTimeline.reversed.map(
              (entry) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Text(
                  '${DateFormat('dd MMM yyyy • hh:mm a').format(entry.createdAt)}\n${entry.title}\n${entry.description}',
                  style: AppTheme.bodySmall,
                ),
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isSaving ? null : _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.terracotta,
                  foregroundColor: Colors.white,
                ),
                child: Text(_isSaving ? 'SAVING...' : 'SAVE ORDER UPDATE'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
