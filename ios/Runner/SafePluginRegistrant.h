//
//  SafePluginRegistrant.h
//  安全的插件注册器 - 跳过 PathProviderPlugin 以避免 iOS 18.6.2 崩溃
//

#import <Foundation/Foundation.h>
#import <Flutter/Flutter.h>

NS_ASSUME_NONNULL_BEGIN

@interface SafePluginRegistrant : NSObject

+ (void)registerWithRegistry:(NSObject<FlutterPluginRegistry>*)registry;

@end

NS_ASSUME_NONNULL_END

