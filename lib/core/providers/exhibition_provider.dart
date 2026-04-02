import 'package:flutter/foundation.dart';
import '../../models/exhibition.dart';
import '../repositories/exhibition_repository.dart';

/// Exposes the currently active exhibition to the customer home screen tree.
/// Loaded once by CustomerLoadingScreen — ExhibitionSection never fetches
/// Firestore itself.
class ExhibitionProvider extends ChangeNotifier {
  Exhibition _exhibition = Exhibition.empty();
  bool _isLoading = false;
  bool _isLoaded  = false;
  String? _error;

  Exhibition get exhibition => _exhibition;
  bool    get isLoading    => _isLoading;
  bool    get isLoaded     => _isLoaded;
  String? get error        => _error;

  Future<void> load() async {
    if (_isLoading) return; // Don't load multiple times simultaneously
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      _exhibition = await ExhibitionRepository.getActive();
      _isLoaded   = true;
      debugPrint('ExhibitionProvider loaded — isActive: ${_exhibition.isActive}, isCurrentlyActive: ${_exhibition.isCurrentlyActive}');
    } catch (e) {
      _error = e.toString();
      debugPrint('ExhibitionProvider error: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> reload() async {
    _isLoaded = false;
    _isLoading = false;
    await load();
  }

  Future<void> refreshNow() async {
    _isLoading = true;
    notifyListeners();
    try {
      _exhibition = await ExhibitionRepository.getActive();
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