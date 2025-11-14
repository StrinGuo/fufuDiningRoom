/// 菜品原料编辑器
/// 
/// 用于编辑菜品所需的原料列表
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/ingredient.dart';
import '../services/admin_service.dart';

/// 菜品原料编辑器对话框
class DishIngredientsEditor extends StatefulWidget {
  const DishIngredientsEditor({
    super.key,
    required this.service,
    required this.ingredients,
  });

  final AdminService service;
  final List<({String ingredientId, String name, String unit, double quantity})> ingredients;

  @override
  State<DishIngredientsEditor> createState() => _DishIngredientsEditorState();
}

class _DishIngredientsEditorState extends State<DishIngredientsEditor> {
  List<({String ingredientId, String name, String unit, double quantity})> _ingredients = [];
  List<Ingredient> _allIngredients = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _ingredients = List.from(widget.ingredients);
    _loadIngredients();
  }

  Future<void> _loadIngredients() async {
    try {
      final ingredients = await widget.service.fetchAllIngredients();
      setState(() {
        _allIngredients = ingredients;
        _isLoading = false;
      });
    } catch (error) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('加载原料失败：${error.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _addIngredient() {
    if (_allIngredients.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('请先添加原料'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) => _AddIngredientDialog(
        allIngredients: _allIngredients,
        existingIngredientIds: _ingredients.map((i) => i.ingredientId).toList(),
        onAdd: (ingredientId, name, unit, quantity) {
          setState(() {
            _ingredients.add((
              ingredientId: ingredientId,
              name: name,
              unit: unit,
              quantity: quantity,
            ));
          });
        },
      ),
    );
  }

  void _removeIngredient(int index) {
    setState(() {
      _ingredients.removeAt(index);
    });
  }

  void _editIngredient(int index) {
    final ingredient = _ingredients[index];
    showDialog(
      context: context,
      builder: (context) => _EditIngredientQuantityDialog(
        ingredient: ingredient,
        onSave: (quantity) {
          setState(() {
            _ingredients[index] = (
              ingredientId: ingredient.ingredientId,
              name: ingredient.name,
              unit: ingredient.unit,
              quantity: quantity,
            );
          });
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        width: 500,
        constraints: const BoxConstraints(maxHeight: 600),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 标题栏
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.shopping_basket,
                        color: Theme.of(context).colorScheme.onPrimaryContainer,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        '编辑原料',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).colorScheme.onPrimaryContainer,
                            ),
                      ),
                    ],
                  ),
                  FilledButton.icon(
                    onPressed: _addIngredient,
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('添加'),
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    ),
                  ),
                ],
              ),
            ),
            // 原料列表
            Flexible(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _ingredients.isEmpty
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.all(32),
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
                                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                                      ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  '点击"添加"按钮添加原料',
                                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                                      ),
                                ),
                              ],
                            ),
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _ingredients.length,
                          itemBuilder: (context, index) {
                            final ing = _ingredients[index];
                            return Card(
                              margin: const EdgeInsets.only(bottom: 8),
                              child: ListTile(
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
                                title: Text(ing.name),
                                subtitle: Text('单位：${ing.unit}'),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      '${ing.quantity}${ing.unit}',
                                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                            fontWeight: FontWeight.w600,
                                            color: Theme.of(context).colorScheme.primary,
                                          ),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.edit, size: 20),
                                      onPressed: () => _editIngredient(index),
                                      tooltip: '编辑数量',
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.delete, size: 20, color: Colors.red),
                                      onPressed: () => _removeIngredient(index),
                                      tooltip: '删除',
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
            ),
            // 操作按钮
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(color: Theme.of(context).dividerColor),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('取消'),
                  ),
                  const SizedBox(width: 12),
                  FilledButton(
                    onPressed: () => Navigator.of(context).pop(_ingredients),
                    child: const Text('确定'),
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

/// 添加原料对话框
class _AddIngredientDialog extends StatefulWidget {
  const _AddIngredientDialog({
    required this.allIngredients,
    required this.existingIngredientIds,
    required this.onAdd,
  });

  final List<Ingredient> allIngredients;
  final List<String> existingIngredientIds;
  final void Function(String ingredientId, String name, String unit, double quantity) onAdd;

  @override
  State<_AddIngredientDialog> createState() => _AddIngredientDialogState();
}

class _AddIngredientDialogState extends State<_AddIngredientDialog> {
  String? _selectedIngredientId;
  final _quantityController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _quantityController.dispose();
    super.dispose();
  }

  void _add() {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedIngredientId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('请选择原料'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final ingredient = widget.allIngredients.firstWhere(
      (ing) => ing.id == _selectedIngredientId,
    );
    final quantity = double.tryParse(_quantityController.text);
    if (quantity == null || quantity <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('请输入有效的数量'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    widget.onAdd(ingredient.id, ingredient.name, ingredient.unit, quantity);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final availableIngredients = widget.allIngredients
        .where((ing) => !widget.existingIngredientIds.contains(ing.id))
        .toList();

    return AlertDialog(
      title: const Text('添加原料'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButtonFormField<String>(
              value: _selectedIngredientId,
              decoration: const InputDecoration(
                labelText: '选择原料 *',
                border: OutlineInputBorder(),
              ),
              items: availableIngredients.map((ing) {
                return DropdownMenuItem(
                  value: ing.id,
                  child: Text('${ing.name} (${ing.unit})'),
                );
              }).toList(),
              onChanged: (value) => setState(() => _selectedIngredientId = value),
              validator: (value) {
                if (value == null) return '请选择原料';
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _quantityController,
              decoration: InputDecoration(
                labelText: '数量 *',
                border: const OutlineInputBorder(),
                suffixText: _selectedIngredientId != null
                    ? widget.allIngredients
                        .firstWhere((ing) => ing.id == _selectedIngredientId)
                        .unit
                    : null,
              ),
              keyboardType: TextInputType.numberWithOptions(decimal: true),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return '请输入数量';
                }
                final qty = double.tryParse(value);
                if (qty == null || qty <= 0) {
                  return '请输入有效的数量';
                }
                return null;
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('取消'),
        ),
        FilledButton(
          onPressed: _add,
          child: const Text('添加'),
        ),
      ],
    );
  }
}

/// 编辑原料数量对话框
class _EditIngredientQuantityDialog extends StatefulWidget {
  const _EditIngredientQuantityDialog({
    required this.ingredient,
    required this.onSave,
  });

  final ({String ingredientId, String name, String unit, double quantity}) ingredient;
  final void Function(double quantity) onSave;

  @override
  State<_EditIngredientQuantityDialog> createState() => _EditIngredientQuantityDialogState();
}

class _EditIngredientQuantityDialogState extends State<_EditIngredientQuantityDialog> {
  late final TextEditingController _quantityController;
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _quantityController = TextEditingController(
      text: widget.ingredient.quantity.toString(),
    );
  }

  @override
  void dispose() {
    _quantityController.dispose();
    super.dispose();
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    final quantity = double.tryParse(_quantityController.text);
    if (quantity == null || quantity <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('请输入有效的数量'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }
    widget.onSave(quantity);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('编辑 ${widget.ingredient.name}'),
      content: Form(
        key: _formKey,
        child: TextFormField(
          controller: _quantityController,
          decoration: InputDecoration(
            labelText: '数量 *',
            border: const OutlineInputBorder(),
            suffixText: widget.ingredient.unit,
          ),
          keyboardType: TextInputType.numberWithOptions(decimal: true),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return '请输入数量';
            }
            final qty = double.tryParse(value);
            if (qty == null || qty <= 0) {
              return '请输入有效的数量';
            }
            return null;
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('取消'),
        ),
        FilledButton(
          onPressed: _save,
          child: const Text('保存'),
        ),
      ],
    );
  }
}

