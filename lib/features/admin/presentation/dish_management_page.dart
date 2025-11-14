/// 菜品管理页面
/// 
/// 用于管理所有菜品：查看、新增、编辑、删除
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../orders/models/dish.dart';
import '../services/admin_service.dart';
import 'dish_edit_dialog.dart';

/// 菜品管理页面组件
class DishManagementPage extends StatefulWidget {
  const DishManagementPage({super.key});

  @override
  State<DishManagementPage> createState() => _DishManagementPageState();
}

class _DishManagementPageState extends State<DishManagementPage> {
  late final AdminService _service;
  bool _isLoading = true;
  String? _error;
  List<Dish> _dishes = const [];
  String _selectedCategory = '全部';

  final List<String> _categories = ['全部', '荤菜', '素菜', '饮料'];

  @override
  void initState() {
    super.initState();
    _service = AdminService(Supabase.instance.client);
    _loadDishes();
  }

  Future<void> _loadDishes() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final dishes = await _service.fetchAllDishes();
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

  Future<void> _deleteDish(Dish dish) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('确认删除'),
        content: Text('确定要删除菜品"${dish.name}"吗？\n此操作不可恢复。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('删除'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await _service.deleteDish(dish.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('删除成功'),
            backgroundColor: Colors.green,
          ),
        );
        _loadDishes();
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('删除失败：${error.toString()}'),
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
        title: const Text('菜品管理'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadDishes,
            tooltip: '刷新',
          ),
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: FilledButton.icon(
              onPressed: () => _showAddDishDialog(),
              icon: const Icon(Icons.add),
              label: const Text('新增菜品'),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // 分类筛选
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
              border: Border(
                bottom: BorderSide(
                  color: Theme.of(context).dividerColor,
                  width: 1,
                ),
              ),
            ),
            child: Row(
              children: _categories.map((category) {
                final isSelected = _selectedCategory == category;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    selected: isSelected,
                    label: Text(category),
                    onSelected: (selected) {
                      if (selected) {
                        setState(() => _selectedCategory = category);
                      }
                    },
                  ),
                );
              }).toList(),
            ),
          ),
          // 菜品列表
          Expanded(
            child: RefreshIndicator(
              onRefresh: _loadDishes,
              child: _buildBody(),
            ),
          ),
        ],
      ),
    );
  }

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
              children: [
                Text('加载失败：$_error'),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _loadDishes,
                  child: const Text('重试'),
                ),
              ],
            ),
          ),
        ],
      );
    }

    final filteredDishes = _selectedCategory == '全部'
        ? _dishes
        : _dishes.where((d) => d.category == _selectedCategory).toList();

    if (filteredDishes.isEmpty) {
      return ListView(
        children: const [
          Padding(
            padding: EdgeInsets.all(16),
            child: Center(child: Text('暂无菜品')),
          ),
        ],
      );
    }

    // 根据屏幕宽度动态计算列数
    return LayoutBuilder(
      builder: (context, constraints) {
        // 计算每列的最小宽度（约280px），然后根据屏幕宽度计算列数
        final minItemWidth = 280.0;
        final crossAxisCount = (constraints.maxWidth / minItemWidth).floor().clamp(1, 6);
        final spacing = 12.0;
        final runSpacing = 12.0;

        return GridView.builder(
          padding: const EdgeInsets.all(16),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: spacing,
            mainAxisSpacing: runSpacing,
            childAspectRatio: 1.2,
          ),
          itemCount: filteredDishes.length,
          itemBuilder: (context, index) {
            final dish = filteredDishes[index];
            return Card(
              child: InkWell(
                onTap: () => _showEditDishDialog(dish),
                borderRadius: BorderRadius.circular(12),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 图片和状态
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // 图片
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: dish.imageUrl != null && dish.imageUrl!.isNotEmpty
                                ? Image.network(
                                    dish.imageUrl!,
                                    width: 60,
                                    height: 60,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) => Container(
                                      width: 60,
                                      height: 60,
                                      color: Theme.of(context).colorScheme.surfaceVariant,
                                      child: const Icon(Icons.restaurant, size: 30),
                                    ),
                                  )
                                : Container(
                                    width: 60,
                                    height: 60,
                                    decoration: BoxDecoration(
                                      color: Theme.of(context).colorScheme.surfaceVariant,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: const Icon(Icons.restaurant, size: 30),
                                  ),
                          ),
                          const SizedBox(width: 8),
                          // 名称和状态
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  dish.name,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 4),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: dish.isAvailable
                                        ? Colors.green.withOpacity(0.2)
                                        : Colors.grey.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    dish.isAvailable ? '在售' : '停售',
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: dish.isAvailable ? Colors.green : Colors.grey,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      // 价格
                      Text(
                        '¥${dish.price.toStringAsFixed(2)}',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.primary,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 4),
                      // 描述
                      if (dish.description != null && dish.description!.isNotEmpty)
                        Expanded(
                          child: Text(
                            dish.description!,
                            style: Theme.of(context).textTheme.bodySmall,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      const Spacer(),
                      // 底部信息
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              dish.category,
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    fontSize: 11,
                                  ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Text(
                            '${dish.ingredients.length}种',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  fontSize: 11,
                                ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      // 操作按钮
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit, size: 18),
                            onPressed: () => _showEditDishDialog(dish),
                            tooltip: '编辑',
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(
                              minWidth: 32,
                              minHeight: 32,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete, size: 18, color: Colors.red),
                            onPressed: () => _deleteDish(dish),
                            tooltip: '删除',
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(
                              minWidth: 32,
                              minHeight: 32,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _showAddDishDialog() async {
    final result = await showDialog<Dish?>(
      context: context,
      builder: (context) => DishEditDialog(service: _service),
    );

    if (result != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('菜品添加成功'),
          backgroundColor: Colors.green,
        ),
      );
      _loadDishes();
    }
  }

  Future<void> _showEditDishDialog(Dish dish) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => DishEditDialog(service: _service, dish: dish),
    );

    if (result == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('菜品更新成功'),
          backgroundColor: Colors.green,
        ),
      );
      _loadDishes();
    }
  }
}

