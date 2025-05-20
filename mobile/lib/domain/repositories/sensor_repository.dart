abstract class SensorRepository {
  /// Get all sensor data
  Future<List<Map<String, dynamic>>> getSensorData();
  
  /// Get latest sensor data
  Future<Map<String, dynamic>> getLatestSensorData();
  
  /// Get sensor data by date range
  Future<List<Map<String, dynamic>>> getSensorDataByDateRange({
    required DateTime startDate,
    required DateTime endDate,
  });
  
  /// Get sensor data statistics
  Future<Map<String, dynamic>> getSensorDataStatistics();
  
  /// Connect to WebSocket for real-time updates
  Future<void> connectToWebSocket();
  
  /// Disconnect from WebSocket
  Future<void> disconnectFromWebSocket();
  
  /// Listen to WebSocket events
  Stream<Map<String, dynamic>> getSensorDataStream();
  
  /// Check if WebSocket is connected
  bool isWebSocketConnected();
}
