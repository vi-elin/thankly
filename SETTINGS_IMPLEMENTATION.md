# Settings Screen Implementation

## Overview
Added a comprehensive settings screen with notification preferences for the Gratitude app.

## Features Implemented

### 1. Settings Service (`lib/services/settings_service.dart`)
- Manages notification preferences using SharedPreferences
- Stores settings for:
  - Daily reminder enabled/disabled state
  - Daily reminder time (hour and minute)
  - Gratitude reminder enabled/disabled state
  - Gratitude reminder time (hour and minute)
  - Gratitude reminder regularity (frequency in hours)

### 2. Settings Screen (`lib/screens/settings_screen.dart`)
Beautiful, modern UI with:
- **Two notification switchers:**
  1. Daily Reminder - Get reminded to write daily gratitude
  2. Gratitude Reminders - Get reminded with saved gratitudes

- **Dynamic controls that appear when switchers are ON:**
  - Time selector with iOS-style time picker
  - Frequency selector for gratitude reminders (Every 1h, 2h, 4h, 8h, 12h, or 24h)

- **Design features:**
  - Card-based layout with subtle shadows
  - iOS-style Cupertino switches
  - Color-coded icons (blue for daily, pink for gratitude)
  - Smooth animations and transitions
  - Info card explaining the benefits
  - Clean, modern aesthetic matching the app theme

### 3. Integration
- Added SettingsService to dependency injection
- Updated main.dart to schedule notifications based on user settings
- Added settings icon to home screen app bar
- Notifications are automatically rescheduled when settings change

## How It Works

1. **Initial State**: Both notifications are enabled by default with:
   - Daily reminder at 8:00 PM
   - Gratitude reminder at 12:00 PM (once daily)

2. **User Interaction**:
   - Toggle switches to enable/disable notifications
   - When enabled, time and frequency controls appear below
   - Tap time selector to open iOS-style time picker
   - Tap frequency chips to change how often gratitude reminders appear

3. **Persistence**:
   - All settings are saved to SharedPreferences
   - Settings persist across app restarts
   - Notifications are rescheduled immediately when settings change

## Navigation
- Access settings via the settings icon (⚙️) in the home screen app bar
- Located next to the notification test icon

## Technical Details
- Uses CupertinoSwitch for iOS-style toggles
- CupertinoDatePicker for time selection
- Automatic notification rescheduling on settings changes
- Clean separation of concerns with dedicated SettingsService
