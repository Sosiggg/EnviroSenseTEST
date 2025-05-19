@echo off
echo Setting up environment for Flutter Web build...

:: Change to the project directory
cd /d "%~dp0"

:: Clean the build directory
echo Cleaning previous build...
call flutter clean

:: Get dependencies
echo Getting dependencies...
call flutter pub get

:: Enable web support
echo Enabling web support...
call flutter config --enable-web

:: Build and run the web app
echo Building and running web app...
call flutter run -d chrome

pause
