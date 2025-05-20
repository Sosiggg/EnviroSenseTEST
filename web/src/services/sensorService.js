import api from '../utils/api';
import websocketManager from '../utils/websocket';

// Get sensor data for current user
export const getSensorData = async () => {
  try {
    const response = await api.get('/sensor/data');
    return response.data;
  } catch (error) {
    console.error('Get sensor data error:', error);
    throw error;
  }
};

// Connect to WebSocket for real-time sensor data
export const connectToWebSocket = (email) => {
  websocketManager.connect(email);
};

// Disconnect from WebSocket
export const disconnectFromWebSocket = () => {
  websocketManager.disconnect();
};

// Add WebSocket listener
export const addWebSocketListener = (callback) => {
  return websocketManager.addListener(callback);
};

// Get latest sensor data
export const getLatestSensorData = async () => {
  try {
    const data = await getSensorData();

    // Sort by timestamp in descending order
    const sortedData = [...data].sort((a, b) => {
      return new Date(b.timestamp) - new Date(a.timestamp);
    });

    // Return the latest data or null if no data
    return sortedData.length > 0 ? sortedData[0] : null;
  } catch (error) {
    console.error('Get latest sensor data error:', error);
    throw error;
  }
};
