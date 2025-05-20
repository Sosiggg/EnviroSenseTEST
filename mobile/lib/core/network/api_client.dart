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
  late final Dio _dio;
  // Temporarily using SharedPreferences instead of FlutterSecureStorage
  // final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

  ApiClient() {
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

    // Cache the token to avoid frequent SharedPreferences access
    String? cachedToken;
    DateTime lastTokenRefresh = DateTime.now();

    // Add interceptors
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          try {
            // Check if we need to refresh the cached token (every 5 minutes)
            final now = DateTime.now();
            final shouldRefreshToken =
                cachedToken == null ||
                now.difference(lastTokenRefresh).inMinutes >= 5;

            if (shouldRefreshToken) {
              final prefs = await SharedPreferences.getInstance();
              cachedToken = prefs.getString('token');
              lastTokenRefresh = now;

              if (cachedToken != null) {
                if (kDebugMode) {
                  print('Token refreshed from SharedPreferences');
                }
              }
            }

            // Add token to request if available
            if (cachedToken != null) {
              options.headers['Authorization'] = 'Bearer $cachedToken';
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
              cachedToken = null; // Clear the cached token too
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

    // Add logging interceptor in debug mode
    if (kDebugMode) {
      _dio.interceptors.add(
        LogInterceptor(requestBody: true, responseBody: true),
      );
    }
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
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return const TimeoutException('Connection timeout');
      case DioExceptionType.badResponse:
        final statusCode = error.response?.statusCode;
        final data = error.response?.data;

        if (statusCode == 401) {
          return const UnauthorizedException('Unauthorized');
        } else if (statusCode == 403) {
          return const ForbiddenException('Forbidden');
        } else if (statusCode == 404) {
          return const NotFoundException('Not found');
        } else if (statusCode == 400) {
          String message = 'Bad request';
          if (data != null && data is Map && data.containsKey('detail')) {
            message = data['detail'];
          }
          return BadRequestException(message);
        } else if (statusCode == 500) {
          return const ServerException('Server error');
        } else {
          return ApiException('API error: ${error.message}');
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
    _dio = Dio(
      BaseOptions(
        baseUrl: ApiConstants.baseUrl,
        connectTimeout: const Duration(seconds: 60),
        receiveTimeout: const Duration(seconds: 60),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        validateStatus: (status) => true,
      ),
    );

    // Re-add logging interceptor in debug mode
    if (kDebugMode) {
      _dio.interceptors.add(
        LogInterceptor(requestBody: true, responseBody: true),
      );
    }
  }
}
