# Flutter Web 部署指南

本指南将帮助你将 Flutter Web 应用部署到公网服务器。

## 📋 前置要求

1. **服务器环境**
   - Linux 服务器（Ubuntu/CentOS/Debian 等）
   - 已安装 Nginx 或 Apache
   - 有 root 或 sudo 权限

2. **本地环境**
   - 已安装 Flutter SDK
   - 项目可以正常构建

## 🚀 部署步骤

### 步骤 1: 构建 Flutter Web 应用

在项目根目录执行：

```bash
# 清理之前的构建
flutter clean

# 获取依赖
flutter pub get

# 构建 Web 应用（Release 模式）
flutter build web --release
```

构建完成后，文件会生成在 `build/web/` 目录。

### 步骤 2: 上传文件到服务器

**方法 A: 使用 SCP（推荐）**

```bash
# 将 build/web 目录下的所有文件上传到服务器
scp -r build/web/* root@your-server-ip:/var/www/html/
```

**方法 B: 使用 SFTP**

```bash
# 使用 FileZilla 或其他 SFTP 工具
# 连接服务器后，将 build/web 目录下的所有文件上传到 /var/www/html/
```

**方法 C: 使用 Git（如果服务器有 Git）**

```bash
# 在服务器上
cd /var/www/html
git clone your-repo-url .
# 然后构建
flutter build web --release
# 将 build/web 内容复制到当前目录
cp -r build/web/* .
```

### 步骤 3: 配置 Web 服务器

#### 选项 A: Nginx 配置（推荐）

创建或编辑 Nginx 配置文件：

```bash
sudo nano /etc/nginx/sites-available/fufu-dining-room
```

添加以下配置：

```nginx
server {
    listen 80;
    server_name your-domain.com;  # 替换为你的域名或 IP

    root /var/www/html;
    index index.html;

    # 启用 gzip 压缩
    gzip on;
    gzip_vary on;
    gzip_min_length 1024;
    gzip_types text/plain text/css text/xml text/javascript application/x-javascript application/xml+rss application/json application/javascript;

    # Flutter Web 路由支持（重要！）
    location / {
        try_files $uri $uri/ /index.html;
    }

    # 缓存静态资源
    location ~* \.(js|css|png|jpg|jpeg|gif|ico|svg|woff|woff2|ttf|eot)$ {
        expires 1y;
        add_header Cache-Control "public, immutable";
    }

    # 不缓存 HTML 文件
    location ~* \.html$ {
        expires -1;
        add_header Cache-Control "no-cache, no-store, must-revalidate";
    }
}
```

启用站点：

```bash
# 创建符号链接
sudo ln -s /etc/nginx/sites-available/fufu-dining-room /etc/nginx/sites-enabled/

# 测试配置
sudo nginx -t

# 重启 Nginx
sudo systemctl restart nginx
```

#### 选项 B: Apache 配置

编辑 Apache 配置文件：

```bash
sudo nano /etc/apache2/sites-available/fufu-dining-room.conf
```

添加以下配置：

```apache
<VirtualHost *:80>
    ServerName your-domain.com  # 替换为你的域名或 IP
    DocumentRoot /var/www/html

    <Directory /var/www/html>
        Options -Indexes +FollowSymLinks
        AllowOverride All
        Require all granted
    </Directory>

    # Flutter Web 路由支持
    <IfModule mod_rewrite.c>
        RewriteEngine On
        RewriteBase /
        RewriteRule ^index\.html$ - [L]
        RewriteCond %{REQUEST_FILENAME} !-f
        RewriteCond %{REQUEST_FILENAME} !-d
        RewriteRule . /index.html [L]
    </IfModule>

    # 启用压缩
    <IfModule mod_deflate.c>
        AddOutputFilterByType DEFLATE text/html text/plain text/xml text/css text/javascript application/javascript application/json
    </IfModule>

    # 缓存静态资源
    <IfModule mod_expires.c>
        ExpiresActive On
        ExpiresByType image/jpg "access plus 1 year"
        ExpiresByType image/jpeg "access plus 1 year"
        ExpiresByType image/gif "access plus 1 year"
        ExpiresByType image/png "access plus 1 year"
        ExpiresByType image/svg+xml "access plus 1 year"
        ExpiresByType text/css "access plus 1 year"
        ExpiresByType application/javascript "access plus 1 year"
        ExpiresByType application/x-javascript "access plus 1 year"
    </IfModule>
</VirtualHost>
```

