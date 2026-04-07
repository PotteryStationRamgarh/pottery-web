import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_theme.dart';
import '../home/widgets/nav_bar.dart';

class SavedAddressesScreen extends StatefulWidget {
  const SavedAddressesScreen({super.key});

  @override
  State<SavedAddressesScreen> createState() => _SavedAddressesScreenState();
}

class _SavedAddressesScreenState extends State<SavedAddressesScreen> {
  final List<Map<String, String>> _addresses = [
    {
      'id': '1',
      'name': 'Manas S.',
      'address': '123 Artisan Lane, Ramgarh',
      'landmark': 'Near River Bed',
      'city': 'Nainital',
      'state': 'Uttarakhand',
      'pincode': '263132',
      'phone': '+91 9876543210',
    },
    {
      'id': '2',
      'name': 'Home Office',
      'address': 'Sector 4, Dwarka',
      'landmark': 'Opposite Park',
      'city': 'New Delhi',
      'state': 'Delhi',
      'pincode': '110075',
      'phone': '+91 8888888888',
    },
  ];

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth > 800;

    return Scaffold(
      backgroundColor: AppTheme.background,
      endDrawer: const NavDrawer(),
      body: Stack(
        children: [
          SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 72),
                Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: isDesktop ? 48 : 20,
                    vertical: 40,
                  ),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 900),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            IconButton(
                              icon: const Icon(Icons.arrow_back, size: 20),
                              onPressed: () => Navigator.pop(context),
                            ),
                            const SizedBox(width: 8),
                            Text("Saved Addresses", style: AppTheme.serifHeadingLarge),
                          ],
                        ),
                        const SizedBox(height: 40),
                        GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: isDesktop ? 2 : 1,
                            crossAxisSpacing: 24,
                            mainAxisSpacing: 24,
                            mainAxisExtent: 220,
                          ),
                          itemCount: _addresses.length + 1,
                          itemBuilder: (context, index) {
                            if (index == _addresses.length) {
                              return _buildAddNewCard();
                            }
                            return _buildAddressCard(_addresses[index]);
                          },
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 80),
              ],
            ),
          ),
          const Positioned(top: 0, left: 0, right: 0, child: NavBar()),
        ],
      ),
    );
  }

  Widget _buildAddressCard(Map<String, String> addr) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                addr['name']!,
                style: GoogleFonts.jost(fontWeight: FontWeight.w600, fontSize: 16),
              ),
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit_outlined, size: 18, color: Colors.grey),
                    onPressed: () => _showAddressForm(addr),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline, size: 18, color: AppTheme.errorRed),
                    onPressed: () {
                      // TODO: Delete
                    },
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            "${addr['address']}, ${addr['landmark']}",
            style: AppTheme.bodySmall,
          ),
          Text(
            "${addr['city']}, ${addr['state']} - ${addr['pincode']}",
            style: AppTheme.bodySmall,
          ),
          const Spacer(),
          Text(
            addr['phone']!,
            style: GoogleFonts.jost(fontSize: 13, fontWeight: FontWeight.w500, color: AppTheme.textDark),
          ),
        ],
      ),
    );
  }

  Widget _buildAddNewCard() {
    return GestureDetector(
      onTap: () => _showAddressForm(null),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.divider, style: BorderStyle.solid),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.terracotta.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.add, color: AppTheme.terracotta),
            ),
            const SizedBox(height: 12),
            Text(
              "Add New Address",
              style: GoogleFonts.jost(fontWeight: FontWeight.w500, color: AppTheme.terracotta),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddressForm(Map<String, String>? address) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.85,
          margin: const EdgeInsets.only(top: 40),
          decoration: const BoxDecoration(
            color: AppTheme.background,
            borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
          ),
          padding: const EdgeInsets.all(32),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppTheme.divider,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                Text(
                  address == null ? "Add New Address" : "Edit Address",
                  style: AppTheme.serifHeadingMedium,
                ),
                const SizedBox(height: 32),
                _buildField("Full Name", address?['name']),
                const Row(
                  children: [
                    Expanded(child: _FormTextField(label: "Phone Number")),
                    SizedBox(width: 16),
                    Expanded(child: _FormTextField(label: "Pincode")),
                  ],
                ),
                _buildField("Street Address", address?['address']),
                _buildField("Landmark / Area", address?['landmark']),
                const Row(
                  children: [
                    Expanded(child: _FormTextField(label: "City")),
                    SizedBox(width: 16),
                    Expanded(child: _FormTextField(label: "State")),
                  ],
                ),
                const SizedBox(height: 40),
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.terracotta,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      elevation: 0,
                    ),
                    child: Text(
                      "SAVE ADDRESS",
                      style: GoogleFonts.jost(
                        fontWeight: FontWeight.w600,
                        letterSpacing: 1.5,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildField(String label, String? initialValue) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: _FormTextField(label: label, initialValue: initialValue),
    );
  }
}

class _FormTextField extends StatelessWidget {
  final String label;
  final String? initialValue;
  const _FormTextField({required this.label, this.initialValue});

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: initialValue != null ? TextEditingController(text: initialValue) : null,
      decoration: AppTheme.inputDecoration(label: label),
      style: AppTheme.bodyMedium,
    );
  }
}
