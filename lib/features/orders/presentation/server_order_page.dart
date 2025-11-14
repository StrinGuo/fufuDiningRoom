/// 服务端订单管理页面
/// 
/// 用于服务端查看订单、接单、拒绝订单等操作
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/order.dart';
import '../services/orders_service.dart';

/// 服务端订单管理页面组件
class ServerOrderPage extends StatefulWidget {
  const ServerOrderPage({
    super.key,
    this.globalRefreshTrigger,
    this.onRequestGlobalRefresh,
  });

  static const String routeName = '/server-orders';
  final ValueNotifier<int>? globalRefreshTrigger;
  final VoidCallback? onRequestGlobalRefresh;

  @override
  State<ServerOrderPage> createState() => _ServerOrderPageState();
}

class _ServerOrderPageState extends State<ServerOrderPage> {
  /// 订单服务实例
  late final OrdersService _service;

  /// 是否正在加载
  bool _isLoading = true;
  
  /// 错误信息
  String? _error;
  
  /// 订单列表
  List<Order> _orders = const [];

  @override
  void initState() {
    super.initState();
    _service = OrdersService(Supabase.instance.client);
    _loadOrders();
    widget.globalRefreshTrigger?.addListener(_onGlobalRefreshTriggered);
  }

  @override
  void dispose() {
    widget.globalRefreshTrigger?.removeListener(_onGlobalRefreshTriggered);
    super.dispose();
  }

  /// 加载订单列表
  Future<void> _loadOrders() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final orders = await _service.fetchOrderList();
      setState(() {
        _orders = orders;
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

  /// 接单并计算原料
  Future<void> _acceptOrder(Order order) async {
    // 确认对话框
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('确认接单'),
        content: Text('确定要接单 #${order.id.substring(0, 8)} 吗？\n接单后将自动计算所需原料。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('确认接单'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    // 显示加载提示
    if (!context.mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: Card(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('正在接单并计算原料...'),
              ],
            ),
          ),
        ),
      ),
    );

