import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/services/firebase_service.dart';
import 'core/providers/config_provider.dart';
import 'core/providers/branding_provider.dart';
import 'app/app.dart';

import 'core/services/remote_config_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase before app starts
  await FirebaseService.initialize();
  
  // Initialize Remote Config for R2 credentials
  await RemoteConfigService.initialize();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ConfigProvider()),
        ChangeNotifierProvider(create: (_) => BrandingProvider()),
      ],
      child: const MyApp(),
    ),
  );
}