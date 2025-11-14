# 宝塔面板部署 Flutter Web 指南

## 📋 前提条件

- 已安装宝塔面板
- 已创建网站（域名或 IP）
- 已安装 Nginx

## 🚀 部署步骤

### 步骤 1: 构建 Flutter Web 应用

在本地项目目录执行：

```bash
flutter clean
flutter pub get
flutter build web --release
```

### 步骤 2: 上传文件到服务器

**方法 A: 使用宝塔面板文件管理器**

1. 登录宝塔面板
2. 进入「文件」管理
3. 导航到 `/www/wwwroot/你的域名或IP/`
4. 删除该目录下的所有文件（如果有）
5. 上传 `build/web` 目录下的所有文件

**方法 B: 使用 SFTP 工具**

使用 FileZilla、WinSCP 等工具，将 `build/web` 目录下的所有文件上传到：
```
/www/wwwroot/123.56.187.81/
```

### 步骤 3: 修改 Nginx 配置

1. 登录宝塔面板
2. 进入「网站」→ 找到你的网站 → 点击「设置」
3. 点击「配置文件」标签
4. 将配置文件替换为 `nginx_baota.conf` 中的内容
5. 或者手动添加以下关键配置：

**重要：在 `location /` 块中添加路由支持**

找到：
```nginx
location / {
    # 这里需要添加 try_files
}
```

修改为：
```nginx
location / {
    try_files $uri $uri/ /index.html;
}
```

**优化静态资源缓存**

找到图片缓存配置，修改为：
```nginx
location ~ .*\.(gif|jpg|jpeg|png|bmp|swf|svg|webp|ico)$
{
    expires      30d;
    add_header Cache-Control "public, immutable";
    error_log /dev/null;
    access_log /dev/null;
}
```

找到 JS/CSS 缓存配置，修改为：
```nginx
location ~ .*\.(js|css|woff|woff2|ttf|eot|otf)$
{
    expires      1y;
    add_header Cache-Control "public, immutable";
    error_log /dev/null;
    access_log /dev/null;
}
```

**添加 HTML 不缓存配置**

在配置文件中添加：
```nginx
location ~ .*\.(html|htm)$
{
    expires      -1;
    add_header Cache-Control "no-cache, no-store, must-revalidate";
    add_header Pragma "no-cache";
}
```

5. 点击「保存」
6. 点击「重载配置」或「重启」Nginx

### 步骤 4: 设置文件权限

在宝塔面板「文件」管理中：
1. 选中网站根目录
2. 右键 → 「权限」
3. 设置为 `755`（目录）和 `644`（文件）
4. 所有者设置为 `www`

或者使用 SSH 执行：
```bash
chown -R www:www /www/wwwroot/123.56.187.81
chmod -R 755 /www/wwwroot/123.56.187.81
find /www/wwwroot/123.56.187.81 -type f -exec chmod 644 {} \;
```

### 步骤 5: 配置 SSL（可选但推荐）

1. 在宝塔面板「网站」→ 你的网站 → 「设置」
2. 点击「SSL」标签
3. 选择「Let's Encrypt」免费证书
4. 输入域名（如果有域名）
5. 点击「申请」
6. 申请成功后，开启「强制 HTTPS」

## ✅ 验证部署

访问 `http://123.56.187.81` 或 `https://你的域名` 查看应用。

## 🐛 常见问题

### 1. 刷新页面出现 404

**原因**: Nginx 配置缺少路由重定向

**解决**: 确保在 `location /` 块中添加了：
```nginx
try_files $uri $uri/ /index.html;
```

### 2. 静态资源加载失败

**原因**: 文件权限不正确

**解决**: 
```bash
chown -R www:www /www/wwwroot/123.56.187.81
chmod -R 755 /www/wwwroot/123.56.187.81
```

### 3. 更新后看不到最新内容

**原因**: 浏览器缓存

**解决**: 
- 清除浏览器缓存
- 或使用 Ctrl+Shift+R（Windows）强制刷新
- 确保 HTML 文件配置了不缓存

### 4. 宝塔面板配置被覆盖

**原因**: 宝塔面板会自动管理部分配置

**解决**: 
- 在「网站设置」→「配置文件」中手动添加关键配置
- 或者使用「伪静态」功能添加路由规则

## 📝 宝塔面板伪静态规则（备选方案）

如果修改配置文件不方便，可以在「网站设置」→「伪静态」中添加：

```nginx
location / {
    try_files $uri $uri/ /index.html;
}
```

## 🔧 性能优化建议

1. **启用 Gzip 压缩**
   - 在宝塔面板「网站」→「性能」中启用

2. **启用 CDN**（可选）
   - 将静态资源上传到 CDN
   - 修改应用中的资源路径

3. **定期备份**
   - 使用宝塔面板的「计划任务」功能定期备份网站文件

## 📚 相关资源

- [宝塔面板官方文档](https://www.bt.cn/bbs/forum-40-1.html)
- [Nginx 官方文档](https://nginx.org/en/docs/)

