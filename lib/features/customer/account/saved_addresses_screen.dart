import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/repositories/address_repository.dart';
import '../../../models/address_model.dart';
import '../home/home_footer.dart';
import '../home/widgets/nav_bar.dart';
import '../address/add_edit_address_screen.dart';

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
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error loading addresses: $e')));
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
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error saving address: $e')));
      }
    }
  }

  Future<void> _handleDelete(String id) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;
      await AddressRepository.deleteAddress(user.uid, id);
      await _loadAddresses();
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Address deleted')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error deleting address: $e')));
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
                            Text(
                              "Saved Addresses",
                              style: AppTheme.serifHeadingLarge,
                            ),
                          ],
                        ),
                        const SizedBox(height: 48),
                        if (_isLoading)
                          const Center(
                            child: CircularProgressIndicator(
                              color: AppTheme.terracotta,
                            ),
                          )
                        else
                          GridView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            gridDelegate:
                                SliverGridDelegateWithFixedCrossAxisCount(
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
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
        border: addr.isDefault
            ? Border.all(color: AppTheme.terracotta, width: 1.5)
            : null,
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
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.terracotta.withValues(alpha: 0.1),
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
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
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
                    icon: const Icon(
                      Icons.edit_outlined,
                      size: 18,
                      color: AppTheme.textLight,
                    ),
                    onPressed: () => _showAddressForm(addr),
                  ),
                  IconButton(
                    icon: Icon(
                      Icons.delete_outline,
                      size: 18,
                      color: AppTheme.errorRed.withValues(alpha: 0.7),
                    ),
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
              const Icon(
                Icons.phone_outlined,
                size: 14,
                color: AppTheme.textLight,
              ),
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
              const Icon(
                Icons.mail_outline,
                size: 14,
                color: AppTheme.textLight,
              ),
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
                color: AppTheme.terracotta.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.add,
                color: AppTheme.terracotta,
                size: 24,
              ),
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

  void _showAddressForm(AddressModel? address) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddEditAddressScreen(existingAddress: address),
      ),
    );
    if (result == true) {
      _loadAddresses();
    }
  }
}


