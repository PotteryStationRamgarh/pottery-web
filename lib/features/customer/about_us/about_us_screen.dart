import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
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
  late Future<AboutUsModel> _aboutUsFuture;

  @override
  void initState() {
    super.initState();
    _aboutUsFuture = AboutUsRepository.getAboutUs();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth > 900;

    return Scaffold(
      backgroundColor: const Color(0xFFF9F7F4), // Premium off-white
      endDrawer: const NavDrawer(),
      body: Stack(
        children: [
          FutureBuilder<AboutUsModel>(
            future: _aboutUsFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: CircularProgressIndicator(color: AppTheme.terracotta),
                );
              }
              final data = snapshot.data ?? AboutUsModel.empty();
              return SingleChildScrollView(
                child: Column(
                  children: [
                    const SizedBox(height: 80),
                    _buildHero(isDesktop, data),
                    _buildArtisanSection(isDesktop, data),
                    _buildProcessSection(isDesktop, data),
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

  Widget _buildHero(bool isDesktop, AboutUsModel data) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: isDesktop ? 80 : 24,
        vertical: isDesktop ? 100 : 40,
      ),
      child: Column(
        children: [
          Text(
            "OUR ARTISTIC JOURNEY",
            style: GoogleFonts.jost(
              fontSize: 12,
              letterSpacing: 4,
              fontWeight: FontWeight.bold,
              color: AppTheme.terracotta.withValues(alpha: 0.8),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            "Crafting the\nSoul of the Earth",
            style: AppTheme.serifHeadingLarge.copyWith(
              fontSize: isDesktop ? 64 : 42,
              height: 1.1,
              fontWeight: FontWeight.w400,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 64),
          Row(
            children: [
              if (isDesktop) const Spacer(flex: 1),
              Expanded(
                flex: isDesktop ? 10 : 1,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: Image.network(
                    data.introImage.isNotEmpty
                        ? data.introImage
                        : "https://images.unsplash.com/photo-1565193566173-7a0ee3dbe261",
                    height: isDesktop ? 600 : 350,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              if (isDesktop) const Spacer(flex: 1),
            ],
          ),
          const SizedBox(height: 64),
          Container(
            constraints: const BoxConstraints(maxWidth: 720),
            child: Text(
              data.intro.isNotEmpty
                  ? data.intro
                  : "Born from the weathered landscape of the high desert, Pottery Station began as a quiet rebellion against the mass-produced. Our philosophy is rooted in \"slow craft\"—a deliberate, rhythmic dance with time that honors the raw integrity of clay.",
              style: GoogleFonts.jost(
                fontSize: 18,
                height: 1.8,
                color: AppTheme.textDark.withValues(alpha: 0.7),
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildArtisanSection(bool isDesktop, AboutUsModel data) {
    return Container(
      width: double.infinity,
      color: Colors.white,
      padding: EdgeInsets.symmetric(
        horizontal: isDesktop ? 80 : 24,
        vertical: isDesktop ? 120 : 80,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Column(
              children: [
                Text(
                  "The Hands Behind the Clay",
                  style: AppTheme.serifHeadingLarge.copyWith(fontSize: 36),
                ),
                const SizedBox(height: 8),
                Text(
                  "Meet the master potters who breathe life into every vessel.",
                  style: GoogleFonts.jost(color: AppTheme.textLight),
                ),
              ],
            ),
          ),
          const SizedBox(height: 80),
          LayoutBuilder(
            builder: (context, constraints) {
              if (isDesktop) {
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: _buildArtisanProfile(
                        data.artisanName1.isNotEmpty
                            ? data.artisanName1
                            : "Elena Rossi",
                        "FOUNDING MASTER ARTISAN",
                        data.artisanAbout1.isNotEmpty
                            ? data.artisanAbout1
                            : "With over 30 years of experience, Elena's work is characterized by organic, flowing forms that mimic the erosion patterns found in desert canyons.",
                        "https://images.unsplash.com/photo-1544005313-94dd902eaf3b",
                      ),
                    ),
                    const SizedBox(width: 48),
                    Expanded(
                      child: _buildArtisanProfile(
                        data.artisanName2.isNotEmpty
                            ? data.artisanName2
                            : "Kenji Tanaka",
                        "LEAD KILN MASTER",
                        data.artisanAbout2.isNotEmpty
                            ? data.artisanAbout2
                            : "A specialist in traditional wood-firing, Kenji controls the alchemy of the flame. His expertise ensures that each piece carries a unique \"ash-kissed\" finish.",
                        "https://images.unsplash.com/photo-1472099645785-5658abf4ff4e",
                      ),
                    ),
                  ],
                );
              }
              return Column(
                children: [
                  _buildArtisanProfile(
                    data.artisanName1.isNotEmpty
                        ? data.artisanName1
                        : "Elena Rossi",
                    "FOUNDING MASTER ARTISAN",
                    data.artisanAbout1.isNotEmpty
                        ? data.artisanAbout1
                        : "With over 30 years of experience, Elena's work is characterized by organic, flowing forms.",
                    "https://images.unsplash.com/photo-1544005313-94dd902eaf3b",
                  ),
                  const SizedBox(height: 64),
                  _buildArtisanProfile(
                    data.artisanName2.isNotEmpty
                        ? data.artisanName2
                        : "Kenji Tanaka",
                    "LEAD KILN MASTER",
                    data.artisanAbout2.isNotEmpty
                        ? data.artisanAbout2
                        : "A specialist in traditional wood-firing, Kenji controls the alchemy of the flame.",
                    "https://images.unsplash.com/photo-1472099645785-5658abf4ff4e",
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildArtisanProfile(
    String name,
    String role,
    String about,
    String imageUrl,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Image.network(
            imageUrl,
            height: 480,
            width: double.infinity,
            fit: BoxFit.cover,
          ),
        ),
        const SizedBox(height: 32),
        Text(name, style: AppTheme.serifHeadingMedium.copyWith(fontSize: 28)),
        const SizedBox(height: 8),
        Text(
          role,
          style: GoogleFonts.jost(
            fontSize: 10,
            letterSpacing: 2,
            fontWeight: FontWeight.bold,
            color: AppTheme.terracotta,
          ),
        ),
        const SizedBox(height: 20),
        Text(
          about,
          style: GoogleFonts.jost(
            fontSize: 16,
            height: 1.7,
            color: AppTheme.textLight,
          ),
        ),
      ],
    );
  }

  Widget _buildProcessSection(bool isDesktop, AboutUsModel data) {
    return Container(
      width: double.infinity,
      color: const Color(0xFFF0EDE9),
      padding: EdgeInsets.symmetric(
        horizontal: isDesktop ? 80 : 24,
        vertical: 120,
      ),
      child: Column(
        children: [
          Text(
            "The Alchemy of Materials",
            style: AppTheme.serifHeadingLarge.copyWith(fontSize: 36),
          ),
          const SizedBox(height: 80),
          _buildProcessGrid(isDesktop, data),
        ],
      ),
    );
  }

  Widget _buildProcessGrid(bool isDesktop, AboutUsModel data) {
    final heads = data.procedureHead.isNotEmpty
        ? data.procedureHead
        : ["The Clay", "The Glaze", "The Kiln"];
    final descs = data.procedureDesc.isNotEmpty
        ? data.procedureDesc
        : [
            "Sourced from the High Desert plateau, our clay is left to age for six months.",
            "Our glazes are mixed by hand from ground minerals and wood ash.",
            "We utilize an Anagama kiln, where the movement of flame creates a natural glaze.",
          ];
    final icons = [
      Icons.layers_outlined,
      Icons.opacity_outlined,
      Icons.local_fire_department_outlined,
    ];

    if (isDesktop) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: List.generate(3, (i) {
          return Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: _buildProcessCard(heads[i], descs[i], icons[i]),
            ),
          );
        }),
      );
    }

    return Column(
      children: List.generate(3, (i) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 32),
          child: _buildProcessCard(heads[i], descs[i], icons[i]),
        );
      }),
    );
  }

  Widget _buildProcessCard(String title, String desc, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(40),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 30,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.terracotta.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: AppTheme.terracotta, size: 28),
          ),
          const SizedBox(height: 32),
          Text(
            title,
            style: AppTheme.serifHeadingMedium.copyWith(fontSize: 24),
          ),
          const SizedBox(height: 16),
          Text(
            desc,
            style: GoogleFonts.jost(
              fontSize: 15,
              height: 1.7,
              color: AppTheme.textLight,
            ),
          ),
        ],
      ),
    );
  }
}
