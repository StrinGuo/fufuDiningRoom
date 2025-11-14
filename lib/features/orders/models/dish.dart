/// 菜品数据模型
/// 
/// 表示菜单中的一个菜品，包含菜品的基本信息和原料列表
/// 用于在客户端展示和处理菜品数据
class Dish {
  const Dish({
    required this.id,
    required this.name,
    this.description,
    required this.price,
    this.imageUrl,
    required this.isAvailable,
    required this.ingredients,
    this.category = '荤菜',
  });

  /// 菜品唯一标识符（UUID）
  final String id;
  
  /// 菜品名称
  final String name;
  
  /// 菜品描述（可选）
  final String? description;
  
  /// 菜品价格（单位：元）
  final double price;
  
  /// 菜品图片 URL（可选）
  final String? imageUrl;
  
  /// 是否可用（是否在售）
  final bool isAvailable;
  
  /// 菜品所需原料列表
  final List<DishIngredient> ingredients;
  
  /// 菜品分类：荤菜/素菜/饮料 等
  /// 默认值为"荤菜"，后续数据库返回分类字段后可自动使用
  final String category;

  /// 从 Supabase 返回的 JSON 数据创建 Dish 对象
  /// 
  /// [map] Supabase 查询返回的 JSON 数据
  /// 包含菜品信息和关联的原料数据（通过 dish_ingredients 表关联）
  factory Dish.fromMap(Map<String, dynamic> map) {
    // 解析关联的原料数据（dish_ingredients 是关联表查询结果）
    final ingredientsData = (map['dish_ingredients'] as List<dynamic>? ?? [])
        .cast<Map<String, dynamic>>();

    return Dish(
      id: map['id'] as String,
      name: map['name'] as String,
      description: map['description'] as String?,
      price: (map['price'] as num).toDouble(),
      imageUrl: map['image_url'] as String?,
      isAvailable: map['is_available'] as bool? ?? true,
      // 将原料数据转换为 DishIngredient 对象列表
      ingredients: ingredientsData
          .map((item) => DishIngredient.fromMap(item))
          .toList(),
      // 处理分类字段：如果数据库中有分类则使用，否则默认为"荤菜"
      // 确保分类值标准化（去除空格，统一大小写）
      category: (map['category'] as String?)?.trim().isNotEmpty == true
          ? (map['category'] as String).trim()
          : '荤菜',
    );
  }
}

/// 菜品原料数据模型
/// 
/// 表示制作某个菜品所需的原料及其数量
/// 通过 dish_ingredients 关联表与 Dish 关联
class DishIngredient {
  const DishIngredient({
    required this.ingredientId,
    required this.name,
    required this.unit,
    required this.quantity,
  });

  /// 原料唯一标识符（UUID）
  final String ingredientId;
  
  /// 原料名称（如：鸡蛋、面粉、盐）
  final String name;
  
  /// 原料单位（如：克、个、勺）
  final String unit;
  
  /// 所需数量
  final double quantity;

  /// 从 Supabase 返回的 JSON 数据创建 DishIngredient 对象
  /// 
  /// [map] 包含原料关联信息，结构为：
  /// {
  ///   "quantity": 100,
  ///   "ingredient": {
  ///     "id": "...",
  ///     "name": "鸡蛋",
  ///     "unit": "个"
  ///   }
  /// }
  factory DishIngredient.fromMap(Map<String, dynamic> map) {
    // 从嵌套的 ingredient 对象中提取原料信息
    final ingredient = map['ingredient'] as Map<String, dynamic>? ?? {};
    return DishIngredient(
      ingredientId: ingredient['id'] as String? ?? '',
      name: ingredient['name'] as String? ?? '',
      unit: ingredient['unit'] as String? ?? '',
      quantity: (map['quantity'] as num).toDouble(), // 数量在关联表中
    );
  }
}

