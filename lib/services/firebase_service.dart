import 'dart:async';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter/foundation.dart';

/// Service for managing Firebase functionality including:
/// - Crashlytics for crash reporting
/// - Analytics for user behavior tracking
/// - Remote Config for app version management
class FirebaseService {
  static final FirebaseService _instance = FirebaseService._internal();
  factory FirebaseService() => _instance;
  FirebaseService._internal();

  late FirebaseAnalytics _analytics;
  late FirebaseRemoteConfig _remoteConfig;

  FirebaseAnalytics get analytics => _analytics;
  FirebaseRemoteConfig get remoteConfig => _remoteConfig;

  /// Initialize Firebase and all its services
  Future<void> initialize() async {
    try {
      // Initialize Firebase
      await Firebase.initializeApp();

      // Initialize Analytics
      _analytics = FirebaseAnalytics.instance;

      // Initialize Remote Config
      _remoteConfig = FirebaseRemoteConfig.instance;
      await _setupRemoteConfig();

      // Initialize Crashlytics
      await _setupCrashlytics();

      debugPrint('✅ Firebase initialized successfully');
    } catch (e, stackTrace) {
      debugPrint('❌ Firebase initialization failed: $e');
      debugPrint('Stack trace: $stackTrace');
    }
  }

  /// Set up Crashlytics for crash reporting
  Future<void> _setupCrashlytics() async {
    // Pass all uncaught "fatal" errors from the framework to Crashlytics
    FlutterError.onError = (errorDetails) {
      FirebaseCrashlytics.instance.recordFlutterFatalError(errorDetails);
    };

    // Pass all uncaught asynchronous errors that aren't handled by the Flutter framework to Crashlytics
    PlatformDispatcher.instance.onError = (error, stack) {
      FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
      return true;
    };

    // Enable Crashlytics collection
    await FirebaseCrashlytics.instance.setCrashlyticsCollectionEnabled(true);

    debugPrint('✅ Crashlytics configured');
  }

  /// Set up Remote Config with default values
  Future<void> _setupRemoteConfig() async {
    try {
      // Set config settings
      await _remoteConfig.setConfigSettings(RemoteConfigSettings(
        fetchTimeout: const Duration(minutes: 1),
        minimumFetchInterval: kDebugMode ? Duration.zero : const Duration(hours: 1),
      ));

      // Set default parameters for app version management
      await _remoteConfig.setDefaults({
        'minimum_app_version': '1.0.0',
        'latest_app_version': '1.0.0',
        'force_update_required': false,
        'update_message_en':
            'A new version is available. Please update to continue.',
        'update_message_uk':
            'Доступна нова версія. Будь ласка, оновіть додаток.',
        'maintenance_mode': false,
        'maintenance_message_en':
            'We are currently performing maintenance. Please try again later.',
        'maintenance_message_uk':
            'Ми проводимо технічне обслуговування. Спробуйте пізніше.',
      });

      // Fetch and activate config
      await _remoteConfig.fetchAndActivate();

      debugPrint('✅ Remote Config configured');
    } catch (e) {
      debugPrint('❌ Remote Config setup failed: $e');
    }
  }

  /// Fetch latest remote config values — always bypasses cache
  Future<void> fetchRemoteConfig() async {
    try {
      // Force a real network fetch regardless of release/debug mode or cached values
      await _remoteConfig.setConfigSettings(RemoteConfigSettings(
        fetchTimeout: const Duration(minutes: 1),
        minimumFetchInterval: Duration.zero,
      ));
      final updated = await _remoteConfig.fetchAndActivate();
      debugPrint('✅ Remote Config fetched (fresh data: $updated)');
    } catch (e) {
      debugPrint('❌ Failed to fetch Remote Config: $e');
    }
  }

  /// Check if app version is supported
  /// Returns true if the current version meets the minimum requirement
  bool isAppVersionSupported(String currentVersion) {
    final minimumVersion = _remoteConfig.getString('minimum_app_version');
    return _compareVersions(currentVersion, minimumVersion) >= 0;
  }

