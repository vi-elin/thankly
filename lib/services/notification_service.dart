import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter/widgets.dart';
import 'dart:async';
import 'dart:convert';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'dart:io' show Platform;
import '../data/dao/gratitude_dao.dart';
import '../data/entities/gratitude_entity.dart';
import '../core/di/injection.dart';
import 'package:shared_preferences/shared_preferences.dart';

@pragma('vm:entry-point')
void notificationTapBackground(
    NotificationResponse notificationResponse) async {
  debugPrint(
      'notificationTapBackground called with input: ${notificationResponse.input}');

  // Ensure Flutter bindings are initialized
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize dependencies if not already done
  if (!getIt.isRegistered<GratitudeDao>()) {
    debugPrint('Initializing dependencies in background handler...');
    await setupDependencyInjection();
  }

  // Handle the notification response
  debugPrint('Calling handleNotificationResponse from background...');
  await NotificationService.instance
      .handleNotificationResponse(notificationResponse);
  debugPrint('Background handler completed');
}

class NotificationService {
  static final NotificationService instance = NotificationService._init();
  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  NotificationService._init();

  final _gratitudeSavedController = StreamController<void>.broadcast();
  Stream<void> get onGratitudeSaved => _gratitudeSavedController.stream;

  final _navigationController = StreamController<String>.broadcast();
  Stream<String> get navigationStream => _navigationController.stream;

  // Track if we've already handled the launch notification to prevent duplicates
  bool _hasHandledLaunchNotification = false;

  // Track if we've already checked the getNotificationAppLaunchDetails() fallback.
  // That API returns the SAME cached response for the entire app process lifetime,
  // so it must only ever be consulted once per process or it will keep re-saving
  // the same notification on every foreground resume.
  bool _hasCheckedLaunchDetailsFallback = false;

  // Window used by the DB-backed duplicate guard in saveQuickGratitude().
  static const _duplicateSaveWindowMs = 60000;

  bool _listEquals(List<String> a, List<String> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  // Reads the localized "Save" label for the iOS quick-reply button.
  //
  // This runs before EasyLocalization's widget tree is mounted (notification
  // categories must be registered during initialize(), which happens ahead
  // of runApp), so 'save_button'.tr() isn't reliable here. Instead we read
  // the saved locale directly from SharedPreferences (the key EasyLocalization
  // persists it under) and load the matching translation file ourselves.
  Future<String> _localizedSaveButtonTitle() async {
    const fallback = 'Save';
    try {
      final prefs = await SharedPreferences.getInstance();
      final localeCode = prefs.getString('locale') ?? 'en';
      final json =
          await rootBundle.loadString('assets/translations/$localeCode.json');
      final translations = jsonDecode(json) as Map<String, dynamic>;
      return translations['save_button'] as String? ?? fallback;
    } catch (e) {
      debugPrint('Error loading localized save button title: $e');
      return fallback;
    }
  }

  Future<void> initialize() async {
    debugPrint('\n========== NOTIFICATION SERVICE INITIALIZATION ==========');

    // Initialize timezone
    debugPrint('Initializing timezones...');
    tz.initializeTimeZones();
    debugPrint('✓ Timezones initialized');

    // Android initialization settings
    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    final saveButtonTitle = await _localizedSaveButtonTitle();

    // iOS initialization settings with text input category.
    // Permission flags are false here so the system prompt doesn't appear
    // at app startup — it's requested explicitly via requestPermissions()
    // once the user finishes onboarding instead.
    final iosSettings = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
      notificationCategories: [
        DarwinNotificationCategory(
          'gratitude_input',
          actions: <DarwinNotificationAction>[
            DarwinNotificationAction.text(
              'quick_add',
              'Quick Add',
              buttonTitle: saveButtonTitle,
              placeholder: 'What are you grateful for?',
              // No .foreground option: saving from the notification's text
              // field should happen in the background, without opening the app.
              options: <DarwinNotificationActionOption>{},
            ),
          ],
        ),
      ],
    );

    final initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    debugPrint('Registering notification handlers...');
    debugPrint('  - Using static handler for both foreground and background');

    final initialized = await _notifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: notificationTapBackground,
      onDidReceiveBackgroundNotificationResponse: notificationTapBackground,
    );

