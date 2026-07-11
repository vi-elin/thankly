import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import '../services/settings_service.dart';
import '../core/di/injection.dart';
import 'home_screen.dart';

const _obPrimary = Color(0xFF211A1C);
const _obHeading = Color(0xFF4A4044);
const _obSecondary = Color(0xFF8A8086);
const _obBullet = Color(0xFFE58BAC);
const _obAccent = Color(0xFFE85A8C);
const _obFaint = Color(0xFFC1BAC0);
const _obSectionLabel = Color(0xFF7A7177);
const _obCardText = Color(0xFF352D31);
const _obListText = Color(0xFF2A2327);
const _obPlaceholder = Color(0xFFB09AA3);

const _obAccentGradient = LinearGradient(
  begin: Alignment.topCenter,
  end: Alignment.bottomCenter,
  colors: [Color(0xFFE580A4), Color(0xFFD2698E)],
);

// Flat white card shadow, matching gratitude_card.dart / home_screen.dart's
// real on-screen cards.
const _flatCardShadow = [
  BoxShadow(color: Color(0x0A000000), blurRadius: 4, offset: Offset(0, 2)),
];

/// A miniature "device screen" frame used to make onboarding examples read
/// as accurate previews of the app's real screens (page background + real
/// chrome), rather than an abstract glass card.
class _DeviceFrame extends StatelessWidget {
  final double width;
  final Widget child;

