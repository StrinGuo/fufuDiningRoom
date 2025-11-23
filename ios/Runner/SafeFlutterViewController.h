//
//  SafeFlutterViewController.h
//  安全的 Flutter View Controller - 修复 iOS 18.6.2 上 VSyncClient 崩溃问题
//

#import <Flutter/Flutter.h>

NS_ASSUME_NONNULL_BEGIN

/// 安全的 Flutter View Controller
/// 
/// 修复 iOS 18.6.2 上 VSyncClient 初始化时的崩溃问题
/// 通过禁用触摸率校正 VSyncClient 来避免崩溃
@interface SafeFlutterViewController : FlutterViewController

@end

NS_ASSUME_NONNULL_END

