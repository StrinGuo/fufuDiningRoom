#!/bin/bash

# Flutter Web 部署脚本
# 使用方法: ./deploy.sh [服务器IP] [服务器用户] [部署路径]

set -e  # 遇到错误立即退出

# 颜色输出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# 配置变量
SERVER_IP="${1:-}"
SERVER_USER="${2:-root}"
DEPLOY_PATH="${3:-/var/www/html}"
LOCAL_BUILD_DIR="build/web"

echo -e "${GREEN}=== Flutter Web 部署脚本 ===${NC}\n"

# 检查参数
if [ -z "$SERVER_IP" ]; then
    echo -e "${RED}错误: 请提供服务器 IP 地址${NC}"
    echo "使用方法: ./deploy.sh <服务器IP> [用户名] [部署路径]"
    echo "示例: ./deploy.sh 192.168.1.100 root /var/www/html"
    exit 1
fi

# 步骤 1: 清理和构建
echo -e "${YELLOW}[1/4] 清理之前的构建...${NC}"
flutter clean

echo -e "${YELLOW}[2/4] 获取依赖...${NC}"
flutter pub get

echo -e "${YELLOW}[3/4] 构建 Web 应用（Release 模式）...${NC}"
flutter build web --release

# 检查构建是否成功
if [ ! -d "$LOCAL_BUILD_DIR" ]; then
    echo -e "${RED}错误: 构建失败，未找到 $LOCAL_BUILD_DIR 目录${NC}"
    exit 1
fi

echo -e "${GREEN}✓ 构建成功！${NC}\n"

# 步骤 2: 上传文件
echo -e "${YELLOW}[4/4] 上传文件到服务器...${NC}"
echo "服务器: $SERVER_USER@$SERVER_IP"
echo "目标路径: $DEPLOY_PATH"

# 检查 SSH 连接
if ! ssh -o ConnectTimeout=5 "$SERVER_USER@$SERVER_IP" "echo 'SSH 连接成功'" 2>/dev/null; then
    echo -e "${RED}错误: 无法连接到服务器 $SERVER_USER@$SERVER_IP${NC}"
    echo "请检查:"
    echo "  1. 服务器 IP 是否正确"
    echo "  2. SSH 服务是否运行"
    echo "  3. 是否配置了 SSH 密钥或密码"
    exit 1
fi

# 创建部署目录（如果不存在）
ssh "$SERVER_USER@$SERVER_IP" "mkdir -p $DEPLOY_PATH"

# 上传文件
echo "正在上传文件..."
rsync -avz --delete \
    --exclude='.DS_Store' \
    "$LOCAL_BUILD_DIR/" \
    "$SERVER_USER@$SERVER_IP:$DEPLOY_PATH/"

# 步骤 3: 设置权限
echo -e "\n${YELLOW}设置文件权限...${NC}"
ssh "$SERVER_USER@$SERVER_IP" "chown -R www-data:www-data $DEPLOY_PATH && chmod -R 755 $DEPLOY_PATH"

echo -e "\n${GREEN}=== 部署完成！ ===${NC}"
echo -e "访问地址: http://$SERVER_IP"
echo -e "\n${YELLOW}注意:${NC}"
echo "1. 确保已配置 Web 服务器（Nginx/Apache）"
echo "2. 确保 Web 服务器指向 $DEPLOY_PATH"
echo "3. 建议配置 HTTPS（使用 Let's Encrypt）"

