# iOS 应用打包完整指南

## 📋 前置要求

1. **macOS 系统**（必须）
   - iOS 应用只能在 macOS 上构建
   - 需要 macOS 10.15 或更高版本

2. **Xcode**
   - 从 App Store 安装 Xcode（免费）
   - 或从 [Apple Developer](https://developer.apple.com/xcode/) 下载
   - 安装后运行：`sudo xcode-select --switch /Applications/Xcode.app/Contents/Developer`

3. **Flutter SDK**
   - 已安装 Flutter
   - 运行 `flutter doctor` 检查 iOS 工具链

4. **Apple Developer 账号**（可选）
   - 免费账号：可以构建和测试，但不能发布到 App Store
   - 付费账号（$99/年）：可以发布到 App Store 和 TestFlight

## 🚀 方法 1: 使用 Flutter 命令行（推荐）

### 步骤 1: 检查环境

```bash
# 检查 Flutter 环境
flutter doctor

# 确保 iOS 工具链正常
flutter doctor -v
```

### 步骤 2: 获取依赖

```bash
# 在项目根目录
flutter clean
flutter pub get
```

### 步骤 3: 构建 iOS 应用

#### 选项 A: Debug 版本（用于测试）

```bash
flutter build ios --debug
```

构建完成后，应用在：`build/ios/iphoneos/Runner.app`

#### 选项 B: Release 版本（用于发布）

```bash
flutter build ios --release
```

构建完成后，应用在：`build/ios/iphoneos/Runner.app`

#### 选项 C: 未签名版本（用于企业内部分发）

```bash
flutter build ios --release
# 然后使用 Xcode 构建未签名版本（见方法 2）
```

### 步骤 4: 在 Xcode 中打开项目

```bash
open ios/Runner.xcworkspace
```

**注意**：必须打开 `.xcworkspace` 文件，不是 `.xcodeproj`！

### 步骤 5: 配置签名（如果需要）

1. 在 Xcode 中选择 **Runner** 项目
2. 选择 **Signing & Capabilities** 标签
3. 选择你的 **Team**（需要 Apple ID 登录）
4. Xcode 会自动管理证书和配置文件

**未签名构建**：
- 取消勾选 **Automatically manage signing**
- 在 **Signing Certificate** 中选择 **None**

### 步骤 6: 选择设备或模拟器

在 Xcode 顶部工具栏：
- 选择连接的 iPhone/iPad（真机测试）
- 或选择模拟器（如 iPhone 14 Pro）

### 步骤 7: 构建并运行

- 按 `Cmd + R` 构建并运行
- 或点击 Xcode 左上角的 ▶️ 按钮

## 🎯 方法 2: 使用 Xcode GUI（详细步骤）

### 步骤 1: 打开项目

```bash
cd ios
open Runner.xcworkspace
```

### 步骤 2: 选择构建目标

在 Xcode 顶部：
- **Scheme**: 选择 `Runner`
- **Destination**: 
  - 选择连接的设备（真机）
  - 或选择模拟器（如 iPhone 14 Pro）

### 步骤 3: 配置签名

1. 左侧项目导航器 → 选择 **Runner** 项目
2. 选择 **Runner** target
3. 点击 **Signing & Capabilities** 标签

**有 Apple Developer 账号**：
- ✅ 勾选 **Automatically manage signing**
- 选择你的 **Team**
- Xcode 会自动处理证书

**无账号或未签名构建**：
- ❌ 取消勾选 **Automatically manage signing**
- **Signing Certificate**: 选择 **None**
- **Provisioning Profile**: 选择 **None**

### 步骤 4: 选择构建配置

**Product** → **Scheme** → **Edit Scheme**：
- **Run**: Debug 或 Release
- **Archive**: Release（用于发布）

### 步骤 5: 构建应用

#### 方式 A: 直接运行（Cmd + R）

- 按 `Cmd + R` 或点击 ▶️ 按钮
- 应用会构建并安装到设备/模拟器

#### 方式 B: 构建 Archive（用于分发）

1. **Product** → **Archive**
2. 等待构建完成
3. **Organizer** 窗口会自动打开
4. 选择你的 Archive
5. 点击 **Distribute App**

### 步骤 6: 导出应用

在 **Organizer** 窗口中：

#### 选项 1: App Store Connect（发布到 App Store）

1. 选择 **App Store Connect**
2. 点击 **Next**
3. 选择分发选项
4. 点击 **Upload**

#### 选项 2: Ad Hoc（内部分发）

1. 选择 **Ad Hoc**
2. 选择设备 UDID
3. 点击 **Export**
4. 生成 `.ipa` 文件

#### 选项 3: Enterprise（企业分发）

1. 选择 **Enterprise**
2. 需要 Enterprise 账号
3. 点击 **Export**

#### 选项 4: Development（开发测试）

1. 选择 **Development**
2. 点击 **Export**
3. 生成 `.ipa` 文件

## 📦 方法 3: 构建未签名 IPA（企业内部分发）

### 步骤 1: 配置项目为未签名

在 Xcode 中：
1. **Runner** → **Signing & Capabilities**
2. 取消勾选 **Automatically manage signing**
3. **Signing Certificate**: **None**
4. **Provisioning Profile**: **None**

### 步骤 2: 使用命令行构建

```bash
cd ios

# 清理
xcodebuild clean -workspace Runner.xcworkspace -scheme Runner

# 构建未签名版本
xcodebuild -workspace Runner.xcworkspace \
           -scheme Runner \
           -configuration Release \
           -destination 'generic/platform=iOS' \
           CODE_SIGN_IDENTITY="" \
           CODE_SIGNING_REQUIRED=NO \
           CODE_SIGNING_ALLOWED=NO \
           build
```

### 步骤 3: 创建 IPA 文件

构建完成后，`Runner.app` 在：
```
build/ios/iphoneos/Runner.app
```

手动创建 IPA：
```bash
# 创建 Payload 目录
mkdir -p Payload

# 复制 app
cp -r build/ios/iphoneos/Runner.app Payload/

# 创建 IPA
zip -r Runner.ipa Payload

# 清理
rm -rf Payload
```

## 🔧 常见问题解决

### 问题 1: "No such module 'Flutter'"

**解决**：
```bash
cd ios
pod install
cd ..
flutter clean
flutter pub get
```

### 问题 2: "Signing for Runner requires a development team"

**解决**：
- 在 Xcode 中登录 Apple ID
- 或取消自动签名，使用未签名构建

### 问题 3: "Unable to boot simulator"

**解决**：
```bash
# 列出所有模拟器
xcrun simctl list devices

# 启动模拟器
open -a Simulator
```

### 问题 4: 构建速度慢

**优化**：
```bash
# 使用 Release 模式
flutter build ios --release

# 或只构建特定架构
flutter build ios --release --target-platform ios-arm64
```

### 问题 5: CocoaPods 问题

**解决**：
```bash
cd ios
pod deintegrate
pod install
cd ..
flutter clean
flutter pub get
```

## 📱 真机测试

### 步骤 1: 连接设备

1. 用 USB 连接 iPhone/iPad 到 Mac
2. 在设备上信任此电脑
3. 在 Xcode 中可以看到设备

### 步骤 2: 配置开发者账号

1. Xcode → **Preferences** → **Accounts**
2. 点击 **+** 添加 Apple ID
3. 登录你的 Apple ID

### 步骤 3: 在设备上运行

1. 选择连接的设备
2. 按 `Cmd + R` 运行
3. 首次运行需要在设备上信任开发者

## 📦 生成 IPA 文件

### 方法 A: 使用 Xcode Archive

1. **Product** → **Archive**
2. **Organizer** → 选择 Archive
3. **Distribute App** → **Development/Ad Hoc**
4. **Export** → 选择保存位置
5. 生成 `.ipa` 文件

### 方法 B: 使用命令行

```bash
# 构建
flutter build ios --release

# 在 Xcode 中 Archive
# 然后使用 xcodebuild 导出
xcodebuild -exportArchive \
  -archivePath ~/Library/Developer/Xcode/Archives/.../Runner.xcarchive \
  -exportPath ./build/ios/ipa \
  -exportOptionsPlist ExportOptions.plist
```

## ✅ 验证清单

- [ ] macOS 系统
- [ ] Xcode 已安装
- [ ] Flutter 环境正常（`flutter doctor`）
- [ ] 项目依赖已获取（`flutter pub get`）
- [ ] CocoaPods 已安装（`pod install`）
- [ ] 签名配置正确（或有未签名配置）
- [ ] 设备/模拟器已选择
- [ ] 构建成功

## 📚 相关资源

- [Flutter iOS 部署文档](https://docs.flutter.dev/deployment/ios)
- [Xcode 官方文档](https://developer.apple.com/xcode/)
- [Apple Developer 文档](https://developer.apple.com/documentation/)

## 🎯 快速命令参考

```bash
# 检查环境
flutter doctor

# 清理并获取依赖
flutter clean
flutter pub get
cd ios && pod install && cd ..

# 构建 Release 版本
flutter build ios --release

# 打开 Xcode
open ios/Runner.xcworkspace

# 构建未签名版本（命令行）
cd ios
xcodebuild -workspace Runner.xcworkspace \
           -scheme Runner \
           -configuration Release \
           -destination 'generic/platform=iOS' \
           CODE_SIGN_IDENTITY="" \
           CODE_SIGNING_REQUIRED=NO \
           CODE_SIGNING_ALLOWED=NO \
           build
```

