/// 应用入口文件
/// 
/// 负责初始化 Flutter 框架、Supabase 数据库连接，并启动应用
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app/app.dart';
import 'core/configs/supabase_config.dart';

/// 应用主入口函数
/// 
/// 执行顺序：
/// 1. 确保 Flutter 框架已初始化
/// 2. 初始化 Supabase 客户端（连接后端数据库）
/// 3. 启动应用主界面
Future<void> main() async {
  // 使用 runZonedGuarded 捕获所有未处理的异常，防止应用崩溃
  runZonedGuarded(() async {
    // 确保 Flutter 框架绑定已初始化（必须在使用任何 Flutter 功能前调用）
    WidgetsFlutterBinding.ensureInitialized();

    try {
      // 初始化 Supabase 客户端，建立与后端数据库的连接
      await Supabase.initialize(
        url: SupabaseConfig.url,        // Supabase 项目 URL
        anonKey: SupabaseConfig.anonKey, // 匿名访问密钥
      );
    } catch (e) {
      // 如果 Supabase 初始化失败，打印错误但不阻止应用启动
      // 这样即使网络问题或配置错误，应用也能正常显示界面
      debugPrint('Supabase 初始化失败: $e');
      // 注意：如果应用依赖 Supabase，可能需要显示错误提示页面
    }

    // 启动应用，渲染根组件
    runApp(const FufuDiningRoomApp());
  }, (error, stack) {
    // 捕获所有未处理的异常
    debugPrint('应用启动异常: $error');
    debugPrint('堆栈跟踪: $stack');
    // 即使发生异常，也尝试启动应用（显示错误页面）
    runApp(const FufuDiningRoomApp());
  });
}
