# Gratitude Reminder Frequency Update

## Feature: Extended Frequency Options (1 Day to 1 Month)

### What Changed:
Updated the frequency options for Gratitude Reminders to support longer intervals, ranging from daily to monthly.

### New Options:
1. **Every minute (TEST)**: For testing purposes only.
2. **Daily**: Repeats every 24 hours.
3. **Every 3 Days**: Repeats every 72 hours.
4. **Weekly**: Repeats every 7 days (same day of week).
5. **Monthly**: Repeats every ~30 days (same day of month).

### Implementation Details:

#### Settings Screen
- Updated the frequency selector to show the new options.

#### Notification Service
- **Daily (24h)**: Uses `DateTimeComponents.time` for native daily repetition.
- **Weekly (168h)**: Uses `DateTimeComponents.dayOfWeekAndTime` for native weekly repetition.
- **Monthly (720h)**: Uses `DateTimeComponents.dayOfMonthAndTime` for native monthly repetition.
- **Every 3 Days (72h)**: Uses custom scheduling logic to schedule individual notifications for the next 30 days.
- **Test Mode (0)**: Schedules per-minute notifications for immediate testing.

### How to Test:
1. Go to **Settings**.
2. Enable **Gratitude Reminders**.
3. Select one of the new options (e.g., "Weekly").
4. Set the time.
5. Verify in logs or by waiting (for shorter intervals) that notifications are scheduled correctly.

### Console Output:
- "Scheduling DAILY gratitude reminder"
- "Scheduling WEEKLY gratitude reminder"
- "Scheduling MONTHLY gratitude reminder"
- "Scheduling custom interval (72 hours) reminders until [Date]"
