import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../features/admin/catalog/widgets/admin_form_field.dart';
import '../../../../models/custom_order_model.dart';

class CustomProductsSummaryCard extends StatelessWidget {
  final bool isEnabled;
  final int pendingCount;
  final bool isSaving;
  final VoidCallback onSave;

  const CustomProductsSummaryCard({
    super.key,
    required this.isEnabled,
    required this.pendingCount,
    required this.isSaving,
    required this.onSave,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              'Custom products are ${isEnabled ? 'enabled' : 'disabled'} • $pendingCount pending request(s)',
              style: AppTheme.headingMedium,
            ),
          ),
          FilledButton(
            onPressed: isSaving ? null : onSave,
            child: isSaving
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Save Settings'),
          ),
        ],
      ),
    );
  }
}

class CustomProductsPanel extends StatelessWidget {
  final String title;
  final Widget child;

  const CustomProductsPanel({
    super.key,
    required this.title,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: AppTheme.headingMedium),
          const SizedBox(height: 20),
          child,
        ],
      ),
    );
  }
}

class CustomStringListEditor extends StatelessWidget {
  final String title;
  final String hint;
  final TextEditingController controller;
  final List<String> items;
  final VoidCallback onAdd;
  final ValueChanged<String> onRemove;

  const CustomStringListEditor({
    super.key,
    required this.title,
    required this.hint,
    required this.controller,
    required this.items,
    required this.onAdd,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: AppTheme.bodyLarge.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: AdminFormField(
                label: title,
                hint: hint,
                controller: controller,
              ),
            ),
            const SizedBox(width: 12),
            FilledButton(onPressed: onAdd, child: const Text('Add')),
          ],
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: items
              .map(
                (item) =>
                    Chip(label: Text(item), onDeleted: () => onRemove(item)),
              )
              .toList(),
        ),
      ],
    );
  }
}

class CustomOrderCard extends StatelessWidget {
  final CustomOrderModel order;
  final bool isSelected;
  final VoidCallback onTap;

  const CustomOrderCard({
    super.key,
    required this.order,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? AppTheme.terracotta : AppTheme.divider,
          ),
          color: isSelected
              ? AppTheme.exhibitionBackground
              : AppTheme.background,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${order.name} • ${order.productType}',
              style: AppTheme.headingMedium,
            ),
            const SizedBox(height: 6),
            Text('${order.email} • ${order.phone}', style: AppTheme.bodySmall),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppTheme.terracotta.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                order.displayStatus.toUpperCase(),
                style: GoogleFonts.jost(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.terracotta,
                  letterSpacing: 1,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class CustomOrderReviewForm extends StatelessWidget {
  final CustomOrderModel order;
  final String status;
  final TextEditingController notesController;
  final TextEditingController priceController;
  final DateTime? proposedDate;
  final bool isSaving;
  final ValueChanged<String> onStatusChanged;
  final VoidCallback onPickDate;
  final VoidCallback onSave;

  const CustomOrderReviewForm({
    super.key,
    required this.order,
    required this.status,
    required this.notesController,
    required this.priceController,
    required this.proposedDate,
    required this.isSaving,
    required this.onStatusChanged,
    required this.onPickDate,
    required this.onSave,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(order.name, style: AppTheme.headingMedium),
        const SizedBox(height: 8),
        Text(
          '${order.productType} • ${order.quantity} item(s)',
          style: AppTheme.bodyMedium,
        ),
        Text('Glaze: ${order.glazePreference}', style: AppTheme.bodyMedium),
        if (order.size.isNotEmpty)
          Text('Size: ${order.size}', style: AppTheme.bodyMedium),
        if (order.inspirationImageUrl.isNotEmpty) ...[
          const SizedBox(height: 16),
          Text(
            'Inspiration Image',
            style: GoogleFonts.jost(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppTheme.textLight,
            ),
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Image.network(
              order.inspirationImageUrl,
              width: double.infinity,
              fit: BoxFit.contain, // Maintain aspect ratio
              frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
                return Container(color: AppTheme.background, child: child);
              },
            ),
          ),
        ],
        const SizedBox(height: 20),
        DropdownButtonFormField<String>(
          initialValue: status,
          items:
              const [
                    'submitted',
                    'in_review',
                    'quoted',
                    'confirmed',
                    'rejected',
                    'in_production',
                    'ready_to_dispatch',
                    'in_transit',
                    'delivered',
                  ]
                  .map(
                    (value) => DropdownMenuItem(
                      value: value,
                      child: Text(
                        CustomOrderModel.normalizeStatus(
                          value,
                        ).replaceAll('_', ' ').toUpperCase(),
                      ),
                    ),
                  )
                  .toList(),
          onChanged: (value) {
            if (value != null) onStatusChanged(value);
          },
        ),
        const SizedBox(height: 16),
        AdminFormField(
          label: 'Quoted Price',
          hint: 'Enter quoted price',
          controller: priceController,
          keyboardType: TextInputType.number,
        ),
        const SizedBox(height: 16),
        AdminFormField(
          label: 'Admin Notes',
          hint: 'Add notes for this request',
          controller: notesController,
          maxLines: 4,
        ),
        const SizedBox(height: 16),
        OutlinedButton(
          onPressed: onPickDate,
          child: Text(
            proposedDate == null
                ? 'Set Creation Date'
                : 'Creation Date: ${DateFormat('dd MMM yyyy').format(proposedDate!)}',
          ),
        ),
        const SizedBox(height: 20),
        FilledButton(
          onPressed: isSaving ? null : onSave,
          child: isSaving
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Save Review'),
        ),
      ],
    );
  }
}
