import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:easy_localization/easy_localization.dart';
import 'core/di/injection.dart';
import 'bloc/gratitude_bloc.dart';
import 'bloc/gratitude_event.dart';
import 'screens/home_screen.dart';
import 'services/notification_service.dart';
import 'services/settings_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize easy_localization
  await EasyLocalization.ensureInitialized();

  // Initialize dependency injection
  await setupDependencyInjection();

  // Initialize notifications
  await getIt<NotificationService>().initialize();

  // Get settings service
  final settingsService = getIt<SettingsService>();
  final notificationService = getIt<NotificationService>();

  // Schedule notifications based on user settings
  if (settingsService.isDailyReminderEnabled) {
    await notificationService.scheduleDailyReminder(
      hour: settingsService.dailyReminderHour,
      minute: settingsService.dailyReminderMinute,
    );
  }

  if (settingsService.isGratitudeReminderEnabled) {
    await notificationService.scheduleRandomGratitudeReminder(
      hour: settingsService.gratitudeReminderHour,
      minute: settingsService.gratitudeReminderMinute,
      regularityHours: settingsService.gratitudeReminderRegularity,
    );
  }

  // Smart language detection
  // If device is Ukrainian or Russian -> set Ukrainian
  // Otherwise -> set English
  Locale startLocale = const Locale('en');
  final platformDispatcher = WidgetsBinding.instance.platformDispatcher;
  final deviceLocale = platformDispatcher.locale;
  final languageCode = deviceLocale.languageCode;

  if (languageCode == 'uk' || languageCode == 'ru') {
    startLocale = const Locale('uk');
  }

  runApp(
    EasyLocalization(
      supportedLocales: const [Locale('en'), Locale('uk')],
      path: 'assets/translations',
      fallbackLocale: const Locale('en'),
      startLocale: startLocale,
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    super.initState();
    // Listen for navigation events from notifications
    getIt<NotificationService>().navigationStream.listen((route) {
      if (route == 'home') {
        debugPrint('Navigating to home screen...');
        // Pop until we reach the first route (Home Screen)
        MyApp.navigatorKey.currentState?.popUntil((route) => route.isFirst);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<GratitudeBloc>()..add(const LoadGratitudes()),
      child: MaterialApp(
        navigatorKey: MyApp.navigatorKey,
        title: 'Thankly',
        debugShowCheckedModeBanner: false,

        // Easy Localization configuration
        localizationsDelegates: context.localizationDelegates,
        supportedLocales: context.supportedLocales,
        locale: context.locale,

        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: Colors.black87,
            brightness: Brightness.light,
          ),
          useMaterial3: true,
          fontFamily: 'SF Pro Text',
          scaffoldBackgroundColor: Colors.grey[50],
        ),
        home: const HomeScreen(),
      ),
    );
  }
}
