import React from 'react';
import {
  Card,
  CardContent,
  Typography,
  Box,
  useTheme,
  alpha,
  LinearProgress
} from '@mui/material';
import {
  Thermostat as ThermostatIcon,
  Opacity as OpacityIcon,
  Warning as WarningIcon
} from '@mui/icons-material';
import {
  formatTemperature,
  formatHumidity,
  formatObstacle,
  getTemperatureColor,
  getHumidityColor,
  getObstacleColor
} from '../utils/formatters';

const SensorCard = ({ title, value, type, icon }) => {
  const theme = useTheme();

  // Determine color based on type and value
  let color;
  if (type === 'temperature') {
    color = getTemperatureColor(value);
  } else if (type === 'humidity') {
    color = getHumidityColor(value);
  } else if (type === 'obstacle') {
    color = getObstacleColor(value);
  } else {
    color = theme.palette.primary.main;
  }

  // Format value based on type
  let formattedValue;
  if (type === 'temperature') {
    formattedValue = formatTemperature(value);
  } else if (type === 'humidity') {
    formattedValue = formatHumidity(value);
  } else if (type === 'obstacle') {
    formattedValue = formatObstacle(value);
  } else {
    formattedValue = value || 'N/A';
  }

  // Determine icon based on type
  let IconComponent;
  if (type === 'temperature') {
    IconComponent = ThermostatIcon;
  } else if (type === 'humidity') {
    IconComponent = OpacityIcon;
  } else if (type === 'obstacle') {
    IconComponent = WarningIcon;
  } else {
    IconComponent = icon || ThermostatIcon;
  }

  // Calculate progress value for progress bar
  let progressValue = 0;
  if (type === 'temperature') {
    // Assuming temperature range from 0 to 50°C
    progressValue = Math.min(Math.max((value / 50) * 100, 0), 100);
  } else if (type === 'humidity') {
    // Humidity range is 0-100%
    progressValue = Math.min(Math.max(value, 0), 100);
  } else if (type === 'obstacle') {
    // Boolean value
    progressValue = value ? 100 : 0;
  }

  return (
    <Card
      sx={{
        height: '100%',
        display: 'flex',
        flexDirection: 'column',
        position: 'relative',
      }}
    >
      <CardContent sx={{ p: 2, flexGrow: 1 }}>
        <Box sx={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', mb: 2 }}>
          <Box sx={{ display: 'flex', alignItems: 'center' }}>
            <Box
              sx={{
                display: 'flex',
                alignItems: 'center',
                justifyContent: 'center',
                width: 36,
                height: 36,
                borderRadius: '6px',
                backgroundColor: alpha(color, 0.1),
                color: color,
                mr: 1.5
              }}
            >
              <IconComponent fontSize="small" />
            </Box>
            <Typography
              variant="subtitle1"
              component="div"
              sx={{
                fontWeight: 'medium',
                color: 'text.primary',
              }}
            >
              {title}
            </Typography>
          </Box>

          {type !== 'obstacle' && (
            <Typography
              variant="caption"
              sx={{
                color: 'text.secondary',
                bgcolor: alpha(color, 0.1),
                px: 1,
                py: 0.5,
                borderRadius: 4,
                fontWeight: 'medium',
                fontSize: '0.7rem'
              }}
            >
              {type === 'temperature' ? 'Celsius' : 'Percent'}
            </Typography>
          )}
        </Box>

        <Typography
          variant="h3"
          component="div"
          sx={{
            fontWeight: 'bold',
            color,
            textAlign: 'center',
            my: 1.5,
            fontSize: { xs: '1.8rem', sm: '2.2rem', md: '2.5rem' },
            height: '2.8rem',
            display: 'flex',
            alignItems: 'center',
            justifyContent: 'center'
          }}
        >
          {formattedValue}
        </Typography>

        {type !== 'obstacle' && (
          <Box sx={{ mt: 2 }}>
            <Box sx={{ display: 'flex', justifyContent: 'space-between', mb: 0.5 }}>
              <Typography variant="caption" color="text.secondary" fontSize="0.7rem">
                {type === 'temperature' ? '0°C' : '0%'}
              </Typography>
              <Typography variant="caption" color="text.secondary" fontSize="0.7rem">
                {type === 'temperature' ? '50°C' : '100%'}
              </Typography>
            </Box>
            <LinearProgress
              variant="determinate"
              value={progressValue}
              sx={{
                height: 6,
                borderRadius: 3,
                bgcolor: alpha(color, 0.1),
                '& .MuiLinearProgress-bar': {
                  bgcolor: color,
                  borderRadius: 3,
                }
              }}
            />
          </Box>
        )}

        {type === 'obstacle' && (
          <Box
            sx={{
              mt: 2,
              display: 'flex',
              justifyContent: 'center',
              alignItems: 'center'
            }}
          >
            <Box
              sx={{
                width: 10,
                height: 10,
                borderRadius: '50%',
                bgcolor: value ? 'error.main' : 'success.main',
                mr: 1,
              }}
            />
            <Typography
              variant="body2"
              color="text.secondary"
              sx={{ fontWeight: 'medium' }}
            >
              {value ? 'Obstacle Detected' : 'Path Clear'}
            </Typography>
          </Box>
        )}
      </CardContent>
    </Card>
  );
};

export default SensorCard;
