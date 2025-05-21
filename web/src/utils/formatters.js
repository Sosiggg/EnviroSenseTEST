// Format date to Manila time (GMT+8) in 12-hour format
export const formatDateTime = (dateString) => {
  try {
    const date = new Date(dateString);

    // Convert to Manila time (GMT+8)
    const manilaTime = new Date(date.getTime() + (8 * 60 * 60 * 1000));

    // Format in 12-hour format
    return manilaTime.toLocaleString('en-US', {
      year: 'numeric',
      month: 'short',
      day: 'numeric',
      hour: 'numeric',
      minute: '2-digit',
      second: '2-digit',
      hour12: true,
    });
  } catch (error) {
    console.error('Error formatting date:', error);
    return 'Invalid date';
  }
};

// Format temperature with unit
export const formatTemperature = (temp) => {
  if (temp === null || temp === undefined) return 'N/A';
  return `${temp.toFixed(1)}°C`;
};

// Format humidity with unit
export const formatHumidity = (humidity) => {
  if (humidity === null || humidity === undefined) return 'N/A';
  return `${humidity.toFixed(1)}%`;
};

// Format obstacle status
export const formatObstacle = (obstacle) => {
  return obstacle ? 'Detected' : 'Clear';
};

// Get color based on temperature value
export const getTemperatureColor = (temp) => {
  if (temp === null || temp === undefined) return '#9e9e9e';
  if (temp < 10) return '#2196f3'; // Cold - blue
  if (temp < 25) return '#4caf50'; // Normal - green
  if (temp < 35) return '#ff9800'; // Warm - orange
  return '#f44336'; // Hot - red
};

// Get color based on humidity value
export const getHumidityColor = (humidity) => {
  if (humidity === null || humidity === undefined) return '#9e9e9e';
  if (humidity < 30) return '#f44336'; // Dry - red
  if (humidity < 60) return '#4caf50'; // Normal - green
  return '#2196f3'; // Humid - blue
};

// Get color based on obstacle status
export const getObstacleColor = (obstacle) => {
  return obstacle ? '#f44336' : '#4caf50';
};

// Generate chart data for temperature
export const generateTemperatureChartData = (sensorData) => {
  // Validate input
  if (!sensorData || !Array.isArray(sensorData) || sensorData.length === 0) {
    console.warn('Invalid or empty sensor data for temperature chart');
    return {
      labels: [],
      datasets: [
        {
          label: 'Temperature (°C)',
          data: [],
          borderColor: '#f44336',
          backgroundColor: 'rgba(244, 67, 54, 0.1)',
          tension: 0.4,
        },
      ],
    };
  }

  try {
    // Filter out any invalid data points
    const validData = sensorData.filter(data =>
      data &&
      data.timestamp &&
      data.temperature !== undefined &&
      data.temperature !== null
    );

    const labels = validData.map(data => formatDateTime(data.timestamp));
    const data = validData.map(data => {
      // Ensure temperature is a number
      const temp = typeof data.temperature === 'string'
        ? parseFloat(data.temperature)
        : data.temperature;
      return isNaN(temp) ? 0 : temp;
    });

    return {
      labels,
      datasets: [
        {
          label: 'Temperature (°C)',
          data,
          borderColor: '#f44336',
          backgroundColor: 'rgba(244, 67, 54, 0.1)',
          tension: 0.4,
        },
      ],
    };
  } catch (error) {
    console.error('Error generating temperature chart data:', error);
    return {
      labels: [],
      datasets: [
        {
          label: 'Temperature (°C)',
          data: [],
          borderColor: '#f44336',
          backgroundColor: 'rgba(244, 67, 54, 0.1)',
          tension: 0.4,
        },
      ],
    };
  }
};

// Generate chart data for humidity
export const generateHumidityChartData = (sensorData) => {
  // Validate input
  if (!sensorData || !Array.isArray(sensorData) || sensorData.length === 0) {
    console.warn('Invalid or empty sensor data for humidity chart');
    return {
      labels: [],
      datasets: [
        {
          label: 'Humidity (%)',
          data: [],
          borderColor: '#2196f3',
          backgroundColor: 'rgba(33, 150, 243, 0.1)',
          tension: 0.4,
        },
      ],
    };
  }

  try {
    // Filter out any invalid data points
    const validData = sensorData.filter(data =>
      data &&
      data.timestamp &&
      data.humidity !== undefined &&
      data.humidity !== null
    );

    const labels = validData.map(data => formatDateTime(data.timestamp));
    const data = validData.map(data => {
      // Ensure humidity is a number
      const humidity = typeof data.humidity === 'string'
        ? parseFloat(data.humidity)
        : data.humidity;
      return isNaN(humidity) ? 0 : humidity;
    });

    return {
      labels,
      datasets: [
        {
          label: 'Humidity (%)',
          data,
          borderColor: '#2196f3',
          backgroundColor: 'rgba(33, 150, 243, 0.1)',
          tension: 0.4,
        },
      ],
    };
  } catch (error) {
    console.error('Error generating humidity chart data:', error);
    return {
      labels: [],
      datasets: [
        {
          label: 'Humidity (%)',
          data: [],
          borderColor: '#2196f3',
          backgroundColor: 'rgba(33, 150, 243, 0.1)',
          tension: 0.4,
        },
      ],
    };
  }
};
