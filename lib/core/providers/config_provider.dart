import 'package:flutter/foundation.dart';
import '../../models/app_config.dart';
import '../services/firestore_service.dart';

/// ConfigProvider — loads and exposes all remote config from Firestore.
/// Wrap the app with ChangeNotifierProvider<ConfigProvider> in main.dart.
///
/// Usage anywhere in widget tree:
///   final config = context.watch<ConfigProvider>();
///   config.branding.appName
///   config.features.maintenanceMode
///   config.exhibition.isActive
class ConfigProvider extends ChangeNotifier {
  // ─────────────────────────────────────────
  // STATE
  // ─────────────────────────────────────────

  AppBranding  _branding   = AppBranding.empty();
  AppContact   _contact    = AppContact.empty();
  AppContent   _content    = AppContent.empty();
  AppSocial    _social     = AppSocial.empty();
  AppFeatures  _features   = AppFeatures.empty();
  AppExhibition _exhibition = AppExhibition.empty();

  bool   _isLoading = false;
  bool   _isLoaded  = false;
  String? _error;

  // ─────────────────────────────────────────
  // GETTERS
  // ─────────────────────────────────────────

  AppBranding   get branding   => _branding;
  AppContact    get contact    => _contact;
  AppContent    get content    => _content;
  AppSocial     get social     => _social;
  AppFeatures   get features   => _features;
  AppExhibition get exhibition => _exhibition;

  bool    get isLoading => _isLoading;
  bool    get isLoaded  => _isLoaded;
  String? get error     => _error;

  /// Quick access used by SplashScreen
  bool get isMaintenanceMode => _features.maintenanceMode;

  // ─────────────────────────────────────────
  // LOAD ALL
  // ─────────────────────────────────────────

  /// Loads all app config from Firestore in parallel.
  /// Safe to call multiple times — skips if already loaded.
  Future<void> load() async {
    if (_isLoading || _isLoaded) return;

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final data = await FirestoreService.getAllConfig();

      _branding   = data['branding']   as AppBranding;
      _contact    = data['contact']    as AppContact;
      _content    = data['content']    as AppContent;
      _social     = data['social']     as AppSocial;
      _features   = data['features']   as AppFeatures;
      _exhibition = data['exhibition'] as AppExhibition;

      _isLoaded = true;
      debugPrint('ConfigProvider: loaded successfully');
    } catch (e) {
      _error = e.toString();
      debugPrint('ConfigProvider: load error $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Forces a fresh reload — call this if admin updates config remotely
  Future<void> reload() async {
    _isLoaded = false;
    await load();
  }

  // ─────────────────────────────────────────
  // MAINTENANCE CHECK
  // ─────────────────────────────────────────

  /// Fetches ONLY the features doc — fast check on splash screen
  /// before loading the full config.
  Future<bool> checkMaintenance() async {
    try {
      final features = await FirestoreService.getFeatures();
      _features = features;
      notifyListeners();
      return features.maintenanceMode;
    } catch (e) {
      debugPrint('ConfigProvider: checkMaintenance error $e');
      return false; // default to not maintenance on error
    }
  }

  /// Updates the features config in Firestore and locally
  Future<void> updateFeatures(AppFeatures newFeatures) async {
    try {
      await FirestoreService.updateConfig('features', newFeatures.toMap());
      _features = newFeatures;
      notifyListeners();
    } catch (e) {
      debugPrint('ConfigProvider: updateFeatures error $e');
      rethrow;
    }
  }
}