#!/bin/bash

# 构建未签名的 iOS 应用包脚本
# 使用方法: ./build_unsigned.sh
# 注意：此脚本使用 xcodebuild 命令，需要先安装 Xcode

echo "开始构建未签名的 iOS 应用包..."

# 进入 iOS 目录
cd "$(dirname "$0")"

# 清理之前的构建
echo "清理之前的构建..."
rm -rf build
rm -rf ~/Library/Developer/Xcode/DerivedData/Runner-*

# 获取 Flutter 依赖
echo "获取 Flutter 依赖..."
cd ..
flutter clean
flutter pub get
cd ios

# 使用 xcodebuild 构建未签名版本
echo "开始构建..."
xcodebuild -workspace Runner.xcworkspace \
           -scheme Runner \
           -configuration Release \
           -destination 'generic/platform=iOS' \
           CODE_SIGN_IDENTITY="" \
           CODE_SIGNING_REQUIRED=NO \
           CODE_SIGNING_ALLOWED=NO \
           build

if [ $? -eq 0 ]; then
    echo ""
    echo "构建完成！"
    echo "应用包位置: build/Release-iphoneos/Runner.app"
    echo ""
    echo "如果需要创建 .ipa 文件，可以使用以下命令："
    echo "cd build/Release-iphoneos"
    echo "mkdir -p Payload"
    echo "cp -r Runner.app Payload/"
    echo "zip -r ../../fufuDiningRoom-unsigned.ipa Payload"
    echo "rm -rf Payload"
else
    echo ""
    echo "构建失败！请检查错误信息。"
    echo "如果 xcodebuild 命令不可用，请使用 Xcode 手动构建："
    echo "1. 打开 ios/Runner.xcworkspace"
    echo "2. 选择 Product > Build"
fi

