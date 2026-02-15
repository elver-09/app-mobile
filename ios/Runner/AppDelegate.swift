import Flutter
import UIKit
import AVFoundation

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    let controller = window?.rootViewController as! FlutterViewController
    let flashlightChannel = FlutterMethodChannel(
      name: "com.trainyl/flashlight",
      binaryMessenger: controller.binaryMessenger
    )
    
    flashlightChannel.setMethodCallHandler { (call: FlutterMethodCall, result: @escaping FlutterResult) in
      switch call.method {
      case "enableFlashlight":
        self.enableFlashlight()
        result(nil)
      case "disableFlashlight":
        self.disableFlashlight()
        result(nil)
      default:
        result(FlutterMethodNotImplemented)
      }
    }
    
    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
  
  private func enableFlashlight() {
    guard let device = AVCaptureDevice.default(for: .video) else { return }
    if device.hasTorch {
      do {
        try device.lockForConfiguration()
        try device.setTorchModeOn(level: AVCaptureDevice.maxAvailableTorchLevel)
        device.unlockForConfiguration()
      } catch {
        print("Error enabling flashlight: \(error)")
      }
    }
  }
  
  private func disableFlashlight() {
    guard let device = AVCaptureDevice.default(for: .video) else { return }
    if device.hasTorch {
      do {
        try device.lockForConfiguration()
        device.torchMode = .off
        device.unlockForConfiguration()
      } catch {
        print("Error disabling flashlight: \(error)")
      }
    }
  }
}
