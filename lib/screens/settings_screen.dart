import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/settings_service.dart';
import '../services/notification_service.dart';
import '../core/di/injection.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late final SettingsService _settingsService;
  late final NotificationService _notificationService;

  // Daily reminder state
  late bool _dailyReminderEnabled;
  late int _dailyReminderHour;
  late int _dailyReminderMinute;

  // Gratitude reminder state
  late bool _gratitudeReminderEnabled;
  late int _gratitudeReminderHour;
  late int _gratitudeReminderMinute;
  late int _gratitudeReminderRegularity;

  @override
  void initState() {
    super.initState();
    _settingsService = getIt<SettingsService>();
    _notificationService = getIt<NotificationService>();

    // Load current settings
    _dailyReminderEnabled = _settingsService.isDailyReminderEnabled;
    _dailyReminderHour = _settingsService.dailyReminderHour;
    _dailyReminderMinute = _settingsService.dailyReminderMinute;

    _gratitudeReminderEnabled = _settingsService.isGratitudeReminderEnabled;
    _gratitudeReminderHour = _settingsService.gratitudeReminderHour;
    _gratitudeReminderMinute = _settingsService.gratitudeReminderMinute;
    _gratitudeReminderRegularity = _settingsService.gratitudeReminderRegularity;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(
          'settings_title'.tr(),
          style: const TextStyle(
            fontWeight: FontWeight.w300,
            letterSpacing: 1.2,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 24),
        children: [
          // Notifications Section Header
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 12),
            child: Text(
              'notifications_header'.tr(),
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Colors.grey[600],
                letterSpacing: 1.0,
              ),
            ),
          ),

          // Daily Reminder Card
          _buildNotificationCard(
            title: 'daily_reminder_title'.tr(),
            description: 'daily_reminder_description'.tr(),
            icon: Icons.calendar_today_outlined,
            iconColor: Colors.blue,
            enabled: _dailyReminderEnabled,
            onToggle: (value) async {
              setState(() {
                _dailyReminderEnabled = value;
              });
              await _settingsService.setDailyReminderEnabled(value);
              await _updateNotifications();
            },
            child: _dailyReminderEnabled
                ? _buildTimeSelector(
                    hour: _dailyReminderHour,
                    minute: _dailyReminderMinute,
                    onTimeChanged: (hour, minute) async {
                      setState(() {
                        _dailyReminderHour = hour;
                        _dailyReminderMinute = minute;
                      });
                      await _settingsService.setDailyReminderHour(hour);
                      await _settingsService.setDailyReminderMinute(minute);
                      await _updateNotifications();
                    },
                  )
                : null,
          ),

          const SizedBox(height: 16),

          // Gratitude Reminder Card
          _buildNotificationCard(
            title: 'gratitude_reminders_title'.tr(),
            description: 'gratitude_reminders_description'.tr(),
            icon: Icons.favorite_outline,
            iconColor: Colors.pink,
            enabled: _gratitudeReminderEnabled,
            onToggle: (value) async {
              setState(() {
                _gratitudeReminderEnabled = value;
              });
              await _settingsService.setGratitudeReminderEnabled(value);
              await _updateNotifications();
            },
            child: _gratitudeReminderEnabled
                ? Column(
                    children: [
                      _buildRegularitySelector(
                        regularity: _gratitudeReminderRegularity,
                        onRegularityChanged: (hours) async {
                          setState(() {
                            _gratitudeReminderRegularity = hours;
                          });
                          await _settingsService
                              .setGratitudeReminderRegularity(hours);
                          await _updateNotifications();
                        },
                      ),
                      const SizedBox(height: 16),
                      _buildTimeSelector(
                        hour: _gratitudeReminderHour,
                        minute: _gratitudeReminderMinute,
                        onTimeChanged: (hour, minute) async {
                          setState(() {
                            _gratitudeReminderHour = hour;
                            _gratitudeReminderMinute = minute;
                          });
                          await _settingsService.setGratitudeReminderHour(hour);
                          await _settingsService
                              .setGratitudeReminderMinute(minute);
                          await _updateNotifications();
                        },
                      ),
                    ],
                  )
                : null,
          ),

          const SizedBox(height: 32),

          // Testing Section Header
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 12),
            child: Text(
              'TESTING',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Colors.grey[600],
                letterSpacing: 1.0,
              ),
            ),
          ),

          // Test Notification Button
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 8,
              ),
              leading: Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.notification_add,
                  color: Colors.orange,
                  size: 24,
                ),
              ),
              title: const Text(
                'Send Test Notification',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Colors.black87,
                ),
              ),
              subtitle: const Text(
                'Test push notification with inline input',
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey,
                ),
              ),
              trailing: Icon(
                Icons.send,
                color: Colors.grey[400],
              ),
              onTap: () async {
                // Send test notification
                await _notificationService.testDailyReminder();

                // Show confirmation
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content:
                          Text('Test notification scheduled for 5 seconds'),
                      behavior: SnackBarBehavior.floating,
                      duration: Duration(seconds: 2),
                    ),
                  );
                }
              },
            ),
          ),

          const SizedBox(height: 32),

          // Legal Section Header
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 12),
            child: Text(
              'legal_header'.tr(),
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Colors.grey[600],
                letterSpacing: 1.0,
              ),
            ),
          ),

          // Legal Links Card
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              children: [
                ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 8,
                  ),
                  leading: Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.privacy_tip_outlined,
                      color: Colors.grey[700],
                      size: 24,
                    ),
                  ),
                  title: Text(
                    'privacy_policy'.tr(),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Colors.black87,
                    ),
                  ),
                  trailing: Icon(
                    Icons.open_in_new,
                    size: 20,
                    color: Colors.grey[400],
                  ),
                  onTap: () {
                    _launchURL(
                        'https://vi-elin.github.io/thankly/privacy-policy.html');
                  },
                ),
                Divider(
                  height: 1,
                  indent: 68,
                  endIndent: 20,
                  color: Colors.grey[200],
                ),
                ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 8,
                  ),
                  leading: Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.description_outlined,
                      color: Colors.grey[700],
                      size: 24,
                    ),
                  ),
                  title: Text(
                    'terms_of_service'.tr(),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Colors.black87,
                    ),
                  ),
                  trailing: Icon(
                    Icons.open_in_new,
                    size: 20,
                    color: Colors.grey[400],
                  ),
                  onTap: () {
                    _launchURL(
                        'https://vi-elin.github.io/thankly/terms-of-service.html');
                  },
                ),
              ],
            ),
          ),

          const SizedBox(height: 32),

          // Language Section Header
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 12),
            child: Text(
              'language_header'.tr(),
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Colors.grey[600],
                letterSpacing: 1.0,
              ),
            ),
          ),

          // Language Selection Card
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 8,
              ),
              leading: Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.language,
                  color: Colors.grey[700],
                  size: 24,
                ),
              ),
              title: Text(
                'language_title'.tr(),
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Colors.black87,
                ),
              ),
              subtitle: Text(
                _getLanguageName(context),
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
              trailing: Icon(
                Icons.chevron_right,
                color: Colors.grey[400],
              ),
              onTap: () => _showLanguageSelector(context),
            ),
          ),

          const SizedBox(height: 32),

          // App Version
          Center(
            child: Column(
              children: [
                Text(
                  'Thankly',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey[600],
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${'version'.tr()} 1.0.0 (1)',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[400],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildNotificationCard({
    required String title,
    required String description,
    required IconData icon,
    required Color iconColor,
    required bool enabled,
    required ValueChanged<bool> onToggle,
    Widget? child,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                // Icon
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: iconColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: iconColor, size: 24),
                ),
                const SizedBox(width: 16),
                // Title and description
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        description,
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey[600],
                          height: 1.3,
                        ),
                      ),
                    ],
                  ),
                ),
                // Switch
                CupertinoSwitch(
                  value: enabled,
                  onChanged: onToggle,
                  activeColor: iconColor,
                ),
              ],
            ),
          ),
          if (child != null)
            Container(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              child: child,
            ),
        ],
      ),
    );
  }

  Widget _buildTimeSelector({
    required int hour,
    required int minute,
    required Function(int hour, int minute) onTimeChanged,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.access_time, size: 18, color: Colors.grey[600]),
              const SizedBox(width: 8),
              Text(
                'time_label'.tr(),
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[700],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          InkWell(
            onTap: () => _showTimePicker(hour, minute, onTimeChanged),
            borderRadius: BorderRadius.circular(8),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _formatTime(hour, minute),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Colors.black87,
                    ),
                  ),
                  Icon(Icons.chevron_right, color: Colors.grey[400]),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRegularitySelector({
    required int regularity,
    required ValueChanged<int> onRegularityChanged,
  }) {
    final regularityOptions = [
      {'hours': 24, 'label': 'frequency_daily'.tr()},
      {'hours': 72, 'label': 'frequency_every_3_days'.tr()},
      {'hours': 168, 'label': 'frequency_weekly'.tr()},
      {'hours': 720, 'label': 'frequency_monthly'.tr()},
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.repeat, size: 18, color: Colors.grey[600]),
              const SizedBox(width: 8),
              Text(
                'frequency_label'.tr(),
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[700],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: regularityOptions.map((option) {
              final hours = option['hours'] as int;
              final label = option['label'] as String;
              final isSelected = regularity == hours;

              return InkWell(
                onTap: () => onRegularityChanged(hours),
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: isSelected ? Colors.pink : Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isSelected ? Colors.pink : Colors.grey[300]!,
                    ),
                  ),
                  child: Text(
                    label,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight:
                          isSelected ? FontWeight.w600 : FontWeight.w400,
                      color: isSelected ? Colors.white : Colors.grey[700],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  void _showTimePicker(
    int currentHour,
    int currentMinute,
    Function(int hour, int minute) onTimeChanged,
  ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        int selectedHour = currentHour;
        int selectedMinute = currentMinute;

        return Container(
          height: 300,
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(color: Colors.grey[200]!),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text('cancel_button'.tr()),
                    ),
                    Text(
                      'select_time'.tr(),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        onTimeChanged(selectedHour, selectedMinute);
                        Navigator.pop(context);
                      },
                      child: Text('done_button'.tr()),
                    ),
                  ],
                ),
              ),
              // Time Picker
              Expanded(
                child: CupertinoDatePicker(
                  mode: CupertinoDatePickerMode.time,
                  initialDateTime: DateTime(
                    2024,
                    1,
                    1,
                    currentHour,
                    currentMinute,
                  ),
                  onDateTimeChanged: (DateTime newDateTime) {
                    selectedHour = newDateTime.hour;
                    selectedMinute = newDateTime.minute;
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  String _formatTime(int hour, int minute) {
    final period = hour >= 12 ? 'PM' : 'AM';
    final displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
    final displayMinute = minute.toString().padLeft(2, '0');
    return '$displayHour:$displayMinute $period';
  }

  Future<void> _updateNotifications() async {
    // Cancel all existing notifications
    await _notificationService.cancelAll();

    // Schedule daily reminder if enabled
    if (_dailyReminderEnabled) {
      await _notificationService.scheduleDailyReminder(
        hour: _dailyReminderHour,
        minute: _dailyReminderMinute,
      );
    }

    // Schedule gratitude reminder if enabled
    if (_gratitudeReminderEnabled) {
      await _notificationService.scheduleRandomGratitudeReminder(
        hour: _gratitudeReminderHour,
        minute: _gratitudeReminderMinute,
        regularityHours: _gratitudeReminderRegularity,
      );
    }
  }

  String _getLanguageName(BuildContext context) {
    final code = context.locale.languageCode;
    if (code == 'uk') return 'language_ukrainian'.tr();
    return 'language_english'.tr();
  }

  Future<void> _launchURL(String url) async {
    final uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('could_not_open_link'.tr()),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void _showLanguageSelector(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(color: Colors.grey[200]!),
                  ),
                ),
                child: Text(
                  'language_title'.tr(),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              // English option
              ListTile(
                leading: const Text('🇬🇧', style: TextStyle(fontSize: 24)),
                title: Text('language_english'.tr()),
                trailing: context.locale.languageCode == 'en'
                    ? const Icon(Icons.check, color: Colors.blue)
                    : null,
                onTap: () async {
                  await context.setLocale(const Locale('en'));
                  if (mounted) {
                    Navigator.pop(context);
                  }
                },
              ),
              // Ukrainian option
              ListTile(
                leading: const Text('🇺🇦', style: TextStyle(fontSize: 24)),
                title: Text('language_ukrainian'.tr()),
                trailing: context.locale.languageCode == 'uk'
                    ? const Icon(Icons.check, color: Colors.blue)
                    : null,
                onTap: () async {
                  await context.setLocale(const Locale('uk'));
                  if (mounted) {
                    Navigator.pop(context);
                  }
                },
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }
}
