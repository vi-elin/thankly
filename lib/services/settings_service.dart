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

  final SharedPreferences _prefs;

  SettingsService(this._prefs);

  // Daily Reminder Settings
  bool get isDailyReminderEnabled =>
      _prefs.getBool(_keyDailyReminderEnabled) ?? true;

  Future<void> setDailyReminderEnabled(bool enabled) async {
    await _prefs.setBool(_keyDailyReminderEnabled, enabled);
  }

  int get dailyReminderHour => _prefs.getInt(_keyDailyReminderHour) ?? 20;

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
      _prefs.getInt(_keyGratitudeReminderHour) ?? 12;

  Future<void> setGratitudeReminderHour(int hour) async {
    await _prefs.setInt(_keyGratitudeReminderHour, hour);
  }

  int get gratitudeReminderMinute =>
      _prefs.getInt(_keyGratitudeReminderMinute) ?? 0;

  Future<void> setGratitudeReminderMinute(int minute) async {
    await _prefs.setInt(_keyGratitudeReminderMinute, minute);
  }

  /// Regularity in hours (e.g., 1, 2, 4, 8, 12, 24)
  int get gratitudeReminderRegularity =>
      _prefs.getInt(_keyGratitudeReminderRegularity) ?? 24;

  Future<void> setGratitudeReminderRegularity(int hours) async {
    await _prefs.setInt(_keyGratitudeReminderRegularity, hours);
  }
}
