# Testing "Every Minute" Notification Feature

## Quick Test Guide

### How to Test:

1. **Open the app** and navigate to **Settings** (⚙️ icon in the home screen)

2. **Enable "Gratitude Reminders"** by toggling the switch ON

3. **Select "Every minute (TEST)"** from the frequency options
   - This is the first option in the frequency selector
   - It's labeled with "(TEST)" to indicate it's for testing purposes

4. **Wait for notifications**
   - First notification will appear in **1 minute**
   - Then another notification every minute after that
   - Total of 60 notifications scheduled (one per minute for the next hour)

### What Happens:

When you select "Every minute (TEST)":
- The app schedules **60 notifications** starting from the current time
- Each notification appears **1 minute apart**
- Notifications are labeled with **[TEST]** in the title: "Remember this? 💭 [TEST]"
- Uses notification IDs 100-159 (separate from regular notifications)

### Console Output:

Check your console/logcat for debug messages:
```
TEST MODE: Scheduling 60 gratitude reminders (every minute for 1 hour)
TEST MODE: Scheduled 60 notifications starting at [timestamp]
```

### Important Notes:

⚠️ **This is for testing only!** 
- Don't leave it on "Every minute" in production
- It will drain battery and spam notifications
- After testing, switch back to a reasonable frequency like "Once a day"

### Troubleshooting:

**If notifications don't appear:**

1. **Check permissions**: Make sure notification permissions are granted
2. **Check battery optimization**: Some Android devices delay notifications to save battery
   - Go to Settings → Apps → Gratitude App → Battery → Unrestricted
3. **Check Do Not Disturb**: Make sure DND mode is off
4. **Check console logs**: Look for error messages in the debug output

**On iOS:**
- Make sure you've granted notification permissions when prompted
- Check Settings → Notifications → Gratitude App → Allow Notifications is ON

**On Android:**
- Go to Settings → Apps → Gratitude App → Notifications
- Make sure "Gratitude Reminders" channel is enabled

### After Testing:

1. Go back to Settings
2. Change frequency to a normal interval (e.g., "Once a day" or "Every 4 hours")
3. The test notifications will be automatically cancelled and replaced with the new schedule

### Other Test Options:

For less aggressive testing, you can also use:
- **"Every hour"** - Good for testing over a few hours
- **"Every 2 hours"** - More realistic testing interval

The "Every minute" option is specifically designed for rapid verification that the notification system is working correctly.
