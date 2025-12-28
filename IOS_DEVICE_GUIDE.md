# How to Run on Real iOS Device

## Prerequisites
- A Mac with Xcode installed
- An Apple ID (Free or Paid)
- An iPhone or iPad
- USB Cable

## Step 1: Open Project in Xcode
1. Open your terminal
2. Navigate to your project folder: `cd /Users/viktoriia/Projects/gratitude_app`
3. Open the iOS workspace:
   ```bash
   open ios/Runner.xcworkspace
   ```

## Step 2: Configure Signing (Crucial!)
1. In Xcode, click on the **Runner** project (blue icon) in the left sidebar.
2. Select the **Runner** target in the main view.
3. Go to the **Signing & Capabilities** tab.
4. Under **Team**, select your Apple ID.
   - If "None" is selected, click **Add an Account...** and log in with your Apple ID.
5. **Bundle Identifier**: You might need to change this if it's already taken.
   - Current: `com.example.gratitudeApp` (or similar)
   - Change to something unique like: `com.viktoriia.gratitudeApp`

## Step 3: Connect Your Device
1. Plug your iPhone/iPad into your Mac.
2. If asked on the device, tap **Trust This Computer** and enter your passcode.
3. In Xcode, look at the top toolbar (where it says "Runner > iPhone 15 Pro Simulator").
4. Click the device name and select your **real device** from the list.

## Step 4: Run the App
1. Click the **Play** button (▶️) in Xcode (top-left).
   - OR run from terminal: `flutter run -d <your_device_name>`
2. Xcode will build and install the app.

## Step 5: Trust Developer (First Time Only)
If the app installs but won't open with an "Untrusted Developer" error:
1. On your iPhone, go to **Settings**.
2. Go to **General** > **VPN & Device Management** (or "Profiles & Device Management").
3. Tap your **Apple ID email**.
4. Tap **Trust "Your Email"**.
5. Tap **Trust** again.

## Step 6: Test Notifications
1. Open the app.
2. Accept the **Notification Permission** prompt.
3. Go to the **Notification Test Screen**.
4. Tap **Daily Reminder (5 sec)**.
5. **Lock your screen** or go to Home Screen.
6. Wait for the notification!

## Troubleshooting
- **"Could not launch"**: Make sure your device is unlocked.
- **"Signing for Runner requires a development team"**: Go back to Step 2 and ensure a Team is selected.
- **"No such module 'Flutter'"**: Run `flutter clean` and `flutter pub get` in your terminal, then try again.
