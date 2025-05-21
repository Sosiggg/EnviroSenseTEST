import React, { useState, useCallback, useEffect } from 'react';
import {
  Grid,
  Typography,
  Box,
  Paper,
  CircularProgress,
  Alert,
  Card,
  Chip,
  useTheme,
  alpha,
  Stack,
  IconButton,
  Tooltip,
  Button,
  Table,
  TableBody,
  TableCell,
  TableHead,
  TableRow
} from '@mui/material';
import {
  Thermostat as ThermostatIcon,
  Refresh as RefreshIcon,
  WifiTethering as WifiTetheringIcon,
  WifiOff as WifiOffIcon
} from '@mui/icons-material';
import { useSensor } from '../context/SensorContext';
import SensorCard from '../components/SensorCard';
import SensorChart from '../components/SensorChart';
import { formatDateTime, getTemperatureColor, getHumidityColor } from '../utils/formatters';

const Dashboard = () => {
  const { sensorData, latestData, loading, error, isConnected, refreshData } = useSensor();
  const theme = useTheme();
  const [refreshing, setRefreshing] = useState(false);

  // Function to refresh sensor data
  const handleRefresh = useCallback(async () => {
    if (refreshing) return;

    setRefreshing(true);
    try {
      console.log('Manually refreshing sensor data...');
      const data = await refreshData();
      console.log('Refreshed sensor data:', data);

      // Force a re-render by setting state
      if (data && data.length > 0) {
        const latest = data[data.length - 1];
        console.log('Setting latest data manually:', latest);
      }
    } catch (error) {
      console.error('Error refreshing data:', error);
    } finally {
      setTimeout(() => setRefreshing(false), 1000); // Show refresh animation for at least 1 second
    }
  }, [refreshData, refreshing]);

  // Auto-refresh data every 30 seconds if connected but no data is showing
  useEffect(() => {
    if (isConnected && (!latestData || latestData.temperature === undefined)) {
      const intervalId = setInterval(() => {
        console.log('Auto-refreshing data...');
        handleRefresh();
      }, 30000); // 30 seconds

      return () => clearInterval(intervalId);
    }
  }, [isConnected, latestData, handleRefresh]);

  // Show loading state
  if (loading) {
    return (
      <Box
        sx={{
          display: 'flex',
          flexDirection: 'column',
          justifyContent: 'center',
          alignItems: 'center',
          height: '70vh'
        }}
      >
        <CircularProgress size={60} thickness={4} sx={{ mb: 3 }} />
        <Typography variant="h6" color="text.secondary">
          Loading sensor data...
        </Typography>
      </Box>
    );
  }

  // Show error state
  if (error) {
    return (
      <Box>
        <Typography variant="h4" component="h1" gutterBottom>
          Dashboard
        </Typography>

        <Alert
          severity="error"
          sx={{
            mt: 2,
            p: 3,
            borderRadius: 2,
            boxShadow: '0 4px 20px rgba(0, 0, 0, 0.08)'
          }}
          action={
            <Button
              color="inherit"
              size="small"
              onClick={handleRefresh}
              disabled={refreshing}
            >
              {refreshing ? 'Retrying...' : 'Retry'}
            </Button>
          }
        >
          <Typography variant="h6" gutterBottom>
            Error Loading Data
          </Typography>
          <Typography variant="body1">
            {error}
          </Typography>
          <Typography variant="body2" sx={{ mt: 1, opacity: 0.8 }}>
            This could be due to a network issue or the server might be unavailable.
          </Typography>
        </Alert>

        <Box sx={{ mt: 3 }}>
          <Paper sx={{ p: 3, borderRadius: 2 }}>
            <Typography variant="h6" gutterBottom>
              Troubleshooting Steps
            </Typography>
            <Typography variant="body1" paragraph>
              Please try the following steps to resolve the connection issue:
            </Typography>
            <Typography variant="body2" component="ol" sx={{ pl: 2 }}>
              <li>Check your internet connection</li>
              <li>Verify that the backend server is running</li>
              <li>Ensure your authentication credentials are correct</li>
              <li>Try refreshing the page or logging out and back in</li>
            </Typography>
          </Paper>
        </Box>
      </Box>
    );
  }

  return (
    <Box sx={{ position: 'relative' }}>
      {/* CSS for animations */}
      <style>{`
        @keyframes spin {
          0% { transform: rotate(0deg); }
          100% { transform: rotate(360deg); }
        }
      `}</style>

      {/* Dashboard Header */}
      <Box
        sx={{
          mb: 3,
          display: 'flex',
          flexDirection: { xs: 'column', sm: 'row' },
          justifyContent: 'space-between',
          alignItems: { xs: 'flex-start', sm: 'center' },
          gap: 1
        }}
      >
        <Box>
          <Typography
            variant="h5"
            component="h1"
            sx={{
              fontWeight: 'bold',
              color: theme.palette.primary.main,
              mb: 0.5
            }}
          >
            EnviroSense Dashboard
          </Typography>
          <Typography variant="body2" color="text.secondary">
            Real-time environmental monitoring data
          </Typography>
        </Box>

        <Stack direction="row" spacing={1} alignItems="center">
          <Chip
            icon={isConnected ? <WifiTetheringIcon fontSize="small" /> : <WifiOffIcon fontSize="small" />}
            label={isConnected ? "Live" : "Offline"}
            color={isConnected ? "success" : "error"}
            variant={isConnected ? "filled" : "outlined"}
            size="small"
            sx={{ fontWeight: 'medium' }}
          />
          <Tooltip title={refreshing ? "Refreshing..." : "Refresh data"}>
            <span>
              <IconButton
                color="primary"
                onClick={handleRefresh}
                disabled={refreshing || loading}
                size="small"
                sx={{
                  animation: refreshing ? 'spin 1s linear infinite' : 'none',
                }}
              >
                <RefreshIcon fontSize="small" />
              </IconButton>
            </span>
          </Tooltip>
        </Stack>
      </Box>

      {/* Latest readings */}
      <Box sx={{ mb: 3 }}>
        <Box
          sx={{
            display: 'flex',
            justifyContent: 'space-between',
            alignItems: 'center',
            mb: 2
          }}
        >
          <Typography
            variant="subtitle1"
            component="h2"
            sx={{ fontWeight: 'medium' }}
          >
            Latest Readings
          </Typography>

          {latestData && (
            <Typography variant="caption" color="text.secondary">
              Last updated: {formatDateTime(latestData.timestamp)}
            </Typography>
          )}
        </Box>

        {latestData && latestData.temperature !== undefined ? (
          <Grid container spacing={2}>
            <Grid item xs={12} sm={6} md={4}>
              <SensorCard
                title="Temperature"
                value={latestData.temperature}
                type="temperature"
              />
            </Grid>
            <Grid item xs={12} sm={6} md={4}>
              <SensorCard
                title="Humidity"
                value={latestData.humidity}
                type="humidity"
              />
            </Grid>
            <Grid item xs={12} sm={6} md={4}>
              <SensorCard
                title="Obstacle"
                value={latestData.obstacle}
                type="obstacle"
              />
            </Grid>
          </Grid>
        ) : (
          <Box>
            <Alert
              severity="info"
              sx={{
                p: 1.5,
                mb: 2
              }}
            >
              <Typography variant="body2">
                No sensor data available yet. Connect your sensors to start receiving data.
              </Typography>
            </Alert>

            <Paper
              sx={{
                p: 3,
                textAlign: 'center',
              }}
            >
              <Box
                sx={{
                  display: 'flex',
                  flexDirection: 'column',
                  alignItems: 'center',
                  justifyContent: 'center',
                  py: 2
                }}
              >
                <ThermostatIcon
                  sx={{
                    fontSize: 40,
                    color: alpha(theme.palette.primary.main, 0.3),
                    mb: 1.5
                  }}
                />
                <Typography variant="subtitle1" gutterBottom>
                  Waiting for Sensor Data
                </Typography>
                <Typography variant="body2" color="text.secondary" sx={{ maxWidth: 500, mb: 2 }}>
                  {isConnected
                    ? "Your device is connected and we're waiting for data."
                    : "Your device appears to be offline. Please check your sensor connection."}
                </Typography>

                <Box sx={{ display: 'flex', gap: 1, flexWrap: 'wrap', justifyContent: 'center' }}>
                  <Button
                    variant="contained"
                    color="primary"
                    onClick={handleRefresh}
                    disabled={refreshing}
                    startIcon={<RefreshIcon />}
                    size="small"
                  >
                    {refreshing ? 'Refreshing...' : 'Refresh Data'}
                  </Button>

                  <Button
                    variant="outlined"
                    color="secondary"
                    onClick={() => window.location.reload()}
                    size="small"
                  >
                    Reload Page
                  </Button>
                </Box>
              </Box>
            </Paper>
          </Box>
        )}
      </Box>

      {/* Charts */}
      {sensorData.length > 0 && (
        <Box sx={{ mb: 3 }}>
          <Typography
            variant="subtitle1"
            component="h2"
            sx={{ fontWeight: 'medium', mb: 2 }}
          >
            Historical Data
          </Typography>
          <Grid container spacing={2}>
            <Grid item xs={12} md={6}>
              <SensorChart
                title="Temperature History"
                type="temperature"
                data={sensorData}
              />
            </Grid>
            <Grid item xs={12} md={6}>
              <SensorChart
                title="Humidity History"
                type="humidity"
                data={sensorData}
              />
            </Grid>
          </Grid>
        </Box>
      )}

      {/* Data history log - Simplified */}
      {sensorData.length > 0 && (
        <Box sx={{ mb: 3 }}>
          <Typography
            variant="subtitle1"
            component="h2"
            sx={{ fontWeight: 'medium', mb: 2 }}
          >
            Data History Log
          </Typography>

          <Card>
            <Box
              sx={{
                maxHeight: 300,
                overflow: 'auto',
                '&::-webkit-scrollbar': {
                  width: '6px',
                },
                '&::-webkit-scrollbar-track': {
                  backgroundColor: alpha(theme.palette.primary.main, 0.05),
                  borderRadius: '6px',
                },
                '&::-webkit-scrollbar-thumb': {
                  backgroundColor: alpha(theme.palette.primary.main, 0.2),
                  borderRadius: '6px',
                },
              }}
            >
              <Table size="small">
                <TableHead>
                  <TableRow>
                    <TableCell>Time</TableCell>
                    <TableCell align="right">Temp</TableCell>
                    <TableCell align="right">Humidity</TableCell>
                    <TableCell align="right">Obstacle</TableCell>
                  </TableRow>
                </TableHead>
                <TableBody>
                  {sensorData.slice().reverse().slice(0, 10).map((data, index) => (
                    <TableRow key={data.id || index}>
                      <TableCell component="th" scope="row">
                        {formatDateTime(data.timestamp)}
                      </TableCell>
                      <TableCell align="right" sx={{ color: getTemperatureColor(data.temperature) }}>
                        {data.temperature.toFixed(1)}°C
                      </TableCell>
                      <TableCell align="right" sx={{ color: getHumidityColor(data.humidity) }}>
                        {data.humidity.toFixed(1)}%
                      </TableCell>
                      <TableCell align="right">
                        <Box sx={{ display: 'flex', alignItems: 'center', justifyContent: 'flex-end' }}>
                          <Box
                            sx={{
                              width: 8,
                              height: 8,
                              borderRadius: '50%',
                              bgcolor: data.obstacle ? 'error.main' : 'success.main',
                              mr: 0.5
                            }}
                          />
                          <Typography variant="body2" sx={{ fontSize: '0.75rem' }}>
                            {data.obstacle ? 'Yes' : 'No'}
                          </Typography>
                        </Box>
                      </TableCell>
                    </TableRow>
                  ))}
                </TableBody>
              </Table>
            </Box>
          </Card>
        </Box>
      )}
    </Box>
  );
};

export default Dashboard;
