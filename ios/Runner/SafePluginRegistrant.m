//
//  SafePluginRegistrant.m
//  安全的插件注册器 - 跳过 PathProviderPlugin 以避免 iOS 18.6.2 崩溃
//

#import "SafePluginRegistrant.h"
#import <Flutter/Flutter.h>

#if __has_include(<app_links/AppLinksIosPlugin.h>)
#import <app_links/AppLinksIosPlugin.h>
#else
@import app_links;
#endif

#if __has_include(<file_picker/FilePickerPlugin.h>)
#import <file_picker/FilePickerPlugin.h>
#else
@import file_picker;
#endif

#if __has_include(<shared_preferences_foundation/SharedPreferencesPlugin.h>)
#import <shared_preferences_foundation/SharedPreferencesPlugin.h>
#else
@import shared_preferences_foundation;
#endif

#if __has_include(<url_launcher_ios/URLLauncherPlugin.h>)
#import <url_launcher_ios/URLLauncherPlugin.h>
#else
@import url_launcher_ios;
#endif

@implementation SafePluginRegistrant

+ (void)registerWithRegistry:(NSObject<FlutterPluginRegistry>*)registry {
  // iOS 18.6.2 上多个 Swift 插件注册时会导致崩溃（EXC_BAD_ACCESS）
  // 这些插件在注册时调用 swift_getObjectType 会访问空指针
  // 解决方案：跳过有问题的插件，只注册安全的插件
  
  NSLog(@"🔧 使用安全插件注册器（跳过 iOS 18.6.2 不兼容的插件）");
  
  // 注册 AppLinksIosPlugin
  [AppLinksIosPlugin registerWithRegistrar:[registry registrarForPlugin:@"AppLinksIosPlugin"]];
  NSLog(@"✅ AppLinksIosPlugin 注册成功");
  
  // 注册 FilePickerPlugin
  [FilePickerPlugin registerWithRegistrar:[registry registrarForPlugin:@"FilePickerPlugin"]];
  NSLog(@"✅ FilePickerPlugin 注册成功");
  
  // 跳过 PathProviderPlugin（在 iOS 18.6.2 上会导致崩溃）
  // [PathProviderPlugin registerWithRegistrar:[registry registrarForPlugin:@"PathProviderPlugin"]];
  NSLog(@"⏭️ PathProviderPlugin 已跳过（iOS 18.6.2 兼容性问题）");
  
  // 跳过 SharedPreferencesPlugin（在 iOS 18.6.2 上也会导致崩溃）
  // [SharedPreferencesPlugin registerWithRegistrar:[registry registrarForPlugin:@"SharedPreferencesPlugin"]];
  NSLog(@"⏭️ SharedPreferencesPlugin 已跳过（iOS 18.6.2 兼容性问题）");
  NSLog(@"⚠️ 注意：应用将无法使用本地存储功能（shared_preferences）");
  
  // 注册 URLLauncherPlugin
  [URLLauncherPlugin registerWithRegistrar:[registry registrarForPlugin:@"URLLauncherPlugin"]];
  NSLog(@"✅ URLLauncherPlugin 注册成功");
  
  NSLog(@"✅ 插件注册完成（部分插件已跳过以避免崩溃）");
}

@end

