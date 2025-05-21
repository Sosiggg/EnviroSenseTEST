import api from '../utils/api';
import websocketManager from '../utils/websocket';

// Get sensor data for current user
export const getSensorData = async () => {
  try {
    console.log('Fetching sensor data from API...');
    const response = await api.get('/sensor/data');
    console.log('Sensor data received:', response.data);

    // Check if response.data is valid
    if (!response.data) {
      console.error('API returned empty data');
      return [];
    }

    // Handle both array and single object responses
    if (Array.isArray(response.data)) {
      return response.data;
    } else if (typeof response.data === 'object') {
      // If it's a single object with sensor data
      if (response.data.temperature !== undefined) {
        console.log('API returned a single sensor data object');
        return [response.data]; // Return as array with single item
      } else if (response.data.data && Array.isArray(response.data.data)) {
        // If data is nested in a 'data' property
        console.log('API returned data in a nested property');
        return response.data.data;
      } else {
        console.error('API returned an object but not in expected format:', response.data);
        return [];
      }
    } else {
      console.error('API returned unexpected data type:', typeof response.data);
      return [];
    }
  } catch (error) {
    console.error('Get sensor data error:', error);
    console.error('Error details:', error.response?.data || 'No response data');
    // Return empty array instead of throwing to prevent app crashes
    return [];
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
