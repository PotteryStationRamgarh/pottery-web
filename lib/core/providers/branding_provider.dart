import 'package:flutter/material.dart';
import '../../models/app_config.dart';
import '../services/firestore_service.dart';

class BrandingProvider extends ChangeNotifier {
  AppBranding _branding = AppBranding.empty();
  bool _isLoading = false;
  bool _isLoaded = false;
  String? _error;

  AppBranding get branding => _branding;
  bool get isLoading => _isLoading;
  bool get isLoaded => _isLoaded;
  String? get error => _error;

  /// Loads branding once — skips if already loaded.
  /// Called by SplashScreen on startup.
  Future<void> loadBranding({bool forceRefresh = false}) async {
    if (_isLoading || _isLoaded) return;
    await _fetchBranding(forceRefresh: forceRefresh);
  }

  /// Forces a fresh fetch from Firestore — ignores cache.
  /// Called by admin after saving branding changes.
  Future<void> reloadBranding({bool forceRefresh = true}) async {
    _isLoaded = false;
    await _fetchBranding(forceRefresh: forceRefresh);
  }

  Future<void> _fetchBranding({bool forceRefresh = false}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final fetched = await FirestoreService.getBranding(
        forceRefresh: forceRefresh,
      );
      _branding = fetched;
      _isLoaded = true;
      debugPrint(
        'BrandingProvider: Loaded — authImageUrl: ${fetched.authImageUrl}',
      );
    } catch (e) {
      _error = e.toString();
      debugPrint('BrandingProvider: Error — $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
