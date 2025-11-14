/// 管理服务类
/// 
/// 负责管理端的数据库操作，包括菜品和原料的增删改查
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../orders/models/dish.dart';
import '../../orders/models/order.dart';
import '../models/ingredient.dart';

/// 管理服务
/// 
/// 提供菜品和原料的完整管理功能
class AdminService {
  /// 构造函数
  /// 
  /// [client] Supabase 客户端实例
  AdminService(this._client);

  /// Supabase 客户端（私有）
  final SupabaseClient _client;

  // ==================== 菜品管理 ====================

  /// 获取所有菜品（包括不可用的）
  /// 
  /// 返回：所有菜品列表，包含原料信息
  Future<List<Dish>> fetchAllDishes() async {
    final List<dynamic> response = await _client
        .from('dishes')
        .select(
          '''
id,
name,
description,
price,
image_url,
is_available,
category,
dish_ingredients(
  quantity,
  ingredient:ingredients(
    id,
    name,
    unit
  )
)
          ''',
        )
        .order('created_at', ascending: false);

    return response
        .cast<Map<String, dynamic>>()
        .map(Dish.fromMap)
        .toList();
  }

  /// 创建新菜品
  /// 
  /// [name] 菜品名称
  /// [description] 菜品描述（可选）
  /// [price] 价格
  /// [imageUrl] 图片URL（可选）
  /// [category] 分类（可选，默认"荤菜"）
  /// [isAvailable] 是否可用（默认true）
  /// 
  /// 返回：创建的菜品ID
  Future<String> createDish({
    required String name,
    String? description,
    required double price,
    String? imageUrl,
    String category = '荤菜',
    bool isAvailable = true,
  }) async {
    final response = await _client
        .from('dishes')
        .insert({
          'name': name.trim(),
          'description': description?.trim(),
          'price': price,
          'image_url': imageUrl?.trim(),
          'category': category,
          'is_available': isAvailable,
        })
        .select()
        .single();

    return response['id'] as String;
  }

  /// 更新菜品信息
  /// 
  /// [dishId] 菜品ID
  /// [name] 菜品名称（可选）
  /// [description] 菜品描述（可选）
  /// [price] 价格（可选）
  /// [imageUrl] 图片URL（可选）
  /// [category] 分类（可选）
  /// [isAvailable] 是否可用（可选）
  Future<void> updateDish({
    required String dishId,
    String? name,
    String? description,
    double? price,
    String? imageUrl,
    String? category,
    bool? isAvailable,
  }) async {
    final updateData = <String, dynamic>{};
    if (name != null) updateData['name'] = name.trim();
    if (description != null) updateData['description'] = description.trim();
    if (price != null) updateData['price'] = price;
    if (imageUrl != null) updateData['image_url'] = imageUrl.trim();
    if (category != null) updateData['category'] = category;
    if (isAvailable != null) updateData['is_available'] = isAvailable;

    if (updateData.isEmpty) return;

    await _client
        .from('dishes')
        .update(updateData)
        .eq('id', dishId);
  }

  /// 删除菜品
  /// 
  /// [dishId] 菜品ID
  /// 
  /// 注意：删除菜品会级联删除关联的 dish_ingredients 记录
  /// 如果菜品被订单项引用，将抛出异常
  /// 
  /// 异常：如果菜品被订单项引用，会抛出异常提示无法删除
  Future<void> deleteDish(String dishId) async {
    // 先检查是否有订单项引用该菜品
    final orderItemsResponse = await _client
        .from('order_items')
        .select('id')
        .eq('dish_id', dishId)
        .limit(1);

    if (orderItemsResponse.isNotEmpty) {
      throw Exception('无法删除该菜品：该菜品已被订单使用，请先将其标记为"停售"');
    }

    // 如果没有订单项引用，可以安全删除
    await _client
        .from('dishes')
        .delete()
        .eq('id', dishId);
  }

  // ==================== 原料管理 ====================

  /// 获取所有原料
  /// 
  /// 返回：所有原料列表
  Future<List<Ingredient>> fetchAllIngredients() async {
    final List<dynamic> response = await _client
        .from('ingredients')
        .select()
        .order('name');

    return response
        .cast<Map<String, dynamic>>()
        .map(Ingredient.fromMap)
        .toList();
  }

  /// 创建新原料
  /// 
  /// [name] 原料名称
  /// [unit] 单位
  /// 
  /// 返回：创建的原料ID
  Future<String> createIngredient({
    required String name,
    required String unit,
  }) async {
    final response = await _client
        .from('ingredients')
        .insert({
          'name': name.trim(),
          'unit': unit.trim(),
        })
        .select()
        .single();

    return response['id'] as String;
  }

