@echo off
echo Building EnviroSense APK...
cd mobile
flutter clean
flutter pub get
flutter build apk --release
echo APK build completed.
echo The APK file is located at: mobile\build\app\outputs\flutter-apk\app-release.apk
pause
