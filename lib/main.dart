import 'package:flutter/material.dart';
import 'core/services/firebase_service.dart';
import 'app/app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase before app starts
  await FirebaseService.initialize();

  runApp(const MyApp());
}