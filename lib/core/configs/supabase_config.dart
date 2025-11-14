/// Supabase 配置类
/// 
/// 集中管理 Supabase 数据库的连接配置
/// 使用静态常量存储配置信息，避免硬编码分散在各处
/// 
/// 注意：anonKey 是公开的匿名密钥，仅用于客户端访问
/// 敏感操作应通过 Supabase 的 Row Level Security (RLS) 策略保护
class SupabaseConfig {
  // 私有构造函数，防止实例化（这是一个工具类）
  const SupabaseConfig._();

  /// Supabase 项目 URL
  /// 
  /// 格式：https://[项目ID].supabase.co
  static const String url = 'https://mnzjejtrgcnoulwxpets.supabase.co';
  
  /// Supabase 匿名访问密钥
  /// 
  /// 用于客户端直接访问数据库（受 RLS 策略限制）
  /// 生产环境建议通过环境变量或配置文件管理，避免提交到版本控制
  static const String anonKey =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im1uemplanRyZ2Nub3Vsd3hwZXRzIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjI5MjU5NDUsImV4cCI6MjA3ODUwMTk0NX0.mTUH_WoeFKd_CbZotwKn1byj0yktrI1-w_jfB4iH3mw';
}