  const _DeviceFrame({
    required this.width,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: const Color(0xFFF2F2F4),
        borderRadius: BorderRadius.circular(34),
        boxShadow: const [
          BoxShadow(color: Color(0x2E462D41), blurRadius: 40, offset: Offset(0, 20)),
        ],
      ),
      child: child,
    );
  }
}

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  static const _pageCount = 4;

  final _pageController = PageController();
  int _step = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _goTo(int index) {
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeOutCubic,
    );
  }

  void _handleContinue() {
    if (_step >= _pageCount - 1) {
      _finish();
      return;
    }
    _goTo(_step + 1);
  }

  Future<void> _finish() async {
    final settingsService = getIt<SettingsService>();
    await settingsService.setHasCompletedOnboarding(true);
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const HomeScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment(-0.6, -1),
            end: Alignment(0.6, 1),
            colors: [Color(0xFFFAFAFB), Color(0xFFFBF8F9), Color(0xFFF7EEF1)],
          ),
        ),
        child: SafeArea(
          child: Stack(
            children: [
              PageView(
                controller: _pageController,
                onPageChanged: (i) => setState(() => _step = i),
                children: const [
                  _WelcomePage(),
                  _OneLinePage(),
                  _NotificationPage(),
                  _RemindersPage(),
                ],
              ),
              Positioned(
                top: 6,
                right: 24,
                child: GestureDetector(
                  onTap: _finish,
                  child: Padding(
                    padding: const EdgeInsets.all(6),
                    child: Text(
                      'onboarding_skip'.tr(),
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: _obSecondary,
                      ),
                    ),
                  ),
                ),
              ),
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: _BottomBar(
                  step: _step,
                  pageCount: _pageCount,
                  onDotTap: _goTo,
                  onContinue: _handleContinue,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BottomBar extends StatelessWidget {
  final int step;
  final int pageCount;
  final ValueChanged<int> onDotTap;
  final VoidCallback onContinue;

  const _BottomBar({
    required this.step,
    required this.pageCount,
    required this.onDotTap,
    required this.onContinue,
  });

  @override
  Widget build(BuildContext context) {
    final isLast = step >= pageCount - 1;
    return Container(
      padding: const EdgeInsets.fromLTRB(30, 20, 30, 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Theme.of(context).scaffoldBackgroundColor.withValues(alpha: 0),
            const Color(0xFFF2F2F4).withValues(alpha: 0.92),
          ],
          stops: const [0.0, 0.3],
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              for (int i = 0; i < pageCount; i++) ...[
                if (i > 0) const SizedBox(width: 8),
                GestureDetector(
                  onTap: () => onDotTap(i),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    width: i == step ? 22 : 8,
                    height: 8,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(999),
                      gradient: i == step ? _obAccentGradient : null,
                      color: i == step ? null : const Color(0x47786E74),
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 22),
          GestureDetector(
            onTap: onContinue,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 19),
              decoration: BoxDecoration(
                gradient: _obAccentGradient,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: const Color(0x66FFFFFF)),
              ),
              child: Center(
                child: Text(
                  isLast ? 'onboarding_get_started'.tr() : 'onboarding_continue'.tr(),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    letterSpacing: -0.18,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Max height of the "examples area" (screenshot or hand-built mockup).
// Kept small on purpose so there's always visible breathing room between
// the example and the title/description below it.
const _obMockupMaxHeight = 300.0;

class _PageScaffold extends StatelessWidget {
  final String imagePath;
  final Widget mockup;
  final String title;
  final String subtitle;
  final double maxMockupHeight;

  const _PageScaffold({
    required this.imagePath,
    required this.mockup,
    required this.title,
    required this.subtitle,
    this.maxMockupHeight = _obMockupMaxHeight,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(30, 64, 30, 168),
      child: Column(
        children: [
          Expanded(
            child: Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(maxHeight: maxMockupHeight),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: _ScreenshotOrMockup(assetPath: imagePath, fallback: mockup),
                ),
              ),
            ),
          ),
          const SizedBox(height: 30),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 29,
              fontWeight: FontWeight.w800,
              color: _obPrimary,
              letterSpacing: -0.7,
              height: 1.12,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: _obSecondary,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

/// Shows a real onboarding screenshot from assets/onboarding/ with rounded
/// corners, falling back to the hand-built illustration if the asset isn't
/// present yet (drop screenshots into that folder to replace the fallback).
class _ScreenshotOrMockup extends StatelessWidget {
  final String assetPath;
  final Widget fallback;

  const _ScreenshotOrMockup({required this.assetPath, required this.fallback});

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      assetPath,
      fit: BoxFit.contain,
      errorBuilder: (context, error, stackTrace) => fallback,
      frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
        if (frame == null && !wasSynchronouslyLoaded) return const SizedBox.shrink();
        return Container(
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(32),
            boxShadow: const [
              BoxShadow(color: Color(0x2E462D41), blurRadius: 40, offset: Offset(0, 20)),
            ],
          ),
          child: child,
        );
      },
    );
  }
}

// ---------- Page 1: Welcome ----------

class _WelcomePage extends StatelessWidget {
  const _WelcomePage();

  static Widget _cardLine(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(right: 10, top: 6),
            child: Container(
              width: 6,
              height: 6,
              decoration: const BoxDecoration(color: _obBullet, shape: BoxShape.circle),
            ),
          ),
          Expanded(
            child: Text(text,
                style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w400, height: 1.4, color: _obCardText)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return _PageScaffold(
      imagePath: 'assets/onboarding/onboarding_1.png',
      title: 'onboarding_title_1'.tr(),
      subtitle: 'onboarding_subtitle_1'.tr(),
      mockup: _DeviceFrame(
        width: 375,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 22),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Center(
                child: Column(
                  children: [
                    Text('62 Gratitudes',
                        style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w500, color: _obSecondary)),
                    SizedBox(height: 2),
                    Text('28 Grateful Days',
                        style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w500, color: _obSecondary)),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              Padding(
                padding: const EdgeInsets.only(left: 4, bottom: 10),
                child: Text('TODAY',
                    style: const TextStyle(
                        fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: 1.68, color: _obSectionLabel)),
              ),
              Container(
                padding: const EdgeInsets.all(16),
                margin: const EdgeInsets.only(bottom: 12),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.all(Radius.circular(20)),
                  boxShadow: _flatCardShadow,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _cardLine('My sister called'),
                    _cardLine('Someone smiled at me'),
                    _cardLine('Beautiful sunset on the way home'),
                    const SizedBox(height: 4),
                    Align(
                      alignment: Alignment.centerRight,
                      child: Text('8:57 PM',
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: _obFaint)),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.all(Radius.circular(20)),
                  boxShadow: _flatCardShadow,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _cardLine('Morning coffee tasted especially good'),
                    _cardLine('Fresh air on my walk'),
                    const SizedBox(height: 4),
                    Align(
                      alignment: Alignment.centerRight,
                      child: Text('9:08 AM',
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: _obFaint)),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------- Page 2: One line = one gratitude ----------

class _OneLinePage extends StatelessWidget {
  const _OneLinePage();

  static Widget _typedLine(String text, {bool showCursor = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Text('• $text',
              style: const TextStyle(
                  fontSize: 17, fontWeight: FontWeight.w500, height: 1.5, letterSpacing: -0.2, color: _obListText)),
          if (showCursor) const _BlinkingCursor(),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return _PageScaffold(
      imagePath: 'assets/onboarding/onboarding_2.png',
      title: 'onboarding_title_2'.tr(),
      subtitle: 'onboarding_subtitle_2'.tr(),
      mockup: _DeviceFrame(
        width: 300,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(22, 22, 22, 30),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration:
                        const BoxDecoration(color: Colors.white, shape: BoxShape.circle, boxShadow: _flatCardShadow),
                    child: const Icon(Icons.chevron_left, size: 19, color: _obListText),
                  ),
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      gradient: _obAccentGradient,
                      shape: BoxShape.circle,
                      boxShadow: const [
                        BoxShadow(color: Color(0x57B2446A), blurRadius: 12, offset: Offset(0, 5)),
                      ],
                    ),
                    child: const Icon(Icons.check, size: 17, color: Colors.white),
                  ),
                ],
              ),
              const SizedBox(height: 22),
              Text(
                'what_are_you_grateful_for'.tr(),
                style: const TextStyle(
                    fontSize: 20, fontWeight: FontWeight.w700, color: _obHeading, letterSpacing: -0.5, height: 1.12),
              ),
              const SizedBox(height: 10),
              _typedLine('My family'),
              _typedLine('Morning coffee'),
              _typedLine('A beautiful sunset', showCursor: true),
            ],
          ),
        ),
      ),
    );
  }
}

class _BlinkingCursor extends StatefulWidget {
  const _BlinkingCursor();

  @override
  State<_BlinkingCursor> createState() => _BlinkingCursorState();
}

class _BlinkingCursorState extends State<_BlinkingCursor> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 1100))..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 3),
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          final visible = _controller.value < 0.5;
          return Opacity(
            opacity: visible ? 1 : 0,
            child: Container(width: 2, height: 17, color: _obAccent),
          );
        },
      ),
    );
  }
}

