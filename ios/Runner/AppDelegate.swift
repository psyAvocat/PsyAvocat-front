import Flutter
import UIKit
import UserNotifications

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)

    // Pont avec Flutter : état et réglages des notifications du téléphone.
    if let registrar = engineBridge.pluginRegistry.registrar(forPlugin: "PsyAvocatNotifications") {
      let canal = FlutterMethodChannel(name: "psyavocat/notifications", binaryMessenger: registrar.messenger())
      canal.setMethodCallHandler { call, result in
        switch call.method {
        case "areNotificationsEnabled":
          UNUserNotificationCenter.current().getNotificationSettings { reglages in
            let autorisees = reglages.authorizationStatus == .authorized
              || reglages.authorizationStatus == .provisional
              || reglages.authorizationStatus == .ephemeral
            DispatchQueue.main.async { result(autorisees) }
          }
        case "openNotificationSettings":
          if let url = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(url)
          }
          result(nil)
        default:
          result(FlutterMethodNotImplemented)
        }
      }
    }
  }
}
