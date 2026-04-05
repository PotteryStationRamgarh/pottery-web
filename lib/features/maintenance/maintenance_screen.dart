import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_theme.dart';

/// MaintenanceScreen — shown to all non-admin users when
/// app_config/features → maintenanceMode: true in Firestore.
///
/// Admin users never see this screen — SplashScreen sends
/// them directly to the dashboard even during maintenance.
///
/// This screen has no buttons or navigation — user just has
/// to wait until admin turns maintenanceMode back to false.
class MaintenanceScreen extends StatelessWidget {
  const MaintenanceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Same dark warm background as splash — feels intentional
      backgroundColor: AppTheme.appBackground,
      body: Center(
        child: Padding(
          // Enough padding so text doesn't touch screen edges on mobile
          padding: const EdgeInsets.symmetric(horizontal: 40),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Icon inside a soft circle border
              // Keeps it minimal — no heavy graphics needed
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppTheme.lightBrown.withOpacity(0.25),
                    width: 1,
                  ),
                ),
                child: Icon(
                  Icons.handyman_outlined,
                  size: 34,
                  color: AppTheme.lightBrown.withOpacity(0.6),
                ),
              ),

              const SizedBox(height: 40),

              // Main heading — warm light brown, serif font
              Text(
                "We'll Be Back Soon",
                textAlign: TextAlign.center,
                style: GoogleFonts.playfairDisplay(
                  fontSize: 30,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.lightBrown,
                  letterSpacing: 0.3,
                ),
              ),

              const SizedBox(height: 16),

              // Supporting message — lighter and smaller
              Text(
                'Pottery Station is currently undergoing\n'
                'maintenance. Please check back shortly.',
                textAlign: TextAlign.center,
                style: GoogleFonts.jost(
                  fontSize: 14,
                  fontWeight: FontWeight.w300,
                  color: AppTheme.lightBrown.withOpacity(0.45),
                  letterSpacing: 0.3,
                  height: 1.8,
                ),
              ),

              const SizedBox(height: 64),

              // Brand name at the bottom — very faint
              // Acts as a subtle footer so the screen feels complete
              Text(
                'POTTERY STATION RAMGARH',
                style: GoogleFonts.jost(
                  fontSize: 10,
                  fontWeight: FontWeight.w300,
                  color: AppTheme.lightBrown.withOpacity(0.25),
                  letterSpacing: 4,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
