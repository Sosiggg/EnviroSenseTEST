import 'dart:async';
import 'dart:convert';
import 'dart:math' show min;

// import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import '../../core/constants/api_constants.dart';
import '../../core/network/api_client.dart';
import '../../core/utils/app_logger.dart';
import '../../domain/repositories/sensor_repository.dart';

class SensorRepositoryImpl implements SensorRepository {
  final ApiClient _apiClient = ApiClient();
  // final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

  WebSocketChannel? _channel;
  final StreamController<Map<String, dynamic>> _sensorDataController =
      StreamController<Map<String, dynamic>>.broadcast();

  @override
  Future<List<Map<String, dynamic>>> getSensorData() async {
    try {
      final response = await _apiClient.get(ApiConstants.sensorData);

      // Check if the response contains data in the expected format
      if (response.containsKey('data') && response['data'] is List) {
        // Convert the list to the expected format
        return List<Map<String, dynamic>>.from(response['data']);
      } else if (response.containsKey('message')) {
        // Log the message but return empty list
        AppLogger.w('API message: ${response['message']}');
        return [];
      }

      // If we get here, check if the response itself is a list
      if (response is List) {
        AppLogger.i('Found direct list format, using it directly');
        final result = <Map<String, dynamic>>[];

        // Cast to Iterable<dynamic> to avoid type errors
        final items = response as Iterable<dynamic>;

        for (final dynamic item in items) {
          if (item is Map<String, dynamic>) {
            result.add(item);
          } else if (item is Map) {
            // Convert to the right type
            result.add(Map<String, dynamic>.from(item));
          }
        }
        return result;
      }

      // If we get here, the response is not in the expected format
      AppLogger.w('Unexpected response format: $response');

      // As a last resort, try to wrap the response in a list if it looks like sensor data
      if (response.containsKey('temperature') &&
          response.containsKey('humidity') &&
          response.containsKey('id')) {
        AppLogger.i('Found single sensor data item, wrapping in list');
        return [Map<String, dynamic>.from(response)];
      }

      return [];
    } catch (e) {
      AppLogger.e('Error getting sensor data: $e', e);
      return [];
    }
  }

  @override
  Future<Map<String, dynamic>> getLatestSensorData() async {
    try {
      final response = await _apiClient.get(ApiConstants.latestSensorData);

      // Check if the response contains data in the expected format
      if (response.containsKey('data') && response['data'] is Map) {
        // Return the data directly
        return Map<String, dynamic>.from(response['data']);
      } else if (response.containsKey('message')) {
        // Log the message but return empty map
        AppLogger.w('API message: ${response['message']}');
        return {};
      }

      // If we get here, the response might be the direct sensor data (not wrapped in 'data')
      // Check if it has the expected sensor data fields
      if (response.containsKey('temperature') &&
          response.containsKey('humidity') &&
          response.containsKey('id')) {
        AppLogger.i('Found direct sensor data format, using it directly');
        return response;
      }

      // If we get here, the response is not in the expected format
      AppLogger.w('Unexpected response format: $response');
      return response; // Return the raw response as a fallback
    } catch (e) {
      AppLogger.e('Error getting latest sensor data: $e', e);
      return {};
    }
  }

  @override
  Future<List<Map<String, dynamic>>> getSensorDataByDateRange({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      final queryParameters = {
        'start_date': startDate.toIso8601String(),
        'end_date': endDate.toIso8601String(),
      };

      final response = await _apiClient.get(
        ApiConstants.sensorData,
        queryParameters: queryParameters,
      );

      // Check if the response contains data in the expected format
      if (response.containsKey('data') && response['data'] is List) {
        // Convert the list to the expected format
        return List<Map<String, dynamic>>.from(response['data']);
      } else if (response.containsKey('message')) {
        // Log the message but return empty list
        AppLogger.w('API message: ${response['message']}');
        return [];
      }

      // If we get here, check if the response itself is a list
      if (response is List) {
        AppLogger.i('Found direct list format, using it directly');
        final result = <Map<String, dynamic>>[];

        // Cast to Iterable<dynamic> to avoid type errors
        final items = response as Iterable<dynamic>;

        for (final dynamic item in items) {
          if (item is Map<String, dynamic>) {
            result.add(item);
          } else if (item is Map) {
            // Convert to the right type
            result.add(Map<String, dynamic>.from(item));
          }
        }
        return result;
      }

      // If we get here, the response is not in the expected format
      AppLogger.w('Unexpected response format: $response');

      // As a last resort, try to wrap the response in a list if it looks like sensor data
      if (response.containsKey('temperature') &&
          response.containsKey('humidity') &&
          response.containsKey('id')) {
        AppLogger.i('Found single sensor data item, wrapping in list');
        return [Map<String, dynamic>.from(response)];
      }

      return [];
    } catch (e) {
      AppLogger.e('Error getting sensor data by date range: $e', e);
      return [];
    }
  }

