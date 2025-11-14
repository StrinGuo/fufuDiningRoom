# 修复 Nginx "unknown directive" 错误

## 🔍 错误原因

`nginx: [emerg] unknown directive` 通常由以下原因引起：
1. 配置文件中有特殊字符（中文引号、全角空格等）
2. 指令位置错误
3. 缺少分号或括号不匹配
4. 复制粘贴时引入了不可见字符

## 🚀 快速修复方法

### 方法 1: 在宝塔面板中手动添加（推荐）

**不要直接复制整个配置文件**，而是：

1. 登录宝塔面板
2. 进入「网站」→ 你的网站 → 「设置」
3. 点击「配置文件」标签
4. **找到 `location /` 块**（如果不存在，添加一个）

**找到这段：**
```nginx
location / {
    # 可能有一些其他配置
}
```

**修改为：**
```nginx
location / {
    try_files $uri $uri/ /index.html;
}
```

5. 点击「保存」
6. 点击「重载配置」

### 方法 2: 使用宝塔面板的「伪静态」功能（最简单）

1. 在宝塔面板「网站」→ 你的网站 → 「设置」
2. 点击「伪静态」标签
3. 选择「Flutter」或「Vue」模板
4. 如果没有，手动添加：

```nginx
location / {
    try_files $uri $uri/ /index.html;
}
```

5. 点击「保存」

### 方法 3: 检查配置文件语法

如果必须修改完整配置，按以下步骤：

1. **备份原配置**（重要！）
2. 在宝塔面板「网站」→ 「设置」→ 「配置文件」
3. 点击「重置」恢复默认配置
4. 然后只添加必要的 `location /` 块

## 📝 最小化配置（只添加必要部分）

在你的原始配置基础上，**只添加或修改这一部分**：

```nginx
# 找到 location / 块，修改为：
location / {
    try_files $uri $uri/ /index.html;
}
```

**不要删除其他配置**，特别是：
- `include` 指令
- SSL 相关配置
- 日志配置
- 其他 location 块

## 🔧 常见错误和修复

### 错误 1: 中文引号

**错误：**
```nginx
add_header Cache-Control "public, immutable";  # 使用了中文引号
```

**正确：**
```nginx
add_header Cache-Control "public, immutable";  # 使用英文引号
```

### 错误 2: 指令位置错误

`location /` 块必须在 `server` 块内，不能在其他 location 块内。

### 错误 3: 缺少分号

**错误：**
```nginx
try_files $uri $uri/ /index.html  # 缺少分号
```

**正确：**
```nginx
try_files $uri $uri/ /index.html;  # 有分号
```

### 错误 4: 特殊字符

复制粘贴时可能引入不可见字符，建议：
- 在宝塔面板中直接输入，不要复制粘贴
- 或使用纯文本编辑器（Notepad++、VS Code）

## ✅ 验证配置

在宝塔面板中：

1. 点击「重载配置」
2. 如果还有错误，查看错误日志：
   - 「网站」→ 「设置」→ 「日志」
   - 或 SSH 执行：`nginx -t`

## 🎯 最简单的解决方案

**如果你只是想快速解决问题：**

1. 在宝塔面板「网站」→ 「设置」→ 「伪静态」
2. 添加这一行：
   ```nginx
   try_files $uri $uri/ /index.html;
   ```
3. 保存

这样就足够了！不需要修改其他配置。

## 📞 如果还是不行

1. **查看完整错误信息**：
   ```bash
   nginx -t
   ```
   这会显示具体是哪一行出错

2. **重置配置**：
   - 在宝塔面板中点击「重置」恢复默认
   - 然后只添加 `location /` 块

3. **检查 Nginx 版本**：
   ```bash
   nginx -v
   ```
   某些指令可能需要特定版本

