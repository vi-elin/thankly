# Test Notification Button

## Feature Added
Added a "Send Test Notification" button to the Settings screen for easy testing of push notifications.

## Location
The test button is located in the Settings screen under a new "TESTING" section, positioned between the notification settings and the legal section.

## Functionality
When tapped, the button:
1. Calls `NotificationService.testDailyReminder()`
2. Schedules a test notification to appear in 5 seconds
3. Shows a confirmation snackbar message
4. The test notification includes inline text input for quick gratitude entry

## Test Notification Details
- **Title**: "Time for Gratitude 🌟 [TEST]"
- **Body**: "Take a moment to reflect on what you're grateful for today"
- **Delay**: 5 seconds
- **Features**: 
  - Inline text input (iOS and Android)
  - Quick Add button
  - Placeholder text: "What are you grateful for?"

## How to Test
1. Open the app
2. Navigate to Settings (gear icon)
3. Scroll to the "TESTING" section
4. Tap "Send Test Notification"
5. Wait 5 seconds
6. The notification will appear with inline input
7. Type a gratitude and submit
8. Open the app to verify it was saved correctly (without duplication!)

## UI Design
- Orange icon (notification_add)
- Matches the existing settings card design
- Clear title and subtitle
- Send icon on the right

## Files Modified
- `/Users/viktoriia/Projects/gratitude_app/lib/screens/settings_screen.dart`
