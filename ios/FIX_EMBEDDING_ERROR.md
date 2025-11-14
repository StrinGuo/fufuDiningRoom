# 修复 "Unresolved reference 'embedding'" 错误

## 问题说明

这个错误通常出现在 Xcode 中，表示无法找到 Flutter 框架。我已经在 `project.pbxproj` 中添加了 `FRAMEWORK_SEARCH_PATHS` 配置。

## 解决方法

### 方法 1: 在 Xcode 中清理并重新构建

1. 打开 `ios/Runner.xcworkspace`
2. 选择菜单：**Product > Clean Build Folder**（或按 `Shift+Cmd+K`）
3. 关闭 Xcode
4. 运行以下命令：
   ```bash
   cd ios
   flutter clean
   flutter pub get
   ```
5. 重新打开 Xcode：`open ios/Runner.xcworkspace`
6. 等待 Xcode 完成索引
7. 选择 **Product > Build**（或按 `Cmd+B`）

### 方法 2: 重新生成 iOS 项目文件

如果方法 1 不起作用，可以尝试重新生成 iOS 项目：

```bash
# 备份当前的 iOS 配置（可选）
cp -r ios ios_backup

# 删除 iOS 目录
rm -rf ios

# 重新创建 iOS 项目
flutter create --platforms=ios .

# 恢复自定义配置
# （需要手动恢复 Info.plist、图标等自定义内容）
```

### 方法 3: 检查 Flutter 环境

确保 Flutter 环境正确配置：

```bash
flutter doctor
flutter doctor -v
```

确保：
- Flutter SDK 已正确安装
- Xcode 已正确安装
- CocoaPods 已安装（如果需要）

### 方法 4: 在 Xcode 中手动添加框架搜索路径

如果上述方法都不行，可以在 Xcode 中手动添加：

1. 打开 `ios/Runner.xcworkspace`
2. 选择左侧导航栏的 **Runner** 项目
3. 选择 **Runner** target
4. 打开 **Build Settings** 标签
5. 搜索 **Framework Search Paths**
6. 添加：`$(PROJECT_DIR)/Flutter`
7. 确保设置为 **recursive**（递归搜索）

## 已修复的配置

我已经在 `project.pbxproj` 中为 Debug、Release 和 Profile 配置添加了：

```
FRAMEWORK_SEARCH_PATHS = (
    "$(inherited)",
    "$(PROJECT_DIR)/Flutter",
);
```

这应该能解决 Flutter 框架路径的问题。

## 如果问题仍然存在

如果问题仍然存在，可能是以下原因：

1. **Flutter 框架未正确生成**：运行 `flutter pub get` 和 `flutter clean`
2. **Xcode 缓存问题**：删除 DerivedData：
   ```bash
   rm -rf ~/Library/Developer/Xcode/DerivedData
   ```
3. **项目文件损坏**：尝试重新创建 iOS 项目（见方法 2）

