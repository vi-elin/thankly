import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/settings_service.dart';
import '../services/notification_service.dart';
import '../services/firebase_service.dart';
import '../core/di/injection.dart';
import '../widgets/app_toast.dart';

const _accent        = Color(0xFFE85A8C);
// ignore: unused_element
const _accentPressed = Color(0xFFD94C7D);
// ignore: unused_element
const _accentTint5   = Color(0xFFFFF6F9);
// ignore: unused_element
const _accentTint10  = Color(0xFFFCEAF1);
const _accentTint15  = Color(0xFFF9E1EA);
const _primary       = Color(0xFF211A1C);
const _secondary     = Color(0xFF6C6166);
const _neutralIcon   = Color(0xFF6B6065);
// ignore: unused_element
const _neutralTint   = Color(0xFFF2ECEE);
const _sectionLabel  = Color(0xFF7A7177);
const _chevron       = Color(0xFF807579);
// ignore: unused_element
const _subBg         = Color(0xFFF3F3F5);
const _pageBg        = Color(0xFFF2F2F4);

// Glassmorphism card: frosted gradient with white border and soft pink shadow
final _cardDecoration = BoxDecoration(
  gradient: const LinearGradient(
    begin: Alignment(0.3, -1.0),
    end: Alignment(-0.3, 1.0),
    colors: [Color(0xB8FFFFFF), Color(0x75FFFFFF)],
  ),
  borderRadius: const BorderRadius.all(Radius.circular(26)),
  border: Border.all(color: const Color(0xD9FFFFFF)),
  boxShadow: const [
    BoxShadow(color: Color(0x17462D41), blurRadius: 36, offset: Offset(0, 14)),
  ],
);

