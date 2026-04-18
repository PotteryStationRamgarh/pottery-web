import 'package:flutter/foundation.dart';
import '../../models/exhibition.dart';
import '../../core/repositories/exhibition_repository.dart';
import '../../features/exhibition/data/models/exhibition_model.dart';
import '../../features/exhibition/data/repositories/exhibition_repository.dart'
    as feat;

/// Exposes the currently active exhibition to the customer home screen tree.
/// Loaded once by CustomerLoadingScreen — ExhibitionSection never fetches
/// Firestore itself.
class ExhibitionProvider extends ChangeNotifier {
  Exhibition _exhibition = Exhibition.empty();
  bool _isLoading = false;
  bool _isLoaded = false;
  String? _error;

  Exhibition get exhibition => _exhibition;
  bool get isLoading => _isLoading;
  bool get isLoaded => _isLoaded;
  String? get error => _error;

  /// Real-time stream of exhibitions for the Exhibition listing screen.
  /// Uses the richer feature-level repository which boasts better sorting.
  Stream<List<ExhibitionModel>> get allExhibitionsStream =>
      feat.ExhibitionRepository.watchAllExhibitions();

  Future<void> load({bool forceRefresh = false}) async {
    if (_isLoading) return; // Don't load multiple times simultaneously
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      _exhibition = await ExhibitionRepository.getActive(
        forceRefresh: forceRefresh,
      );
      _isLoaded = true;
      debugPrint(
        'ExhibitionProvider loaded — isActive: ${_exhibition.isActive}, isCurrentlyActive: ${_exhibition.isCurrentlyActive}',
      );
    } catch (e) {
      _error = e.toString();
      debugPrint('ExhibitionProvider error: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> reload({bool forceRefresh = true}) async {
    _isLoaded = false;
    _isLoading = false;
    await load(forceRefresh: forceRefresh);
  }

  Future<void> refreshNow() async {
    _isLoading = true;
    notifyListeners();
    try {
      _exhibition = await ExhibitionRepository.getActive(forceRefresh: true);
      debugPrint('ExhibitionProvider refreshed');
    } catch (e) {
      _error = e.toString();
      debugPrint('ExhibitionProvider refresh error: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
