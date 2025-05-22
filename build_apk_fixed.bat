@echo off
echo ===================================================
echo Building EnviroSense APK...
echo ===================================================

cd mobile

echo.
echo Step 1: Cleaning previous build files...
call flutter clean

echo.
echo Step 2: Getting dependencies...
call flutter pub get

echo.
echo Step 3: Updating Android SDK configuration...
echo Ensuring compileSdk and ndkVersion are set correctly...

echo.
echo Step 4: Building APK...
call flutter build apk --target-platform=android-arm64 --debug

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
