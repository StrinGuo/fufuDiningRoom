# iOS 未签名构建说明

## 配置说明

已配置项目支持构建未签名的 iOS 应用包。主要修改包括：

1. **project.pbxproj** - 已设置：
   - `CODE_SIGN_STYLE = Manual`
   - `CODE_SIGN_IDENTITY = ""`（空字符串，表示不签名）
   - `DEVELOPMENT_TEAM = ""`（空字符串）

2. **ExportOptions.plist** - 导出选项配置文件（用于未签名导出）

3. **build_unsigned.sh** - 自动化构建脚本（使用 xcodebuild）

## 构建方法

### 方法 1: 使用 Xcode GUI（推荐，最简单）

1. **打开项目**
   ```bash
   open ios/Runner.xcworkspace
   ```
   ⚠️ **重要**：必须打开 `.xcworkspace` 文件，不是 `.xcodeproj`

2. **等待索引完成**
   - Xcode 会自动开始索引项目
   - 等待索引完成（状态栏显示 "Indexing..."）

3. **选择构建目标**
   - 点击顶部工具栏的 Scheme 选择器（Runner）
   - 选择 **Runner**
   - 在 Destination 中选择 **Any iOS Device (arm64)**

4. **构建**
   - 选择菜单：**Product > Build**（或按 `Cmd+B`）
   - 等待构建完成

5. **查找构建产物**
   - 构建完成后，在 Xcode 左侧导航栏展开 **Products**
   - 右键点击 **Runner.app**
   - 选择 **Show in Finder**
   - 或者手动查找：`~/Library/Developer/Xcode/DerivedData/Runner-*/Build/Products/Release-iphoneos/Runner.app`

### 方法 2: 使用自动化脚本（命令行）

```bash
cd ios
chmod +x build_unsigned.sh
./build_unsigned.sh
```

脚本会自动：
- 清理之前的构建
- 获取 Flutter 依赖
- 使用 xcodebuild 构建未签名版本

构建完成后，应用包位于：`ios/build/Release-iphoneos/Runner.app`

### 方法 3: 手动使用 xcodebuild 命令

```bash
cd ios

# 获取 Flutter 依赖
cd ..
flutter clean
flutter pub get
cd ios

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

构建完成后，应用包位于：`ios/build/Release-iphoneos/Runner.app`

## 创建 .ipa 文件（可选）

如果需要创建 .ipa 文件：

```bash
cd ios/build/Release-iphoneos
mkdir -p Payload
cp -r Runner.app Payload/
zip -r ../../fufuDiningRoom-unsigned.ipa Payload
rm -rf Payload
```

生成的 .ipa 文件位于：`ios/build/fufuDiningRoom-unsigned.ipa`

## 注意事项

1. **未签名的应用包无法直接在 iOS 设备上安装**，除非：
   - 使用越狱设备
   - 通过 Xcode 直接安装到连接的设备
   - 使用企业证书或开发证书签名

2. **如果需要签名**，请修改 `project.pbxproj` 中的：
   - `CODE_SIGN_IDENTITY` 为你的证书名称（如 "iPhone Developer"）
   - `DEVELOPMENT_TEAM` 为你的团队 ID

3. **最低 iOS 版本**：当前设置为 iOS 13.0

4. **Bundle Identifier**：`com.strin.fufuDiningRoom`

5. **前提条件**：
   - 需要安装 Xcode（从 App Store 下载）
   - 需要安装 Xcode Command Line Tools：
     ```bash
     xcode-select --install
     ```

## 常见问题

### 1. 找不到 Runner.xcworkspace

确保已运行过 `flutter pub get`，这会生成必要的文件。

### 2. 构建失败：找不到 Pods

如果使用 CocoaPods，需要先安装依赖：

```bash
cd ios
pod install
```

### 3. 签名错误

如果 Xcode 提示签名错误，可以：
- 在 Signing & Capabilities 中取消勾选 "Automatically manage signing"
- 或者使用命令行构建（会自动跳过签名）

### 4. 找不到 xcodebuild

确保已安装 Xcode Command Line Tools：
```bash
xcode-select --install
```

## 恢复签名配置

如果需要恢复自动签名，可以手动修改 `project.pbxproj`，将：
- `CODE_SIGN_STYLE = Manual` 改为 `CODE_SIGN_STYLE = Automatic`
- 移除 `CODE_SIGN_IDENTITY` 和 `DEVELOPMENT_TEAM` 行
