/// 应用主组件
/// 
/// 这是整个 Flutter 应用的根组件，负责：
/// - 配置全局主题样式
/// - 设置路由管理
/// - 定义应用入口页面
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

import '../core/routing/app_router.dart';
import '../features/admin/presentation/admin_home_page.dart';
import '../features/orders/presentation/root_page.dart';

/// 应用根组件
/// 
/// 使用 MaterialApp 包装整个应用，提供 Material Design 风格的基础设施
class FufuDiningRoomApp extends StatelessWidget {
  const FufuDiningRoomApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Fufu Dining Room', // 应用名称（用于系统任务管理器等）
      theme: _buildTheme(), // 全局主题配置
      onGenerateRoute: AppRouter.onGenerateRoute, // 路由生成器
      // Web 端显示管理后台，移动端显示主应用
      home: kIsWeb ? const AdminHomePage() : const RootPage(),
    );
  }
}

/// 构建全局主题配置
/// 
/// 统一管理整个应用的视觉风格，包括：
/// - 颜色方案（基于品牌色自动生成）
/// - 组件样式（按钮、卡片、标签等）
/// - 字体和间距规范
/// 
/// 修改品牌色：调整 `brand` 常量即可，系统会自动生成配套的颜色方案
ThemeData _buildTheme() {
  // 品牌主色（紫色），可根据设计规范调整
  const brand = Color(0xFF6C63FF);
  
  // 基于品牌色自动生成完整的颜色方案（主色、辅色、背景色等）
  final colorScheme = ColorScheme.fromSeed(
    seedColor: brand,
    brightness: Brightness.light, // 浅色模式
  );

  return ThemeData(
    useMaterial3: true, // 启用 Material Design 3
    colorScheme: colorScheme, // 应用颜色方案
    
    // AppBar（顶部导航栏）主题
    appBarTheme: AppBarTheme(
      elevation: 0, // 无阴影（扁平化设计）
      backgroundColor: colorScheme.surface,
      foregroundColor: colorScheme.onSurface,
      centerTitle: true, // 标题居中
      titleTextStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
    ),
    
    // Card（卡片）主题
    cardTheme: CardThemeData(
      elevation: 0, // 无阴影
      margin: EdgeInsets.zero, // 无外边距（由使用方控制）
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)), // 大圆角
      clipBehavior: Clip.antiAlias, // 裁剪子组件以适配圆角
      color: colorScheme.surface,
    ),
    
    // FilledButton（实心按钮）主题
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        textStyle: const TextStyle(fontWeight: FontWeight.w600),
      ),
    ),
    
    // ElevatedButton（凸起按钮）主题
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        textStyle: const TextStyle(fontWeight: FontWeight.w600),
      ),
    ),
    
    // Chip（标签/芯片）主题
    chipTheme: ChipThemeData(
      shape: StadiumBorder(side: BorderSide.none), // 药丸形状，无边框
      labelStyle: TextStyle(color: colorScheme.onSecondaryContainer),
      backgroundColor: colorScheme.secondaryContainer,
      selectedColor: colorScheme.primaryContainer,
      secondarySelectedColor: colorScheme.primaryContainer,
    ),
    
    // NavigationBar（底部导航栏）主题
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: colorScheme.surface,
      indicatorColor: colorScheme.primaryContainer, // 选中项指示器颜色
      labelTextStyle: MaterialStateProperty.resolveWith(
        (states) => TextStyle(
          // 选中项加粗，未选中项正常字重
          fontWeight: states.contains(MaterialState.selected) ? FontWeight.w700 : FontWeight.w500,
        ),
      ),
    ),
    
    // TabBar（标签栏）主题
    tabBarTheme: TabBarThemeData(
      labelStyle: const TextStyle(fontWeight: FontWeight.w600), // 选中标签加粗
      unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500), // 未选中标签正常
      labelColor: colorScheme.onPrimaryContainer,
      unselectedLabelColor: colorScheme.onSurfaceVariant,
      indicatorSize: TabBarIndicatorSize.tab, // 指示器大小与标签一致
    ),
    
    // Divider（分隔线）主题
    dividerTheme: DividerThemeData(
      color: colorScheme.outlineVariant, // 使用浅色分隔线
    ),
  );  
}

