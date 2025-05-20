import React, { useRef, useEffect } from 'react';
import { Card, CardContent, Typography, Box, useTheme, alpha, Chip } from '@mui/material';
import {
  Chart as ChartJS,
  CategoryScale,
  LinearScale,
  PointElement,
  LineElement,
  Title,
  Tooltip,
  Legend,
  Filler
} from 'chart.js';
import { Line } from 'react-chartjs-2';
import { generateTemperatureChartData, generateHumidityChartData } from '../utils/formatters';
import {
  Thermostat as ThermostatIcon,
  Opacity as OpacityIcon,
  Timeline as TimelineIcon
} from '@mui/icons-material';

// Register ChartJS components
ChartJS.register(
  CategoryScale,
  LinearScale,
  PointElement,
  LineElement,
  Title,
  Tooltip,
  Legend,
  Filler
);

const SensorChart = ({ title, type, data }) => {
  const chartRef = useRef(null);
  const theme = useTheme();

  // Get color based on type
  const getColor = () => {
    if (type === 'temperature') {
      return theme.palette.error.main;
    } else if (type === 'humidity') {
      return theme.palette.info.main;
    }
    return theme.palette.primary.main;
  };

  const color = getColor();

  // Generate chart data based on type
  const chartData = type === 'temperature'
    ? generateTemperatureChartData(data)
    : generateHumidityChartData(data);

  // Customize chart data with gradients
  const customizeChartData = (canvas) => {
    const ctx = canvas.getContext('2d');

    // Create gradient for background
    const gradient = ctx.createLinearGradient(0, 0, 0, 300);
    gradient.addColorStop(0, alpha(color, 0.3));
    gradient.addColorStop(1, alpha(color, 0.0));

    // Apply gradient to dataset
    const customData = { ...chartData };
    if (customData.datasets && customData.datasets.length > 0) {
      customData.datasets[0] = {
        ...customData.datasets[0],
        backgroundColor: gradient,
        borderColor: color,
        borderWidth: 2,
        pointBackgroundColor: color,
        pointBorderColor: '#fff',
        pointHoverBackgroundColor: '#fff',
        pointHoverBorderColor: color,
        pointRadius: 3,
        pointHoverRadius: 5,
        fill: true,
      };
    }

    return customData;
  };

  // Chart options
  const options = {
    responsive: true,
    maintainAspectRatio: false,
    plugins: {
      legend: {
        display: false,
      },
      title: {
        display: false,
      },
      tooltip: {
        mode: 'index',
        intersect: false,
        backgroundColor: alpha(theme.palette.background.paper, 0.9),
        titleColor: theme.palette.text.primary,
        bodyColor: theme.palette.text.secondary,
        borderColor: theme.palette.divider,
        borderWidth: 1,
        padding: 12,
        cornerRadius: 8,
        boxShadow: '0 4px 12px rgba(0,0,0,0.1)',
        titleFont: {
          family: theme.typography.fontFamily,
          size: 14,
          weight: 'bold',
        },
        bodyFont: {
          family: theme.typography.fontFamily,
          size: 13,
        },
        callbacks: {
          label: function(context) {
            let label = context.dataset.label || '';
            if (label) {
              label += ': ';
            }
            if (context.parsed.y !== null) {
              label += type === 'temperature'
                ? `${context.parsed.y.toFixed(1)}°C`
                : `${context.parsed.y.toFixed(1)}%`;
            }
            return label;
          }
        }
      },
    },
    scales: {
      x: {
        display: true,
        grid: {
          display: false,
          drawBorder: false,
        },
        ticks: {
          maxTicksLimit: 6,
          maxRotation: 0,
          minRotation: 0,
          padding: 10,
          font: {
            family: theme.typography.fontFamily,
            size: 11,
          },
          color: theme.palette.text.secondary,
        },
      },
      y: {
        display: true,
        grid: {
          color: alpha(theme.palette.divider, 0.1),
          drawBorder: false,
        },
        ticks: {
          padding: 10,
          font: {
            family: theme.typography.fontFamily,
            size: 11,
          },
          color: theme.palette.text.secondary,
        },
        suggestedMin: type === 'temperature' ? 0 : 0,
        suggestedMax: type === 'temperature' ? 50 : 100,
      },
    },
    interaction: {
      mode: 'nearest',
      axis: 'x',
      intersect: false,
    },
    animation: {
      duration: 1000,
    },
    elements: {
      line: {
        tension: 0.4, // Smoother curves
      },
    },
  };

  // Update chart when data changes
  useEffect(() => {
    if (chartRef.current) {
      chartRef.current.update();
    }
  }, [data]);

  // Get icon based on type
  const getIcon = () => {
    if (type === 'temperature') {
      return <ThermostatIcon fontSize="small" />;
    } else if (type === 'humidity') {
      return <OpacityIcon fontSize="small" />;
    }
    return <TimelineIcon fontSize="small" />;
  };

  return (
    <Card
      sx={{
        height: '100%',
        boxShadow: '0 4px 20px rgba(0, 0, 0, 0.08)',
        transition: 'all 0.3s ease',
        '&:hover': {
          transform: 'translateY(-5px)',
          boxShadow: '0 8px 25px rgba(0, 0, 0, 0.1)',
        },
      }}
    >
      <CardContent sx={{ p: 3 }}>
        <Box sx={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', mb: 3 }}>
          <Box sx={{ display: 'flex', alignItems: 'center' }}>
            <Box
              sx={{
                display: 'flex',
                alignItems: 'center',
                justifyContent: 'center',
                width: 40,
                height: 40,
                borderRadius: '12px',
                backgroundColor: alpha(color, 0.1),
                color: color,
                mr: 2
              }}
            >
              {getIcon()}
            </Box>
            <Typography
              variant="h6"
              component="div"
              sx={{ fontWeight: 'medium' }}
            >
              {title}
            </Typography>
          </Box>

          <Chip
            label={type === 'temperature' ? 'Last 24 hours' : 'Last 24 hours'}
            size="small"
            sx={{
              bgcolor: alpha(theme.palette.primary.main, 0.1),
              color: theme.palette.primary.main,
              fontWeight: 'medium',
              fontSize: '0.75rem'
            }}
          />
        </Box>

        <Box sx={{ height: 300, position: 'relative' }}>
          {data.length > 0 ? (
            <Line
              ref={chartRef}
              options={options}
              data={(canvas) => customizeChartData(canvas)}
            />
          ) : (
            <Box
              sx={{
                display: 'flex',
                flexDirection: 'column',
                justifyContent: 'center',
                alignItems: 'center',
                height: '100%',
                bgcolor: alpha(theme.palette.background.paper, 0.5),
                borderRadius: 2,
                p: 3
              }}
            >
              <TimelineIcon
                sx={{
                  fontSize: 40,
                  color: alpha(theme.palette.text.secondary, 0.3),
                  mb: 2
                }}
              />
              <Typography variant="body1" color="text.secondary" align="center">
                No data available yet
              </Typography>
              <Typography variant="body2" color="text.disabled" align="center" sx={{ mt: 1 }}>
                Data will appear here once sensors start sending readings
              </Typography>
            </Box>
          )}
        </Box>

        {data.length > 0 && (
          <Box sx={{ display: 'flex', justifyContent: 'space-between', mt: 2 }}>
            <Typography variant="caption" color="text.secondary">
              {type === 'temperature' ? 'Min: ' : 'Min: '}
              <Typography
                component="span"
                variant="caption"
                fontWeight="medium"
                color={color}
              >
                {type === 'temperature'
                  ? `${Math.min(...data.map(d => d.temperature)).toFixed(1)}°C`
                  : `${Math.min(...data.map(d => d.humidity)).toFixed(1)}%`
                }
              </Typography>
            </Typography>

            <Typography variant="caption" color="text.secondary">
              {type === 'temperature' ? 'Avg: ' : 'Avg: '}
              <Typography
                component="span"
                variant="caption"
                fontWeight="medium"
                color={color}
              >
                {type === 'temperature'
                  ? `${(data.reduce((sum, d) => sum + d.temperature, 0) / data.length).toFixed(1)}°C`
                  : `${(data.reduce((sum, d) => sum + d.humidity, 0) / data.length).toFixed(1)}%`
                }
              </Typography>
            </Typography>

            <Typography variant="caption" color="text.secondary">
              {type === 'temperature' ? 'Max: ' : 'Max: '}
              <Typography
                component="span"
                variant="caption"
                fontWeight="medium"
                color={color}
              >
                {type === 'temperature'
                  ? `${Math.max(...data.map(d => d.temperature)).toFixed(1)}°C`
                  : `${Math.max(...data.map(d => d.humidity)).toFixed(1)}%`
                }
              </Typography>
            </Typography>
          </Box>
        )}
      </CardContent>
    </Card>
  );
};

export default SensorChart;