  @override
  Future<Map<String, dynamic>> getSensorDataByDatePaginated({
    required DateTime date,
    required int page,
    required int pageSize,
  }) async {
    try {
      // Create start and end date for the specified date (full day)
      final startDate = DateTime(date.year, date.month, date.day);
      final endDate = DateTime(
        date.year,
        date.month,
        date.day,
        23,
        59,
        59,
        999,
      );

      final queryParameters = {
        'start_date': startDate.toIso8601String(),
        'end_date': endDate.toIso8601String(),
        'page': page.toString(),
        'page_size': pageSize.toString(),
      };

      AppLogger.i(
        'Getting paginated sensor data for date: ${startDate.toIso8601String()} (page $page, size $pageSize)',
      );

      final response = await _apiClient.get(
        ApiConstants.sensorData,
        queryParameters: queryParameters,
      );

      // Check if the response has the expected structure with data and pagination
      if (response.containsKey('data')) {
        // Return the entire response which includes both data and pagination info
        AppLogger.i(
          'Received paginated response with ${response['data'].length} items',
        );

        // Make sure pagination info exists, create default if not
        if (!response.containsKey('pagination')) {
          AppLogger.w('Response missing pagination info, creating default');
          response['pagination'] = {
            'page': page,
            'page_size': pageSize,
            'total_count': response['data'].length,
            'total_pages': 1,
            'has_next': false,
            'has_prev': page > 1,
          };
        }

        return response;
      } else if (response.containsKey('message')) {
        // Log the message but return empty result with pagination structure
        AppLogger.w('API message: ${response['message']}');
        return {
          'data': [],
          'pagination': {
            'page': page,
            'page_size': pageSize,
            'total_count': 0,
            'total_pages': 0,
            'has_next': false,
            'has_prev': false,
          },
        };
      }

      // If we get here, check if the response itself is a list (old format)
      if (response is List) {
        AppLogger.i('Found direct list format, converting to paginated format');
        final dataList = <Map<String, dynamic>>[];

        // Cast to Iterable<dynamic> to avoid type errors
        final items = response as Iterable<dynamic>;

        for (final dynamic item in items) {
          if (item is Map<String, dynamic>) {
            dataList.add(item);
          } else if (item is Map) {
            // Convert to the right type
            dataList.add(Map<String, dynamic>.from(item));
          }
        }

        // Create a paginated response format
        return {
          'data': dataList,
          'pagination': {
            'page': page,
            'page_size': pageSize,
            'total_count': dataList.length,
            'total_pages': (dataList.length / pageSize).ceil(),
            'has_next': dataList.length >= pageSize,
            'has_prev': page > 1,
          },
        };
      }

      // If we get here, the response is not in the expected format
      AppLogger.w('Unexpected response format: $response');
      return {
        'data': [],
        'pagination': {
          'page': page,
          'page_size': pageSize,
          'total_count': 0,
          'total_pages': 0,
          'has_next': false,
          'has_prev': false,
        },
      };
    } catch (e) {
      AppLogger.e('Error getting paginated sensor data: $e', e);
      return {
        'data': [],
        'pagination': {
          'page': page,
          'page_size': pageSize,
          'total_count': 0,
          'total_pages': 0,
          'has_next': false,
          'has_prev': false,
        },
      };
    }
  }

