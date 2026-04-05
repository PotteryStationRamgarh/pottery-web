import 'dart:developer';
import 'package:firebase_remote_config/firebase_remote_config.dart';

/// Service to securely fetch Cloudflare R2 credentials without hardcoding them
class RemoteConfigService {
  static final _remoteConfig = FirebaseRemoteConfig.instance;

  static Future<void> initialize() async {
    try {
      await _remoteConfig.setConfigSettings(
        RemoteConfigSettings(
          fetchTimeout: const Duration(minutes: 1),
          minimumFetchInterval: const Duration(hours: 1),
        ),
      );

      // Define default values in case network fails
      await _remoteConfig.setDefaults(const {
        'r2_account_id': '',
        'r2_access_key_id': '',
        'r2_secret_access_key': '',
      });

      await _remoteConfig.fetchAndActivate();
      log('Remote config initialized safely.');
    } catch (e) {
      log('Failed to fetch remote config: $e');
    }
  }

  static String get r2AccountId => _remoteConfig.getString('r2_account_id');
  static String get r2AccessKeyId =>
      _remoteConfig.getString('r2_access_key_id');
  static String get r2SecretAccessKey =>
      _remoteConfig.getString('r2_secret_access_key');
}
