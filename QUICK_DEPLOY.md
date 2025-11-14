# 快速部署指南

## 🚀 一键部署（推荐）

### Linux/macOS

```bash
# 1. 给脚本添加执行权限
chmod +x deploy.sh

# 2. 运行部署脚本
./deploy.sh 192.168.1.100 root /var/www/html
```

### Windows

```powershell
# 运行 PowerShell 脚本
.\deploy.ps1 -ServerIP "192.168.1.100" -ServerUser "root" -DeployPath "/var/www/html"
```

## 📝 手动部署步骤

### 1. 构建应用

```bash
flutter clean
flutter pub get
flutter build web --release
```

### 2. 上传文件

**使用 SCP:**
```bash
scp -r build/web/* root@your-server-ip:/var/www/html/
```

**使用 SFTP 工具:**
- FileZilla
- WinSCP
- 将 `build/web` 目录下的所有文件上传到服务器的 `/var/www/html/`

### 3. 配置 Nginx

```bash
# 复制配置文件
sudo cp nginx.conf.example /etc/nginx/sites-available/fufu-dining-room

# 编辑配置文件，修改域名
sudo nano /etc/nginx/sites-available/fufu-dining-room

# 启用站点
sudo ln -s /etc/nginx/sites-available/fufu-dining-room /etc/nginx/sites-enabled/

# 测试配置
sudo nginx -t

# 重启 Nginx
sudo systemctl restart nginx
```

### 4. 配置 Apache（如果使用 Apache）

```bash
# 复制配置文件
sudo cp apache.conf.example /etc/apache2/sites-available/fufu-dining-room.conf

# 编辑配置文件，修改域名
sudo nano /etc/apache2/sites-available/fufu-dining-room.conf

# 启用模块
sudo a2enmod rewrite expires deflate

# 启用站点
sudo a2ensite fufu-dining-room.conf

# 测试配置
sudo apache2ctl configtest

# 重启 Apache
sudo systemctl restart apache2
```

### 5. 设置文件权限

```bash
sudo chown -R www-data:www-data /var/www/html
sudo chmod -R 755 /var/www/html
```

### 6. 配置 HTTPS（可选但推荐）

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
```

## ✅ 验证

访问 `http://your-server-ip` 或 `https://your-domain.com` 查看应用。

## 🐛 常见问题

### 路由 404 错误
确保 Web 服务器配置了路由重定向（见配置文件中的 `try_files` 或 `RewriteRule`）。

### 静态资源加载失败
检查文件权限：`sudo chmod -R 755 /var/www/html`

### 需要更多帮助？
查看完整文档：`DEPLOY_WEB.md`

