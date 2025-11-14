/// 报告页面
/// 
/// 显示每个月已买订单的食材总和统计
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/order.dart';
import '../services/orders_service.dart';

/// 报告页面组件
class ReportPage extends StatefulWidget {
  const ReportPage({super.key, this.globalRefreshTrigger});

  static const String routeName = '/report';
  final ValueNotifier<int>? globalRefreshTrigger;

  @override
  State<ReportPage> createState() => _ReportPageState();
}

class _ReportPageState extends State<ReportPage> {
  /// 订单服务实例
  late final OrdersService _service;

  /// 是否正在加载
  bool _isLoading = true;

  /// 错误信息
  String? _error;

  /// 已买订单列表
  List<Order> _purchasedOrders = const [];

  @override
  void initState() {
    super.initState();
    _service = OrdersService(Supabase.instance.client);
    _loadData();
    widget.globalRefreshTrigger?.addListener(_handleExternalRefresh);
  }

  @override
  void dispose() {
    widget.globalRefreshTrigger?.removeListener(_handleExternalRefresh);
    super.dispose();
  }

  /// 加载数据
  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final orders = await _service.fetchPurchasedOrders();
      setState(() {
        _purchasedOrders = orders;
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

  void _handleExternalRefresh() {
    _loadData();
  }

  /// 按月份统计食材总和
  Map<String, Map<String, ({double quantity, String unit})>> _calculateMonthlyIngredients() {
    final monthlyData = <String, Map<String, ({double quantity, String unit})>>{};

    for (final order in _purchasedOrders) {
      // 使用购买完成时间，如果没有则使用创建时间
      final date = order.purchaseCompletedAt ?? order.createdAt;
      final monthKey = '${date.year}-${date.month.toString().padLeft(2, '0')}';

      if (order.ingredientsList == null || order.ingredientsList!.isEmpty) {
        continue;
      }

      // 初始化该月份的数据
      monthlyData.putIfAbsent(monthKey, () => <String, ({double quantity, String unit})>{});

      // 累加该订单的食材
      for (final entry in order.ingredientsList!.entries) {
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

        final monthIngredients = monthlyData[monthKey]!;
        if (monthIngredients.containsKey(ingredientName)) {
          final existing = monthIngredients[ingredientName]!;
          monthIngredients[ingredientName] = (
            quantity: existing.quantity + quantity,
            unit: existing.unit.isNotEmpty ? existing.unit : unit,
          );
        } else {
          monthIngredients[ingredientName] = (
            quantity: quantity,
            unit: unit,
          );
        }
      }
    }

    return monthlyData;
  }

  /// 格式化月份显示
  String _formatMonth(String monthKey) {
    final parts = monthKey.split('-');
    if (parts.length != 2) return monthKey;
    final year = int.tryParse(parts[0]) ?? 0;
    final month = int.tryParse(parts[1]) ?? 0;
    return '$year年$month月';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('报告'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
            tooltip: '刷新',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadData,
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
                  '加载报告失败',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                Text(_error!),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _loadData,
                  child: const Text('重试'),
                ),
              ],
            ),
          ),
        ],
      );
    }

    final monthlyData = _calculateMonthlyIngredients();

    if (monthlyData.isEmpty) {
      return ListView(
        children: const [
          Padding(
            padding: EdgeInsets.all(16),
            child: Center(child: Text('暂无已买订单数据')),
          ),
        ],
      );
    }

    // 按月份倒序排列
    final sortedMonths = monthlyData.keys.toList()
      ..sort((a, b) => b.compareTo(a));

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: sortedMonths.length,
      itemBuilder: (context, index) {
        final monthKey = sortedMonths[index];
        final ingredients = monthlyData[monthKey]!;
        final sortedIngredients = ingredients.entries.toList()
          ..sort((a, b) => a.key.compareTo(b.key));

        return Card(
          margin: const EdgeInsets.only(bottom: 16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 月份标题
                Row(
                  children: [
                    Icon(
                      Icons.calendar_month,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _formatMonth(monthKey),
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primaryContainer,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${ingredients.length}种食材',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onPrimaryContainer,
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
                const Divider(height: 24),
                // 食材列表
                ...sortedIngredients.map((entry) {
                  final ingredientName = entry.key;
                  final data = entry.value;
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Row(
                      children: [
                        Container(
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
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                ingredientName,
                                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                      fontWeight: FontWeight.w600,
                                    ),
                              ),
                              if (data.unit.isNotEmpty)
                                Text(
                                  '单位：${data.unit}',
                                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                                      ),
                                ),
                            ],
                          ),
                        ),
                        Text(
                          data.unit.isNotEmpty
                              ? '${data.quantity.toStringAsFixed(2)}${data.unit}'
                              : data.quantity.toStringAsFixed(2),
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                        ),
                      ],
                    ),
                  );
                }),
              ],
            ),
          ),
        );
      },
    );
  }
}

