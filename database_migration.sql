-- 数据库迁移脚本
-- 在 Supabase SQL Editor 中执行以下 SQL 来添加 category 字段

-- 为 dishes 表添加 category 字段
ALTER TABLE dishes 
ADD COLUMN IF NOT EXISTS category VARCHAR(50) DEFAULT '荤菜';

-- 更新现有记录的 category 字段（如果需要）
-- UPDATE dishes SET category = '荤菜' WHERE category IS NULL;






