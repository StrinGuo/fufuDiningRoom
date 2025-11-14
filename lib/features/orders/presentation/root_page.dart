/// 根页面（带底部导航的主页面）
/// 
/// 这是应用的主界面，包含底部导航栏，用于在不同功能模块间切换
/// 使用 IndexedStack 保持各页面的状态，切换时不会重新构建
import 'package:flutter/material.dart';

import 'menu_page.dart';
import 'order_page.dart';
import 'report_page.dart';
import 'server_order_page.dart';

/// 根页面组件
/// 
/// 提供 4 个底部导航标签：
/// - 点菜：菜单浏览和下单
/// - 订单：订单列表和详情
/// - 服务端：服务端订单管理
/// - 报告：每月已买订单的食材统计
class RootPage extends StatefulWidget {
  const RootPage({super.key});

  /// 路由名称，用于导航
  static const String routeName = '/root';

  @override
  State<RootPage> createState() => _RootPageState();
}

class _RootPageState extends State<RootPage> {
  /// 当前选中的底部导航索引（0-3）
  int _currentIndex = 0;
  
  /// 订单刷新触发器，当值改变时会触发订单页面刷新
  final ValueNotifier<int> _orderRefreshTrigger = ValueNotifier<int>(0);
  final ValueNotifier<int> _globalRefreshTrigger = ValueNotifier<int>(0);

  @override
  void dispose() {
    _orderRefreshTrigger.dispose();
    _globalRefreshTrigger.dispose();
    super.dispose();
  }

  /// 订单提交成功回调
  /// 
  /// 当菜单页面提交订单成功后，自动刷新订单页面
  void _onOrderSubmitted() {
    // 触发订单页面刷新（通过改变值来触发）
    _orderRefreshTrigger.value++;
    _notifyGlobalRefresh();
  }

  void _notifyGlobalRefresh() {
    _globalRefreshTrigger.value++;
  }

  @override
  Widget build(BuildContext context) {
    // 定义所有页面组件
    // 使用 IndexedStack 可以保持页面状态，切换时不会重新构建
    final pages = <Widget>[
      MenuPage(
        onOrderSubmitted: _onOrderSubmitted,
        globalRefreshTrigger: _globalRefreshTrigger,
        onRequestGlobalRefresh: _notifyGlobalRefresh,
      ), // 点菜页面
      OrderPage(
        refreshTrigger: _orderRefreshTrigger,
        globalRefreshTrigger: _globalRefreshTrigger,
        onRequestGlobalRefresh: _notifyGlobalRefresh,
      ), // 订单列表页
      ServerOrderPage(
        globalRefreshTrigger: _globalRefreshTrigger,
        onRequestGlobalRefresh: _notifyGlobalRefresh,
      ), // 服务端订单管理页
      ReportPage(
        globalRefreshTrigger: _globalRefreshTrigger,
      ), // 报告页面
    ];

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: pages,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.restaurant_menu_outlined),
            selectedIcon: Icon(Icons.restaurant_menu),
            label: '点菜',
          ),
          NavigationDestination(
            icon: Icon(Icons.receipt_long_outlined),
            selectedIcon: Icon(Icons.receipt_long),
            label: '订单',
          ),
          NavigationDestination(
            icon: Icon(Icons.store_outlined),
            selectedIcon: Icon(Icons.store),
            label: '服务端',
          ),
          NavigationDestination(
            icon: Icon(Icons.assessment_outlined),
            selectedIcon: Icon(Icons.assessment),
            label: '报告',
          ),
        ],
        onDestinationSelected: (index) {
          if (index == _currentIndex) return;
          setState(() => _currentIndex = index);
        },
      ),
    );
  }
}

/// 占位页面组件
/// 
/// 用于尚未开发完成的页面，显示"开发中"提示
class _PlaceholderScaffold extends StatelessWidget {
  const _PlaceholderScaffold({required this.title});

  /// 页面标题
  final String title;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(
        child: Text(
          '$title 开发中',
          style: Theme.of(context).textTheme.titleLarge,
        ),
      ),
    );
  }
}

