import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_theme.dart';
import '../home/widgets/nav_bar.dart';

class ProductDetailScreen extends StatefulWidget {
  const ProductDetailScreen({super.key});

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  int _currentImageIndex = 0;
  final bool _isSoldOut = false; // Toggle to test sold out state

  final List<String> _dummyImages = [
    'https://images.unsplash.com/photo-1578749556568-bc2c40e68b61?q=80&w=1000&auto=format&fit=crop',
    'https://images.unsplash.com/photo-1610701596007-11502861dcfa?q=80&w=1000&auto=format&fit=crop',
    'https://images.unsplash.com/photo-1525857597365-5f6dbff2e36e?q=80&w=1000&auto=format&fit=crop',
    'https://images.unsplash.com/photo-1593150501174-d9a042d15c39?q=80&w=1000&auto=format&fit=crop',
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
                const SizedBox(height: 72), // Height of NavBar
                if (isDesktop)
                  _buildDesktopLayout()
                else
                  _buildMobileLayout(),
                _buildProcessSection(),
                _buildCareInstructions(),
                const SizedBox(height: 80),
              ],
            ),
          ),
          const Positioned(top: 0, left: 0, right: 0, child: NavBar()),
        ],
      ),
    );
  }

  Widget _buildMobileLayout() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildImageGallery(),
        _buildProductInfo(),
      ],
    );
  }

  Widget _buildDesktopLayout() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 48),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(flex: 3, child: _buildImageGallery()),
          const SizedBox(width: 48),
          Expanded(flex: 2, child: _buildProductInfo()),
        ],
      ),
    );
  }

  Widget _buildImageGallery() {
    return Column(
      children: [
        Container(
          height: 500,
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.grey.withOpacity(0.1),
          ),
          child: PageView.builder(
            onPageChanged: (index) => setState(() => _currentImageIndex = index),
            itemCount: _dummyImages.length,
            itemBuilder: (context, index) {
              return Image.network(
                _dummyImages[index],
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) =>
                    const Center(child: Icon(Icons.image, size: 50, color: Colors.grey)),
              );
            },
          ),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(
            _dummyImages.length,
            (index) => Container(
              width: 6,
              height: 6,
              margin: const EdgeInsets.symmetric(horizontal: 4),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _currentImageIndex == index
                    ? AppTheme.terracotta
                    : AppTheme.divider,
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: _dummyImages.asMap().entries.map((entry) {
              return GestureDetector(
                onTap: () => setState(() => _currentImageIndex = entry.key),
                child: Container(
                  width: 60,
                  height: 60,
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: _currentImageIndex == entry.key
                          ? AppTheme.terracotta
                          : Colors.transparent,
                      width: 2,
                    ),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(2),
                    child: Image.network(_dummyImages[entry.key], fit: BoxFit.cover),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildProductInfo() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: AppTheme.divider.withOpacity(0.3),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              "LIMITED EDITION • SERIES 04",
              style: GoogleFonts.jost(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                letterSpacing: 2,
                color: AppTheme.textLight,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            "Earthy Terracotta Vase",
            style: AppTheme.serifHeadingLarge,
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Text(
                "₹4,500",
                style: GoogleFonts.jost(
                  fontSize: 24,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.terracotta,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                "₹5,200",
                style: GoogleFonts.jost(
                  fontSize: 16,
                  color: AppTheme.textLight,
                  decoration: TextDecoration.lineThrough,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            "+ Delivery charges",
            style: GoogleFonts.jost(
              fontSize: 12,
              color: AppTheme.textLight,
              fontStyle: FontStyle.italic,
            ),
          ),
          const SizedBox(height: 16),
          _buildStockIndicator(),
          const SizedBox(height: 24),
          Text(
            "Hand-thrown on the wheel using local Ramgarh clay. This vase features a unique reduction-fired glaze that transitions from deep umber to a soft sand finish.",
            style: AppTheme.bodyLarge.copyWith(height: 1.6),
          ),
          const SizedBox(height: 32),
          _buildSpecsRow(),
          const SizedBox(height: 40),
          Row(
            children: [
              Expanded(
                child: _buildButton(
                  "ADD TO CART",
                  isFilled: true,
                  onPressed: _isSoldOut ? null : () {
                    // TODO: Implement additive to cart
                  },
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildButton(
                  "BUY NOW",
                  isFilled: false,
                  onPressed: _isSoldOut ? null : () {
                    // TODO: Implement buy now
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStockIndicator() {
    int stockCount = 3; // Dummy stock
    if (_isSoldOut) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.grey[200],
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(
          "SOLD OUT",
          style: GoogleFonts.jost(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Colors.grey[600],
          ),
        ),
      );
    }
    if (stockCount <= 5) {
      return Text(
        "Only $stockCount left",
        style: GoogleFonts.jost(
          fontSize: 13,
          fontWeight: FontWeight.w500,
          color: Colors.orange[800],
        ),
      );
    }
    return const SizedBox.shrink();
  }

  Widget _buildSpecsRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _buildSpecItem(Icons.waves, "Clay Type", "Ramgarh Red"),
        _buildSpecItem(Icons.fireplace, "Firing", "1250°C"),
        _buildSpecItem(Icons.square_foot, "Dimensions", "15x22 cm"),
      ],
    );
  }

  Widget _buildSpecItem(IconData icon, String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: AppTheme.textLight),
        const SizedBox(height: 8),
        Text(
          label,
          style: GoogleFonts.jost(
            fontSize: 11,
            color: AppTheme.textLight,
            fontWeight: FontWeight.w500,
          ),
        ),
        Text(
          value,
          style: GoogleFonts.jost(
            fontSize: 13,
            color: AppTheme.textDark,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildButton(String text, {required bool isFilled, VoidCallback? onPressed}) {
    final bool isDisabled = onPressed == null;
    return InkWell(
      onTap: onPressed,
      child: Container(
        height: 54,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isDisabled
              ? Colors.grey[300]
              : (isFilled ? AppTheme.terracotta : Colors.transparent),
          border: Border.all(
            color: isDisabled ? Colors.transparent : AppTheme.terracotta,
            width: 1.5,
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          isDisabled ? "Sold Out" : text,
          style: GoogleFonts.jost(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            letterSpacing: 1.5,
            color: isDisabled
                ? Colors.grey[600]
                : (isFilled ? Colors.white : AppTheme.terracotta),
          ),
        ),
      ),
    );
  }

  Widget _buildProcessSection() {
    return Container(
      width: double.infinity,
      color: AppTheme.exhibitionBackground,
      padding: const EdgeInsets.symmetric(vertical: 80, horizontal: 24),
      child: Column(
        children: [
          Text("The Artist's Process", style: AppTheme.serifHeadingMedium),
          const SizedBox(height: 48),
          LayoutBuilder(builder: (context, constraints) {
            final double cardWidth = (constraints.maxWidth - 48) / (constraints.maxWidth > 800 ? 3 : 1);
            return Wrap(
              spacing: 24,
              runSpacing: 40,
              alignment: WrapAlignment.center,
              children: [
                _buildProcessCard("Sourcing", "Selecting the finest local clay from the Ramgarh riverbeds.", Icons.landscape),
                _buildProcessCard("Wheel", "Slowly throwing and shaping on a manual kick-wheel.", Icons.change_circle_outlined),
                _buildProcessCard("Cure", "Sun-dried for 4 days before double-firing in a traditional kiln.", Icons.wb_sunny_outlined),
              ],
            );
          }),
        ],
      ),
    );
  }

  Widget _buildProcessCard(String title, String desc, IconData icon) {
    return SizedBox(
      width: 280,
      child: Column(
        children: [
          Icon(icon, size: 40, color: AppTheme.terracotta),
          const SizedBox(height: 20),
          Text(title, style: AppTheme.headingMedium),
          const SizedBox(height: 12),
          Text(
            desc,
            textAlign: TextAlign.center,
            style: AppTheme.bodyMedium.copyWith(height: 1.6),
          ),
        ],
      ),
    );
  }

  Widget _buildCareInstructions() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 80, horizontal: 24),
      child: Column(
        children: [
          Text("Care Instructions", style: AppTheme.serifHeadingMedium),
          const SizedBox(height: 40),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: Column(
              children: [
                _buildCareItem(Icons.wash, "Hand wash only with mild soap"),
                _buildCareItem(Icons.waves_rounded, "Not suitable for microwave use"),
                _buildCareItem(Icons.dry_cleaning, "Dry completely before storage"),
                _buildCareItem(Icons.eco, "Natural lead-free food safe glazes"),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCareItem(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Icon(icon, size: 20, color: AppTheme.textLight),
          const SizedBox(width: 16),
          Expanded(
            child: Text(text, style: AppTheme.bodyMedium),
          ),
        ],
      ),
    );
  }
}
