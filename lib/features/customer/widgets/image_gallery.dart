import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_theme.dart';

/// ImageGallery — full screen swipeable image gallery overlay.
/// Opens when user taps a product image anywhere in the app.
///
/// Features:
/// - Swipe left/right to navigate images
/// - Keyboard arrow keys also work (great for desktop/web)
/// - Escape key closes the gallery
/// - Dot indicators at bottom show current position
/// - Left/right arrow buttons for mouse users
/// - Image counter top left (1 / 3 etc.)
///
/// Usage — call this static method from anywhere:
///   ImageGallery.show(
///     context,
///     images: product.imageUrls,
///     title: product.title,
///   );
class ImageGallery extends StatefulWidget {
  final List<String> images;
  final String title;
  final int initialIndex;

  const ImageGallery({
    super.key,
    required this.images,
    required this.title,
    this.initialIndex = 0,
  });

  /// Static helper — call this instead of using showDialog directly.
  /// Keeps all dialog setup in one place.
  static Future<void> show(
    BuildContext context, {
    required List<String> images,
    required String title,
    int initialIndex = 0,
  }) {
    return showDialog(
      context: context,
      // Nearly black background — keeps focus on image
      barrierColor: Colors.black.withValues(alpha: 0.93),
      builder: (_) => ImageGallery(
        images: images,
        title: title,
        initialIndex: initialIndex,
      ),
    );
  }

  @override
  State<ImageGallery> createState() => _ImageGalleryState();
}

class _ImageGalleryState extends State<ImageGallery> {
  late PageController _pageController;
  late int _currentIndex;
  late FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
    _focusNode = FocusNode();

    // Auto focus so keyboard navigation works immediately on open
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

  // ─────────────────────────────────────────
  // NAVIGATION
  // ─────────────────────────────────────────

  void _prev() {
    if (_currentIndex > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOut,
      );
    }
  }

  void _next() {
    if (_currentIndex < widget.images.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOut,
      );
    }
  }

  // ─────────────────────────────────────────
  // BUILD
  // ─────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return KeyboardListener(
      focusNode: _focusNode,
      // Handle keyboard events — arrow keys and escape
      onKeyEvent: (event) {
        if (event is KeyDownEvent) {
          if (event.logicalKey == LogicalKeyboardKey.arrowLeft) _prev();
          if (event.logicalKey == LogicalKeyboardKey.arrowRight) _next();
          if (event.logicalKey == LogicalKeyboardKey.escape) {
            Navigator.pop(context);
          }
        }
      },
      child: Material(
        color: Colors.transparent,
        child: Stack(
          children: [
            // ── Main swipeable image pages ──
            PageView.builder(
              controller: _pageController,
              itemCount: widget.images.length,
              onPageChanged: (index) {
                setState(() => _currentIndex = index);
              },
              itemBuilder: (context, index) {
                return Center(
                  child: Padding(
                    // Padding keeps image away from arrows and screen edges
                    padding: const EdgeInsets.symmetric(
                      horizontal: 80,
                      vertical: 80,
                    ),
                    child: Image.network(
                      widget.images[index],
                      fit: BoxFit.contain,
                      // Loading state while image downloads
                      loadingBuilder: (context, child, progress) {
                        if (progress == null) return child;
                        return Center(
                          child: SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 1.5,
                              color: AppTheme.lightBrown.withValues(alpha: 0.5),
                            ),
                          ),
                        );
                      },
                      // Error state if image fails
                      errorBuilder: (_, _, _) => Icon(
                        Icons.broken_image_outlined,
                        size: 48,
                        color: Colors.white.withValues(alpha: 0.25),
                      ),
                    ),
                  ),
                );
              },
            ),

            // ── Close button — top right ──
            Positioned(
              top: 20,
              right: 20,
              child: IconButton(
                onPressed: () {
                  // Dialogs should always pop to close.
                  Navigator.of(context).pop();
                },
                icon: const Icon(Icons.close, color: Colors.white, size: 24),
                style: IconButton.styleFrom(
                  backgroundColor: Colors.white.withValues(alpha: 0.1),
                  shape: const CircleBorder(),
                ),
              ),
            ),

            // ── Title + counter — top left ──
            Positioned(
              top: 28,
              left: 28,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Product title
                  Text(
                    widget.title,
                    style: GoogleFonts.playfairDisplay(
                      fontSize: 17,
                      fontWeight: FontWeight.w500,
                      color: Colors.white.withValues(alpha: 0.88),
                    ),
                  ),
                  // Counter — only show if more than one image
                  if (widget.images.length > 1)
                    Text(
                      '${_currentIndex + 1} / ${widget.images.length}',
                      style: GoogleFonts.jost(
                        fontSize: 12,
                        color: Colors.white.withValues(alpha: 0.45),
                        letterSpacing: 1,
                      ),
                    ),
                ],
              ),
            ),

            // ── Left arrow — only show if not on first image ──
            if (widget.images.length > 1 && _currentIndex > 0)
              Positioned(
                left: 16,
                top: 0,
                bottom: 0,
                child: Center(
                  child: IconButton(
                    onPressed: _prev,
                    icon: const Icon(
                      Icons.arrow_back_ios_new,
                      color: Colors.white,
                      size: 20,
                    ),
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.white.withValues(alpha: 0.1),
                      shape: const CircleBorder(),
                    ),
                  ),
                ),
              ),

            // ── Right arrow — only show if not on last image ──
            if (widget.images.length > 1 &&
                _currentIndex < widget.images.length - 1)
              Positioned(
                right: 16,
                top: 0,
                bottom: 0,
                child: Center(
                  child: IconButton(
                    onPressed: _next,
                    icon: const Icon(
                      Icons.arrow_forward_ios,
                      color: Colors.white,
                      size: 20,
                    ),
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.white.withValues(alpha: 0.1),
                      shape: const CircleBorder(),
                    ),
                  ),
                ),
              ),

            // ── Dot indicators — bottom center ──
            // Only show if more than one image
            if (widget.images.length > 1)
              Positioned(
                bottom: 28,
                left: 0,
                right: 0,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    widget.images.length,
                    (index) => AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      margin: const EdgeInsets.symmetric(horizontal: 3),
                      // Active dot is wider — pill shape
                      width: index == _currentIndex ? 20 : 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: index == _currentIndex
                            ? Colors.white
                            : Colors.white.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
