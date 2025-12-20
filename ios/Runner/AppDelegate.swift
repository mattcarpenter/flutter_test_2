import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    // Set up method channel for App Group access
    let controller = window?.rootViewController as! FlutterViewController
    let channel = FlutterMethodChannel(
      name: "app.stockpot.app/app_group",
      binaryMessenger: controller.binaryMessenger
    )

    channel.setMethodCallHandler { (call, result) in
      if call.method == "getContainerPath" {
        let path = FileManager.default.containerURL(
          forSecurityApplicationGroupIdentifier: "group.app.stockpot.app"
        )?.path
        result(path)
      } else {
        result(FlutterMethodNotImplemented)
      }
    }

    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
