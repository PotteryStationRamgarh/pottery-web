import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_theme.dart';

class AdminExclusiveProductsPage extends StatelessWidget {
  const AdminExclusiveProductsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return _DummyAdminPage(
      icon: Icons.star_outline,
      title: 'Exclusive Products',
      description: 'Manage exclusive, limited-edition pottery pieces.',
    );
  }
}

class _DummyAdminPage extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  const _DummyAdminPage({required this.icon, required this.title, required this.description});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                color: AppTheme.white,
                shape: BoxShape.circle,
                border: Border.all(color: AppTheme.divider),
              ),
              child: Icon(icon, size: 48, color: AppTheme.primaryBrown),
            ),
            const SizedBox(height: 24),
            Text(
              title,
              style: GoogleFonts.playfairDisplay(
                fontSize: 28,
                fontWeight: FontWeight.w700,
                color: AppTheme.textDark,
              ),
            ),
            const SizedBox(height: 10),
            Text(description, style: AppTheme.bodyMedium),
            const SizedBox(height: 28),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              decoration: BoxDecoration(
                color: AppTheme.primaryBrown.withOpacity(0.08),
                borderRadius: BorderRadius.circular(30),
                border: Border.all(color: AppTheme.primaryBrown.withOpacity(0.2)),
              ),
              child: Text(
                'Coming Soon',
                style: AppTheme.bodyMedium.copyWith(
                  color: AppTheme.primaryBrown,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
