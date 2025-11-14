/// 菜品编辑对话框
/// 
/// 用于新增或编辑菜品信息
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';

import '../../orders/models/dish.dart';
import '../services/admin_service.dart';
import 'dish_ingredients_editor.dart';
import '../../../core/configs/supabase_config.dart';

/// 菜品编辑对话框组件
class DishEditDialog extends StatefulWidget {
  const DishEditDialog({
    super.key,
    required this.service,
    this.dish,
  });

  final AdminService service;
  final Dish? dish;

  @override
  State<DishEditDialog> createState() => _DishEditDialogState();
}

class _DishEditDialogState extends State<DishEditDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _priceController;
  late final TextEditingController _imageUrlController;
  late String _category;
  late bool _isAvailable;
  bool _isSaving = false;
  PlatformFile? _pickedFile;
  bool _isUploading = false;

  // 原料编辑相关
  List<({String ingredientId, String name, String unit, double quantity})> _ingredients = [];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.dish?.name ?? '');
    _descriptionController = TextEditingController(text: widget.dish?.description ?? '');
    _priceController = TextEditingController(text: widget.dish?.price.toString() ?? '');
    _imageUrlController = TextEditingController(text: widget.dish?.imageUrl ?? '');
    _category = widget.dish?.category ?? '荤菜';
    _isAvailable = widget.dish?.isAvailable ?? true;

    // 初始化原料列表
    if (widget.dish != null) {
      _ingredients = widget.dish!.ingredients.map((ing) => (
        ingredientId: ing.ingredientId,
        name: ing.name,
        unit: ing.unit,
        quantity: ing.quantity,
      )).toList();
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _imageUrlController.dispose();
    super.dispose();
  }

  /// 选择并上传图片到Supabase存储
  /// 支持 JPG、PNG、GIF 等常见图片格式
  Future<void> _pickAndUploadImage() async {
    try {
      // 选择文件
      final result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        withData: true,
      );

      if (result == null || result.files.isEmpty) return;

      setState(() {
        _pickedFile = result.files.first;
        _isUploading = true;
      });

      // 上传文件到Supabase存储
      // 生成安全的文件名：只使用数字和英文字符
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileExtension = _pickedFile!.name.contains('.')
          ? _pickedFile!.name.split('.').last
          : 'jpg';
      final fileName = 'dish_${timestamp}.$fileExtension';

      await Supabase.instance.client.storage
          .from('dish-images')
          .uploadBinary(fileName, _pickedFile!.bytes!);

      // 获取公共URL
      final imageUrl = Supabase.instance.client.storage
          .from('dish-images')
          .getPublicUrl(fileName);

      // 如果URL不含完整域名，补全为完整URL
      final fullImageUrl = imageUrl.startsWith('http')
          ? imageUrl
          : '${SupabaseConfig.url}/storage/v1/object/public/dish-images/$fileName';

      // 更新图片URL输入框
      setState(() {
        _imageUrlController.text = fullImageUrl;
        _isUploading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('图片上传成功'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (error) {
      print('图片上传失败详情: $error');
      setState(() {
        _isUploading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('图片上传失败：${error.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      final price = double.tryParse(_priceController.text);
      if (price == null || price < 0) {
        throw Exception('价格必须是有效的正数');
      }

      if (widget.dish == null) {
        // 新增菜品
        final dishId = await widget.service.createDish(
          name: _nameController.text.trim(),
          description: _descriptionController.text.trim().isEmpty
              ? null
              : _descriptionController.text.trim(),
          price: price,
          imageUrl: _imageUrlController.text.trim().isEmpty
              ? null
              : _imageUrlController.text.trim(),
          category: _category,
          isAvailable: _isAvailable,
        );

        // 添加原料关联
        if (_ingredients.isNotEmpty) {
          await widget.service.updateDishIngredients(
            dishId: dishId,
            ingredients: _ingredients.map((ing) => (
              ingredientId: ing.ingredientId,
              quantity: ing.quantity,
            )).toList(),
          );
        }

        if (mounted) {
          Navigator.of(context).pop(Dish(
            id: dishId,
            name: _nameController.text.trim(),
            description: _descriptionController.text.trim().isEmpty
                ? null
                : _descriptionController.text.trim(),
            price: price,
            imageUrl: _imageUrlController.text.trim().isEmpty
                ? null
                : _imageUrlController.text.trim(),
            category: _category,
            isAvailable: _isAvailable,
            ingredients: [],
          ));
        }
      } else {
        // 更新菜品
        await widget.service.updateDish(
          dishId: widget.dish!.id,
          name: _nameController.text.trim(),
          description: _descriptionController.text.trim().isEmpty
              ? null
              : _descriptionController.text.trim(),
          price: price,
          imageUrl: _imageUrlController.text.trim().isEmpty
              ? null
              : _imageUrlController.text.trim(),
          category: _category,
          isAvailable: _isAvailable,
        );

        // 更新原料关联
        await widget.service.updateDishIngredients(
          dishId: widget.dish!.id,
          ingredients: _ingredients.map((ing) => (
            ingredientId: ing.ingredientId,
            quantity: ing.quantity,
          )).toList(),
        );

        if (mounted) {
          Navigator.of(context).pop(true);
        }
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
    return Dialog(
      child: Container(
        width: 600,
        constraints: const BoxConstraints(maxHeight: 800),
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
                children: [
                  Icon(
                    widget.dish == null ? Icons.add_circle : Icons.edit,
                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    widget.dish == null ? '新增菜品' : '编辑菜品',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.onPrimaryContainer,
                        ),
                  ),
                ],
              ),
            ),
            // 表单内容
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 基本信息
                      Text(
                        '基本信息',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _nameController,
                        decoration: const InputDecoration(
                          labelText: '菜品名称 *',
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return '请输入菜品名称';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _descriptionController,
                        decoration: const InputDecoration(
                          labelText: '菜品描述',
                          border: OutlineInputBorder(),
                        ),
                        maxLines: 3,
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _priceController,
                              decoration: const InputDecoration(
                                labelText: '价格（元） *',
                                border: OutlineInputBorder(),
                              ),
                              keyboardType: TextInputType.numberWithOptions(decimal: true),
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return '请输入价格';
                                }
                                final price = double.tryParse(value);
                                if (price == null || price < 0) {
                                  return '请输入有效的价格';
                                }
                                return null;
                              },
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              value: _category,
                              decoration: const InputDecoration(
                                labelText: '分类 *',
                                border: OutlineInputBorder(),
                              ),
                              items: const [
                                DropdownMenuItem(value: '荤菜', child: Text('荤菜')),
                                DropdownMenuItem(value: '素菜', child: Text('素菜')),
                                DropdownMenuItem(value: '饮料', child: Text('饮料')),
                              ],
                              onChanged: (value) {
                                if (value != null) {
                                  setState(() => _category = value);
                                }
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      // 图片上传区域
                      Text(
                        '菜品图片',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: Theme.of(context).colorScheme.outline,
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          children: [
                            // 图片预览
                            if (_imageUrlController.text.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Image.network(
                                    _imageUrlController.text,
                                    height: 150,
                                    width: double.infinity,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) {
                                      return Container(
                                        height: 150,
                                        color: Theme.of(context).colorScheme.surfaceVariant,
                                        child: const Center(
                                          child: Icon(Icons.broken_image),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              ),
                            // 上传按钮
                            Padding(
                              padding: const EdgeInsets.all(12.0),
                              child: _isUploading
                                  ? const SizedBox(
                                      height: 40,
                                      child: Center(
                                        child: CircularProgressIndicator(strokeWidth: 2),
                                      ),
                                    )
                                  : FilledButton.icon(
                                      onPressed: _pickAndUploadImage,
                                      icon: const Icon(Icons.upload_file),
                                      label: const Text('选择并上传图片'),
                                    ),
                            ),
                            // 或者输入URL
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
                              child: TextFormField(
                                controller: _imageUrlController,
                                decoration: const InputDecoration(
                                  labelText: '或直接输入图片URL',
                                  border: OutlineInputBorder(),
                                  hintText: 'https://example.com/image.jpg',
                                  isDense: true,
                                ),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.only(bottom: 8.0),
                              child: Text(
                                '支持 JPG、PNG、GIF 等格式',
                                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                                    ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      SwitchListTile(
                        title: const Text('是否在售'),
                        value: _isAvailable,
                        onChanged: (value) => setState(() => _isAvailable = value),
                      ),
                      const Divider(height: 32),
                      // 原料管理
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '所需原料',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                          TextButton.icon(
                            onPressed: () async {
                              final result = await showDialog<
                                  List<({String ingredientId, String name, String unit, double quantity})>>(
                                context: context,
                                builder: (context) => DishIngredientsEditor(
                                  service: widget.service,
                                  ingredients: _ingredients,
                                ),
                              );
                              if (result != null) {
                                setState(() => _ingredients = result);
                              }
                            },
                            icon: const Icon(Icons.edit),
                            label: const Text('编辑原料'),
                          ),
                        ],
                      ),
                      if (_ingredients.isEmpty)
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: Center(
                            child: Text(
                              '暂无原料，点击"编辑原料"添加',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                                  ),
                            ),
                          ),
                        )
                      else
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Column(
                            children: _ingredients.map((ing) => Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 4),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(ing.name),
                                      Text('${ing.quantity}${ing.unit}'),
                                    ],
                                  ),
                                )).toList(),
                          ),
                        ),
                    ],
                  ),
                ),
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
                    onPressed: _isSaving ? null : () => Navigator.of(context).pop(),
                    child: const Text('取消'),
                  ),
                  const SizedBox(width: 12),
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
              ),
            ),
          ],
        ),
      ),
    );
  }
}

