import 'package:flutter/material.dart';
import '../admin_branding_controller.dart';
import 'section_card.dart';
import 'field_input.dart';

class BrandingTextSection extends StatelessWidget {
  final AdminBrandingController controller;
  const BrandingTextSection({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: SectionCard(
            title: 'Hero Section',
            children: [
              FieldInput(
                  label: 'App Name',
                  controller: controller.appNameCtrl),
              const SizedBox(height: 16),
              FieldInput(
                  label: 'Hero Title',
                  controller: controller.heroTextCtrl),
              const SizedBox(height: 16),
              FieldInput(
                  label: 'Hero Description',
                  controller: controller.heroDescCtrl,
                  maxLines: 3),
            ],
          ),
        ),
        const SizedBox(width: 24),
        Expanded(
          child: SectionCard(
            title: 'Store Banner',
            children: [
              FieldInput(
                  label: 'Banner Title',
                  controller: controller.bannerTitleCtrl),
              const SizedBox(height: 16),
              FieldInput(
                  label: 'Banner Description',
                  controller: controller.bannerDescCtrl,
                  maxLines: 4),
            ],
          ),
        ),
      ],
    );
  }
}