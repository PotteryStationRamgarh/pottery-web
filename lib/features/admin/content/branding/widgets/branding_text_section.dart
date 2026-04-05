import 'package:flutter/material.dart';
import '../admin_branding_controller.dart';
import '../../../../../core/utils/responsive_utils.dart';
import 'section_card.dart';
import 'field_input.dart';

class BrandingTextSection extends StatelessWidget {
  final AdminBrandingController controller;
  const BrandingTextSection({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isStacked = !ResponsiveBreakpoints.isDesktopWidth(
          constraints.maxWidth,
        );

        if (isStacked) {
          return Column(
            children: [
              _heroSection(),
              const SizedBox(height: 24),
              _bannerSection(),
            ],
          );
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: _heroSection()),
            const SizedBox(width: 24),
            Expanded(child: _bannerSection()),
          ],
        );
      },
    );
  }

  Widget _heroSection() => SectionCard(
    title: 'Hero Section',
    children: [
      FieldInput(label: 'App Name', controller: controller.appNameCtrl),
      const SizedBox(height: 16),
      FieldInput(label: 'Hero Title', controller: controller.heroTextCtrl),
      const SizedBox(height: 16),
      FieldInput(
        label: 'Hero Description',
        controller: controller.heroDescCtrl,
        maxLines: 3,
      ),
    ],
  );

  Widget _bannerSection() => SectionCard(
    title: 'Store Banner',
    children: [
      FieldInput(label: 'Banner Title', controller: controller.bannerTitleCtrl),
      const SizedBox(height: 16),
      FieldInput(
        label: 'Banner Description',
        controller: controller.bannerDescCtrl,
        maxLines: 4,
      ),
    ],
  );
}
