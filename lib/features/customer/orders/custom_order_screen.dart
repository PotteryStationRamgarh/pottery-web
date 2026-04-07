import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/repositories/custom_order_repository.dart';
import '../../../models/custom_order_model.dart';
import '../home/widgets/nav_bar.dart';

class CustomOrderScreen extends StatefulWidget {
  const CustomOrderScreen({super.key});

  @override
  State<CustomOrderScreen> createState() => _CustomOrderScreenState();
}

class _CustomOrderScreenState extends State<CustomOrderScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _sizeController = TextEditingController();
  final _glazeController = TextEditingController();
  final _notesController = TextEditingController();
  
  String _selectedType = 'Bowl';
  int _quantity = 1;
  bool _isSubmitting = false;

  final List<String> _productTypes = [
    'Bowl',
    'Vase',
    'Mug',
    'Plate',
    'Decorative',
    'Other'
  ];

  @override
  void initState() {
    super.initState();
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      _emailController.text = user.email ?? '';
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _sizeController.dispose();
    _glazeController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    if (_nameController.text.isEmpty || _emailController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please provide your name and email')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      final customOrder = CustomOrderModel(
        id: '',
        userId: user?.uid ?? '',
        name: _nameController.text,
        email: _emailController.text,
        phone: _phoneController.text,
        productType: _selectedType,
        size: _sizeController.text,
        glazePreference: _glazeController.text,
        quantity: _quantity,
        specialNotes: _notesController.text,
        createdAt: DateTime.now(),
      );

      await CustomOrderRepository.submitCustomOrder(customOrder);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Vision submitted! We will reach out soon.'),
            backgroundColor: AppTheme.successGreen,
          ),
        );
        _clearForm();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Submission failed: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  void _clearForm() {
    _nameController.clear();
    _phoneController.clear();
    _sizeController.clear();
    _glazeController.clear();
    _notesController.clear();
    setState(() {
      _selectedType = 'Bowl';
      _quantity = 1;
    });
  }

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
                      constraints: const BoxConstraints(maxWidth: 900),
                      padding: EdgeInsets.all(isDesktop ? 80 : 32),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(32),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.04),
                            blurRadius: 40,
                            offset: const Offset(0, 20),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("Commission a Piece", style: AppTheme.serifHeadingLarge),
                          const SizedBox(height: 16),
                          Text(
                            "Share your vision with us. Our artisans will bring it to life using traditional techniques and bespoke glazes.",
                            style: GoogleFonts.jost(
                              color: AppTheme.textLight,
                              height: 1.8,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 60),
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
      height: 400,
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
              Colors.black.withOpacity(0.7),
              Colors.transparent,
            ],
          ),
        ),
        padding: EdgeInsets.all(isDesktop ? 80 : 32),
        alignment: Alignment.bottomLeft,
        child: Text(
          "Bespoke Creations",
          style: GoogleFonts.playfairDisplay(
            fontSize: isDesktop ? 56 : 36,
            fontWeight: FontWeight.bold,
            color: Colors.white,
            letterSpacing: 1,
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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildLabel("Product Type"),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    decoration: BoxDecoration(
                      border: Border.all(color: AppTheme.divider, width: 1.5),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _selectedType,
                        isExpanded: true,
                        style: AppTheme.bodyMedium,
                        borderRadius: BorderRadius.circular(12),
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
                ],
              ),
            ),
            const SizedBox(width: 32),
            Expanded(
              flex: 1,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildLabel("Quantity"),
                  const SizedBox(height: 12),
                  _buildQtyCounter(),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 40),
        Row(
          children: [
            Expanded(child: _FormTextField(label: "Size / Dimensions", hint: "e.g. 20cm diameter", controller: _sizeController)),
            const SizedBox(width: 32),
            Expanded(child: _FormTextField(label: "Glaze Preference", hint: "e.g. Ash glaze, Earth tones", controller: _glazeController)),
          ],
        ),
        const SizedBox(height: 40),
        _buildLabel("Special Vision"),
        const SizedBox(height: 12),
        TextField(
          controller: _notesController,
          maxLines: 5,
          decoration: AppTheme.inputDecoration(
            label: "Vision Notes",
            hint: "Describe shapes, patterns, or specific utilitarian needs...",
          ),
          style: AppTheme.bodyMedium,
        ),
        const SizedBox(height: 60),
        const Divider(),
        const SizedBox(height: 60),
        Text("Personal Details", style: AppTheme.serifHeadingMedium),
        const SizedBox(height: 40),
        _FormTextField(label: "Your Full Name", controller: _nameController),
        const SizedBox(height: 24),
        Row(
          children: [
            Expanded(child: _FormTextField(label: "Email Address", controller: _emailController)),
            const SizedBox(width: 32),
            Expanded(child: _FormTextField(label: "Phone Number", controller: _phoneController)),
          ],
        ),
        const SizedBox(height: 60),
        SizedBox(
          width: double.infinity,
          height: 64,
          child: ElevatedButton(
            onPressed: _isSubmitting ? null : _handleSubmit,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.terracotta,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              elevation: 0,
            ),
            child: _isSubmitting
                ? const SizedBox(
                    height: 24,
                    width: 24,
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                  )
                : Text(
                    "SUBMIT COMMISSION REQUEST",
                    style: GoogleFonts.jost(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2.5,
                    ),
                  ),
          ),
        ),
        const SizedBox(height: 32),
        Center(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.history_toggle_off, size: 16, color: AppTheme.textLight),
              const SizedBox(width: 12),
              Text(
                "Our artisans typically respond within 2-3 working days",
                style: GoogleFonts.jost(
                  fontSize: 13,
                  color: AppTheme.textLight,
                  fontStyle: FontStyle.italic,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLabel(String label) {
    return Text(
      label,
      style: GoogleFonts.jost(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: AppTheme.textLight,
        letterSpacing: 1,
      ),
    );
  }

  Widget _buildQtyCounter() {
    return Container(
      height: 52,
      decoration: BoxDecoration(
        border: Border.all(color: AppTheme.divider, width: 1.5),
        borderRadius: BorderRadius.circular(12),
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
            style: GoogleFonts.jost(fontWeight: FontWeight.w600, fontSize: 16),
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
  final TextEditingController controller;
  
  const _FormTextField({
    required this.label, 
    this.hint, 
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.jost(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppTheme.textLight,
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: controller,
          decoration: AppTheme.inputDecoration(label: "", hint: hint),
          style: AppTheme.bodyMedium,
        ),
      ],
    );
  }
}
