import 'dart:async';
import 'dart:io';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../errors/api_exceptions.dart';

/// Network utility class with retry logic and circuit breaker pattern
class NetworkUtils {
  // Circuit breaker state
  static bool _isCircuitOpen = false;
  static DateTime? _circuitResetTime;
  static int _failureCount = 0;
  static const int _failureThreshold = 5;
  static const Duration _resetTimeout = Duration(minutes: 1);

  /// Check if the device has internet connection
  static Future<bool> hasInternetConnection() async {
    try {
      final connectivityResult = await Connectivity().checkConnectivity();
      // Check if we have no connectivity
      if (connectivityResult == ConnectivityResult.none) {
        return false;
      }

      // Additional check by trying to reach a reliable host
      try {
        final result = await InternetAddress.lookup('google.com');
        return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
      } on SocketException catch (_) {
        return false;
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error checking internet connection: $e');
      }
      return false;
    }
  }

  /// Check if the circuit breaker is open (preventing requests)
  static bool isCircuitBreakerOpen() {
    // If circuit is open, check if it's time to reset
    if (_isCircuitOpen && _circuitResetTime != null) {
      if (DateTime.now().isAfter(_circuitResetTime!)) {
        // Reset the circuit breaker
        _isCircuitOpen = false;
        _failureCount = 0;
        _circuitResetTime = null;
        if (kDebugMode) {
          print('Circuit breaker reset after timeout');
        }
      }
    }
    return _isCircuitOpen;
  }

  /// Record a failure and potentially open the circuit breaker
  static void recordFailure() {
    _failureCount++;
    if (kDebugMode) {
      print('Circuit breaker: Failure count: $_failureCount');
    }

    if (_failureCount >= _failureThreshold) {
      _isCircuitOpen = true;
      _circuitResetTime = DateTime.now().add(_resetTimeout);
      if (kDebugMode) {
        print('Circuit breaker opened due to too many failures');
        print('Circuit will reset at: $_circuitResetTime');
      }
    }
  }

  /// Reset the circuit breaker
  static void resetCircuitBreaker() {
    _isCircuitOpen = false;
    _failureCount = 0;
    _circuitResetTime = null;
    if (kDebugMode) {
      print('Circuit breaker manually reset');
    }
  }

  /// Execute a function with retry logic and circuit breaker
  static Future<T> executeWithRetry<T>({
    required Future<T> Function() function,
    int maxRetries = 3,
    Duration retryDelay = const Duration(seconds: 1),
    bool useExponentialBackoff = true,
  }) async {
    // Check circuit breaker first
    if (isCircuitBreakerOpen()) {
      throw const CircuitBreakerException(
        'Circuit breaker is open. Too many failures recently.',
      );
    }

    // Check internet connection
    final hasInternet = await hasInternetConnection();
    if (!hasInternet) {
      throw const NetworkException('No internet connection');
    }

    int retryCount = 0;
    Exception? lastException;

    while (retryCount <= maxRetries) {
      try {
        // Execute the function
        final result = await function();

        // If successful, reset failure count (partial reset for circuit breaker)
        if (_failureCount > 0) {
          _failureCount = Math.max(0, _failureCount - 1);
        }

        return result;
      } on DioException catch (e) {
        lastException = _handleDioError(e);

        // Don't retry for certain error types
        if (e.type == DioExceptionType.badResponse) {
          final statusCode = e.response?.statusCode;
          // Don't retry for client errors (except 429 Too Many Requests)
          if (statusCode != null &&
              statusCode >= 400 &&
              statusCode < 500 &&
              statusCode != 429) {
            throw lastException;
          }
        }
      } on SocketException catch (e) {
        lastException = NetworkException(e.message);
      } catch (e) {
        lastException = UnknownException(e.toString());
      }

      // Increment retry count
      retryCount++;

      // If we've reached max retries, record failure and throw
      if (retryCount > maxRetries) {
        recordFailure();
        // Since lastException is guaranteed to be non-null at this point
        throw lastException;
      }

      // Wait before retrying with exponential backoff if enabled
      final delay =
          useExponentialBackoff
              ? Duration(
                milliseconds: retryDelay.inMilliseconds * (1 << retryCount),
              )
              : retryDelay;

      if (kDebugMode) {
        print(
          'Retrying request ($retryCount/$maxRetries) after ${delay.inMilliseconds}ms',
        );
      }

      await Future.delayed(delay);
    }

    // This should never be reached, but just in case
    throw UnknownException('Unknown error during retry');
  }

  /// Handle Dio errors
  static Exception _handleDioError(DioException error) {
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
          return const UnauthorizedException('Unauthorized');
        } else if (statusCode == 403) {
          return const ForbiddenException('Forbidden');
        } else if (statusCode == 404) {
          return const NotFoundException('Resource not found');
        } else if (statusCode == 429) {
          return const TooManyRequestsException('Too many requests');
        } else if (statusCode != null && statusCode >= 500) {
          String message = 'Server error: $statusCode';
          if (data != null && data is Map && data.containsKey('detail')) {
            message = data['detail'];
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
}

/// Circuit breaker exception
class CircuitBreakerException implements Exception {
  final String message;
  const CircuitBreakerException(this.message);

  @override
  String toString() => 'CircuitBreakerException: $message';
}

/// Math utility class for min/max operations
class Math {
  static int max(int a, int b) => a > b ? a : b;
  static int min(int a, int b) => a < b ? a : b;
}
