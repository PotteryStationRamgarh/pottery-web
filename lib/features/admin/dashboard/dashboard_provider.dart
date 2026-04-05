import 'package:flutter/foundation.dart';
import '../../../core/services/firestore_service.dart';
import '../../../models/app_config.dart';
import '../../../models/exhibition.dart';
import '../../../core/repositories/exhibition_repository.dart';

/// DashboardProvider — fetches counts and status for the Admin Dashboard.
/// This is Firestore-ready but does NOT require data to exist yet.
class DashboardProvider extends ChangeNotifier {
  DashboardProvider() {
    load();
  }

  // ─── State ─────────────────────────────────────────────────────────────────

  int _productCount = 0;
  int _exclusiveCount = 0;
  String _exhibitionStatus = 'Loading…';
  AppExhibition _exhibition = AppExhibition.empty();
  List<Exhibition> _futureExhibitions = [];
  List<Exhibition> _pastExhibitions = [];
  bool _isLoading = false;

  // ─── Getters ────────────────────────────────────────────────────────────────

  int get productCount => _productCount;
  int get exclusiveCount => _exclusiveCount;
  String get exhibitionStatus => _exhibitionStatus;
  AppExhibition get exhibition => _exhibition;
  List<Exhibition> get futureExhibitions => _futureExhibitions;
  List<Exhibition> get pastExhibitions => _pastExhibitions;
  bool get isLoading => _isLoading;

  // ─── Load ───────────────────────────────────────────────────────────────────

  Future<void> load() async {
    _isLoading = true;
    notifyListeners();

    try {
      final products = await FirestoreService.getAllProducts();
      final exclusives = await FirestoreService.getExclusiveProducts();

      // Get categorized exhibitions
      final categorized = await ExhibitionRepository.getCategorized();
      final current = categorized['current'] as Exhibition?;
      _futureExhibitions = List<Exhibition>.from(categorized['future'] ?? []);
      _pastExhibitions = List<Exhibition>.from(categorized['past'] ?? []);

      _productCount = products.length;
      _exclusiveCount = exclusives.length;

      if (current != null) {
        _exhibition = AppExhibition(
          title: current.title,
          location: current.location,
          address: current.address,
          startDate: current.startDate,
          endDate: current.endDate,
          openTime: current.openTime,
          closeTime: current.closeTime,
          displayTime: current.displayTime,
          imageUrl: current.imageUrl,
          isActive: current.isActive,
          thankYouMessage: current.thankYouMessage,
          lastDayMessage: current.lastDayMessage,
          upcomingMessage: current.upcomingMessage,
        );
        _exhibitionStatus = 'Active';
      } else if (_futureExhibitions.isNotEmpty) {
        // Show the soonest upcoming exhibition in the card
        final next = _futureExhibitions.first;
        _exhibition = AppExhibition(
          title: next.title,
          location: next.location,
          address: next.address,
          startDate: next.startDate,
          endDate: next.endDate,
          openTime: next.openTime,
          closeTime: next.closeTime,
          displayTime: next.displayTime,
          imageUrl: next.imageUrl,
          isActive: next.isActive,
          thankYouMessage: next.thankYouMessage,
          lastDayMessage: next.lastDayMessage,
          upcomingMessage: next.upcomingMessage,
        );
        _exhibitionStatus = 'Upcoming';
      } else if (_pastExhibitions.isNotEmpty) {
        // Show most recent past exhibition
        final last = _pastExhibitions.first;
        _exhibition = AppExhibition(
          title: last.title,
          location: last.location,
          address: last.address,
          startDate: last.startDate,
          endDate: last.endDate,
          openTime: last.openTime,
          closeTime: last.closeTime,
          displayTime: last.displayTime,
          imageUrl: last.imageUrl,
          isActive: last.isActive,
          thankYouMessage: last.thankYouMessage,
          lastDayMessage: last.lastDayMessage,
          upcomingMessage: last.upcomingMessage,
        );
        _exhibitionStatus = 'Past';
      } else {
        _exhibitionStatus = 'None';
        _exhibition = AppExhibition.empty();
      }
    } catch (e) {
      debugPrint('DashboardProvider.load error: $e');
      _exhibitionStatus = 'Error';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> refresh() async {
    await load();
  }
}
