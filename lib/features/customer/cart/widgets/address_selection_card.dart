import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../models/address_model.dart';

class AddressSelectionCard extends StatelessWidget {
  final AddressModel address;
  final bool isSelected;
  final VoidCallback onTap;

  const AddressSelectionCard({
    super.key,
    required this.address,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? AppTheme.terracotta : AppTheme.divider,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppTheme.terracotta.withValues(alpha: 0.1),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ]
              : [],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  isSelected ? Icons.check_circle : Icons.radio_button_unchecked,
                  color: isSelected ? AppTheme.terracotta : AppTheme.textLight,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Text(
                  address.name,
                  style: GoogleFonts.jost(
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                    color: AppTheme.textDark,
                  ),
                ),
                if (address.addressType.isNotEmpty) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppTheme.background,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      address.addressType.toUpperCase(),
                      style: GoogleFonts.jost(
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textLight,
                      ),
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 16),
            Text(
              address.addressLine1,
              style: GoogleFonts.jost(color: AppTheme.textDark, height: 1.5),
            ),
            if (address.addressLine2.isNotEmpty)
              Text(
                address.addressLine2,
                style: GoogleFonts.jost(color: AppTheme.textDark, height: 1.5),
              ),
            Text(
              "${address.city}, ${address.state} - ${address.pincode}",
              style: GoogleFonts.jost(color: AppTheme.textLight),
            ),
            const SizedBox(height: 12),
            Text(
              address.phone,
              style: GoogleFonts.jost(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: AppTheme.textDark,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class AddAddressCard extends StatelessWidget {
  final VoidCallback onTap;
  const AddAddressCard({super.key, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 180,
        decoration: BoxDecoration(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: AppTheme.divider,
            style: BorderStyle.solid,
            width: 1.5,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.terracotta.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.add, color: AppTheme.terracotta, size: 24),
            ),
            const SizedBox(height: 16),
            Text(
              "Add New Address",
              style: GoogleFonts.jost(
                fontWeight: FontWeight.w600,
                color: AppTheme.terracotta,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
