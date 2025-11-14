@echo off
REM 设置 JAVA_HOME 环境变量为 Android Studio 的 JDK
set JAVA_HOME=C:\Program Files\Android\Android Studio\jbr
set PATH=%JAVA_HOME%\bin;%PATH%

echo JAVA_HOME 已设置为: %JAVA_HOME%
echo.
echo 现在可以运行 Gradle 命令了：
echo   gradlew clean
echo   gradlew build
echo.

REM 保持命令行窗口打开
cmd /k


