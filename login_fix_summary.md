# EnviroSense Mobile App Login Fix

We've made several changes to fix the login issue with the EnviroSense mobile app. Here's a summary of the changes:

## 1. Updated API URLs

Changed the API URLs from local development URLs to production URLs:

```dart
// In lib/core/constants/api_constants.dart

// Before
static const String baseUrl = 'http://10.0.2.2:8000/api/v1';
static const String wsUrl = 'ws://10.0.2.2:8000/api/v1/sensor/ws';

// After
static const String baseUrl = 'https://envirosense-2khv.onrender.com/api/v1';
static const String wsUrl = 'wss://envirosense-2khv.onrender.com/api/v1/sensor/ws';
```

## 2. Increased Connection Timeouts

Increased the connection and receive timeouts to handle potential slow responses from the production server:

```dart
// In lib/core/network/api_client.dart

// Before
connectTimeout: const Duration(seconds: 10),
receiveTimeout: const Duration(seconds: 10),

// After
connectTimeout: const Duration(seconds: 30),
receiveTimeout: const Duration(seconds: 30),
```

## 3. Fixed Login Form Data Format

Updated the login method to correctly send form data with the proper content type:

```dart
// In lib/data/repositories/auth_repository_impl.dart

// Before
final formData = 'username=$username&password=$password';
final response = await _apiClient.post(ApiConstants.login, data: formData);

// After
final dio = Dio(BaseOptions(
  baseUrl: ApiConstants.baseUrl,
  connectTimeout: const Duration(seconds: 30),
  receiveTimeout: const Duration(seconds: 30),
  headers: {
    'Content-Type': 'application/x-www-form-urlencoded',
    'Accept': 'application/json',
  },
));

final formData = {'username': username, 'password': password};

final dioResponse = await dio.post(
  ApiConstants.login,
  data: formData,
  options: Options(contentType: 'application/x-www-form-urlencoded'),
);
```

## 4. Temporarily Replaced Secure Storage

To fix Windows build issues, we temporarily replaced flutter_secure_storage with SharedPreferences:

```dart
// In pubspec.yaml
# Commented out
# flutter_secure_storage: ^9.0.0

// In code files
// Before
final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
await _secureStorage.write(key: 'token', value: token);
final token = await _secureStorage.read(key: 'token');

// After
final prefs = await SharedPreferences.getInstance();
await prefs.setString('token', token);
final token = prefs.getString('token');
```

## Next Steps

1. Try logging in with the updated code
2. If login is successful, you should be able to access the dashboard and see sensor data
3. For a permanent fix, install Visual Studio with C++ Desktop Development Workload to support flutter_secure_storage on Windows

## Troubleshooting

If you still encounter issues:

1. Check the Render.com logs to ensure the backend is running correctly
2. Verify that your user account exists on the production server
3. Try creating a new account through the app
4. Check network connectivity to ensure you can reach the production server
