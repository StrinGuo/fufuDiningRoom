/// 应用路由管理器
/// 
/// 集中管理所有页面的路由配置
/// 当需要导航到某个页面时，使用 Navigator.pushNamed(context, routeName)
/// 
/// 示例：
/// ```dart
/// Navigator.pushNamed(context, MenuPage.routeName);
/// ```
import 'package:flutter/material.dart';

import '../../features/admin/presentation/admin_home_page.dart';
import '../../features/orders/presentation/menu_page.dart';
import '../../features/orders/presentation/order_page.dart';
import '../../features/orders/presentation/root_page.dart';

/// 路由管理器类
/// 
/// 使用静态方法处理路由生成，无需实例化
class AppRouter {
  // 私有构造函数，防止实例化
  const AppRouter._();

  /// 路由生成器
  /// 
  /// 根据路由名称返回对应的页面组件
  /// 如果路由不存在，返回一个错误提示页面
  /// 
  /// [settings] 包含路由名称和参数信息
  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      // 菜单页面路由
      case MenuPage.routeName:
        return MaterialPageRoute(builder: (_) => const MenuPage());
      
      // 订单页面路由
      case OrderPage.routeName:
        return MaterialPageRoute(builder: (_) => const OrderPage());
      
      // 管理端首页路由
      case AdminHomePage.routeName:
        return MaterialPageRoute(builder: (_) => const AdminHomePage());
      
      // 根页面路由（带底部导航的主页面）
      case RootPage.routeName:
        return MaterialPageRoute(builder: (_) => const RootPage());
      
      // 未知路由，显示错误提示
      default:
        return MaterialPageRoute(
          builder: (_) => const Scaffold(
            body: Center(
              child: Text('未知路由'),
            ),
          ),
        );
    }
  }
}

