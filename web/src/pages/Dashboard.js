import React from 'react';
import {
  Grid,
  Typography,
  Box,
  Paper,
  CircularProgress,
  Alert,
  Divider,
  Card,
  CardContent,
  Chip,
  useTheme,
  alpha,
  Stack,
  IconButton,
  Tooltip
} from '@mui/material';
import {
  Thermostat as ThermostatIcon,
  Opacity as OpacityIcon,
  Warning as WarningIcon,
  Refresh as RefreshIcon,
  History as HistoryIcon,
  MoreVert as MoreVertIcon,
  WifiTethering as WifiTetheringIcon,
  WifiOff as WifiOffIcon
} from '@mui/icons-material';
import { useSensor } from '../context/SensorContext';
import SensorCard from '../components/SensorCard';
import SensorChart from '../components/SensorChart';
import { formatDateTime, getTemperatureColor, getHumidityColor, getObstacleColor } from '../utils/formatters';

const Dashboard = () => {
  const { sensorData, latestData, loading, error, isConnected } = useSensor();
  const theme = useTheme();

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
      <Alert
        severity="error"
        sx={{
          mt: 2,
          p: 3,
          borderRadius: 2,
          boxShadow: '0 4px 20px rgba(0, 0, 0, 0.08)'
        }}
      >
        <Typography variant="h6" gutterBottom>
          Error Loading Data
        </Typography>
        <Typography variant="body1">
          {error}
        </Typography>
      </Alert>
    );
  }

  return (
    <Box>
      {/* Dashboard Header */}
      <Box
        sx={{
          mb: 4,
          display: 'flex',
          flexDirection: { xs: 'column', sm: 'row' },
          justifyContent: 'space-between',
          alignItems: { xs: 'flex-start', sm: 'center' },
          gap: 2
        }}
      >
        <Box>
          <Typography
            variant="h4"
            component="h1"
            gutterBottom
            sx={{
              fontWeight: 'bold',
              background: `linear-gradient(45deg, ${theme.palette.primary.main} 30%, ${theme.palette.primary.light} 90%)`,
              WebkitBackgroundClip: 'text',
              WebkitTextFillColor: 'transparent',
              letterSpacing: '0.5px'
            }}
          >
            EnviroSense Dashboard
          </Typography>
          <Typography variant="body1" color="text.secondary">
            Real-time environmental monitoring data
          </Typography>
        </Box>

        <Stack direction="row" spacing={1} alignItems="center">
          <Chip
            icon={isConnected ? <WifiTetheringIcon /> : <WifiOffIcon />}
            label={isConnected ? "Live Data" : "Offline"}
            color={isConnected ? "success" : "default"}
            variant={isConnected ? "filled" : "outlined"}
            sx={{
              fontWeight: 'medium',
              px: 1,
              '& .MuiChip-icon': {
                animation: isConnected ? 'pulse 2s infinite' : 'none'
              }
            }}
          />
          <Tooltip title="Refresh data">
            <IconButton
              color="primary"
              sx={{
                bgcolor: alpha(theme.palette.primary.main, 0.1),
                '&:hover': {
                  bgcolor: alpha(theme.palette.primary.main, 0.2),
                }
              }}
            >
              <RefreshIcon />
            </IconButton>
          </Tooltip>
        </Stack>
      </Box>

      {/* Latest readings */}
      <Box sx={{ mb: 5 }}>
        <Box
          sx={{
            display: 'flex',
            justifyContent: 'space-between',
            alignItems: 'center',
            mb: 3
          }}
        >
          <Typography
            variant="h5"
            component="h2"
            sx={{ fontWeight: 'medium' }}
          >
            Latest Readings
          </Typography>

          {latestData && (
            <Chip
              label={`Last updated: ${formatDateTime(latestData.timestamp)}`}
              size="small"
              icon={<HistoryIcon fontSize="small" />}
              sx={{
                bgcolor: alpha(theme.palette.primary.main, 0.1),
                color: theme.palette.text.primary,
                fontWeight: 'medium',
                px: 1
              }}
            />
          )}
        </Box>

        {latestData ? (
          <Grid container spacing={3}>
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
          <Alert
            severity="info"
            sx={{
              borderRadius: 2,
              boxShadow: '0 4px 20px rgba(0, 0, 0, 0.05)',
              p: 2
            }}
          >
            <Typography variant="body1">
              No sensor data available yet. Connect your sensors to start receiving data.
            </Typography>
          </Alert>
        )}
      </Box>

      {/* Charts */}
      {sensorData.length > 0 && (
        <Box sx={{ mb: 5 }}>
          <Typography
            variant="h5"
            component="h2"
            gutterBottom
            sx={{ fontWeight: 'medium', mb: 3 }}
          >
            Historical Data
          </Typography>
          <Grid container spacing={3}>
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

      {/* Data history log */}
      {sensorData.length > 0 && (
        <Box sx={{ mb: 4 }}>
          <Box
            sx={{
              display: 'flex',
              justifyContent: 'space-between',
              alignItems: 'center',
              mb: 3
            }}
          >
            <Typography
              variant="h5"
              component="h2"
              sx={{ fontWeight: 'medium' }}
            >
              Data History Log
            </Typography>

            <Tooltip title="More options">
              <IconButton>
                <MoreVertIcon />
              </IconButton>
            </Tooltip>
          </Box>

          <Card
            sx={{
              borderRadius: 3,
              boxShadow: '0 4px 20px rgba(0, 0, 0, 0.08)',
              overflow: 'hidden'
            }}
          >
            <CardContent sx={{ p: 0 }}>
              <Box
                sx={{
                  maxHeight: 400,
                  overflow: 'auto',
                  px: 3,
                  py: 2,
                  '&::-webkit-scrollbar': {
                    width: '8px',
                  },
                  '&::-webkit-scrollbar-track': {
                    backgroundColor: alpha(theme.palette.primary.main, 0.05),
                    borderRadius: '10px',
                  },
                  '&::-webkit-scrollbar-thumb': {
                    backgroundColor: alpha(theme.palette.primary.main, 0.2),
                    borderRadius: '10px',
                    '&:hover': {
                      backgroundColor: alpha(theme.palette.primary.main, 0.3),
                    },
                  },
                }}
              >
                {sensorData.slice().reverse().map((data, index) => (
                  <Box
                    key={data.id || index}
                    sx={{
                      mb: 2,
                      pb: 2,
                      borderBottom: index < sensorData.length - 1 ? `1px solid ${alpha(theme.palette.divider, 0.6)}` : 'none',
                    }}
                  >
                    <Box
                      sx={{
                        display: 'flex',
                        justifyContent: 'space-between',
                        alignItems: 'center',
                        mb: 1.5
                      }}
                    >
                      <Typography
                        variant="subtitle1"
                        fontWeight="medium"
                        sx={{ color: theme.palette.text.primary }}
                      >
                        {formatDateTime(data.timestamp)}
                      </Typography>

                      <Typography
                        variant="caption"
                        sx={{
                          color: theme.palette.text.secondary,
                          bgcolor: alpha(theme.palette.background.default, 0.7),
                          px: 1,
                          py: 0.5,
                          borderRadius: 1,
                          fontWeight: 'medium'
                        }}
                      >
                        ID: {data.id || 'N/A'}
                      </Typography>
                    </Box>

                    <Grid container spacing={2}>
                      <Grid item xs={12} sm={4}>
                        <Box
                          sx={{
                            display: 'flex',
                            alignItems: 'center',
                            p: 1.5,
                            borderRadius: 2,
                            bgcolor: alpha(getTemperatureColor(data.temperature), 0.1),
                          }}
                        >
                          <ThermostatIcon
                            sx={{
                              color: getTemperatureColor(data.temperature),
                              mr: 1,
                              fontSize: 20
                            }}
                          />
                          <Typography variant="body2" fontWeight="medium">
                            Temperature: {data.temperature.toFixed(1)}°C
                          </Typography>
                        </Box>
                      </Grid>
                      <Grid item xs={12} sm={4}>
                        <Box
                          sx={{
                            display: 'flex',
                            alignItems: 'center',
                            p: 1.5,
                            borderRadius: 2,
                            bgcolor: alpha(getHumidityColor(data.humidity), 0.1),
                          }}
                        >
                          <OpacityIcon
                            sx={{
                              color: getHumidityColor(data.humidity),
                              mr: 1,
                              fontSize: 20
                            }}
                          />
                          <Typography variant="body2" fontWeight="medium">
                            Humidity: {data.humidity.toFixed(1)}%
                          </Typography>
                        </Box>
                      </Grid>
                      <Grid item xs={12} sm={4}>
                        <Box
                          sx={{
                            display: 'flex',
                            alignItems: 'center',
                            p: 1.5,
                            borderRadius: 2,
                            bgcolor: alpha(getObstacleColor(data.obstacle), 0.1),
                          }}
                        >
                          <WarningIcon
                            sx={{
                              color: getObstacleColor(data.obstacle),
                              mr: 1,
                              fontSize: 20
                            }}
                          />
                          <Typography variant="body2" fontWeight="medium">
                            Obstacle: {data.obstacle ? 'Detected' : 'Clear'}
                          </Typography>
                        </Box>
                      </Grid>
                    </Grid>
                  </Box>
                ))}
              </Box>
            </CardContent>
          </Card>
        </Box>
      )}
    </Box>
  );
};

export default Dashboard;
