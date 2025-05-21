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

  /// Get paginated sensor data by date
  /// Returns a map containing data list and pagination metadata
  Future<Map<String, dynamic>> getSensorDataByDatePaginated({
    required DateTime date,
    required int page,
    required int pageSize,
  });

  /// Get paginated sensor data by date range
  /// Returns a map containing data list and pagination metadata
  Future<Map<String, dynamic>> getSensorDataByDateRangePaginated({
    required DateTime startDate,
    required DateTime endDate,
    required int page,
    required int pageSize,
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

  /// Check if there is any sensor data available
  Future<Map<String, dynamic>> checkSensorData();

  /// Clear all sensor data (both cached and in-memory)
  Future<void> clearAllSensorData();
}