    debugPrint('✓ Notification plugin initialized: $initialized');
    debugPrint('✓ Handlers registered successfully');

    // Check if app was launched by notification
    debugPrint('Checking if app was launched by notification...');
    final details = await _notifications.getNotificationAppLaunchDetails();
    debugPrint(
        'Launch details: didNotificationLaunchApp=${details?.didNotificationLaunchApp}');
    // getNotificationAppLaunchDetails() returns the same cached value for the
    // whole process lifetime, so mark it as checked now to prevent the
    // checkAndHandlePendingNotification() fallback from re-processing it later.
    _hasCheckedLaunchDetailsFallback = true;

    if (details != null && details.didNotificationLaunchApp) {
      final response = details.notificationResponse;
      if (response != null) {
        debugPrint('!!! App WAS launched by notification !!!');
        debugPrint('Handling launch notification response...');
        await handleNotificationResponse(response);
        // Mark that we've handled the launch notification
        _hasHandledLaunchNotification = true;
        debugPrint('✓ Launch notification handled and flagged');
      }
    } else {
      debugPrint('App was NOT launched by notification (normal app start)');
    }

    debugPrint('========== NOTIFICATION SERVICE READY ==========\n');
  }

  /// Shows the system notification permission prompt. Called once the user
  /// finishes onboarding, rather than at app startup, so it doesn't appear
  /// before they've seen what the app does.
  Future<void> requestPermissions() async {
    if (Platform.isIOS) {
      await _notifications
          .resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin>()
          ?.requestPermissions(
            alert: true,
            badge: true,
            sound: true,
          );
    } else if (Platform.isAndroid) {
      final androidImplementation =
          _notifications.resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();
      await androidImplementation?.requestNotificationsPermission();
    }
  }

  Future<void> _onNotificationTapped(NotificationResponse response) async {
    debugPrint('=== FOREGROUND HANDLER CALLED ===');

    // Ensure dependencies are initialized (safety check)
    if (!getIt.isRegistered<GratitudeDao>()) {
      debugPrint('WARNING: Dependencies not registered, initializing...');
      WidgetsFlutterBinding.ensureInitialized();
      await setupDependencyInjection();
    }

    await handleNotificationResponse(response);
  }

  /// Check for and handle pending notification responses
  /// This is called when the app resumes to catch notifications that didn't trigger the callback
  Future<void> checkAndHandlePendingNotification() async {
    debugPrint('>>> Checking for pending notification responses...');

    // If we already handled the launch notification during initialization, skip this check
    // to prevent duplicate processing
    if (_hasHandledLaunchNotification) {
      debugPrint(
          '>>> Launch notification already handled during initialization, skipping');
      _hasHandledLaunchNotification = false; // Reset for next time
      return;
    }

    // WORKAROUND: Check UserDefaults for notification text saved by native iOS code
    try {
      final prefs = await SharedPreferences.getInstance();
      final pendingText = prefs.getString('pending_gratitude_text');
      final pendingTimestamp = prefs.getDouble('pending_gratitude_timestamp');

      if (pendingText != null && pendingText.isNotEmpty) {
        debugPrint('>>> 🎉 Found pending gratitude in UserDefaults!');
        debugPrint('>>> Text: "$pendingText"');
        debugPrint('>>> Timestamp: $pendingTimestamp');

        // Save the gratitude
        await saveQuickGratitude(pendingText);

        // Clear the pending data
        await prefs.remove('pending_gratitude_text');
        await prefs.remove('pending_gratitude_timestamp');
        debugPrint('>>> Cleared pending gratitude from UserDefaults');

        return; // Exit early since we handled it
      }
    } catch (e) {
      debugPrint('>>> Error checking UserDefaults: $e');
    }

    // Fallback: Try the standard flutter_local_notifications approach.
    // getNotificationAppLaunchDetails() caches the ORIGINAL launch response for
    // the entire app process lifetime, so this must only run once per process -
    // otherwise every foreground resume re-saves the same notification.
    if (_hasCheckedLaunchDetailsFallback) {
      debugPrint(
          '>>> Launch details fallback already checked for this app session, skipping');
      return;
    }
    _hasCheckedLaunchDetailsFallback = true;

    try {
      final details = await _notifications.getNotificationAppLaunchDetails();
      debugPrint(
          '>>> Got launch details: didNotificationLaunchApp=${details?.didNotificationLaunchApp}');

      if (details != null && details.notificationResponse != null) {
        final response = details.notificationResponse!;
        debugPrint('>>> Found pending notification response!');
        debugPrint('>>> Payload: ${response.payload}');
        debugPrint('>>> Action ID: ${response.actionId}');
        debugPrint('>>> Input: ${response.input}');

        // Handle the response
        await handleNotificationResponse(response);
      } else {
        debugPrint('>>> No pending notification responses');
      }
    } catch (e) {
      debugPrint('>>> Error checking pending notifications: $e');
    }
  }

  Future<void> handleNotificationResponse(NotificationResponse response) async {
    debugPrint('=== handleNotificationResponse START ===');
    debugPrint('Notification payload: ${response.payload}');
    debugPrint('Action ID: ${response.actionId}');
    debugPrint('Input text: "${response.input}"');
    debugPrint('Input is null: ${response.input == null}');

    // If this is a gratitude reminder notification (just showing saved gratitude)
    // Signal the app to navigate to the main screen
    if (response.payload == 'gratitude_reminder') {
      debugPrint('Gratitude reminder tapped - signaling navigation to home');
      _navigationController.add('home');
      debugPrint('=== handleNotificationResponse END ===');
      return;
    }

    // Handle daily reminder notifications with text input
    if (response.input != null && response.input!.isNotEmpty) {
      debugPrint('Input is valid, proceeding to save...');
      await saveQuickGratitude(response.input!);
      debugPrint('Save completed');
    } else {
      debugPrint('WARNING: Input is null or empty');
      // DEBUG: Save placeholder if input is missing but action was tapped
      if (response.actionId == 'quick_add') {
        debugPrint('Action is quick_add, saving placeholder...');
        await saveQuickGratitude("Gratitude from notification (input missing)");
      } else {
        debugPrint('Action is not quick_add, skipping save');
      }
    }
    debugPrint('=== handleNotificationResponse END ===');
  }

  Future<void> saveQuickGratitude(String text) async {
    debugPrint('>>> saveQuickGratitude called with text: "$text"');
    debugPrint('>>> Text length: ${text.length}');
    debugPrint('>>> Text trimmed length: ${text.trim().length}');

    if (text.trim().isEmpty) {
      debugPrint('>>> ERROR: Text is empty after trim, skipping save');
      return;
    }

    try {
      debugPrint('>>> Checking if GratitudeDao is registered...');
      debugPrint(
          '>>> GratitudeDao registered: ${getIt.isRegistered<GratitudeDao>()}');

      final dao = getIt<GratitudeDao>();
      debugPrint('>>> Got DAO instance: $dao');

      final items =
          text.split('\n').where((line) => line.trim().isNotEmpty).toList();
      debugPrint('>>> Parsed items: $items');

      // Duplicate guard: the same notification tap can be picked up by more
      // than one path (the plugin's background callback, the native iOS
      // UserDefaults fallback, and the app-launch check), including across
      // separate app opens. Notification responses carry no durable unique
      // ID, so treat an identical entry saved moments ago as the same tap
      // rather than a new one. Checking the DB (not an in-memory flag) means
      // this still catches duplicates even if the two saves happen in
      // different app processes.
      final recentGratitudes = await dao.findAllGratitudes();
      if (recentGratitudes.isNotEmpty) {
        final mostRecent = recentGratitudes.first;
        final now = DateTime.now().millisecondsSinceEpoch;
        final isSameItems = _listEquals(mostRecent.items, items);
        final isWithinDedupeWindow =
            (now - mostRecent.timestamp).abs() < _duplicateSaveWindowMs;
        if (isSameItems && isWithinDedupeWindow) {
          debugPrint(
              '>>> Duplicate of most recent entry detected (saved ${now - mostRecent.timestamp}ms ago), skipping');
          return;
        }
      }

      final entity = GratitudeEntity.fromItems(
        timestamp: DateTime.now().millisecondsSinceEpoch,
        items: items,
      );
      debugPrint('>>> Created entity with timestamp: ${entity.timestamp}');
      debugPrint('>>> Entity items: ${entity.items}');

      debugPrint('>>> Calling dao.insertGratitude...');
      await dao.insertGratitude(entity);
      debugPrint('>>> ✓ Gratitude saved to database successfully!');

      debugPrint('>>> Notifying listeners via stream...');
      _gratitudeSavedController.add(null);
      debugPrint('>>> ✓ Stream notification sent');
    } catch (e, stackTrace) {
      debugPrint('>>> ✗ ERROR saving quick gratitude: $e');
      debugPrint('>>> Stack trace: $stackTrace');
    }
  }

  // Schedule daily reminder to add gratitude
  Future<void> scheduleDailyReminder({
    int hour = 20, // 8 PM by default
    int minute = 0,
  }) async {
    await _notifications.zonedSchedule(
      0, // Notification ID
      'Time for Gratitude',
      'Take a moment to reflect on what you\'re grateful for today',
      _nextInstanceOfTime(hour, minute),
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'daily_reminder',
          'Daily Reminder',
          channelDescription: 'Daily reminder to add gratitude',
          importance: Importance.high,
          priority: Priority.high,
          // Android inline reply action. showsUserInterface is false so
          // replying saves the gratitude in the background without opening the app.
          actions: <AndroidNotificationAction>[
            AndroidNotificationAction(
              'quick_add',
              'Quick Add',
              showsUserInterface: false,
              inputs: <AndroidNotificationActionInput>[
                AndroidNotificationActionInput(
                  label: 'What are you grateful for?',
                ),
              ],
            ),
          ],
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
          // iOS text input category
          categoryIdentifier: 'gratitude_input',
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  // Schedule notification with random gratitude
  Future<void> scheduleRandomGratitudeReminder({
    int hour = 17, // 5pm by default
    int minute = 0,
    int regularityHours =
        168, // How often to repeat (in hours), 0 = every minute (test mode)
  }) async {
    try {
      // Prefer a random gratitude from the last 7 days; fall back to any-time
      // random if the user hasn't written anything that recently, so the
      // reminder still has something to show.
      final dao = getIt<GratitudeDao>();
      final sevenDaysAgo =
          DateTime.now().subtract(const Duration(days: 7)).millisecondsSinceEpoch;
      final randomGratitude = await dao.findRandomGratitudeSince(sevenDaysAgo) ??
          await dao.findRandomGratitude();

      if (randomGratitude == null) {
        // No gratitudes yet, skip
        debugPrint('No gratitudes in database, skipping gratitude reminder');
        return;
      }

      final gratitudeText = randomGratitude.items.join('\n• ');

      // TEST MODE: Every minute (regularityHours = 0)
      if (regularityHours == 0) {
        final now = tz.TZDateTime.now(tz.local);
        // Schedule 60 notifications (one per minute for the next hour)
        const totalNotifications = 60;

        debugPrint(
            'TEST MODE: Scheduling $totalNotifications gratitude reminders (every minute for 1 hour)');

        for (int i = 0; i < totalNotifications; i++) {
          final scheduledTime = now.add(Duration(minutes: i + 1));
          final notificationId = 100 + i;

          await _notifications.zonedSchedule(
            notificationId,
            'Remember this? 💭 [TEST]',
            '• $gratitudeText',
            scheduledTime,
            const NotificationDetails(
              android: AndroidNotificationDetails(
                'gratitude_reminder',
                'Gratitude Reminders',
                channelDescription: 'Random gratitude from your journal',
                importance: Importance.defaultImportance,
                priority: Priority.defaultPriority,
              ),
              iOS: DarwinNotificationDetails(
                presentAlert: true,
                presentBadge: true,
                presentSound: true,
              ),
            ),
            androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
            uiLocalNotificationDateInterpretation:
                UILocalNotificationDateInterpretation.absoluteTime,
            payload: 'gratitude_reminder',
          );
        }
        return;
      }

      // Standard Intervals using DateTimeComponents
      DateTimeComponents? matchComponent;

      if (regularityHours == 24) {
        // Daily
        matchComponent = DateTimeComponents.time;
        debugPrint('Scheduling DAILY gratitude reminder');
      } else if (regularityHours == 168) {
        // Weekly (24 * 7)
        matchComponent = DateTimeComponents.dayOfWeekAndTime;
        debugPrint('Scheduling WEEKLY gratitude reminder');
      } else if (regularityHours == 720) {
        // Monthly (approx 30 days)
        matchComponent = DateTimeComponents.dayOfMonthAndTime;
        debugPrint('Scheduling MONTHLY gratitude reminder');
      }

      if (matchComponent != null) {
        await _notifications.zonedSchedule(
          1, // ID 1 for recurring
          'Remember this? 💭',
          '• $gratitudeText',
          _nextInstanceOfTime(hour, minute),
          const NotificationDetails(
            android: AndroidNotificationDetails(
              'gratitude_reminder',
              'Gratitude Reminders',
              channelDescription: 'Random gratitude from your journal',
              importance: Importance.defaultImportance,
              priority: Priority.defaultPriority,
            ),
            iOS: DarwinNotificationDetails(
              presentAlert: true,
              presentBadge: true,
              presentSound: true,
            ),
          ),
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
          uiLocalNotificationDateInterpretation:
              UILocalNotificationDateInterpretation.absoluteTime,
          matchDateTimeComponents: matchComponent,
          payload: 'gratitude_reminder',
        );
      } else {
        // Custom Intervals (e.g., Every 3 days) or fallback
        // Schedule individual notifications
        final now = tz.TZDateTime.now(tz.local);
        var startTime = tz.TZDateTime(
          tz.local,
          now.year,
          now.month,
          now.day,
          hour,
          minute,
        );

        if (startTime.isBefore(now)) {
          startTime = startTime.add(const Duration(days: 1));
        }

        // For "Every 3 days" (72h), schedule for next 30 days
        // For others, schedule for next 7 days
        final daysToSchedule = regularityHours == 72 ? 30 : 7;
        final intervalDuration = Duration(hours: regularityHours);

        // Calculate total notifications roughly
        // If 72h (3 days), in 30 days -> ~10 notifications
        int count = 0;
        tz.TZDateTime nextTime = startTime;
        final endTime = startTime.add(Duration(days: daysToSchedule));

        debugPrint(
            'Scheduling custom interval ($regularityHours hours) reminders until $endTime');

        while (nextTime.isBefore(endTime)) {
          final notificationId = 1 + (count % 100); // Recycle IDs 1-100

          await _notifications.zonedSchedule(
            notificationId,
            'Remember this? 💭',
            '• $gratitudeText',
            nextTime,
            const NotificationDetails(
              android: AndroidNotificationDetails(
                'gratitude_reminder',
                'Gratitude Reminders',
                channelDescription: 'Random gratitude from your journal',
                importance: Importance.defaultImportance,
                priority: Priority.defaultPriority,
              ),
              iOS: DarwinNotificationDetails(
                presentAlert: true,
                presentBadge: true,
                presentSound: true,
              ),
            ),
            androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
            uiLocalNotificationDateInterpretation:
                UILocalNotificationDateInterpretation.absoluteTime,
            payload: 'gratitude_reminder',
          );

          nextTime = nextTime.add(intervalDuration);
          count++;
        }
        debugPrint('Scheduled $count custom reminders');
      }
    } catch (e) {
      debugPrint('Error scheduling random gratitude: $e');
    }
  }

  tz.TZDateTime _nextInstanceOfTime(int hour, int minute) {
    final now = tz.TZDateTime.now(tz.local);
    var scheduledDate = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );

    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    return scheduledDate;
  }

  // Cancel all notifications
  Future<void> cancelAll() async {
    await _notifications.cancelAll();
  }

  // Cancel specific notification
  Future<void> cancel(int id) async {
    await _notifications.cancel(id);
  }

  // ============= TEST METHODS =============
  // These methods trigger notifications immediately for testing

  /// Test the daily reminder notification (triggers after [delay], default 5 seconds)
  Future<void> testDailyReminder({Duration delay = const Duration(seconds: 5)}) async {
    final now = tz.TZDateTime.now(tz.local);
    final testTime = now.add(delay);

    await _notifications.zonedSchedule(
      999, // Test notification ID
      'Time for Gratitude [TEST]',
      'Take a moment to reflect on what you\'re grateful for today',
      testTime,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'daily_reminder',
          'Daily Reminder',
          channelDescription: 'Daily reminder to add gratitude',
          importance: Importance.high,
          priority: Priority.high,
          // Android inline reply action
          actions: <AndroidNotificationAction>[
            AndroidNotificationAction(
              'quick_add',
              'Quick Add',
              showsUserInterface: false,
              inputs: <AndroidNotificationActionInput>[
                AndroidNotificationActionInput(
                  label: 'What are you grateful for?',
                ),
              ],
            ),
          ],
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
          // iOS text input category
          categoryIdentifier: 'gratitude_input',
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      payload: 'test_daily_reminder', // Add payload for tracking
    );

    debugPrint('Test notification scheduled for ${delay.inSeconds} seconds from now');
  }

  /// Test the random gratitude notification (triggers in 5 seconds)
  Future<void> testRandomGratitudeReminder() async {
    try {
      final dao = getIt<GratitudeDao>();
      final randomGratitude = await dao.findRandomGratitude();

      if (randomGratitude == null) {
        debugPrint('No gratitudes in database to show');
        return;
      }

      final gratitudeText = randomGratitude.items.join('\n• ');
      final now = tz.TZDateTime.now(tz.local);
      final testTime = now.add(const Duration(seconds: 5));

      await _notifications.zonedSchedule(
        998, // Test notification ID
        'Remember this? 💭 [TEST]',
        '• $gratitudeText',
        testTime,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'gratitude_reminder',
            'Gratitude Reminders',
            channelDescription: 'Random gratitude from your journal',
            importance: Importance.defaultImportance,
            priority: Priority.defaultPriority,
          ),
          iOS: DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
      );

      debugPrint(
          'Test random gratitude notification scheduled for 5 seconds from now');
    } catch (e) {
      debugPrint('Error scheduling test random gratitude: $e');
    }
  }

  /// Show an immediate notification (no delay)
  Future<void> showImmediateTestNotification() async {
    debugPrint('Showing immediate test notification...');
    await _notifications.show(
      997,
      'Immediate Test Notification 🔔',
      'Tap me to test notification handling!',
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'test_channel',
          'Test Notifications',
          channelDescription: 'Test notifications',
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      payload: 'immediate_test', // Add payload to track taps
    );
    debugPrint(
        'Immediate test notification shown with payload: immediate_test');
  }
}
