/// 菜单页面
/// 
/// 客户端的主要功能页面
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/dish.dart';
import '../services/orders_service.dart';

/// 菜单页面组件
class MenuPage extends StatefulWidget {
  const MenuPage({super.key, this.onOrderSubmitted});

  static const String routeName = '/menu';
  final VoidCallback? onOrderSubmitted;

  @override
  State<MenuPage> createState() => _MenuPageState();
}

class _MenuPageState extends State<MenuPage> {
  late final OrdersService _service;
  bool _isLoading = true;
  String? _error;
  List<Dish> _dishes = const [];
  final Map<String, _CartItem> _cart = {};
  final List<String> _categories = const ['荤菜', '素菜', '饮料'];

  @override
  void initState() {
    super.initState();
    _service = OrdersService(Supabase.instance.client);
    _loadMenu();
  }

  /// 计算购物车总价
  double get _cartTotal {
    return _cart.values.fold<double>(
      0,
      (sum, item) => sum + item.dish.price * item.quantity,
    );
  }

  /// 计算购物车总数量
  int get _cartCount {
    return _cart.values.fold<int>(
      0,
      (sum, item) => sum + item.quantity,
    );
  }

  /// 添加菜品到购物车
  void _addToCart(Dish dish) {
    setState(() {
      if (_cart.containsKey(dish.id)) {
        _cart[dish.id]!.quantity++;
      } else {
        _cart[dish.id] = _CartItem(dish: dish, quantity: 1);
      }
    });
  }

  /// 从购物车移除菜品
  void _removeFromCart(String dishId) {
    setState(() {
      if (_cart.containsKey(dishId)) {
        if (_cart[dishId]!.quantity > 1) {
          _cart[dishId]!.quantity--;
        } else {
          _cart.remove(dishId);
        }
      }
    });
  }

