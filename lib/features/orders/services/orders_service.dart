/// 订单服务类
/// 
/// 负责与 Supabase 数据库交互，处理菜单、订单相关的数据操作
/// 封装所有后端 API 调用，使业务逻辑层无需直接操作 Supabase 客户端
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/dish.dart';
import '../models/order.dart';

/// 订单服务
/// 
/// 提供菜单查询、订单提交、订单管理等业务功能
class OrdersService {
  /// 构造函数
  /// 
  /// [client] Supabase 客户端实例，用于执行数据库查询
  OrdersService(this._client);

  /// Supabase 客户端（私有，外部无法直接访问）
  final SupabaseClient _client;

  /// 获取菜单列表
  /// 
  /// 查询所有可用的菜品，并关联查询每个菜品所需的原料信息
  /// 
  /// 返回：菜品列表，每个菜品包含完整的原料信息
  /// 
  /// 异常：如果网络请求失败或数据解析错误，会抛出异常
  Future<List<Dish>> fetchMenuList() async {
    try {
      print('[DEBUG OrdersService] 开始查询菜单...');
      // 使用 Supabase 的 PostgREST 查询语法
      // 通过 select 指定需要查询的字段和关联表
      // 注意：PostgREST 的 select 字符串中不能包含注释
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
        .eq('is_available', true)
        .order('created_at');

      print('[DEBUG OrdersService] 查询完成，取得 ${response.length} 条记录');
      // 将查询结果转换为 Dish 对象列表
      return response
          .cast<Map<String, dynamic>>()
          .map(Dish.fromMap)
          .toList();
    } catch (e) {
      print('[ERROR OrdersService] 查询菜单失败: $e');
      rethrow;
    }
  }

  /// 创建订单
  /// 
  /// 将购物车中的菜品提交为订单，插入到数据库
  /// 
  /// [customerName] 客户名称
  /// [customerContact] 客户联系方式（可选）
  /// [cartItems] 购物车中的菜品列表（Dish 和数量）
  /// 
  /// 返回：创建的订单ID
  /// 
  /// 异常：如果网络请求失败或数据插入错误，会抛出异常
  Future<String> createOrder({
    required String customerName,
    String? customerContact,
    required Map<String, ({Dish dish, int quantity})> cartItems,
  }) async {
    // 验证输入
    if (customerName.trim().isEmpty) {
      throw Exception('客户名称不能为空');
    }
    if (cartItems.isEmpty) {
      throw Exception('购物车为空，无法创建订单');
    }

    // 计算订单总价
    final totalPrice = cartItems.values.fold<double>(
      0,
      (sum, item) => sum + item.dish.price * item.quantity,
    );

    print('开始创建订单：客户=$customerName, 总价=$totalPrice, 商品数量=${cartItems.length}');

    try {
      // 1. 创建订单主记录
      final orderResponse = await _client
          .from('orders')
          .insert({
            'customer_name': customerName.trim(),
            'customer_contact': customerContact?.trim(),
            'total_price': totalPrice,
            'status': 'pending', // 初始状态为待处理
          })
          .select()
          .single();

      final orderId = orderResponse['id'] as String;
      print('订单主记录创建成功，订单ID：$orderId');

      // 2. 批量插入订单项
      final orderItems = cartItems.entries.map((entry) {
        final dish = entry.value.dish;
        final quantity = entry.value.quantity;
        return {
          'order_id': orderId,
          'dish_id': dish.id,
          'quantity': quantity,
          'unit_price': dish.price,
        };
      }).toList();

      print('准备插入 ${orderItems.length} 个订单项');
      await _client.from('order_items').insert(orderItems);
      print('订单项插入成功');

      return orderId;
    } catch (e, stackTrace) {
      print('创建订单时发生错误：$e');
      print('堆栈跟踪：$stackTrace');
      rethrow; // 重新抛出异常，让调用者处理
    }
  }

  /// 获取订单列表
  /// 
  /// 查询所有订单，包含订单项信息
  /// 
  /// 返回：订单列表，按创建时间倒序排列
  /// 
  /// 异常：如果网络请求失败或数据解析错误，会抛出异常
  Future<List<Order>> fetchOrderList() async {
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
        .order('created_at', ascending: false); // 按创建时间倒序

    return response
        .cast<Map<String, dynamic>>()
        .map(Order.fromMap)
        .toList();
  }

  /// 更新订单状态为已接单
  /// 
  /// [orderId] 订单ID
  /// 
  /// 异常：如果网络请求失败或更新错误，会抛出异常
  Future<void> acceptOrder(String orderId) async {
    await _client
        .from('orders')
        .update({'status': 'accepted'})
        .eq('id', orderId);
  }

  /// 更新订单状态为已拒绝
  /// 
  /// [orderId] 订单ID
  /// 
  /// 异常：如果网络请求失败或更新错误，会抛出异常
  Future<void> rejectOrder(String orderId) async {
    await _client
        .from('orders')
        .update({'status': 'rejected'})
        .eq('id', orderId);
  }

