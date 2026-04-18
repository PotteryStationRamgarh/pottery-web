import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;

class IndiaState {
  final String name;
  final List<String> districts;

  const IndiaState({required this.name, required this.districts});
}

class IndiaLocationService {
  IndiaLocationService._();

  static const _assetPath = 'assets/data/india_states_districts.json';
  static List<IndiaState>? _cachedStates;

  static Future<List<IndiaState>> getStates() async {
    if (_cachedStates != null) {
      return _cachedStates!;
    }

    final raw = await rootBundle.loadString(_assetPath);
    final decoded = jsonDecode(raw) as Map<String, dynamic>;
    final states =
        (decoded['states'] as List? ?? const [])
            .whereType<Map>()
            .map((entry) {
              final map = Map<String, dynamic>.from(entry);
              final districts =
                  (map['districts'] as List? ?? const [])
                      .whereType<Map>()
                      .map((item) => (item['name'] as String? ?? '').trim())
                      .where((name) => name.isNotEmpty)
                      .toSet()
                      .toList()
                    ..sort();
              return IndiaState(
                name: _normalizeDisplayName(
                  (map['state'] as String? ?? '').trim(),
                ),
                districts: districts,
              );
            })
            .where((state) => state.name.isNotEmpty)
            .toList()
          ..sort((a, b) => a.name.compareTo(b.name));

    _cachedStates = states;
    return states;
  }

  static Future<List<String>> getStateNames() async {
    final states = await getStates();
    return states.map((state) => state.name).toList(growable: false);
  }

  static Future<List<String>> getDistrictsForState(String stateName) async {
    final states = await getStates();
    final normalized = normalizeLookupValue(stateName);
    final matched = states.where(
      (state) => normalizeLookupValue(state.name) == normalized,
    );
    return matched.isEmpty ? const [] : matched.first.districts;
  }

  /// Get the state name for a given district
  static Future<String?> getStateForDistrict(String district) async {
    final states = await getStates();
    final normalizedDistrict = normalizeLookupValue(district);

    for (final state in states) {
      for (final d in state.districts) {
        if (normalizeLookupValue(d) == normalizedDistrict) {
          return state.name;
        }
      }
    }
    return null;
  }

  static String normalizeLookupValue(String value) {
    return value
        .toLowerCase()
        .replaceAll('&amp;', '&')
        .replaceAll(RegExp(r'\([^)]*\)'), '')
        .replaceAll(RegExp(r'[^a-z0-9]+'), ' ')
        .trim();
  }

  static String _normalizeDisplayName(String value) {
    return value
        .replaceAll('&amp;', '&')
        .replaceAll('(UT)', 'UT')
        .replaceAll('(NCT)', 'NCT')
        .trim();
  }
}
