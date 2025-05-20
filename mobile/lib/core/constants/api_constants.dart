class ApiConstants {
  // Base URLs
  // static const String baseUrl = 'http://10.0.2.2:8000/api/v1'; // Local development URL
  static const String baseUrl =
      'https://envirosense-2khv.onrender.com/api/v1'; // Production URL
  static const String productionBaseUrl =
      'https://envirosense-2khv.onrender.com/api/v1';

  // WebSocket URLs
  // static const String wsUrl = 'ws://10.0.2.2:8000/api/v1/sensor/ws'; // Local development WebSocket
  static const String wsUrl =
      'wss://envirosense-2khv.onrender.com/api/v1/sensor/ws'; // Production WebSocket
  static const String productionWsUrl =
      'wss://envirosense-2khv.onrender.com/api/v1/sensor/ws';

  // Auth Endpoints
  static const String register = '/auth/register';
  static const String login = '/auth/token';
  static const String forgotPassword = '/auth/forgot-password';
  static const String resetPassword = '/auth/reset-password';
  static const String userProfile = '/auth/me';
  static const String changePassword = '/auth/change-password';

  // Sensor Endpoints
  static const String sensorData = '/sensor/data';
  static const String latestSensorData = '/sensor/data/latest';
  static const String sensorDataStatistics = '/sensor/data/statistics';
}