// ---------- Page 3: Reply from notification ----------

class _NotificationPage extends StatelessWidget {
  const _NotificationPage();

  @override
  Widget build(BuildContext context) {
    return _PageScaffold(
      imagePath: 'assets/onboarding/onboarding_3.png',
      title: 'onboarding_title_3'.tr(),
      subtitle: 'onboarding_subtitle_3'.tr(),
      mockup: SizedBox(
        width: 280,
        child: Container(
          padding: const EdgeInsets.fromLTRB(16, 15, 16, 15),
          decoration: BoxDecoration(
            color: const Color(0xB8FFFFFF),
            borderRadius: BorderRadius.circular(26),
            boxShadow: const [
              BoxShadow(color: Color(0x33462D41), blurRadius: 40, offset: Offset(0, 18)),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        begin: Alignment(-0.87, -0.5),
                        end: Alignment(0.87, 0.5),
                        colors: [Color(0xFFF7C6DC), Color(0xFFE58BAC)],
                      ),
                      borderRadius: BorderRadius.circular(11),
                      boxShadow: const [
                        BoxShadow(color: Color(0x48B2446A), blurRadius: 8, offset: Offset(0, 3)),
                      ],
                    ),
                    child: const Icon(Icons.auto_awesome, size: 19, color: Colors.white),
                  ),
                  const SizedBox(width: 11),
                  const Expanded(
                    child: Text('GRATITUDE',
                        style: TextStyle(
                            fontSize: 14, fontWeight: FontWeight.w700, color: _obPrimary, letterSpacing: 0.2)),
                  ),
                  const Text('now', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w500, color: _obSecondary)),
                ],
              ),
              const SizedBox(height: 11),
              const Text('What made you smile today?',
                  style: TextStyle(fontSize: 15.5, fontWeight: FontWeight.w700, color: _obPrimary)),
              const SizedBox(height: 3),
              const Text('Tap to capture a grateful moment.',
                  style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.w500, color: Color(0xFF6C6166), height: 1.4)),
              const SizedBox(height: 13),
              Container(
                padding: const EdgeInsets.fromLTRB(16, 6, 6, 6),
                decoration: BoxDecoration(
                  color: const Color(0xE6F0F0F3),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: const Color(0xB3FFFFFF)),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text('${'edit_your_gratitude'.tr()}…',
                          style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w500, color: _obPlaceholder)),
                    ),
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        gradient: _obAccentGradient,
                        shape: BoxShape.circle,
                        boxShadow: const [
                          BoxShadow(color: Color(0x52B2446A), blurRadius: 10, offset: Offset(0, 4)),
                        ],
                      ),
                      child: const Icon(Icons.arrow_upward, size: 16, color: Colors.white),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------- Page 4: Daily reminders ----------

