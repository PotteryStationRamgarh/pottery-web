import 'package:flutter/material.dart';
import '../admin_branding_controller.dart';
import 'section_card.dart';
import 'field_input.dart';

class ContentSection extends StatelessWidget {
  final AdminBrandingController controller;
  const ContentSection({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      title: 'App Content & Legal',
      children: [
        FieldInput(
          label: 'About Us',
          controller: controller.aboutCtrl,
          maxLines: 6,
        ),
        const SizedBox(height: 20),
        FieldInput(
          label: 'Help Text',
          controller: controller.helpCtrl,
          maxLines: 3,
        ),
        const SizedBox(height: 20),
        FieldInput(
          label: 'Privacy Policy',
          controller: controller.privacyCtrl,
          maxLines: 4,
        ),
        const SizedBox(height: 20),
        FieldInput(
          label: 'Terms & Conditions',
          controller: controller.termsCtrl,
          maxLines: 3,
        ),
      ],
    );
  }
}
