# 修改应用图标和名称指南

## 📋 准备工作

### 1. 准备应用图标

你需要准备一个 **1024x1024** 像素的 PNG 图标（透明背景，正方形）。

**图标要求：**
- 格式：PNG
- 尺寸：1024x1024 像素（最小）
- 背景：透明或纯色
- 内容：图标内容应该在安全区域内（避免被圆角裁剪）

**在线工具推荐：**
- [App Icon Generator](https://www.appicon.co/)
- [Icon Kitchen](https://icon.kitchen/)

## 🚀 方法 1: 使用 flutter_launcher_icons（推荐）

### 步骤 1: 添加依赖

在 `pubspec.yaml` 的 `dev_dependencies` 中添加：

```yaml
dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^5.0.0
  flutter_launcher_icons: ^0.13.1  # 添加这一行
```

### 步骤 2: 配置图标

在 `pubspec.yaml` 文件末尾添加：

```yaml
flutter_launcher_icons:
  android: true
  ios: true
  web:
    generate: true
    image_path: "assets/icon/app_icon.png"  # 你的图标路径
  image_path: "assets/icon/app_icon.png"   # 主图标路径
  adaptive_icon_background: "#FFFFFF"       # Android 自适应图标背景色
  adaptive_icon_foreground: "assets/icon/app_icon.png"  # Android 自适应图标前景
```

### 步骤 3: 创建图标目录并放置图标

```bash
# 创建目录
mkdir -p assets/icon

# 将你的 1024x1024 图标复制到 assets/icon/app_icon.png
```

### 步骤 4: 生成图标

```bash
flutter pub get
flutter pub run flutter_launcher_icons
```

## 📝 方法 2: 手动修改（如果不想用工具）

### Android 图标

1. **准备图标文件**（不同尺寸）：
   - `android/app/src/main/res/mipmap-mdpi/ic_launcher.png` (48x48)
   - `android/app/src/main/res/mipmap-hdpi/ic_launcher.png` (72x72)
   - `android/app/src/main/res/mipmap-xhdpi/ic_launcher.png` (96x96)
   - `android/app/src/main/res/mipmap-xxhdpi/ic_launcher.png` (144x144)
   - `android/app/src/main/res/mipmap-xxxhdpi/ic_launcher.png` (192x192)

2. **替换文件**：将对应尺寸的图标替换上述文件

### iOS 图标

1. **准备图标文件**（不同尺寸）
2. 在 Xcode 中打开 `ios/Runner.xcworkspace`
3. 在 `Assets.xcassets` → `AppIcon` 中替换图标

### Web 图标

替换 `web/icons/` 目录下的图标文件：
- `Icon-192.png` (192x192)
- `Icon-512.png` (512x512)
- `Icon-maskable-192.png` (192x192)
- `Icon-maskable-512.png` (512x512)

## ✏️ 修改应用名称

### Android 应用名称

修改 `android/app/src/main/AndroidManifest.xml`：

```xml
<application
    android:label="你的应用名称"  <!-- 修改这里 -->
    ...
>
```

### iOS 应用名称

修改 `ios/Runner/Info.plist`：

```xml
<key>CFBundleDisplayName</key>
<string>你的应用名称</string>  <!-- 修改这里 -->
```

### Web 应用名称

修改 `web/manifest.json`：

```json
{
    "name": "你的应用名称",
    "short_name": "你的应用名称",
    ...
}
```

修改 `web/index.html`：

```html
<title>你的应用名称</title>
<meta name="apple-mobile-web-app-title" content="你的应用名称">
```

## 📦 完整配置示例

查看 `pubspec.yaml` 中的完整配置示例。

## ✅ 验证

### Android
```bash
flutter build apk --debug
# 安装到设备后查看应用名称和图标
```

### iOS
```bash
flutter build ios
# 在 Xcode 中运行查看
```

### Web
```bash
flutter build web
# 在浏览器中查看
```

## 🎨 图标设计建议

1. **简洁明了**：图标应该在小尺寸下也能清晰识别
2. **避免文字**：图标中尽量不要包含文字
3. **品牌一致性**：使用与应用主题一致的颜色
4. **测试不同尺寸**：确保在所有尺寸下都清晰可见

## 🐛 常见问题

### 图标没有更新

1. **清理构建缓存**：
   ```bash
   flutter clean
   flutter pub get
   ```

2. **重新生成图标**：
   ```bash
   flutter pub run flutter_launcher_icons
   ```

3. **完全卸载应用后重新安装**

### Android 自适应图标

如果使用 `flutter_launcher_icons`，确保配置了 `adaptive_icon_foreground` 和 `adaptive_icon_background`。

### iOS 图标不显示

1. 确保图标尺寸正确
2. 在 Xcode 中清理构建：Product → Clean Build Folder
3. 删除应用后重新安装

