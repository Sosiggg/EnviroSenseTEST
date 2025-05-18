# How to Fix Windows Build Error for Flutter Secure Storage

The error you're seeing:
```
Cannot open include file: 'atlstr.h': No such file or directory
```

This is related to the `flutter_secure_storage_windows` plugin which requires the Windows SDK ATL (Active Template Library) components.

## Solution:

1. **Install Visual Studio with C++ Desktop Development Workload**:
   - Download Visual Studio 2022 Community Edition (free): https://visualstudio.microsoft.com/downloads/
   - During installation, select "Desktop development with C++"
   - Make sure to check the "Windows 10/11 SDK" and "C++ ATL for latest v143 build tools" options

2. **Alternative: Modify your existing Visual Studio installation**:
   - Open Visual Studio Installer
   - Select "Modify" on your existing installation
   - Check "Desktop development with C++"
   - Under "Installation details", make sure "C++ ATL for latest v143 build tools" is selected
   - Click "Modify" to update your installation

3. **Restart your computer** after installation to ensure all environment variables are updated

4. **Clean and rebuild your Flutter project**:
   ```
   flutter clean
   flutter pub get
   flutter run -d windows
   ```

## Temporary Workaround:

If you need a quick solution without installing Visual Studio components, you can temporarily remove the secure storage dependency:

1. Edit your `pubspec.yaml` file
2. Comment out or remove the `flutter_secure_storage` dependency
3. Run `flutter pub get`
4. Update your code to not use secure storage temporarily

This will allow you to build and test other parts of your application while you set up the proper development environment for Windows.

## For Future Reference:

When developing Flutter apps for Windows, make sure you have the following installed:
- Flutter SDK
- Visual Studio 2022 (Community Edition is fine)
- Desktop development with C++ workload
- Windows 10/11 SDK
- C++ ATL for latest build tools

These components are required for many native Windows plugins to compile properly.
