import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../../../core/services/firestore_service.dart';
import '../../../models/app_config.dart';

/// DashboardProvider — fetches counts and status for the Admin Dashboard.
/// This is Firestore-ready but does NOT require data to exist yet.
class DashboardProvider extends ChangeNotifier {
  DashboardProvider() {
    load();
  }

  // ─── State ─────────────────────────────────────────────────────────────────

  int    _productCount   = 0;
  int    _exclusiveCount = 0;
  String _exhibitionStatus = 'Loading…';
  AppExhibition _exhibition = AppExhibition.empty();
  bool   _isLoading = false;

  // ─── Getters ────────────────────────────────────────────────────────────────

  int    get productCount      => _productCount;
  int    get exclusiveCount    => _exclusiveCount;
  String get exhibitionStatus  => _exhibitionStatus;
  AppExhibition get exhibition => _exhibition;
  bool   get isLoading         => _isLoading;

  // ─── Load ───────────────────────────────────────────────────────────────────

  Future<void> load() async {
    _isLoading = true;
    notifyListeners();

    try {
      final products   = await FirestoreService.getAllProducts();
      final exclusives = await FirestoreService.getExclusiveProducts();
      final exhibition = await FirestoreService.getExhibition();

      _productCount   = products.length;
      _exclusiveCount = exclusives.length;
      _exhibition     = exhibition;

      final now = DateTime.now();
      if (exhibition.isActive) {
        _exhibitionStatus = 'Active';
      } else if (exhibition.startDate != null &&
          exhibition.startDate!.isAfter(now)) {
        _exhibitionStatus = 'Upcoming';
      } else if (exhibition.endDate != null &&
          now.isAfter(exhibition.endDate!)) {
        _exhibitionStatus = 'Past';
      } else {
        _exhibitionStatus = 'None';
      }
    } catch (e) {
      debugPrint('DashboardProvider.load error: $e');
      _exhibitionStatus = 'None';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
