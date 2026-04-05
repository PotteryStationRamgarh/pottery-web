import 'package:flutter/foundation.dart';
import '../../models/app_config.dart';
import '../services/firestore_service.dart';

/// ConfigProvider — loads and exposes all remote config from Firestore.
/// Exhibition is no longer part of this provider — it lives in ExhibitionProvider.
class ConfigProvider extends ChangeNotifier {
  AppBranding _branding = AppBranding.empty();
  AppContact _contact = AppContact.empty();
  AppContent _content = AppContent.empty();
  AppSocial _social = AppSocial.empty();
  AppFeatures _features = AppFeatures.empty();

  bool _isLoading = false;
  bool _isLoaded = false;
  String? _error;

  AppBranding get branding => _branding;
  AppContact get contact => _contact;
  AppContent get content => _content;
  AppSocial get social => _social;
  AppFeatures get features => _features;

  bool get isLoading => _isLoading;
  bool get isLoaded => _isLoaded;
  String? get error => _error;
  bool get isMaintenanceMode => _features.maintenanceMode;

  Future<void> load({bool forceRefresh = false}) async {
    if (_isLoading || _isLoaded) return;
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      final data = await FirestoreService.getAllConfig(
        forceRefresh: forceRefresh,
      );
      _branding = data['branding'] as AppBranding;
      _contact = data['contact'] as AppContact;
      _content = data['content'] as AppContent;
      _social = data['social'] as AppSocial;
      _features = data['features'] as AppFeatures;
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

  Future<void> reload({bool forceRefresh = true}) async {
    _isLoaded = false;
    await load(forceRefresh: forceRefresh);
  }

  Future<bool> checkMaintenance() async {
    try {
      final features = await FirestoreService.getFeatures(forceRefresh: true);
      _features = features;
      notifyListeners();
      return features.maintenanceMode;
    } catch (e) {
      debugPrint('ConfigProvider: checkMaintenance error $e');
      return false;
    }
  }

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
