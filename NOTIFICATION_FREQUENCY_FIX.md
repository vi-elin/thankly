# Notification Frequency Fix

## Problem
The notification system wasn't using the frequency/regularity settings. Both daily reminders and gratitude reminders were always scheduled to repeat once per day, regardless of the user's chosen frequency setting.

## Root Cause
The `scheduleRandomGratitudeReminder` method in `NotificationService` was:
1. Not accepting a `regularityHours` parameter
2. Always using `matchDateTimeComponents: DateTimeComponents.time`, which makes notifications repeat daily
3. The frequency setting from `SettingsService` was never being passed to the notification scheduler

## Solution Implemented

### 1. Updated NotificationService (`lib/services/notification_service.dart`)
Added support for custom frequency intervals:

**For 24-hour intervals (once daily):**
- Uses the standard `matchDateTimeComponents: DateTimeComponents.time` approach
- Notification repeats automatically every day at the specified time

**For intervals less than 24 hours (1h, 2h, 4h, 8h, 12h):**
- Schedules multiple individual notifications for the next 7 days
- Calculates how many notifications per day based on the interval
- Example: "Every 2 hours" = 12 notifications per day × 7 days = 84 total notifications
- Each notification gets a unique ID to avoid conflicts

### 2. Updated Settings Screen (`lib/screens/settings_screen.dart`)
- Now passes the `regularityHours` parameter when calling `scheduleRandomGratitudeReminder`
- The frequency setting is properly applied when notifications are rescheduled

### 3. Updated Main App (`lib/main.dart`)
- Passes the `regularityHours` parameter at app startup
- Ensures notifications use the saved frequency setting from the first launch

## How It Works Now

### Daily Reminder
- Always repeats once per day at the configured time
- No frequency options (it's a daily reminder by definition)

### Gratitude Reminder
**Frequency: Once a day (24 hours)**
- Single notification scheduled with daily repeat
- Efficient and uses minimal notification slots

**Frequency: Every 1-12 hours**
- Schedules 7 days worth of notifications in advance
- Example for "Every 4 hours" starting at 12:00 PM:
  - Day 1: 12:00 PM, 4:00 PM, 8:00 PM, 12:00 AM, 4:00 AM, 8:00 AM
  - Day 2: 12:00 PM, 4:00 PM, 8:00 PM, 12:00 AM, 4:00 AM, 8:00 AM
  - ... continues for 7 days
- After 7 days, user should open the app to reschedule (or we could add a background task)

## Testing Instructions

1. **Open the app** and go to Settings (⚙️ icon)
2. **Enable "Gratitude Reminders"**
3. **Select a frequency** (e.g., "Every 2 hours")
4. **Set a time** that's soon (e.g., 2 minutes from now)
5. **Wait** for the notification to appear
6. **Check** that you receive notifications at the correct interval

### Quick Test
To test immediately:
1. Set frequency to "Every hour"
2. Set time to the current hour (e.g., if it's 9:45 PM, set to 9:00 PM)
3. The first notification should appear at the next hour mark (10:00 PM)
4. Then another at 11:00 PM, etc.

## Important Notes

### Notification Limits
- iOS and Android have limits on scheduled notifications (typically 64)
- For high-frequency settings (every 1-2 hours), we schedule 7 days worth
- User should periodically open the app to refresh notifications

### Battery Optimization
- Some Android devices may delay exact timing due to battery optimization
- Users may need to disable battery optimization for the app in system settings

### Timezone Changes
- Notifications use the device's local timezone
- If user travels to a different timezone, notifications will adjust automatically

## Debug Logging
The notification service now includes debug prints:
- "Scheduled daily gratitude reminder at HH:MM" - for 24-hour frequency
- "Scheduling X gratitude reminders (every Y hours for 7 days)" - for custom frequencies
- Check the console/logcat to verify notifications are being scheduled correctly
