/// 订单数据模型
/// 
/// 表示一个订单，包含订单基本信息和订单项列表
import 'dish.dart';

class Order {
  const Order({
    required this.id,
    required this.customerName,
    this.customerContact,
    required this.totalPrice,
    required this.status,
    this.ingredientsList,
    this.isIngredientsPurchased = false,
    this.purchaseCompletedAt,
    this.rating,
    this.reviewText,
    this.reviewedAt,
    required this.createdAt,
    required this.updatedAt,
    this.items = const [],
  });

  /// 订单唯一标识符（UUID）
  final String id;
  
  /// 客户名称
  final String customerName;
  
  /// 客户联系方式（可选）
  final String? customerContact;
  
  /// 订单总价（单位：元）
  final double totalPrice;
  
  /// 订单状态：pending/accepted/rejected/completed
  final String status;
  
  /// 总原料清单（JSON格式）
  final Map<String, dynamic>? ingredientsList;
  
  /// 是否已买完菜
  final bool isIngredientsPurchased;
  
  /// 买完菜时间
  final DateTime? purchaseCompletedAt;
  
  /// 评分（1-5星）
  final int? rating;
  
  /// 评价内容
  final String? reviewText;
  
  /// 评价时间
  final DateTime? reviewedAt;
  
  /// 订单创建时间
  final DateTime createdAt;
  
  /// 订单更新时间
  final DateTime updatedAt;
  
  /// 订单项列表
  final List<OrderItem> items;

  /// 从 Supabase 返回的 JSON 数据创建 Order 对象
  factory Order.fromMap(Map<String, dynamic> map) {
    // 解析订单项（如果有关联查询）
    final itemsData = (map['order_items'] as List<dynamic>? ?? [])
        .cast<Map<String, dynamic>>();
    
    return Order(
      id: map['id'] as String,
      customerName: map['customer_name'] as String,
      customerContact: map['customer_contact'] as String?,
      totalPrice: (map['total_price'] as num).toDouble(),
      status: map['status'] as String? ?? 'pending',
      ingredientsList: map['ingredients_list'] as Map<String, dynamic>?,
      isIngredientsPurchased: map['is_ingredients_purchased'] as bool? ?? false,
      purchaseCompletedAt: map['purchase_completed_at'] != null
          ? DateTime.parse(map['purchase_completed_at'] as String)
          : null,
      rating: map['rating'] as int?,
      reviewText: map['review_text'] as String?,
      reviewedAt: map['reviewed_at'] != null
          ? DateTime.parse(map['reviewed_at'] as String)
          : null,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
      items: itemsData.map((item) => OrderItem.fromMap(item)).toList(),
    );
  }

  /// 获取订单状态的中文显示
  String get statusText {
    switch (status) {
      case 'pending':
        return '待处理';
      case 'accepted':
        return '已接单';
      case 'rejected':
        return '已拒绝';
      case 'completed':
        return '已完成';
      default:
        return status;
    }
  }
}

/// 订单项数据模型
/// 
/// 表示订单中的一个菜品项
class OrderItem {
  const OrderItem({
    required this.id,
    required this.orderId,
    required this.dishId,
    required this.quantity,
    required this.unitPrice,
    this.dish,
    this.createdAt,
  });

  /// 订单项唯一标识符（UUID）
  final String id;
  
  /// 所属订单ID
  final String orderId;
  
  /// 菜品ID
  final String dishId;
  
  /// 菜品数量
  final int quantity;
  
  /// 下单时的单价（单位：元）
  final double unitPrice;
  
  /// 菜品信息（如果有关联查询）
  final Dish? dish;
  
  /// 创建时间
  final DateTime? createdAt;

  /// 从 Supabase 返回的 JSON 数据创建 OrderItem 对象
  factory OrderItem.fromMap(Map<String, dynamic> map) {
    return OrderItem(
      id: map['id'] as String,
      orderId: map['order_id'] as String,
      dishId: map['dish_id'] as String,
      quantity: map['quantity'] as int,
      unitPrice: (map['unit_price'] as num).toDouble(),
      dish: map['dish'] != null ? Dish.fromMap(map['dish'] as Map<String, dynamic>) : null,
      createdAt: map['created_at'] != null
          ? DateTime.parse(map['created_at'] as String)
          : null,
    );
  }
  
  /// 计算该项小计金额
  double get subtotal => quantity * unitPrice;
}

