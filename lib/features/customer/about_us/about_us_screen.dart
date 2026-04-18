import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../app/routes.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/repositories/about_us_repository.dart';
import '../../../models/about_us_model.dart';
import '../home/home_footer.dart';
import '../home/widgets/nav_bar.dart';

class AboutUsScreen extends StatefulWidget {
  const AboutUsScreen({super.key});

  @override
  State<AboutUsScreen> createState() => _AboutUsScreenState();
}

class _AboutUsScreenState extends State<AboutUsScreen> {
  late Future<AboutUsModel> _future;

  @override
  void initState() {
    super.initState();
    _future = AboutUsRepository.getAboutUs();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth > 900;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F2EE),
      endDrawer: const NavDrawer(),
      body: Stack(
        children: [
          FutureBuilder<AboutUsModel>(
            future: _future,
            builder: (context, snap) {
              if (snap.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: CircularProgressIndicator(color: AppTheme.terracotta),
                );
              }
              final data = snap.data ?? AboutUsModel.empty();
              return SingleChildScrollView(
                child: Column(
                  children: [
                    const SizedBox(height: 80),
                    _HeroSection(isDesktop: isDesktop, data: data),
                    _ArtisanSection(isDesktop: isDesktop, data: data),
                    _MaterialsSection(isDesktop: isDesktop, data: data),
                    _SustainabilityBanner(data: data),
                    const HomeFooter(),
                  ],
                ),
              );
            },
          ),
          const Positioned(top: 0, left: 0, right: 0, child: NavBar()),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// SECTION 1  –  Hero (matches image 1 top)
// Layout: left col = label + two-line title + body + CTA
//         right col = intro image with rounded corners
// ─────────────────────────────────────────────────────────────────
class _HeroSection extends StatelessWidget {
  final bool isDesktop;
  final AboutUsModel data;
  const _HeroSection({required this.isDesktop, required this.data});

  static const _fallbackIntro =
      'Born from the weathered landscape of the high desert, Pottery Station '
      'began as a quiet rebellion against the mass-produced. Our philosophy is '
      'rooted in "slow craft"—a deliberate, rhythmic dance with time that '
      'honors the raw integrity of clay.';

  static const _fallbackImage =
      'https://images.unsplash.com/photo-1565193566173-7a0ee3dbe261?w=900';

  @override
  Widget build(BuildContext context) {
    final introText =
        data.intro.isNotEmpty ? data.intro : _fallbackIntro;
    final imageUrl =
        data.introImage.isNotEmpty ? data.introImage : _fallbackImage;

    if (isDesktop) {
      return Container(
        padding: const EdgeInsets.fromLTRB(80, 80, 80, 100),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // ── Left column ──────────────────────────────────────
            Expanded(
              flex: 5,
              child: _LeftHeroContent(introText: introText),
            ),
            const SizedBox(width: 60),
            // ── Right column — Image ─────────────────────────────
            Expanded(
              flex: 6,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: Image.network(
                  imageUrl,
                  height: 560,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    height: 560,
                    color: AppTheme.divider.withValues(alpha: 0.3),
                    child: const Icon(
                      Icons.image_outlined,
                      size: 60,
                      color: AppTheme.textLight,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }

    // Mobile layout — stacked
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 48, 24, 40),
      child: Column(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Image.network(
              imageUrl,
              height: 280,
              width: double.infinity,
              fit: BoxFit.cover,
            ),
          ),
          const SizedBox(height: 40),
          _LeftHeroContent(introText: introText),
        ],
      ),
    );
  }
}

class _LeftHeroContent extends StatelessWidget {
  final String introText;
  const _LeftHeroContent({required this.introText});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // "OUR ARTISTIC JOURNEY" label
        Text(
          'OUR ARTISTIC JOURNEY',
          style: GoogleFonts.jost(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 3,
            color: AppTheme.terracotta,
          ),
        ),
        const SizedBox(height: 20),

        // Two-line title: "Crafting the" + italic coloured "Soul of the Earth"
        RichText(
          text: TextSpan(
            children: [
              TextSpan(
                text: 'Crafting the\n',
                style: GoogleFonts.playfairDisplay(
                  fontSize: 52,
                  fontWeight: FontWeight.w400,
                  height: 1.1,
                  color: AppTheme.textDark,
                ),
              ),
              TextSpan(
                text: 'Soul of the Earth',
                style: GoogleFonts.playfairDisplay(
                  fontSize: 52,
                  fontWeight: FontWeight.w400,
                  fontStyle: FontStyle.italic,
                  height: 1.1,
                  color: AppTheme.terracotta,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 28),

        // Body paragraph
        Text(
          introText,
          style: GoogleFonts.jost(
            fontSize: 15,
            height: 1.75,
            color: AppTheme.textDark.withValues(alpha: 0.7),
          ),
        ),
        const SizedBox(height: 36),

        // CTA button
        Builder(
          builder: (context) => ElevatedButton(
            onPressed: () =>
                Navigator.pushNamed(context, Routes.customerHome),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.terracotta,
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Discover the Collection',
                  style: GoogleFonts.jost(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(Icons.arrow_forward, size: 16),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// SECTION 2  –  Artisans (matches image 1 bottom)
// ─────────────────────────────────────────────────────────────────
class _ArtisanSection extends StatelessWidget {
  final bool isDesktop;
  final AboutUsModel data;
  const _ArtisanSection({required this.isDesktop, required this.data});

  @override
  Widget build(BuildContext context) {
    final artisans = [
      _ArtisanData(
        name: data.artisanName1.isNotEmpty ? data.artisanName1 : 'Master Artisan 1',
        role: data.artisanRole1.isNotEmpty ? data.artisanRole1 : 'FOUNDING MASTER ARTISAN',
        about: data.artisanAbout1.isNotEmpty
            ? data.artisanAbout1
            : 'With decades of experience, our lead artisan breathes life into each vessel '
                'using ancestral techniques merged with contemporary vision.',
        imageUrl: data.artisanPic1,
      ),
      _ArtisanData(
        name: data.artisanName2.isNotEmpty ? data.artisanName2 : 'Master Artisan 2',
        role: data.artisanRole2.isNotEmpty ? data.artisanRole2 : 'LEAD KILN MASTER',
        about: data.artisanAbout2.isNotEmpty
            ? data.artisanAbout2
            : 'A specialist in traditional wood-firing, ensuring that each piece carries '
                'a unique finish impossible to replicate in modern electric kilns.',
        imageUrl: data.artisanPic2,
      ),
    ];

    return Container(
      color: Colors.white,
      padding: EdgeInsets.symmetric(
        horizontal: isDesktop ? 80 : 24,
        vertical: isDesktop ? 100 : 60,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section header
          Text(
            'The Hands Behind the Clay',
            style: GoogleFonts.playfairDisplay(
              fontSize: isDesktop ? 36 : 28,
              fontWeight: FontWeight.w500,
              color: AppTheme.textDark,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Meet the master potters who breathe life into every vessel,\n'
            'merging ancestral techniques with contemporary vision.',
            style: GoogleFonts.jost(
              fontSize: 14,
              color: AppTheme.textLight,
              height: 1.6,
            ),
          ),
          const SizedBox(height: 60),

          // Cards
          if (isDesktop)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: artisans
                  .expand(
                    (a) => [
                      Expanded(child: _ArtisanCard(artisan: a)),
                      if (a != artisans.last) const SizedBox(width: 40),
                    ],
                  )
                  .toList(),
            )
          else
            Column(
              children: artisans
                  .expand(
                    (a) => [
                      _ArtisanCard(artisan: a),
                      if (a != artisans.last) const SizedBox(height: 48),
                    ],
                  )
                  .toList(),
            ),
        ],
      ),
    );
  }
}

class _ArtisanData {
  final String name;
  final String role;
  final String about;
  final String imageUrl;
  const _ArtisanData({
    required this.name,
    required this.role,
    required this.about,
    required this.imageUrl,
  });
}

class _ArtisanCard extends StatelessWidget {
  final _ArtisanData artisan;
  const _ArtisanCard({required this.artisan});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Photo
        ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: artisan.imageUrl.isNotEmpty
              ? Image.network(
                  artisan.imageUrl,
                  height: 440,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) =>
                      _ArtisanImagePlaceholder(name: artisan.name),
                )
              : _ArtisanImagePlaceholder(name: artisan.name),
        ),
        const SizedBox(height: 28),

        // Name
        Text(
          artisan.name,
          style: GoogleFonts.playfairDisplay(
            fontSize: 24,
            fontWeight: FontWeight.w500,
            color: AppTheme.textDark,
          ),
        ),
        const SizedBox(height: 6),

        // Role chip
        Text(
          artisan.role.toUpperCase(),
          style: GoogleFonts.jost(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            letterSpacing: 2,
            color: AppTheme.terracotta,
          ),
        ),
        const SizedBox(height: 16),

        // Bio
        Text(
          artisan.about,
          style: GoogleFonts.jost(
            fontSize: 14,
            height: 1.75,
            color: AppTheme.textLight,
          ),
        ),
      ],
    );
  }
}

class _ArtisanImagePlaceholder extends StatelessWidget {
  final String name;
  const _ArtisanImagePlaceholder({required this.name});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 440,
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppTheme.primaryBrown.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.person_outline,
            size: 72,
            color: AppTheme.primaryBrown.withValues(alpha: 0.3),
          ),
          const SizedBox(height: 12),
          Text(
            name,
            style: GoogleFonts.jost(
              fontSize: 14,
              color: AppTheme.textLight,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// SECTION 3  –  Materials/Process (matches image 2 top)
// ─────────────────────────────────────────────────────────────────
class _MaterialsSection extends StatelessWidget {
  final bool isDesktop;
  final AboutUsModel data;
  const _MaterialsSection({required this.isDesktop, required this.data});

  static const _defaultHeads = ['The Clay', 'The Glaze', 'The Kiln'];
  static const _defaultDescs = [
    'Sourced from the High Desert plateau, our clay is left to age for six months, '
        'allowing natural bacterial growth to improve plasticity and depth of color.',
    'Our glazes are mixed by hand from ground minerals and wood ash, reacting uniquely '
        'to the fire\'s atmosphere to create one-of-a-kind patterns.',
    'We utilize an Anagama kiln, where the movement of flame and fly ash creates a '
        'natural glaze on the pottery over a 4-day firing period.',
  ];

  static const _icons = [
    Icons.layers_outlined, // Clay
    Icons.opacity_outlined, // Glaze
    Icons.local_fire_department_outlined, // Kiln
  ];

  @override
  Widget build(BuildContext context) {
    final heads = data.procedureHead.isNotEmpty ? data.procedureHead : _defaultHeads;
    final descs = data.procedureDesc.isNotEmpty ? data.procedureDesc : _defaultDescs;
    final count = heads.length < descs.length ? heads.length : descs.length;

    return Container(
      color: const Color(0xFFEEEBE6),
      padding: EdgeInsets.symmetric(
        horizontal: isDesktop ? 80 : 24,
        vertical: isDesktop ? 100 : 60,
      ),
      child: Column(
        children: [
          Text(
            'The Alchemy of Materials',
            style: GoogleFonts.playfairDisplay(
              fontSize: isDesktop ? 36 : 28,
              fontWeight: FontWeight.w500,
              color: AppTheme.textDark,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 56),
          if (isDesktop)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: List.generate(count, (i) {
                return Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(left: i == 0 ? 0 : 20),
                    child: _MaterialCard(
                      icon: i < _icons.length ? _icons[i] : Icons.circle_outlined,
                      head: heads[i],
                      desc: descs[i],
                      imageUrl: i < data.procedureImage.length
                          ? data.procedureImage[i]
                          : '',
                    ),
                  ),
                );
              }),
            )
          else
            Column(
              children: List.generate(count, (i) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 20),
                  child: _MaterialCard(
                    icon: i < _icons.length ? _icons[i] : Icons.circle_outlined,
                    head: heads[i],
                    desc: descs[i],
                    imageUrl: i < data.procedureImage.length
                        ? data.procedureImage[i]
                        : '',
                  ),
                );
              }),
            ),
        ],
      ),
    );
  }
}

class _MaterialCard extends StatelessWidget {
  final IconData icon;
  final String head;
  final String desc;
  final String imageUrl;
  const _MaterialCard({
    required this.icon,
    required this.head,
    required this.desc,
    required this.imageUrl,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Icon badge — show custom image if available, else icon
          if (imageUrl.isNotEmpty)
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Image.network(
                imageUrl,
                width: 48,
                height: 48,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => _iconBadge(icon),
              ),
            )
          else
            _iconBadge(icon),
          const SizedBox(height: 28),
          Text(
            head,
            style: GoogleFonts.playfairDisplay(
              fontSize: 22,
              fontWeight: FontWeight.w500,
              color: AppTheme.textDark,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            desc,
            style: GoogleFonts.jost(
              fontSize: 14,
              height: 1.75,
              color: AppTheme.textLight,
            ),
          ),
        ],
      ),
    );
  }

  Widget _iconBadge(IconData data) {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: AppTheme.terracotta,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Icon(data, color: Colors.white, size: 24),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// SECTION 4  –  Sustainability banner (matches image 2 bottom)
// ─────────────────────────────────────────────────────────────────
class _SustainabilityBanner extends StatelessWidget {
  final AboutUsModel data;
  const _SustainabilityBanner({required this.data});

  static const _fallbackTitle = 'A Commitment to Sustainability';
  static const _fallbackBody =
      'We believe craft should give more than it takes. From recycling our '
      'water to utilizing 100% plastic-free, compostable packaging, our studio '
      'is dedicated to a circular, low-impact footprint.';

  @override
  Widget build(BuildContext context) {
    final title = data.sustainabilityTitle.isNotEmpty
        ? data.sustainabilityTitle
        : _fallbackTitle;
    final body = data.sustainabilityBody.isNotEmpty
        ? data.sustainabilityBody
        : _fallbackBody;
    final isDesktop = MediaQuery.of(context).size.width > 900;
    final hPad = isDesktop ? 80.0 : 24.0;

    return Container(
      color: const Color(0xFFEEEBE6),
      padding: EdgeInsets.fromLTRB(hPad, 0, hPad, 100),
      child: Container(
        decoration: BoxDecoration(
          color: AppTheme.terracotta,
          borderRadius: BorderRadius.circular(24),
        ),
        padding: const EdgeInsets.fromLTRB(48, 48, 48, 48),
        child: Stack(
          children: [
            // Decorative leaf in back-right
            Positioned(
              right: -10,
              top: -10,
              child: Icon(
                Icons.eco_outlined,
                size: 140,
                color: Colors.white.withValues(alpha: 0.08),
              ),
            ),
            // Content
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.playfairDisplay(
                    fontSize: 28,
                    fontWeight: FontWeight.w500,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  body,
                  style: GoogleFonts.jost(
                    fontSize: 14,
                    height: 1.75,
                    color: Colors.white.withValues(alpha: 0.85),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
