# 快速设置应用图标和名称

## ✅ 已完成的配置

我已经为你配置好了：
- ✅ Android 应用名称：`福福餐厅`
- ✅ iOS 应用名称：`福福餐厅`
- ✅ Web 应用名称：`福福餐厅`
- ✅ 添加了 `flutter_launcher_icons` 包配置

## 🎨 现在你需要做的

### 步骤 1: 准备图标

准备一个 **1024x1024** 像素的 PNG 图标文件。

**图标要求：**
- 格式：PNG
- 尺寸：1024x1024 像素（正方形）
- 背景：透明或纯色
- 文件名：`app_icon.png`

### 步骤 2: 放置图标文件

```bash
# 创建目录（如果不存在）
mkdir -p assets/icon

# 将你的图标文件复制到 assets/icon/app_icon.png
# 在 Windows 上，可以直接在文件管理器中创建文件夹并复制文件
```

**目录结构应该是：**
```
项目根目录/
  ├── assets/
  │   └── icon/
  │       └── app_icon.png  ← 你的图标文件
  ├── pubspec.yaml
  └── ...
```

### 步骤 3: 生成图标

在项目根目录执行：

```bash
# 1. 获取依赖
flutter pub get

# 2. 生成所有平台的图标
flutter pub run flutter_launcher_icons
```

### 步骤 4: 验证

**Android:**
```bash
flutter build apk --debug
# 安装到设备后查看图标和名称
```

**Web:**
```bash
flutter build web
# 在浏览器中查看
```

## 📝 修改应用名称

如果你想修改应用名称，编辑以下文件：

1. **Android**: `android/app/src/main/AndroidManifest.xml`
   ```xml
   android:label="你的应用名称"
   ```

2. **iOS**: `ios/Runner/Info.plist`
   ```xml
   <key>CFBundleDisplayName</key>
   <string>你的应用名称</string>
   ```

3. **Web**: 
   - `web/manifest.json` 中的 `name` 和 `short_name`
   - `web/index.html` 中的 `<title>` 和 `apple-mobile-web-app-title`

## 🎨 图标设计建议

1. **简洁明了**：图标应该在小尺寸下也能清晰识别
2. **避免文字**：图标中尽量不要包含文字（应用名称会显示在图标下方）
3. **品牌一致性**：使用与应用主题一致的颜色
4. **安全区域**：重要内容放在中心区域，避免被圆角裁剪

## 🐛 常见问题

### 图标没有更新

1. **清理构建缓存**：
   ```bash
   flutter clean
   flutter pub get
   flutter pub run flutter_launcher_icons
   ```

2. **完全卸载应用后重新安装**（Android/iOS）

3. **清除浏览器缓存**（Web）

### 找不到图标文件

确保图标文件路径正确：
- 文件路径：`assets/icon/app_icon.png`
- 文件存在且可读
- 文件大小合理（不要太大）

### Android 自适应图标

如果需要 Android 自适应图标（Android 8.0+），取消注释 `pubspec.yaml` 中的：
```yaml
adaptive_icon_background: "#FFFFFF"
adaptive_icon_foreground: "assets/icon/app_icon.png"
```

## 📚 更多信息

查看 `CHANGE_APP_ICON_NAME.md` 获取详细说明。

