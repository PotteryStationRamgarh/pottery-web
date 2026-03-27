import 'package:flutter/material.dart';
import '../admin_branding_controller.dart';
import 'section_card.dart';
import 'field_input.dart';

class ContactSocialSection extends StatelessWidget {
  final AdminBrandingController controller;
  const ContactSocialSection({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: SectionCard(
            title: 'Contact Information',
            children: [
              FieldInput(
                  label: 'Support Email',
                  controller: controller.emailCtrl),
              const SizedBox(height: 16),
              FieldInput(
                  label: 'Support Phone',
                  controller: controller.phoneCtrl),
              const SizedBox(height: 16),
              FieldInput(
                  label: 'Address',
                  controller: controller.addressCtrl,
                  maxLines: 3),
            ],
          ),
        ),
        const SizedBox(width: 24),
        Expanded(
          child: SectionCard(
            title: 'Social Links',
            children: [
              FieldInput(
                  label: 'Instagram URL',
                  controller: controller.igCtrl),
              const SizedBox(height: 16),
              FieldInput(
                  label: 'Facebook URL',
                  controller: controller.fbCtrl),
              const SizedBox(height: 16),
              FieldInput(
                  label: 'Website URL',
                  controller: controller.webCtrl),
            ],
          ),
        ),
      ],
    );
  }
}