  @override
  Future<Map<String, dynamic>> getSensorDataByDateRangePaginated({
    required DateTime startDate,
    required DateTime endDate,
    required int page,
    required int pageSize,
  }) async {
    try {
      final queryParameters = {
        'start_date': startDate.toIso8601String(),
        'end_date': endDate.toIso8601String(),
        'page': page.toString(),
        'page_size': pageSize.toString(),
      };

      AppLogger.i(
        'Getting paginated sensor data for date range: ${startDate.toIso8601String()} to ${endDate.toIso8601String()} (page $page, size $pageSize)',
      );

      // Use the direct endpoint path
      final response = await _apiClient.get(
        '/sensor/data',
        queryParameters: queryParameters,
      );

      // Check if the response has the expected structure with data and pagination
      if (response.containsKey('data')) {
        // Return the entire response which includes both data and pagination info
        AppLogger.i(
          'Received paginated response with ${response['data'].length} items',
        );

        // Make sure pagination info exists, create default if not
        if (!response.containsKey('pagination')) {
          AppLogger.w('Response missing pagination info, creating default');
          response['pagination'] = {
            'page': page,
            'page_size': pageSize,
            'total_count': response['data'].length,
            'total_pages': 1,
            'has_next': false,
            'has_prev': page > 1,
          };
        }

        return response;
      } else if (response.containsKey('message')) {
        // Log the message but return empty result with pagination structure
        AppLogger.w('API message: ${response['message']}');
        return {
          'data': [],
          'pagination': {
            'page': page,
            'page_size': pageSize,
            'total_count': 0,
            'total_pages': 0,
            'has_next': false,
            'has_prev': false,
          },
        };
      }

      // If we get here, check if the response itself is a list (old format)
      if (response is List) {
        AppLogger.i('Found direct list format, converting to paginated format');
        final dataList = <Map<String, dynamic>>[];

        // Cast to Iterable<dynamic> to avoid type errors
        final items = response as Iterable<dynamic>;

        AppLogger.d('Direct list format items: $items');

        for (final dynamic item in items) {
          try {
            if (item is Map<String, dynamic>) {
              dataList.add(item);
              AppLogger.d('Added item as Map<String, dynamic>: $item');
            } else if (item is Map) {
              // Convert to the right type
              final convertedItem = Map<String, dynamic>.from(item);
              dataList.add(convertedItem);
              AppLogger.d('Added converted item: $convertedItem');
            } else {
              AppLogger.w(
                'Skipping item with unexpected type: ${item.runtimeType}',
              );
            }
          } catch (e) {
            AppLogger.e('Error processing item: $e', e);
          }
        }

        AppLogger.i('Converted ${dataList.length} items to paginated format');

        // Create a paginated response format
        return {
          'data': dataList,
          'pagination': {
            'page': page,
            'page_size': pageSize,
            'total_count': dataList.length,
            'total_pages': (dataList.length / pageSize).ceil(),
            'has_next': dataList.length >= pageSize,
            'has_prev': page > 1,
          },
        };
      }

      // If we get here, the response is not in the expected format
      AppLogger.w('Unexpected response format: $response');
      return {
        'data': [],
        'pagination': {
          'page': page,
          'page_size': pageSize,
          'total_count': 0,
          'total_pages': 0,
          'has_next': false,
          'has_prev': false,
        },
      };
    } catch (e) {
      AppLogger.e('Error getting paginated sensor data by date range: $e', e);
      return {
        'data': [],
        'pagination': {
          'page': page,
          'page_size': pageSize,
          'total_count': 0,
          'total_pages': 0,
          'has_next': false,
          'has_prev': false,
        },
      };
    }
  }

  @override
  Future<Map<String, dynamic>> getSensorDataStatistics() async {
    try {
      final response = await _apiClient.get(ApiConstants.sensorDataStatistics);

      // Check if the response contains data in the expected format
      if (response.containsKey('data') && response['data'] is Map) {
        // Return the data directly
        return Map<String, dynamic>.from(response['data']);
      } else if (response.containsKey('message')) {
        // Log the message but return empty map
        AppLogger.w('API message: ${response['message']}');
        return {};
      }

      // If we get here, the response is not in the expected format
      AppLogger.w('Unexpected response format: $response');
      return response; // Return the raw response as a fallback
    } catch (e) {
      AppLogger.e('Error getting sensor data statistics: $e', e);
      return {};
    }
  }

  // Timer for reconnection attempts
  Timer? _reconnectTimer;

