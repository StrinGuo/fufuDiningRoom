//
//  SafeFlutterViewController.m
//  安全的 Flutter View Controller - 修复 iOS 18.6.2 上 VSyncClient 崩溃问题
//

#import "SafeFlutterViewController.h"
#import <objc/runtime.h>

@implementation SafeFlutterViewController

// 使用运行时方法交换来拦截 createTouchRateCorrectionVSyncClientIfNeeded 方法
+ (void)load {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        Class class = [FlutterViewController class];
        
        // 方法选择器
        SEL originalSelector = NSSelectorFromString(@"createTouchRateCorrectionVSyncClientIfNeeded");
        
        // 尝试获取原始方法（使用运行时查找，因为这是私有方法）
        Method originalMethod = class_getInstanceMethod(class, originalSelector);
        
        if (originalMethod) {
            // 创建一个空的实现来替换原方法
            void (^emptyBlock)(id) = ^(id self) {
                // 空实现，什么都不做，避免 VSyncClient 初始化崩溃
                NSLog(@"🔧 SafeFlutterViewController: 已跳过 createTouchRateCorrectionVSyncClientIfNeeded（避免 iOS 18.6.2 崩溃）");
            };
            
            IMP swizzledImplementation = imp_implementationWithBlock(emptyBlock);
            
            // 获取原始实现
            IMP originalImplementation = method_getImplementation(originalMethod);
            
            // 替换实现
            method_setImplementation(originalMethod, swizzledImplementation);
            
            NSLog(@"✅ SafeFlutterViewController: 已成功拦截 createTouchRateCorrectionVSyncClientIfNeeded");
        } else {
            // 如果方法不存在，尝试使用 category 添加一个空实现
            // 这样即使原方法不存在，也不会崩溃
            NSLog(@"⚠️ SafeFlutterViewController: 未找到 createTouchRateCorrectionVSyncClientIfNeeded 方法，尝试添加空实现");
            
            // 添加一个空方法实现
            void (^emptyBlock)(id) = ^(id self) {
                NSLog(@"🔧 SafeFlutterViewController: 空实现已调用（避免崩溃）");
            };
            IMP emptyImplementation = imp_implementationWithBlock(emptyBlock);
            
            // 获取方法签名（void 返回类型，无参数）
            const char *types = "v@:";
            class_addMethod(class, originalSelector, emptyImplementation, types);
            
            NSLog(@"✅ SafeFlutterViewController: 已添加空实现方法");
        }
    });
}

@end

