import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/repositories/address_repository.dart';
import '../../../models/address_model.dart';
import '../home/home_footer.dart';
import '../home/widgets/nav_bar.dart';

class SavedAddressesScreen extends StatefulWidget {
  const SavedAddressesScreen({super.key});

  @override
  State<SavedAddressesScreen> createState() => _SavedAddressesScreenState();
}

class _SavedAddressesScreenState extends State<SavedAddressesScreen> {
  List<AddressModel> _addresses = [];
  bool _isLoading = true;
  final _user = FirebaseAuth.instance.currentUser;

  @override
  void initState() {
    super.initState();
    _loadAddresses();
  }

  Future<void> _loadAddresses() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      if (mounted) setState(() => _isLoading = false);
      return;
    }

    try {
      final addresses = await AddressRepository.getAddressesByUser(user.uid);
      if (mounted) {
        setState(() {
          _addresses = addresses;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading addresses: $e')),
        );
      }
    }
  }

  Future<void> _handleSave(AddressModel address) async {
    try {
      await AddressRepository.saveAddress(address);
      await _loadAddresses();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Address saved successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving address: $e')),
        );
      }
    }
  }

  Future<void> _handleDelete(String id) async {
    try {
      await AddressRepository.deleteAddress(id);
      await _loadAddresses();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Address deleted')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error deleting address: $e')),
        );
      }
    }
  }

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
                const SizedBox(height: 100),
                Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: isDesktop ? 80 : 20,
                    vertical: 40,
                  ),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1000),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            IconButton(
                              icon: const Icon(Icons.arrow_back, size: 20),
                              onPressed: () => Navigator.pop(context),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                            ),
                            const SizedBox(width: 16),
                            Text("Saved Addresses", style: AppTheme.serifHeadingLarge),
                          ],
                        ),
                        const SizedBox(height: 48),
                        if (_isLoading)
                          const Center(
                            child: CircularProgressIndicator(color: AppTheme.terracotta),
                          )
                        else
                          GridView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: isDesktop ? 2 : 1,
                              crossAxisSpacing: 32,
                              mainAxisSpacing: 32,
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
                const HomeFooter(),
              ],
            ),
          ),
          const Positioned(top: 0, left: 0, right: 0, child: NavBar()),
        ],
      ),
    );
  }

  Widget _buildAddressCard(AddressModel addr) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
        border: addr.isDefault ? Border.all(color: AppTheme.terracotta, width: 1.5) : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Text(
                    addr.name,
                    style: GoogleFonts.jost(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                      color: AppTheme.textDark,
                    ),
                  ),
                  if (addr.isDefault) ...[
                    const SizedBox(width: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppTheme.terracotta.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        "DEFAULT",
                        style: GoogleFonts.jost(
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.terracotta,
                        ),
                      ),
                    ),
                  ],
                  if (addr.addressType.isNotEmpty) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppTheme.background,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        addr.addressType.toUpperCase(),
                        style: GoogleFonts.jost(
                          fontSize: 9,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textLight,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit_outlined, size: 18, color: AppTheme.textLight),
                    onPressed: () => _showAddressForm(addr),
                  ),
                  IconButton(
                    icon: Icon(Icons.delete_outline, size: 18, color: AppTheme.errorRed.withOpacity(0.7)),
                    onPressed: () => _handleDelete(addr.id),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            addr.normalizedAddressLine1,
            style: GoogleFonts.jost(color: AppTheme.textDark, height: 1.5),
          ),
          if (addr.addressLine2.isNotEmpty)
            Text(
              addr.addressLine2,
              style: GoogleFonts.jost(color: AppTheme.textDark, height: 1.5),
            ),
          if (addr.landmark.isNotEmpty)
            Text(
              "Near ${addr.landmark}",
              style: GoogleFonts.jost(color: AppTheme.textLight),
            ),
          Text(
            "${addr.city}, ${addr.state} - ${addr.pincode}",
            style: GoogleFonts.jost(color: AppTheme.textLight),
          ),
          const Spacer(),
          Row(
            children: [
              const Icon(Icons.phone_outlined, size: 14, color: AppTheme.textLight),
              const SizedBox(width: 8),
              Text(
                addr.phone,
                style: GoogleFonts.jost(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: AppTheme.textDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.mail_outline, size: 14, color: AppTheme.textLight),
              const SizedBox(width: 8),
              Text(
                _user?.email ?? 'No email',
                style: GoogleFonts.jost(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: AppTheme.textDark,
                ),
              ),
            ],
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
          borderRadius: BorderRadius.circular(20),
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
                color: AppTheme.terracotta.withOpacity(0.08),
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

  void _showAddressForm(AddressModel? address) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => AddressFormSheet(
        address: address,
        onSave: (newAddr) async {
          Navigator.pop(context);
          await _handleSave(newAddr);
        },
      ),
    );
  }
}

class AddressFormSheet extends StatefulWidget {
  final AddressModel? address;
  final Function(AddressModel) onSave;

  const AddressFormSheet({super.key, this.address, required this.onSave});

  @override
  State<AddressFormSheet> createState() => _AddressFormSheetState();
}

