/// 原料数据模型
/// 
/// 用于管理端的原料管理
class Ingredient {
  const Ingredient({
    required this.id,
    required this.name,
    required this.unit,
    this.createdAt,
  });

  /// 原料唯一标识符（UUID）
  final String id;
  
  /// 原料名称
  final String name;
  
  /// 原料单位（如：克、个、勺）
  final String unit;
  
  /// 创建时间
  final DateTime? createdAt;

  /// 从 Supabase 返回的 JSON 数据创建 Ingredient 对象
  factory Ingredient.fromMap(Map<String, dynamic> map) {
    return Ingredient(
      id: map['id'] as String,
      name: map['name'] as String,
      unit: map['unit'] as String,
      createdAt: map['created_at'] != null
          ? DateTime.parse(map['created_at'] as String)
          : null,
    );
  }

  /// 转换为 JSON 格式（用于插入/更新）
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'unit': unit,
    };
  }
}