  /// 显示购物车对话框
  void _showCart() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => _CartSheet(
        cart: _cart,
        onAdd: _addToCart,
        onRemove: _removeFromCart,
        onCheckout: _checkout,
      ),
    );
  }

  /// 结算
  Future<void> _checkout() async {
    // 关闭购物车
    Navigator.of(context).pop();

    // 提交订单
    try {
      // 将 _CartItem 转换为 createOrder 期望的格式
      final cartItems = <String, ({Dish dish, int quantity})>{};
      _cart.forEach((key, value) {
        cartItems[key] = (dish: value.dish, quantity: value.quantity);
      });

      await _service.createOrder(
        customerName: '客户',
        customerContact: null,
        cartItems: cartItems,
      );

      if (mounted) {
        // 清空购物车
        setState(() {
          _cart.clear();
        });

        // 显示成功提示
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('订单提交成功！')),
        );

        // 通知父组件刷新订单列表
        widget.onOrderSubmitted?.call();
      }
    } catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('提交失败：${error.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _loadMenu() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final dishes = await _service.fetchMenuList();
      setState(() {
        _dishes = dishes;
      });
    } catch (error) {
      setState(() {
        _error = error.toString();
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: _categories.length,
      child: Scaffold(
        backgroundColor: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
        appBar: AppBar(
          elevation: 0,
          backgroundColor: Colors.transparent,
          flexibleSpace: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Theme.of(context).colorScheme.primaryContainer,
                  Theme.of(context).colorScheme.secondaryContainer,
                ],
              ),
            ),
          ),
          title: const Text('美味菜单', style: TextStyle(fontWeight: FontWeight.w600)),
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: IconButton.filledTonal(
                onPressed: _cart.isEmpty ? null : _showCart,
                icon: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    const Icon(Icons.shopping_cart_outlined),
                    if (_cartCount > 0)
                      Positioned(
                        top: -4,
                        right: -4,
                        child: _CartBadge(count: _cartCount),
                      ),
                  ],
                ),
              ),
            ),
          ],
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(56),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: Container(
                height: 44,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.9),
                  borderRadius: BorderRadius.circular(22),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.08),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: TabBar(
                  isScrollable: true,
                  indicatorSize: TabBarIndicatorSize.tab,
                  dividerColor: Colors.transparent,
                  labelPadding: const EdgeInsets.symmetric(horizontal: 20),
                  indicator: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Theme.of(context).colorScheme.primary,
                        Theme.of(context).colorScheme.primary.withOpacity(0.8),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(22),
                    boxShadow: [
                      BoxShadow(
                        color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  labelColor: Colors.white,
                  unselectedLabelColor: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                  labelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                  unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
                  tabs: _categories.map((c) => Tab(text: c)).toList(),
                ),
              ),
            ),
          ),
        ),
        body: TabBarView(
          children: _categories.map((c) {
            return RefreshIndicator(
              onRefresh: _loadMenu,
              child: _buildBody(category: c),
            );
          }).toList(),
        ),
        floatingActionButton: _cart.isEmpty
            ? null
            : Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(28),
                  gradient: LinearGradient(
                    colors: [
                      Theme.of(context).colorScheme.primary,
                      Theme.of(context).colorScheme.tertiary,
                    ],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Theme.of(context).colorScheme.primary.withOpacity(0.4),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: FloatingActionButton.extended(
                  elevation: 0,
                  backgroundColor: Colors.transparent,
                  onPressed: _showCart,
                  icon: const Icon(Icons.shopping_cart_checkout),
                  label: Text(
                    '¥${_cartTotal.toStringAsFixed(2)} 去结算',
                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
                  ),
                ),
              ),
      ),
    );
  }

  Widget _buildBody({required String category}) {
    if (_isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              strokeWidth: 3,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 16),
            Text(
              '加载中...',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      );
    }

    if (_error != null) {
      return ListView(
        children: [
          Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Icon(
                  Icons.error_outline,
                  size: 64,
                  color: Theme.of(context).colorScheme.error.withOpacity(0.6),
                ),
                const SizedBox(height: 16),
                Text(
                  '加载菜单失败',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _error!,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 24),
                FilledButton.icon(
                  onPressed: _loadMenu,
                  icon: const Icon(Icons.refresh),
                  label: const Text('重试'),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  ),
                ),
              ],
            ),
          ),
        ],
      );
    }

    if (_dishes.isEmpty) {
      return ListView(
        children: [
          Padding(
            padding: const EdgeInsets.all(48),
            child: Column(
              children: [
                Icon(
                  Icons.restaurant_menu_outlined,
                  size: 80,
                  color: Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.3),
                ),
                const SizedBox(height: 16),
                Text(
                  '暂无菜品',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      );
    }

    // 根据分类筛选菜品
    final filtered = _dishes
        .where((d) => (d.category.isNotEmpty ? d.category : '荤菜') == category)
        .toList();

    if (filtered.isEmpty) {
      return ListView(
        children: [
          Padding(
            padding: const EdgeInsets.all(48),
            child: Column(
              children: [
                Icon(
                  Icons.search_off,
                  size: 80,
                  color: Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.3),
                ),
                const SizedBox(height: 16),
                Text(
                  '该分类下暂无菜品',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      );
    }

    return ListView.builder(
      itemCount: filtered.length,
      itemBuilder: (context, index) {
        final dish = filtered[index];
        final quantity = _cart[dish.id]?.quantity ?? 0;
        return _MenuCard(
          dish: dish,
          onAdd: () => _addToCart(dish),
          quantity: quantity,
          onMinus: () => _removeFromCart(dish.id),
        );
      },
    );
  }
}

/// 购物车徽章
class _CartBadge extends StatelessWidget {
  const _CartBadge({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.error,
        shape: BoxShape.circle,
      ),
      constraints: const BoxConstraints(
        minWidth: 16,
        minHeight: 16,
      ),
      child: Text(
        count > 99 ? '99+' : count.toString(),
        style: TextStyle(
          color: Theme.of(context).colorScheme.onError,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }
}

/// 菜品卡片
class _MenuCard extends StatelessWidget {
  const _MenuCard({
    required this.dish,
    required this.onAdd,
    required this.quantity,
    required this.onMinus,
  });

  final Dish dish;
  final VoidCallback onAdd;
  final int quantity;
  final VoidCallback onMinus;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 图片区域
            Stack(
              children: [
                if (dish.imageUrl != null && dish.imageUrl!.isNotEmpty)
                  Image.network(
                    dish.imageUrl!,
                    height: 200,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                      height: 200,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            theme.colorScheme.primaryContainer.withOpacity(0.3),
                            theme.colorScheme.secondaryContainer.withOpacity(0.3),
                          ],
                        ),
                      ),
                      child: Center(
                        child: Icon(
                          Icons.restaurant_menu,
                          size: 64,
                          color: theme.colorScheme.onSurfaceVariant.withOpacity(0.3),
                        ),
                      ),
                    ),
                  )
                else
                  Container(
                    height: 200,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          theme.colorScheme.primaryContainer.withOpacity(0.3),
                          theme.colorScheme.secondaryContainer.withOpacity(0.3),
                        ],
                      ),
                    ),
                    child: Center(
                      child: Icon(
                        Icons.restaurant_menu,
                        size: 64,
                        color: theme.colorScheme.onSurfaceVariant.withOpacity(0.3),
                      ),
                    ),
                  ),
                // 价格标签
                Positioned(
                  top: 12,
                  right: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          theme.colorScheme.errorContainer,
                          theme.colorScheme.error.withOpacity(0.8),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Text(
                      '¥${dish.price.toStringAsFixed(2)}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            // 内容区域
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 菜品名称
                  Text(
                    dish.name,
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                    ),
                  ),
                  // 描述
                  if (dish.description != null && dish.description!.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      dish.description!,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                        height: 1.5,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  // 原料标签
                  if (dish.ingredients.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: dish.ingredients.take(4).map((ing) {
                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.surfaceVariant.withOpacity(0.5),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: theme.colorScheme.outline.withOpacity(0.2),
                              width: 1,
                            ),
                          ),
                          child: Text(
                            '${ing.name} ${ing.quantity}${ing.unit}',
                            style: TextStyle(
                              fontSize: 12,
                              color: theme.colorScheme.onSurfaceVariant,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                  const SizedBox(height: 20),
                  // 按钮区域
                  if (quantity == 0)
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: FilledButton.icon(
                        onPressed: onAdd,
                        style: FilledButton.styleFrom(
                          backgroundColor: theme.colorScheme.primary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: 2,
                        ),
                        icon: const Icon(Icons.add_shopping_cart),
                        label: const Text(
                          '加入购物车',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                        ),
                      ),
                    )
                  else
                    Container(
                      height: 48,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            theme.colorScheme.primaryContainer,
                            theme.colorScheme.secondaryContainer,
                          ],
                        ),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: theme.colorScheme.primary.withOpacity(0.2),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: onMinus,
                              borderRadius: BorderRadius.circular(16),
                              child: Container(
                                width: 48,
                                height: 48,
                                alignment: Alignment.center,
                                child: Icon(
                                  quantity == 1 ? Icons.delete_outline : Icons.remove,
                                  color: theme.colorScheme.onPrimaryContainer,
                                ),
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Text(
                              quantity.toString(),
                              style: theme.textTheme.titleLarge?.copyWith(
                                color: theme.colorScheme.onPrimaryContainer,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: onAdd,
                              borderRadius: BorderRadius.circular(16),
                              child: Container(
                                width: 48,
                                height: 48,
                                alignment: Alignment.center,
                                child: Icon(
                                  Icons.add,
                                  color: theme.colorScheme.onPrimaryContainer,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 购物车底部对话框
class _CartSheet extends StatelessWidget {
  const _CartSheet({
    required this.cart,
    required this.onAdd,
    required this.onRemove,
    required this.onCheckout,
  });

  final Map<String, _CartItem> cart;
  final void Function(Dish) onAdd;
  final void Function(String) onRemove;
  final VoidCallback onCheckout;

  @override
  Widget build(BuildContext context) {
    final total = cart.values.fold<double>(
      0,
      (sum, item) => sum + item.dish.price * item.quantity,
    );

    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 20,
                offset: const Offset(0, -4),
              ),
            ],
          ),
          child: Column(
            children: [
              // 拖动条
              Container(
                margin: const EdgeInsets.only(top: 12, bottom: 8),
                width: 48,
                height: 5,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
              // 标题栏
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 8, 16, 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.shopping_cart,
                          color: Theme.of(context).colorScheme.primary,
                          size: 28,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          '购物车',
                          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close),
                      style: IconButton.styleFrom(
                        backgroundColor: Theme.of(context).colorScheme.surfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              // 购物车列表
              Expanded(
                child: ListView.builder(
                  controller: scrollController,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: cart.length,
                  itemBuilder: (context, index) {
                    final item = cart.values.elementAt(index);
                    return Container(
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Row(
                          children: [
                            // 图片
                            ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: item.dish.imageUrl != null && item.dish.imageUrl!.isNotEmpty
                                  ? Image.network(
                                      item.dish.imageUrl!,
                                      width: 70,
                                      height: 70,
                                      fit: BoxFit.cover,
                                      errorBuilder: (context, error, stackTrace) => Container(
                                        width: 70,
                                        height: 70,
                                        color: Theme.of(context).colorScheme.surfaceVariant,
                                        child: Icon(
                                          Icons.restaurant_menu,
                                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                                        ),
                                      ),
                                    )
                                  : Container(
                                      width: 70,
                                      height: 70,
                                      color: Theme.of(context).colorScheme.surfaceVariant,
                                      child: Icon(
                                        Icons.restaurant_menu,
                                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                                      ),
                                    ),
                            ),
                            const SizedBox(width: 16),
                            // 信息
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item.dish.name,
                                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                      fontWeight: FontWeight.w600,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '¥${item.dish.price.toStringAsFixed(2)}',
                                    style: TextStyle(
                                      color: Theme.of(context).colorScheme.primary,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            // 数量控制
                            Container(
                              decoration: BoxDecoration(
                                color: Theme.of(context).colorScheme.surface,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    onPressed: () => onRemove(item.dish.id),
                                    icon: Icon(
                                      item.quantity == 1 ? Icons.delete_outline : Icons.remove,
                                      size: 20,
                                    ),
                                    constraints: const BoxConstraints(
                                      minWidth: 36,
                                      minHeight: 36,
                                    ),
                                    padding: EdgeInsets.zero,
                                  ),
                                  Container(
                                    constraints: const BoxConstraints(minWidth: 32),
                                    alignment: Alignment.center,
                                    child: Text(
                                      item.quantity.toString(),
                                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  IconButton(
                                    onPressed: () => onAdd(item.dish),
                                    icon: const Icon(Icons.add, size: 20),
                                    constraints: const BoxConstraints(
                                      minWidth: 36,
                                      minHeight: 36,
                                    ),
                                    padding: EdgeInsets.zero,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              // 底部结算栏
              Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, -2),
                    ),
                  ],
                ),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                '合计',
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '¥${total.toStringAsFixed(2)}',
                                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                  color: Theme.of(context).colorScheme.primary,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Container(
                            height: 56,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  Theme.of(context).colorScheme.primary,
                                  Theme.of(context).colorScheme.tertiary,
                                ],
                              ),
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: Theme.of(context).colorScheme.primary.withOpacity(0.4),
                                  blurRadius: 12,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: FilledButton(
                              onPressed: onCheckout,
                              style: FilledButton.styleFrom(
                                backgroundColor: Colors.transparent,
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                              child: const Text(
                                '结算',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}


/// 购物车项
class _CartItem {
  final Dish dish;
  int quantity;

  _CartItem({required this.dish, required this.quantity});
}
