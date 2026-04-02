import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../app/routes.dart';
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
  late FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _focusNode = FocusNode();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _prev() {
    if (_currentPage > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOut,
      );
    }
  }

  void _next() {
    final images = widget.product.imageUrls.isNotEmpty 
        ? widget.product.imageUrls 
        : [widget.product.primaryImage];
    if (_currentPage < images.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOut,
      );
    }
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
      body: KeyboardListener(
        focusNode: _focusNode,
        onKeyEvent: (event) {
          if (event is KeyDownEvent) {
            if (event.logicalKey == LogicalKeyboardKey.arrowLeft) _prev();
            if (event.logicalKey == LogicalKeyboardKey.arrowRight) _next();
            if (event.logicalKey == LogicalKeyboardKey.escape) {
              Navigator.pop(context);
            }
          }
        },
        child: Stack(
        children: [
          
          // 1. Immersive Image Carousel
          PageView.builder(
            controller: _pageController,
            physics: const BouncingScrollPhysics(),
            onPageChanged: (index) => setState(() => _currentPage = index),
            itemCount: images.length,
            itemBuilder: (context, index) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 80, horizontal: 24),
                child: InteractiveViewer(
                  minScale: 0.8,
                  maxScale: 2.5,
                  child: Center(
                    child: Hero(
                      tag: 'product_${widget.product.id}_$index',
                      child: Image.network(
                        images[index],
                        fit: BoxFit.contain,
                        // Ensure image doesn't fill entire screen to allow margin
                        alignment: Alignment.center,
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return const Center(
                            child: CircularProgressIndicator(color: AppTheme.lightBrown),
                          );
                        },
                        errorBuilder: (_, __, ___) => const Center(
                          child: Icon(Icons.broken_image_outlined, color: AppTheme.greyPlaceholder, size: 48),
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
                      onPressed: () {
                        if (Navigator.canPop(context)) {
                          Navigator.pop(context);
                        } else {
                          // If no history (e.g. direct link), go to Home
                          Navigator.pushReplacementNamed(context, Routes.customerHome);
                        }
                      },
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

          // 3. Thumbnails — bottom center
          if (images.length > 1)
            Positioned(
              bottom: 40,
              left: 24,
              right: 24,
              child: Center(
                child: SizedBox(
                  height: 60,
                  child: ListView.separated(
                    shrinkWrap: true,
                    scrollDirection: Axis.horizontal,
                    itemCount: images.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 10),
                    itemBuilder: (context, index) => GestureDetector(
                      onTap: () {
                        _pageController.animateToPage(
                          index,
                          duration: const Duration(milliseconds: 350),
                          curve: Curves.easeInOut,
                        );
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        width: 60,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: _currentPage == index ? Colors.white : Colors.white.withOpacity(0.3),
                            width: 2,
                          ),
                          image: DecorationImage(
                            image: NetworkImage(images[index]),
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),

          // 5. Left/Right Arrows
          if (images.length > 1 && _currentPage > 0)
            Positioned(
              left: 16,
              top: 0,
              bottom: 0,
              child: Center(
                child: IconButton(
                  onPressed: _prev,
                  icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20),
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.white.withOpacity(0.1),
                    shape: const CircleBorder(),
                  ),
                ),
              ),
            ),
          if (images.length > 1 && _currentPage < images.length - 1)
            Positioned(
              right: 16,
              top: 0,
              bottom: 0,
              child: Center(
                child: IconButton(
                  onPressed: _next,
                  icon: const Icon(Icons.arrow_forward_ios, color: Colors.white, size: 20),
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.white.withOpacity(0.1),
                    shape: const CircleBorder(),
                  ),
                ),
              ),
            ),
        ],
      ),
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
