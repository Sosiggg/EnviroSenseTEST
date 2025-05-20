import React, { createContext, useState, useEffect, useContext } from 'react';
import {
  getSensorData,
  connectToWebSocket,
  disconnectFromWebSocket,
  addWebSocketListener
} from '../services/sensorService';
import { useAuth } from './AuthContext';

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
        const data = await getSensorData();

        // Sort by timestamp in ascending order
        const sortedData = [...data].sort((a, b) => {
          return new Date(a.timestamp) - new Date(b.timestamp);
        });

        setSensorData(sortedData);

        // Set latest data
        if (sortedData.length > 0) {
          setLatestData(sortedData[sortedData.length - 1]);
        }
      } catch (error) {
        console.error('Fetch sensor data error:', error);
        setError('Failed to fetch sensor data');
      } finally {
        setLoading(false);
      }
    };

    fetchSensorData();
  }, [isAuthenticated]);

  // Connect to WebSocket for real-time updates
  useEffect(() => {
    if (isAuthenticated && user) {
      // Use email for WebSocket connection
      if (user.email) {
        // Connect to WebSocket using email
        connectToWebSocket(user.email);
        setIsConnected(true);

        // Add WebSocket listener
        const removeListener = addWebSocketListener((data) => {
          // Check if data has temperature (it's a sensor data update)
          if (data.temperature !== undefined) {
            // Update latest data
            setLatestData(data);

            // Update sensor data array
            setSensorData(prevData => {
              // Add new data to array
              const newData = [...prevData, data];

              // Sort by timestamp in ascending order
              return newData.sort((a, b) => {
                return new Date(a.timestamp) - new Date(b.timestamp);
              });
            });
          }
        });

        // Cleanup function
        return () => {
          removeListener();
          disconnectFromWebSocket();
          setIsConnected(false);
        };
      }
    }
  }, [isAuthenticated, user]);

  // Context value
  const value = {
    sensorData,
    latestData,
    loading,
    error,
    isConnected,
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
