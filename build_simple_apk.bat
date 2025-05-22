@echo off
echo ===================================================
echo Building Simple EnviroSense APK...
echo ===================================================

cd mobile

echo.
echo Step 1: Cleaning previous build files...
call flutter clean

echo.
echo Step 2: Getting dependencies...
call flutter pub get

echo.
echo Step 3: Building APK with flutter run...
call flutter build apk --debug --target-platform=android-arm64

echo.
if %ERRORLEVEL% EQU 0 (
    echo ===================================================
    echo APK build completed successfully!
    echo The APK file is located at: 
    echo mobile\build\app\outputs\flutter-apk\app-debug.apk
    echo ===================================================
) else (
    echo ===================================================
    echo APK build failed with error code: %ERRORLEVEL%
    echo Please check the error messages above.
    echo ===================================================
)

pause