class _AddressFormSheetState extends State<AddressFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  late TextEditingController _addressLine1Controller;
  late TextEditingController _addressLine2Controller;
  late TextEditingController _landmarkController;
  late TextEditingController _cityController;
  late TextEditingController _stateController;
  late TextEditingController _pincodeController;
  bool _isDefault = false;
  String _addressType = 'Home';

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.address?.name);
    _phoneController = TextEditingController(text: widget.address?.phone);
    _addressLine1Controller = TextEditingController(
      text: widget.address?.normalizedAddressLine1,
    );
    _addressLine2Controller = TextEditingController(
      text: widget.address?.addressLine2,
    );
    _landmarkController = TextEditingController(text: widget.address?.landmark);
    _cityController = TextEditingController(text: widget.address?.city);
    _stateController = TextEditingController(text: widget.address?.state);
    _pincodeController = TextEditingController(text: widget.address?.pincode);
    _isDefault = widget.address?.isDefault ?? false;
    _addressType = widget.address?.addressType ?? 'Home';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _addressLine1Controller.dispose();
    _addressLine2Controller.dispose();
    _landmarkController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _pincodeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      margin: const EdgeInsets.only(top: 40),
      decoration: const BoxDecoration(
        color: AppTheme.background,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      padding: const EdgeInsets.fromLTRB(32, 16, 32, 32),
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
            widget.address == null ? "Add New Address" : "Edit Address",
            style: AppTheme.serifHeadingMedium,
          ),
          const SizedBox(height: 32),
          Expanded(
            child: SingleChildScrollView(
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    _buildField("Full Name", _nameController, validator: _validateName),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(
                          child: _buildField(
                            "Phone Number",
                            _phoneController,
                            keyboardType: TextInputType.phone,
                            validator: _validatePhone,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildField(
                            "Pincode",
                            _pincodeController,
                            keyboardType: TextInputType.number,
                            validator: _validatePincode,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    _buildField(
                      "House / Flat / Building",
                      _addressLine1Controller,
                      validator: _requiredField('House / Flat / Building'),
                    ),
                    const SizedBox(height: 20),
                    _buildField(
                      "Street / Area / Colony",
                      _addressLine2Controller,
                      validator: _requiredField('Street / Area / Colony'),
                    ),
                    const SizedBox(height: 20),
                    _buildField("Landmark", _landmarkController),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(
                          child: _buildField(
                            "City",
                            _cityController,
                            validator: _requiredField('City'),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildField(
                            "State",
                            _stateController,
                            validator: _requiredField('State'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    DropdownButtonFormField<String>(
                      value: _addressType,
                      decoration: AppTheme.inputDecoration(label: 'Address Type'),
                      items: const ['Home', 'Work', 'Studio']
                          .map(
                            (type) => DropdownMenuItem<String>(
                              value: type,
                              child: Text(type),
                            ),
                          )
                          .toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setState(() => _addressType = value);
                        }
                      },
                    ),
                    const SizedBox(height: 24),
                    SwitchListTile(
                      title: Text(
                        "Set as default address",
                        style: GoogleFonts.jost(fontSize: 14, color: AppTheme.textDark),
                      ),
                      value: _isDefault,
                      activeColor: AppTheme.terracotta,
                      onChanged: (val) => setState(() => _isDefault = val),
                      contentPadding: EdgeInsets.zero,
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            height: 60,
            child: ElevatedButton(
              onPressed: () {
                if (!_formKey.currentState!.validate()) {
                  return;
                }

                final user = FirebaseAuth.instance.currentUser;
                if (user == null) return;

                widget.onSave(AddressModel(
                  id: widget.address?.id ?? '',
                  userId: user.uid,
                  name: _nameController.text.trim(),
                  phone: _phoneController.text.trim(),
                  street: [
                    _addressLine1Controller.text.trim(),
                    _addressLine2Controller.text.trim(),
                  ].where((value) => value.isNotEmpty).join(', '),
                  addressLine1: _addressLine1Controller.text.trim(),
                  addressLine2: _addressLine2Controller.text.trim(),
                  landmark: _landmarkController.text.trim(),
                  city: _cityController.text.trim(),
                  state: _stateController.text.trim(),
                  pincode: _pincodeController.text.trim(),
                  addressType: _addressType,
                  isDefault: _isDefault,
                  createdAt: widget.address?.createdAt ?? DateTime.now(),
                ));
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.terracotta,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 0,
              ),
              child: Text(
                "SAVE ADDRESS",
                style: GoogleFonts.jost(
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildField(
    String label,
    TextEditingController controller, {
    String? Function(String?)? validator,
    TextInputType? keyboardType,
  }) {
    return TextFormField(
      controller: controller,
      validator: validator,
      keyboardType: keyboardType,
      decoration: AppTheme.inputDecoration(label: label),
      style: AppTheme.bodyMedium,
    );
  }

  String? _validateName(String? value) {
    if (value == null || value.trim().length < 2) {
      return 'Enter the recipient name.';
    }
    return null;
  }

  String? _validatePhone(String? value) {
    final digits = value?.replaceAll(RegExp(r'[^0-9]'), '') ?? '';
    if (digits.length != 10) {
      return 'Enter a valid 10-digit phone number.';
    }
    return null;
  }

  String? _validatePincode(String? value) {
    final digits = value?.trim() ?? '';
    if (!RegExp(r'^\d{6}$').hasMatch(digits)) {
      return 'Enter a valid 6-digit pincode.';
    }
    return null;
  }

  String? Function(String?) _requiredField(String label) {
    return (value) {
      if (value == null || value.trim().isEmpty) {
        return '$label is required.';
      }
      return null;
    };
  }
}
