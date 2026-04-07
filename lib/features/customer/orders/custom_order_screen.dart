import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_theme.dart';
import '../home/widgets/nav_bar.dart';

class CustomOrderScreen extends StatefulWidget {
  const CustomOrderScreen({super.key});

  @override
  State<CustomOrderScreen> createState() => _CustomOrderScreenState();
}

class _CustomOrderScreenState extends State<CustomOrderScreen> {
  String _selectedType = 'Bowl';
  int _quantity = 1;

  final List<String> _productTypes = [
    'Bowl',
    'Vase',
    'Mug',
    'Plate',
    'Decorative',
    'Other'
  ];

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth > 900;

    return Scaffold(
      backgroundColor: AppTheme.background,
      endDrawer: const NavDrawer(),
      body: Stack(
        children: [
          SingleChildScrollView(
            child: Column(
              children: [
                const SizedBox(height: 72),
                _buildHeader(isDesktop),
                Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: isDesktop ? 48 : 20,
                    vertical: 60,
                  ),
                  child: Center(
                    child: Container(
                      constraints: const BoxConstraints(maxWidth: 800),
                      padding: EdgeInsets.all(isDesktop ? 60 : 24),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: AppTheme.divider),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("Commission a Piece", style: AppTheme.serifHeadingLarge),
                          const SizedBox(height: 12),
                          Text(
                            "Tell us about your vision. Our artisans will bring it to life using traditional techniques.",
                            style: GoogleFonts.jost(color: AppTheme.textLight, height: 1.6),
                          ),
                          const SizedBox(height: 48),
                          _buildForm(),
                        ],
                      ),
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

  Widget _buildHeader(bool isDesktop) {
    return Container(
      height: 300,
      width: double.infinity,
      decoration: const BoxDecoration(
        image: DecorationImage(
          image: NetworkImage('https://images.unsplash.com/photo-1565191999001-551c187427bb?q=80&w=1500&auto=format&fit=crop'),
          fit: BoxFit.cover,
        ),
      ),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.bottomCenter,
            end: Alignment.topCenter,
            colors: [
              Colors.black.withOpacity(0.6),
              Colors.transparent,
            ],
          ),
        ),
        padding: const EdgeInsets.all(48),
        alignment: Alignment.bottomLeft,
        child: Text(
          "Custom Creations",
          style: GoogleFonts.playfairDisplay(
            fontSize: isDesktop ? 48 : 32,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  Widget _buildForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              flex: 2,
              child: _buildDropdownLabel("Product Type"),
            ),
            const SizedBox(width: 24),
            Expanded(
              flex: 1,
              child: _buildDropdownLabel("Quantity"),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              flex: 2,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  border: Border.all(color: AppTheme.divider, width: 1.5),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _selectedType,
                    isExpanded: true,
                    style: AppTheme.bodyMedium,
                    items: _productTypes.map((String type) {
                      return DropdownMenuItem<String>(
                        value: type,
                        child: Text(type),
                      );
                    }).toList(),
                    onChanged: (val) => setState(() => _selectedType = val!),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 24),
            Expanded(
              flex: 1,
              child: _buildQtyCounter(),
            ),
          ],
        ),
        const SizedBox(height: 32),
        const Row(
          children: [
            Expanded(child: _FormTextField(label: "Size / Dimensions", hint: "e.g. 20cm diameter")),
            SizedBox(width: 24),
            Expanded(child: _FormTextField(label: "Glaze Preference", hint: "e.g. Ash glaze, Earth tones")),
          ],
        ),
        const SizedBox(height: 32),
        TextField(
          maxLines: 4,
          decoration: AppTheme.inputDecoration(
            label: "Special Notes",
            hint: "Any specific patterns or shapes in mind?",
          ),
          style: AppTheme.bodyMedium,
        ),
        const SizedBox(height: 48),
        const Divider(),
        const SizedBox(height: 48),
        Text("Contact Information", style: AppTheme.headingMedium),
        const SizedBox(height: 32),
        const _FormTextField(label: "Your Name"),
        const Row(
          children: [
            Expanded(child: _FormTextField(label: "Email Address")),
            SizedBox(width: 24),
            Expanded(child: _FormTextField(label: "Phone Number")),
          ],
        ),
        const SizedBox(height: 48),
        SizedBox(
          width: double.infinity,
          height: 60,
          child: ElevatedButton(
            onPressed: () {
              // TODO: Submit request
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.terracotta,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              elevation: 0,
            ),
            child: Text(
              "SUBMIT REQUEST",
              style: GoogleFonts.jost(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                letterSpacing: 2,
                color: Colors.white,
              ),
            ),
          ),
        ),
        const SizedBox(height: 20),
        Center(
          child: Text(
            "We'll reach out within 2-3 working days",
            style: GoogleFonts.jost(fontSize: 12, color: AppTheme.textLight, fontStyle: FontStyle.italic),
          ),
        ),
      ],
    );
  }

  Widget _buildDropdownLabel(String label) {
    return Text(
      label,
      style: GoogleFonts.jost(
        fontSize: 13,
        fontWeight: FontWeight.w500,
        color: AppTheme.textLight,
      ),
    );
  }

  Widget _buildQtyCounter() {
    return Container(
      height: 50,
      decoration: BoxDecoration(
        border: Border.all(color: AppTheme.divider, width: 1.5),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          IconButton(
            icon: const Icon(Icons.remove, size: 18),
            onPressed: () {
              if (_quantity > 1) setState(() => _quantity--);
            },
          ),
          Text(
            "$_quantity",
            style: GoogleFonts.jost(fontWeight: FontWeight.w600),
          ),
          IconButton(
            icon: const Icon(Icons.add, size: 18),
            onPressed: () => setState(() => _quantity++),
          ),
        ],
      ),
    );
  }
}

class _FormTextField extends StatelessWidget {
  final String label;
  final String? hint;
  const _FormTextField({required this.label, this.hint});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: TextField(
        decoration: AppTheme.inputDecoration(label: label, hint: hint),
        style: AppTheme.bodyMedium,
      ),
    );
  }
}
