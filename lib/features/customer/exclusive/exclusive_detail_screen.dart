import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../app/routes.dart';
import '../../../core/theme/app_theme.dart';
import '../../../models/product.dart';
import '../home/widgets/nav_bar.dart';
import '../home/home_footer.dart';

class ExclusiveDetailScreen extends StatefulWidget {
  final ExclusiveProduct product;
  const ExclusiveDetailScreen({super.key, required this.product});

  @override
  State<ExclusiveDetailScreen> createState() => _ExclusiveDetailScreenState();
}

class _ExclusiveDetailScreenState extends State<ExclusiveDetailScreen> {
  int _activeImageIndex = 0;

  @override
  Widget build(BuildContext context) {
    final List<String> allImages = widget.product.imageUrls.isNotEmpty 
        ? List<String>.from(widget.product.imageUrls) 
        : (widget.product.primaryImage.isNotEmpty ? [widget.product.primaryImage] : []);
    final isMobile = MediaQuery.of(context).size.width < 768;

    return Scaffold(
      backgroundColor: AppTheme.background,
      endDrawer: const NavDrawer(),
      body: Stack(
        children: [
          SingleChildScrollView(
            child: Column(
              children: [
                const SizedBox(height: 80), // Spacing for NavBar

                // Main Content
                Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: isMobile ? 24 : MediaQuery.of(context).size.width * 0.1,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Breadcrumb-style navigation (Back button)
                      TextButton.icon(
                        onPressed: () {
                          if (Navigator.canPop(context)) {
                            Navigator.pop(context);
                          } else {
                            Navigator.pushReplacementNamed(context, Routes.customerHome);
                          }
                        },
                        icon: const Icon(Icons.arrow_back, size: 18),
                        label: Text('Back to Home', style: GoogleFonts.jost(fontWeight: FontWeight.w500)),
                        style: TextButton.styleFrom(foregroundColor: AppTheme.textDark),
                      ),
                      const SizedBox(height: 16),

                      // Layout: Images on left (desktop), Info on right
                      isMobile
                          ? _buildMobileLayout(allImages)
                          : _buildDesktopLayout(allImages),

                      const SizedBox(height: 32),
                    ],
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

  Widget _buildDesktopLayout(List<String> allImages) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Image Gallery (Left)
        Expanded(
          flex: 1,
          child: Column(
            children: [
              // Main Image - AspectRatio 1:1 to shrink vertical height
              AspectRatio(
                aspectRatio: 1 / 1, 
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    image: DecorationImage(
                      image: NetworkImage(allImages[_activeImageIndex]),
                      fit: BoxFit.cover,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              // Thumbnails
              if (allImages.length > 1)
                SizedBox(
                  height: 80,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: allImages.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 12),
                    itemBuilder: (context, index) => GestureDetector(
                      onTap: () => setState(() => _activeImageIndex = index),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: 80,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: _activeImageIndex == index ? AppTheme.primaryBrown : Colors.transparent,
                            width: 2,
                          ),
                          image: DecorationImage(
                            image: NetworkImage(allImages[index]),
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),

        const SizedBox(width: 40),

        // Product Details (Right)
        Expanded(
          flex: 1,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 450),
            child: _buildProductInfo(),
          ),
        ),
      ],
    );
  }

  Widget _buildMobileLayout(List<String> allImages) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Main Image Slider
        AspectRatio(
          aspectRatio: 1 / 1, // Shrink height on mobile too
          child: PageView.builder(
            onPageChanged: (idx) => setState(() => _activeImageIndex = idx),
            itemCount: allImages.length,
            itemBuilder: (context, index) => Container(
              margin: const EdgeInsets.symmetric(horizontal: 4),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                image: DecorationImage(image: NetworkImage(allImages[index]), fit: BoxFit.cover),
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        _buildProductInfo(),
      ],
    );
  }

  Widget _buildProductInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Badge
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          decoration: BoxDecoration(
            color: AppTheme.primaryBrown.withOpacity(0.1),
            borderRadius: BorderRadius.circular(30),
          ),
          child: Text(
            'EXCLUSIVE PIECE',
            style: GoogleFonts.jost(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: AppTheme.primaryBrown,
              letterSpacing: 1.2,
            ),
          ),
        ),
        const SizedBox(height: 12),

        Text(
          widget.product.title,
          style: GoogleFonts.playfairDisplay(
            fontSize: 32,
            fontWeight: FontWeight.w600,
            color: AppTheme.textDark,
          ),
        ),
        const SizedBox(height: 12),

        // Features Grid
        Wrap(
          spacing: 12,
          runSpacing: 8,
          children: [
            _buildFeatureTag(Icons.auto_awesome, 'Handmade'),
            if (widget.product.hasCertificate)
              _buildFeatureTag(Icons.verified_user_outlined, 'Certified'),
          ],
        ),
        const SizedBox(height: 16),

        Text(
          'About this piece',
          style: GoogleFonts.jost(fontSize: 15, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        Text(
          widget.product.description,
          style: AppTheme.bodyLarge.copyWith(height: 1.6, fontSize: 14),
        ),
        const SizedBox(height: 20),

        // Summary Card
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppTheme.divider),
          ),
          child: Column(
            children: [
              _buildSummaryRow('Limited Edition', 'Only ${widget.product.totalPieces} pieces'),
              const Divider(height: 24),
              _buildSummaryRow('Material', widget.product.material.isNotEmpty ? widget.product.material : 'Not available'),
              const Divider(height: 24),
              _buildSummaryRow('Crafting Time', widget.product.craftingTime.isNotEmpty ? widget.product.craftingTime : 'Not available'),
            ],
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildFeatureTag(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        border: Border.all(color: AppTheme.divider),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppTheme.textDark),
          const SizedBox(width: 8),
          Text(label, style: GoogleFonts.jost(fontSize: 12, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: GoogleFonts.jost(color: AppTheme.textLight)),
        Text(value, style: GoogleFonts.jost(fontWeight: FontWeight.w600, color: AppTheme.textDark)),
      ],
    );
  }
}
