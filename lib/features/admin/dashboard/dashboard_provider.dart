import 'package:cloud_firestore/cloud_firestore.dart';
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
      final exhibitionData = await ExhibitionRepository.getActive();
      
      _productCount   = products.length;
      _exclusiveCount = exclusives.length;
      _exhibition     = AppExhibition(
        title: exhibitionData.title,
        location: exhibitionData.location,
        address: exhibitionData.address,
        startDate: exhibitionData.startDate,
        endDate: exhibitionData.endDate,
        openTime: exhibitionData.openTime,
        closeTime: exhibitionData.closeTime,
        displayTime: exhibitionData.displayTime,
        imageUrl: exhibitionData.imageUrl,
        isActive: exhibitionData.isActive,
        thankYouMessage: exhibitionData.thankYouMessage,
        lastDayMessage: exhibitionData.lastDayMessage,
        upcomingMessage: exhibitionData.upcomingMessage,
      );

      final now = DateTime.now();
      if (exhibitionData.isActive) {
        _exhibitionStatus = 'Active';
      } else if (exhibitionData.startDate != null &&
          exhibitionData.startDate!.isAfter(now)) {
        _exhibitionStatus = 'Upcoming';
      } else if (exhibitionData.endDate != null &&
          now.isAfter(exhibitionData.endDate!)) {
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
