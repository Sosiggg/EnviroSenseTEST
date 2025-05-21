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

  // Generate chart data based on type and ensure it's valid
  const generateChartData = () => {
    // Ensure data is an array and has valid items
    if (!data || !Array.isArray(data) || data.length === 0) {
      return {
        labels: [],
        datasets: [{
          label: type === 'temperature' ? 'Temperature (°C)' : 'Humidity (%)',
          data: [],
          borderColor: color,
          backgroundColor: alpha(color, 0.1),
          tension: 0.4,
        }]
      };
    }

    // Generate chart data based on type
    return type === 'temperature'
      ? generateTemperatureChartData(data)
      : generateHumidityChartData(data);
  };

  // Create a stable reference to chart data
  const chartData = generateChartData();

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
      }}
    >
      <CardContent sx={{ p: 2 }}>
        <Box sx={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', mb: 2 }}>
          <Box sx={{ display: 'flex', alignItems: 'center' }}>
            <Box
              sx={{
                display: 'flex',
                alignItems: 'center',
                justifyContent: 'center',
                width: 32,
                height: 32,
                borderRadius: '6px',
                backgroundColor: alpha(color, 0.1),
                color: color,
                mr: 1.5
              }}
            >
              {getIcon()}
            </Box>
            <Typography
              variant="subtitle1"
              component="div"
              sx={{ fontWeight: 'medium' }}
            >
              {title}
            </Typography>
          </Box>

          <Chip
            label="24h"
            size="small"
            sx={{
              bgcolor: alpha(theme.palette.primary.main, 0.1),
              color: theme.palette.primary.main,
              fontWeight: 'medium',
              fontSize: '0.7rem',
              height: 24,
              px: 0.5
            }}
          />
        </Box>

        <Box sx={{ height: 240, position: 'relative' }}>
          {data && Array.isArray(data) && data.length > 0 ? (
            <Line
              ref={chartRef}
              options={options}
              data={chartData}
              plugins={[
                {
                  id: 'customCanvasBackgroundColor',
                  beforeDraw: (chart) => {
                    const ctx = chart.canvas.getContext('2d');
                    if (!ctx) return;

                    // Apply gradient to dataset if possible
                    try {
                      const gradient = ctx.createLinearGradient(0, 0, 0, 240);
                      gradient.addColorStop(0, alpha(color, 0.2));
                      gradient.addColorStop(1, alpha(color, 0.0));

                      if (chart.data.datasets && chart.data.datasets.length > 0) {
                        chart.data.datasets[0].backgroundColor = gradient;
                      }
                    } catch (error) {
                      console.error('Error applying gradient:', error);
                    }
                  }
                }
              ]}
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
                borderRadius: 1,
                p: 2
              }}
            >
              <TimelineIcon
                sx={{
                  fontSize: 32,
                  color: alpha(theme.palette.text.secondary, 0.3),
                  mb: 1
                }}
              />
              <Typography variant="body2" color="text.secondary" align="center">
                No data available yet
              </Typography>
            </Box>
          )}
        </Box>

        {data && Array.isArray(data) && data.length > 0 && (
          <Box
            sx={{
              display: 'flex',
              justifyContent: 'space-between',
              mt: 1.5,
              pt: 1.5,
              borderTop: `1px solid ${alpha(theme.palette.divider, 0.1)}`
            }}
          >
            <Box>
              <Typography variant="caption" color="text.secondary" fontSize="0.7rem">
                Min
              </Typography>
              <Typography
                variant="body2"
                fontWeight="medium"
                color={color}
              >
                {(() => {
                  try {
                    // Get valid values for the calculation
                    const values = type === 'temperature'
                      ? data.filter(d => d && d.temperature !== undefined && d.temperature !== null)
                          .map(d => typeof d.temperature === 'string' ? parseFloat(d.temperature) : d.temperature)
                          .filter(val => !isNaN(val))
                      : data.filter(d => d && d.humidity !== undefined && d.humidity !== null)
                          .map(d => typeof d.humidity === 'string' ? parseFloat(d.humidity) : d.humidity)
                          .filter(val => !isNaN(val));

                    if (values.length === 0) return type === 'temperature' ? '0.0°C' : '0.0%';

                    const min = Math.min(...values);
                    return type === 'temperature' ? `${min.toFixed(1)}°C` : `${min.toFixed(1)}%`;
                  } catch (error) {
                    console.error('Error calculating min:', error);
                    return type === 'temperature' ? '0.0°C' : '0.0%';
                  }
                })()}
              </Typography>
            </Box>

            <Box sx={{ textAlign: 'center' }}>
              <Typography variant="caption" color="text.secondary" fontSize="0.7rem">
                Avg
              </Typography>
              <Typography
                variant="body2"
                fontWeight="medium"
                color={color}
              >
                {(() => {
                  try {
                    // Get valid values for the calculation
                    const values = type === 'temperature'
                      ? data.filter(d => d && d.temperature !== undefined && d.temperature !== null)
                          .map(d => typeof d.temperature === 'string' ? parseFloat(d.temperature) : d.temperature)
                          .filter(val => !isNaN(val))
                      : data.filter(d => d && d.humidity !== undefined && d.humidity !== null)
                          .map(d => typeof d.humidity === 'string' ? parseFloat(d.humidity) : d.humidity)
                          .filter(val => !isNaN(val));

                    if (values.length === 0) return type === 'temperature' ? '0.0°C' : '0.0%';

                    const avg = values.reduce((sum, val) => sum + val, 0) / values.length;
                    return type === 'temperature' ? `${avg.toFixed(1)}°C` : `${avg.toFixed(1)}%`;
                  } catch (error) {
                    console.error('Error calculating average:', error);
                    return type === 'temperature' ? '0.0°C' : '0.0%';
                  }
                })()}
              </Typography>
            </Box>

            <Box sx={{ textAlign: 'right' }}>
              <Typography variant="caption" color="text.secondary" fontSize="0.7rem">
                Max
              </Typography>
              <Typography
                variant="body2"
                fontWeight="medium"
                color={color}
              >
                {(() => {
                  try {
                    // Get valid values for the calculation
                    const values = type === 'temperature'
                      ? data.filter(d => d && d.temperature !== undefined && d.temperature !== null)
                          .map(d => typeof d.temperature === 'string' ? parseFloat(d.temperature) : d.temperature)
                          .filter(val => !isNaN(val))
                      : data.filter(d => d && d.humidity !== undefined && d.humidity !== null)
                          .map(d => typeof d.humidity === 'string' ? parseFloat(d.humidity) : d.humidity)
                          .filter(val => !isNaN(val));

                    if (values.length === 0) return type === 'temperature' ? '0.0°C' : '0.0%';

                    const max = Math.max(...values);
                    return type === 'temperature' ? `${max.toFixed(1)}°C` : `${max.toFixed(1)}%`;
                  } catch (error) {
                    console.error('Error calculating max:', error);
                    return type === 'temperature' ? '0.0°C' : '0.0%';
                  }
                })()}
              </Typography>
            </Box>
          </Box>
        )}
      </CardContent>
    </Card>
  );
};

export default SensorChart;