启用站点：

```bash
# 启用 rewrite 模块
sudo a2enmod rewrite
sudo a2enmod expires
sudo a2enmod deflate

# 启用站点
sudo a2ensite fufu-dining-room.conf

# 测试配置
sudo apache2ctl configtest

# 重启 Apache
sudo systemctl restart apache2
```

### 步骤 4: 配置 HTTPS（可选但强烈推荐）

使用 Let's Encrypt 免费 SSL 证书：

```bash
# 安装 Certbot
sudo apt-get update
sudo apt-get install certbot python3-certbot-nginx  # Nginx
# 或
sudo apt-get install certbot python3-certbot-apache  # Apache

# 获取证书
sudo certbot --nginx -d your-domain.com  # Nginx
# 或
sudo certbot --apache -d your-domain.com  # Apache

# 自动续期（已自动配置）
sudo certbot renew --dry-run
```

### 步骤 5: 设置文件权限

```bash
# 设置正确的文件权限
sudo chown -R www-data:www-data /var/www/html
sudo chmod -R 755 /var/www/html
```

## 🔧 高级配置

### 1. 配置环境变量（如果需要）

如果将来需要区分开发/生产环境，可以：

1. 修改 `lib/core/configs/supabase_config.dart` 使用环境变量
2. 在构建时注入环境变量（需要修改构建脚本）

### 2. 配置 CORS（如果需要）

如果 Supabase 需要额外的 CORS 配置，在 Nginx 配置中添加：

```nginx
location / {
    add_header Access-Control-Allow-Origin *;
    add_header Access-Control-Allow-Methods "GET, POST, OPTIONS";
    add_header Access-Control-Allow-Headers "DNT,User-Agent,X-Requested-With,If-Modified-Since,Cache-Control,Content-Type,Range";
}
```

### 3. 配置 CDN（可选）

可以将静态资源（JS、CSS、图片）上传到 CDN，加速访问。

## 📝 快速部署脚本

创建 `deploy.sh` 脚本（见下方文件）可以一键部署。

## ✅ 验证部署

1. 在浏览器访问 `http://your-server-ip` 或 `https://your-domain.com`
2. 检查浏览器控制台是否有错误
3. 测试应用功能是否正常

## 🐛 常见问题

### 1. 路由 404 错误

**问题**: 刷新页面或直接访问子路由时出现 404。

**解决**: 确保 Web 服务器配置了路由重定向（见步骤 3）。

### 2. 静态资源加载失败

**问题**: JS、CSS 文件无法加载。

**解决**: 
- 检查文件路径是否正确
- 检查文件权限（应该是 755）
- 检查 Nginx/Apache 配置

### 3. Supabase 连接失败

**问题**: 无法连接到 Supabase。

**解决**:
- 检查 `supabase_config.dart` 中的 URL 和 Key 是否正确
- 检查服务器防火墙是否允许 HTTPS 连接
- 检查 Supabase 项目的网络设置

### 4. 性能问题

**优化建议**:
- 启用 gzip 压缩（已在配置中）
- 使用 CDN 加速静态资源
- 启用浏览器缓存（已在配置中）
- 考虑使用 Flutter Web 的 CanvasKit 渲染器（性能更好但体积更大）

## 📚 相关资源

- [Flutter Web 部署文档](https://docs.flutter.dev/deployment/web)
- [Nginx 官方文档](https://nginx.org/en/docs/)
- [Apache 官方文档](https://httpd.apache.org/docs/)
- [Let's Encrypt 文档](https://letsencrypt.org/docs/)

