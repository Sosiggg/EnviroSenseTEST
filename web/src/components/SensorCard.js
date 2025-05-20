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
        transition: 'all 0.3s ease',
        overflow: 'visible',
        position: 'relative',
        '&:hover': {
          transform: 'translateY(-5px)',
          boxShadow: '0 8px 25px rgba(0, 0, 0, 0.1)',
        },
      }}
    >
      <Box
        sx={{
          position: 'absolute',
          top: -15,
          left: 20,
          width: 50,
          height: 50,
          borderRadius: '50%',
          display: 'flex',
          alignItems: 'center',
          justifyContent: 'center',
          backgroundColor: alpha(color, 0.9),
          color: '#fff',
          boxShadow: `0 4px 12px ${alpha(color, 0.4)}`,
        }}
      >
        <IconComponent fontSize="medium" />
      </Box>

      <CardContent sx={{ pt: 4, pb: 3, px: 3, flexGrow: 1 }}>
        <Box sx={{ display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start', mb: 3, mt: 1 }}>
          <Typography
            variant="h6"
            component="div"
            sx={{
              fontWeight: 'medium',
              color: 'text.primary',
              ml: 5
            }}
          >
            {title}
          </Typography>

          {type !== 'obstacle' && (
            <Typography
              variant="caption"
              sx={{
                color: 'text.secondary',
                bgcolor: alpha(color, 0.1),
                px: 1.5,
                py: 0.5,
                borderRadius: 10,
                fontWeight: 'medium'
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
            my: 2,
            fontSize: { xs: '2rem', sm: '2.5rem', md: '3rem' },
            transition: 'all 0.5s ease',
            position: 'relative',
            height: '3.5rem',
            display: 'flex',
            alignItems: 'center',
            justifyContent: 'center'
          }}
        >
          {formattedValue}
        </Typography>

        {type !== 'obstacle' && (
          <Box sx={{ mt: 3, mb: 1 }}>
            <Box sx={{ display: 'flex', justifyContent: 'space-between', mb: 0.5 }}>
              <Typography variant="caption" color="text.secondary">
                {type === 'temperature' ? '0°C' : '0%'}
              </Typography>
              <Typography variant="caption" color="text.secondary">
                {type === 'temperature' ? '50°C' : '100%'}
              </Typography>
            </Box>
            <LinearProgress
              variant="determinate"
              value={progressValue}
              sx={{
                height: 8,
                borderRadius: 4,
                bgcolor: alpha(color, 0.1),
                '& .MuiLinearProgress-bar': {
                  bgcolor: color,
                  borderRadius: 4,
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
                width: 12,
                height: 12,
                borderRadius: '50%',
                bgcolor: value ? 'error.main' : 'success.main',
                mr: 1,
                animation: value ? 'pulse 1.5s infinite' : 'none'
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
