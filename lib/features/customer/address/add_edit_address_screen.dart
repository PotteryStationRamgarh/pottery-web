import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import '../../../core/theme/app_theme.dart';
import '../../../models/address_model.dart';
import '../../../core/services/pincode_service.dart';
import '../../../core/services/phone_verification_service.dart';
import '../../../core/repositories/address_repository.dart';

// ─────────────────────────────────────────────────────────────────────────────
// DEBOUNCER
// ─────────────────────────────────────────────────────────────────────────────

class _Debouncer {
  final int milliseconds;
  Timer? _timer;
  _Debouncer({required this.milliseconds});
  void run(VoidCallback action) {
    _timer?.cancel();
    _timer = Timer(Duration(milliseconds: milliseconds), action);
  }
  void dispose() => _timer?.cancel();
}

// ─────────────────────────────────────────────────────────────────────────────
// STATE NOTIFIER
// ─────────────────────────────────────────────────────────────────────────────

class AddressFormNotifier extends ChangeNotifier {
  final String userId;
  final AddressModel? existingAddress;

  String fullName = '';
  String phone = '';
  bool phoneVerified = false;
  String addressLine1 = '';
  String addressLine2 = '';
  String addressLine3 = '';
  String pincode = '';
  String city = '';
  String state = '';
  String addressType = 'Home';
  bool isDefault = false;

  bool isPincodeFetching = false;
  bool isPincodeVerified = false;
  String? pincodeError;
  List<PostOffice>? multiplePostOffices;

  bool isPhoneVerifying = false;
  String? phoneVerificationError;

  AddressFormNotifier({required this.userId, this.existingAddress}) {
    if (existingAddress != null) {
      final a = existingAddress!;
      fullName = a.name;
      phone = a.phone;
      phoneVerified = a.phoneVerified;
      addressLine1 = a.addressLine1;
      addressLine2 = a.addressLine2;
      addressLine3 = a.addressLine3;
      pincode = a.pincode;
      city = a.city;
      state = a.state;
      addressType = a.addressType;
      isDefault = a.isDefault;
      isPincodeVerified = true;
    }
  }

  void setFullName(String v) { fullName = v; notifyListeners(); }
  void setPhone(String v) {
    phone = v;
    if (v != existingAddress?.phone) phoneVerified = false;
    notifyListeners();
  }
  void setAddressLine1(String v) { addressLine1 = v; notifyListeners(); }
  void setAddressLine2(String v) { addressLine2 = v; notifyListeners(); }
  void setAddressLine3(String v) { addressLine3 = v; notifyListeners(); }
  void setAddressType(String v) { addressType = v; notifyListeners(); }
  void setIsDefault(bool v) { isDefault = v; notifyListeners(); }

  // City & state are always editable — user can override auto-fill
  void setCity(String v) { city = v; notifyListeners(); }
  void setState(String v) { state = v; notifyListeners(); }

  void setPincode(String v) {
    pincode = v;
    pincodeError = null;
    isPincodeVerified = false;
    multiplePostOffices = null;
    notifyListeners();
  }

  Future<void> fetchPincodeDetails() async {
    if (pincode.length != 6) {
      pincodeError = 'PIN code must be 6 digits';
      notifyListeners();
      return;
    }
    isPincodeFetching = true;
    pincodeError = null;
    multiplePostOffices = null;
    notifyListeners();

    try {
      final response = await PinCodeService.getPinCodeDetails(pincode);
      if (response != null && response.status == 'Success') {
        if (PinCodeService.hasMultiplePostOffices(response)) {
          multiplePostOffices = response.postOffices;
        } else {
          city = PinCodeService.getCityFromResponse(response) ?? '';
          state = PinCodeService.getStateFromResponse(response) ?? '';
        }
        isPincodeVerified = true;
      } else {
        pincodeError = 'Invalid PIN code or not found';
      }
    } catch (e) {
      pincodeError = 'Error fetching PIN details. Please enter city/state manually.';
    } finally {
      isPincodeFetching = false;
      notifyListeners();
    }
  }