  /// 获取订单详情（包含菜品的原料信息）
  /// 
  /// [orderId] 订单ID
  /// 
  /// 返回：订单对象，包含完整的菜品和原料信息
  Future<Order> fetchOrderDetail(String orderId) async {
    final response = await _client
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
    is_available,
    dish_ingredients(
      quantity,
      ingredient:ingredients(
        id,
        name,
        unit
      )
    )
  )
)
          ''',
        )
        .eq('id', orderId)
        .single();

    return Order.fromMap(response as Map<String, dynamic>);
  }

  /// 计算订单所需的所有原料并更新到数据库
  /// 
  /// [orderId] 订单ID
  /// 
  /// 返回：计算后的原料清单（Map<原料名称, 数量>）
  /// 
  /// 异常：如果网络请求失败或计算错误，会抛出异常
  Future<Map<String, double>> calculateAndUpdateIngredients(String orderId) async {
    // 1. 获取订单详情（包含菜品和原料信息）
    final order = await fetchOrderDetail(orderId);

    // 2. 计算所有原料的总数量
    final ingredientsMap = <String, ({String unit, double quantity})>{};

    for (final item in order.items) {
      if (item.dish == null) continue;
      final dish = item.dish!;
      final itemQuantity = item.quantity;

      // 遍历该菜品的所有原料
      for (final dishIngredient in dish.ingredients) {
        final ingredientName = dishIngredient.name;
        final ingredientUnit = dishIngredient.unit;
        final ingredientQuantity = dishIngredient.quantity;

        // 计算该原料的总数量（原料数量 × 菜品数量）
        final totalQuantity = ingredientQuantity * itemQuantity;

        if (ingredientsMap.containsKey(ingredientName)) {
          // 如果原料已存在，累加数量
          final existing = ingredientsMap[ingredientName]!;
          // 检查单位是否一致
          if (existing.unit != ingredientUnit) {
            print('警告：原料 $ingredientName 的单位不一致（${existing.unit} vs $ingredientUnit）');
          }
          ingredientsMap[ingredientName] = (
            unit: existing.unit,
            quantity: existing.quantity + totalQuantity,
          );
        } else {
          // 新原料，直接添加
          ingredientsMap[ingredientName] = (
            unit: ingredientUnit,
            quantity: totalQuantity,
          );
        }
      }
    }

    // 3. 转换为 JSON 格式（包含单位信息）
    final ingredientsJson = <String, dynamic>{};
    for (final entry in ingredientsMap.entries) {
      ingredientsJson[entry.key] = {
        'quantity': entry.value.quantity,
        'unit': entry.value.unit,
      };
    }

    // 4. 更新订单的原料清单
    await _client
        .from('orders')
        .update({'ingredients_list': ingredientsJson})
        .eq('id', orderId);

    // 5. 返回简化的原料清单（只包含数量，用于显示）
    final simplifiedMap = <String, double>{};
    for (final entry in ingredientsMap.entries) {
      simplifiedMap[entry.key] = entry.value.quantity;
    }

    return simplifiedMap;
  }

  /// 标记订单原料已购买
  /// 
  /// [orderId] 订单ID
  /// 
  /// 异常：如果网络请求失败或更新错误，会抛出异常
  Future<void> markIngredientsPurchased(String orderId) async {
    await _client
        .from('orders')
        .update({
          'is_ingredients_purchased': true,
          'purchase_completed_at': DateTime.now().toIso8601String(),
        })
        .eq('id', orderId);
  }

  /// 提交订单评价
  /// 
  /// [orderId] 订单ID
  /// [rating] 评分（1-5星）
  /// [reviewText] 评价内容（可选）
  /// 
  /// 异常：如果网络请求失败或更新错误，会抛出异常
  Future<void> submitReview({
    required String orderId,
    required int rating,
    String? reviewText,
  }) async {
    if (rating < 1 || rating > 5) {
      throw Exception('评分必须在1-5之间');
    }

    await _client
        .from('orders')
        .update({
          'rating': rating,
          'review_text': reviewText?.trim(),
          'reviewed_at': DateTime.now().toIso8601String(),
        })
        .eq('id', orderId);
  }

  /// 获取已买订单列表
  /// 
  /// 查询所有已购买原料的订单，包含订单项和原料清单信息
  /// 
  /// 返回：已买订单列表，按购买时间倒序排列
  /// 
  /// 异常：如果网络请求失败或数据解析错误，会抛出异常
  Future<List<Order>> fetchPurchasedOrders() async {
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
        .eq('is_ingredients_purchased', true)
        .order('purchase_completed_at', ascending: false);

    return response
        .cast<Map<String, dynamic>>()
        .map(Order.fromMap)
        .toList();
  }
}

