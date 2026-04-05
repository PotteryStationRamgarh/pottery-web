import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../core/providers/config_provider.dart';
import '../../../core/providers/exhibition_provider.dart';
import '../../../core/repositories/home_repository.dart';
import '../../../core/theme/app_theme.dart';
import '../../../app/routes.dart';

/// Shown immediately after sign-in for customer users.
/// Pre-fetches all Firestore data and precaches every image so the
/// home screen renders instantly with no loading spinners.
class CustomerLoadingScreen extends StatefulWidget {
  const CustomerLoadingScreen({super.key});

  @override
  State<CustomerLoadingScreen> createState() => _CustomerLoadingScreenState();
}

class _CustomerLoadingScreenState extends State<CustomerLoadingScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulse;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadEverything());
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  Future<void> _loadEverything() async {
    try {
      // Step 1: Config (skips if already loaded from splash)
      _setStatus('Loading app config…', 0.1);
      final config = context.read<ConfigProvider>();
      final exhibition = context.read<ExhibitionProvider>();

      await Future.wait([
        if (!config.isLoaded) config.load(),
        if (!exhibition.isLoaded) exhibition.load(),
      ]);

      // Step 2: Fetch products + exclusives in parallel via HomeRepository
      _setStatus('Fetching products…', 0.3);
      await HomeRepository.fetchAll();

      // Step 3: Precache only key above-the-fold images. The rest lazy-load.
      _setStatus('Caching key visuals…', 0.55);
      final imageUrls = <String>[
        if (config.branding.logoUrl.isNotEmpty) config.branding.logoUrl,
        if (config.branding.heroImageUrl.isNotEmpty)
          config.branding.heroImageUrl,
        if (exhibition.exhibition.imageUrl.isNotEmpty)
          exhibition.exhibition.imageUrl,
      ];

      await _precacheImages(imageUrls);

      // Step 4: Navigate
      _setStatus('All set!', 1.0);
      await Future.delayed(const Duration(milliseconds: 120));

      if (mounted) {
        Navigator.pushReplacementNamed(context, Routes.customerHome);
      }
    } catch (e) {
      debugPrint('CustomerLoadingScreen error: $e');
      // Even on error go to home — sections handle their own fallbacks
      if (mounted) {
        Navigator.pushReplacementNamed(context, Routes.customerHome);
      }
    }
  }

  Future<void> _precacheImages(List<String> urls) async {
    if (!mounted) return;
    final total = urls.length;
    if (total == 0) return;

    int done = 0;
    await Future.wait(
      urls.map((url) async {
        try {
          await precacheImage(NetworkImage(url), context);
        } catch (_) {}
        done++;
        if (mounted) {
          _setStatus(
            'Caching key visuals… ($done/$total)',
            0.55 + (done / total) * 0.35,
          );
        }
      }),
    );
  }

  void _setStatus(String text, double progress) {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final config = context.watch<ConfigProvider>();
    final logoUrl = config.branding.logoUrl;

    return Scaffold(
      backgroundColor: AppTheme.appBackground,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (logoUrl.isNotEmpty)
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.network(
                  logoUrl,
                  width: 80,
                  height: 80,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => _textLogo(),
                ),
              )
            else
              _textLogo(),

            const SizedBox(height: 40),

            Text(
              config.branding.appName.isNotEmpty
                  ? config.branding.appName
                  : 'Pottery Station',
              style: GoogleFonts.playfairDisplay(
                fontSize: 28,
                fontWeight: FontWeight.w600,
                color: AppTheme.lightBrown,
                letterSpacing: 1.0,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'RAMGARH',
              style: GoogleFonts.jost(
                fontSize: 11,
                fontWeight: FontWeight.w300,
                color: AppTheme.lightBrown.withOpacity(0.45),
                letterSpacing: 6,
              ),
            ),

            const SizedBox(height: 52),

            SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: AppTheme.lightBrown.withOpacity(0.5),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _textLogo() => Text(
    'PS',
    style: GoogleFonts.playfairDisplay(
      fontSize: 42,
      fontWeight: FontWeight.w600,
      color: AppTheme.lightBrown,
    ),
  );
}
