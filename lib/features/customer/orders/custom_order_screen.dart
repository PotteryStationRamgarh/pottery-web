import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:typed_data';
import '../../../app/routes.dart';
import '../../../core/services/auth_gate_service.dart';
import '../../../core/repositories/custom_products_config_repository.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/repositories/custom_order_repository.dart';
import '../../../models/custom_order_model.dart';
import '../../../models/custom_products_config.dart';
import '../../admin/catalog/widgets/image_upload_widget.dart';
import '../home/home_footer.dart';
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
  final _notesController = TextEditingController();

  String _selectedType = 'Bowl';
  String _selectedGlaze = 'Natural Matte';
  int _quantity = 1;
  bool _isSubmitting = false;
  Uint8List? _inspirationImageBytes;
  bool _isLoadingConfig = true;
  late CustomProductsConfig _config;

  List<String> get _productTypes => _config.productTypes;
  List<String> get _glazeOptions => _config.glazeOptions;

  @override
  void initState() {
    super.initState();
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      _emailController.text = user.email ?? '';
    }
    _loadConfig();
  }

  Future<void> _loadConfig() async {
    final config = await CustomProductsConfigRepository.getConfig();
    final productTypes = config.productTypes.isEmpty
        ? CustomProductsConfig.fromMap(null).productTypes
        : config.productTypes;
    final glazeOptions = config.glazeOptions.isEmpty
        ? CustomProductsConfig.fromMap(null).glazeOptions
        : config.glazeOptions;
    if (!mounted) return;
    setState(() {
      _config = CustomProductsConfig(
        heroImageUrl: config.heroImageUrl,
        heroTitle: config.heroTitle,
        heroSubtitle: config.heroSubtitle,
        glazeOptions: glazeOptions,
        productTypes: productTypes,
        introText: config.introText,
        isEnabled: config.isEnabled,
      );
      _selectedType = productTypes.first;
      _selectedGlaze = glazeOptions.first;
      _isLoadingConfig = false;
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _sizeController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      AuthGateService.requireLogin(context, routeName: Routes.customOrder);
      return;
    }

    if (_nameController.text.isEmpty || _emailController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          behavior: SnackBarBehavior.floating,
          duration: Duration(seconds: 2),
          content: Text('Please provide your name and email'),
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final customOrder = CustomOrderModel(
        id: '',
        userId: user.uid,
        name: _nameController.text,
        email: _emailController.text,
        phone: _phoneController.text,
        productType: _selectedType,
        size: _sizeController.text,
        glazePreference: _selectedGlaze,
        glazeFinish: _selectedGlaze,
        quantity: _quantity,
        specialNotes: _notesController.text,
        createdAt: DateTime.now(),
      );

      await CustomOrderRepository.submitCustomOrderWithImage(
        customOrder,
        inspirationImageBytes: _inspirationImageBytes,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            behavior: SnackBarBehavior.floating,
            duration: Duration(seconds: 2),
            content: Text('Custom product request submitted successfully.'),
            backgroundColor: AppTheme.successGreen,
          ),
        );
        _clearForm();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 2),
            content: Text('Submission failed: $e'),
          ),
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
    _notesController.clear();
    setState(() {
      _selectedType = 'Bowl';
      if (_productTypes.isNotEmpty) {
        _selectedType = _productTypes.first;
      }
      _selectedGlaze = _glazeOptions.first;
      _quantity = 1;
      _inspirationImageBytes = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth > 900;

    return Scaffold(
      backgroundColor: AppTheme.background,
      endDrawer: const NavDrawer(),
      body: _isLoadingConfig
          ? const Center(child: CircularProgressIndicator())
          : Stack(
              children: [
                SingleChildScrollView(
                  child: Column(
                    children: [
                      const SizedBox(height: 72),
                      _buildHeader(isDesktop),
                      Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: isDesktop ? 48 : 18,
                          vertical: isDesktop ? 60 : 28,
                        ),
                        child: Center(
                          child: Container(
                            constraints: const BoxConstraints(maxWidth: 900),
                            padding: EdgeInsets.all(isDesktop ? 80 : 24),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(32),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.04),
                                  blurRadius: 40,
                                  offset: const Offset(0, 20),
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "Commission a Piece",
                                  style: AppTheme.serifHeadingLarge,
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  _config.introText,
                                  style: GoogleFonts.jost(
                                    color: AppTheme.textLight,
                                    height: 1.8,
                                    fontSize: 16,
                                  ),
                                ),
                                if (FirebaseAuth.instance.currentUser ==
                                    null) ...[
                                  const SizedBox(height: 16),
                                  OutlinedButton.icon(
                                    onPressed: () =>
                                        AuthGateService.requireLogin(
                                          context,
                                          routeName: Routes.customOrder,
                                        ),
                                    icon: const Icon(Icons.login),
                                    label: const Text(
                                      'LOGIN TO SUBMIT THIS REQUEST',
                                    ),
                                  ),
                                ],
                                const SizedBox(height: 60),
                                _buildForm(),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const HomeFooter(),
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
      decoration: BoxDecoration(
        image: DecorationImage(
          image: NetworkImage(_config.heroImageUrl),
          fit: BoxFit.cover,
        ),
      ),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.bottomCenter,
            end: Alignment.topCenter,
            colors: [Colors.black.withValues(alpha: 0.7), Colors.transparent],
          ),
        ),
        padding: EdgeInsets.all(isDesktop ? 80 : 32),
        alignment: Alignment.bottomLeft,
        child: Text(
          _config.heroTitle,
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
        LayoutBuilder(
          builder: (context, constraints) {
            final isCompact = constraints.maxWidth < 720;
            final children = [
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
                          onChanged: (val) {
                            if (val != null) {
                              setState(() => _selectedType = val);
                            }
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(width: isCompact ? 0 : 32, height: isCompact ? 24 : 0),
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
            ];

            return isCompact
                ? Column(children: children)
                : Row(children: children);
          },
        ),
        const SizedBox(height: 40),
        LayoutBuilder(
          builder: (context, constraints) {
            final isCompact = constraints.maxWidth < 720;
            final children = [
              Expanded(
                child: _FormTextField(
                  label: "Size / Dimensions",
                  hint: "e.g. 20cm diameter",
                  controller: _sizeController,
                ),
              ),
              SizedBox(width: isCompact ? 0 : 32, height: isCompact ? 24 : 0),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildLabel("Glaze Preference"),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      decoration: BoxDecoration(
                        border: Border.all(color: AppTheme.divider, width: 1.5),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _selectedGlaze,
                          isExpanded: true,
                          style: AppTheme.bodyMedium,
                          items: _glazeOptions
                              .map(
                                (glaze) => DropdownMenuItem(
                                  value: glaze,
                                  child: Text(glaze),
                                ),
                              )
                              .toList(),
                          onChanged: (value) {
                            if (value != null) {
                              setState(() => _selectedGlaze = value);
                            }
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ];

            return isCompact
                ? Column(children: children)
                : Row(children: children);
          },
        ),
        const SizedBox(height: 40),
        _buildLabel("Inspiration Image"),
        const SizedBox(height: 12),
        ImageUploadWidget(
          title: 'Reference Image',
          multiple: false,
          minHeight: 220,
          onImagesSelected: (images) {
            setState(() {
              _inspirationImageBytes = images.isEmpty ? null : images.first;
            });
          },
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
        LayoutBuilder(
          builder: (context, constraints) {
            final isCompact = constraints.maxWidth < 720;
            final children = [
              Expanded(
                child: _FormTextField(
                  label: "Email Address",
                  controller: _emailController,
                ),
              ),
              SizedBox(width: isCompact ? 0 : 32, height: isCompact ? 24 : 0),
              Expanded(
                child: _FormTextField(
                  label: "Phone Number",
                  controller: _phoneController,
                ),
              ),
            ];
            return isCompact
                ? Column(children: children)
                : Row(children: children);
          },
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
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 0,
            ),
            child: _isSubmitting
                ? const SizedBox(
                    height: 24,
                    width: 24,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
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
              if (_quantity > 1) {
                setState(() => _quantity--);
              }
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
