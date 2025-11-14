# 使用 Xcode 构建未签名 iOS 应用包

## 前提条件

1. 已安装 Xcode（从 App Store 下载）
2. 已安装 Xcode Command Line Tools：
   ```bash
   xcode-select --install
   ```

## 方法 1: 使用 Xcode GUI（最简单）

### 步骤

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

4. **配置签名（如果需要）**
   - 点击左侧导航栏的 **Runner** 项目
   - 选择 **Runner** target
   - 打开 **Signing & Capabilities** 标签
   - 取消勾选 **Automatically manage signing**
   - 如果显示签名错误，可以忽略（因为我们构建未签名版本）

5. **构建**
   - 选择菜单：**Product > Build**（或按 `Cmd+B`）
   - 等待构建完成

6. **查找构建产物**
   - 构建完成后，在 Xcode 左侧导航栏展开 **Products**
   - 右键点击 **Runner.app**
   - 选择 **Show in Finder**
   - 或者手动查找：`~/Library/Developer/Xcode/DerivedData/Runner-*/Build/Products/Release-iphoneos/Runner.app`

## 方法 2: 使用命令行（xcodebuild）

### 快速构建

```bash
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

### 构建产物位置

构建完成后，应用包位于：
```
ios/build/Release-iphoneos/Runner.app
```

## 创建 .ipa 文件

如果需要创建 .ipa 文件：

```bash
cd ios/build/Release-iphoneos
mkdir -p Payload
cp -r Runner.app Payload/
zip -r ../../fufuDiningRoom-unsigned.ipa Payload
rm -rf Payload
```

生成的 .ipa 文件位于：`ios/build/fufuDiningRoom-unsigned.ipa`

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

