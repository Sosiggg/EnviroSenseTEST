@echo off
echo Setting up environment for Flutter Windows build...

:: Change to the project directory
cd /d "%~dp0"

:: Clean the build directory
echo Cleaning previous build...
call flutter clean

:: Get dependencies
echo Getting dependencies...
call flutter pub get

:: Enable Windows desktop support
echo Enabling Windows desktop support...
call flutter config --enable-windows-desktop

:: Build and run the Windows app
echo Building and running Windows app...
call flutter run -d windows --verbose

pause