  /// 更新原料信息
  /// 
  /// [ingredientId] 原料ID
  /// [name] 原料名称（可选）
  /// [unit] 单位（可选）
  Future<void> updateIngredient({
    required String ingredientId,
    String? name,
    String? unit,
  }) async {
    final updateData = <String, dynamic>{};
    if (name != null) updateData['name'] = name.trim();
    if (unit != null) updateData['unit'] = unit.trim();

    if (updateData.isEmpty) return;

    await _client
        .from('ingredients')
        .update(updateData)
        .eq('id', ingredientId);
  }

  /// 删除原料
  /// 
  /// [ingredientId] 原料ID
  /// 
  /// 注意：删除原料会级联删除关联的 dish_ingredients 记录
  Future<void> deleteIngredient(String ingredientId) async {
    await _client
        .from('ingredients')
        .delete()
        .eq('id', ingredientId);
  }

  // ==================== 菜品-原料关联管理 ====================

  /// 获取菜品的所有原料关联
  /// 
  /// [dishId] 菜品ID
  /// 
  /// 返回：原料关联列表（包含原料信息和数量）
  Future<List<Map<String, dynamic>>> fetchDishIngredients(String dishId) async {
    final response = await _client
        .from('dish_ingredients')
        .select(
          '''
id,
quantity,
ingredient:ingredients(
  id,
  name,
  unit
)
          ''',
        )
        .eq('dish_id', dishId);

    return response.cast<Map<String, dynamic>>();
  }

  /// 添加菜品原料关联
  /// 
  /// [dishId] 菜品ID
  /// [ingredientId] 原料ID
  /// [quantity] 所需数量
  Future<void> addDishIngredient({
    required String dishId,
    required String ingredientId,
    required double quantity,
  }) async {
    await _client
        .from('dish_ingredients')
        .insert({
          'dish_id': dishId,
          'ingredient_id': ingredientId,
          'quantity': quantity,
        });
  }

  /// 更新菜品原料关联的数量
  /// 
  /// [dishIngredientId] 关联ID
  /// [quantity] 新数量
  Future<void> updateDishIngredientQuantity({
    required String dishIngredientId,
    required double quantity,
  }) async {
    await _client
        .from('dish_ingredients')
        .update({'quantity': quantity})
        .eq('id', dishIngredientId);
  }

  /// 删除菜品原料关联
  /// 
  /// [dishIngredientId] 关联ID
  Future<void> deleteDishIngredient(String dishIngredientId) async {
    await _client
        .from('dish_ingredients')
        .delete()
        .eq('id', dishIngredientId);
  }

  /// 批量更新菜品的原料关联
  /// 
  /// [dishId] 菜品ID
  /// [ingredients] 原料列表，每个包含 ingredientId 和 quantity
  /// 
  /// 注意：此方法会先删除所有现有关联，然后添加新关联
  Future<void> updateDishIngredients({
    required String dishId,
    required List<({String ingredientId, double quantity})> ingredients,
  }) async {
    // 1. 删除所有现有关联
    await _client
        .from('dish_ingredients')
        .delete()
        .eq('dish_id', dishId);

    // 2. 批量插入新关联
    if (ingredients.isEmpty) return;

    final insertData = ingredients.map((ing) => {
      'dish_id': dishId,
      'ingredient_id': ing.ingredientId,
      'quantity': ing.quantity,
    }).toList();

    await _client
        .from('dish_ingredients')
        .insert(insertData);
  }

  // ==================== 订单管理 ====================

  /// 获取所有订单
  /// 
  /// 返回：所有订单列表，包含订单项信息，按创建时间倒序排列
  Future<List<Order>> fetchAllOrders() async {
    final List<dynamic> response = await _client
        .from('orders')
        .select(
          '''
            id,
            customer_name,
            customer_contact,
            total_price,
            status,
            ingredients_list,
            is_ingredients_purchased,
            purchase_completed_at,
            rating,
            review_text,
            reviewed_at,
            created_at,
            updated_at,
            order_items(
              id,
              order_id,
              dish_id,
              quantity,
              unit_price,
              created_at,
              dish:dishes(
                id,
                name,
                description,
                price,
                image_url,
                is_available
              )
            )
          ''',
        )
        .order('created_at', ascending: false);

    return response
        .cast<Map<String, dynamic>>()
        .map(Order.fromMap)
        .toList();
  }

  /// 删除订单
  /// 
  /// [orderId] 订单ID
  /// 
  /// 注意：删除订单会级联删除关联的 order_items 记录
  Future<void> deleteOrder(String orderId) async {
    // 先删除订单项（级联删除）
    await _client
        .from('order_items')
        .delete()
        .eq('order_id', orderId);

    // 然后删除订单主记录
    await _client
        .from('orders')
        .delete()
        .eq('id', orderId);
  }
}

