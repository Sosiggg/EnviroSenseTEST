import React, { createContext, useState, useEffect, useContext } from 'react';
import {
  getSensorData,
  connectToWebSocket,
  disconnectFromWebSocket,
  addWebSocketListener
} from '../services/sensorService';
import { generateMockSensorData, getLatestMockData } from '../utils/mockData';
import { useAuth } from './AuthContext';

// Flag to use mock data when backend is unavailable
const USE_MOCK_DATA = false; // Disabled as per user request

// Create context
const SensorContext = createContext();

// Sensor provider component
export const SensorProvider = ({ children }) => {
  const { isAuthenticated, user } = useAuth();
  const [sensorData, setSensorData] = useState([]);
  const [latestData, setLatestData] = useState(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(null);
  const [isConnected, setIsConnected] = useState(false);

  // Log user info for debugging
  useEffect(() => {
    if (user) {
      console.log('User info in SensorContext:', user);
    }
  }, [user]);

  // Fetch initial sensor data
  useEffect(() => {
    const fetchSensorData = async () => {
      if (!isAuthenticated) {
        setLoading(false);
        return;
      }

      setLoading(true);
      setError(null);

      try {
        let data;

        if (USE_MOCK_DATA) {
          // Use mock data if backend is unavailable
          console.log('Using mock sensor data');
          data = generateMockSensorData(20);

          // Set latest data from mock
          setLatestData(data[data.length - 1]);
          setSensorData(data);

          // Simulate WebSocket connection
          setIsConnected(true);

          // Simulate real-time updates with mock data
          const mockUpdateInterval = setInterval(() => {
            const newData = getLatestMockData();
            console.log('Mock data update:', newData);
            setLatestData(newData);
            setSensorData(prev => {
              const updated = [...prev, newData].slice(-50); // Keep last 50 readings
              return updated.sort((a, b) => new Date(a.timestamp) - new Date(b.timestamp));
            });
          }, 10000); // Update every 10 seconds

          // Clean up interval on unmount
          return () => clearInterval(mockUpdateInterval);
        } else {
          // Use real backend data
          data = await getSensorData();
          console.log('Raw data from API:', data);

          // Check if data is an array
          if (!data || !Array.isArray(data)) {
            console.error('API did not return an array:', data);
            // Handle single object case
            if (data && typeof data === 'object' && data.temperature !== undefined) {
              const processedData = {
                ...data,
                temperature: typeof data.temperature === 'string' ? parseFloat(data.temperature) : data.temperature,
                humidity: typeof data.humidity === 'string' ? parseFloat(data.humidity) : data.humidity,
                obstacle: typeof data.obstacle === 'string' ? (data.obstacle === 'true' || data.obstacle === '1') : Boolean(data.obstacle)
              };
              setSensorData([processedData]);
              setLatestData(processedData);
            } else {
              // Initialize with empty array
              setSensorData([]);
            }
          } else {
            // Sort by timestamp in ascending order
            const sortedData = [...data].sort((a, b) => {
              return new Date(a.timestamp) - new Date(b.timestamp);
            });

            setSensorData(sortedData);

            // Set latest data
            if (sortedData.length > 0) {
              setLatestData(sortedData[sortedData.length - 1]);
            }
          }
        }
      } catch (error) {
        console.error('Fetch sensor data error:', error);

        if (USE_MOCK_DATA) {
          // Fall back to mock data on error
          console.log('Falling back to mock data after error');
          const mockData = generateMockSensorData(20);
          setSensorData(mockData);
          setLatestData(mockData[mockData.length - 1]);
          setIsConnected(true);
        } else {
          setError('Failed to fetch sensor data. Please check your connection and try again.');
        }
      } finally {
        setLoading(false);
      }
    };

    fetchSensorData();

    // Clean up function
    return () => {
      // Any cleanup needed
    };
  }, [isAuthenticated]);

  // Connect to WebSocket for real-time updates
  useEffect(() => {
    // Skip WebSocket connection if using mock data
    if (USE_MOCK_DATA) {
      console.log('Using mock data - skipping real WebSocket connection');
      return;
    }

    if (isAuthenticated && user) {
      // Use email for WebSocket connection
      if (user.email) {
        console.log('Connecting to WebSocket with email:', user.email);

        // Connect to WebSocket using email
        connectToWebSocket(user.email);

        // Add WebSocket listener
        const removeListener = addWebSocketListener((data) => {
          console.log('WebSocket data received in SensorContext:', data);

          // Handle connection status messages
          if (data.type === 'connection') {
            console.log('Connection status update:', data.status);

            // Update connection status based on the status field
            const connected = data.status === 'connected';
            setIsConnected(connected);

            // Handle error states
            if (['error', 'failed', 'timeout'].includes(data.status)) {
              console.error('WebSocket connection issue:', data.message || data.error);

              if (USE_MOCK_DATA) {
                // Don't show error if using mock data
                console.log('Using mock data - ignoring WebSocket error');
              } else {
                // Show user-friendly error message
                const errorMessage = data.message ||
                  `Connection error: ${data.error || 'Unable to connect to sensor data'}`;
                console.error(errorMessage);
                setError(errorMessage);
              }
            } else if (data.status === 'connected') {
              // Clear any existing error when connection is successful
              setError(null);
            }
            return;
          }

          // Check if data has temperature (it's a sensor data update)
          if (data.temperature !== undefined) {
            console.log('Sensor data update received:', data);
            console.log('Data type:', typeof data);
            console.log('Temperature:', data.temperature, 'type:', typeof data.temperature);
            console.log('Humidity:', data.humidity, 'type:', typeof data.humidity);
            console.log('Obstacle:', data.obstacle, 'type:', typeof data.obstacle);
            console.log('Timestamp:', data.timestamp, 'type:', typeof data.timestamp);

            // Convert numeric strings to numbers if needed
            const processedData = {
              ...data,
              temperature: typeof data.temperature === 'string' ? parseFloat(data.temperature) : data.temperature,
              humidity: typeof data.humidity === 'string' ? parseFloat(data.humidity) : data.humidity,
              obstacle: typeof data.obstacle === 'string' ? (data.obstacle === 'true' || data.obstacle === '1') : Boolean(data.obstacle)
            };

            console.log('Processed data:', processedData);

            // Update latest data
            setLatestData(processedData);

            // Update sensor data array
            setSensorData(prevData => {
              // Add new data to array
              const newData = [...prevData, processedData];

              // Sort by timestamp in ascending order
              const sortedData = newData.sort((a, b) => {
                return new Date(a.timestamp) - new Date(b.timestamp);
              });

              console.log('Updated sensor data array, now has', sortedData.length, 'items');
              return sortedData;
            });
          } else if (data.status === 'success' && data.message && data.message.includes('received')) {
            // This is just an acknowledgment message, log it but don't update state
            console.log('Received acknowledgment message:', data);
          } else if (data.status === 'connected') {
            // This is a connection status message, log it
            console.log('Received connection status message:', data);
          } else {
            console.log('Received data without temperature field:', data);
          }
        });

        // Cleanup function
        return () => {
          console.log('Cleaning up WebSocket connection');
          removeListener();
          disconnectFromWebSocket();
          setIsConnected(false);
        };
      } else {
        console.error('User has no email, cannot connect to WebSocket');
      }
    }
  }, [isAuthenticated, user]);

  // Function to refresh sensor data
  const refreshData = async () => {
    setLoading(true);
    setError(null);

    try {
      if (USE_MOCK_DATA) {
        // Use mock data
        console.log('Refreshing with mock data');
        const mockData = generateMockSensorData(20);
        setSensorData(mockData);
        setLatestData(mockData[mockData.length - 1]);
        setIsConnected(true);
        setLoading(false);
        return mockData;
      } else {
        // Use real backend data
        const data = await getSensorData();
        console.log('Fetched sensor data from API:', data);

        // Check if data is an array
        if (!data || !Array.isArray(data)) {
          console.error('API did not return an array:', data);

          // Handle single object case
          if (data && typeof data === 'object' && data.temperature !== undefined) {
            const processedData = {
              ...data,
              temperature: typeof data.temperature === 'string' ? parseFloat(data.temperature) : data.temperature,
              humidity: typeof data.humidity === 'string' ? parseFloat(data.humidity) : data.humidity,
              obstacle: typeof data.obstacle === 'string' ? (data.obstacle === 'true' || data.obstacle === '1') : Boolean(data.obstacle)
            };

            // Create an array with the single item
            const dataArray = [processedData];
            setSensorData(dataArray);
            setLatestData(processedData);

            console.log('Processed single data item:', processedData);
            return dataArray;
          } else {
            // Return empty array if no valid data
            console.log('No valid data found, returning empty array');
            setSensorData([]);
            return [];
          }
        } else {
          // Process the data to ensure correct types
          const processedData = data.map(item => ({
            ...item,
            temperature: typeof item.temperature === 'string' ? parseFloat(item.temperature) : item.temperature,
            humidity: typeof item.humidity === 'string' ? parseFloat(item.humidity) : item.humidity,
            obstacle: typeof item.obstacle === 'string' ? (item.obstacle === 'true' || item.obstacle === '1') : Boolean(item.obstacle)
          }));

          // Sort by timestamp in ascending order
          const sortedData = [...processedData].sort((a, b) => {
            return new Date(a.timestamp) - new Date(b.timestamp);
          });

          console.log('Processed and sorted data:', sortedData);
          setSensorData(sortedData);

          // Set latest data
          if (sortedData.length > 0) {
            const latest = sortedData[sortedData.length - 1];
            console.log('Setting latest data from API:', latest);
            setLatestData(latest);
          }

          return sortedData;
        }
      }
    } catch (error) {
      console.error('Refresh sensor data error:', error);

      // Extract error message from response if available
      const errorMessage = error.response?.data?.detail ||
                          error.message ||
                          'Failed to refresh sensor data. Please check your connection and try again.';

      if (USE_MOCK_DATA) {
        // Fall back to mock data on error
        console.log('Falling back to mock data after refresh error');
        const mockData = generateMockSensorData(20);
        setSensorData(mockData);
        setLatestData(mockData[mockData.length - 1]);
        setIsConnected(true);
        setLoading(false);
        return mockData;
      } else {
        setError(errorMessage);

        // If we have connection issues, try to reconnect WebSocket
        if (!isConnected && user && user.email) {
          console.log('Connection issue detected, attempting to reconnect WebSocket');
          connectToWebSocket(user.email);
        }

        // Don't throw the error - handle it gracefully
        return [];
      }
    } finally {
      setLoading(false);
    }
  };

  // Context value
  const value = {
    sensorData,
    latestData,
    loading,
    error,
    isConnected,
    refreshData,
  };

  return <SensorContext.Provider value={value}>{children}</SensorContext.Provider>;
};

// Custom hook to use sensor context
export const useSensor = () => {
  const context = useContext(SensorContext);

  if (!context) {
    throw new Error('useSensor must be used within a SensorProvider');
  }

  return context;
};
