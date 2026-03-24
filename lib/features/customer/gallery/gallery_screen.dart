import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_theme.dart';
import '../../../models/product.dart';

/// GalleryScreen — dedicated page for viewing high-quality product images.
/// Features a slidable carousel and a "Back" button to return to collections.
///
/// Designed to feel immersive and artistic.
class GalleryScreen extends StatefulWidget {
  final Product product;

  const GalleryScreen({
    super.key,
    required this.product,
  });

  @override
  State<GalleryScreen> createState() => _GalleryScreenState();
}

class _GalleryScreenState extends State<GalleryScreen> {
  late PageController _pageController;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final images = widget.product.imageUrls.isNotEmpty 
        ? widget.product.imageUrls 
        : [widget.product.primaryImage];
    
    // Fallback if truly no images exist
    if (images.isEmpty || (images.length == 1 && images[0].isEmpty)) {
      return _buildEmptyState(context);
    }

    return Scaffold(
      backgroundColor: AppTheme.appBackground,
      body: Stack(
        children: [
          
          // 1. Immersive Image Carousel
          PageView.builder(
            controller: _pageController,
            onPageChanged: (index) => setState(() => _currentPage = index),
            itemCount: images.length,
            itemBuilder: (context, index) {
              return InteractiveViewer(
                child: Center(
                  child: Hero(
                    tag: 'product_${widget.product.id}_$index',
                    child: Image.network(
                      images[index],
                      fit: BoxFit.contain,
                      width: double.infinity,
                      height: double.infinity,
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return const Center(
                          child: CircularProgressIndicator(
                            color: AppTheme.lightBrown,
                          ),
                        );
                      },
                      errorBuilder: (_, __, ___) => const Center(
                        child: Icon(
                          Icons.broken_image_outlined,
                          color: AppTheme.greyPlaceholder,
                          size: 48,
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),

          // 2. Top Navigation Bar — Glass effect
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withOpacity(0.5),
                    Colors.black.withOpacity(0.0),
                  ],
                ),
              ),
              child: SafeArea(
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20),
                      onPressed: () => Navigator.pop(context),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.product.title.isNotEmpty ? widget.product.title : 'Gallery',
                            style: GoogleFonts.playfairDisplay(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            'POTTERY STATION RAMGARH',
                            style: GoogleFonts.jost(
                              color: Colors.white70,
                              fontSize: 10,
                              letterSpacing: 2,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // 3. Page Indicators
          if (images.length > 1)
            Positioned(
              bottom: 40,
              left: 0,
              right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(images.length, (index) {
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width:  _currentPage == index ? 24 : 8,
                    height: 8,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(4),
                      color: _currentPage == index 
                          ? AppTheme.lightBrown 
                          : Colors.white.withOpacity(0.3),
                    ),
                  );
                }),
              ),
            ),

          // 4. Instructions Hint
          if (images.length > 1)
            Positioned(
              bottom: 80,
              left: 0,
              right: 0,
              child: Center(
                child: Text(
                  'Swipe to explore',
                  style: GoogleFonts.jost(
                    color: Colors.white.withOpacity(0.4),
                    fontSize: 11,
                    letterSpacing: 1.5,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppTheme.textDark),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Center(
        child: Text(
          'No images available for this product.',
          style: AppTheme.bodyLarge,
        ),
      ),
    );
  }
}
