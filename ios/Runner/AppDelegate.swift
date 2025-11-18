import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    // 使用安全的插件注册方式，避免 PathProviderPlugin 在 iOS 18.6.2 上的崩溃
    // 注意：这会跳过 path_provider 插件，file_picker 可能仍可工作（如果它不依赖 path_provider）
    // 如果应用仍然崩溃，可以尝试使用 SafePluginRegistrant.register(with: self)
    // 而不是 GeneratedPluginRegistrant.register(with: self)
    
    // 方案 1: 使用标准注册（如果更新版本后问题已解决）
    // GeneratedPluginRegistrant.register(with: self)
    
    // 方案 2: 使用安全注册（跳过 path_provider，避免 iOS 18.6.2 崩溃）
    SafePluginRegistrant.register(with: self)
    
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
