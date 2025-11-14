/// 原料管理页面
/// 
/// 用于管理所有原料：查看、新增、编辑、删除
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/ingredient.dart';
import '../services/admin_service.dart';

/// 原料管理页面组件
class IngredientManagementPage extends StatefulWidget {
  const IngredientManagementPage({super.key});

  @override
  State<IngredientManagementPage> createState() => _IngredientManagementPageState();
}

class _IngredientManagementPageState extends State<IngredientManagementPage> {
  late final AdminService _service;
  bool _isLoading = true;
  String? _error;
  List<Ingredient> _ingredients = const [];

  @override
  void initState() {
    super.initState();
    _service = AdminService(Supabase.instance.client);
    _loadIngredients();
  }

  Future<void> _loadIngredients() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final ingredients = await _service.fetchAllIngredients();
      setState(() {
        _ingredients = ingredients;
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

  Future<void> _deleteIngredient(Ingredient ingredient) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('确认删除'),
        content: Text('确定要删除原料"${ingredient.name}"吗？\n此操作不可恢复，且会删除所有相关的菜品-原料关联。'),
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
      await _service.deleteIngredient(ingredient.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('删除成功'),
            backgroundColor: Colors.green,
          ),
        );
        _loadIngredients();
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
        title: const Text('原料管理'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadIngredients,
            tooltip: '刷新',
          ),
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: FilledButton.icon(
              onPressed: () => _showAddIngredientDialog(),
              icon: const Icon(Icons.add),
              label: const Text('新增原料'),
            ),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadIngredients,
        child: _buildBody(),
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
                  onPressed: _loadIngredients,
                  child: const Text('重试'),
                ),
              ],
            ),
          ),
        ],
      );
    }

    if (_ingredients.isEmpty) {
      return ListView(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.shopping_basket_outlined,
                    size: 64,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    '暂无原料',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '点击"新增原料"按钮添加',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                  ),
                ],
              ),
            ),
          ),
        ],
      );
    }

    // 根据屏幕宽度动态计算列数
    return LayoutBuilder(
      builder: (context, constraints) {
        // 计算每列的最小宽度（约200px），然后根据屏幕宽度计算列数
        final minItemWidth = 200.0;
        final crossAxisCount = (constraints.maxWidth / minItemWidth).floor().clamp(1, 8);
        final spacing = 12.0;
        final runSpacing = 12.0;

        return GridView.builder(
          padding: const EdgeInsets.all(16),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: spacing,
            mainAxisSpacing: runSpacing,
            childAspectRatio: 1.5,
          ),
          itemCount: _ingredients.length,
          itemBuilder: (context, index) {
            final ingredient = _ingredients[index];
            return Card(
              child: InkWell(
                onTap: () => _showEditIngredientDialog(ingredient),
                borderRadius: BorderRadius.circular(12),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 图标
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primaryContainer,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          Icons.shopping_basket,
                          color: Theme.of(context).colorScheme.onPrimaryContainer,
                          size: 22,
                        ),
                      ),
                      const SizedBox(height: 12),
                      // 名称
                      Text(
                        ingredient.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      // 单位
                      Text(
                        '单位：${ingredient.unit}',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      const Spacer(),
                      // 操作按钮
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit, size: 18),
                            onPressed: () => _showEditIngredientDialog(ingredient),
                            tooltip: '编辑',
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(
                              minWidth: 32,
                              minHeight: 32,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete, size: 18, color: Colors.red),
                            onPressed: () => _deleteIngredient(ingredient),
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

  Future<void> _showAddIngredientDialog() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => _IngredientEditDialog(service: _service),
    );

    if (result == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('原料添加成功'),
          backgroundColor: Colors.green,
        ),
      );
      _loadIngredients();
    }
  }

  Future<void> _showEditIngredientDialog(Ingredient ingredient) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => _IngredientEditDialog(
        service: _service,
        ingredient: ingredient,
      ),
    );

    if (result == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('原料更新成功'),
          backgroundColor: Colors.green,
        ),
      );
      _loadIngredients();
    }
  }
}

/// 原料编辑对话框
class _IngredientEditDialog extends StatefulWidget {
  const _IngredientEditDialog({
    required this.service,
    this.ingredient,
  });

  final AdminService service;
  final Ingredient? ingredient;

  @override
  State<_IngredientEditDialog> createState() => _IngredientEditDialogState();
}

class _IngredientEditDialogState extends State<_IngredientEditDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _unitController;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.ingredient?.name ?? '');
    _unitController = TextEditingController(text: widget.ingredient?.unit ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _unitController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      if (widget.ingredient == null) {
        // 新增
        await widget.service.createIngredient(
          name: _nameController.text.trim(),
          unit: _unitController.text.trim(),
        );
      } else {
        // 更新
        await widget.service.updateIngredient(
          ingredientId: widget.ingredient!.id,
          name: _nameController.text.trim(),
          unit: _unitController.text.trim(),
        );
      }

      if (mounted) {
        Navigator.of(context).pop(true);
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('保存失败：${error.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.ingredient == null ? '新增原料' : '编辑原料'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: '原料名称 *',
                border: OutlineInputBorder(),
                hintText: '例如：鸡蛋、面粉、盐',
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return '请输入原料名称';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _unitController,
              decoration: const InputDecoration(
                labelText: '单位 *',
                border: OutlineInputBorder(),
                hintText: '例如：克、个、勺、毫升',
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return '请输入单位';
                }
                return null;
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSaving ? null : () => Navigator.of(context).pop(),
          child: const Text('取消'),
        ),
        FilledButton(
          onPressed: _isSaving ? null : _save,
          child: _isSaving
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('保存'),
        ),
      ],
    );
  }
}

