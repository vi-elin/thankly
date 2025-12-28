# Gratitude Duplication Bug Fix

## Problem Description
When saving gratitudes from push notifications, the gratitude was being saved twice (duplicated). This also occurred when opening the app by tapping on a push notification with previously entered gratitudes.

## Root Cause
The duplication was caused by **double processing** of notification responses:

1. **During app initialization** (`NotificationService.initialize()`):
   - Lines 104-116: The app checks if it was launched by a notification
   - If yes, it calls `handleNotificationResponse()` to save the gratitude

2. **During app resume** (`HomeScreen.didChangeAppLifecycleState()`):
   - Line 49: When the app resumes, it calls `checkAndHandlePendingNotification()`
   - This method checks for pending notifications again
   - Lines 189-203: It finds the same notification response and processes it again
   - This causes the same gratitude to be saved a second time

## Solution
Added a flag `_hasHandledLaunchNotification` to track whether we've already processed the launch notification during initialization:

1. **Added flag** (line 49):
   ```dart
   bool _hasHandledLaunchNotification = false;
   ```

2. **Set flag during initialization** (lines 113-115):
   - When handling a launch notification, set `_hasHandledLaunchNotification = true`
   - This marks that we've already processed this notification

3. **Check flag in checkAndHandlePendingNotification** (lines 164-170):
   - At the start of the method, check if `_hasHandledLaunchNotification` is true
   - If true, skip processing and reset the flag
   - This prevents duplicate processing of the same notification

## Files Modified
- `/Users/viktoriia/Projects/gratitude_app/lib/services/notification_service.dart`

## Testing
To verify the fix:
1. Send a test notification with inline text input
2. Enter a gratitude in the notification
3. Tap to open the app
4. Verify that only ONE gratitude is saved (not duplicated)
5. Check the debug logs to confirm the skip message appears

## Additional Notes
The fix preserves the existing workaround for iOS UserDefaults while preventing duplicate processing through the standard notification response mechanism.
