import 'package:shared_preferences/shared_preferences.dart';

/// Service to manage app settings and notification preferences
class SettingsService {
  static const String _keyDailyReminderEnabled = 'daily_reminder_enabled';
  static const String _keyDailyReminderHour = 'daily_reminder_hour';
  static const String _keyDailyReminderMinute = 'daily_reminder_minute';

  static const String _keyGratitudeReminderEnabled =
      'gratitude_reminder_enabled';
  static const String _keyGratitudeReminderHour = 'gratitude_reminder_hour';
  static const String _keyGratitudeReminderMinute = 'gratitude_reminder_minute';
  static const String _keyGratitudeReminderRegularity =
      'gratitude_reminder_regularity';

  static const String _keyHasCompletedOnboarding = 'has_completed_onboarding';
  static const String _keyInstallDateMillis = 'install_date_millis';
  static const String _keyHasShownRateUsPrompt = 'has_shown_rate_us_prompt';

  final SharedPreferences _prefs;

  SettingsService(this._prefs);

  // Onboarding
  bool get hasCompletedOnboarding =>
      _prefs.getBool(_keyHasCompletedOnboarding) ?? false;

  Future<void> setHasCompletedOnboarding(bool completed) async {
    await _prefs.setBool(_keyHasCompletedOnboarding, completed);
  }

  /// The moment this device first ran the app. Persisted lazily on first
  /// access (there's no distinct "install" hook), so the first read of this
  /// getter after a fresh install/data-clear captures and locks it in.
  /// Used as the stable anchor for reminder scheduling.
  DateTime get installDate {
    final existing = _prefs.getInt(_keyInstallDateMillis);
    if (existing != null) return DateTime.fromMillisecondsSinceEpoch(existing);
    final now = DateTime.now();
    _prefs.setInt(_keyInstallDateMillis, now.millisecondsSinceEpoch);
    return now;
  }

  // Daily Reminder Settings
  bool get isDailyReminderEnabled =>
      _prefs.getBool(_keyDailyReminderEnabled) ?? true;

  Future<void> setDailyReminderEnabled(bool enabled) async {
    await _prefs.setBool(_keyDailyReminderEnabled, enabled);
  }

  int get dailyReminderHour => _prefs.getInt(_keyDailyReminderHour) ?? 21;

  Future<void> setDailyReminderHour(int hour) async {
    await _prefs.setInt(_keyDailyReminderHour, hour);
  }

  int get dailyReminderMinute => _prefs.getInt(_keyDailyReminderMinute) ?? 0;

  Future<void> setDailyReminderMinute(int minute) async {
    await _prefs.setInt(_keyDailyReminderMinute, minute);
  }

  // Gratitude Reminder Settings
  bool get isGratitudeReminderEnabled =>
      _prefs.getBool(_keyGratitudeReminderEnabled) ?? true;

  Future<void> setGratitudeReminderEnabled(bool enabled) async {
    await _prefs.setBool(_keyGratitudeReminderEnabled, enabled);
  }

  int get gratitudeReminderHour =>
      _prefs.getInt(_keyGratitudeReminderHour) ?? 17;

  Future<void> setGratitudeReminderHour(int hour) async {
    await _prefs.setInt(_keyGratitudeReminderHour, hour);
  }

  int get gratitudeReminderMinute =>
      _prefs.getInt(_keyGratitudeReminderMinute) ?? 0;

  Future<void> setGratitudeReminderMinute(int minute) async {
    await _prefs.setInt(_keyGratitudeReminderMinute, minute);
  }

  /// Regularity in hours (24 = Daily, 72 = Every 3 Days, 168 = Weekly, 720 = Monthly)
  int get gratitudeReminderRegularity =>
      _prefs.getInt(_keyGratitudeReminderRegularity) ?? 72;

  Future<void> setGratitudeReminderRegularity(int hours) async {
    await _prefs.setInt(_keyGratitudeReminderRegularity, hours);
  }

  // Rate Us prompt — shown at most once, after the 7th saved gratitude
  bool get hasShownRateUsPrompt =>
      _prefs.getBool(_keyHasShownRateUsPrompt) ?? false;

  Future<void> setHasShownRateUsPrompt(bool shown) async {
    await _prefs.setBool(_keyHasShownRateUsPrompt, shown);
  }
}
