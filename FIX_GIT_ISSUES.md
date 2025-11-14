# 修复 Git 问题指南

## 🔍 问题分析

### 问题 1: LF/CRLF 换行符警告

这是 Windows 和 Unix 系统之间的换行符差异：
- **LF** (Line Feed): Unix/Linux/macOS 使用 `\n`
- **CRLF** (Carriage Return + Line Feed): Windows 使用 `\r\n`

Git 检测到文件使用了 LF，但会在下次操作时转换为 CRLF（因为你在 Windows 上）。

### 问题 2: Git Push 失败

```
fatal: unable to access 'https://github.com/...': Recv failure: Connection was reset
```

这通常是网络连接问题，可能原因：
- 网络不稳定
- 需要配置代理（如果在国内）
- GitHub 连接被限制

## 🚀 解决方案

### 解决换行符警告（可选但推荐）

#### 方法 1: 配置 Git 自动处理（推荐）

在项目根目录执行：

```bash
# 配置 Git 自动转换换行符
git config core.autocrlf true

# 或者只对当前仓库配置
git config --local core.autocrlf true
```

**说明：**
- `true`: 提交时转换为 LF，检出时转换为 CRLF（Windows 推荐）
- `input`: 提交时转换为 LF，检出时不转换（Linux/macOS 推荐）
- `false`: 不转换（不推荐，除非团队统一使用一种系统）

#### 方法 2: 创建 .gitattributes 文件

在项目根目录创建 `.gitattributes` 文件：

```gitattributes
# 自动检测文本文件并标准化行尾
* text=auto

# 明确声明你希望始终标准化并在检出时转换为本地行尾的文件
*.dart text eol=lf
*.yaml text eol=lf
*.yml text eol=lf
*.json text eol=lf
*.md text eol=lf
*.txt text eol=lf

# 声明始终具有 CRLF 行尾的文件
*.bat text eol=crlf
*.cmd text eol=crlf
*.ps1 text eol=crlf

# 明确声明二进制文件（所有未明确声明的文件）
*.png binary
*.jpg binary
*.jpeg binary
*.gif binary
*.ico binary
*.pdf binary
*.apk binary
*.ipa binary
*.jar binary
*.class binary
*.so binary
*.dll binary
*.exe binary
*.zip binary
*.tar.gz binary
*.rar binary
*.7z binary
```

然后执行：

```bash
# 重新标准化所有文件
git add --renormalize .
git commit -m "Normalize line endings"
```

### 解决 Git Push 失败

#### 方法 1: 重试（最简单）

网络问题通常是暂时的，直接重试：

```bash
git push origin master
```

#### 方法 2: 配置 Git 使用 SSH（推荐）

如果 HTTPS 连接不稳定，使用 SSH：

1. **生成 SSH 密钥**（如果还没有）：
   ```bash
   ssh-keygen -t ed25519 -C "your_email@example.com"
   ```

2. **添加 SSH 密钥到 GitHub**：
   - 复制 `~/.ssh/id_ed25519.pub` 的内容
   - 在 GitHub → Settings → SSH and GPG keys → New SSH key

3. **修改远程仓库 URL**：
   ```bash
   # 查看当前远程 URL
   git remote -v
   
   # 修改为 SSH URL
   git remote set-url origin git@github.com:StrinGuo/fufuDiningRoom.git
   
   # 验证
   git remote -v
   ```

4. **测试连接**：
   ```bash
   ssh -T git@github.com
   ```

5. **重新推送**：
   ```bash
   git push origin master
   ```

#### 方法 3: 配置代理（如果在国内）

如果你使用代理：

```bash
# HTTP 代理
git config --global http.proxy http://127.0.0.1:7890
git config --global https.proxy http://127.0.0.1:7890

# SOCKS5 代理
git config --global http.proxy socks5://127.0.0.1:7890
git config --global https.proxy socks5://127.0.0.1:7890

# 取消代理
git config --global --unset http.proxy
git config --global --unset https.proxy
```

#### 方法 4: 增加缓冲区大小

```bash
git config --global http.postBuffer 524288000
git config --global http.lowSpeedLimit 0
git config --global http.lowSpeedTime 999999
```

#### 方法 5: 使用 GitHub CLI（备选）

如果以上方法都不行，可以使用 GitHub CLI：

```bash
# 安装 GitHub CLI (gh)
# Windows: winget install GitHub.cli
# 或下载: https://cli.github.com/

# 登录
gh auth login

# 推送
git push origin master
```

## ✅ 快速修复步骤

### 1. 配置换行符（可选）

```bash
git config --local core.autocrlf true
```

### 2. 重试推送

```bash
git push origin master
```

### 3. 如果还是失败，使用 SSH

```bash
# 修改远程 URL
git remote set-url origin git@github.com:StrinGuo/fufuDiningRoom.git

# 推送
git push origin master
```

## 📝 注意事项

1. **换行符警告不影响功能**：这只是警告，不会影响代码运行
2. **团队协作**：如果团队使用不同操作系统，建议统一配置 `.gitattributes`
3. **网络问题**：GitHub 在国内访问可能不稳定，建议使用 SSH 或代理

## 🔧 验证配置

```bash
# 查看 Git 配置
git config --list

# 查看远程仓库 URL
git remote -v

# 测试 SSH 连接（如果使用 SSH）
ssh -T git@github.com
```

