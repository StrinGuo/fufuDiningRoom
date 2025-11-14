# 福福厨房

用于福福和小兔日常点菜的小程序。

## 项目简介

福福厨房是一个专为福福和小兔设计的点菜小程序，方便日常点餐使用。

## 技术栈

- **框架**: Flutter
- **后端**: Supabase
- **语言**: Dart

## 功能特性

- 日常点菜功能
- 订单管理
- 管理员功能

## 开发环境要求

- Flutter SDK: ^3.9.2
- Dart SDK: ^3.9.2

## 快速开始

### 1. 安装依赖

```bash
flutter pub get
```

### 2. 生成应用图标（可选）

```bash
flutter pub run flutter_launcher_icons
```

### 3. 运行项目

```bash
# Android
flutter run

# iOS
flutter run

# Web
flutter run -d chrome
```

## 项目结构

```
lib/
├── app/              # 应用入口
├── core/             # 核心功能（路由、主题、工具类）
├── data/             # 数据层（数据源、模型、仓库）
├── domain/           # 业务逻辑层（实体、仓库接口、用例）
└── features/         # 功能模块
    ├── admin/        # 管理员功能
    └── orders/       # 订单功能
```

## 构建说明

### Android

```bash
flutter build apk --release
```

### iOS

```bash
flutter build ipa --release
```

### Web

```bash
flutter build web --release
```

## 许可证

私有项目
