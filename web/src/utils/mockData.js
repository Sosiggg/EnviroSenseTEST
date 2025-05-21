// Mock data for testing when the backend is unavailable

// Generate a timestamp for a specific time ago
const getTimestamp = (minutesAgo) => {
  const date = new Date();
  date.setMinutes(date.getMinutes() - minutesAgo);
  return date.toISOString();
};

// Generate mock sensor data
export const generateMockSensorData = (count = 20) => {
  const data = [];
  
  for (let i = 0; i < count; i++) {
    // Generate random values with some realistic patterns
    const minutesAgo = i * 3; // Each record is 3 minutes apart
    const baseTemp = 25 + Math.sin(i / 5) * 3; // Temperature oscillates around 25°C
    const baseHumidity = 60 + Math.cos(i / 4) * 10; // Humidity oscillates around 60%
    
    // Add some random noise
    const temperature = parseFloat((baseTemp + (Math.random() * 0.5 - 0.25)).toFixed(1));
    const humidity = parseFloat((baseHumidity + (Math.random() * 2 - 1)).toFixed(1));
    
    // Obstacle detection (occasional true values)
    const obstacle = Math.random() > 0.8;
    
    data.push({
      id: `mock-${i}`,
      temperature,
      humidity,
      obstacle,
      timestamp: getTimestamp(minutesAgo),
      user_id: 'mock-user'
    });
  }
  
  // Sort by timestamp in ascending order
  return data.sort((a, b) => new Date(a.timestamp) - new Date(b.timestamp));
};

// Get the latest mock sensor data
export const getLatestMockData = () => {
  const mockData = generateMockSensorData(1);
  return mockData[0];
};

// Default export for all mock data functions
export default {
  generateMockSensorData,
  getLatestMockData
};
