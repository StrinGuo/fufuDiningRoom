# Flutter Web 部署脚本 (Windows PowerShell)
# 使用方法: .\deploy.ps1 -ServerIP "192.168.1.100" -ServerUser "root" -DeployPath "/var/www/html"

param(
    [Parameter(Mandatory=$true)]
    [string]$ServerIP,
    
    [Parameter(Mandatory=$false)]
    [string]$ServerUser = "root",
    
    [Parameter(Mandatory=$false)]
    [string]$DeployPath = "/var/www/html"
)

$ErrorActionPreference = "Stop"
$LocalBuildDir = "build\web"

Write-Host "=== Flutter Web 部署脚本 ===" -ForegroundColor Green
Write-Host ""

# 步骤 1: 清理和构建
Write-Host "[1/4] 清理之前的构建..." -ForegroundColor Yellow
flutter clean

Write-Host "[2/4] 获取依赖..." -ForegroundColor Yellow
flutter pub get

Write-Host "[3/4] 构建 Web 应用（Release 模式）..." -ForegroundColor Yellow
flutter build web --release

# 检查构建是否成功
if (-not (Test-Path $LocalBuildDir)) {
    Write-Host "错误: 构建失败，未找到 $LocalBuildDir 目录" -ForegroundColor Red
    exit 1
}

Write-Host "✓ 构建成功！" -ForegroundColor Green
Write-Host ""

# 步骤 2: 上传文件
Write-Host "[4/4] 上传文件到服务器..." -ForegroundColor Yellow
Write-Host "服务器: ${ServerUser}@${ServerIP}"
Write-Host "目标路径: $DeployPath"

# 检查是否安装了 SCP（通过 OpenSSH）
$scpPath = Get-Command scp -ErrorAction SilentlyContinue
if (-not $scpPath) {
    Write-Host "错误: 未找到 scp 命令" -ForegroundColor Red
    Write-Host "请安装 OpenSSH 客户端或使用其他方式上传文件" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "手动上传步骤:" -ForegroundColor Yellow
    Write-Host "1. 将 $LocalBuildDir 目录下的所有文件上传到服务器"
    Write-Host "2. 使用 FileZilla、WinSCP 或其他 SFTP 工具"
    Write-Host "3. 目标路径: ${ServerUser}@${ServerIP}:$DeployPath"
    exit 1
}

# 创建部署目录（如果不存在）
Write-Host "创建部署目录..."
ssh "${ServerUser}@${ServerIP}" "mkdir -p $DeployPath"

# 上传文件
Write-Host "正在上传文件..."
scp -r "${LocalBuildDir}\*" "${ServerUser}@${ServerIP}:${DeployPath}/"

# 步骤 3: 设置权限
Write-Host ""
Write-Host "设置文件权限..." -ForegroundColor Yellow
ssh "${ServerUser}@${ServerIP}" "chown -R www-data:www-data $DeployPath && chmod -R 755 $DeployPath"

Write-Host ""
Write-Host "=== 部署完成！ ===" -ForegroundColor Green
Write-Host "访问地址: http://$ServerIP"
Write-Host ""
Write-Host "注意:" -ForegroundColor Yellow
Write-Host "1. 确保已配置 Web 服务器（Nginx/Apache）"
Write-Host "2. 确保 Web 服务器指向 $DeployPath"
Write-Host "3. 建议配置 HTTPS（使用 Let's Encrypt）"