  @override
  Future<void> connectToWebSocket() async {
    if (_channel != null) {
      await disconnectFromWebSocket();
    }

    // Cancel any existing reconnect timer
    _reconnectTimer?.cancel();

    // Get the current user's email
    String? userEmail = await _getCurrentUserEmail();

    // Double-check that we have a valid email
    if (userEmail == null || userEmail.isEmpty) {
      AppLogger.e(
        'SensorRepository: No user email available for WebSocket connection',
      );

      // Try one more time with a delay
      await Future.delayed(const Duration(seconds: 1));
      userEmail = await _getCurrentUserEmail();

      if (userEmail == null || userEmail.isEmpty) {
        // Use the hardcoded email from the ESP32 sketch as a last resort
        userEmail = "ivi.salski.35@gmail.com";
        AppLogger.w('Using hardcoded email as last resort: $userEmail');
      }
    }

    // Validate email format as an extra safety check
    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(userEmail)) {
      AppLogger.e('SensorRepository: Invalid email format: $userEmail');

      // Use the hardcoded email from the ESP32 sketch as a fallback
      userEmail = "ivi.salski.35@gmail.com";
      AppLogger.w('Using hardcoded email due to invalid format: $userEmail');
    }

    // URL encode the email for the query parameter
    final encodedEmail = Uri.encodeComponent(userEmail);
    final wsUrl = '${ApiConstants.wsUrl}?email=$encodedEmail';

    AppLogger.i(
      'SensorRepository: Connecting to WebSocket with email: $userEmail',
    );
    AppLogger.i('SensorRepository: WebSocket URL: $wsUrl');

