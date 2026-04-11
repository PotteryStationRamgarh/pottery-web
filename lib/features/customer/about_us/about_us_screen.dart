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
      backgroundColor: AppTheme.background,
      endDrawer: const NavDrawer(),
      body: Stack(
        children: [
          FutureBuilder<AboutUsModel>(
            future: _aboutUsFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              final data = snapshot.data ?? AboutUsModel.empty();
              return SingleChildScrollView(
                child: Column(
                  children: [
                    const SizedBox(height: 72),
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
        vertical: isDesktop ? 100 : 60,
      ),
      child: Column(
        children: [
          Text(
            "Our Story",
            style: GoogleFonts.playfairDisplay(
              fontSize: 14,
              letterSpacing: 4,
              fontWeight: FontWeight.w500,
              color: AppTheme.terracotta,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            "The Art of Intentional Form",
            style: AppTheme.serifHeadingLarge.copyWith(
              fontSize: isDesktop ? 56 : 36,
              height: 1.2,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 60),
          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Image.network(
              data.introImage.isNotEmpty 
                  ? data.introImage 
                  : "https://images.unsplash.com/photo-1565193566173-7a0ee3dbe261",
              width: isDesktop ? 1000 : double.infinity,
              height: isDesktop ? 600 : 300,
              fit: BoxFit.cover,
            ),
          ),
          const SizedBox(height: 60),
          Container(
            constraints: const BoxConstraints(maxWidth: 800),
            child: Text(
              data.intro,
              style: GoogleFonts.jost(
                fontSize: 18,
                height: 1.8,
                color: AppTheme.textDark.withValues(alpha: 0.8),
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
        vertical: 100,
      ),
      child: Column(
        children: [
          Text(
            "THE HANDS BEHIND THE CLAY",
            style: GoogleFonts.jost(
              fontSize: 12,
              letterSpacing: 3,
              fontWeight: FontWeight.bold,
              color: AppTheme.textLight,
            ),
          ),
          const SizedBox(height: 60),
          _buildArtisanRow(
            isDesktop,
            data.artisanName1,
            data.artisanAbout1,
            true,
          ),
          const SizedBox(height: 80),
          _buildArtisanRow(
            isDesktop,
            data.artisanName2,
            data.artisanAbout2,
            false,
          ),
        ],
      ),
    );
  }

  Widget _buildArtisanRow(bool isDesktop, String name, String about, bool imageLeft) {
    final children = [
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              name,
              style: GoogleFonts.playfairDisplay(
                fontSize: 32,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              about,
              style: GoogleFonts.jost(
                fontSize: 16,
                height: 1.8,
                color: AppTheme.textLight,
              ),
            ),
          ],
        ),
      ),
      const SizedBox(width: 80, height: 40),
      Expanded(
        child: Container(
          height: 400,
          decoration: BoxDecoration(
            color: AppTheme.background,
            borderRadius: BorderRadius.circular(16),
            image: const DecorationImage(
              image: NetworkImage("https://images.unsplash.com/photo-1541675154750-0444c7d51e8e"),
              fit: BoxFit.cover,
            ),
          ),
        ),
      ),
    ];

    return Container(
      constraints: const BoxConstraints(maxWidth: 1000),
      child: isDesktop
          ? Row(children: imageLeft ? children.reversed.toList() : children)
          : Column(children: [children[2], const SizedBox(height: 32), children[0]]),
    );
  }

  Widget _buildProcessSection(bool isDesktop, AboutUsModel data) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: isDesktop ? 80 : 24,
        vertical: 100,
      ),
      child: Column(
        children: [
          Text(
            "THE ALCHEMY OF MATERIALS",
            style: GoogleFonts.jost(
              fontSize: 12,
              letterSpacing: 3,
              fontWeight: FontWeight.bold,
              color: AppTheme.textLight,
            ),
          ),
          const SizedBox(height: 60),
          if (isDesktop)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: List.generate(data.procedureHead.length, (i) {
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: _buildProcessCard(
                      data.procedureHead[i],
                      data.procedureDesc[i],
                      data.procedureImage.length > i ? data.procedureImage[i] : "",
                    ),
                  ),
                );
              }),
            )
          else
            Column(
              children: List.generate(data.procedureHead.length, (i) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 40),
                  child: _buildProcessCard(
                    data.procedureHead[i],
                    data.procedureDesc[i],
                    data.procedureImage.length > i ? data.procedureImage[i] : "",
                  ),
                );
              }),
            ),
        ],
      ),
    );
  }

  Widget _buildProcessCard(String title, String desc, String imageUrl) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Image.network(
            imageUrl.isNotEmpty ? imageUrl : "https://images.unsplash.com/photo-1525498122383-3f61b912b053",
            height: 240,
            width: double.infinity,
            fit: BoxFit.cover,
          ),
        ),
        const SizedBox(height: 24),
        Text(
          title,
          style: GoogleFonts.playfairDisplay(
            fontSize: 24,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          desc,
          style: GoogleFonts.jost(
            fontSize: 15,
            height: 1.6,
            color: AppTheme.textLight,
          ),
        ),
      ],
    );
  }
}