  void selectPostOffice(PostOffice po) {
    city = po.district;
    state = po.state;
    multiplePostOffices = null;
    isPincodeVerified = true;
    notifyListeners();
  }

  void setPhoneVerified(bool value, {String? error}) {
    phoneVerified = value;
    phoneVerificationError = error;
    isPhoneVerifying = false;
    notifyListeners();
  }

  bool isFormValid() =>
      fullName.trim().isNotEmpty &&
      phone.length == 10 &&
      addressLine1.trim().isNotEmpty &&
      pincode.length == 6 &&
      city.trim().isNotEmpty &&
      state.trim().isNotEmpty &&
      phoneVerified;

  Future<void> saveAddress() async {
    final address = AddressModel(
      id: existingAddress?.id ?? '',
      userId: userId,
      name: fullName,
      phone: phone,
      street: '',
      addressLine1: addressLine1,
      addressLine2: addressLine2,
      addressLine3: addressLine3,
      landmark: '',
      city: city,
      state: state,
      pincode: pincode,
      addressType: addressType,
      isDefault: isDefault,
      createdAt: existingAddress?.createdAt,
      phoneVerified: phoneVerified,
    );

    if (existingAddress != null) {
      await AddressRepository.updateAddress(userId, existingAddress!.id, {
        'name': fullName,
        'phone': phone,
        'phoneVerified': phoneVerified,
        'addressLine1': addressLine1,
        'addressLine2': addressLine2,
        'addressLine3': addressLine3,
        'pincode': pincode,
        'city': city,
        'state': state,
        'addressType': addressType,
        'isDefault': isDefault,
        'street': address.composedStreet,
      });
    } else {
      await AddressRepository.saveAddress(address);
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// SCREEN
// ─────────────────────────────────────────────────────────────────────────────

class AddEditAddressScreen extends StatefulWidget {
  final AddressModel? existingAddress;
  const AddEditAddressScreen({super.key, this.existingAddress});

  @override
  State<AddEditAddressScreen> createState() => _AddEditAddressScreenState();
}

class _AddEditAddressScreenState extends State<AddEditAddressScreen> {
  late AddressFormNotifier _notifier;
  final _formKey = GlobalKey<FormState>();
  final _debouncer = _Debouncer(milliseconds: 700);

  // Controllers for auto-filled, but still editable fields
  final _cityCtrl = TextEditingController();
  final _stateCtrl = TextEditingController();
  final _pincodeCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _name1Ctrl = TextEditingController();
  final _addr1Ctrl = TextEditingController();
  final _addr2Ctrl = TextEditingController();
  final _addr3Ctrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    final user = FirebaseAuth.instance.currentUser;
    _notifier = AddressFormNotifier(
      userId: user?.uid ?? '',
      existingAddress: widget.existingAddress,
    );
    // Seed controllers from existing address
    _name1Ctrl.text = _notifier.fullName;
    _phoneCtrl.text = _notifier.phone;
    _addr1Ctrl.text = _notifier.addressLine1;
    _addr2Ctrl.text = _notifier.addressLine2;
    _addr3Ctrl.text = _notifier.addressLine3;
    _pincodeCtrl.text = _notifier.pincode;
    _cityCtrl.text = _notifier.city;
    _stateCtrl.text = _notifier.state;

    _notifier.addListener(_syncAutoFilledControllers);
  }

  // Sync only city & state (auto-filled from PIN) without disrupting cursor
  void _syncAutoFilledControllers() {
    if (_cityCtrl.text != _notifier.city) {
      _cityCtrl.value = TextEditingValue(
        text: _notifier.city,
        selection: TextSelection.collapsed(offset: _notifier.city.length),
      );
    }
    if (_stateCtrl.text != _notifier.state) {
      _stateCtrl.value = TextEditingValue(
        text: _notifier.state,
        selection: TextSelection.collapsed(offset: _notifier.state.length),
      );
    }
  }

  @override
  void dispose() {
    _debouncer.dispose();
    _notifier.removeListener(_syncAutoFilledControllers);
    _notifier.dispose();
    _cityCtrl.dispose();
    _stateCtrl.dispose();
    _pincodeCtrl.dispose();
    _phoneCtrl.dispose();
    _name1Ctrl.dispose();
    _addr1Ctrl.dispose();
    _addr2Ctrl.dispose();
    _addr3Ctrl.dispose();
    super.dispose();
  }

  // ── BUILD ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          widget.existingAddress != null ? 'Edit Address' : 'Add New Address',
          style: AppTheme.headingLarge,
        ),
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: AppTheme.textDark,
        surfaceTintColor: Colors.transparent,
      ),
      body: ChangeNotifierProvider.value(
        value: _notifier,
        child: Consumer<AddressFormNotifier>(
          builder: (context, notifier, _) => Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 720),
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ── Section: Contact Info ─────────────────────────────
                      _sectionHeader('Contact Information'),
                      const SizedBox(height: 16),

                      // Full Name
                      _label('Full Name *'),
                      TextFormField(
                        controller: _name1Ctrl,
                        onChanged: notifier.setFullName,
                        textCapitalization: TextCapitalization.words,
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) return 'Full name is required';
                          if (v.trim().length < 3) return 'Name too short';
                          return null;
                        },
                        decoration: _inputDec(
                          hint: 'Full name of recipient',
                          icon: Icons.person_outline,
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Phone Number
                      _label('Phone Number *'),
                      TextFormField(
                        controller: _phoneCtrl,
                        onChanged: notifier.setPhone,
                        keyboardType: TextInputType.phone,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          LengthLimitingTextInputFormatter(10),
                        ],
                        validator: (v) {
                          if (v == null || v.isEmpty) return 'Phone number is required';
                          if (v.length != 10) return 'Enter a valid 10-digit phone number';
                          return null;
                        },
                        decoration: _inputDec(
                          hint: '10-digit mobile number',
                          icon: Icons.phone_outlined,
                          prefix: '+91 ',
                        ).copyWith(
                          suffixIcon: notifier.phoneVerified
                              ? const Padding(
                                  padding: EdgeInsets.symmetric(horizontal: 12),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.verified_rounded, color: Colors.green, size: 20),
                                      SizedBox(width: 4),
                                      Text('Verified', style: TextStyle(color: Colors.green, fontSize: 12, fontWeight: FontWeight.w600)),
                                    ],
                                  ),
                                )
                              : Padding(
                                  padding: const EdgeInsets.only(right: 8),
                                  child: TextButton(
                                    onPressed: notifier.phone.length == 10
                                        ? () => _showVerificationDialog(context, notifier)
                                        : null,
                                    style: TextButton.styleFrom(
                                      foregroundColor: AppTheme.terracotta,
                                      padding: const EdgeInsets.symmetric(horizontal: 12),
                                      minimumSize: Size.zero,
                                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                    ),
                                    child: Text(
                                      'Verify',
                                      style: GoogleFonts.jost(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        color: notifier.phone.length == 10
                                            ? AppTheme.terracotta
                                            : Colors.grey,
                                      ),
                                    ),
                                  ),
                                ),
                        ),
                      ),
                      if (notifier.phoneVerificationError != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 6, left: 4),
                          child: Text(
                            notifier.phoneVerificationError!,
                            style: const TextStyle(color: Colors.red, fontSize: 12),
                          ),
                        ),
                      const SizedBox(height: 28),

                      // ── Section: Delivery Address ─────────────────────────
                      _sectionHeader('Delivery Address'),
                      const SizedBox(height: 16),

                      // Address Line 1
                      _label('Address Line 1 *'),
                      TextFormField(
                        controller: _addr1Ctrl,
                        onChanged: notifier.setAddressLine1,
                        textCapitalization: TextCapitalization.sentences,
                        validator: (v) => (v == null || v.trim().isEmpty) ? 'Address Line 1 is required' : null,
                        decoration: _inputDec(
                          hint: 'Flat / House No., Building, Street',
                          icon: Icons.home_outlined,
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Address Line 2
                      _label('Address Line 2 (Optional)'),
                      TextFormField(
                        controller: _addr2Ctrl,
                        onChanged: notifier.setAddressLine2,
                        textCapitalization: TextCapitalization.sentences,
                        decoration: _inputDec(
                          hint: 'Area, Colony, Sector',
                          icon: Icons.location_on_outlined,
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Address Line 3
                      _label('Address Line 3 (Optional)'),
                      TextFormField(
                        controller: _addr3Ctrl,
                        onChanged: notifier.setAddressLine3,
                        textCapitalization: TextCapitalization.sentences,
                        decoration: _inputDec(
                          hint: 'Landmark, Near...',
                          icon: Icons.flag_outlined,
                        ),
                      ),
                      const SizedBox(height: 16),

                      // PIN Code
                      _label('PIN Code *'),
                      TextFormField(
                        controller: _pincodeCtrl,
                        onChanged: (v) {
                          notifier.setPincode(v);
                          if (v.length == 6) {
                            _debouncer.run(() => notifier.fetchPincodeDetails());
                          }
                        },
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          LengthLimitingTextInputFormatter(6),
                        ],
                        validator: (v) {
                          if (v == null || v.isEmpty) return 'PIN code is required';
                          if (v.length != 6) return 'PIN must be 6 digits';
                          return null;
                        },
                        decoration: _inputDec(
                          hint: '6-digit Indian PIN code',
                          icon: Icons.pin_drop_outlined,
                        ).copyWith(
                          suffixIcon: notifier.isPincodeFetching
                              ? const Padding(
                                  padding: EdgeInsets.all(14),
                                  child: SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(strokeWidth: 2),
                                  ),
                                )
                              : notifier.isPincodeVerified
                              ? const Icon(Icons.verified_rounded, color: Colors.green, size: 20)
                              : null,
                        ),
                      ),
                      if (notifier.pincodeError != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 6, left: 4),
                          child: Row(
                            children: [
                              const Icon(Icons.info_outline, size: 14, color: Colors.orange),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  notifier.pincodeError!,
                                  style: const TextStyle(color: Colors.orange, fontSize: 12),
                                ),
                              ),
                            ],
                          ),
                        ),

                      // Multiple PO selector
                      if (notifier.multiplePostOffices != null) ...[
                        const SizedBox(height: 14),
                        _label('Select your area:'),
                        Container(
                          decoration: BoxDecoration(
                            border: Border.all(color: AppTheme.divider),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: ListView.separated(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: notifier.multiplePostOffices!.length,
                            separatorBuilder: (_, __) => const Divider(height: 0),
                            itemBuilder: (ctx, i) {
                              final po = notifier.multiplePostOffices![i];
                              return ListTile(
                                dense: true,
                                title: Text(po.name,
                                    style: GoogleFonts.jost(fontSize: 13, fontWeight: FontWeight.w500)),
                                subtitle: Text('${po.district}, ${po.state}',
                                    style: GoogleFonts.jost(fontSize: 11, color: AppTheme.textLight)),
                                trailing: const Icon(Icons.chevron_right, size: 16),
                                onTap: () => notifier.selectPostOffice(po),
                              );
                            },
                          ),
                        ),
                      ],
                      const SizedBox(height: 16),

                      // City & State — always editable but auto-filled from PIN
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _label('City / District *'),
                                TextFormField(
                                  controller: _cityCtrl,
                                  onChanged: notifier.setCity,
                                  textCapitalization: TextCapitalization.words,
                                  validator: (v) => (v == null || v.trim().isEmpty) ? 'City required' : null,
                                  decoration: _inputDec(
                                    hint: 'Auto-filled / Enter city',
                                    icon: Icons.location_city_outlined,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _label('State *'),
                                TextFormField(
                                  controller: _stateCtrl,
                                  onChanged: notifier.setState,
                                  textCapitalization: TextCapitalization.words,
                                  validator: (v) => (v == null || v.trim().isEmpty) ? 'State required' : null,
                                  decoration: _inputDec(
                                    hint: 'Auto-filled / Enter state',
                                    icon: Icons.map_outlined,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      if (notifier.isPincodeVerified)
                        Padding(
                          padding: const EdgeInsets.only(top: 6, left: 4),
                          child: Text(
                            '✓ City & state auto-filled from PIN code — you can edit if needed',
                            style: GoogleFonts.jost(fontSize: 11, color: Colors.green.shade700),
                          ),
                        ),
                      const SizedBox(height: 28),

                      // ── Section: Address Type ─────────────────────────────
                      _sectionHeader('Address Type'),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: ['Home', 'Office', 'Other'].map((type) {
                          final selected = notifier.addressType == type;
                          return ChoiceChip(
                            label: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  type == 'Home' ? Icons.home_outlined
                                      : type == 'Office' ? Icons.business_outlined
                                      : Icons.location_on_outlined,
                                  size: 16,
                                  color: selected ? Colors.white : AppTheme.textDark,
                                ),
                                const SizedBox(width: 6),
                                Text(type),
                              ],
                            ),
                            selected: selected,
                            onSelected: (_) => notifier.setAddressType(type),
                            selectedColor: AppTheme.terracotta,
                            backgroundColor: Colors.grey.shade100,
                            labelStyle: GoogleFonts.jost(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: selected ? Colors.white : AppTheme.textDark,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            side: BorderSide(
                              color: selected ? AppTheme.terracotta : Colors.transparent,
                            ),
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 16),

                      // Default Toggle
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.grey.shade200),
                        ),
                        child: CheckboxListTile(
                          value: notifier.isDefault,
                          onChanged: (v) => notifier.setIsDefault(v ?? false),
                          title: Text('Set as default address', style: GoogleFonts.jost(fontSize: 14)),
                          subtitle: Text(
                            'This will be automatically selected at checkout',
                            style: GoogleFonts.jost(fontSize: 12, color: AppTheme.textLight),
                          ),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                          activeColor: AppTheme.terracotta,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                      const SizedBox(height: 32),

                      // Save Button
                      SizedBox(
                        width: double.infinity,
                        height: 54,
                        child: ElevatedButton(
                          onPressed: notifier.isFormValid()
                              ? () => _saveAddress(context, notifier)
                              : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.terracotta,
                            disabledBackgroundColor: Colors.grey.shade200,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            elevation: 0,
                          ),
                          child: Text(
                            !notifier.phoneVerified
                                ? 'Verify phone to continue'
                                : 'Save Address',
                            style: GoogleFonts.jost(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: notifier.isFormValid() ? Colors.white : Colors.grey,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  Widget _sectionHeader(String text) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        text,
        style: GoogleFonts.jost(
          fontSize: 16,
          fontWeight: FontWeight.w700,
          color: AppTheme.textDark,
        ),
      ),
      const SizedBox(height: 4),
      Container(height: 2, width: 40, color: AppTheme.terracotta),
    ],
  );

  Widget _label(String text) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Text(
      text,
      style: GoogleFonts.jost(fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.textDark),
    ),
  );

  InputDecoration _inputDec({required String hint, IconData? icon, String? prefix}) =>
      InputDecoration(
        hintText: hint,
        hintStyle: GoogleFonts.jost(fontSize: 14, color: Colors.grey.shade400),
        prefixText: prefix,
        prefixStyle: GoogleFonts.jost(fontSize: 14),
        prefixIcon: icon != null ? Icon(icon, size: 20, color: Colors.grey.shade500) : null,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        filled: true,
        fillColor: Colors.grey.shade50,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.grey.shade200),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.grey.shade200),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: AppTheme.terracotta, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Colors.red),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Colors.red, width: 1.5),
        ),
      );

  void _showVerificationDialog(BuildContext context, AddressFormNotifier notifier) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => PhoneVerificationDialog(
        phone: '+91${notifier.phone}',
        onVerificationComplete: () {
          notifier.setPhoneVerified(true);
          if (Navigator.canPop(context)) Navigator.pop(context);
        },
        onError: (error) => notifier.setPhoneVerified(false, error: error),
      ),
    );
  }

  Future<void> _saveAddress(BuildContext context, AddressFormNotifier notifier) async {
    if (!_formKey.currentState!.validate()) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Saving address…')),
    );
    try {
      await notifier.saveAddress();
      if (mounted) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            const SnackBar(
              content: Text('Address saved successfully'),
              backgroundColor: Colors.green,
            ),
          );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
          );
      }
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// PHONE VERIFICATION DIALOG
// ─────────────────────────────────────────────────────────────────────────────

