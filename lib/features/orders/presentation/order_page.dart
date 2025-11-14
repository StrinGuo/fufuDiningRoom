/// 订单列表页面
/// 
/// 显示所有订单，包括订单状态、总价、创建时间等信息
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/order.dart';
import '../services/orders_service.dart';

/// 订单列表页面组件
class OrderPage extends StatefulWidget {
  const OrderPage({super.key, this.refreshTrigger});

  static const String routeName = '/orders';

  /// 刷新触发器，当值改变时会触发刷新
  final ValueNotifier<int>? refreshTrigger;

  @override
  State<OrderPage> createState() => _OrderPageState();
}

class _OrderPageState extends State<OrderPage> {
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
    
    // 监听刷新触发器
    widget.refreshTrigger?.addListener(_onRefreshTriggered);
  }

  @override
  void dispose() {
    widget.refreshTrigger?.removeListener(_onRefreshTriggered);
    super.dispose();
  }

  /// 当刷新触发器改变时调用
  void _onRefreshTriggered() {
    _loadOrders();
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('订单'),
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
                // 订单头部：订单号、状态、总价
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
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        // 状态标签
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
                        const SizedBox(height: 8),
                        Text(
                          '¥${order.totalPrice.toStringAsFixed(2)}',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                color: Theme.of(context).colorScheme.primary,
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                      ],
                    ),
                  ],
                ),
                const Divider(height: 24),
                // 订单项列表
                if (order.items.isNotEmpty) ...[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '订单明细',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                      if (order.status == 'accepted')
                        TextButton.icon(
                          onPressed: () => _showIngredients(context, order),
                          icon: const Icon(Icons.shopping_basket_outlined, size: 18),
                          label: const Text('查看原料'),
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Container(
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      children: order.items.map((item) => Padding(
                            padding: const EdgeInsets.symmetric(vertical: 6),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 4,
                                        height: 4,
                                        decoration: BoxDecoration(
                                          color: Theme.of(context).colorScheme.primary,
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Text(
                                          item.dish?.name ?? '菜品ID: ${item.dishId}',
                                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                                fontWeight: FontWeight.w500,
                                              ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Text(
                                  '${item.quantity}份',
                                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                                      ),
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  '¥${item.subtotal.toStringAsFixed(2)}',
                                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                        fontWeight: FontWeight.w600,
                                        color: Theme.of(context).colorScheme.primary,
                                      ),
                                ),
                              ],
                            ),
                          )).toList(),
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
                // 订单时间和联系方式
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (order.customerContact != null && order.customerContact!.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Row(
                          children: [
                            Icon(
                              Icons.phone_outlined,
                              size: 14,
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              order.customerContact!,
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                                  ),
                            ),
                          ],
                        ),
                      ),
                    Row(
                      children: [
                        Icon(
                          Icons.access_time_outlined,
                          size: 14,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '创建时间：${_formatDateTime(order.createdAt)}',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Theme.of(context).colorScheme.onSurfaceVariant,
                              ),
                        ),
                      ],
                    ),
                  ],
                ),
                // 评价区域
                if (order.isIngredientsPurchased) ...[
                  const Divider(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '评价',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                      if (order.reviewedAt != null)
                        TextButton.icon(
                          onPressed: () => _showReview(context, order),
                          icon: const Icon(Icons.rate_review_outlined, size: 18),
                          label: const Text('查看评价'),
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          ),
                        )
                      else
                        FilledButton.icon(
                          onPressed: () => _showReviewDialog(context, order),
                          icon: const Icon(Icons.star_outline, size: 18),
                          label: const Text('评价'),
                          style: FilledButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          ),
                        ),
                    ],
                  ),
                  if (order.reviewedAt != null) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          ...List.generate(5, (index) {
                            return Icon(
                              index < (order.rating ?? 0)
                                  ? Icons.star
                                  : Icons.star_border,
                              color: Colors.amber,
                              size: 20,
                            );
                          }),
                          if (order.reviewText != null && order.reviewText!.isNotEmpty) ...[
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                order.reviewText!,
                                style: Theme.of(context).textTheme.bodyMedium,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ],
              ],
            ),
          ),
        );
      },
    );
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

  /// 显示原料清单
  Future<void> _showIngredients(BuildContext context, Order order) async {
    // 如果已有原料清单，直接显示
    if (order.ingredientsList != null && order.ingredientsList!.isNotEmpty) {
      _displayIngredients(context, order.ingredientsList!);
      return;
    }

    // 如果没有原料清单，需要计算
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
                Text('正在计算原料...'),
              ],
            ),
          ),
        ),
      ),
    );

    try {
      final ingredients = await _service.calculateAndUpdateIngredients(order.id);
      if (context.mounted) {
        Navigator.of(context).pop(); // 关闭加载对话框
        _displayIngredients(context, ingredients);
        // 刷新订单列表
        _loadOrders();
      }
    } catch (error) {
      if (context.mounted) {
        Navigator.of(context).pop(); // 关闭加载对话框
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('计算原料失败：${error.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// 显示原料清单对话框
  void _displayIngredients(BuildContext context, Map<String, dynamic> ingredientsData) {
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

                    // 处理不同的数据格式
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
              FilledButton(
                onPressed: () => Navigator.of(context).pop(),
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(48),
                ),
                child: const Text('关闭'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 显示评价对话框
  Future<void> _showReviewDialog(BuildContext context, Order order) async {
    final result = await showDialog<({int rating, String? reviewText})>(
      context: context,
      builder: (context) => _ReviewDialog(),
    );

    if (result == null) return;

    try {
      await _service.submitReview(
        orderId: order.id,
        rating: result.rating,
        reviewText: result.reviewText,
      );

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('评价提交成功！'),
            backgroundColor: Colors.green,
          ),
        );
        _loadOrders(); // 刷新订单列表
      }
    } catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('提交失败：${error.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// 显示评价详情
  void _showReview(BuildContext context, Order order) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('订单评价'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text('评分：'),
                const SizedBox(width: 8),
                ...List.generate(5, (index) {
                  return Icon(
                    index < (order.rating ?? 0)
                        ? Icons.star
                        : Icons.star_border,
                    color: Colors.amber,
                    size: 24,
                  );
                }),
                const SizedBox(width: 8),
                Text('${order.rating ?? 0}星'),
              ],
            ),
            if (order.reviewText != null && order.reviewText!.isNotEmpty) ...[
              const SizedBox(height: 16),
              const Text('评价内容：'),
              const SizedBox(height: 8),
              Text(
                order.reviewText!,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
            if (order.reviewedAt != null) ...[
              const SizedBox(height: 16),
              Text(
                '评价时间：${_formatDateTime(order.reviewedAt!)}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('关闭'),
          ),
        ],
      ),
    );
  }
}

/// 评价对话框
class _ReviewDialog extends StatefulWidget {
  @override
  State<_ReviewDialog> createState() => _ReviewDialogState();
}

class _ReviewDialogState extends State<_ReviewDialog> {
  int _rating = 0;
  final _reviewController = TextEditingController();

  @override
  void dispose() {
    _reviewController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('订单评价'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('请选择评分：'),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(5, (index) {
              return IconButton(
                onPressed: () {
                  setState(() {
                    _rating = index + 1;
                  });
                },
                icon: Icon(
                  index < _rating ? Icons.star : Icons.star_border,
                  color: Colors.amber,
                  size: 40,
                ),
              );
            }),
          ),
          const SizedBox(height: 24),
          TextField(
            controller: _reviewController,
            decoration: const InputDecoration(
              labelText: '评价内容（可选）',
              hintText: '请输入您的评价...',
              border: OutlineInputBorder(),
            ),
            maxLines: 4,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('取消'),
        ),
        FilledButton(
          onPressed: _rating > 0
              ? () {
                  Navigator.of(context).pop((
                    rating: _rating,
                    reviewText: _reviewController.text.trim().isEmpty
                        ? null
                        : _reviewController.text.trim(),
                  ));
                }
              : null,
          child: const Text('提交'),
        ),
      ],
    );
  }
}