// Preset times shown in the time picker sheet
const _presetHours = [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23];

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late final SettingsService _settingsService;
  late final NotificationService _notificationService;

  late bool _dailyReminderEnabled;
  late int _dailyReminderHour;
  late int _dailyReminderMinute;

  late bool _gratitudeReminderEnabled;
  late int _gratitudeReminderHour;
  late int _gratitudeReminderMinute;
  late int _gratitudeReminderRegularity;

  @override
  void initState() {
    super.initState();
    _settingsService = getIt<SettingsService>();
    _notificationService = getIt<NotificationService>();

    _dailyReminderEnabled = _settingsService.isDailyReminderEnabled;
    _dailyReminderHour = _settingsService.dailyReminderHour;
    _dailyReminderMinute = _settingsService.dailyReminderMinute;

    _gratitudeReminderEnabled = _settingsService.isGratitudeReminderEnabled;
    _gratitudeReminderHour = _settingsService.gratitudeReminderHour;
    _gratitudeReminderMinute = _settingsService.gratitudeReminderMinute;
    _gratitudeReminderRegularity = _settingsService.gratitudeReminderRegularity;

    FirebaseService().logScreenView(
      screenName: 'settings_screen',
      screenClass: 'SettingsScreen',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _pageBg,
      appBar: AppBar(
        backgroundColor: _pageBg,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        leading: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Center(
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: const [
                  BoxShadow(color: Color(0x0A000000), blurRadius: 4, offset: Offset(0, 2)),
                ],
              ),
              child: const Icon(Icons.chevron_left, color: _primary, size: 22),
            ),
          ),
        ),
        title: const Text(
          'Settings',
          style: TextStyle(
            fontSize: 21,
            fontWeight: FontWeight.w700,
            color: _primary,
            letterSpacing: -0.21,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(18, 6, 18, 60),
        children: [
          _sectionHeader('notifications_header'.tr()),

          // Daily Reminder
          _buildNotificationCard(
            title: 'daily_reminder_title'.tr(),
            description: 'daily_reminder_description'.tr(),
            icon: Icons.calendar_today_outlined,
            enabled: _dailyReminderEnabled,
            onToggle: () async {
              final value = !_dailyReminderEnabled;
              setState(() => _dailyReminderEnabled = value);
              await _settingsService.setDailyReminderEnabled(value);
              await _updateNotifications();
              await FirebaseService().logEvent(
                name: 'notification_settings_changed',
                parameters: {'notification_type': 'daily_reminder', 'enabled': value},
              );
            },
            expandedContent: _dailyReminderEnabled
                ? _buildTimeSection(
                    hour: _dailyReminderHour,
                    minute: _dailyReminderMinute,
                    onPick: (h, m) async {
                      setState(() { _dailyReminderHour = h; _dailyReminderMinute = m; });
                      await _settingsService.setDailyReminderHour(h);
                      await _settingsService.setDailyReminderMinute(m);
                      await _updateNotifications();
                    },
                  )
                : null,
          ),

          const SizedBox(height: 14),

          // Gratitude Reminders
          _buildNotificationCard(
            title: 'gratitude_reminders_title'.tr(),
            description: 'gratitude_reminders_description'.tr(),
            icon: Icons.favorite_outline,
            enabled: _gratitudeReminderEnabled,
            onToggle: () async {
              final value = !_gratitudeReminderEnabled;
              setState(() => _gratitudeReminderEnabled = value);
              await _settingsService.setGratitudeReminderEnabled(value);
              await _updateNotifications();
              await FirebaseService().logEvent(
                name: 'notification_settings_changed',
                parameters: {'notification_type': 'gratitude_reminder', 'enabled': value},
              );
            },
            expandedContent: _gratitudeReminderEnabled
                ? Column(
                    children: [
                      _buildFrequencySection(),
                      const SizedBox(height: 12),
                      _buildTimeSection(
                        hour: _gratitudeReminderHour,
                        minute: _gratitudeReminderMinute,
                        onPick: (h, m) async {
                          setState(() { _gratitudeReminderHour = h; _gratitudeReminderMinute = m; });
                          await _settingsService.setGratitudeReminderHour(h);
                          await _settingsService.setGratitudeReminderMinute(m);
                          await _updateNotifications();
                        },
                      ),
                    ],
                  )
                : null,
          ),

          _sectionHeader('language_header'.tr()),

          // Language card
          GestureDetector(
            onTap: () => _showLanguageSelector(context),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
              decoration: _cardDecoration,
              child: Row(
                children: [
                  Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      color: const Color(0xD9E4E4E8),
                      borderRadius: BorderRadius.circular(15),
                      border: Border.all(color: const Color(0x80FFFFFF)),
                    ),
                    child: const Icon(Icons.language, color: _neutralIcon, size: 22),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('language_title'.tr(),
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: _primary)),
                        const SizedBox(height: 2),
                        Text(_getLanguageName(context),
                            style: const TextStyle(fontSize: 13.5, color: _secondary)),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right, color: _chevron, size: 22),
                ],
              ),
            ),
          ),

          _sectionHeader('legal_header'.tr()),

          // Legal card
          Container(
            decoration: _cardDecoration,
            child: Column(
              children: [
                _buildLegalRow(
                  icon: Icons.shield_outlined,
                  label: 'privacy_policy'.tr(),
                  onTap: () => _launchURL('https://vi-elin.github.io/thankly/privacy-policy.html'),
                ),
                Container(height: 1, color: const Color(0x12140814), margin: const EdgeInsets.only(left: 70)),
                _buildLegalRow(
                  icon: Icons.description_outlined,
                  label: 'terms_of_service'.tr(),
                  onTap: () => _launchURL('https://vi-elin.github.io/thankly/terms-of-service.html'),
                ),
              ],
            ),
          ),

          const SizedBox(height: 30),

          // Version footer
          Center(
            child: Column(
              children: [
                const Text('Thankly',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: _primary, letterSpacing: 0.15)),
                const SizedBox(height: 3),
                Text('${'version'.tr()} 1.0.0 (1)',
                    style: const TextStyle(fontSize: 12.5, color: Color(0xFFAAA0A4))),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionHeader(String text) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 22, 8, 12),
      child: Text(
        text.toUpperCase(),
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.68,
          color: _sectionLabel,
        ),
      ),
    );
  }

  Widget _buildNotificationCard({
    required String title,
    required String description,
    required IconData icon,
    required bool enabled,
    required VoidCallback onToggle,
    Widget? expandedContent,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: _cardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Pink gradient glassmorphism icon container
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment(-0.87, -0.5),
                    end: Alignment(0.87, 0.5),
                    colors: [Color(0xD9FBDBE9), Color(0x9EF6C8DD)],
                  ),
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(color: const Color(0xBFFFFFFF)),
                ),
                child: Icon(icon, color: const Color(0xFFDB6A92), size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(top: 1),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title,
                          style: const TextStyle(
                              fontSize: 17.5, fontWeight: FontWeight.w700,
                              color: _primary, letterSpacing: -0.175)),
                      const SizedBox(height: 3),
                      Text(description,
                          style: const TextStyle(
                              fontSize: 13.5, color: _secondary, height: 1.45)),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 10),
              _buildToggle(enabled, onToggle),
            ],
          ),
          AnimatedOpacity(
            opacity: expandedContent != null ? 1.0 : 0.0,
            duration: const Duration(milliseconds: 250),
            child: expandedContent != null
                ? Column(
                    children: [
                      const SizedBox(height: 16),
                      expandedContent,
                    ],
                  )
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }

  Widget _buildToggle(bool value, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 50,
        height: 30,
        padding: const EdgeInsets.all(3),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(999),
          gradient: value
              ? const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xFFEFA8C5), Color(0xFFDF7CA0)],
                )
              : null,
          color: value ? null : const Color(0x33787076),
        ),
        child: AnimatedAlign(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeInOut,
          alignment: value ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            width: 24,
            height: 24,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white,
              boxShadow: [BoxShadow(color: Color(0x38000000), blurRadius: 5, offset: Offset(0, 2))],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFrequencySection() {
    final options = [
      (hours: 24, label: 'frequency_daily'.tr()),
      (hours: 72, label: 'frequency_every_3_days'.tr()),
      (hours: 168, label: 'frequency_weekly'.tr()),
      (hours: 720, label: 'frequency_monthly'.tr()),
    ];

    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: const Color(0xB2EBEBEE),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0x8CFFFFFF)),
        boxShadow: const [
          BoxShadow(color: Color(0x0D282832), blurRadius: 2, offset: Offset(0, 1)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            const Icon(Icons.repeat, size: 16, color: _secondary),
            const SizedBox(width: 8),
            Text('frequency_label'.tr(),
                style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600,
                    color: _secondary, letterSpacing: 0.27)),
          ]),
          const SizedBox(height: 13),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: options.map((opt) {
              final isSelected = _gratitudeReminderRegularity == opt.hours;
              return GestureDetector(
                onTap: () async {
                  setState(() => _gratitudeReminderRegularity = opt.hours);
                  await _settingsService.setGratitudeReminderRegularity(opt.hours);
                  await _updateNotifications();
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 11),
                  decoration: BoxDecoration(
                    gradient: isSelected
                        ? const LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [Color(0xFFE580A4), Color(0xFFD2698E)],
                          )
                        : null,
                    color: isSelected ? null : Colors.white,
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(
                      color: isSelected ? const Color(0x66FFFFFF) : const Color(0x241E0F16),
                    ),
                  ),
                  child: Text(
                    opt.label,
                    style: TextStyle(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w600,
                      color: isSelected ? Colors.white : _primary,
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

  Widget _buildTimeSection({
    required int hour,
    required int minute,
    required Function(int, int) onPick,
  }) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: const Color(0xB2EBEBEE),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0x8CFFFFFF)),
        boxShadow: const [
          BoxShadow(color: Color(0x0D282832), blurRadius: 2, offset: Offset(0, 1)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            const Icon(Icons.access_time, size: 16, color: _secondary),
            const SizedBox(width: 8),
            Text('time_label'.tr(),
                style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600,
                    color: _secondary, letterSpacing: 0.27)),
          ]),
          const SizedBox(height: 11),
          GestureDetector(
            onTap: () => _showTimePicker(hour, minute, onPick),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 17, vertical: 15),
              decoration: BoxDecoration(
                color: const Color(0x80FFFFFF),
                borderRadius: BorderRadius.circular(15),
                border: Border.all(color: const Color(0xD9FFFFFF)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _formatTime(hour, minute),
                    style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w700, color: _primary),
                  ),
                  const Icon(Icons.chevron_right, color: _chevron, size: 22),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLegalRow({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: const Color(0xD9E4E4E8),
                borderRadius: BorderRadius.circular(13),
                border: Border.all(color: const Color(0x80FFFFFF)),
              ),
              child: Icon(icon, color: _neutralIcon, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(label,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: _primary)),
            ),
            const Icon(Icons.open_in_new, size: 18, color: _chevron),
          ],
        ),
      ),
    );
  }

  void _showTimePicker(int currentHour, int currentMinute, Function(int, int) onPick) {
    const itemHeight = 52.0;
    final selectedIndex = _presetHours.indexOf(currentHour);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final scrollCtrl = ScrollController();

        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!scrollCtrl.hasClients) return;
          final viewport = scrollCtrl.position.viewportDimension;
          final target = selectedIndex * itemHeight - viewport / 2 + itemHeight / 2;
          scrollCtrl.jumpTo(target.clamp(0.0, scrollCtrl.position.maxScrollExtent));
        });

        return Container(
          height: MediaQuery.of(ctx).size.height * 0.5,
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
          ),
          padding: const EdgeInsets.fromLTRB(14, 10, 14, 30),
          child: Column(
            children: [
              Container(
                width: 42, height: 5,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: const Color(0x24000000),
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              const Text(
                'REMINDER TIME',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700,
                    letterSpacing: 1.56, color: _sectionLabel),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: ListView.builder(
                  controller: scrollCtrl,
                  itemCount: _presetHours.length,
                  itemExtent: itemHeight,
                  itemBuilder: (_, i) {
                    final h = _presetHours[i];
                    final isActive = h == currentHour;
                    return GestureDetector(
                      onTap: () {
                        onPick(h, 0);
                        Navigator.pop(ctx);
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        margin: const EdgeInsets.symmetric(vertical: 1.5),
                        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                        decoration: BoxDecoration(
                          color: isActive ? _accentTint15 : Colors.transparent,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              _formatTime(h, 0),
                              style: TextStyle(
                                fontSize: 17,
                                fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                                color: isActive ? _accent : _primary,
                              ),
                            ),
                            if (isActive)
                              const Icon(Icons.check, color: _accent, size: 20),
                          ],
                        ),
                      ),
                    );
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
    await _notificationService.cancelAll();
    if (_dailyReminderEnabled) {
      await _notificationService.scheduleDailyReminder(
        hour: _dailyReminderHour,
        minute: _dailyReminderMinute,
      );
    }
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
        AppToast.error(context, 'could_not_open_link'.tr());
      }
    }
  }

  void _showLanguageSelector(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
          ),
          padding: const EdgeInsets.fromLTRB(14, 10, 14, 30),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 42, height: 5,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: const Color(0x24000000),
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              Text('language_title'.tr(),
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700,
                      letterSpacing: 1.56, color: _sectionLabel)),
              const SizedBox(height: 12),
              _languageOption(ctx, code: 'en', label: 'language_english'.tr()),
              _languageOption(ctx, code: 'uk', label: 'language_ukrainian'.tr()),
            ],
          ),
        );
      },
    );
  }

  Widget _languageOption(BuildContext sheetCtx, {required String code, required String label}) {
    final isActive = context.locale.languageCode == code;
    return GestureDetector(
      onTap: () async {
        await context.setLocale(Locale(code));
        await FirebaseService().logEvent(name: 'language_changed', parameters: {'language': code});
        if (mounted) Navigator.pop(context);
      },
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 1.5),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 15),
        decoration: BoxDecoration(
          color: isActive ? _accentTint15 : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(label,
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                    color: isActive ? _accent : _primary,
                  )),
            ),
            if (isActive) const Icon(Icons.check, color: _accent, size: 20),
          ],
        ),
      ),
    );
  }
}