class PhoneVerificationDialog extends StatefulWidget {
  final String phone;
  final VoidCallback onVerificationComplete;
  final Function(String) onError;

  const PhoneVerificationDialog({
    super.key,
    required this.phone,
    required this.onVerificationComplete,
    required this.onError,
  });

  @override
  State<PhoneVerificationDialog> createState() => _PhoneVerificationDialogState();
}

class _PhoneVerificationDialogState extends State<PhoneVerificationDialog> {
  final _otpCtrl = TextEditingController();
  bool _isSending = true;
  bool _isVerifying = false;
  String? _error;
  bool _codeSent = false;
  bool _canResend = false;
  int _resendCountdown = 30;
  Timer? _resendTimer;

  @override
  void initState() {
    super.initState();
    _sendOTP();
  }

  @override
  void dispose() {
    _otpCtrl.dispose();
    _resendTimer?.cancel();
    super.dispose();
  }

  void _startResendCountdown() {
    _canResend = false;
    _resendCountdown = 30;
    _resendTimer?.cancel();
    _resendTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) { t.cancel(); return; }
      setState(() {
        _resendCountdown--;
        if (_resendCountdown <= 0) {
          _canResend = true;
          t.cancel();
        }
      });
    });
  }

  Future<void> _sendOTP() async {
    try {
      setState(() { _isSending = true; _error = null; });
      await PhoneVerificationService.sendOTP(widget.phone);
      if (mounted) {
        setState(() { _codeSent = true; _isSending = false; });
        _startResendCountdown();
      }
    } catch (e) {
      if (mounted) {
        setState(() { _error = _friendlyError(e.toString()); _isSending = false; });
      }
    }
  }

  Future<void> _verifyOTP() async {
    final otp = _otpCtrl.text.trim();
    if (otp.length != 6) {
      setState(() => _error = 'Please enter the 6-digit OTP');
      return;
    }
    setState(() { _isVerifying = true; _error = null; });
    try {
      await PhoneVerificationService.verifyOTP(otp);
      PhoneVerificationService.resetState();
      if (mounted) {
        widget.onVerificationComplete();
      }
    } on FirebaseAuthException catch (e) {
      if (mounted) {
        setState(() { _isVerifying = false; _error = _firebaseErrorMessage(e.code); });
      }
    } catch (e) {
      if (mounted) {
        setState(() { _isVerifying = false; _error = _friendlyError(e.toString()); });
      }
    }
  }

  String _firebaseErrorMessage(String code) {
    switch (code) {
      case 'invalid-verification-code': return 'Incorrect OTP. Please check and try again.';
      case 'code-expired': return 'OTP has expired. Please request a new one.';
      case 'session-expired': return 'Session expired. Please request a new OTP.';
      case 'too-many-requests': return 'Too many attempts. Please try again later.';
      default: return 'Verification failed. Please try again.';
    }
  }

  String _friendlyError(String raw) {
    if (raw.contains('too-many-requests')) return 'Too many attempts. Please try again later.';
    if (raw.contains('invalid-phone')) return 'Invalid phone number format.';
    if (raw.contains('network')) return 'Network error. Check your connection.';
    if (raw.contains('No signed-in user')) return 'Please sign in before verifying your phone.';
    return 'An error occurred. Please try again.';
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 400),
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppTheme.terracotta.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(Icons.phone_android_outlined, color: AppTheme.terracotta, size: 24),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Verify Phone Number',
                            style: GoogleFonts.jost(fontSize: 17, fontWeight: FontWeight.w700, color: AppTheme.textDark)),
                        Text(widget.phone,
                            style: GoogleFonts.jost(fontSize: 13, color: AppTheme.textLight)),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close, size: 20),
                    color: AppTheme.textLight,
                    padding: EdgeInsets.zero,
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Body
              if (_isSending) ...[
                const Center(child: CircularProgressIndicator()),
                const SizedBox(height: 16),
                Center(
                  child: Text(
                    'Sending OTP to ${widget.phone}…',
                    style: GoogleFonts.jost(fontSize: 14, color: AppTheme.textLight),
                    textAlign: TextAlign.center,
                  ),
                ),
              ] else if (_error != null && !_codeSent) ...[
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.red.shade200),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline, color: Colors.red, size: 20),
                      const SizedBox(width: 10),
                      Expanded(child: Text(_error!, style: GoogleFonts.jost(fontSize: 13, color: Colors.red))),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: _sendOTP,
                    icon: const Icon(Icons.refresh, size: 18),
                    label: Text('Try Again', style: GoogleFonts.jost(fontWeight: FontWeight.w600)),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.terracotta,
                      side: BorderSide(color: AppTheme.terracotta),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ] else ...[
                Text(
                  'Enter the 6-digit OTP sent to your number',
                  style: GoogleFonts.jost(fontSize: 13, color: AppTheme.textLight),
                ),
                const SizedBox(height: 16),

                // OTP input
                TextFormField(
                  controller: _otpCtrl,
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.center,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(6),
                  ],
                  style: GoogleFonts.jost(fontSize: 24, fontWeight: FontWeight.w700, letterSpacing: 8),
                  decoration: InputDecoration(
                    hintText: '— — — — — —',
                    hintStyle: GoogleFonts.jost(fontSize: 20, color: Colors.grey.shade300, letterSpacing: 6),
                    filled: true,
                    fillColor: Colors.grey.shade50,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade200)),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade200)),
                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: AppTheme.terracotta, width: 2)),
                    contentPadding: const EdgeInsets.symmetric(vertical: 18),
                  ),
                  onChanged: (v) { if (v.length == 6) _verifyOTP(); },
                ),

                if (_error != null) ...[
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.red.shade200)),
                    child: Row(
                      children: [
                        const Icon(Icons.error_outline, color: Colors.red, size: 16),
                        const SizedBox(width: 8),
                        Expanded(child: Text(_error!, style: GoogleFonts.jost(fontSize: 12, color: Colors.red))),
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: 20),

                // Verify button
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: _isVerifying ? null : _verifyOTP,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.terracotta,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      elevation: 0,
                    ),
                    child: _isVerifying
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : Text('Verify OTP', style: GoogleFonts.jost(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.white)),
                  ),
                ),

                const SizedBox(height: 16),

                // Resend
                Center(
                  child: _canResend
                      ? TextButton.icon(
                          onPressed: () {
                            _otpCtrl.clear();
                            setState(() { _error = null; _codeSent = false; });
                            _sendOTP();
                          },
                          icon: const Icon(Icons.refresh, size: 16),
                          label: Text('Resend OTP', style: GoogleFonts.jost(fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.terracotta)),
                          style: TextButton.styleFrom(foregroundColor: AppTheme.terracotta),
                        )
                      : Text(
                          'Resend OTP in ${_resendCountdown}s',
                          style: GoogleFonts.jost(fontSize: 12, color: AppTheme.textLight),
                        ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
