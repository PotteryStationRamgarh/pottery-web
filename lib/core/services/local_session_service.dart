import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class LocalSessionService {
  LocalSessionService._();

  static const _guestCartKey = 'guest_cart_v1';
  static const _guestWishlistKey = 'guest_wishlist_v1';
  static const _maintenanceRunKey = 'maintenance_last_run_v1';

  static Future<List<Map<String, dynamic>>> readGuestCart() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_guestCartKey);
    if (raw == null || raw.isEmpty) return const [];

    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return const [];
      return decoded
          .whereType<Map>()
          .map((item) => Map<String, dynamic>.from(item))
          .toList();
    } catch (_) {
      return const [];
    }
  }

  static Future<void> writeGuestCart(List<Map<String, dynamic>> items) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_guestCartKey, jsonEncode(items));
  }

  static Future<void> clearGuestCart() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_guestCartKey);
  }

  static Future<Set<String>> readGuestWishlist() async {
    final prefs = await SharedPreferences.getInstance();
    final values = prefs.getStringList(_guestWishlistKey) ?? const <String>[];
    return values.toSet();
  }

  static Future<void> writeGuestWishlist(Set<String> items) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_guestWishlistKey, items.toList());
  }

  static Future<void> clearGuestWishlist() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_guestWishlistKey);
  }

  static Future<DateTime?> readLastMaintenanceRun() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_maintenanceRunKey);
    if (raw == null || raw.isEmpty) return null;
    return DateTime.tryParse(raw);
  }

  static Future<void> writeLastMaintenanceRun(DateTime value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_maintenanceRunKey, value.toIso8601String());
  }
}
