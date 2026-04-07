import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_theme.dart';
import '../home/widgets/nav_bar.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  final List<Map<String, dynamic>> _dummyItems = [
    {
      'id': '1',
      'name': 'Terracotta Vase',
      'desc': 'Series 04 • Limited Edition',
      'price': 4500,
      'qty': 1,
      'image': 'https://images.unsplash.com/photo-1578749556568-bc2c40e68b61?q=80&w=200&auto=format&fit=crop',
      'checked': true,
    },
    {
      'id': '2',
      'name': 'Minimalist Mug',
      'desc': 'Ash glaze • Hand-thrown',
      'price': 1200,
      'qty': 2,
      'image': 'https://images.unsplash.com/photo-1574362848149-11496d93a7c7?q=80&w=200&auto=format&fit=crop',
      'checked': true,
    },
    {
      'id': '3',
      'name': 'Rustic Bowl',
      'desc': 'Earth tones • Large',
      'price': 2800,
      'qty': 1,
      'image': 'https://images.unsplash.com/photo-1593150501174-d9a042d15c39?q=80&w=200&auto=format&fit=crop',
      'checked': false,
    },
  ];

  String _pincode = "";
  String _pincodeStatus = ""; // "Checking...", "Delivery available ✓", "Not serviceable ✗"

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth > 1000;

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
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Your Collection", style: AppTheme.serifHeadingLarge),
                      const SizedBox(height: 8),
                      Text(
                        "${_dummyItems.length} items in your curation",
                        style: GoogleFonts.jost(color: AppTheme.textLight),
                      ),
                      const SizedBox(height: 48),
                      if (isDesktop)
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(flex: 3, child: _buildCartItems()),
                            const SizedBox(width: 60),
                            Expanded(flex: 2, child: _buildCheckoutPanel()),
                          ],
                        )
                      else
                        Column(
                          children: [
                            _buildCartItems(),
                            const SizedBox(height: 48),
                            _buildCheckoutPanel(),
                          ],
                        ),
                    ],
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

  Widget _buildCartItems() {
    return Column(
      children: [
        ..._dummyItems.map((item) => _buildCartItem(item)).toList(),
        const SizedBox(height: 32),
        _buildGiftingCard(),
      ],
    );
  }

  Widget _buildCartItem(Map<String, dynamic> item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Checkbox(
            value: item['checked'],
            activeColor: AppTheme.terracotta,
            onChanged: (val) {
              setState(() => item['checked'] = val);
            },
          ),
          const SizedBox(width: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.network(
              item['image'],
              width: 80,
              height: 80,
              fit: BoxFit.cover,
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item['name'], style: AppTheme.headingMedium),
                const SizedBox(height: 4),
                Text(item['desc'], style: AppTheme.bodySmall),
                const SizedBox(height: 12),
                Text(
                  "₹${item['price']}",
                  style: GoogleFonts.jost(
                    fontWeight: FontWeight.w600,
                    color: AppTheme.terracotta,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              IconButton(
                icon: const Icon(Icons.close, size: 18, color: Colors.grey),
                onPressed: () {
                  // TODO: Remove item
                },
              ),
              _buildQtyStepper(item),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQtyStepper(Map<String, dynamic> item) {
    return Row(
      children: [
        _stepperButton(Icons.remove, () {
          if (item['qty'] > 1) setState(() => item['qty']--);
        }),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text(
            "${item['qty']}",
            style: GoogleFonts.jost(fontWeight: FontWeight.w600),
          ),
        ),
        _stepperButton(Icons.add, () {
          setState(() => item['qty']++);
        }),
      ],
    );
  }

  Widget _stepperButton(IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          border: Border.all(color: AppTheme.divider),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Icon(icon, size: 14, color: AppTheme.textDark),
      ),
    );
  }

  Widget _buildGiftingCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppTheme.exhibitionBackground,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.card_giftcard, size: 20, color: AppTheme.terracotta),
              const SizedBox(width: 12),
              Text("Curated Gifting", style: AppTheme.headingMedium),
            ],
          ),
          const SizedBox(height: 16),
          TextField(
            maxLines: 2,
            decoration: AppTheme.inputDecoration(
              label: "Gift Note (Optional)",
              hint: "Write a message for your loved ones...",
            ),
            style: AppTheme.bodyMedium,
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              const Icon(Icons.info_outline, size: 14, color: AppTheme.textLight),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  "All orders include a hand-stamped linen dust bag.",
                  style: GoogleFonts.jost(fontSize: 12, color: AppTheme.textLight),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCheckoutPanel() {
    double subtotal = _dummyItems
        .where((item) => item['checked'])
        .fold(0, (sum, item) => sum + (item['price'] * item['qty']));
    double delivery = subtotal > 0 ? 250 : 0;
    double total = subtotal + delivery;

    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Acquisition Details", style: AppTheme.serifHeadingMedium),
          const SizedBox(height: 24),
          _buildAddressSection(),
          const SizedBox(height: 32),
          _buildPaymentSection(),
          const SizedBox(height: 32),
          const Divider(),
          const SizedBox(height: 24),
          _buildSummaryRow("Subtotal", "₹$subtotal"),
          _buildSummaryRow("Delivery Charges", "₹$delivery"),
          const SizedBox(height: 12),
          _buildSummaryRow("Total", "₹$total", isTotal: true),
          const SizedBox(height: 32),
          _buildCompletePurchaseButton(),
          const SizedBox(height: 16),
          Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.lock_outline, size: 14, color: AppTheme.textLight),
                const SizedBox(width: 6),
                Text(
                  "Secure Transaction",
                  style: GoogleFonts.jost(fontSize: 12, color: AppTheme.textLight),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAddressSection() {
    bool hasAddress = false; // Dummy check
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text("Shipping To", style: AppTheme.bodyLarge.copyWith(fontWeight: FontWeight.w600)),
            TextButton(
              onPressed: () {
                // TODO: Change address
              },
              child: Text(
                hasAddress ? "Change" : "Add Address",
                style: GoogleFonts.jost(fontSize: 12, color: AppTheme.terracotta),
              ),
            ),
          ],
        ),
        if (!hasAddress) ...[
          const SizedBox(height: 8),
          _buildAddressForm(),
        ] else
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              "Manas S., 123 Artisan Lane, Ramgarh, Uttarakhand - 263132",
              style: AppTheme.bodyMedium,
            ),
          ),
      ],
    );
  }

  Widget _buildAddressForm() {
    return Column(
      children: [
        TextField(
          decoration: AppTheme.inputDecoration(label: "Full Name"),
          style: AppTheme.bodyMedium,
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: TextField(
                decoration: AppTheme.inputDecoration(label: "Pincode"),
                onChanged: (val) {
                  setState(() {
                    _pincode = val;
                    if (val.length == 6) {
                      _pincodeStatus = "Checking delivery...";
                      Future.delayed(const Duration(seconds: 1), () {
                        setState(() => _pincodeStatus = "Delivery available ✓");
                      });
                    } else {
                      _pincodeStatus = "";
                    }
                  });
                },
              ),
            ),
            if (_pincodeStatus.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(left: 12),
                child: Text(
                  _pincodeStatus,
                  style: GoogleFonts.jost(
                    fontSize: 11,
                    color: _pincodeStatus.contains("available") ? Colors.green : Colors.orange,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 12),
        TextField(
          decoration: AppTheme.inputDecoration(label: "Street Address"),
          style: AppTheme.bodyMedium,
        ),
      ],
    );
  }

  int _selectedPayment = 0; // 0: Card, 1: UPI, 2: Net Banking
  Widget _buildPaymentSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("Payment Method", style: AppTheme.bodyLarge.copyWith(fontWeight: FontWeight.w600)),
        const SizedBox(height: 16),
        Row(
          children: [
            _paymentPill(0, "Card"),
            const SizedBox(width: 8),
            _paymentPill(1, "UPI"),
            const SizedBox(width: 8),
            _paymentPill(2, "Bank"),
          ],
        ),
      ],
    );
  }

  Widget _paymentPill(int index, String label) {
    bool isSelected = _selectedPayment == index;
    return GestureDetector(
      onTap: () => setState(() => _selectedPayment = index),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.terracotta : Colors.transparent,
          border: Border.all(color: isSelected ? AppTheme.terracotta : AppTheme.divider),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: GoogleFonts.jost(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: isSelected ? Colors.white : AppTheme.textDark,
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value, {bool isTotal = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: isTotal
                ? AppTheme.headingMedium
                : GoogleFonts.jost(color: AppTheme.textLight),
          ),
          Text(
            value,
            style: isTotal
                ? GoogleFonts.jost(fontSize: 22, fontWeight: FontWeight.bold, color: AppTheme.terracotta)
                : GoogleFonts.jost(fontWeight: FontWeight.w600, color: AppTheme.textDark),
          ),
        ],
      ),
    );
  }

  Widget _buildCompletePurchaseButton() {
    return InkWell(
      onTap: () {
        // TODO: Complete purchase
      },
      child: Container(
        height: 56,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: AppTheme.terracotta,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          "COMPLETE PURCHASE",
          style: GoogleFonts.jost(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            letterSpacing: 1.5,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}
