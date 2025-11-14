/// 应用入口文件
/// 
/// 负责初始化 Flutter 框架、Supabase 数据库连接，并启动应用
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
  // 确保 Flutter 框架绑定已初始化（必须在使用任何 Flutter 功能前调用）
  WidgetsFlutterBinding.ensureInitialized();

  // 初始化 Supabase 客户端，建立与后端数据库的连接
  await Supabase.initialize(
    url: SupabaseConfig.url,        // Supabase 项目 URL
    anonKey: SupabaseConfig.anonKey, // 匿名访问密钥
  );

  // 启动应用，渲染根组件
  runApp(const FufuDiningRoomApp());
}
