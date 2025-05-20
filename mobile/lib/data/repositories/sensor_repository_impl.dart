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
      if (response is List<dynamic>) {
        AppLogger.i('Found direct list format, using it directly');
        final result = <Map<String, dynamic>>[];
        for (final dynamic item in response) {
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
      if (response is List<dynamic>) {
        AppLogger.i('Found direct list format, using it directly');
        final result = <Map<String, dynamic>>[];
        for (final dynamic item in response) {
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

    // Try to get the token with multiple attempts
    String? token;
    for (int attempt = 1; attempt <= 3; attempt++) {
      final prefs = await SharedPreferences.getInstance();
      token = prefs.getString('token');

      if (token != null) {
        break;
      }

      // If token is still null, wait and try again
      if (attempt < 3) {
        AppLogger.w(
          'Token not found on attempt $attempt, waiting before retry...',
        );
        await Future.delayed(Duration(milliseconds: 500 * attempt));
      }
    }

    if (token == null) {
      throw Exception('No token available after multiple attempts');
    }

    final wsUrl = '${ApiConstants.wsUrl}?token=$token';
    AppLogger.i('Connecting to WebSocket: $wsUrl');

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
              data = jsonDecode(message) as Map<String, dynamic>;
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

      // Check if token is available before scheduling reconnection
      bool tokenAvailable = false;
      try {
        final prefs = await SharedPreferences.getInstance();
        final token = prefs.getString('token');
        tokenAvailable = token != null;
      } catch (e) {
        AppLogger.e('Error checking token availability: $e', e);
      }

      if (!tokenAvailable) {
        AppLogger.w('Skipping reconnection attempt - no token available');
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
    // Cancel timers
    _reconnectTimer?.cancel();
    _reconnectTimer = null;

    _pingTimer?.cancel();
    _pingTimer = null;

    // Close WebSocket connection
    if (_channel != null) {
      await _channel!.sink.close();
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
}