// Non-interactive, pixel-accurate replica of settings_screen.dart's
// NOTIFICATIONS section (_buildNotificationCard / _buildFrequencySection /
// _buildTimeSection), used verbatim as an onboarding example.

const _settingsPrimary = Color(0xFF211A1C);
const _settingsSecondary = Color(0xFF6C6166);
const _settingsChevron = Color(0xFF807579);

final _settingsCardDecoration = BoxDecoration(
  gradient: const LinearGradient(
    begin: Alignment(0.3, -1.0),
    end: Alignment(-0.3, 1.0),
    colors: [Color(0xB8FFFFFF), Color(0x75FFFFFF)],
  ),
  borderRadius: BorderRadius.circular(26),
  border: Border.all(color: const Color(0xD9FFFFFF)),
  boxShadow: const [
    BoxShadow(color: Color(0x17462D41), blurRadius: 36, offset: Offset(0, 14)),
  ],
);

final _settingsSubSectionDecoration = BoxDecoration(
  color: const Color(0xB2EBEBEE),
  borderRadius: BorderRadius.circular(18),
  border: Border.all(color: const Color(0x8CFFFFFF)),
  boxShadow: const [
    BoxShadow(color: Color(0x0D282832), blurRadius: 2, offset: Offset(0, 1)),
  ],
);

class _RemindersPage extends StatelessWidget {
  const _RemindersPage();

  @override
  Widget build(BuildContext context) {
    return _PageScaffold(
      imagePath: 'assets/onboarding/onboarding_4.png',
      title: 'onboarding_title_4'.tr(),
      subtitle: 'onboarding_subtitle_4'.tr(),
      maxMockupHeight: 460,
      mockup: _DeviceFrame(
        width: 300,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 22, 16, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.only(left: 8, bottom: 12),
                child: Text('notifications_header'.tr(),
                    style: const TextStyle(
                        fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: 1.68, color: _obSectionLabel)),
              ),
              _SettingsNotificationCard(
                icon: Icons.calendar_today_outlined,
                title: 'daily_reminder_title'.tr(),
                description: 'daily_reminder_description'.tr(),
                expandedContent: _SettingsTimeSection(timeLabel: '5:00 PM'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SettingsNotificationCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final Widget expandedContent;

  const _SettingsNotificationCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.expandedContent,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _settingsCardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment(-0.87, -0.5),
                    end: Alignment(0.87, 0.5),
                    colors: [Color(0xD9FBDBE9), Color(0x9EF6C8DD)],
                  ),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xBFFFFFFF)),
                ),
                child: Icon(icon, color: const Color(0xFFDB6A92), size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(top: 1),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title,
                          style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: _settingsPrimary,
                              letterSpacing: -0.16)),
                      const SizedBox(height: 3),
                      Text(description, style: const TextStyle(fontSize: 12.5, color: _settingsSecondary, height: 1.4)),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              const _SettingsToggle(),
            ],
          ),
          const SizedBox(height: 14),
          expandedContent,
        ],
      ),
    );
  }
}

class _SettingsToggle extends StatelessWidget {
  const _SettingsToggle();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 46,
      height: 27,
      padding: const EdgeInsets.all(3),
      alignment: Alignment.centerRight,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFEFA8C5), Color(0xFFDF7CA0)],
        ),
      ),
      child: Container(
        width: 21,
        height: 21,
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white,
          boxShadow: [BoxShadow(color: Color(0x38000000), blurRadius: 5, offset: Offset(0, 2))],
        ),
      ),
    );
  }
}

class _SettingsTimeSection extends StatelessWidget {
  final String timeLabel;

  const _SettingsTimeSection({required this.timeLabel});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(13),
      decoration: _settingsSubSectionDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            const Icon(Icons.access_time, size: 15, color: _settingsSecondary),
            const SizedBox(width: 7),
            Text('time_label'.tr(),
                style: const TextStyle(
                    fontSize: 12.5, fontWeight: FontWeight.w600, color: _settingsSecondary, letterSpacing: 0.25)),
          ]),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 13),
            decoration: BoxDecoration(
              color: const Color(0x80FFFFFF),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xD9FFFFFF)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(timeLabel,
                    style: const TextStyle(fontSize: 17.5, fontWeight: FontWeight.w700, color: _settingsPrimary)),
                const Icon(Icons.chevron_right, color: _settingsChevron, size: 20),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
