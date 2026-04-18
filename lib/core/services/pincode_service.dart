import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

/// Model for PIN code API response
class PinCodeResponse {
  final String status;
  final List<PostOffice> postOffices;
  final String? message;

  PinCodeResponse({
    required this.status,
    required this.postOffices,
    this.message,
  });

  factory PinCodeResponse.fromJson(List<dynamic> json) {
    if (json.isEmpty) {
      return PinCodeResponse(
        status: 'Error',
        postOffices: [],
        message: 'Invalid response format',
      );
    }

    final Map<String, dynamic> data = json[0] as Map<String, dynamic>;

    return PinCodeResponse(
      status: data['Status'] as String? ?? 'Error',
      postOffices: ((data['PostOffice'] as List<dynamic>?) ?? [])
          .map((po) => PostOffice.fromJson(po as Map<String, dynamic>))
          .toList(),
      message: data['Message'] as String?,
    );
  }
}

class PostOffice {
  final String name;
  final String district;
  final String state;
  final String pincode;

  PostOffice({
    required this.name,
    required this.district,
    required this.state,
    required this.pincode,
  });

  factory PostOffice.fromJson(Map<String, dynamic> json) {
    return PostOffice(
      name: json['Name'] as String? ?? '',
      district: json['District'] as String? ?? '',
      state: json['State'] as String? ?? '',
      pincode: json['Pincode'] as String? ?? '',
    );
  }

  @override
  String toString() => '$name, $district, $state';
}

/// Service to fetch PIN code details from public API
/// API Endpoint: https://api.postalpincode.in/pincode/{pincode}
/// Rate limit: ~30 requests per minute (no API key needed)
class PinCodeService {
  static const String _baseUrl = 'https://api.postalpincode.in';
  static const Duration _timeout = Duration(seconds: 10);

  /// Fetch details for a given 6-digit PIN code
  /// Returns null if API fails or PIN is invalid
  ///
  /// Example:
  /// var response = await PinCodeService.getPinCodeDetails('411001');
  /// if (response?.status == 'Success') {
  ///   print('City: ${response?.postOffices.first.district}');
  ///   print('State: ${response?.postOffices.first.state}');
  /// }
  static Future<PinCodeResponse?> getPinCodeDetails(String pincode) async {
    try {
      // Validate input
      if (pincode.isEmpty ||
          pincode.length != 6 ||
          !RegExp(r'^\d{6}$').hasMatch(pincode)) {
        debugPrint('PinCodeService: Invalid PIN format: $pincode');
        return null;
      }

      debugPrint('PinCodeService: Fetching details for PIN: $pincode');

      final uri = Uri.parse('$_baseUrl/pincode/$pincode');
      final response = await http.get(uri).timeout(_timeout);

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body) as List<dynamic>;
        final pinResponse = PinCodeResponse.fromJson(json);

        if (pinResponse.status == 'Success' &&
            pinResponse.postOffices.isNotEmpty) {
          debugPrint(
            'PinCodeService: SUCCESS - District: ${pinResponse.postOffices.first.district}, '
            'State: ${pinResponse.postOffices.first.state}',
          );
          return pinResponse;
        } else {
          debugPrint('PinCodeService: No data found for PIN: $pincode');
          return null;
        }
      } else {
        debugPrint(
          'PinCodeService: HTTP ${response.statusCode} - ${response.body}',
        );
        return null;
      }
    } on http.ClientException catch (e) {
      debugPrint('PinCodeService: Network error - $e');
      return null;
    } catch (e) {
      debugPrint('PinCodeService: Error - $e');
      return null;
    }
  }

  /// Helper: Get primary city/district from response
  static String? getCityFromResponse(PinCodeResponse response) {
    if (response.postOffices.isEmpty) return null;
    return response.postOffices.first.district;
  }

  /// Helper: Get primary state from response
  static String? getStateFromResponse(PinCodeResponse response) {
    if (response.postOffices.isEmpty) return null;
    return response.postOffices.first.state;
  }

  /// Helper: Check if PIN code has multiple post offices
  /// (useful for showing selection dialog)
  static bool hasMultiplePostOffices(PinCodeResponse response) {
    return response.postOffices.length > 1;
  }
}
