import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:pottery_web/firebase_options.dart'; // IMPORTANT

class FirebaseService {
  FirebaseService._();

  static Future<void> initialize() async {
    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );

      debugPrint("Firebase initialized successfully");
    } catch (e) {
      debugPrint("Firebase initialization failed: $e");
      rethrow;
    }
  }
}