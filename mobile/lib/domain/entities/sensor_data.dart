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

    // Handle ESP32 data format which might be missing some fields
    DateTime timestamp;
    try {
      if (json.containsKey('timestamp')) {
        timestamp = DateTime.parse(json['timestamp']);
      } else {
        timestamp = DateTime.now();
      }
    } catch (e) {
      AppLogger.e('Error parsing timestamp: $e', e);
      timestamp = DateTime.now();
    }

    return SensorData(
      id: json['id'] ?? 0, // Default to 0 if id is missing
      temperature: _parseDouble(json['temperature']),
      humidity: _parseDouble(json['humidity']),
      obstacle: json['obstacle'] ?? false,
      timestamp: timestamp,
      userId: json['user_id'] ?? 1, // Default to 1 if user_id is missing
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
