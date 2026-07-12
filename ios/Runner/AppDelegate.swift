import UIKit
import Flutter
import UserNotifications
// Required for FlutterLocalNotificationsPlugin.setPluginRegistrantCallback.
import flutter_local_notifications

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)

    // Required so notification actions without the .foreground option (e.g. our
    // "Save" quick-reply) can run our Dart background callback via a separate
    // Flutter engine when the app isn't already running, instead of silently
    // failing to save.
    FlutterLocalNotificationsPlugin.setPluginRegistrantCallback { (registry) in
      GeneratedPluginRegistrant.register(with: registry)
    }

    // Set up notification delegate
    if #available(iOS 10.0, *) {
      UNUserNotificationCenter.current().delegate = self
    }

    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
  
  // Handle notification responses (including text input)
  @available(iOS 10.0, *)
  override func userNotificationCenter(
    _ center: UNUserNotificationCenter,
    didReceive response: UNNotificationResponse,
    withCompletionHandler completionHandler: @escaping () -> Void
  ) {
    print("🔔 AppDelegate: Notification response received!")
    print("🔔 Action identifier: \\(response.actionIdentifier)")
    
    // Check if this is a text input response
    if let textResponse = response as? UNTextInputNotificationResponse {
      let userText = textResponse.userText
      print("🔔 User text input: \\(userText)")
      
      // Save to UserDefaults so Flutter can read it
      let defaults = UserDefaults.standard
      defaults.set(userText, forKey: "pending_gratitude_text")
      defaults.set(Date().timeIntervalSince1970, forKey: "pending_gratitude_timestamp")
      defaults.synchronize()
      
      print("🔔 Saved to UserDefaults: \\(userText)")
    }
    
    // Call the super implementation to let flutter_local_notifications handle it too
    super.userNotificationCenter(center, didReceive: response, withCompletionHandler: completionHandler)
  }
}
