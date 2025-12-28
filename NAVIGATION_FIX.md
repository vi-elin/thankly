# Fix: Navigate to Home Screen on Notification Tap

## Problem
Previously, tapping a gratitude reminder notification would open the app but leave the user on the last opened screen (e.g., Settings) instead of navigating to the main screen.

## Solution
Implemented a global navigation mechanism to force navigation to the Home Screen.

### 1. NotificationService Updates
- Added `_navigationController` and `navigationStream` to broadcast navigation events.
- Updated `handleNotificationResponse` to emit a `'home'` event when a gratitude reminder is tapped.

### 2. Main App Updates (`lib/main.dart`)
- Converted `MyApp` to a `StatefulWidget`.
- Added a `GlobalKey<NavigatorState>` to access the navigator globally.
- Added a listener in `initState` that listens for `'home'` events.
- When `'home'` is received, calls `MyApp.navigatorKey.currentState?.popUntil((route) => route.isFirst)` to return to the root screen (Home Screen).

## How to Test
1. Open the app and go to **Settings**.
2. Enable **Gratitude Reminders** and set to **"Every minute (TEST)"**.
3. Keep the app open on the **Settings screen** (or put it in background while on Settings).
4. Wait for the notification.
5. **Tap the notification**.
6. The app should open and **automatically navigate back to the Home Screen**, closing the Settings screen.

## Technical Details
- **Stream**: `Stream<String>` used for loose coupling between service and UI.
- **Navigator Key**: Allows navigation from outside the widget tree context (though here we use it inside `MyApp`).
- **popUntil**: Clears the navigation stack down to the first route, ensuring a clean state on the Home Screen.
