import '../../core/utils/app_logger.dart';

class SensorData {
  final int id;
  final double temperature;
  final double humidity;
  final bool obstacle;
  final DateTime timestamp;
  final int userId;

  SensorData({
    required this.id,
    required this.temperature,
    required this.humidity,
    required this.obstacle,
    required this.timestamp,
    required this.userId,
  });

  factory SensorData.fromJson(Map<String, dynamic> json) {
    // Log the raw JSON for debugging
    AppLogger.d('SensorData.fromJson raw data: $json');

    // IMPORTANT: This is the exact format from the ESP32 sketch:
    // {
    //   "temperature": 30.5,
    //   "humidity": 65.2,
    //   "obstacle": false
    // }

    // For history data from API, the format might be different with additional fields

    // Handle timestamp - use current time for ESP32 data or parse from API
    DateTime timestamp;
    try {
      if (json.containsKey('timestamp') && json['timestamp'] != null) {
        timestamp = DateTime.parse(json['timestamp']);
      } else if (json.containsKey('created_at') && json['created_at'] != null) {
        timestamp = DateTime.parse(json['created_at']);
      } else {
        // This is likely live data from ESP32, use current time
        timestamp = DateTime.now();
      }
    } catch (e) {
      AppLogger.e('Error parsing timestamp: $e', e);
      timestamp = DateTime.now();
    }

    // Handle obstacle field - directly from ESP32 or from API
    bool obstacleValue = false;
    if (json.containsKey('obstacle')) {
      final obstacle = json['obstacle'];
      if (obstacle is bool) {
        obstacleValue = obstacle;
      } else if (obstacle is String) {
        obstacleValue = obstacle.toLowerCase() == 'true' || obstacle == '1';
      } else if (obstacle is num) {
        obstacleValue = obstacle != 0;
      }
    }

    // For user_id, use default for ESP32 data or parse from API
    int userIdValue = 1; // Default to 1 for ESP32 data
    if (json.containsKey('user_id') && json['user_id'] != null) {
      userIdValue =
          json['user_id'] is int
              ? json['user_id']
              : int.tryParse(json['user_id'].toString()) ?? 1;
    }

    // For id, use default for ESP32 data or parse from API
    int idValue = 0; // Default to 0 for ESP32 data
    if (json.containsKey('id') && json['id'] != null) {
      idValue =
          json['id'] is int
              ? json['id']
              : int.tryParse(json['id'].toString()) ?? 0;
    }

    // Parse temperature and humidity - these are always required
    double tempValue = _parseDouble(json['temperature']);
    double humValue = _parseDouble(json['humidity']);

    // Log the parsed values
    AppLogger.d(
      'Parsed values: id=$idValue, temp=$tempValue, '
      'humidity=$humValue, obstacle=$obstacleValue, '
      'timestamp=$timestamp, userId=$userIdValue',
    );

    return SensorData(
      id: idValue,
      temperature: tempValue,
      humidity: humValue,
      obstacle: obstacleValue,
      timestamp: timestamp,
      userId: userIdValue,
    );
  }

  // Helper method to safely parse doubles
  static double _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is int) return value.toDouble();
    if (value is double) return value;
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'temperature': temperature,
      'humidity': humidity,
      'obstacle': obstacle,
      'timestamp': timestamp.toIso8601String(),
      'user_id': userId,
    };
  }

  @override
  String toString() {
    return 'SensorData(temperature: ${temperature.toStringAsFixed(1)}°C, humidity: ${humidity.toStringAsFixed(1)}%, obstacle: $obstacle)';
  }

  SensorData copyWith({
    int? id,
    double? temperature,
    double? humidity,
    bool? obstacle,
    DateTime? timestamp,
    int? userId,
  }) {
    return SensorData(
      id: id ?? this.id,
      temperature: temperature ?? this.temperature,
      humidity: humidity ?? this.humidity,
      obstacle: obstacle ?? this.obstacle,
      timestamp: timestamp ?? this.timestamp,
      userId: userId ?? this.userId,
    );
  }
}
