import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../errors/api_exceptions.dart';
import '../network/network_utils.dart';

/// Centralized error handling utility
class ErrorHandler {
  /// Get a user-friendly error message from an exception
  static String getUserFriendlyMessage(Exception error) {
    if (error is UnauthorizedException) {
      return 'Your session has expired. Please log in again.';
    } else if (error is ForbiddenException) {
      return 'You don\'t have permission to access this resource.';
    } else if (error is NotFoundException) {
      return 'The requested resource was not found.';
    } else if (error is BadRequestException) {
      return 'Invalid request. Please check your input and try again.';
    } else if (error is ServerException) {
      return 'Server error. Please try again later.';
    } else if (error is TimeoutException) {
      return 'Connection timed out. Please check your internet connection and try again.';
    } else if (error is NetworkException) {
      return 'No internet connection. Please check your network settings and try again.';
    } else if (error is CircuitBreakerException) {
      return 'Too many failed requests. Please try again later.';
    } else if (error is RequestCancelledException) {
      return 'Request was cancelled.';
    } else if (error is ApiException) {
      return error.message;
    } else {
      return 'An unexpected error occurred. Please try again.';
    }
  }

  /// Get a detailed error message for logging
  static String getDetailedErrorMessage(dynamic error) {
    if (error is DioException) {
      return _handleDioError(error);
    } else if (error is SocketException) {
      return 'SocketException: ${error.message}';
    } else if (error is Exception) {
      return 'Exception: ${error.toString()}';
    } else {
      return 'Unknown error: ${error.toString()}';
    }
  }

  /// Handle Dio errors and return detailed message
  static String _handleDioError(DioException error) {
    final buffer = StringBuffer('DioException: ');
    buffer.write('Type: ${error.type}, ');
    buffer.write('Message: ${error.message}, ');
    
    if (error.response != null) {
      buffer.write('Status: ${error.response?.statusCode}, ');
      
      if (error.response?.data != null) {
        if (error.response?.data is Map) {
          final data = error.response?.data as Map;
          if (data.containsKey('detail')) {
            buffer.write('Detail: ${data['detail']}');
          } else if (data.containsKey('message')) {
            buffer.write('Detail: ${data['message']}');
          } else {
            buffer.write('Data: ${error.response?.data}');
          }
        } else {
          buffer.write('Data: ${error.response?.data}');
        }
      }
    }
    
    return buffer.toString();
  }

  /// Show a snackbar with an error message
  static void showErrorSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 4),
        action: SnackBarAction(
          label: 'Dismiss',
          textColor: Colors.white,
          onPressed: () {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
          },
        ),
      ),
    );
  }

  /// Show a dialog with an error message
  static Future<void> showErrorDialog(
    BuildContext context, {
    required String title,
    required String message,
    String? buttonText,
  }) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title),
          content: SingleChildScrollView(
            child: Text(message),
          ),
          actions: <Widget>[
            TextButton(
              child: Text(buttonText ?? 'OK'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  /// Log an error with detailed information
  static void logError(dynamic error, [StackTrace? stackTrace]) {
    if (kDebugMode) {
      print('ERROR: ${getDetailedErrorMessage(error)}');
      if (stackTrace != null) {
        print('STACK TRACE: $stackTrace');
      }
    }
    
    // Here you could add integration with a logging service like Firebase Crashlytics
    // or Sentry for production error tracking
  }

  /// Handle an error with appropriate UI feedback
  static void handleError(
    BuildContext context,
    dynamic error, {
    String? fallbackMessage,
    bool showSnackBar = true,
    bool showDialog = false,
    String? dialogTitle,
    VoidCallback? onRetry,
  }) {
    // Log the error
    logError(error);
    
    // Get user-friendly message
    String message;
    if (error is Exception) {
      message = getUserFriendlyMessage(error);
    } else {
      message = fallbackMessage ?? 'An unexpected error occurred. Please try again.';
    }
    
    // Show UI feedback
    if (showSnackBar) {
      showErrorSnackBar(context, message);
    }
    
    if (showDialog) {
      showErrorDialog(
        context,
        title: dialogTitle ?? 'Error',
        message: message,
        buttonText: onRetry != null ? 'Retry' : 'OK',
      ).then((_) {
        if (onRetry != null) {
          onRetry();
        }
      });
    }
  }
}
