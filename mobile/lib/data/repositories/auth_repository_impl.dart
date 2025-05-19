// import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:dio/dio.dart';
import 'package:jwt_decoder/jwt_decoder.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/constants/api_constants.dart';
import '../../core/errors/api_exceptions.dart';
import '../../core/network/api_client.dart';
import '../../core/utils/app_logger.dart';
import '../../domain/repositories/auth_repository.dart';

class AuthRepositoryImpl implements AuthRepository {
  final ApiClient _apiClient = ApiClient();
  // final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

  @override
  Future<Map<String, dynamic>> register({
    required String username,
    required String email,
    required String password,
  }) async {
    final data = {'username': username, 'email': email, 'password': password};

    final response = await _apiClient.post(ApiConstants.register, data: data);
    return response;
  }

  @override
  Future<Map<String, dynamic>> login({
    required String username,
    required String password,
  }) async {
    // Create a custom Dio instance for form data
    final dio = Dio(
      BaseOptions(
        baseUrl: ApiConstants.baseUrl,
        connectTimeout: const Duration(seconds: 60), // Increased timeout
        receiveTimeout: const Duration(seconds: 60), // Increased timeout
        headers: {
          'Content-Type': 'application/x-www-form-urlencoded',
          'Accept': 'application/json',
        },
        // Disable certificate verification for development
        validateStatus: (status) => true, // Accept any status code
      ),
    );

    // Add logging interceptor
    dio.interceptors.add(
      LogInterceptor(requestBody: true, responseBody: true, error: true),
    );

    // The API expects form data for login
    final formData = {'username': username, 'password': password};

    try {
      // Try direct URL first (not using baseUrl)
      final fullUrl = '${ApiConstants.baseUrl}${ApiConstants.login}';
      AppLogger.i('Attempting to connect to: $fullUrl');

      // Connect to login endpoint with retry logic
      int retryCount = 0;
      const maxRetries = 3;
      DioException? lastError;

      while (retryCount < maxRetries) {
        try {
          AppLogger.i('Login attempt ${retryCount + 1}');

          final dioResponse = await dio.post(
            fullUrl, // Use full URL instead of relative path
            data: formData,
            options: Options(
              contentType: 'application/x-www-form-urlencoded',
              followRedirects: true,
              validateStatus: (status) => true, // Accept any status code
              receiveTimeout: const Duration(seconds: 30),
              sendTimeout: const Duration(seconds: 30),
            ),
          );

          // Process response
          final response = dioResponse.data;
          AppLogger.i('Login response status: ${dioResponse.statusCode}');

          // Ensure response is a Map<String, dynamic>
          Map<String, dynamic> responseMap;
          if (response is Map) {
            // Convert to Map<String, dynamic> to ensure type safety
            responseMap = Map<String, dynamic>.from(response);
          } else {
            AppLogger.w('Response is not a Map: $response');
            return {
              'error': true,
              'message': 'Invalid response format from server',
            };
          }

          if (responseMap.containsKey('access_token')) {
            await saveToken(responseMap['access_token']);
            AppLogger.i('Token saved successfully');
            return responseMap;
          } else {
            AppLogger.w('Login failed: ${dioResponse.statusMessage}');
            return {
              'error': true,
              'message': 'Login failed: ${dioResponse.statusMessage}',
            };
          }
        } on DioException catch (e) {
          lastError = e;
          AppLogger.e(
            'Login attempt ${retryCount + 1} failed: ${e.type} - ${e.message}',
            e,
          );

          // Only retry on connection errors, not on auth errors
          if (e.type != DioExceptionType.badResponse) {
            retryCount++;
            if (retryCount < maxRetries) {
              // Wait before retrying with exponential backoff
              await Future.delayed(Duration(seconds: 2 * retryCount));
              continue;
            }
          } else {
            // Don't retry for auth errors (400, 401, etc.)
            break;
          }
        }
      }

      // All retries failed or auth error
      if (lastError != null) {
        if (lastError.response != null) {
          return {
            'error': true,
            'message':
                'Server error: ${lastError.response?.statusCode} - ${lastError.response?.statusMessage}',
            'details': lastError.response?.data,
          };
        } else {
          return {
            'error': true,
            'message':
                'Connection error: ${lastError.type} - ${lastError.message}',
          };
        }
      }

      return {'error': true, 'message': 'Login failed after multiple attempts'};
    } catch (e) {
      // Handle other errors
      AppLogger.e('Unexpected error during login: $e', e);
      return {'error': true, 'message': 'Unexpected error: ${e.toString()}'};
    }
  }

