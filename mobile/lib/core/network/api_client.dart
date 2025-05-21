import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
// Temporarily using shared_preferences instead of flutter_secure_storage
// import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../constants/api_constants.dart';
import '../errors/api_exceptions.dart';

class ApiClient {
  late Dio _dio; // Removed 'final' to allow resetting
  // Temporarily using SharedPreferences instead of FlutterSecureStorage
  // final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

  ApiClient() {
    _initDio();
  }

  // Static variables for token caching that persist across Dio resets
  static String? _cachedToken;
  static DateTime _lastTokenRefresh = DateTime.now();

  // Initialize Dio with default settings
  void _initDio() {
    // Create a new Dio instance with default settings
    _dio = Dio(
      BaseOptions(
        baseUrl: ApiConstants.baseUrl,
        connectTimeout: const Duration(
          seconds: 60,
        ), // Increased timeout for production server
        receiveTimeout: const Duration(
          seconds: 60,
        ), // Increased timeout for production server
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        // Accept any status code to handle errors in code
        validateStatus: (status) => true,
      ),
    );

    // Add logging interceptor in debug mode
    if (kDebugMode) {
      _dio.interceptors.add(
        LogInterceptor(requestBody: true, responseBody: true, error: true),
      );
    }

    // Add interceptors
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          try {
            // Check if we need to refresh the cached token (every 5 minutes)
            final now = DateTime.now();
            final shouldRefreshToken =
                _cachedToken == null ||
                now.difference(_lastTokenRefresh).inMinutes >= 5;

            if (shouldRefreshToken) {
              final prefs = await SharedPreferences.getInstance();
              _cachedToken = prefs.getString('token');
              _lastTokenRefresh = now;

              if (_cachedToken != null) {
                if (kDebugMode) {
                  print('Token refreshed from SharedPreferences');
                }
              }
            }

            // Add token to request if available
            if (_cachedToken != null) {
              options.headers['Authorization'] = 'Bearer $_cachedToken';
            }

            return handler.next(options);
          } catch (e) {
            if (kDebugMode) {
              print('Error in token interceptor: $e');
            }
            // Continue with the request even if there's an error getting the token
            return handler.next(options);
          }
        },
        onError: (DioException error, handler) async {
          // Handle token expiration
          if (error.response?.statusCode == 401) {
            // Token expired, clear it
            try {
              final prefs = await SharedPreferences.getInstance();
              await prefs.remove('token');
              _cachedToken = null; // Clear the cached token too
              if (kDebugMode) {
                print('Token cleared due to 401 error');
              }
            } catch (e) {
              if (kDebugMode) {
                print('Error clearing token: $e');
              }
            }
          }
          return handler.next(error);
        },
      ),
    );
  }

  // GET request
  Future<Map<String, dynamic>> get(
    String path, {
    Map<String, dynamic>? queryParameters,
  }) async {
    try {
      final response = await _dio.get(path, queryParameters: queryParameters);

      // Handle different response types
      if (response.data is Map<String, dynamic>) {
        return response.data;
      } else if (response.data is String) {
        try {
          // Try to parse string as JSON
          return jsonDecode(response.data);
        } catch (e) {
          // If it's not valid JSON, return as a message
          return {'message': response.data, 'statusCode': response.statusCode};
        }
      } else if (response.data == null) {
        return {
          'message': 'No data returned',
          'statusCode': response.statusCode,
        };
      } else {
        // For any other type, convert to string and return as message
        return {
          'message': response.data.toString(),
          'statusCode': response.statusCode,
        };
      }
    } on DioException catch (e) {
      throw _handleError(e);
    } on SocketException {
      throw const NetworkException('No internet connection');
    } catch (e) {
      throw UnknownException(e.toString());
    }
  }

  // POST request
  Future<Map<String, dynamic>> post(String path, {dynamic data}) async {
    try {
      final response = await _dio.post(
        path,
        data: data is String ? data : jsonEncode(data),
      );

      // Log the response for debugging
      if (kDebugMode) {
        print('POST response status: ${response.statusCode}');
        print('POST response data: ${response.data}');
      }

      // Check for error status codes
      if (response.statusCode != null && response.statusCode! >= 400) {
        // Handle error responses
        if (response.data is Map<String, dynamic>) {
          final errorData = response.data as Map<String, dynamic>;

          // Add status code to the response
          errorData['statusCode'] = response.statusCode;

          // Check for FastAPI style error response
          if (errorData.containsKey('detail')) {
            return {
              'error': true,
              'message': errorData['detail'],
              'detail': errorData['detail'],
              'statusCode': response.statusCode,
            };
          }

          return errorData;
        } else {
          return {
            'error': true,
            'message': 'Error ${response.statusCode}',
            'statusCode': response.statusCode,
          };
        }
      }

      // Handle different response types
      if (response.data is Map<String, dynamic>) {
        // Add status code to the response
        final responseData = response.data as Map<String, dynamic>;
        responseData['statusCode'] = response.statusCode;
        return responseData;
      } else if (response.data is String) {
        try {
          // Try to parse string as JSON
          final jsonData = jsonDecode(response.data);
          if (jsonData is Map<String, dynamic>) {
            jsonData['statusCode'] = response.statusCode;
            return jsonData;
          } else {
            return {
              'message': response.data,
              'statusCode': response.statusCode,
            };
          }
        } catch (e) {
          // If it's not valid JSON, return as a message
          return {'message': response.data, 'statusCode': response.statusCode};
        }
      } else if (response.data == null) {
        return {
          'message': 'No data returned',
          'statusCode': response.statusCode,
        };
      } else {
        // For any other type, convert to string and return as message
        return {
          'message': response.data.toString(),
          'statusCode': response.statusCode,
        };
      }
    } on DioException catch (e) {
      // Log the error for debugging
      if (kDebugMode) {
        print('DioException in POST request: ${e.message}');
        print('DioException response: ${e.response?.data}');
        print('DioException status code: ${e.response?.statusCode}');
      }

      throw _handleError(e);
    } on SocketException {
      throw const NetworkException('No internet connection');
    } catch (e) {
      if (kDebugMode) {
        print('Unknown exception in POST request: $e');
      }
      throw UnknownException(e.toString());
    }
  }

  // PUT request
  Future<Map<String, dynamic>> put(String path, {dynamic data}) async {
    try {
      final response = await _dio.put(
        path,
        data: data is String ? data : jsonEncode(data),
      );

      // Handle different response types
      if (response.data is Map<String, dynamic>) {
        return response.data;
      } else if (response.data is String) {
        try {
          // Try to parse string as JSON
          return jsonDecode(response.data);
        } catch (e) {
          // If it's not valid JSON, return as a message
          return {'message': response.data, 'statusCode': response.statusCode};
        }
      } else if (response.data == null) {
        return {
          'message': 'No data returned',
          'statusCode': response.statusCode,
        };
      } else {
        // For any other type, convert to string and return as message
        return {
          'message': response.data.toString(),
          'statusCode': response.statusCode,
        };
      }
    } on DioException catch (e) {
      throw _handleError(e);
    } on SocketException {
      throw const NetworkException('No internet connection');
    } catch (e) {
      throw UnknownException(e.toString());
    }
  }

  // DELETE request
  Future<Map<String, dynamic>> delete(String path) async {
    try {
      final response = await _dio.delete(path);

      // Handle different response types
      if (response.data is Map<String, dynamic>) {
        return response.data;
      } else if (response.data is String) {
        try {
          // Try to parse string as JSON
          return jsonDecode(response.data);
        } catch (e) {
          // If it's not valid JSON, return as a message
          return {'message': response.data, 'statusCode': response.statusCode};
        }
      } else if (response.data == null) {
        return {
          'message': 'No data returned',
          'statusCode': response.statusCode,
        };
      } else {
        // For any other type, convert to string and return as message
        return {
          'message': response.data.toString(),
          'statusCode': response.statusCode,
        };
      }
    } on DioException catch (e) {
      throw _handleError(e);
    } on SocketException {
      throw const NetworkException('No internet connection');
    } catch (e) {
      throw UnknownException(e.toString());
    }
  }

  // Handle Dio errors
  Exception _handleError(DioException error) {
    // Log detailed error information in debug mode
    if (kDebugMode) {
      print('DioException type: ${error.type}');
      print('DioException message: ${error.message}');
      print('DioException response status: ${error.response?.statusCode}');
      print('DioException response data: ${error.response?.data}');
    }

    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return const TimeoutException('Connection timeout');
      case DioExceptionType.badResponse:
        final statusCode = error.response?.statusCode;
        final data = error.response?.data;

        if (statusCode == 401) {
          String message = 'Unauthorized';
          if (data != null && data is Map) {
            if (data.containsKey('detail')) {
              message = data['detail'];
            } else if (data.containsKey('message')) {
              message = data['message'];
            }
          }
          return UnauthorizedException(message);
        } else if (statusCode == 403) {
          String message = 'Forbidden';
          if (data != null && data is Map) {
            if (data.containsKey('detail')) {
              message = data['detail'];
            } else if (data.containsKey('message')) {
              message = data['message'];
            }
          }
          return ForbiddenException(message);
        } else if (statusCode == 404) {
          String message = 'Not found';
          if (data != null && data is Map) {
            if (data.containsKey('detail')) {
              message = data['detail'];
            } else if (data.containsKey('message')) {
              message = data['message'];
            }
          }
          return NotFoundException(message);
        } else if (statusCode == 400) {
          String message = 'Bad request';
          if (data != null && data is Map) {
            if (data.containsKey('detail')) {
              message = data['detail'];
            } else if (data.containsKey('message')) {
              message = data['message'];
            }
          }
          return BadRequestException(message);
        } else if (statusCode == 500) {
          String message = 'Server error';
          if (data != null && data is Map) {
            if (data.containsKey('detail')) {
              message = data['detail'];
            } else if (data.containsKey('message')) {
              message = data['message'];
            }
          }
          return ServerException(message);
        } else {
          // For any other status code, try to extract a meaningful message
          String message = 'API error: ${error.message}';
          if (data != null && data is Map) {
            if (data.containsKey('detail')) {
              message = data['detail'];
            } else if (data.containsKey('message')) {
              message = data['message'];
            }
          }
          return ApiException(message);
        }
      case DioExceptionType.cancel:
        return const RequestCancelledException('Request cancelled');
      case DioExceptionType.unknown:
      default:
        if (error.error is SocketException) {
          return const NetworkException('No internet connection');
        }
        return UnknownException(error.message ?? 'Unknown error');
    }
  }

  // Save token
  Future<void> saveToken(String token) async {
    // await _secureStorage.write(key: 'token', value: token);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('token', token);
  }

  // Get token
  Future<String?> getToken() async {
    // return await _secureStorage.read(key: 'token');
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  // Clear token
  Future<void> clearToken() async {
    // await _secureStorage.delete(key: 'token');
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');

    // Also clear any cached token in memory
    if (kDebugMode) {
      print('API Client: Clearing cached token');
    }

    // Reset the Dio instance to clear any cached headers
    try {
      // Clear all interceptors first
      _dio.interceptors.clear();

      // Reinitialize Dio with default settings
      _initDio();

      if (kDebugMode) {
        print('API Client: Dio instance reset successfully');
      }
    } catch (e) {
      // If there's an error resetting Dio, log it but don't throw
      if (kDebugMode) {
        print('API Client: Error resetting Dio instance: $e');
      }
    }
  }
}
