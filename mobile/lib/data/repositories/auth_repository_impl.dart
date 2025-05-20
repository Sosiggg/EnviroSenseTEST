// import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:dio/dio.dart';
import 'dart:convert';

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

          // Safely handle the response data
          Map<String, dynamic> responseMap;

          if (response is Map<String, dynamic>) {
            // Response is already a Map
            responseMap = response;
          } else if (response is String) {
            try {
              // Try to parse the string as JSON
              responseMap = json.decode(response) as Map<String, dynamic>;
            } catch (e) {
              // If parsing fails, create a simple map with the string as a message
              responseMap = {'error': true, 'message': 'Incorrect password'};
            }
          } else if (response == null) {
            // Handle null response
            responseMap = {'error': true, 'message': 'Incorrect password'};
          } else {
            // Handle other types
            responseMap = {'error': true, 'message': 'Incorrect password'};
          }

          // Check for specific error status codes that indicate authentication issues
          if (dioResponse.statusCode == 401) {
            AppLogger.w('Authentication failed: Invalid credentials');
            return {
              'error': true,
              'message': 'Incorrect password',
              'code': 'INVALID_CREDENTIALS',
            };
          }

          // Check for access token in the processed response
          if (responseMap.containsKey('access_token') &&
              responseMap['access_token'] != null) {
            try {
              final token = responseMap['access_token'].toString();
              await saveToken(token);
              AppLogger.i('Token saved successfully');
              return responseMap;
            } catch (e) {
              AppLogger.e('Error saving token: $e', e);
              return {
                'error': true,
                'message': 'Incorrect password',
                'code': 'INVALID_CREDENTIALS',
              };
            }
          } else {
            // For any error during login, simplify the message to "Incorrect password"
            AppLogger.w('Login failed: ${dioResponse.statusMessage}');
            return {
              'error': true,
              'message': 'Incorrect password',
              'code': 'INVALID_CREDENTIALS',
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

      // All retries failed or auth error - simplify the error message
      return {
        'error': true,
        'message': 'Incorrect password',
        'code': 'INVALID_CREDENTIALS',
      };
    } catch (e) {
      // Handle other errors with a simplified message
      AppLogger.e('Unexpected error during login: $e', e);
      return {
        'error': true,
        'message': 'Incorrect password',
        'code': 'INVALID_CREDENTIALS',
      };
    }
  }

  @override
  Future<Map<String, dynamic>> forgotPassword({required String email}) async {
    try {
      AppLogger.i('Requesting password reset for email: $email');

      final data = {'email': email};

      final response = await _apiClient.post(
        ApiConstants.forgotPassword,
        data: data,
      );

      AppLogger.d('Forgot password response: $response');

      // Check if the response contains HTML (which would indicate an error)
      if (response.containsKey('message')) {
        final message = response['message'];
        if (message is String &&
            (message.contains('<html') || message.contains('<!DOCTYPE'))) {
          // This is an HTML response, extract a more user-friendly message
          AppLogger.w('Received HTML response from forgot password endpoint');
          return {
            'error': true,
            'message':
                'Password reset request sent. Please check your email for instructions.',
            'raw_response': message,
          };
        }
      }

      return response;
    } catch (e) {
      AppLogger.e('Error in forgotPassword: $e', e);
      return {
        'error': true,
        'message': 'Failed to send password reset request: ${e.toString()}',
      };
    }
  }

  @override
  Future<Map<String, dynamic>> resetPassword({
    required String token,
    required String newPassword,
    required String email,
  }) async {
    try {
      AppLogger.i('Resetting password for email: $email with token');

      final data = {
        'token': token,
        'new_password': newPassword,
        'email': email,
      };

      final response = await _apiClient.post(
        ApiConstants.resetPassword,
        data: data,
      );

      AppLogger.d('Reset password response: $response');

      // Check if the response contains HTML (which would indicate an error)
      if (response.containsKey('message')) {
        final message = response['message'];
        if (message is String &&
            (message.contains('<html') || message.contains('<!DOCTYPE'))) {
          // This is an HTML response, extract a more user-friendly message
          AppLogger.w('Received HTML response from reset password endpoint');
          return {
            'error': true,
            'message':
                'Password reset successful. Please login with your new password.',
            'raw_response': message,
          };
        }
      }

      return response;
    } catch (e) {
      AppLogger.e('Error in resetPassword: $e', e);
      return {
        'error': true,
        'message': 'Failed to reset password: ${e.toString()}',
      };
    }
  }

  @override
  Future<Map<String, dynamic>> getUserProfile() async {
    try {
      AppLogger.i('Getting user profile');

      // Get the current token to identify the user
      final token = await getToken();
      if (token == null) {
        AppLogger.w('No token available when getting user profile');
        return {'error': true, 'message': 'Not authenticated'};
      }

      // Add retry logic for transient errors
      int retryCount = 0;
      const maxRetries = 2;
      Exception? lastException;

      while (retryCount <= maxRetries) {
        try {
          // Make the API request to get the latest profile data
          final response = await _apiClient.get(ApiConstants.userProfile);

          // If we get here, the request succeeded
          if (retryCount > 0) {
            AppLogger.i('Profile fetch succeeded after $retryCount retries');
          }

          // Log the response for debugging
          AppLogger.d('User profile response: $response');

          // Check if the response indicates an error
          if (response.containsKey('error') && response['error'] == true) {
            AppLogger.w('Error in user profile response: ${response['message']}');
            return response;
          }

          // Validate that the response contains expected user data
          if (!response.containsKey('id') && !response.containsKey('username')) {
            AppLogger.w('Response missing required user data fields: $response');

            // Check if the response contains a detail field (common in FastAPI errors)
            if (response.containsKey('detail')) {
              return {
                'error': true,
                'message': 'Authentication error: ${response['detail']}. Please log out and log in again.'
              };
            }

            // Check if the response contains a message field
            if (response.containsKey('message')) {
              return {
                'error': true,
                'message': 'Authentication error: ${response['message']}. Please log out and log in again.'
              };
            }

            // If we have a status code, include it in the error message
            if (response.containsKey('statusCode')) {
              return {
                'error': true,
                'message': 'Server returned status ${response['statusCode']}. Please log out and log in again.'
              };
            }

            // Default error message with more helpful instructions
            return {
              'error': true,
              'message': 'Unable to load your profile. Please log out and log in again to refresh your session.'
            };
          }

          // Ensure ID is properly handled
          if (response.containsKey('id') && response['id'] is String) {
            // Convert string ID to int if possible
            try {
              final idInt = int.parse(response['id']);
              response['id'] = idInt;
            } catch (e) {
              AppLogger.w('Could not parse user ID as integer: ${response['id']}');
              // Keep the string ID, the User.fromJson will handle it
            }
          }

          // Cache the profile data with the token as part of the key
          try {
            final prefs = await SharedPreferences.getInstance();
            final tokenFirstPart = token.split('.').first; // Use part of the token as an identifier
            await prefs.setString(
              'user_profile_$tokenFirstPart',
              jsonEncode(response),
            );
            AppLogger.d('User profile cached successfully');
          } catch (cacheError) {
            AppLogger.w('Error caching user profile: $cacheError');
            // Continue even if caching fails
          }

          return response;

        } on ApiException catch (e) {
          lastException = e;

          // Only retry on server errors or timeouts, not on auth errors
          if (e is ServerException || e is TimeoutException) {
            retryCount++;
            if (retryCount <= maxRetries) {
              AppLogger.w('Retrying profile fetch (attempt $retryCount) after error: ${e.message}');
              await Future.delayed(Duration(milliseconds: 500 * retryCount));
              continue;
            }
          } else {
            // Don't retry for auth errors or other client errors
            AppLogger.e('Non-retryable API error during profile fetch: ${e.message}', e);
            rethrow;
          }
        } catch (e) {
          lastException = e is Exception ? e : Exception(e.toString());

          // Retry for other errors too
          retryCount++;
          if (retryCount <= maxRetries) {
            AppLogger.w('Retrying profile fetch (attempt $retryCount) after error: $e');
            await Future.delayed(Duration(milliseconds: 500 * retryCount));
            continue;
          }
        }
      }

      // If we get here, all retries failed
      if (lastException != null) {
        throw lastException;
      }

      // Fallback response if all retries failed but no exception was thrown
      return {
        'error': true,
        'message': 'Failed to fetch profile after $maxRetries retries'
      };
    } catch (e) {
      AppLogger.e('Error getting user profile: $e', e);
      return {'error': true, 'message': 'Failed to get user profile: $e'};
    }
  }

      // Log the response for debugging
      AppLogger.d('User profile response: $response');

      // Check if the response indicates an error
      if (response.containsKey('error') && response['error'] == true) {
        AppLogger.w('Error in user profile response: ${response['message']}');
        return response;
      }

      // Validate that the response contains expected user data
      if (!response.containsKey('id') && !response.containsKey('username')) {
        AppLogger.w('Response missing required user data fields: $response');

        // Check if the response contains a detail field (common in FastAPI errors)
        if (response.containsKey('detail')) {
          return {
            'error': true,
            'message':
                'Authentication error: ${response['detail']}. Please log out and log in again.',
          };
        }

        // Check if the response contains a message field
        if (response.containsKey('message')) {
          return {
            'error': true,
            'message':
                'Authentication error: ${response['message']}. Please log out and log in again.',
          };
        }

        // If we have a status code, include it in the error message
        if (response.containsKey('statusCode')) {
          return {
            'error': true,
            'message':
                'Server returned status ${response['statusCode']}. Please log out and log in again.',
          };
        }

        // Default error message with more helpful instructions
        return {
          'error': true,
          'message':
              'Unable to load your profile. Please log out and log in again to refresh your session.',
        };
      }

      // Ensure ID is properly handled
      if (response.containsKey('id') && response['id'] is String) {
        // Convert string ID to int if possible
        try {
          final idInt = int.parse(response['id']);
          response['id'] = idInt;
        } catch (e) {
          AppLogger.w('Could not parse user ID as integer: ${response['id']}');
          // Keep the string ID, the User.fromJson will handle it
        }
      }

      // Cache the profile data with the token as part of the key
      try {
        final prefs = await SharedPreferences.getInstance();
        final tokenFirstPart =
            token.split('.').first; // Use part of the token as an identifier
        await prefs.setString(
          'user_profile_$tokenFirstPart',
          jsonEncode(response),
        );
        AppLogger.d('User profile cached successfully');
      } catch (cacheError) {
        AppLogger.w('Error caching user profile: $cacheError');
        // Continue even if caching fails
      }

      return response;
    } catch (e) {
      AppLogger.e('Error getting user profile: $e', e);
      return {'error': true, 'message': 'Failed to get user profile: $e'};
    }
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

      // Check for specific error patterns in the response
      if (response.containsKey('message') && response['message'] is String) {
        final message = response['message'] as String;

        // Check for "Internal Server Error"
        if (message.contains('Internal Server Error')) {
          AppLogger.w('Server error during password change: $message');
          return {
            'error': true,
            'message': 'The current password you entered is incorrect',
            'code': 'INVALID_CREDENTIALS',
            'original_error': message,
          };
        }

        // Check for other error messages that might indicate incorrect password
        if (message.toLowerCase().contains('incorrect') ||
            message.toLowerCase().contains('invalid') ||
            message.toLowerCase().contains('wrong') ||
            message.toLowerCase().contains('password')) {
          AppLogger.w('Password validation error: $message');
          return {
            'error': true,
            'message': 'The current password you entered is incorrect',
            'code': 'INVALID_CREDENTIALS',
            'original_error': message,
          };
        }
      }

      // Check for status code in the response
      if (response.containsKey('statusCode') && response['statusCode'] == 500) {
        AppLogger.w('Server error (500) during password change');
        return {
          'error': true,
          'message': 'The current password you entered is incorrect',
          'code': 'INVALID_CREDENTIALS',
          'original_status': response['statusCode'],
        };
      }

      return response;
    } on ApiException catch (e) {
      AppLogger.e('API error during password change: ${e.message}', e);

      // Provide a user-friendly message for common errors
      if (e is ServerException || e.message.contains('500')) {
        return {
          'error': true,
          'message': 'The current password you entered is incorrect',
          'code': 'INVALID_CREDENTIALS',
          'original_error': e.message,
        };
      }

      return {'error': true, 'message': 'The current password you entered is incorrect'};
    } catch (e) {
      AppLogger.e('Unexpected error during password change: $e', e);
      return {'error': true, 'message': 'The current password you entered is incorrect'};
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

    // Also clear the token in the API client
    await _apiClient.clearToken();
  }

  @override
  Future<void> clearUserCache() async {
    try {
      // Get the current token to identify user-specific cache entries
      final token = await getToken();
      final prefs = await SharedPreferences.getInstance();

      if (token != null) {
        // Clear user-specific cache entries
        final tokenFirstPart = token.split('.').first;
        await prefs.remove('user_profile_$tokenFirstPart');
        AppLogger.i('User-specific cache cleared for token: $tokenFirstPart');
      }

      // Clear any other user-related cache entries
      // Get all keys and remove those that start with 'user_profile_'
      final keys = prefs.getKeys();
      for (final key in keys) {
        if (key.startsWith('user_profile_')) {
          await prefs.remove(key);
          AppLogger.d('Removed cached data for key: $key');
        }
      }

      // Log the cache clearing
      AppLogger.i('All user cache cleared successfully');
    } catch (e) {
      AppLogger.e('Error clearing user cache: $e', e);
      // Continue even if there's an error
    }
  }
}
