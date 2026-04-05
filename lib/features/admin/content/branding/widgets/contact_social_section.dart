import 'package:flutter/material.dart';
import '../admin_branding_controller.dart';
import '../../../../../core/utils/responsive_utils.dart';
import 'section_card.dart';
import 'field_input.dart';

class ContactSocialSection extends StatelessWidget {
  final AdminBrandingController controller;
  const ContactSocialSection({super.key, required this.controller});

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
              _contactSection(),
              const SizedBox(height: 24),
              _socialSection(),
            ],
          );
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: _contactSection()),
            const SizedBox(width: 24),
            Expanded(child: _socialSection()),
          ],
        );
      },
    );
  }

  Widget _contactSection() => SectionCard(
    title: 'Contact Information',
    children: [
      FieldInput(label: 'Support Email', controller: controller.emailCtrl),
      const SizedBox(height: 16),
      FieldInput(label: 'Support Phone', controller: controller.phoneCtrl),
      const SizedBox(height: 16),
      FieldInput(
        label: 'Address',
        controller: controller.addressCtrl,
        maxLines: 3,
      ),
    ],
  );

  Widget _socialSection() => SectionCard(
    title: 'Social Links',
    children: [
      FieldInput(label: 'Instagram URL', controller: controller.igCtrl),
      const SizedBox(height: 16),
      FieldInput(label: 'Facebook URL', controller: controller.fbCtrl),
      const SizedBox(height: 16),
      FieldInput(label: 'Website URL', controller: controller.webCtrl),
    ],
  );
}
