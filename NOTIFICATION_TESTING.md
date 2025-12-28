# Testing Push Notifications

## Quick Access

Tap the **bell icon** (🔔) in the top-right corner of the home screen to access the notification test screen.

## How Notifications Work

### Production Schedule

The app automatically schedules two types of notifications when it starts:

1. **Daily Reminder**: 8:00 PM (20:00) every day
   - Prompts you to add gratitude
   - Has inline text input for quick add
   
2. **Random Gratitude**: 12:00 PM (noon) every day
   - Shows a random gratitude from your journal
   - Reminds you of past gratitudes

### Notification Features

**Both iOS and Android** support inline text input:

- **Long press** the notification
- **Type** directly in the text field
- **Submit** to save the gratitude
- The gratitude is saved to the database automatically
- No need to open the app!

## Testing Notifications

### Option 1: Immediate Test
1. Tap **"Immediate Notification"** button
2. Notification appears right away
3. This tests basic notification functionality

### Option 2: Scheduled Test (5 seconds)
1. Tap **"Daily Reminder (5 sec)"** button
2. **Minimize the app** (go to home screen)
3. Wait 5 seconds
4. Notification appears
5. **Long press** the notification
6. **Type** in the text field (e.g., "Test gratitude")
7. **Submit**
8. Return to the app
9. Your test gratitude should appear in the list!

### Option 3: Random Gratitude Test
1. **First**, add at least one gratitude in the app
2. Tap **"Random Gratitude (5 sec)"** button
3. **Minimize the app**
4. Wait 5 seconds
5. Notification appears showing one of your gratitudes

## Important Notes

⚠️ **You must minimize the app** to see scheduled notifications. Notifications won't appear while the app is in the foreground.

⚠️ **Grant notification permissions** when prompted on first launch.

⚠️ **iOS**: You may need to enable notifications in Settings > Gratitude App > Notifications

⚠️ **Android**: You may need to allow "Alarms & reminders" permission for exact scheduling

## Troubleshooting

### Notifications not appearing?

1. **Check permissions**: 
   - iOS: Settings > Gratitude App > Notifications
   - Android: Settings > Apps > Gratitude App > Notifications

2. **Check Do Not Disturb**: Make sure DND is off or allows notifications

3. **Check the console**: Look for debug messages like:
   - "Test notification scheduled for 5 seconds from now"
   - "Error saving quick gratitude: ..."

### Inline text input not working?

1. **Make sure you long press** the notification (not just tap)
2. **iOS**: Look for the text input field below the notification
3. **Android**: The inline reply should appear automatically

### Quick-add not saving?

1. Check the console for errors
2. Make sure the database is initialized
3. Try adding a gratitude manually first to verify the database works

## Code Reference

- **Notification Service**: [notification_service.dart](file:///Users/viktoriia/Projects/gratitude_app/lib/services/notification_service.dart)
- **Test Methods**: Lines 225-340 in notification_service.dart
- **Test Screen**: [notification_test_screen.dart](file:///Users/viktoriia/Projects/gratitude_app/lib/screens/notification_test_screen.dart)

## Test Methods Available

```dart
// In NotificationService
await getIt<NotificationService>().showImmediateTestNotification();
await getIt<NotificationService>().testDailyReminder();
await getIt<NotificationService>().testRandomGratitudeReminder();
```

You can call these from anywhere in the app using the get_it service locator!