    try {
      // 1. 更新订单状态为已接单
      await _service.acceptOrder(order.id);
      
      // 2. 计算并更新原料清单
      await _service.calculateAndUpdateIngredients(order.id);

      if (context.mounted) {
        Navigator.of(context).pop(); // 关闭加载对话框
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('接单成功！原料清单已计算'),
            backgroundColor: Colors.green,
          ),
        );
        // 刷新订单列表
        _loadOrders();
        widget.onRequestGlobalRefresh?.call();
      }
    } catch (error) {
      if (context.mounted) {
        Navigator.of(context).pop(); // 关闭加载对话框
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('接单失败：${error.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// 拒绝订单
  Future<void> _rejectOrder(Order order) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('确认拒绝'),
        content: Text('确定要拒绝订单 #${order.id.substring(0, 8)} 吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('确认拒绝'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await _service.rejectOrder(order.id);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('订单已拒绝'),
            backgroundColor: Colors.orange,
          ),
        );
        _loadOrders();
        widget.onRequestGlobalRefresh?.call();
      }
    } catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('操作失败：${error.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('服务端订单管理'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadOrders,
            tooltip: '刷新',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadOrders,
        child: _buildBody(),
      ),
    );
  }

  /// 构建页面主体
  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return ListView(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '加载订单失败',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                Text(_error!),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _loadOrders,
                  child: const Text('重试'),
                ),
              ],
            ),
          ),
        ],
      );
    }

    if (_orders.isEmpty) {
      return ListView(
        children: const [
          Padding(
            padding: EdgeInsets.all(16),
            child: Center(child: Text('暂无订单')),
          ),
        ],
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _orders.length,
      itemBuilder: (context, index) {
        final order = _orders[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 订单头部
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '订单 #${order.id.substring(0, 8)}',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '客户：${order.customerName}',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: _getStatusColor(order.status).withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        order.statusText,
                        style: TextStyle(
                          color: _getStatusColor(order.status),
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
                const Divider(height: 24),
                // 订单明细
                if (order.items.isNotEmpty) ...[
                  Text(
                    '订单明细',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  const SizedBox(height: 8),
                  ...order.items.map((item) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                item.dish?.name ?? '菜品ID: ${item.dishId}',
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                            ),
                            Text(
                              '${item.quantity}份 × ¥${item.unitPrice.toStringAsFixed(2)}',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                                  ),
                            ),
                          ],
                        ),
                      )),
                  const SizedBox(height: 16),
                ],
                // 操作按钮
                if (order.status == 'pending') ...[
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _rejectOrder(order),
                          icon: const Icon(Icons.close),
                          label: const Text('拒绝'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.red,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 2,
                        child: FilledButton.icon(
                          onPressed: () => _acceptOrder(order),
                          icon: const Icon(Icons.check_circle),
                          label: const Text('接单'),
                        ),
                      ),
                    ],
                  ),
                ] else if (order.status == 'accepted') ...[
                  Row(
                    children: [
                      Expanded(
                        child: order.isIngredientsPurchased
                            ? OutlinedButton.icon(
                                onPressed: null,
                                icon: const Icon(Icons.check_circle),
                                label: const Text('已买'),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: Colors.green,
                                ),
                              )
                            : OutlinedButton.icon(
                                onPressed: () {
                                  // 显示原料清单
                                  if (order.ingredientsList != null && order.ingredientsList!.isNotEmpty) {
                                    _showIngredients(context, order.ingredientsList!, order);
                                  } else {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('原料清单未计算，请先接单'),
                                        backgroundColor: Colors.orange,
                                      ),
                                    );
                                  }
                                },
                                icon: const Icon(Icons.shopping_basket_outlined),
                                label: const Text('查看原料'),
                              ),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 8),
                // 订单信息
                Text(
                  '总价：¥${order.totalPrice.toStringAsFixed(2)} | 创建时间：${_formatDateTime(order.createdAt)}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// 显示原料清单
  void _showIngredients(BuildContext context, Map<String, dynamic> ingredientsData, Order order) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Theme.of(context).dividerColor,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                '所需原料清单',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 16),
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: ingredientsData.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final entry = ingredientsData.entries.elementAt(index);
                    final ingredientName = entry.key;
                    final ingredientData = entry.value;

                    String unit = '';
                    double quantity = 0;

                    if (ingredientData is Map) {
                      unit = ingredientData['unit']?.toString() ?? '';
                      quantity = (ingredientData['quantity'] as num?)?.toDouble() ?? 0;
                    } else if (ingredientData is num) {
                      quantity = ingredientData.toDouble();
                    }

                    return ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 0, vertical: 8),
                      leading: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primaryContainer,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          Icons.shopping_basket,
                          color: Theme.of(context).colorScheme.onPrimaryContainer,
                          size: 20,
                        ),
                      ),
                      title: Text(
                        ingredientName,
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                      trailing: Text(
                        unit.isNotEmpty
                            ? '${quantity.toStringAsFixed(2)}$unit'
                            : quantity.toStringAsFixed(2),
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size.fromHeight(48),
                      ),
                      child: const Text('关闭'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: order.isIngredientsPurchased
                          ? null
                          : () => _markAsPurchased(context, order),
                      icon: const Icon(Icons.check_circle),
                      label: const Text('已买'),
                      style: FilledButton.styleFrom(
                        minimumSize: const Size.fromHeight(48),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 标记原料已购买
  Future<void> _markAsPurchased(BuildContext context, Order order) async {
    Navigator.of(context).pop(); // 关闭原料清单对话框

    try {
      await _service.markIngredientsPurchased(order.id);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('已标记为已买'),
            backgroundColor: Colors.green,
          ),
        );
        _loadOrders(); // 刷新订单列表
        widget.onRequestGlobalRefresh?.call();
      }
    } catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('操作失败：${error.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _onGlobalRefreshTriggered() {
    _loadOrders();
  }

  /// 获取订单状态对应的颜色
  Color _getStatusColor(String status) {
    switch (status) {
      case 'pending':
        return Colors.orange;
      case 'accepted':
        return Colors.blue;
      case 'rejected':
        return Colors.red;
      case 'completed':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  /// 格式化日期时间
  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.year}-${dateTime.month.toString().padLeft(2, '0')}-${dateTime.day.toString().padLeft(2, '0')} '
        '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }
}