  @override
  Future<Map<String, dynamic>> forgotPassword({required String email}) async {
    final data = {'email': email};

    final response = await _apiClient.post(
      ApiConstants.forgotPassword,
      data: data,
    );
    return response;
  }

  @override
  Future<Map<String, dynamic>> resetPassword({
    required String token,
    required String newPassword,
  }) async {
    final data = {'token': token, 'new_password': newPassword};

    final response = await _apiClient.post(
      ApiConstants.resetPassword,
      data: data,
    );
    return response;
  }

  @override
  Future<Map<String, dynamic>> getUserProfile() async {
    final response = await _apiClient.get(ApiConstants.userProfile);
    return response;
  }

  @override
  Future<Map<String, dynamic>> updateUserProfile({
    String? username,
    String? email,
  }) async {
    try {
      AppLogger.i('Updating user profile: username=$username, email=$email');

      final data = {
        if (username != null && username.isNotEmpty) 'username': username,
        if (email != null && email.isNotEmpty) 'email': email,
      };

      if (data.isEmpty) {
        AppLogger.w('No data provided for profile update');
        return {'error': true, 'message': 'No data provided for update'};
      }

      final response = await _apiClient.put(
        ApiConstants.userProfile,
        data: data,
      );
      AppLogger.i('Profile update response: $response');
      return response;
    } on ApiException catch (e) {
      AppLogger.e('API error during profile update: ${e.message}', e);
      return {'error': true, 'message': e.message};
    } catch (e) {
      AppLogger.e('Unexpected error during profile update: $e', e);
      return {'error': true, 'message': 'Unexpected error: ${e.toString()}'};
    }
  }

  @override
  Future<Map<String, dynamic>> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      AppLogger.i('Changing password');

      if (currentPassword.isEmpty || newPassword.isEmpty) {
        AppLogger.w('Current or new password is empty');
        return {
          'error': true,
          'message': 'Current or new password cannot be empty',
        };
      }

      final data = {
        'current_password': currentPassword,
        'new_password': newPassword,
      };

      final response = await _apiClient.post(
        ApiConstants.changePassword,
        data: data,
      );

      AppLogger.i('Password change response: $response');
      return response;
    } on ApiException catch (e) {
      AppLogger.e('API error during password change: ${e.message}', e);
      return {'error': true, 'message': e.message};
    } catch (e) {
      AppLogger.e('Unexpected error during password change: $e', e);
      return {'error': true, 'message': 'Unexpected error: ${e.toString()}'};
    }
  }

  @override
  Future<bool> isLoggedIn() async {
    final token = await getToken();
    if (token == null) {
      return false;
    }

    try {
      // Check if token is expired
      final isExpired = JwtDecoder.isExpired(token);
      return !isExpired;
    } catch (e) {
      // Invalid token
      await clearToken();
      return false;
    }
  }

  @override
  Future<String?> getToken() async {
    // return await _secureStorage.read(key: 'token');
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  @override
  Future<void> saveToken(String token) async {
    // await _secureStorage.write(key: 'token', value: token);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('token', token);
  }

  @override
  Future<void> clearToken() async {
    // await _secureStorage.delete(key: 'token');
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
  }
}
