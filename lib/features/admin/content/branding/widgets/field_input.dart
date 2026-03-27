import 'package:flutter/material.dart';
import '../../../../../core/theme/app_theme.dart';

class FieldInput extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final int maxLines;

  const FieldInput({
    super.key,
    required this.label,
    required this.controller,
    this.maxLines = 1,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTheme.bodySmall.copyWith(
            color: AppTheme.textDark,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          maxLines: maxLines,
          style: AppTheme.bodyLarge,
          decoration: AppTheme.inputDecoration(
              label: label, hint: 'Enter $label'),
        ),
      ],
    );
  }
}