  /// Check if force update is required
  bool isForceUpdateRequired() {
    return _remoteConfig.getBool('force_update_required');
  }

  /// Get the latest available app version
  String getLatestAppVersion() {
    return _remoteConfig.getString('latest_app_version');
  }

  /// Check if a newer version is available
  bool isUpdateAvailable(String currentVersion) {
    final latestVersion = getLatestAppVersion();
    return _compareVersions(currentVersion, latestVersion) < 0;
  }

  /// Get update message based on locale
  String getUpdateMessage(String languageCode) {
    switch (languageCode) {
      case 'uk':
        return _remoteConfig.getString('update_message_uk');
      default:
        return _remoteConfig.getString('update_message_en');
    }
  }

  /// Check if app is in maintenance mode
  bool isMaintenanceMode() {
    return _remoteConfig.getBool('maintenance_mode');
  }

  /// Get maintenance message based on locale
  String getMaintenanceMessage(String languageCode) {
    switch (languageCode) {
      case 'uk':
        return _remoteConfig.getString('maintenance_message_uk');
      default:
        return _remoteConfig.getString('maintenance_message_en');
    }
  }

  /// Compare two version strings (e.g., "1.2.3" vs "1.3.0")
  /// Returns: -1 if v1 < v2, 0 if equal, 1 if v1 > v2
  int _compareVersions(String v1, String v2) {
    final v1Parts = v1.split('.').map(int.parse).toList();
    final v2Parts = v2.split('.').map(int.parse).toList();

    for (int i = 0; i < 3; i++) {
      final part1 = i < v1Parts.length ? v1Parts[i] : 0;
      final part2 = i < v2Parts.length ? v2Parts[i] : 0;

      if (part1 < part2) return -1;
      if (part1 > part2) return 1;
    }

    return 0;
  }

  /// Log custom event to Analytics
  Future<void> logEvent({
    required String name,
    Map<String, dynamic>? parameters,
  }) async {
    try {
      await _analytics.logEvent(
        name: name,
        parameters: parameters,
      );
    } catch (e) {
      debugPrint('❌ Failed to log event: $e');
    }
  }

  /// Log screen view to Analytics
  Future<void> logScreenView({
    required String screenName,
    String? screenClass,
  }) async {
    try {
      await _analytics.logScreenView(
        screenName: screenName,
        screenClass: screenClass,
      );
    } catch (e) {
      debugPrint('❌ Failed to log screen view: $e');
    }
  }

  /// Set user property for Analytics
  Future<void> setUserProperty({
    required String name,
    required String value,
  }) async {
    try {
      await _analytics.setUserProperty(
        name: name,
        value: value,
      );
    } catch (e) {
      debugPrint('❌ Failed to set user property: $e');
    }
  }

  /// Log a non-fatal error to Crashlytics
  Future<void> logError(
    dynamic exception,
    StackTrace? stackTrace, {
    String? reason,
    bool fatal = false,
  }) async {
    try {
      await FirebaseCrashlytics.instance.recordError(
        exception,
        stackTrace,
        reason: reason,
        fatal: fatal,
      );
    } catch (e) {
      debugPrint('❌ Failed to log error to Crashlytics: $e');
    }
  }

  /// Set custom key for Crashlytics
  Future<void> setCrashlyticsKey(String key, dynamic value) async {
    try {
      await FirebaseCrashlytics.instance.setCustomKey(key, value);
    } catch (e) {
      debugPrint('❌ Failed to set Crashlytics key: $e');
    }
  }

  /// Set user identifier for Crashlytics
  Future<void> setCrashlyticsUserId(String userId) async {
    try {
      await FirebaseCrashlytics.instance.setUserIdentifier(userId);
    } catch (e) {
      debugPrint('❌ Failed to set Crashlytics user ID: $e');
    }
  }
}