    try {
      _channel = WebSocketChannel.connect(Uri.parse(wsUrl));
      AppLogger.i('WebSocket connection established');

      _channel!.stream.listen(
        (dynamic message) {
          try {
            AppLogger.d('WebSocket message received: $message');

            // Parse the message
            Map<String, dynamic> data;
            if (message is String) {
              // Check if the message is empty
              if (message.isEmpty) {
                AppLogger.w('Empty message received from WebSocket, ignoring');
                return;
              }

              try {
                data = jsonDecode(message) as Map<String, dynamic>;
              } catch (e) {
                AppLogger.e('Failed to parse JSON message: $e', e);
                AppLogger.w('Invalid message content: "$message"');
                return;
              }
            } else if (message is Map) {
              data = Map<String, dynamic>.from(message);
            } else {
              // Unknown message type, ignore it
              AppLogger.w('Unknown message type: ${message.runtimeType}');
              return;
            }

            // Check if this is a status message or actual sensor data
            if (data.containsKey('status') && data.containsKey('message')) {
              AppLogger.d(
                'Status message: ${data['status']} - ${data['message']}',
              );
              // This is just a status message, not sensor data
              return;
            }

            // Check if this is a pong message
            if (data.containsKey('type') && data['type'] == 'pong') {
              AppLogger.d('Pong received');
              return;
            }

            AppLogger.d('Sensor data received: $data');
            // Add the data to the stream controller
            _sensorDataController.add(data);
          } catch (e) {
            // Log parsing errors
            AppLogger.e('Error parsing WebSocket message: $e', e);
          }
        },
        onError: (error) {
          // Handle WebSocket errors
          AppLogger.e('WebSocket error: $error', error);
          _handleDisconnection();
        },
        onDone: () {
          // Handle WebSocket closure
          AppLogger.w('WebSocket connection closed');
          _handleDisconnection();
        },
      );

      // Send a ping message to keep the connection alive
      _startPingTimer();
    } catch (e) {
      // Handle connection errors
      AppLogger.e('WebSocket connection error: $e', e);
      _channel = null;
      _handleDisconnection();
      rethrow;
    }
  }

  // Helper method to get the current user's email
  Future<String?> _getCurrentUserEmail() async {
    try {
      // First try to get it from SharedPreferences for faster access
      final prefs = await SharedPreferences.getInstance();
      final cachedUserData = prefs.getString('user_data');

      if (cachedUserData != null) {
        try {
          final userData = jsonDecode(cachedUserData) as Map<String, dynamic>;
          if (userData.containsKey('email') && userData['email'] != null) {
            final email = userData['email'] as String;
            AppLogger.i('Got user email from cache: $email');

            // Validate email format
            if (RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email)) {
              return email;
            } else {
              AppLogger.w('Cached email has invalid format: $email');
              // Continue to try other methods
            }
          }
        } catch (e) {
          AppLogger.w('Error parsing cached user data: $e');
          // Continue to try other methods
        }
      }

      // If cache fails, try to get the user profile from the API
      try {
        final userProfile = await _apiClient.get(ApiConstants.userProfile);
        AppLogger.d('User profile response: $userProfile');

        if (userProfile.containsKey('email') && userProfile['email'] != null) {
          final email = userProfile['email'] as String;
          AppLogger.i('Got user email from profile API: $email');

          // Save to cache for future use
          if (email.isNotEmpty) {
            try {
              // Create a minimal user data object if we don't have one
              Map<String, dynamic> userData = {'email': email};
              if (userProfile.containsKey('username')) {
                userData['username'] = userProfile['username'];
              }
              if (userProfile.containsKey('id')) {
                userData['id'] = userProfile['id'];
              }

              await prefs.setString('user_data', jsonEncode(userData));
              AppLogger.i('Saved user email to cache: $email');
            } catch (e) {
              AppLogger.w('Error saving email to cache: $e');
              // Continue anyway
            }
          }

          return email;
        }
      } catch (e) {
        AppLogger.w('Error getting user profile from API: $e');
        // Continue to try other methods
      }

      // As a last resort, try the hardcoded email from the ESP32 sketch
      // This is a fallback for testing purposes
      const fallbackEmail = "ivi.salski.35@gmail.com";
      AppLogger.w('Using fallback email: $fallbackEmail');
      return fallbackEmail;
    } catch (e) {
      AppLogger.e('Error getting user email: $e', e);

      // As a last resort, try the hardcoded email from the ESP32 sketch
      // This is a fallback for testing purposes
      const fallbackEmail = "ivi.salski.35@gmail.com";
      AppLogger.w('Using fallback email after error: $fallbackEmail');
      return fallbackEmail;
    }
  }

  // Handle WebSocket disconnection with automatic reconnect
  void _handleDisconnection() {
    _channel = null;

    // Try to reconnect after a delay with exponential backoff
    int reconnectAttempts = 0;

    void attemptReconnect() async {
      reconnectAttempts++;
      int delay = min(reconnectAttempts * 2, 30); // Max 30 seconds delay
      AppLogger.i(
        'Attempting to reconnect in $delay seconds (attempt $reconnectAttempts)',
      );

      // Check if user email is available before scheduling reconnection
      String? userEmail = await _getCurrentUserEmail();
      bool emailAvailable = userEmail != null && userEmail.isNotEmpty;

      if (!emailAvailable) {
        AppLogger.w('Skipping reconnection attempt - no user email available');
        // Try again after a longer delay
        if (reconnectAttempts < 10) {
          // Limit max attempts
          _reconnectTimer = Timer(
            Duration(seconds: delay * 2),
            attemptReconnect,
          );
        } else {
          AppLogger.e(
            'Giving up reconnection after $reconnectAttempts attempts',
          );
        }
        return;
      }

      AppLogger.i('User email available for reconnection: $userEmail');

      _reconnectTimer = Timer(Duration(seconds: delay), () async {
        try {
          AppLogger.i('Reconnecting to WebSocket...');
          await connectToWebSocket();
          // Reset attempts on successful connection
          reconnectAttempts = 0;
        } catch (e) {
          AppLogger.e('Reconnection failed: $e', e);
          // Try again with exponential backoff
          attemptReconnect();
        }
      });
    }

    // Start the reconnection process
    attemptReconnect();
  }

  // Timer for sending periodic pings to keep the connection alive
  Timer? _pingTimer;

  void _startPingTimer() {
    _pingTimer?.cancel();
    _pingTimer = Timer.periodic(const Duration(seconds: 15), (_) {
      if (_channel != null) {
        try {
          // Send a ping message to keep the connection alive
          AppLogger.d('Sending ping to keep connection alive');
          _channel!.sink.add(jsonEncode({'type': 'ping'}));
        } catch (e) {
          // Log ping errors
          AppLogger.e('Error sending ping: $e', e);
        }
      }
    });
  }

  @override
  Future<void> disconnectFromWebSocket() async {
    try {
      AppLogger.i('SensorRepository: Disconnecting WebSocket');

      // Cancel timers
      _reconnectTimer?.cancel();
      _reconnectTimer = null;

      _pingTimer?.cancel();
      _pingTimer = null;

      // Close WebSocket connection
      if (_channel != null) {
        await _channel!.sink.close();
        _channel = null;
        AppLogger.i('SensorRepository: WebSocket disconnected successfully');
      }

      // Clear any cached data in SharedPreferences
      try {
        final prefs = await SharedPreferences.getInstance();
        final keys = prefs.getKeys().toList();
        for (final key in keys) {
          if (key.contains('sensor_') ||
              key.contains('_data_cache') ||
              key.contains('_latest_')) {
            await prefs.remove(key);
            AppLogger.d('SensorRepository: Removed cached data for key: $key');
          }
        }
        AppLogger.i(
          'SensorRepository: Cleared all cached sensor data from SharedPreferences',
        );
      } catch (cacheError) {
        AppLogger.e(
          'SensorRepository: Error clearing cached sensor data: $cacheError',
          cacheError,
        );
        // Continue even if cache clearing fails
      }
    } catch (e) {
      AppLogger.e('SensorRepository: Error disconnecting WebSocket: $e', e);
      // Reset channel to null even if there was an error
      _channel = null;
    }
  }

  @override
  Stream<Map<String, dynamic>> getSensorDataStream() {
    return _sensorDataController.stream;
  }

  @override
  bool isWebSocketConnected() {
    return _channel != null;
  }

  @override
  Future<Map<String, dynamic>> checkSensorData() async {
    try {
      final response = await _apiClient.get(ApiConstants.checkSensorData);
      AppLogger.i('Sensor data check response: $response');
      return response;
    } catch (e) {
      AppLogger.e('Error checking sensor data: $e', e);
      return {
        'error': true,
        'message': 'Error checking sensor data',
        'has_data': false,
        'total_records': 0,
      };
    }
  }

  @override
  Future<void> clearAllSensorData() async {
    try {
      AppLogger.i('SensorRepository: Clearing all sensor data');

      // First disconnect WebSocket if connected
      if (isWebSocketConnected()) {
        await disconnectFromWebSocket();
      }

      // Clear any cached data in SharedPreferences
      try {
        final prefs = await SharedPreferences.getInstance();

        // First, explicitly clear known sensor data keys
        final knownKeys = [
          'sensor_data',
          'sensor_latest',
          'sensor_history',
          'sensor_statistics',
          'sensor_cache',
          'latest_sensor_data',
          'sensor_data_cache',
        ];

        for (final key in knownKeys) {
          await prefs.remove(key);
          AppLogger.d('SensorRepository: Removed known key: $key');
        }

        // Then clear any keys matching patterns
        final keys = prefs.getKeys().toList();
        for (final key in keys) {
          if (key.contains('sensor_') ||
              key.contains('_data_cache') ||
              key.contains('_latest_') ||
              key.contains('_history_') ||
              key.contains('temperature') ||
              key.contains('humidity') ||
              key.contains('obstacle')) {
            await prefs.remove(key);
            AppLogger.d('SensorRepository: Removed cached data for key: $key');
          }
        }

        AppLogger.i(
          'SensorRepository: Cleared all cached sensor data from SharedPreferences',
        );
      } catch (cacheError) {
        AppLogger.e(
          'SensorRepository: Error clearing cached sensor data: $cacheError',
          cacheError,
        );
        // Continue even if cache clearing fails
      }

      // Clear any in-memory data
      _sensorDataController.add({
        'clear': true,
        'message': 'All sensor data cleared',
        'timestamp': DateTime.now().toIso8601String(),
      });

      // Reset internal state
      try {
        // Cancel any existing timers
        _pingTimer?.cancel();
        _pingTimer = null;

        _reconnectTimer?.cancel();
        _reconnectTimer = null;
      } catch (e) {
        AppLogger.e('SensorRepository: Error resetting internal state: $e', e);
        // Continue even if resetting internal state fails
      }

      AppLogger.i('SensorRepository: All sensor data cleared successfully');
    } catch (e) {
      AppLogger.e('SensorRepository: Error clearing all sensor data: $e', e);
      rethrow;
    }
  }
}
