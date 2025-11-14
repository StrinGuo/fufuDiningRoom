# 解决 Apache 默认页面问题

## 🔍 问题分析

看到 "Welcome to HTTP Server Test Page!" 说明：
- ✅ Apache 服务器正常运行
- ❌ Flutter Web 文件还没有上传到正确位置
- ❌ 或者网站根目录配置不正确

## 🚀 解决步骤

### 步骤 1: 确认网站根目录

在宝塔面板中：

1. 登录宝塔面板
2. 进入「网站」→ 找到你的网站（IP: 123.56.187.81）
3. 点击「设置」→ 查看「网站目录」
4. 通常路径是：`/www/wwwroot/123.56.187.81`

### 步骤 2: 构建 Flutter Web 应用

在本地项目目录执行：

```bash
flutter clean
flutter pub get
flutter build web --release
```

构建完成后，文件在 `build/web/` 目录。

### 步骤 3: 上传文件

**方法 A: 使用宝塔面板文件管理器（推荐）**

1. 在宝塔面板进入「文件」管理
2. 导航到 `/www/wwwroot/123.56.187.81/`
3. **删除所有现有文件**（包括 `index.html` 等默认文件）
4. 上传 `build/web` 目录下的**所有文件**：
   - `index.html`
   - `main.dart.js`
   - `flutter.js`
   - `canvaskit/` 目录（如果有）
   - 其他所有文件

**方法 B: 使用 SFTP 工具**

使用 FileZilla、WinSCP 等工具：
- 连接服务器
- 删除 `/www/wwwroot/123.56.187.81/` 目录下的所有文件
- 上传 `build/web` 目录下的所有文件

### 步骤 4: 检查文件权限

在宝塔面板「文件」管理中：

1. 选中网站根目录 `/www/wwwroot/123.56.187.81`
2. 右键 → 「权限」
3. 设置为：
   - 所有者：`www`
   - 权限：`755`（目录）和 `644`（文件）

或使用 SSH 执行：

```bash
chown -R www:www /www/wwwroot/123.56.187.81
chmod -R 755 /www/wwwroot/123.56.187.81
find /www/wwwroot/123.56.187.81 -type f -exec chmod 644 {} \;
```

### 步骤 5: 配置 Apache（如果需要）

如果使用的是 Apache 而不是 Nginx：

1. 在宝塔面板「网站」→ 你的网站 → 「设置」
2. 点击「配置文件」标签
3. 确保 `DocumentRoot` 指向正确路径：
   ```apache
   DocumentRoot /www/wwwroot/123.56.187.81
   ```
4. 确保有路由重写规则（Flutter Web 需要）：
   ```apache
   <Directory /www/wwwroot/123.56.187.81>
       Options -Indexes +FollowSymLinks
       AllowOverride All
       Require all granted
   </Directory>

   <IfModule mod_rewrite.c>
       RewriteEngine On
       RewriteBase /
       RewriteRule ^index\.html$ - [L]
       RewriteCond %{REQUEST_FILENAME} !-f
       RewriteCond %{REQUEST_FILENAME} !-d
       RewriteRule . /index.html [L]
   </IfModule>
   ```

5. 点击「保存」
6. 重启 Apache（在「网站」→ 「设置」→ 「服务」中重启）

### 步骤 6: 清除浏览器缓存

访问网站前：
- 按 `Ctrl + Shift + R`（Windows）强制刷新
- 或清除浏览器缓存

## ✅ 验证

访问 `http://123.56.187.81`，应该看到你的 Flutter Web 应用，而不是 Apache 默认页面。

## 🐛 如果还是不行

### 检查 1: 确认文件已上传

SSH 连接到服务器，检查：

```bash
ls -la /www/wwwroot/123.56.187.81/
```

应该看到：
- `index.html`
- `main.dart.js`
- `flutter.js`
- 其他 Flutter Web 文件

### 检查 2: 确认使用的是哪个 Web 服务器

在宝塔面板「网站」→ 「设置」中查看：
- 如果显示「Nginx」，参考 `nginx_baota.conf`
- 如果显示「Apache」，需要配置 Apache 路由规则

### 检查 3: 检查错误日志

在宝塔面板「网站」→ 「设置」→ 「日志」中查看错误日志，排查问题。

## 📝 快速检查清单

- [ ] Flutter Web 已构建（`flutter build web --release`）
- [ ] 文件已上传到 `/www/wwwroot/123.56.187.81/`
- [ ] 已删除默认的 Apache 测试文件
- [ ] 文件权限正确（www:www, 755/644）
- [ ] Web 服务器配置了路由重写规则
- [ ] 已重启 Web 服务器
- [ ] 已清除浏览器缓存

