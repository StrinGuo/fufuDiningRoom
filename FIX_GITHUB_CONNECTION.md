# 解决 GitHub 连接问题

## 🔍 问题

```
fatal: unable to access 'https://github.com/...': Failed to connect to github.com port 443
```

这是网络连接问题，在国内访问 GitHub 可能不稳定。

## 🚀 解决方案（按推荐顺序）

### 方案 1: 使用 SSH（最推荐）

SSH 连接通常比 HTTPS 更稳定。

#### 步骤 1: 检查是否已有 SSH 密钥

```bash
# 检查是否存在 SSH 密钥
dir %USERPROFILE%\.ssh
# 或
ls ~/.ssh
```

如果看到 `id_rsa` 或 `id_ed25519` 文件，说明已有密钥。

#### 步骤 2: 生成 SSH 密钥（如果没有）

```bash
ssh-keygen -t ed25519 -C "your_email@example.com"
```

按 Enter 使用默认路径，可以设置密码（可选）。

#### 步骤 3: 复制公钥

```bash
# Windows PowerShell
type %USERPROFILE%\.ssh\id_ed25519.pub
# 或
cat ~/.ssh/id_ed25519.pub
```

复制输出的内容（以 `ssh-ed25519` 开头）。

#### 步骤 4: 添加到 GitHub

1. 登录 GitHub
2. 点击右上角头像 → **Settings**
3. 左侧菜单 → **SSH and GPG keys**
4. 点击 **New SSH key**
5. Title: 填写一个名称（如 "My Windows PC"）
6. Key: 粘贴刚才复制的公钥
7. 点击 **Add SSH key**

#### 步骤 5: 测试 SSH 连接

```bash
ssh -T git@github.com
```

如果看到 "Hi StrinGuo! You've successfully authenticated..." 说明成功。

#### 步骤 6: 修改远程仓库 URL

```bash
# 修改为 SSH URL
git remote set-url origin git@github.com:StrinGuo/fufuDiningRoom.git

# 验证
git remote -v
```

#### 步骤 7: 重新推送

```bash
git push origin master
```

### 方案 2: 配置代理（如果你有代理）

如果你使用代理软件（如 Clash、V2Ray 等）：

#### 查看代理端口

通常在代理软件的设置中可以看到，常见端口：
- HTTP: 7890, 10809
- SOCKS5: 1080, 7891

#### 配置 Git 代理

```bash
# HTTP 代理（端口根据你的代理软件调整）
git config --global http.proxy http://127.0.0.1:7890
git config --global https.proxy http://127.0.0.1:7890

# SOCKS5 代理
git config --global http.proxy socks5://127.0.0.1:7890
git config --global https.proxy socks5://127.0.0.1:7890
```

#### 测试连接

```bash
git push origin master
```

#### 取消代理（如果不需要了）

```bash
git config --global --unset http.proxy
git config --global --unset https.proxy
```

### 方案 3: 使用 GitHub 镜像（临时方案）

可以临时使用镜像站点，但不推荐长期使用。

### 方案 4: 增加超时时间

```bash
git config --global http.postBuffer 524288000
git config --global http.lowSpeedLimit 0
git config --global http.lowSpeedTime 999999
git config --global http.timeout 300
```

然后重试：

```bash
git push origin master
```

### 方案 5: 使用 GitHub Desktop（GUI 工具）

如果命令行一直失败，可以使用 GitHub Desktop：
1. 下载：https://desktop.github.com/
2. 登录 GitHub 账号
3. 打开项目
4. 点击 Push

## ✅ 推荐操作流程

1. **首先尝试 SSH**（最稳定）
   ```bash
   # 检查 SSH 密钥
   dir %USERPROFILE%\.ssh
   
   # 如果没有，生成一个
   ssh-keygen -t ed25519 -C "your_email@example.com"
   
   # 复制公钥并添加到 GitHub
   type %USERPROFILE%\.ssh\id_ed25519.pub
   
   # 修改远程 URL
   git remote set-url origin git@github.com:StrinGuo/fufuDiningRoom.git
   
   # 推送
   git push origin master
   ```

2. **如果 SSH 不行，配置代理**
   ```bash
   git config --global http.proxy http://127.0.0.1:7890
   git config --global https.proxy http://127.0.0.1:7890
   git push origin master
   ```

## 🔧 验证配置

```bash
# 查看远程 URL
git remote -v

# 测试 SSH 连接
ssh -T git@github.com

# 查看代理配置
git config --global --get http.proxy
```

## 📝 注意事项

1. **SSH 是最稳定的方案**，强烈推荐
2. **代理需要保持运行**，否则会失败
3. **网络问题可能是暂时的**，可以稍后重试
4. **如果都不行**，可以考虑使用 GitHub Desktop 或 GitLab/Gitee 作为替代

