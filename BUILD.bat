@echo off
echo ========================================
echo Building Serbisyo PH APK
echo ========================================
echo.

cd /d C:\Users\rossk\OneDrive\Desktop\serbisyo_ph

set JAVA_HOME=C:\Program Files\Java\jdk-21
set ANDROID_HOME=C:\android-sdk
set ANDROID_SDK_ROOT=C:\android-sdk
set JAVA_OPTS=-Djdk.module.illegalAccess=permit

echo Building APK...
flutter build apk --debug

echo.
echo ========================================
echo Done!
echo APK location: build\app\outputs\flutter-apk\app-debug.apk
echo ========================================
pause
