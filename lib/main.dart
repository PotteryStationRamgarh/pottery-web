import 'package:flutter/material.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'package:provider/provider.dart';
import 'core/services/firebase_service.dart';
import 'core/providers/config_provider.dart';
import 'core/providers/branding_provider.dart';
import 'core/providers/exhibition_provider.dart';
import 'core/providers/app_refresh_provider.dart';
import 'core/services/remote_config_service.dart';
import 'app/app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Use path-based URLs (/home instead of /#/home) — required for
  // browser back/forward buttons to work correctly on Flutter Web.
  usePathUrlStrategy();

  await FirebaseService.initialize();
  await RemoteConfigService.initialize();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AppRefreshProvider()),
        ChangeNotifierProvider(create: (_) => ConfigProvider()),
        ChangeNotifierProvider(create: (_) => BrandingProvider()),
        ChangeNotifierProvider(create: (_) => ExhibitionProvider()),
      ],
      child: const MyApp(),
    ),
  );
}
